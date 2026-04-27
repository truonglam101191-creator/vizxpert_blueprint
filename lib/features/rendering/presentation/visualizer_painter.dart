import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../workspace/providers/ui_config_provider.dart';
import 'painters/bar_painter.dart';
import 'painters/circular_painter.dart';
import 'painters/symmetric_bar_painter.dart';
import 'painters/wave_painter.dart';

/// Factory that selects the correct [CustomPainter] based on [UIConfigState].
///
/// Usage:
/// ```dart
/// CustomPaint(
///   painter: VisualizerPainterFactory.create(
///     config: uiConfig,
///     fftBars: fftState.bars,
///     rotationAngle: angle,
///   ),
///   size: Size.infinite,
/// )
/// ```
abstract final class VisualizerPainterFactory {
  static CustomPainter create({
    required UIConfigState config,
    required List<double> fftBars,
    double rotationAngle = 0.0,
    ui.Image? backgroundImage,
  }) {
    switch (config.visualizerType) {
      case VisualizerType.bars:
        return BarVisualizerPainter(
          fftBars: fftBars,
          colorStart: config.barColorStart,
          colorEnd: config.barColorEnd,
          useGradient: config.useGradient,
          backgroundColor: config.backgroundColor,
          backgroundImage: backgroundImage,
          scale: config.visualizerScale,
          position: config.visualizerPosition,
        );
      case VisualizerType.circular:
        return CircularVisualizerPainter(
          fftBars: fftBars,
          colorStart: config.barColorStart,
          colorEnd: config.barColorEnd,
          useGradient: config.useGradient,
          backgroundColor: config.backgroundColor,
          rotationAngle: rotationAngle,
          backgroundImage: backgroundImage,
          scale: config.visualizerScale,
          position: config.visualizerPosition,
        );
      case VisualizerType.symmetricBars:
        return SymmetricBarPainter(
          fftBars: fftBars,
          colorStart: config.barColorStart,
          colorEnd: config.barColorEnd,
          useGradient: config.useGradient,
          backgroundColor: config.backgroundColor,
          backgroundImage: backgroundImage,
          scale: config.visualizerScale,
          position: config.visualizerPosition,
        );
      case VisualizerType.wave:
        return WaveVisualizerPainter(
          fftBars: fftBars,
          colorStart: config.barColorStart,
          colorEnd: config.barColorEnd,
          useGradient: config.useGradient,
          backgroundColor: config.backgroundColor,
          backgroundImage: backgroundImage,
          scale: config.visualizerScale,
          position: config.visualizerPosition,
        );
    }
  }
}
