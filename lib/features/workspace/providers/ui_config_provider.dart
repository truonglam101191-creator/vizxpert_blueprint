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
    this.backgroundColor = AppColors.scaffold,
    this.resolution = AppConstants.defaultResolution,
    this.fps = AppConstants.defaultFps,
    this.backgroundPresetKey = 'Midnight',
  });

  final Color backgroundColor;
  final Size resolution;
  final int fps;
  final String backgroundPresetKey;

  UIConfigState copyWith({
    Color? backgroundColor,
    Size? resolution,
    int? fps,
    String? backgroundPresetKey,
  }) {
    return UIConfigState(
      backgroundColor: backgroundColor ?? this.backgroundColor,
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

  void setBackgroundColor(Color c, {String? presetKey}) =>
      state = state.copyWith(
        backgroundColor: c,
        backgroundPresetKey: presetKey ?? state.backgroundPresetKey,
      );

  void setResolution(Size v) => state = state.copyWith(resolution: v);

  void setFps(int v) => state = state.copyWith(fps: v);
}

// ─── Provider ───────────────────────────────────────────────────────────────

final uiConfigProvider = NotifierProvider<UIConfigNotifier, UIConfigState>(
  UIConfigNotifier.new,
);
