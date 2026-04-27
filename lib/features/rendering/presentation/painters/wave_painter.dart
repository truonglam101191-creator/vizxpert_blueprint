import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WaveVisualizerPainter extends CustomPainter {
  WaveVisualizerPainter({
    required this.fftBars,
    required this.colorStart,
    required this.colorEnd,
    required this.useGradient,
    required this.backgroundColor,
    this.backgroundImage,
    this.scale = 1.0,
    this.position = Offset.zero,
  });

  final List<double> fftBars;
  final Color colorStart;
  final Color colorEnd;
  final bool useGradient;
  final Color backgroundColor;
  final ui.Image? backgroundImage;
  final double scale;
  final Offset position;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // 2. Draw background image (if any)
    if (backgroundImage != null) {
      final imgWidth = backgroundImage!.width.toDouble();
      final imgHeight = backgroundImage!.height.toDouble();
      final imgRatio = imgWidth / imgHeight;
      final canvasRatio = size.width / size.height;

      double drawWidth, drawHeight;
      if (imgRatio > canvasRatio) {
        drawHeight = size.height;
        drawWidth = size.height * imgRatio;
      } else {
        drawWidth = size.width;
        drawHeight = size.width / imgRatio;
      }

      final drawRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: drawWidth,
        height: drawHeight,
      );

      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, imgWidth, imgHeight),
        drawRect,
        Paint(),
      );
    }

    if (fftBars.isEmpty) return;

    // ── APPLY TRANSFORMATIONS ──────────────────────────────────────
    canvas.save();

    final absPosition = Offset(
      position.dx * size.width,
      position.dy * size.height,
    );
    canvas.translate(absPosition.dx, absPosition.dy);
    final pivot = Offset(size.width / 2, size.height / 2);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(scale);
    canvas.translate(-pivot.dx, -pivot.dy);

    // ── DRAW WAVE ──────────────────────────────────────────────────
    // Create a smooth, symmetric wave from the center out, or just left to right
    // Let's do a symmetric wave left-to-right (Bass in the middle, treble on edges)
    final mirroredBars = [...fftBars.reversed, ...fftBars];
    final barCount = mirroredBars.length;
    
    final totalWidth = size.width;
    final stepX = totalWidth / (barCount - 1);
    
    final startY = size.height * 0.8;
    final maxWaveHeight = size.height * 0.4;

    final path = Path();
    path.moveTo(0, startY);

    final points = <Offset>[];
    for (var i = 0; i < barCount; i++) {
      final value = mirroredBars[i].clamp(0.0, 1.0);
      final x = i * stepX;
      final y = startY - (value * maxWaveHeight);
      points.add(Offset(x, y));
    }

    // Smooth curve using cubic bezier
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Close path to create a solid fill at the bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()..style = PaintingStyle.fill;

    if (useGradient) {
      paint.shader = ui.Gradient.linear(
        Offset(0, startY - maxWaveHeight),
        Offset(0, size.height),
        [colorStart.withValues(alpha: 0.8), colorEnd.withValues(alpha: 0.2)],
      );
    } else {
      paint.color = colorStart.withValues(alpha: 0.6);
    }

    // Draw solid wave
    canvas.drawPath(path, paint);

    // Draw the top line of the wave for extra sharpness
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = colorStart
      ..strokeCap = StrokeCap.round;

    // Draw glow for the top line
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = colorStart.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WaveVisualizerPainter oldDelegate) {
    return oldDelegate.fftBars != fftBars ||
        oldDelegate.colorStart != colorStart ||
        oldDelegate.colorEnd != colorEnd ||
        oldDelegate.useGradient != useGradient ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.scale != scale ||
        oldDelegate.position != position;
  }
}
