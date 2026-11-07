import 'dart:async';

import 'package:flutter/widgets.dart';

/// Runs [onVisit] every time [visits] fires: the tab was picked again, or
/// the app came back to the foreground while it was on screen. Lets a
/// screen kept alive in an `IndexedStack` look for news.
class OnVisit extends StatefulWidget {
  const OnVisit({
    super.key,
    required this.visits,
    required this.onVisit,
    required this.child,
  });

  final Stream<void>? visits;
  final void Function(BuildContext context) onVisit;
  final Widget child;

  @override
  State<OnVisit> createState() => _OnVisitState();
}

class _OnVisitState extends State<OnVisit> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.visits?.listen((_) {
      if (mounted) widget.onVisit(context);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
