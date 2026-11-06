import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Blurs a money value when the balance is hidden. The blur animates in and
/// out (instant with reduce motion), and screen readers hear "oculto"
/// instead of the number.
class SensitiveValue extends StatelessWidget {
  const SensitiveValue({super.key, required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  static const _sigma = 7.0;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return Semantics(
      label: hidden ? 'oculto' : null,
      excludeSemantics: hidden,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: hidden ? _sigma : 0),
        duration: duration,
        builder: (context, sigma, child) => sigma == 0
            ? child!
            : ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: child,
              ),
        child: child,
      ),
    );
  }
}
