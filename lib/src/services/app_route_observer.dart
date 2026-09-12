import 'package:flutter/material.dart';

/// Global [RouteObserver] used to track when modal routes are pushed, popped,
/// or obscured by other screens (e.g., meditation sessions, settings, etc.).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
