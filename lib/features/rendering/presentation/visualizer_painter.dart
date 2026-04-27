import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../workspace/providers/ui_config_provider.dart';
import '../../overlay/domain/visualizer_overlay.dart';
import 'painters/bar_painter.dart';
import 'painters/circular_painter.dart';
import 'painters/symmetric_bar_painter.dart';
import 'painters/wave_painter.dart';

/// Factory that selects the correct [CustomPainter] based on [VisualizerOverlay].
abstract final class VisualizerPainterFactory {
  static CustomPainter create({
    required VisualizerOverlay item,
    required List<double> fftBars,
    double timeInSeconds = 0.0,
  }) {
    // 1. Resample from 256 to item.barCount
    List<double> resampled = fftBars;
    if (fftBars.isNotEmpty && fftBars.length != item.barCount && item.barCount > 0) {
      resampled = List.generate(item.barCount, (i) {
        final srcIdx = (i * fftBars.length / item.barCount).floor();
        return fftBars[srcIdx.clamp(0, fftBars.length - 1)];
      });
    }

    // 2. Apply intensity
    final adjustedBars = resampled.map((v) => (v * item.intensity).clamp(0.0, 1.0)).toList();
    
    // Calculate rotation if autoRotate is enabled
    final rotationAngle = item.autoRotate ? timeInSeconds * 0.1 : 0.0;

    switch (item.visualizerType) {
      case VisualizerType.bars:
        return BarVisualizerPainter(
          fftBars: adjustedBars,
          colorStart: item.colorStart,
          colorEnd: item.colorEnd,
          useGradient: item.useGradient,
          scale: item.size.width,
          position: item.position,
        );
      case VisualizerType.circular:
        return CircularVisualizerPainter(
          fftBars: adjustedBars,
          colorStart: item.colorStart,
          colorEnd: item.colorEnd,
          useGradient: item.useGradient,
          rotationAngle: rotationAngle,
          scale: item.size.width,
          position: item.position,
        );
      case VisualizerType.symmetricBars:
        return SymmetricBarPainter(
          fftBars: adjustedBars,
          colorStart: item.colorStart,
          colorEnd: item.colorEnd,
          useGradient: item.useGradient,
          scale: item.size.width,
          position: item.position,
        );
      case VisualizerType.wave:
        return WaveVisualizerPainter(
          fftBars: adjustedBars,
          colorStart: item.colorStart,
          colorEnd: item.colorEnd,
          useGradient: item.useGradient,
          scale: item.size.width,
          position: item.position,
        );
    }
  }
}

