import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Modular 6 also defines context.read/watch; the bloc ones are used here.
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../../app/routes.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/ui/monte_logo.dart';
import '../login/login_page.dart';
import 'splash_cubit.dart';

/// The ridge draws itself, the coin drops into the sky, then the name and
/// the slogan appear. Meanwhile [SplashCubit] decides where to go; the app
/// moves on when both are done. With "reduce motion" on, it is static.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<SplashCubit>()..start(),
    child: const _SplashView(),
  );
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _name = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
  );
  late final Animation<double> _slogan = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.7, 1, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goWhenReady(SplashState state) async {
    if (state is SplashChecking) return;
    if (!_controller.isCompleted) {
      await _controller.forward().orCancel.catchError((Object _) {});
    }
    if (!mounted) return;
    switch (state) {
      case SplashGoHome():
        Modular.to.navigate(Routes.home);
      case SplashGoToLogin(:final lastCpf):
        Modular.to.navigate(
          Routes.login,
          arguments: LoginArgs(lastCpf: lastCpf),
        );
      case SplashChecking():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocListener<SplashCubit, SplashState>(
      listener: (_, state) => _goWhenReady(state),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: context.monte.brandDeep,
          body: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MonteLogo(
                    size: 120,
                    withBackground: false,
                    progress: _logo.value,
                  ),
                  const SizedBox(height: 14),
                  _Reveal(
                    progress: _name.value,
                    child: Text(
                      'monte',
                      style: text.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Reveal(
                    progress: _slogan.value,
                    child: Text(
                      'seu dinheiro em outro patamar',
                      style: text.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades in while sliding up a few pixels.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress,
    child: Transform.translate(
      offset: Offset(0, 10 * (1 - progress)),
      child: child,
    ),
  );
}
