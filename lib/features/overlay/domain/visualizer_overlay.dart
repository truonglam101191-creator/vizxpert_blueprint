import 'package:flutter/material.dart';
import '../../workspace/providers/ui_config_provider.dart'; // For VisualizerType
import 'overlay_item.dart';

@immutable
class VisualizerOverlay extends OverlayItem {
  const VisualizerOverlay({
    required super.id,
    super.type = OverlayType.visualizer,
    super.position = Offset.zero,
    super.size = const Size(1.0, 1.0),
    super.rotation = 0.0,
    super.opacity = 1.0,
    super.zIndex = 0,
    super.isLocked = false,
    super.isVisible = true,
    super.startTimeMs,
    super.endTimeMs,
    required this.visualizerType,
    this.barCount = 64,
    this.intensity = 1.0,
    this.smoothing = 0.5,
    this.colorStart = const Color(0xFF6200EE),
    this.colorEnd = const Color(0xFF03DAC6),
    this.useGradient = true,
    this.autoRotate = true,
  });

  final VisualizerType visualizerType;
  final int barCount;
  final double intensity;
  final double smoothing;
  final Color colorStart;
  final Color colorEnd;
  final bool useGradient;
  final bool autoRotate;

  @override
  VisualizerOverlay copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    int? startTimeMs,
    int? endTimeMs,
    OverlayType? type, // Added to match OverlayItem signature
    VisualizerType? visualizerType,
    int? barCount,
    double? intensity,
    double? smoothing,
    Color? colorStart,
    Color? colorEnd,
    bool? useGradient,
    bool? autoRotate,
  }) {
    return VisualizerOverlay(
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
      visualizerType: visualizerType ?? this.visualizerType,
      barCount: barCount ?? this.barCount,
      intensity: intensity ?? this.intensity,
      smoothing: smoothing ?? this.smoothing,
      colorStart: colorStart ?? this.colorStart,
      colorEnd: colorEnd ?? this.colorEnd,
      useGradient: useGradient ?? this.useGradient,
      autoRotate: autoRotate ?? this.autoRotate,
    );
  }
}
