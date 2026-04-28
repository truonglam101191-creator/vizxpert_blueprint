import 'package:flutter/material.dart';

import 'overlay_item.dart';

/// Supported shape types.
enum ShapeType { rectangle, circle, line, triangle }

/// A geometric shape overlay on the canvas.
@immutable
class ShapeOverlay extends OverlayItem {
  const ShapeOverlay({
    required super.id,
    super.position,
    super.size = const Size(0.15, 0.15),
    super.rotation,
    super.opacity,
    super.zIndex,
    super.isLocked,
    super.isVisible,
    super.startTimeMs,
    super.endTimeMs,
    this.shapeType = ShapeType.rectangle,
    this.fillColor = const Color(0x44FFFFFF),
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.0,
    this.borderRadius = 0.0,
  }) : super(type: OverlayType.shape);

  final ShapeType shapeType;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  /// Corner radius (applies to rectangle only).
  final double borderRadius;

  @override
  ShapeOverlay copyWith({
    String? id,
    OverlayType? type,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    int? startTimeMs,
    int? endTimeMs,
    ShapeType? shapeType,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    double? borderRadius,
  }) {
    return ShapeOverlay(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      shapeType: shapeType ?? this.shapeType,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}
