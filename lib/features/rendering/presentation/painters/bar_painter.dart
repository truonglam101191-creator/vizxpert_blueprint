import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints vertical bars that respond to FFT data.
///
/// Features:
/// - Rounded-top bars with gradient fill
/// - Subtle glow shadow behind each bar
/// - Mirror reflection at the bottom (30 % opacity)
class BarVisualizerPainter extends CustomPainter {
  BarVisualizerPainter({
    required this.fftBars,
    required this.colorStart,
    required this.colorEnd,
    required this.useGradient,
    this.backgroundColor,
  });

  final List<double> fftBars;
  final Color colorStart;
  final Color colorEnd;
  final bool useGradient;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ──────────────────────────────────────────────────
    if (backgroundColor != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = backgroundColor!,
      );
    }

    if (fftBars.isEmpty) return;

    final barCount = fftBars.length;
    final totalGapRatio = 0.3; // 30 % of width is gaps
    final totalBarWidth = size.width * (1 - totalGapRatio);
    final barWidth = totalBarWidth / barCount;
    final gap = (size.width * totalGapRatio) / (barCount + 1);
    final maxBarHeight = size.height * 0.75;
    final baselineY = size.height * 0.65; // bars sit above this line
    final cornerRadius = math.min(barWidth * 0.4, 4.0);

    for (var i = 0; i < barCount; i++) {
      final value = fftBars[i].clamp(0.0, 1.0);
      final barHeight = math.max(value * maxBarHeight, 2.0);
      final x = gap + i * (barWidth + gap);
      final y = baselineY - barHeight;

      // ── Gradient / solid paint ────────────────────────────────────
      final paint = Paint()..style = PaintingStyle.fill;
      if (useGradient) {
        paint.shader = ui.Gradient.linear(
          Offset(x, baselineY),
          Offset(x, y),
          [colorStart, colorEnd],
        );
      } else {
        paint.color = colorStart;
      }

      // ── Glow shadow ──────────────────────────────────────────────
      final glowPaint = Paint()
        ..color = colorStart.withValues(alpha: 0.25 * value)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final glowRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - 2, y - 2, barWidth + 4, barHeight + 4),
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.circular(cornerRadius),
      );
      canvas.drawRRect(glowRect, glowPaint);

      // ── Main bar ─────────────────────────────────────────────────
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.circular(cornerRadius),
      );
      canvas.drawRRect(barRect, paint);

      // ── Mirror reflection ────────────────────────────────────────
      final reflectionHeight = barHeight * 0.35;
      final reflPaint = Paint()..style = PaintingStyle.fill;
      if (useGradient) {
        reflPaint.shader = ui.Gradient.linear(
          Offset(x, baselineY),
          Offset(x, baselineY + reflectionHeight),
          [
            colorStart.withValues(alpha: 0.25),
            colorStart.withValues(alpha: 0.0),
          ],
        );
      } else {
        reflPaint.shader = ui.Gradient.linear(
          Offset(x, baselineY),
          Offset(x, baselineY + reflectionHeight),
          [
            colorStart.withValues(alpha: 0.25),
            colorStart.withValues(alpha: 0.0),
          ],
        );
      }
      final reflRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, baselineY, barWidth, reflectionHeight),
        bottomLeft: Radius.circular(cornerRadius),
        bottomRight: Radius.circular(cornerRadius),
      );
      canvas.drawRRect(reflRect, reflPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BarVisualizerPainter oldDelegate) {
    return !_listEquals(fftBars, oldDelegate.fftBars) ||
        colorStart != oldDelegate.colorStart ||
        colorEnd != oldDelegate.colorEnd;
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
