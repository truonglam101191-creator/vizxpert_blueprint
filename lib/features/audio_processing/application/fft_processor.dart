import '../domain/audio_analyzer.dart';

/// Orchestrates per-frame FFT processing: raw → normalise → resample → smooth.
class FFTProcessor {
  FFTProcessor({AudioAnalyzer? analyzer})
    : _analyzer = analyzer ?? const AudioAnalyzer();

  final AudioAnalyzer _analyzer;

  List<double> _previous = [];

  /// Process a single FFT frame.
  ///
  /// [rawFft]       – raw magnitudes straight from SoLoud.
  /// [barCount]     – target number of visualiser bars.
  /// [smoothing]    – EMA smoothing factor (0 = none, ~0.9 = very smooth).
  /// [intensity]    – multiplier applied after normalisation.
  List<double> processFrame({
    required List<double> rawFft,
    required int barCount,
    required double smoothing,
    required double intensity,
  }) {
    // 1. Normalise + resample
    var processed = _analyzer.processRaw(rawFft, barCount: barCount);

    // 2. Apply intensity multiplier
    if (intensity != 1.0) {
      processed = [for (final v in processed) (v * intensity).clamp(0.0, 1.0)];
    }

    // 3. Smooth across frames
    processed = _analyzer.smoothData(processed, _previous, smoothing);

    _previous = processed;
    return processed;
  }

  /// Reset internal state (e.g. when loading a new song).
  void reset() {
    _previous = [];
  }
}
