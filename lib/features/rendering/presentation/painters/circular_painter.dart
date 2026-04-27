import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints bars radiating outward from a central circle.
///
/// Features:
/// - Bars extend from a centre ring outward, length driven by FFT values
/// - Gradient fill per bar, glow halo around centre
/// - Subtle centre‐circle pulse effect based on average energy
class CircularVisualizerPainter extends CustomPainter {
  CircularVisualizerPainter({
    required this.fftBars,
    required this.colorStart,
    required this.colorEnd,
    required this.useGradient,
    this.backgroundColor,
    this.rotationAngle = 0.0,
  });

  final List<double> fftBars;
  final Color colorStart;
  final Color colorEnd;
  final bool useGradient;
  final Color? backgroundColor;
  final double rotationAngle;

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

    final centre = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height);
    final innerRadius = minSide * 0.12;
    final maxBarLength = minSide * 0.30;
    final barCount = fftBars.length;
    final angleStep = (2 * math.pi) / barCount;

    // Average energy for pulse
    final avgEnergy =
        fftBars.fold<double>(0.0, (sum, v) => sum + v) / barCount;

    // ── Centre glow ─────────────────────────────────────────────────
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        centre,
        innerRadius * (1.0 + avgEnergy * 0.5),
        [
          colorStart.withValues(alpha: 0.15 + avgEnergy * 0.15),
          colorStart.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(
      centre,
      innerRadius * (1.5 + avgEnergy * 0.3),
      glowPaint,
    );

    // ── Centre circle ───────────────────────────────────────────────
    final pulsedRadius = innerRadius * (1.0 + avgEnergy * 0.08);
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = colorStart.withValues(alpha: 0.6);
    canvas.drawCircle(centre, pulsedRadius, circlePaint);

    // ── Bars ────────────────────────────────────────────────────────
    for (var i = 0; i < barCount; i++) {
      final value = fftBars[i].clamp(0.0, 1.0);
      final barLength = math.max(value * maxBarLength, 1.5);
      final angle = i * angleStep + rotationAngle;

      final startX = centre.dx + math.cos(angle) * pulsedRadius;
      final startY = centre.dy + math.sin(angle) * pulsedRadius;
      final endX = centre.dx + math.cos(angle) * (pulsedRadius + barLength);
      final endY = centre.dy + math.sin(angle) * (pulsedRadius + barLength);

      final barPaint = Paint()
        ..strokeWidth = math.max(2.0, (2 * math.pi * pulsedRadius) / barCount * 0.5)
        ..strokeCap = StrokeCap.round;

      if (useGradient) {
        barPaint.shader = ui.Gradient.linear(
          Offset(startX, startY),
          Offset(endX, endY),
          [colorStart, colorEnd],
        );
      } else {
        barPaint.color = colorStart;
      }

      // Glow
      if (value > 0.3) {
        final glowBarPaint = Paint()
          ..strokeWidth = barPaint.strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..color = colorStart.withValues(alpha: 0.15 * value)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          glowBarPaint,
        );
      }

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularVisualizerPainter oldDelegate) {
    return !_listEquals(fftBars, oldDelegate.fftBars) ||
        colorStart != oldDelegate.colorStart ||
        colorEnd != oldDelegate.colorEnd ||
        rotationAngle != oldDelegate.rotationAngle;
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
