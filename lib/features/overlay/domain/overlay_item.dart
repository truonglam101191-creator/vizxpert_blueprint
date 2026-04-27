import 'package:flutter/material.dart';

/// Types of overlay items that can be placed on the canvas.
enum OverlayType {
  text,
  image,
  shape,
  visualizer,
}

/// Base model for every overlay item on the canvas.
///
/// Positions and sizes are stored as **normalized fractions** (0.0–1.0)
/// relative to the canvas dimensions, so they scale with resolution changes.
@immutable
class OverlayItem {
  const OverlayItem({
    required this.id,
    required this.type,
    this.position = const Offset(0.1, 0.1),
    this.size = const Size(0.3, 0.15),
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Type discriminator used by the compositor.
  final OverlayType type;

  /// Top-left position as fraction of canvas (0.0–1.0).
  final Offset position;

  /// Width × height as fraction of canvas (0.0–1.0).
  final Size size;

  /// Rotation angle in radians.
  final double rotation;

  /// Opacity (0.0 = invisible, 1.0 = fully opaque).
  final double opacity;

  /// Drawing order. Higher = on top.
  final int zIndex;

  /// If true, the item cannot be moved or edited.
  final bool isLocked;

  /// If false, the item is hidden on canvas and in export.
  final bool isVisible;

  /// Convenience: absolute rect given a canvas [canvasSize].
  Rect absoluteRect(Size canvasSize) {
    return Rect.fromLTWH(
      position.dx * canvasSize.width,
      position.dy * canvasSize.height,
      size.width * canvasSize.width,
      size.height * canvasSize.height,
    );
  }

  OverlayItem copyWith({
    String? id,
    OverlayType? type,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return OverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
