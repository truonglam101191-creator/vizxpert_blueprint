import 'package:flutter/material.dart';

import 'overlay_item.dart';

/// A text label overlay on the canvas.
@immutable
class TextOverlay extends OverlayItem {
  const TextOverlay({
    required super.id,
    super.position,
    super.size = const Size(0.35, 0.1),
    super.rotation,
    super.opacity,
    super.zIndex,
    super.isLocked,
    super.isVisible,
    this.text = 'Your Text',
    this.fontFamily = 'Inter',
    this.fontSize = 48.0,
    this.fontWeight = FontWeight.w700,
    this.textColor = Colors.white,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.textAlign = TextAlign.center,
    this.hasShadow = true,
    this.shadowColor = Colors.black54,
    this.shadowOffset = const Offset(2, 2),
    this.shadowBlur = 4.0,
  }) : super(type: OverlayType.text);

  final String text;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color? strokeColor;
  final double strokeWidth;
  final TextAlign textAlign;
  final bool hasShadow;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;

  @override
  TextOverlay copyWith({
    String? id,
    OverlayType? type,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    String? text,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? strokeColor,
    double? strokeWidth,
    TextAlign? textAlign,
    bool? hasShadow,
    Color? shadowColor,
    Offset? shadowOffset,
    double? shadowBlur,
  }) {
    return TextOverlay(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      textAlign: textAlign ?? this.textAlign,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      shadowBlur: shadowBlur ?? this.shadowBlur,
    );
  }
}
