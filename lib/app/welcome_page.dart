import 'package:flutter/material.dart';

import '../core/theme/monte_theme.dart';
import '../core/ui/monte_logo.dart';

/// Placeholder home while the features are being built.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.monte.brandDeep,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MonteLogo(size: 112, withBackground: false),
          const SizedBox(height: 16),
          Text(
            'monte',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    ),
  );
}
