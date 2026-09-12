import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/services/app_route_observer.dart';

/// A synchronized Google Maps widget that displays the current GPS location
/// and synchronizes its camera bearing with the device's compass.
class CurrentLocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String cityName;
  final double height;
  final double? width;
  final Completer<GoogleMapController>? controllerCompleter;
  final bool isActive;

  const CurrentLocationMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.height = 350.0,
    this.width,
    this.controllerCompleter,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<CurrentLocationMapWidget> createState() =>
      _CurrentLocationMapWidgetState();
}

class _CurrentLocationMapWidgetState extends State<CurrentLocationMapWidget>
    with RouteAware, WidgetsBindingObserver {
  GoogleMapController? _controller;
  StreamSubscription<CompassEvent>? _compassSub;

  late bool _compassTracking;
  late double _currentZoom;
  late MapType _mapType;

  double _currentHeading = 0.0;
  double _lastUpdatedBearing = 0.0;
  DateTime _lastBearingUpdate = DateTime.now();

  bool _isRouteActive = true;
  bool _isAppActive = true;
  bool _subscribedToRoute = false;

  bool get _isScreenVisible =>
      widget.isActive && _isRouteActive && _isAppActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _compassTracking = Prefs.mapCompassSync;
    _currentZoom = Prefs.mapZoomLevel;
    _mapType = (Prefs.mapType == 'normal') ? MapType.normal : MapType.satellite;

    if (_isScreenVisible) {
      _startCompass();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribedToRoute) {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null) {
        appRouteObserver.subscribe(this, modalRoute);
        _subscribedToRoute = true;
        _isRouteActive = modalRoute.isCurrent;
      }
    }
  }

  @override
  void didUpdateWidget(covariant CurrentLocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _recenter(animate: true);
    }
    if (oldWidget.isActive != widget.isActive) {
      _updateTrackingState();
    }
  }

  @override
  void dispose() {
    if (_subscribedToRoute) {
      appRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _compassSub?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  void didPush() {
    _isRouteActive = true;
    _updateTrackingState();
  }

  @override
  void didPushNext() {
    // Another screen was pushed on top (e.g., Meditation)
    _isRouteActive = false;
    _updateTrackingState();
  }

  @override
  void didPopNext() {
    // Returned to this screen
    _isRouteActive = true;
    _updateTrackingState();
  }

  @override
  void didPop() {
    _isRouteActive = false;
    _updateTrackingState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      _updateTrackingState();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      _isAppActive = false;
      _updateTrackingState();
    }
  }

  void _updateTrackingState() {
    if (!mounted) return;
    if (_isScreenVisible) {
      if (_compassTracking && _compassSub == null) {
        _startCompass();
      }
    } else {
      _compassSub?.cancel();
      _compassSub = null;
    }
    setState(() {});
  }

  void _startCompass() {
    _compassSub?.cancel();
    if (!_compassTracking) return;

    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted || !_compassTracking || _controller == null) return;
      final raw = event.heading;
      if (raw == null) return;

      final heading = (raw < 0) ? raw + 360 : raw;
      _currentHeading = heading;

      final now = DateTime.now();
      if (now.difference(_lastBearingUpdate).inMilliseconds < 90) return;

      // Circular angular difference check
      double diff = (heading - _lastUpdatedBearing).abs();
      if (diff > 180) diff = 360 - diff;
      if (diff < 1.5) return; // Prevent micro-jitter

      _lastBearingUpdate = now;
      _lastUpdatedBearing = heading;

      final lat = _validLat(widget.latitude);
      final lng = _validLng(widget.longitude);
      if (lat == 0.0 && lng == 0.0) return;

      try {
        _controller?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: _currentZoom,
              bearing: heading,
            ),
          ),
        );
      } catch (_) {}

      // Update UI heading label
      if (mounted) setState(() {});
    });
  }

  double _validLat(double val) => (val != 1.1) ? val : 0.0;
  double _validLng(double val) => (val != 1.1) ? val : 0.0;

  void _toggleCompassTracking() {
    setState(() {
      _compassTracking = !_compassTracking;
      Prefs.mapCompassSync = _compassTracking;
    });

    if (_compassTracking) {
      if (_isScreenVisible) {
        _startCompass();
      }
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_validLat(widget.latitude), _validLng(widget.longitude)),
            zoom: _currentZoom,
            bearing: _currentHeading,
          ),
        ),
      );
    } else {
      _compassSub?.cancel();
      _compassSub = null;
      // Animate to North Up (0°)
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_validLat(widget.latitude), _validLng(widget.longitude)),
            zoom: _currentZoom,
            bearing: 0.0,
          ),
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _mapType =
          (_mapType == MapType.satellite) ? MapType.normal : MapType.satellite;
      Prefs.mapType = (_mapType == MapType.satellite) ? 'satellite' : 'normal';
    });
  }

  void _recenter({bool animate = true}) {
    final lat = _validLat(widget.latitude);
    final lng = _validLng(widget.longitude);
    if (lat == 0.0 && lng == 0.0) return;

    final target = LatLng(lat, lng);
    final bearing = _compassTracking ? _currentHeading : 0.0;

    final update = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: target,
        zoom: _currentZoom,
        bearing: bearing,
      ),
    );

    if (animate) {
      _controller?.animateCamera(update);
    } else {
      _controller?.moveCamera(update);
    }
  }

  String _getCardinalDirection(double deg) {
    const cardinals = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg + 22.5) % 360 / 45).floor();
    return cardinals[idx % 8];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lat = _validLat(widget.latitude);
    final lng = _validLng(widget.longitude);

    final markers = <Marker>{
      Marker(
        markerId: MarkerId(
            widget.cityName.isNotEmpty ? widget.cityName : 'current_loc'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title:
              widget.cityName.isNotEmpty ? widget.cityName : 'Current Location',
          snippet: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        ),
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.width ?? 420.0,
          maxHeight: widget.height,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _controller = controller;
                    if (widget.controllerCompleter != null &&
                        !widget.controllerCompleter!.isCompleted) {
                      widget.controllerCompleter!.complete(controller);
                    }
                    if (_compassTracking && _isScreenVisible) {
                      _startCompass();
                    }
                  },
                  markers: markers,
                  mapType: _mapType,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  initialCameraPosition: CameraPosition(
                    zoom: _currentZoom,
                    target: LatLng(lat, lng),
                    bearing: _compassTracking ? _currentHeading : 0.0,
                  ),
                  onCameraMove: (position) {
                    _currentZoom = position.zoom;
                    Prefs.mapZoomLevel = position.zoom;
                  },
                ),

                // Live Compass Sync Indicator & Toggle Pill (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Material(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _toggleCompassTracking,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _compassTracking
                                  ? Icons.explore
                                  : Icons.explore_off_outlined,
                              size: 16,
                              color: _compassTracking
                                  ? const Color(0xFFFFB300)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _compassTracking
                                  ? '${_currentHeading.toStringAsFixed(0)}° ${_getCardinalDirection(_currentHeading)}'
                                  : 'North Up',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Action Controls (Bottom Right)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recenter Button
                      Material(
                        color: Colors.black.withOpacity(0.65),
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _recenter(animate: true),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.my_location,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Map Type Switcher Button
                      Material(
                        color: Colors.black.withOpacity(0.65),
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _toggleMapType,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _mapType == MapType.satellite
                                  ? Icons.layers
                                  : Icons.satellite_alt_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
