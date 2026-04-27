import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';

// ─── Visualizer Type ────────────────────────────────────────────────────────

enum VisualizerType {
  bars,
  circular,
  symmetricBars,
  wave,
}

// ─── State ──────────────────────────────────────────────────────────────────

@immutable
class UIConfigState {
  const UIConfigState({
    this.visualizerType = VisualizerType.bars,
    this.barCount = AppConstants.defaultBarCount,
    this.intensity = AppConstants.defaultIntensity,
    this.smoothing = AppConstants.defaultSmoothing,
    this.backgroundColor = AppColors.scaffold,
    this.barColorStart = AppColors.barStart,
    this.barColorEnd = AppColors.barEnd,
    this.useGradient = true,
    this.resolution = AppConstants.defaultResolution,
    this.fps = AppConstants.defaultFps,
    this.backgroundPresetKey = 'Midnight',
    this.visualizerScale = 1.0,
    this.visualizerPosition = Offset.zero,
    this.autoRotate = true,
  });

  final VisualizerType visualizerType;
  final int barCount;
  final double intensity;
  final double smoothing;
  final Color backgroundColor;
  final Color barColorStart;
  final Color barColorEnd;
  final bool useGradient;
  final Size resolution;
  final int fps;
  final String backgroundPresetKey;
  final double visualizerScale;
  final Offset visualizerPosition;
  final bool autoRotate;

  UIConfigState copyWith({
    VisualizerType? visualizerType,
    int? barCount,
    double? intensity,
    double? smoothing,
    Color? backgroundColor,
    Color? barColorStart,
    Color? barColorEnd,
    bool? useGradient,
    Size? resolution,
    int? fps,
    String? backgroundPresetKey,
    double? visualizerScale,
    Offset? visualizerPosition,
    bool? autoRotate,
  }) {
    return UIConfigState(
      visualizerType: visualizerType ?? this.visualizerType,
      barCount: barCount ?? this.barCount,
      intensity: intensity ?? this.intensity,
      smoothing: smoothing ?? this.smoothing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barColorStart: barColorStart ?? this.barColorStart,
      barColorEnd: barColorEnd ?? this.barColorEnd,
      useGradient: useGradient ?? this.useGradient,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      backgroundPresetKey: backgroundPresetKey ?? this.backgroundPresetKey,
      visualizerScale: visualizerScale ?? this.visualizerScale,
      visualizerPosition: visualizerPosition ?? this.visualizerPosition,
      autoRotate: autoRotate ?? this.autoRotate,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class UIConfigNotifier extends Notifier<UIConfigState> {
  @override
  UIConfigState build() => const UIConfigState();

  void setVisualizerType(VisualizerType type) =>
      state = state.copyWith(visualizerType: type);

  void setBarCount(int count) => state = state.copyWith(barCount: count);

  void setIntensity(double v) => state = state.copyWith(intensity: v);

  void setSmoothing(double v) => state = state.copyWith(smoothing: v);

  void setBackgroundColor(Color c, {String? presetKey}) =>
      state = state.copyWith(
        backgroundColor: c,
        backgroundPresetKey: presetKey ?? state.backgroundPresetKey,
      );

  void setBarColorStart(Color c) => state = state.copyWith(barColorStart: c);
  void setBarColorEnd(Color c) => state = state.copyWith(barColorEnd: c);

  void setUseGradient(bool v) => state = state.copyWith(useGradient: v);

  void setResolution(Size r) => state = state.copyWith(resolution: r);

  void setFps(int v) => state = state.copyWith(fps: v);

  void setVisualizerScale(double v) =>
      state = state.copyWith(visualizerScale: v);

  void setVisualizerPosition(Offset v) =>
      state = state.copyWith(visualizerPosition: v);

  void setAutoRotate(bool v) => state = state.copyWith(autoRotate: v);
}

// ─── Provider ───────────────────────────────────────────────────────────────

final uiConfigProvider = NotifierProvider<UIConfigNotifier, UIConfigState>(
  UIConfigNotifier.new,
);
