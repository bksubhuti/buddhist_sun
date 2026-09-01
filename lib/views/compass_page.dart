import 'dart:async';
import 'dart:math' as math;
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/widgets/dharmachakra_icon.dart';
import 'package:buddhist_sun/widgets/place_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({Key? key}) : super(key: key);

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage>
    with TickerProviderStateMixin {
  double _direction = 0.0;
  double _bearing = 0.0;
  double _distance = 0.0;
  double _userLatitude = 0.0;
  double _userLongitude = 0.0;
  double _targetLatitude = Prefs.targetLat;
  double _targetLongitude = Prefs.targetLong;
  late AnimationController _controller;
  bool _vibrationEnabled = false;
  final int limits = 3;
  bool _isLoadingLocation = true;
  bool _isChangingLocation = false;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _posSub;
  bool _wasOnTarget = false;
  Timer? _pulseTimer;
  DateTime? _lastVibeAt;
  final _minVibeGap = const Duration(milliseconds: 300);
  bool _askedThisSession = false;
  bool _showingDialog = false;
  Key _placeSelectorKey = UniqueKey();

  String _targetDisplayName(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (Prefs.targetName) {
      case 'bodhGaya':
        return t.place_bodhGaya;
      case 'lumbiniPagoda':
        return t.place_lumbiniPagoda;
      case 'sarnath':
        return t.place_sarnath;
      case 'kushinagar':
        return t.place_kushinagar;
      case 'shwedagonPagoda':
        return t.place_shwedagonPagoda;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      case 'toothRelicPagoda':
        return t.place_toothRelicPagoda;
      case 'userDest1':
        return Prefs.userDest1;
      default:
        return Prefs.targetName;
    }
  }

  double _angDiff(double a, double b) {
    final d = (a - b) % 360;
    return (d + 540) % 360 - 180;
  }

  bool _isWithinLimits() {
    return _angDiff(_bearing, _direction).abs() <= limits;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/compass_normal.png'), context);
    precacheImage(
        const AssetImage('assets/images/compass_on_target.png'), context);
    precacheImage(
        const AssetImage('assets/images/flags/flag_india.png'), context);
    precacheImage(
        const AssetImage('assets/images/flags/flag_nepal.png'), context);
    precacheImage(
        const AssetImage('assets/images/flags/flag_sri_lanka.png'), context);
    precacheImage(
        const AssetImage('assets/images/flags/flag_myanmar.png'), context);
  }

  Future<void> _getLocation(BuildContext context) async {
    final ok = await _ensureLocationPermissionWithPrompt(context);
    if (!ok) return;

    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      _promptOpenLocationServices(context);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 0),
      );
      if (mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        _showSnack(context, AppLocalizations.of(context)!.locationError);
      }
    }
  }

  void _promptOpenLocationServices(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.locationServicesTitle),
        content: Text(
          AppLocalizations.of(context)!.locationServicesContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            child: Text(
                AppLocalizations.of(context)!.locationRequiredOpenSettings),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _ensureLocationPermissionWithPrompt(BuildContext context) async {
    if (_askedThisSession) return await _hasLocationPermission();
    _askedThisSession = true;

    if (await _hasLocationPermission()) return true;

    final proceed = await _showRationaleDialog(context);
    if (proceed != true) return false;

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        await _showSettingsOrExitDialog(context,
            message: AppLocalizations.of(context)!.locationRequiredMessage1);
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await _showSettingsOrExitDialog(context,
            message: AppLocalizations.of(context)!.locationRequiredMessage2);
      }
      return false;
    }

    return false;
  }

  Future<bool> _hasLocationPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<bool?> _showRationaleDialog(BuildContext context) async {
    if (_showingDialog) return false;
    _showingDialog = true;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)!.locationPermissionRationaleTitle),
        content: Text(
          AppLocalizations.of(context)!.locationPermissionRationaleMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!
                .locationPermissionRationaleNotNow),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!
                .locationPermissionRationaleContinue),
          ),
        ],
      ),
    );
    _showingDialog = false;
    return res;
  }

  Future<void> _showSettingsOrExitDialog(BuildContext context,
      {required String message}) async {
    if (_showingDialog) return;
    _showingDialog = true;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.locationRequiredTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.locationRequiredCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: Text(
                AppLocalizations.of(context)!.locationRequiredOpenSettings),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: Text(AppLocalizations.of(context)!.locationRequiredExit),
          ),
        ],
      ),
    );
    _showingDialog = false;
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) async {
      if (!mounted) return;
      setState(() {
        _targetLatitude = Prefs.targetLat;
        _targetLongitude = Prefs.targetLong;

        _direction = event.heading ?? 0.0;
        _direction = (_direction < 0) ? _direction + 360 : _direction;
        _bearing = _calculateBearing(
          _userLatitude,
          _userLongitude,
          _targetLatitude,
          _targetLongitude,
        );
      });

      double newDistance = await _calculateDistance(
        _userLatitude,
        _userLongitude,
        _targetLatitude,
        _targetLongitude,
      );

      if (!mounted) return;
      setState(() {
        _distance = newDistance;
      });

      final onTarget = _isWithinLimits();

      if (onTarget != _wasOnTarget) {
        _wasOnTarget = onTarget;

        if (_vibrationEnabled) {
          await Vibration.cancel();
          if (onTarget) {
            _pulseTimer?.cancel();
            _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
              if (await _canVibrate()) Vibration.vibrate(duration: 100);
            });
          } else {
            _pulseTimer?.cancel();
            _pulseTimer = null;
            if (await _canVibrate()) Vibration.vibrate(duration: 250);
          }
        } else {
          _pulseTimer?.cancel();
          _pulseTimer = null;
          await Vibration.cancel();
        }
      }
    });
  }

  Future<bool> _canVibrate() async {
    if (!_vibrationEnabled) return false;
    if (!(await Vibration.hasVibrator())) return false;
    final now = DateTime.now();
    if (_lastVibeAt != null && now.difference(_lastVibeAt!) < _minVibeGap) {
      return false;
    }
    _lastVibeAt = now;
    return true;
  }

  double _calculateBearing(
      double startLat, double startLng, double endLat, double endLng) {
    double startLatRad = startLat * (math.pi / 180);
    double startLngRad = startLng * (math.pi / 180);
    double endLatRad = endLat * (math.pi / 180);
    double endLngRad = endLng * (math.pi / 180);

    double dLng = endLngRad - startLngRad;

    double y = math.sin(dLng) * math.cos(endLatRad);
    double x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    double bearingRad = math.atan2(y, x);
    double bearingDeg = bearingRad * (180 / math.pi);

    return (bearingDeg + 360) % 360;
  }

  Future<double> _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) async {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    return distanceInMeters / 1000;
  }

  @override
  void initState() {
    super.initState();
    _vibrationEnabled = Prefs.vibeOn;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _startCompass();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _ensureLocationPermissionWithPrompt(context);
      if (ok) {
        final servicesOn = await Geolocator.isLocationServiceEnabled();
        if (servicesOn) {
          _startLocationStream();
        }
      }
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    });
  }

  @override
  void dispose() {
    Vibration.cancel();
    _pulseTimer?.cancel();
    _compassSub?.cancel();
    _posSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startLocationStream() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
        _isLoadingLocation = false;
      });
    });
  }

  String _cardinalDirection(double deg) {
    final normalized = (deg % 360 + 360) % 360;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
      'N'
    ];
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  String _alignmentGuidanceText(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final targetName = _targetDisplayName(context);
    if (_isWithinLimits()) {
      return t.facingTarget(targetName);
    }
    final diff = _angDiff(_bearing, _direction);
    final deg = diff.abs().round();
    if (diff > 0) {
      return t.turnRightToFace(deg, targetName);
    } else {
      return t.turnLeftToFace(deg, targetName);
    }
  }

  Widget _buildCompass() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onTarget = _isWithinLimits();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Halo Glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            boxShadow: onTarget
                ? [
                    BoxShadow(
                      color: primary.withAlpha(140),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.amber.withAlpha(90),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
            border: Border.all(
              color: onTarget
                  ? primary
                  : theme.colorScheme.outlineVariant.withAlpha(120),
              width: onTarget ? 2.5 : 1.5,
            ),
          ),
        ),

        // Rotating Compass Dial
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: Transform.rotate(
            key: ValueKey<bool>(onTarget),
            angle: -math.pi * _direction / 180,
            child: Image.asset(
              onTarget
                  ? 'assets/images/compass_on_target.png'
                  : 'assets/images/compass_normal.png',
              width: 270,
              height: 270,
            ),
          ),
        ),

        // Target Direction Marker (Outer Needle pointing to sacred site)
        Transform.rotate(
          angle: math.pi * (_bearing - _direction) / 180,
          child: SizedBox(
            width: 286,
            height: 286,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: onTarget ? primary : Colors.amber.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (onTarget ? primary : Colors.amber).withAlpha(150),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const DharmachakraIcon(
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Fixed Top Device Heading Indicator
        Positioned(
          top: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: onTarget ? primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: onTarget ? Colors.transparent : primary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: onTarget ? Colors.white : primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentBadge() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onTarget = _isWithinLimits();
    final diff = _angDiff(_bearing, _direction);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: onTarget
            ? primary.withAlpha(220)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(160),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: onTarget
              ? primary
              : theme.colorScheme.outlineVariant.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: onTarget
            ? [
                BoxShadow(
                  color: primary.withAlpha(100),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onTarget
                ? Icons.check_circle_rounded
                : (diff > 0
                    ? Icons.turn_right_rounded
                    : Icons.turn_left_rounded),
            size: 20,
            color: onTarget
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _alignmentGuidanceText(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: onTarget
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationCard() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _vibrationEnabled
                ? primary.withAlpha(40)
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.vibration_rounded,
            color: _vibrationEnabled
                ? primary
                : theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.vibration,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.hapticPulseGuidance,
          style: const TextStyle(fontSize: 12),
        ),
        value: _vibrationEnabled,
        onChanged: (value) async {
          setState(() {
            _vibrationEnabled = value;
            Prefs.vibeOn = value;
          });
          if (!value) {
            _pulseTimer?.cancel();
            _pulseTimer = null;
            await Vibration.cancel();
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 290,
      width: 290,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void showHelpDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: Text(AppLocalizations.of(context)!.ok),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog help = AlertDialog(
      title: Text(AppLocalizations.of(context)!.help),
      content: SingleChildScrollView(
        child: Text(
          AppLocalizations.of(context)!.compassHelpContent,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return help;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          t.compass,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: t.help,
            onPressed: () => showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Compass Dial
                  (_isLoadingLocation || _isChangingLocation)
                      ? _buildLoadingIndicator()
                      : _buildCompass(),

                  const SizedBox(height: 18),

                  // 2. Alignment Guidance Badge
                  _buildAlignmentBadge(),

                  const SizedBox(height: 18),

                  // 3. Stats Row (Heading, Target Bearing, Distance)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.navigation_rounded,
                          label: t.compassHeading,
                          value: '${_direction.toInt()}°',
                          subValue: _cardinalDirection(_direction),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.explore_rounded,
                          label: t.compassTarget,
                          value: '${_bearing.toInt()}°',
                          subValue: _cardinalDirection(_bearing),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.straighten_rounded,
                          label: t.compassDistance,
                          value: _distance >= 1000
                              ? '${(_distance / 1000).toStringAsFixed(1)}k'
                              : '${_distance.toInt()}',
                          subValue: 'km',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. Sacred Pilgrimage Site Selector
                  PlaceSelector(
                    key: _placeSelectorKey,
                    onLocationChanged: () {
                      setState(() {
                        _isChangingLocation = true;
                      });
                      _getLocation(context).then((_) {
                        if (mounted) {
                          setState(() {
                            _isChangingLocation = false;
                          });
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // 5. Vibration Toggle Card
                  _buildVibrationCard(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
