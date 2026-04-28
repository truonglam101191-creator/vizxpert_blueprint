import 'package:flutter/material.dart';

import 'overlay_item.dart';

/// An image overlay on the canvas loaded from a local file.
@immutable
class ImageOverlay extends OverlayItem {
  const ImageOverlay({
    required super.id,
    required this.imagePath,
    super.position,
    super.size = const Size(0.25, 0.25),
    super.rotation,
    super.opacity,
    super.zIndex,
    super.isLocked,
    super.isVisible,
    super.startTimeMs,
    super.endTimeMs,
    this.fit = BoxFit.contain,
    this.borderRadius = 0.0,
    this.borderColor,
    this.borderWidth = 0.0,
  }) : super(type: OverlayType.image);

  /// Absolute path to the source image file.
  final String imagePath;

  /// How the image is fitted within its bounding box.
  final BoxFit fit;

  /// Corner radius.
  final double borderRadius;

  /// Optional border colour.
  final Color? borderColor;

  /// Border width in logical pixels.
  final double borderWidth;

  @override
  ImageOverlay copyWith({
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
    String? imagePath,
    BoxFit? fit,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
  }) {
    return ImageOverlay(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      fit: fit ?? this.fit,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}
