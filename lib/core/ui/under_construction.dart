import 'package:flutter/material.dart';

import '../theme/monte_theme.dart';

/// "Coming soon" popup for bank features outside the scope of the test
/// (Pix, boleto, cards...), so the app feels complete without fake flows.
Future<void> showUnderConstruction(BuildContext context, String feature) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => _UnderConstructionDialog(feature),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );

class _UnderConstructionDialog extends StatelessWidget {
  const _UnderConstructionDialog(this.feature);

  final String feature;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: context.monte.gold.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.construction_rounded,
                    size: 34,
                    color: context.monte.warning,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$feature tá subindo o morro 🏔',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essa parte ainda está em construção. Logo chega por aqui.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: context.monte.subtle),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Beleza'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
