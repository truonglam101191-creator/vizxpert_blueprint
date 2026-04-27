
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../application/fft_processor.dart';
import '../../../core/utils/app_constants.dart';

// ─── State ──────────────────────────────────────────────────────────────────

@immutable
class FFTState {
  const FFTState({
    this.bars = const [],
    this.isActive = false,
  });

  /// Processed, normalised, smoothed bar heights \[0.0 – 1.0\].
  final List<double> bars;

  /// Whether the ticker is actively collecting data.
  final bool isActive;

  FFTState copyWith({
    List<double>? bars,
    bool? isActive,
  }) {
    return FFTState(
      bars: bars ?? this.bars,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class FFTNotifier extends Notifier<FFTState> {
  final FFTProcessor _processor = FFTProcessor();

  Ticker? _ticker;
  AudioData? _audioData;
  int _barCount = AppConstants.defaultBarCount;
  double _smoothing = AppConstants.defaultSmoothing;
  double _intensity = AppConstants.defaultIntensity;

  @override
  FFTState build() => const FFTState();

  // ── Configuration (set by UI) ──────────────────────────────────────

  void updateConfig({int? barCount, double? smoothing, double? intensity}) {
    if (barCount != null) _barCount = barCount;
    if (smoothing != null) _smoothing = smoothing;
    if (intensity != null) _intensity = intensity;
  }

  // ── Ticker control ─────────────────────────────────────────────────

  void start(TickerProvider vsync) {
    if (_ticker != null) return;

    // Create AudioData for linear mode (FFT + wave)
    _audioData = AudioData(GetSamplesKind.linear);

    _ticker = vsync.createTicker(_onTick);
    _ticker!.start();
    state = state.copyWith(isActive: true);
  }

  void stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _audioData?.dispose();
    _audioData = null;
    _processor.reset();
    state = const FFTState();
  }

  void _onTick(Duration _) {
    if (_audioData == null) return;
    if (!SoLoud.instance.isInitialized) return;

    try {
      // Update audio samples from SoLoud
      _audioData!.updateSamples();

      // Get the linear data: first 256 = FFT, next 256 = wave
      final samples = _audioData!.getAudioData();
      if (samples.isEmpty) return;

      // Extract FFT portion (first 256 values)
      final fftLength = samples.length >= 512 ? 256 : samples.length;
      final rawFft = samples.sublist(0, fftLength);

      final bars = _processor.processFrame(
        rawFft: rawFft.toList(),
        barCount: _barCount,
        smoothing: _smoothing,
        intensity: _intensity,
      );

      state = FFTState(
        bars: bars,
        isActive: true,
      );
    } catch (_) {
      // SoLoud may throw if engine is not ready yet; silently ignore.
    }
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final fftProvider =
    NotifierProvider<FFTNotifier, FFTState>(FFTNotifier.new);
