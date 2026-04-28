import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../overlay/application/image_cache_service.dart';
import '../../workspace/providers/ui_config_provider.dart';
import '../../overlay/providers/overlay_provider.dart';
import '../../audio_processing/application/offline_fft_reader.dart';
import '../providers/export_provider.dart';
import 'ffmpeg_service.dart';
import 'frame_capturer.dart';

/// Orchestrates the full export pipeline:
///   1. Check / download FFmpeg
///   2. Analyze audio (pre-compute FFT)
///   3. Capture all frames → PNG files
///   4. Encode frames + audio → MP4 via FFmpeg
///   5. Clean up temp files
///   6. Report result
///
/// Each phase reports progress to [ExportNotifier] so the UI can display
/// a detailed status bar with percentage and descriptive messages.
class ExportOrchestrator {
  ExportOrchestrator({
    required this.exportNotifier,
    FFmpegService? ffmpegService,
  }) : _ffmpeg = ffmpegService ?? const FFmpegService();

  final ExportNotifier exportNotifier;
  final FFmpegService _ffmpeg;

  Future<void> export({
    required String audioPath,
    required int durationMs,
    required UIConfigState config,
    required OverlayState overlayState,
    required String outputPath,
    List<double> Function(int timestampMs)? fftDataAtTime,
  }) async {
    OfflineFFTReader? fftReader;

    try {
      // ── Phase 0: Check / download FFmpeg ─────────────────────────────
      exportNotifier.startCheckingFFmpeg();

      final ffmpegPath = await _ffmpeg.ensureAvailable(
        onDownloadProgress: (p) => exportNotifier.updateFFmpegDownload(p),
      );
      if (ffmpegPath == null) {
        exportNotifier.fail(
          'FFmpeg not found and auto-download failed.\n'
          'Please check your internet connection and try again.',
        );
        return;
      }

      // ── Phase 1: Analyze audio (pre-compute FFT) ────────────────────
      List<double> Function(int timestampMs) resolvedFftFn;

      if (fftDataAtTime != null) {
        resolvedFftFn = fftDataAtTime;
      } else {
        final totalExportFrames = (durationMs / 1000.0 * config.fps).ceil();
        exportNotifier.startAnalyzingAudio(totalExportFrames);

        debugPrint('ExportOrchestrator: Pre-computing FFT from audio...');
        fftReader = OfflineFFTReader(
          audioPath: audioPath,
          durationMs: durationMs,
          fps: config.fps,
        );

        await fftReader.precompute(
          onProgress: (current, total) {
            exportNotifier.updateAnalysisProgress(current, total);
          },
        );

        resolvedFftFn = fftReader.getFFTAtTime;
        debugPrint('ExportOrchestrator: FFT pre-computation complete.');
      }

      // ── Phase 2: Create temp directory & preload assets ─────────────
      final tempBase = await getTemporaryDirectory();
      final framesDir =
          '${tempBase.path}/vizxpert_frames_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(framesDir).create(recursive: true);

      ui.Image? bgImage;
      if (overlayState.backgroundImagePath != null) {
        bgImage = await ImageCacheService.instance.getImage(
          overlayState.backgroundImagePath!,
        );
      }

      // ── Phase 3: Capture frames ─────────────────────────────────────
      final capturer = FrameCapturer(
        config: config,
        resolution: config.resolution,
        fps: config.fps,
        durationMs: durationMs,
        outputDir: framesDir,
        overlayItems: overlayState.items,
        backgroundImage: bgImage,
      );

      exportNotifier.startPreparing(capturer.totalFrames);

      await capturer.captureAll(
        fftDataAtTime: resolvedFftFn,
        onProgress: (current, total) {
          exportNotifier.updateFrameProgress(current);
        },
      );

      // ── Phase 4: Encode with FFmpeg ─────────────────────────────────
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

      // ── Phase 5: Cleanup ────────────────────────────────────────────
      await _ffmpeg.cleanupFrames(framesDir);
      fftReader?.dispose();

      // ── Phase 6: Report ─────────────────────────────────────────────
      if (result.success) {
        exportNotifier.complete(outputPath);
      } else {
        exportNotifier.fail(result.message);
      }
    } catch (e) {
      fftReader?.dispose();
      exportNotifier.fail('Export failed: $e');
    }
  }
}
