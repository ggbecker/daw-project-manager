import 'package:flutter/material.dart';

/// Global route observer — registered in MaterialApp so any widget can mix in
/// [RouteAware] and get notified when routes are pushed/popped on top of them.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Tracks whether this route is currently the topmost (visible, interactive)
/// one, via [appRouteObserver]. Mix into any State that owns a
/// desktop_drop `DropTarget` and pass [dropTargetEnabled] as that
/// DropTarget's `enable:` argument.
///
/// desktop_drop's DropTarget keeps receiving drag events even while fully
/// covered by a pushed route — its own doc comment warns about this
/// (https://github.com/MixinNetwork/flutter-plugins/issues/2). Left
/// unhandled, that means: push a route with its own DropTarget (e.g.
/// dashboard -> project detail), and both DropTargets react to the same
/// drop simultaneously, corrupting desktop_drop's internal hover
/// state-machine — which then leaves the dashboard's DropTarget stuck
/// non-functional even after returning to it, not just the covered one.
mixin RouteAwareDropTargetState<T extends StatefulWidget> on State<T>
    implements RouteAware {
  bool dropTargetEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {
    if (mounted) setState(() => dropTargetEnabled = false);
  }

  @override
  void didPopNext() {
    if (mounted) setState(() => dropTargetEnabled = true);
  }
}
