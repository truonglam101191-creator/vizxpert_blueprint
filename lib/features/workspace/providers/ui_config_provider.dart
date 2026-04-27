import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';

// ─── Visualizer Type ────────────────────────────────────────────────────────

enum VisualizerType { bars, circular }

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

  void setBackgroundColor(Color c, {String? presetKey}) => state = state.copyWith(
        backgroundColor: c,
        backgroundPresetKey: presetKey ?? state.backgroundPresetKey,
      );

  void setBarColorStart(Color c) => state = state.copyWith(barColorStart: c);
  void setBarColorEnd(Color c) => state = state.copyWith(barColorEnd: c);

  void setUseGradient(bool v) => state = state.copyWith(useGradient: v);

  void setResolution(Size r) => state = state.copyWith(resolution: r);

  void setFps(int v) => state = state.copyWith(fps: v);
}

// ─── Provider ───────────────────────────────────────────────────────────────

final uiConfigProvider =
    NotifierProvider<UIConfigNotifier, UIConfigState>(UIConfigNotifier.new);
