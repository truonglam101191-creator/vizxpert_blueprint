import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';

import '../../overlay/domain/overlay_item.dart';
import '../../rendering/presentation/visualizer_painter.dart';
import '../../rendering/presentation/painters/overlay_compositor.dart';
import '../../workspace/providers/ui_config_provider.dart';
import '../../audio_processing/application/fft_processor.dart';

/// Captures individual frames to PNG files for offline video rendering.
///
/// Renders a complete composited frame including:
/// 1. Background (color or image)
/// 2. Audio visualizer (bar/circular)
/// 3. Overlay items (text, image, shapes)
class FrameCapturer {
  FrameCapturer({
    required this.config,
    required this.resolution,
    required this.fps,
    required this.durationMs,
    required this.outputDir,
    this.overlayItems = const [],
    this.backgroundImage,
  });

  final UIConfigState config;
  final Size resolution;
  final int fps;
  final int durationMs;
  final String outputDir;

  /// Overlay items to render on each frame.
  final List<OverlayItem> overlayItems;

  /// Optional background image (pre-loaded).
  final ui.Image? backgroundImage;

  /// Total number of frames that will be generated.
  int get totalFrames => (durationMs / 1000.0 * fps).ceil();

  /// Capture all frames, calling [onProgress] with (current, total).
  ///
  /// [fftDataAtTime] is a function that returns raw FFT data for a given
  /// timestamp in milliseconds. If null, a simple sine-wave placeholder
  /// is generated.
  Future<void> captureAll({
    List<double> Function(int timestampMs)? fftDataAtTime,
    void Function(int current, int total)? onProgress,
  }) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final processor = FFTProcessor();
    final total = totalFrames;
    final width = resolution.width.toInt();
    final height = resolution.height.toInt();

    for (var i = 0; i < total; i++) {
      final timestampMs = (i / fps * 1000).round();

      // Get FFT data for this timestamp
      final rawFft = fftDataAtTime?.call(timestampMs) ??
          _generatePlaceholderFFT(timestampMs, config.barCount);

      // Process through pipeline
      final bars = processor.processFrame(
        rawFft: rawFft,
        barCount: config.barCount,
        smoothing: config.smoothing,
        intensity: config.intensity,
      );

      // Paint to offscreen canvas
      final bytes = await _renderFrame(bars, width, height, timestampMs);

      // Save PNG
      final frameNumber = i.toString().padLeft(5, '0');
      final file = File('$outputDir/frame_$frameNumber.png');
      await file.writeAsBytes(bytes);

      onProgress?.call(i + 1, total);
    }
  }

  Future<Uint8List> _renderFrame(
    List<double> bars,
    int width,
    int height,
    int timestampMs,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final canvasSize = Size(width.toDouble(), height.toDouble());

    // ── 1. Draw visualizer (includes background color & image) ──────────────
    final visualizerPainter = VisualizerPainterFactory.create(
      config: config,
      fftBars: bars,
      rotationAngle: config.autoRotate ? (timestampMs / 1000.0 * 0.1) : 0.0,
      backgroundImage: backgroundImage,
    );
    visualizerPainter.paint(canvas, canvasSize);

    // ── 2. Draw overlay items ───────────────────────────────────────
    if (overlayItems.isNotEmpty) {
      final overlayPainter = OverlayCompositorPainter(
        overlayItems: overlayItems,
        canvasSize: canvasSize,
      );
      overlayPainter.paint(canvas, canvasSize);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Placeholder FFT data for preview/testing when no real audio is available.
  List<double> _generatePlaceholderFFT(int timestampMs, int barCount) {
    final t = timestampMs / 1000.0;
    return List.generate(barCount, (i) {
      final freq = i / barCount;
      return (0.3 +
              0.3 *
                  (0.5 +
                      0.5 *
                          math.sin(t * 2.0 + freq * 6.28) *
                          math.sin(t * 0.5 + freq * 3.14)))
          .clamp(0.0, 1.0);
    });
  }
}
