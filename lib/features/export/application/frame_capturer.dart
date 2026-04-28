import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';

import '../../overlay/domain/overlay_item.dart';
import '../../rendering/presentation/painters/background_painter.dart';
import '../../rendering/presentation/painters/overlay_compositor.dart';
import '../../workspace/providers/ui_config_provider.dart';
import '../../audio_processing/application/fft_processor.dart';

/// Captures individual frames for offline video rendering.
///
/// Renders a complete composited frame including:
/// 1. Background (color or image)
/// 2. Audio visualizer (bar/circular)
/// 3. Overlay items (text, image, shapes)
///
/// Performance optimisations:
/// - Uses raw RGBA bytes internally → converted to PNG only on disk
/// - Reuses a single [FFTProcessor] across all frames for smoothing
/// - Processes frames in batches to allow UI updates
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
  /// timestamp in milliseconds.
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

    // Process in batches to reduce GC pressure and allow UI updates
    const batchSize = 10;

    for (var i = 0; i < total; i++) {
      final timestampMs = (i / fps * 1000).round();

      // Get FFT data for this timestamp
      final rawFft =
          fftDataAtTime?.call(timestampMs) ??
          _generatePlaceholderFFT(timestampMs, 256);

      // Process through pipeline (maintains smoothing state across frames).
      // Higher smoothing (0.75) than live preview (0.5) ensures silky-smooth
      // transitions in the exported video.
      final bars = processor.processFrame(
        rawFft: rawFft,
        barCount: 256,
        smoothing: 0.75,
        intensity: 1.0,
      );

      // Paint to offscreen canvas and save directly as PNG
      final bytes = await _renderFrame(bars, width, height, timestampMs);

      // Save PNG
      final frameNumber = i.toString().padLeft(5, '0');
      final file = File('$outputDir/frame_$frameNumber.png');
      await file.writeAsBytes(bytes, flush: false);

      onProgress?.call(i + 1, total);

      // Yield control every batch to keep UI responsive
      if ((i + 1) % batchSize == 0) {
        await Future.delayed(Duration.zero);
      }
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

    // ── 1. Draw background color & image ──────────────
    final bgPainter = BackgroundPainter(
      backgroundColor: config.backgroundColor,
      backgroundImage: backgroundImage,
    );
    bgPainter.paint(canvas, canvasSize);

    // ── 2. Draw overlay items (including visualizers) ─────────────
    if (overlayItems.isNotEmpty) {
      final overlayPainter = OverlayCompositorPainter(
        overlayItems: overlayItems,
        canvasSize: canvasSize,
        fftBars: bars,
        timeInSeconds: timestampMs / 1000.0,
        currentTimeMs: timestampMs,
        totalDurationMs: durationMs,
      );
      overlayPainter.paint(canvas, canvasSize);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Placeholder FFT data when no real audio data is available.
  /// Generates a more realistic bass-heavy spectrum with rhythmic variation.
  List<double> _generatePlaceholderFFT(int timestampMs, int barCount) {
    final t = timestampMs / 1000.0;
    final rng = math.Random(timestampMs ~/ 33);

    return List.generate(barCount, (i) {
      final freq = i / barCount;

      // Bass-heavy falloff
      final bassFalloff = math.exp(-freq * 3.0);

      // Simulated beats at ~120 BPM
      final beat = 0.5 + 0.5 * math.sin(t * math.pi * 4.0);
      final subBeat = 0.3 + 0.7 * math.sin(t * math.pi * 2.0);

      // Add variation
      final noise = rng.nextDouble() * 0.12;

      return (bassFalloff * (beat * 0.6 + subBeat * 0.4) + noise).clamp(
        0.0,
        1.0,
      );
    });
  }
}
