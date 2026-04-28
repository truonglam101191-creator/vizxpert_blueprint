import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/providers/ui_config_provider.dart';
import '../../overlay/providers/overlay_provider.dart';
import '../application/export_orchestrator.dart';

// ─── State ──────────────────────────────────────────────────────────────────

enum ExportStatus {
  idle,
  checkingFFmpeg,
  analyzingAudio,
  preparingFrames,
  encoding,
  done,
  error,
}

@immutable
class ExportState {
  const ExportState({
    this.status = ExportStatus.idle,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
    this.currentFrame = 0,
    this.totalFrames = 0,
    this.statusMessage = '',
  });

  final ExportStatus status;

  /// 0.0 – 1.0 overall progress.
  final double progress;
  final String? outputPath;
  final String? errorMessage;
  final int currentFrame;
  final int totalFrames;

  /// Human-readable status message for display.
  final String statusMessage;

  bool get isExporting =>
      status == ExportStatus.checkingFFmpeg ||
      status == ExportStatus.analyzingAudio ||
      status == ExportStatus.preparingFrames ||
      status == ExportStatus.encoding;

  ExportState copyWith({
    ExportStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
    int? currentFrame,
    int? totalFrames,
    String? statusMessage,
  }) {
    return ExportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFrame: currentFrame ?? this.currentFrame,
      totalFrames: totalFrames ?? this.totalFrames,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  // ── Phase 0: Checking FFmpeg ────────────────────────────────────────
  void startCheckingFFmpeg() {
    state = const ExportState(
      status: ExportStatus.checkingFFmpeg,
      progress: 0.0,
      statusMessage: 'Checking FFmpeg…',
    );
  }

  void updateFFmpegDownload(double p) {
    state = state.copyWith(
      progress: p * 0.05, // 0–5% of total
      statusMessage: 'Downloading FFmpeg… ${(p * 100).toInt()}%',
    );
  }

  // ── Phase 1: Analyzing audio (FFT pre-computation) ──────────────────
  void startAnalyzingAudio(int totalFrames) {
    state = ExportState(
      status: ExportStatus.analyzingAudio,
      progress: 0.05,
      totalFrames: totalFrames,
      statusMessage: 'Analyzing audio…',
    );
  }

  void updateAnalysisProgress(int current, int total) {
    // Analysis takes 5–20% of total progress
    final p = total > 0 ? current / total : 0.0;
    state = state.copyWith(
      progress: 0.05 + p * 0.15,
      currentFrame: current,
      statusMessage: 'Analyzing audio… ${(p * 100).toInt()}%',
    );
  }

  // ── Phase 2: Capturing frames ───────────────────────────────────────
  void startPreparing(int totalFrames) {
    state = ExportState(
      status: ExportStatus.preparingFrames,
      totalFrames: totalFrames,
      progress: 0.20,
      statusMessage: 'Capturing frames… 0/$totalFrames',
    );
  }

  void updateFrameProgress(int currentFrame) {
    // Frame capture takes 20–85% of total progress
    final p = state.totalFrames > 0
        ? (currentFrame / state.totalFrames)
        : 0.0;
    state = state.copyWith(
      currentFrame: currentFrame,
      progress: 0.20 + p * 0.65,
      statusMessage:
          'Capturing frames… $currentFrame/${state.totalFrames} '
          '(${(p * 100).toInt()}%)',
    );
  }

  // ── Phase 3: Encoding video ─────────────────────────────────────────
  void startEncoding() {
    state = state.copyWith(
      status: ExportStatus.encoding,
      progress: 0.85,
      statusMessage: 'Encoding video…',
    );
  }

  void updateEncodingProgress(double p) {
    state = state.copyWith(
      progress: 0.85 + p * 0.15,
      statusMessage: 'Encoding video… ${(p * 100).toInt()}%',
    );
  }

  // ── Final states ────────────────────────────────────────────────────
  void complete(String outputPath) {
    state = ExportState(
      status: ExportStatus.done,
      progress: 1.0,
      outputPath: outputPath,
      statusMessage: 'Export complete!',
    );
  }

  void fail(String message) {
    state = ExportState(
      status: ExportStatus.error,
      errorMessage: message,
      statusMessage: 'Export failed',
    );
  }

  void reset() {
    state = const ExportState();
  }

  Future<void> exportVideo({
    required String audioPath,
    required int durationMs,
    required UIConfigState config,
    required OverlayState overlayState,
    required String outputPath,
    List<double> Function(int timestampMs)? fftDataAtTime,
  }) async {
    final orchestrator = ExportOrchestrator(exportNotifier: this);
    await orchestrator.export(
      audioPath: audioPath,
      durationMs: durationMs,
      config: config,
      overlayState: overlayState,
      outputPath: outputPath,
      fftDataAtTime: fftDataAtTime,
    );
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final exportProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);
