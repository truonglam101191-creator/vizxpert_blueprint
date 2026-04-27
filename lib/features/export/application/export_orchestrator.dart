import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../workspace/providers/ui_config_provider.dart';
import '../providers/export_provider.dart';
import 'ffmpeg_service.dart';
import 'frame_capturer.dart';

/// Orchestrates the full export pipeline:
///   1. Create temp directory
///   2. Capture all frames → PNG files
///   3. Encode frames + audio → MP4 via FFmpeg
///   4. Clean up temp files
///   5. Report result
class ExportOrchestrator {
  ExportOrchestrator({
    required this.exportNotifier,
    FFmpegService? ffmpegService,
  }) : _ffmpeg = ffmpegService ?? const FFmpegService();

  final ExportNotifier exportNotifier;
  final FFmpegService _ffmpeg;

  /// Run the full export pipeline.
  ///
  /// [audioPath]    – path to the source audio file
  /// [durationMs]   – total duration of the audio in milliseconds
  /// [config]       – current UI config (colors, visualizer type, etc.)
  /// [outputPath]   – where to save the final .mp4
  /// [fftDataAtTime] – optional function to get real FFT data per timestamp
  Future<void> export({
    required String audioPath,
    required int durationMs,
    required UIConfigState config,
    required String outputPath,
    List<double> Function(int timestampMs)? fftDataAtTime,
  }) async {
    try {
      // ── 0. Check FFmpeg ─────────────────────────────────────────────
      final ffmpegAvailable = await _ffmpeg.checkAvailable();
      if (!ffmpegAvailable) {
        exportNotifier.fail(
          'FFmpeg not found.\n'
          'Install it with: brew install ffmpeg',
        );
        return;
      }

      // ── 1. Create temp directory ────────────────────────────────────
      final tempBase = await getTemporaryDirectory();
      final framesDir =
          '${tempBase.path}/vizxpert_frames_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(framesDir).create(recursive: true);

      // ── 2. Capture frames ───────────────────────────────────────────
      final capturer = FrameCapturer(
        config: config,
        resolution: config.resolution,
        fps: config.fps,
        durationMs: durationMs,
        outputDir: framesDir,
      );

      exportNotifier.startPreparing(capturer.totalFrames);

      await capturer.captureAll(
        fftDataAtTime: fftDataAtTime,
        onProgress: (current, total) {
          exportNotifier.updateFrameProgress(current);
        },
      );

      // ── 3. Encode with FFmpeg ───────────────────────────────────────
      exportNotifier.startEncoding();

      final result = await _ffmpeg.encodeVideo(
        framesDir: framesDir,
        audioPath: audioPath,
        outputPath: outputPath,
        fps: config.fps,
        resolution: (
          width: config.resolution.width.toInt(),
          height: config.resolution.height.toInt(),
        ),
        onProgress: (p) => exportNotifier.updateEncodingProgress(p),
      );

      // ── 4. Cleanup ─────────────────────────────────────────────────
      await _ffmpeg.cleanupFrames(framesDir);

      // ── 5. Report ──────────────────────────────────────────────────
      if (result.success) {
        exportNotifier.complete(outputPath);
      } else {
        exportNotifier.fail(result.message);
      }
    } catch (e) {
      exportNotifier.fail('Export failed: $e');
    }
  }
}
