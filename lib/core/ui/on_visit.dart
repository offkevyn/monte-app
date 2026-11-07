import 'dart:async';

import 'package:flutter/widgets.dart';

/// Why a tab kept alive in an `IndexedStack` came (back) on screen.
enum Visit {
  /// Picked in the bottom bar.
  tab,

  /// The app returned to the foreground while the tab was on screen.
  resume,
}

/// Runs [onVisit] every time [visits] fires, so a screen kept alive in an
/// `IndexedStack` can look for news.
class OnVisit extends StatefulWidget {
  const OnVisit({
    super.key,
    required this.visits,
    required this.onVisit,
    required this.child,
  });

  final Stream<Visit>? visits;
  final void Function(BuildContext context, Visit visit) onVisit;
  final Widget child;

  @override
  State<OnVisit> createState() => _OnVisitState();
}

class _OnVisitState extends State<OnVisit> {
  StreamSubscription<Visit>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.visits?.listen((visit) {
      if (mounted) widget.onVisit(context, visit);
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
