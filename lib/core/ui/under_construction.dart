import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
                const BuildingMonte(),
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
                  'Essa função chega numa próxima versão do Monte. Enquanto isso, '
                  'dá uma olhada no seu extrato.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: context.monte.subtle),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Monte logo drawing itself (a Lottie made for the app, see
/// `tool/make_under_construction_lottie.py`): the mountain is still being
/// built. Plays once; with "remove animations" on, it shows the last frame.
class BuildingMonte extends StatefulWidget {
  const BuildingMonte({super.key, this.size = 96});

  static const asset = 'assets/lottie/under_construction.json';

  final double size;

  @override
  State<BuildingMonte> createState() => _BuildingMonteState();
}

class _BuildingMonteState extends State<BuildingMonte>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Lottie.asset(
      BuildingMonte.asset,
      controller: _controller,
      width: widget.size,
      height: widget.size,
      onLoaded: _start,
      // Never leaves a hole in the popup if the asset fails to load.
      errorBuilder: (context, _, _) => Icon(
        Icons.construction_rounded,
        size: widget.size * 0.5,
        color: context.monte.warning,
      ),
    ),
  );
}
