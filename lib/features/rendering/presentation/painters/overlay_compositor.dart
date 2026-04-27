import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../overlay/domain/overlay_item.dart';
import '../../../overlay/domain/text_overlay.dart';
import '../../../overlay/domain/image_overlay.dart';
import '../../../overlay/domain/shape_overlay.dart';
import '../../../overlay/application/image_cache_service.dart';

/// Paints all overlay items on top of the visualizer canvas.
///
/// Iterates through [overlayItems] sorted by zIndex and delegates
/// to specialised drawing helpers for text, image, and shape types.
class OverlayCompositorPainter extends CustomPainter {
  OverlayCompositorPainter({
    required this.overlayItems,
    required this.canvasSize,
    this.selectedItemId,
  });

  final List<OverlayItem> overlayItems;
  final Size canvasSize;
  final String? selectedItemId;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Overlay items sorted by zIndex ──────────────────────────────
    final sorted = List<OverlayItem>.from(overlayItems);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final item in sorted) {
      if (!item.isVisible) continue;

      canvas.save();

      final rect = item.absoluteRect(size);
      final center = rect.center;

      // Apply rotation around center
      if (item.rotation != 0.0) {
        canvas.translate(center.dx, center.dy);
        canvas.rotate(item.rotation);
        canvas.translate(-center.dx, -center.dy);
      }

      // Apply opacity
      if (item.opacity < 1.0) {
        canvas.saveLayer(
          rect.inflate(20),
          Paint()
            ..color = Color.fromARGB(
              (item.opacity * 255).round(),
              255,
              255,
              255,
            ),
        );
      }

      // Dispatch to type-specific painter
      switch (item.type) {
        case OverlayType.text:
          _drawText(canvas, size, item as TextOverlay, rect);
        case OverlayType.image:
          _drawImage(canvas, size, item as ImageOverlay, rect);
        case OverlayType.shape:
          _drawShape(canvas, size, item as ShapeOverlay, rect);
      }

      if (item.opacity < 1.0) {
        canvas.restore(); // restore saveLayer
      }

      // ── Selection handles ───────────────────────────────────────
      if (item.id == selectedItemId) {
        _drawSelectionHandles(canvas, rect);
      }

      canvas.restore();
    }
  }

  // ── Text ─────────────────────────────────────────────────────────────────

  void _drawText(Canvas canvas, Size size, TextOverlay item, Rect rect) {
    // Shadow
    if (item.hasShadow) {
      final shadowPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontFamily: item.fontFamily,
            fontSize: item.fontSize * (size.width / 1920),
            fontWeight: item.fontWeight,
            color: item.shadowColor,
          ),
        ),
        textAlign: item.textAlign,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      shadowPainter.paint(
        canvas,
        rect.topLeft + item.shadowOffset * (size.width / 1920),
      );
    }

    // Stroke (draw behind text)
    if (item.strokeColor != null && item.strokeWidth > 0) {
      final strokePainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontFamily: item.fontFamily,
            fontSize: item.fontSize * (size.width / 1920),
            fontWeight: item.fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = item.strokeWidth * (size.width / 1920)
              ..color = item.strokeColor!,
          ),
        ),
        textAlign: item.textAlign,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      strokePainter.paint(canvas, rect.topLeft);
    }

    // Main text
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.text,
        style: TextStyle(
          fontFamily: item.fontFamily,
          fontSize: item.fontSize * (size.width / 1920),
          fontWeight: item.fontWeight,
          color: item.textColor,
        ),
      ),
      textAlign: item.textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    // Center vertically within the rect
    final yOffset = (rect.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(rect.left, rect.top + yOffset));
  }

  // ── Image ────────────────────────────────────────────────────────────────

  void _drawImage(Canvas canvas, Size size, ImageOverlay item, Rect rect) {
    final cachedImage = ImageCacheService.instance.getCachedImage(
      item.imagePath,
    );
    if (cachedImage == null) {
      // Draw placeholder while loading
      final placeholderPaint = Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.fill;
      if (item.borderRadius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(item.borderRadius)),
          placeholderPaint,
        );
      } else {
        canvas.drawRect(rect, placeholderPaint);
      }
      // Icon
      final iconPainter = TextPainter(
        text: const TextSpan(text: '🖼', style: TextStyle(fontSize: 24)),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        rect.center - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
      return;
    }

    // Clip to border radius
    if (item.borderRadius > 0) {
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(item.borderRadius)),
      );
    }

    // Draw image fitted to rect
    final src = Rect.fromLTWH(
      0,
      0,
      cachedImage.width.toDouble(),
      cachedImage.height.toDouble(),
    );
    canvas.drawImageRect(cachedImage, src, rect, Paint());

    if (item.borderRadius > 0) {
      canvas.restore();
    }

    // Border
    if (item.borderColor != null && item.borderWidth > 0) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = item.borderColor!
        ..strokeWidth = item.borderWidth;
      if (item.borderRadius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(item.borderRadius)),
          borderPaint,
        );
      } else {
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  // ── Shape ────────────────────────────────────────────────────────────────

  void _drawShape(Canvas canvas, Size size, ShapeOverlay item, Rect rect) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = item.fillColor;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = item.strokeColor
      ..strokeWidth = item.strokeWidth;

    switch (item.shapeType) {
      case ShapeType.rectangle:
        if (item.borderRadius > 0) {
          final rrect = RRect.fromRectAndRadius(
            rect,
            Radius.circular(item.borderRadius),
          );
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
        } else {
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
        }
      case ShapeType.circle:
        final center = rect.center;
        final radius = math.min(rect.width, rect.height) / 2;
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, strokePaint);
      case ShapeType.line:
        canvas.drawLine(
          rect.topLeft,
          rect.bottomRight,
          strokePaint..strokeWidth = math.max(item.strokeWidth, 2.0),
        );
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
    }
  }

  // ── Selection handles ────────────────────────────────────────────────────

  void _drawSelectionHandles(Canvas canvas, Rect rect) {
    // Dashed border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, borderPaint);

    // Corner handles
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6C63FF);
    final handleBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1.5;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (final corner in corners) {
      final handleRect = Rect.fromCenter(
        center: corner,
        width: handleSize,
        height: handleSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
        handlePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
        handleBorderPaint,
      );
    }

    // Mid-edge handles
    final midEdges = [
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
    ];
    for (final mid in midEdges) {
      final handleRect = Rect.fromCenter(center: mid, width: 6, height: 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, const Radius.circular(1)),
        handlePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, const Radius.circular(1)),
        handleBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OverlayCompositorPainter oldDelegate) {
    return overlayItems != oldDelegate.overlayItems ||
        selectedItemId != oldDelegate.selectedItemId;
  }
}
