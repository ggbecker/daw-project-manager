import 'package:flutter/material.dart';

/// Global route observer — registered in MaterialApp so any widget can mix in
/// [RouteAware] and get notified when routes are pushed/popped on top of them.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
