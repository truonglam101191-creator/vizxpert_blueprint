import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  BackgroundPainter({
    required this.backgroundColor,
    this.backgroundImage,
  });

  final Color backgroundColor;
  final ui.Image? backgroundImage;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // Draw background image if available
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
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.backgroundImage != backgroundImage;
  }
}
