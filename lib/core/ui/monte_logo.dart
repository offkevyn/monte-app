import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// The Monte mark: a mountain whose last ridge turns into a chart arrow, with
/// the gold coin in the sky.
///
/// Drawn in code (no image asset) so it stays sharp at any size and can be
/// animated: [progress] goes from 0 (nothing drawn) to 1 (complete), which
/// the splash screen uses to "draw" the ridge.
class MonteLogo extends StatelessWidget {
  const MonteLogo({
    super.key,
    this.size = 96,
    this.withBackground = true,
    this.progress = 1,
  });

  final double size;

  /// Rounded dark-green square behind the mark, as in the app icon.
  final bool withBackground;

  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Monte',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _MonteLogoPainter(
        withBackground: withBackground,
        progress: progress.clamp(0, 1),
      ),
    ),
  );
}

class _MonteLogoPainter extends CustomPainter {
  _MonteLogoPainter({required this.withBackground, required this.progress});

  final bool withBackground;
  final double progress;

  static const _deep = Color(0xFF0B3D2A);
  static const _mountain = Color(0xFF1A7A50);
  static const _gold = Color(0xFFF5C531);
  static const _ridge = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinates follow the 120x120 SVG approved in the brand page.
    canvas.scale(size.width / 120, size.height / 120);

    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 120, 120),
          const Radius.circular(28),
        ),
        Paint()..color = _deep,
      );
    }

    final mountain = Path()
      ..moveTo(16, 94)
      ..lineTo(44, 50)
      ..lineTo(60, 72)
      ..lineTo(84, 36)
      ..lineTo(104, 94)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = _mountain.withValues(alpha: progress),
    );

    final stroke = Paint()
      ..color = _ridge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ridge = Path()
      ..moveTo(16, 94)
      ..lineTo(44, 50)
      ..lineTo(60, 72)
      ..lineTo(84, 36);
    final arrowHead = Path()
      ..moveTo(71, 35)
      ..lineTo(85, 34)
      ..lineTo(86, 48);

    // The ridge takes the first 80% of the animation, the arrow head the rest.
    _drawPartial(canvas, ridge, stroke, (progress / 0.8).clamp(0, 1));
    _drawPartial(
      canvas,
      arrowHead,
      stroke,
      ((progress - 0.8) / 0.2).clamp(0, 1),
    );

    canvas.drawCircle(
      const Offset(36, 30),
      9 * Curves.easeOutBack.transform(progress),
      Paint()..color = _gold,
    );
  }

  void _drawPartial(Canvas canvas, Path path, Paint paint, double fraction) {
    if (fraction <= 0) return;
    if (fraction >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * fraction;
    for (final PathMetric metric in metrics) {
      if (remaining <= 0) break;
      final length = remaining.clamp(0, metric.length).toDouble();
      canvas.drawPath(metric.extractPath(0, length), paint);
      remaining -= length;
    }
  }

  @override
  bool shouldRepaint(_MonteLogoPainter old) =>
      old.progress != progress || old.withBackground != withBackground;
}
