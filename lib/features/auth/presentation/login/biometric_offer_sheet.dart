import 'package:flutter/material.dart';

import '../../../../core/theme/monte_theme.dart';
import 'login_cubit.dart';

/// Asked once, right after the first login.
Future<void> showBiometricOfferSheet(BuildContext context, LoginCubit cubit) =>
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        // Scrolls on short screens or with large fonts instead of cutting
        // the buttons off.
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: context.monte.chip,
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 44,
                    color: context.monte.brand,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Entrar com a digital?',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Na próxima vez, é só encostar o dedo. Você também pode usar '
                  'a digital pra mostrar o saldo.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: context.monte.subtle),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('biometrics.accept'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.acceptBiometrics();
                  },
                  child: const Text('Usar digital'),
                ),
                TextButton(
                  key: const Key('biometrics.decline'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.declineBiometrics();
                  },
                  child: const Text('Agora não'),
                ),
              ],
            ),
          ),
        );
      },
    );
