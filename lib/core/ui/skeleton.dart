import 'package:flutter/material.dart';

import '../theme/monte_theme.dart';

/// Placeholder block with a soft moving shine while data loads. Static when
/// the system asks to reduce motion. Hidden from screen readers; the page
/// announces "Carregando" once instead.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.monte.subtle.withValues(alpha: 0.12);
    final light = context.monte.subtle.withValues(alpha: 0.04);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) {
          final t = _shine.value * 3 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(t - 1, 0),
                end: Alignment(t + 1, 0),
                colors: [base, light, base],
              ),
            ),
          );
        },
      ),
    );
  }
}
