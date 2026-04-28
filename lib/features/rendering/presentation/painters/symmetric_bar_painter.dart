import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SymmetricBarPainter extends CustomPainter {
  SymmetricBarPainter({
    required this.fftBars,
    required this.colorStart,
    required this.colorEnd,
    required this.useGradient,
  });

  final List<double> fftBars;
  final Color colorStart;
  final Color colorEnd;
  final bool useGradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (fftBars.isEmpty) return;

    // ── APPLY TRANSFORMATIONS ──────────────────────────────────────
    canvas.save();

    // ── DRAW SYMMETRIC BARS ──────────────────────────────────────────
    final barCount = fftBars.length;
    final totalWidth = size.width * 0.8;
    final startX = (size.width - totalWidth) / 2;
    final barWidth = totalWidth / barCount;
    final padding = barWidth * 0.2;
    final actualBarWidth = barWidth - padding;

    final centerY = size.height / 2;
    final maxHalfHeight = size.height * 0.4;

    for (var i = 0; i < barCount; i++) {
      final value = fftBars[i].clamp(0.0, 1.0);
      final halfHeight = value * maxHalfHeight;
      
      final x = startX + (i * barWidth) + (padding / 2);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x,
          centerY - halfHeight,
          x + actualBarWidth,
          centerY + halfHeight,
        ),
        Radius.circular(actualBarWidth / 2),
      );

      final barPaint = Paint()..style = PaintingStyle.fill;

      if (useGradient) {
        barPaint.shader = ui.Gradient.linear(
          Offset(x, centerY - maxHalfHeight),
          Offset(x, centerY + maxHalfHeight),
          [colorEnd, colorStart, colorEnd],
          [0.0, 0.5, 1.0],
        );
      } else {
        barPaint.color = colorStart;
      }

      // Draw Glow
      if (value > 0.3) {
        final glowPaint = Paint()
          ..color = colorStart.withValues(alpha: 0.2 * value)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawRRect(barRect, glowPaint);
      }

      canvas.drawRRect(barRect, barPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SymmetricBarPainter oldDelegate) {
    return oldDelegate.fftBars != fftBars ||
        oldDelegate.colorStart != colorStart ||
        oldDelegate.colorEnd != colorEnd ||
        oldDelegate.useGradient != useGradient;
  }
}
