import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/providers/ui_config_provider.dart';
import '../../overlay/providers/overlay_provider.dart';
import '../application/export_orchestrator.dart';

// ─── State ──────────────────────────────────────────────────────────────────

enum ExportStatus { idle, preparingFrames, encoding, done, error }

@immutable
class ExportState {
  const ExportState({
    this.status = ExportStatus.idle,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
    this.currentFrame = 0,
    this.totalFrames = 0,
  });

  final ExportStatus status;

  /// 0.0 – 1.0 overall progress.
  final double progress;
  final String? outputPath;
  final String? errorMessage;
  final int currentFrame;
  final int totalFrames;

  bool get isExporting =>
      status == ExportStatus.preparingFrames || status == ExportStatus.encoding;

  ExportState copyWith({
    ExportStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
    int? currentFrame,
    int? totalFrames,
  }) {
    return ExportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFrame: currentFrame ?? this.currentFrame,
      totalFrames: totalFrames ?? this.totalFrames,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  void startPreparing(int totalFrames) {
    state = ExportState(
      status: ExportStatus.preparingFrames,
      totalFrames: totalFrames,
    );
  }

  void updateFrameProgress(int currentFrame) {
    final progress = state.totalFrames > 0
        ? (currentFrame / state.totalFrames) * 0.8
        : 0.0;
    state = state.copyWith(
      currentFrame: currentFrame,
      progress: progress,
    );
  }

  void startEncoding() {
    state = state.copyWith(
      status: ExportStatus.encoding,
      progress: 0.85,
    );
  }

  void updateEncodingProgress(double p) {
    state = state.copyWith(progress: 0.8 + p * 0.2);
  }

  void complete(String outputPath) {
    state = ExportState(
      status: ExportStatus.done,
      progress: 1.0,
      outputPath: outputPath,
    );
  }

  void fail(String message) {
    state = ExportState(
      status: ExportStatus.error,
      errorMessage: message,
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

final exportProvider =
    NotifierProvider<ExportNotifier, ExportState>(ExportNotifier.new);
