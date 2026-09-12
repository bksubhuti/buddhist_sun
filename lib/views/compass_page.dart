import 'dart:async';
import 'dart:math' as math;
import 'package:buddhist_sun/l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/widgets/dharmachakra_icon.dart';
import 'package:buddhist_sun/widgets/place_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';

enum CompassViewMode { compass, map2d, earth }

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
  late CompassViewMode _viewMode;
  bool _earthAlignWithDirection = true;
  GoogleMapController? _mapController;
  late FlutterEarthGlobeController _globeController;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _posSub;
  bool _wasOnTarget = false;
  Timer? _pulseTimer;
  DateTime? _lastVibeAt;
  final _minVibeGap = const Duration(milliseconds: 300);
  bool _askedThisSession = false;
  bool _showingDialog = false;
  Key _placeSelectorKey = UniqueKey();
  int _cardPointerCount = 0;
  bool _isInteractingWithCard = false;

  void _onCardPointerDown(PointerDownEvent event) {
    _cardPointerCount++;
    if (!_isInteractingWithCard) {
      setState(() {
        _isInteractingWithCard = true;
      });
    }
  }

  void _onCardPointerUp(PointerUpEvent event) {
    _cardPointerCount = math.max(0, _cardPointerCount - 1);
    if (_cardPointerCount == 0 && _isInteractingWithCard) {
      setState(() {
        _isInteractingWithCard = false;
      });
    }
  }

  void _onCardPointerCancel(PointerCancelEvent event) {
    _cardPointerCount = math.max(0, _cardPointerCount - 1);
    if (_cardPointerCount == 0 && _isInteractingWithCard) {
      setState(() {
        _isInteractingWithCard = false;
      });
    }
  }

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
    precacheImage(const AssetImage('assets/images/2k_earth-day.jpg'), context);
    precacheImage(
        const AssetImage('assets/images/2k_earth-night.jpg'), context);
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
          _distance = _calculateDistance(
              _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
          _isLoadingLocation = false;
        });
        if (_viewMode != CompassViewMode.compass) {
          _refreshMapView();
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

  double _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    if ((startLat == 0.0 && startLng == 0.0) ||
        (endLat == 0.0 && endLng == 0.0)) {
      return 0.0;
    }
    final double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    return distanceInMeters / 1000;
  }

  double _calculateGlobeZoomForDistance(double distanceKm) {
    if (distanceKm <= 0.0) return 0.0;

    // Card dimensions: 290 x 290.
    // 65% of the card is 290 * 0.65 = 188.5 px (20% less than original 85%).
    const double targetSpan = 188.5;
    const double baseRadius = 94.25;
    const double earthRadiusKm = 6371.0;

    // Angular distance theta in radians (0 to pi)
    final double theta = (distanceKm / earthRadiusKm).clamp(0.01, math.pi);
    final double sinHalf = math.sin(theta / 2.0);

    // If points are on opposite sides of the globe (e.g. Statue of Liberty ~14,000 km, theta >= 95°),
    // the Earth sphere itself should take up ~65% of the card with both points showing.
    // At baseRadius = 94.25 and zoom = 0.0, the Earth diameter is exactly 188.5px (65% of card).
    if (distanceKm >= 9500 || theta >= (math.pi * 0.52)) {
      return 0.0;
    }

    // For regional / continental routes (e.g. Sri Lanka to Bodh Gaya ~2,000 km),
    // the distance between the two points on screen should take up 65% of the card.
    // Screen distance = 2 * R * sin(theta / 2) = targetSpan
    // => R = targetSpan / (2 * sin(theta / 2))
    // Since R = baseRadius * 2^zoom:
    // => zoom = log2(R / baseRadius)
    final double desiredRadius = targetSpan / (2.0 * sinHalf);
    final double zoom = math.log(desiredRadius / baseRadius) / math.ln2;

    return zoom.clamp(0.0, 2.75);
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
    Prefs.lastScreen = 'compass';
    WidgetsBinding.instance.addObserver(this);
    if (_userLatitude != 0.0 && _userLongitude != 0.0) {
      _bearing = _calculateBearing(
          _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
      _distance = _calculateDistance(
          _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
    }
    _vibrationEnabled = Prefs.vibeOn;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _startCompass();

    final modeStr = Prefs.compassViewMode;
    if (modeStr == 'map2d') {
      _viewMode = CompassViewMode.map2d;
    } else if (modeStr == 'earth') {
      _viewMode = CompassViewMode.earth;
    } else {
      _viewMode = CompassViewMode.compass;
    }

    _globeController = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      isRotating: false,
      zoom: 0.0,
      minZoom: -1.5,
      maxZoom: 3.5,
      zoomSensitivity: 1.5,
      showAtmosphere: true,
      atmosphereColor: const Color(0xFF4A90E2).withAlpha(120),
      surface: const AssetImage('assets/images/2k_earth-day.jpg'),
      nightSurface: const AssetImage('assets/images/2k_earth-night.jpg'),
      isDayNightCycleEnabled: false,
    );
    _globeController.onLoaded = () {
      if (mounted && _viewMode == CompassViewMode.earth) {
        _updateGlobePointsAndCamera(animateCamera: true);
      }
    };
    _onTargetNotifier.addListener(_handleOnTargetChanged);

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
        if (_viewMode != CompassViewMode.compass) {
          _refreshMapView();
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
    _onTargetNotifier.removeListener(_handleOnTargetChanged);
    _onTargetNotifier.dispose();
    _globeController.onLoaded = null;
    _globeController.onPointConnectionAdded = null;
    _globeController.onResetGlobeRotation = null;
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
        _distance = _calculateDistance(
            _userLatitude, _userLongitude, _targetLatitude, _targetLongitude);
        _isLoadingLocation = false;
      });
      if (_viewMode == CompassViewMode.earth) {
        _updateGlobePointsAndCamera(animateCamera: false);
      }
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
    final String distStr = _distance >= 1000
        ? '${(_distance / 1000).toStringAsFixed(1)}k km'
        : '${_distance.toInt()} km';

    return ValueListenableBuilder<double>(
      valueListenable: _directionNotifier,
      builder: (context, direction, _) {
        final onTarget = (_angDiff(_bearing, direction).abs() <= limits);
        final diff = _angDiff(_bearing, direction);

        return GestureDetector(
          onTap: () {
            if (_viewMode == CompassViewMode.earth) {
              _updateGlobePointsAndCamera(animateCamera: true);
            } else if (_viewMode == CompassViewMode.map2d) {
              _updateMapCamera();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: onTarget
                  ? (theme.brightness == Brightness.dark
                      ? const Color(0xFFFFB300).withAlpha(225)
                      : const Color(0xFFFFB300))
                  : theme.colorScheme.surfaceContainerHighest.withAlpha(160),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: onTarget
                    ? const Color(0xFFFFD54F)
                    : theme.colorScheme.outlineVariant.withAlpha(100),
                width: 1.5,
              ),
              boxShadow: onTarget
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withAlpha(120),
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
                  color: onTarget ? Colors.black87 : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${_alignmentGuidanceText(context, direction)} • $distStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onTarget
                          ? Colors.black87
                          : theme.colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
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

  void _refreshMapView() {
    if (!mounted || _viewMode == CompassViewMode.compass) return;
    if (_viewMode == CompassViewMode.earth) {
      _updateGlobePointsAndCamera(animateCamera: true);
    } else if (_viewMode == CompassViewMode.map2d) {
      _updateMapCamera();
    }
  }

  void _setViewMode(CompassViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      Prefs.compassViewMode = mode.name;
      Prefs.compassShowMap = (mode != CompassViewMode.compass);
      if (mode != CompassViewMode.map2d) {
        _mapController = null;
      }
    });
    if (mode == CompassViewMode.earth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _viewMode == CompassViewMode.earth) {
          _updateGlobePointsAndCamera(animateCamera: true);
        }
      });
    } else if (mode == CompassViewMode.map2d) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _viewMode == CompassViewMode.map2d) {
          _updateMapCamera();
        }
      });
    }
  }

  double _getGlobeRotationTurns() {
    final double userLat = (_userLatitude != 0.0)
        ? _userLatitude
        : ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
    final double userLng = (_userLongitude != 0.0)
        ? _userLongitude
        : ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);
    if (!_earthAlignWithDirection || (userLat == 0.0 && userLng == 0.0)) {
      return 0.0;
    }
    final LatLng midPoint =
        _calculateMidpoint(userLat, userLng, _targetLatitude, _targetLongitude);
    final double midBearing = _calculateBearing(midPoint.latitude,
        midPoint.longitude, _targetLatitude, _targetLongitude);
    return -midBearing / 360.0;
  }

  void _addRouteConnections(double userLat, double userLng, bool onTarget) {
    _globeController.removePointConnection('pilgrimage_route_casing');
    _globeController.removePointConnection('pilgrimage_route');

    // 1. High contrast dark casing line underneath for visibility over terrain/clouds
    _globeController.addPointConnection(PointConnection(
      id: 'pilgrimage_route_casing',
      start: GlobeCoordinates(userLat, userLng),
      end: GlobeCoordinates(_targetLatitude, _targetLongitude),
      curveScale: 0.12,
      style: PointConnectionStyle(
        type: PointConnectionType.solid,
        color: Colors.black.withAlpha(onTarget ? 220 : 180),
        lineWidth: onTarget ? 7.0 : 5.5,
        animateOnAdd: false,
      ),
    ));

    // 2. Vibrant Geodesic Great-Circle Route line on top
    _globeController.addPointConnection(PointConnection(
      id: 'pilgrimage_route',
      start: GlobeCoordinates(userLat, userLng),
      end: GlobeCoordinates(_targetLatitude, _targetLongitude),
      curveScale: 0.12,
      style: PointConnectionStyle(
        type: PointConnectionType.solid,
        color: onTarget ? const Color(0xFFFFB300) : const Color(0xFF00E5FF),
        lineWidth: onTarget ? 4.5 : 3.2,
        animateOnAdd: false,
      ),
    ));

    // Force animationProgress to 1.0 so flutter_earth_globe GPU painter renders the arc
    for (final c in _globeController.connections) {
      c.animationProgress = 1.0;
    }
  }

  void _handleOnTargetChanged() {
    if (!mounted || _viewMode != CompassViewMode.earth) return;
    final double userLat = (_userLatitude != 0.0)
        ? _userLatitude
        : ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
    final double userLng = (_userLongitude != 0.0)
        ? _userLongitude
        : ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);
    if (userLat != 0.0 || userLng != 0.0) {
      final bool onTarget = _onTargetNotifier.value;
      _addRouteConnections(userLat, userLng, onTarget);
      _updateGlobePointsAndCamera(animateCamera: false);
    }
  }

  void _updateGlobePointsAndCamera({bool animateCamera = true}) {
    if (!mounted) return;

    final double userLat = (_userLatitude != 0.0)
        ? _userLatitude
        : ((Prefs.lat != 1.1) ? Prefs.lat : 0.0);
    final double userLng = (_userLongitude != 0.0)
        ? _userLongitude
        : ((Prefs.lng != 1.1) ? Prefs.lng : 0.0);

    _globeController.removePoint('north_pole');
    _globeController.removePoint('user_location');
    _globeController.removePoint('target_site');
    _globeController.removePointConnection('pilgrimage_route_casing');
    _globeController.removePointConnection('pilgrimage_route');

    final t = AppLocalizations.of(context);
    final String userLabel = t?.yourLocation ?? 'Your Location';
    final String targetLabel = _targetDisplayName(context);
    final bool onTarget = _isWithinLimits();

    // North pole orientation marker
    _globeController.addPoint(Point(
      id: 'north_pole',
      coordinates: const GlobeCoordinates(90, 0),
      label: 'N',
      isLabelVisible: true,
      style: const PointStyle(
        color: Colors.white70,
        size: 0,
        altitude: 0.01,
      ),
      labelBuilder: (context, point, isHovering, isVisible) {
        return AnimatedRotation(
          turns: -_getGlobeRotationTurns(),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1.0),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    ));

    if (userLat != 0.0 || userLng != 0.0) {
      _globeController.addPoint(Point(
        id: 'user_location',
        coordinates: GlobeCoordinates(userLat, userLng),
        label: userLabel,
        isLabelVisible: true,
        style: const PointStyle(
          color: Color(0xFF00E5FF),
          size: 0,
          altitude: 0.02,
        ),
        labelBuilder: (context, point, isHovering, isVisible) {
          return AnimatedRotation(
            turns: -_getGlobeRotationTurns(),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            child: Tooltip(
              message: point.label ?? userLabel,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A).withAlpha(235),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E5FF),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withAlpha(160),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
            ),
          );
        },
      ));
    }

    final String cardinal = _cardinalDirection(_bearing);
    final String distStr = _distance >= 1000
        ? '${(_distance / 1000).toStringAsFixed(1)}k km'
        : '${_distance.toInt()} km';

    _globeController.addPoint(Point(
      id: 'target_site',
      coordinates: GlobeCoordinates(_targetLatitude, _targetLongitude),
      label: targetLabel,
      isLabelVisible: true,
      style: const PointStyle(
        color: Color(0xFFFFB300),
        size: 0,
        altitude: 0.03,
      ),
      labelBuilder: (context, point, isHovering, isVisible) {
        final Color destColor =
            onTarget ? const Color(0xFFFFD54F) : const Color(0xFFFFB300);
        return AnimatedRotation(
          turns: -_getGlobeRotationTurns(),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          child: Tooltip(
            message: '$targetLabel • ${_bearing.toInt()}° $cardinal ($distStr)',
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1300).withAlpha(235),
                shape: BoxShape.circle,
                border: Border.all(
                  color: destColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: destColor.withAlpha(180),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: destColor,
                ),
              ),
            ),
          ),
        );
      },
    ));

    if (userLat != 0.0 || userLng != 0.0) {
      _addRouteConnections(userLat, userLng, onTarget);

      final LatLng midPoint = _calculateMidpoint(
          userLat, userLng, _targetLatitude, _targetLongitude);
      final double targetZoom = _calculateGlobeZoomForDistance(_distance);
      _globeController.setZoom(targetZoom);
      if (animateCamera) {
        try {
          _globeController.focusOnCoordinates(
            GlobeCoordinates(midPoint.latitude, midPoint.longitude),
            animate: true,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        } catch (_) {}
      }
    } else {
      _globeController.setZoom(0.0);
      if (animateCamera) {
        try {
          _globeController.focusOnCoordinates(
            GlobeCoordinates(_targetLatitude, _targetLongitude),
            animate: true,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        } catch (_) {}
      }
    }
  }

  void _updateMapCamera() {
    if (_viewMode != CompassViewMode.map2d ||
        _mapController == null ||
        !mounted) return;
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
      onTap: () => _setViewMode(CompassViewMode.compass),
      child: Tooltip(
        message: AppLocalizations.of(context)?.compassView ?? 'Compass View',
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

  Widget _buildGlobeView() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (_globeController.surface == null) {
      _globeController
          .loadSurface(const AssetImage('assets/images/2k_earth-day.jpg'));
    }

    if (_globeController.points.isEmpty ||
        (_globeController.connections.isEmpty &&
            (_userLatitude != 0.0 || Prefs.lat != 1.1))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _viewMode == CompassViewMode.earth) {
          _updateGlobePointsAndCamera(animateCamera: false);
        }
      });
    }

    final double rotationTurns = _getGlobeRotationTurns();

    return Container(
      width: 290,
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF070B19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: primary.withAlpha(120),
          width: 2.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListenableBuilder(
            listenable: _globeController,
            builder: (context, _) {
              if (_globeController.surface == null) {
                return const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: size),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: AnimatedRotation(
                        turns: rotationTurns,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        child: FlutterEarthGlobe(
                          controller: _globeController,
                          radius: 94.25,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Live Mini Buddhist Compass in Top-Left Corner (tap returns to Compass)
          Positioned(
            top: 8,
            left: 8,
            child: _buildMiniBuddhistCompassWidget(),
          ),
          // Direction Alignment Toggle in Bottom-Left Corner
          Positioned(
            bottom: 10,
            left: 10,
            child: Material(
              color: theme.colorScheme.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _earthAlignWithDirection = !_earthAlignWithDirection;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9.0, vertical: 5.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _earthAlignWithDirection
                            ? Icons.navigation_rounded
                            : Icons.north_rounded,
                        size: 14,
                        color: primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _earthAlignWithDirection ? 'Aligned' : 'North Up',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Controls in Bottom-Right Corner (Zoom In/Out + Recenter)
          Positioned(
            bottom: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Zoom +/- pill
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(220),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withAlpha(80),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          onTap: () {
                            _globeController.setZoom(
                              (_globeController.zoom + 0.35).clamp(
                                  _globeController.minZoom,
                                  _globeController.maxZoom),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        width: 18,
                        color: primary.withAlpha(50),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14)),
                          onTap: () {
                            _globeController.setZoom(
                              (_globeController.zoom - 0.35).clamp(
                                  _globeController.minZoom,
                                  _globeController.maxZoom),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Recenter / Focus Route button
                Material(
                  color: theme.colorScheme.surface.withAlpha(220),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        _updateGlobePointsAndCamera(animateCamera: true),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.center_focus_strong_rounded,
                        size: 18,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapView() {
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
                    if (mounted &&
                        _viewMode == CompassViewMode.map2d &&
                        _mapController == controller) {
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
          // Recenter / Fit Route button in Bottom-Right Corner
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

  Widget _buildMainView() {
    switch (_viewMode) {
      case CompassViewMode.compass:
        return _buildCompass();
      case CompassViewMode.map2d:
        return Listener(
          onPointerDown: _onCardPointerDown,
          onPointerUp: _onCardPointerUp,
          onPointerCancel: _onCardPointerCancel,
          child: _buildGoogleMapView(),
        );
      case CompassViewMode.earth:
        return Listener(
          onPointerDown: _onCardPointerDown,
          onPointerUp: _onCardPointerUp,
          onPointerCancel: _onCardPointerCancel,
          child: _buildGlobeView(),
        );
    }
  }

  Widget _buildViewModeSelector(AppLocalizations t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withAlpha(200)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildModeTab(
            mode: CompassViewMode.compass,
            icon: Icons.explore_rounded,
            label: t.compass,
          ),
          _buildModeTab(
            mode: CompassViewMode.map2d,
            icon: Icons.map_rounded,
            label: 'Map',
          ),
          _buildModeTab(
            mode: CompassViewMode.earth,
            icon: Icons.public_rounded,
            label: 'Globe',
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required CompassViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = (_viewMode == mode);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _setViewMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withAlpha(180),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _appBarIconForMode(CompassViewMode mode) {
    switch (mode) {
      case CompassViewMode.compass:
        return Icons.map_rounded;
      case CompassViewMode.map2d:
        return Icons.public_rounded;
      case CompassViewMode.earth:
        return Icons.explore_rounded;
    }
  }

  String _appBarTooltipForMode(CompassViewMode mode, AppLocalizations t) {
    switch (mode) {
      case CompassViewMode.compass:
        return 'Map';
      case CompassViewMode.map2d:
        return 'Globe';
      case CompassViewMode.earth:
        return t.compass;
    }
  }

  CompassViewMode _getNextViewMode(CompassViewMode current) {
    switch (current) {
      case CompassViewMode.compass:
        return CompassViewMode.map2d;
      case CompassViewMode.map2d:
        return CompassViewMode.earth;
      case CompassViewMode.earth:
        return CompassViewMode.compass;
    }
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
            icon: Icon(_appBarIconForMode(_viewMode)),
            tooltip: _appBarTooltipForMode(_viewMode, t),
            onPressed: () => _setViewMode(_getNextViewMode(_viewMode)),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: t.help,
            onPressed: () => showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: _isInteractingWithCard
            ? const NeverScrollableScrollPhysics()
            : null,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Compass Dial OR 2D Google Map OR 3D Earth Globe
                  (_isLoadingLocation || _isChangingLocation)
                      ? _buildLoadingIndicator()
                      : _buildMainView(),

                  const SizedBox(height: 12),

                  // 2. Alignment & Direction Guidance Badge (Outside the card)
                  _buildAlignmentBadge(),

                  const SizedBox(height: 12),

                  // 3. 3-Way Mode Segmented Control: [ Compass ] [ Map ] [ Globe ]
                  _buildViewModeSelector(t),

                  const SizedBox(height: 16),

                  // 4. Stats Row (Heading, Target Bearing, Distance)
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

                  // 5. Sacred Pilgrimage Site Selector
                  PlaceSelector(
                    key: _placeSelectorKey,
                    onLocationChanged: () {
                      setState(() {
                        _isChangingLocation = true;
                        _targetLatitude = Prefs.targetLat;
                        _targetLongitude = Prefs.targetLong;
                        _bearing = _calculateBearing(_userLatitude,
                            _userLongitude, _targetLatitude, _targetLongitude);
                        _distance = _calculateDistance(_userLatitude,
                            _userLongitude, _targetLatitude, _targetLongitude);
                      });
                      _getLocation(context).then((_) {
                        if (mounted) {
                          setState(() {
                            _isChangingLocation = false;
                          });
                          if (_viewMode != CompassViewMode.compass) {
                            _refreshMapView();
                          }
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // 6. Vibration Toggle Card
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
