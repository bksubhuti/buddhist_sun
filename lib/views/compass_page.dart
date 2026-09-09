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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({Key? key}) : super(key: key);

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  double _direction = 0.0;
  final ValueNotifier<double> _directionNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _onTargetNotifier = ValueNotifier<bool>(false);
  double _bearing = 0.0;
  double _distance = 0.0;
  late double _userLatitude = (Prefs.lat != 1.1) ? Prefs.lat : 0.0;
  late double _userLongitude = (Prefs.lng != 1.1) ? Prefs.lng : 0.0;
  late double _targetLatitude = Prefs.targetLat;
  late double _targetLongitude = Prefs.targetLong;
  late AnimationController _controller;
  bool _vibrationEnabled = false;
  final int limits = 3;
  bool _isLoadingLocation = true;
  bool _isChangingLocation = false;
  late bool _showMap = Prefs.compassShowMap;
  GoogleMapController? _mapController;
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
      case 'mahamuni':
        return t.place_mahamuni;
      case 'watPhraKaew':
        return t.place_watPhraKaew;
      case 'mahaCetiya':
        return t.place_mahaCetiya;
      case 'toothRelicPagoda':
        return t.place_toothRelicPagoda;
      case 'statueOfLiberty':
        return 'Statue of Liberty';
      case 'userDest1':
        return Prefs.userDest1.trim().isNotEmpty
            ? Prefs.userDest1
            : t.enterCustom;
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
        const AssetImage('assets/images/compass_buddha.png'), context);
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
          _bearing = _calculateBearing(
              _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
          _isLoadingLocation = false;
        });
        _calculateDistance(_userLatitude, _userLongitude, _targetLatitude,
                _targetLongitude)
            .then((d) {
          if (mounted) setState(() => _distance = d);
        });
        if (_showMap) {
          _updateMapCamera();
        }
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
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final rawHeading = event.heading ?? 0.0;
      final newDirection = (rawHeading < 0) ? rawHeading + 360 : rawHeading;
      final onTarget = (_angDiff(_bearing, newDirection).abs() <= limits);

      _direction = newDirection;
      _directionNotifier.value = newDirection;

      if (onTarget != _wasOnTarget) {
        _wasOnTarget = onTarget;
        _onTargetNotifier.value = onTarget;

        if (_vibrationEnabled) {
          Vibration.cancel();
          if (onTarget) {
            _pulseTimer?.cancel();
            _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
              if (await _canVibrate()) Vibration.vibrate(duration: 100);
            });
          } else {
            _pulseTimer?.cancel();
            _pulseTimer = null;
            if (_canVibrateSync()) Vibration.vibrate(duration: 250);
          }
        } else {
          _pulseTimer?.cancel();
          _pulseTimer = null;
          Vibration.cancel();
        }
      }
    });
  }

  bool _canVibrateSync() {
    if (!_vibrationEnabled) return false;
    final now = DateTime.now();
    if (_lastVibeAt != null && now.difference(_lastVibeAt!) < _minVibeGap) {
      return false;
    }
    _lastVibeAt = now;
    return true;
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

  LatLng _calculateMidpoint(
      double lat1, double lon1, double lat2, double lon2) {
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double rLat1 = lat1 * (math.pi / 180.0);
    final double rLat2 = lat2 * (math.pi / 180.0);
    final double rLon1 = lon1 * (math.pi / 180.0);

    final double bx = math.cos(rLat2) * math.cos(dLon);
    final double by = math.cos(rLat2) * math.sin(dLon);

    final double midLat = math.atan2(
      math.sin(rLat1) + math.sin(rLat2),
      math.sqrt((math.cos(rLat1) + bx) * (math.cos(rLat1) + bx) + by * by),
    );
    final double midLon = rLon1 + math.atan2(by, math.cos(rLat1) + bx);

    return LatLng(midLat * (180.0 / math.pi), midLon * (180.0 / math.pi));
  }

  double _calculateZoomForDistance(double distanceInKm) {
    if (distanceInKm <= 0) return 3.0;
    final double distMeters = distanceInKm * 1000.0;
    final double zoom = (math.log(40075000 * 0.45 / distMeters) / math.ln2);
    return zoom.clamp(1.0, 18.0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_userLatitude != 0.0 && _userLongitude != 0.0) {
      _bearing = _calculateBearing(
          _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
      _calculateDistance(
              _userLatitude, _userLongitude, _targetLatitude, _targetLongitude)
          .then((d) {
        if (mounted) setState(() => _distance = d);
      });
    }
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
          _getLocation(context);
        }
      }
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    });
  }

  void _stopAllSensors() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    Vibration.cancel();
    _compassSub?.cancel();
    _compassSub = null;
    _posSub?.cancel();
    _posSub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopAllSensors();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) {
        _vibrationEnabled = Prefs.vibeOn;
        _startCompass();
        _startLocationStream();
        if (_showMap) {
          _updateMapCamera();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllSensors();
    _controller.dispose();
    _directionNotifier.dispose();
    _onTargetNotifier.dispose();
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
        _bearing = _calculateBearing(
            _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
        _isLoadingLocation = false;
      });
      _calculateDistance(
              _userLatitude, _userLongitude, _targetLatitude, _targetLongitude)
          .then((d) {
        if (mounted) setState(() => _distance = d);
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

  String _alignmentGuidanceText(BuildContext context, [double? currentDir]) {
    final t = AppLocalizations.of(context)!;
    final targetName = _targetDisplayName(context);
    final dir = currentDir ?? _direction;
    if (_angDiff(_bearing, dir).abs() <= limits) {
      return t.facingTarget(targetName);
    }
    final diff = _angDiff(_bearing, dir);
    final deg = diff.abs().round();
    if (diff > 0) {
      return t.turnRightToFace(deg, targetName);
    } else {
      return t.turnLeftToFace(deg, targetName);
    }
  }

  Widget _buildCompass({double size = 290}) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: _onTargetNotifier,
      builder: (context, onTarget, _) {
        return SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Halo Glow & Inner Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? (onTarget
                              ? Color.alphaBlend(
                                  primary.withAlpha(65),
                                  theme.colorScheme.surfaceContainerHighest,
                                )
                              : theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(140))
                          : (onTarget
                              ? Color.alphaBlend(
                                  primary.withAlpha(45),
                                  theme.colorScheme.surfaceContainerHighest,
                                )
                              : theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(160)),
                      boxShadow: onTarget
                          ? [
                              BoxShadow(
                                color: primary.withAlpha(150),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: primary.withAlpha(70),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 30 : 15),
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

                  // Rotating Compass Dial & Target Needle
                  ValueListenableBuilder<double>(
                    valueListenable: _directionNotifier,
                    builder: (context, direction, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: Transform.rotate(
                              key: ValueKey<bool>(onTarget),
                              angle: -math.pi * direction / 180,
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
                            angle: math.pi * (_bearing - direction) / 180,
                            child: SizedBox(
                              width: 286,
                              height: 286,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: onTarget
                                        ? primary
                                        : Colors.amber.shade700,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (onTarget ? primary : Colors.amber)
                                                .withAlpha(150),
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
                        ],
                      );
                    },
                  ),

                  // Fixed Upright Transparent Buddha on Top (stays stationary while compass dial spins)
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: onTarget ? 0.95 : 0.88,
                      child: Image.asset(
                        'assets/images/compass_buddha.png',
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Fixed Top Device Heading Indicator
                  Positioned(
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlignmentBadge() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ValueListenableBuilder<double>(
      valueListenable: _directionNotifier,
      builder: (context, direction, _) {
        final onTarget = (_angDiff(_bearing, direction).abs() <= limits);
        final diff = _angDiff(_bearing, direction);

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
                  _alignmentGuidanceText(context, direction),
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
      },
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

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      clipBehavior: Clip.antiAlias,
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

  void _updateMapCamera() {
    if (!_showMap || _mapController == null || !mounted) return;
    final controller = _mapController;
    if (controller == null) return;

    final double userLat = (_userLatitude != 0.0)
        ? _userLatitude
        : ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
    final double userLng = (_userLongitude != 0.0)
        ? _userLongitude
        : ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);

    if (userLat == 0.0 && userLng == 0.0) {
      try {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_targetLatitude, _targetLongitude),
              zoom: 3,
            ),
          ),
        );
      } catch (_) {}
      return;
    }

    final double bearing =
        _calculateBearing(userLat, userLng, _targetLatitude, _targetLongitude);

    final LatLng midPoint =
        _calculateMidpoint(userLat, userLng, _targetLatitude, _targetLongitude);

    final double distKm = (_distance > 0)
        ? _distance
        : (Geolocator.distanceBetween(
                userLat, userLng, _targetLatitude, _targetLongitude) /
            1000.0);

    final double zoom = _calculateZoomForDistance(distKm);

    try {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: midPoint,
            bearing: bearing,
            zoom: zoom,
          ),
        ),
      );
    } catch (_) {
      try {
        controller.animateCamera(
          CameraUpdate.newLatLng(midPoint),
        );
      } catch (_) {}
    }
  }

  Widget _buildMiniBuddhistCompassWidget() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMap = false;
          Prefs.compassShowMap = false;
          _mapController = null;
        });
      },
      child: Tooltip(
        message: AppLocalizations.of(context)!.compassView,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withAlpha(140),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildCompass(size: 52),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final t = AppLocalizations.of(context)!;

    final double userLat = (_userLatitude != 0.0)
        ? _userLatitude
        : ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
    final double userLng = (_userLongitude != 0.0)
        ? _userLongitude
        : ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);
    final userPos = LatLng(userLat, userLng);
    final targetPos = LatLng(_targetLatitude, _targetLongitude);

    final markers = <Marker>{
      if (userLat != 0.0 || userLng != 0.0)
        Marker(
          markerId: const MarkerId('user_location'),
          position: userPos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: t.yourLocation,
            snippet:
                '${userLat.toStringAsFixed(4)}, ${userLng.toStringAsFixed(4)}',
          ),
        ),
      Marker(
        markerId: const MarkerId('target_site'),
        position: targetPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: _targetDisplayName(context),
          snippet: '${_distance.toInt()} km • Bearing: ${_bearing.toInt()}°',
        ),
      ),
    };

    return Container(
      width: 290,
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: primary.withAlpha(100),
          width: 2.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _onTargetNotifier,
            builder: (context, onTarget, _) {
              final Color routeColor = onTarget
                  ? const Color(0xFFFFB300)
                  : (theme.brightness == Brightness.dark
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withAlpha(220));

              final polylines = <Polyline>{
                if (userLat != 0.0 || userLng != 0.0) ...[
                  // High-contrast dark casing
                  Polyline(
                    polylineId: const PolylineId('geodesic_casing'),
                    points: [userPos, targetPos],
                    geodesic: true,
                    color: Colors.black.withAlpha(onTarget ? 210 : 160),
                    width: onTarget ? 8 : 6,
                  ),
                  // Geodesic Flight Route
                  Polyline(
                    polylineId: const PolylineId('geodesic_flight_path'),
                    points: [userPos, targetPos],
                    geodesic: true,
                    color: routeColor,
                    width: onTarget ? 5 : 4,
                  ),
                ],
              };

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: (userLat != 0.0 || userLng != 0.0)
                      ? _calculateMidpoint(
                          userLat, userLng, _targetLatitude, _targetLongitude)
                      : LatLng(_targetLatitude, _targetLongitude),
                  bearing: (userLat != 0.0 || userLng != 0.0) ? _bearing : 0.0,
                  zoom: (userLat != 0.0 || userLng != 0.0)
                      ? _calculateZoomForDistance(_distance)
                      : 2,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && _showMap && _mapController == controller) {
                      _updateMapCamera();
                    }
                  });
                },
              );
            },
          ),
          // Live Mini Buddhist Compass in Top-Left Corner
          Positioned(
            top: 8,
            left: 8,
            child: _buildMiniBuddhistCompassWidget(),
          ),
          // Recenter / Fit Route button
          Positioned(
            bottom: 10,
            right: 10,
            child: Material(
              color: theme.colorScheme.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(20),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _updateMapCamera,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    size: 20,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            icon: Icon(
              _showMap ? Icons.explore_rounded : Icons.public_rounded,
            ),
            tooltip: _showMap ? t.compassView : t.mapView,
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
                Prefs.compassShowMap = _showMap;
                if (!_showMap) {
                  _mapController = null;
                }
              });
              if (_showMap) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _showMap) {
                    _updateMapCamera();
                  }
                });
              }
            },
          ),
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
                  // 1. Compass Dial OR Interactive Map View
                  (_isLoadingLocation || _isChangingLocation)
                      ? _buildLoadingIndicator()
                      : _showMap
                          ? _buildMapView()
                          : _buildCompass(),

                  const SizedBox(height: 18),

                  // 2. Alignment Guidance Badge
                  _buildAlignmentBadge(),

                  const SizedBox(height: 18),

                  // 3. Stats Row (Heading, Target Bearing, Distance)
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _directionNotifier,
                          builder: (context, direction, _) {
                            return _buildMetricCard(
                              context: context,
                              icon: Icons.navigation_rounded,
                              label: t.compassHeading,
                              value: '${direction.toInt()}°',
                              subValue: _cardinalDirection(direction),
                            );
                          },
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
                        _targetLatitude = Prefs.targetLat;
                        _targetLongitude = Prefs.targetLong;
                        _bearing = _calculateBearing(_userLatitude,
                            _userLongitude, _targetLatitude, _targetLongitude);
                      });
                      _calculateDistance(_userLatitude, _userLongitude,
                              _targetLatitude, _targetLongitude)
                          .then((d) {
                        if (mounted) setState(() => _distance = d);
                      });
                      _getLocation(context).then((_) {
                        if (mounted) {
                          setState(() {
                            _isChangingLocation = false;
                          });
                          if (_showMap) {
                            _updateMapCamera();
                          }
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
