import 'dart:math' as math;

import '../../../core/utils/app_constants.dart';

/// Pure-function audio analysis utilities.
///
/// All methods are stateless to make testing and offline processing simple.
class AudioAnalyzer {
  const AudioAnalyzer();

  // ─── Normalization ──────────────────────────────────────────────────

  /// Normalise raw FFT magnitudes into the \[0.0, 1.0\] range.
  ///
  /// Uses a logarithmic scale that mirrors how humans perceive loudness,
  /// with a noise floor at [minDb] (default -60 dB) and a ceiling at 0 dB.
  List<double> normalizeFFT(List<double> rawFft, {double minDb = -60.0}) {
    if (rawFft.isEmpty) return [];
    final result = List<double>.filled(rawFft.length, 0.0);
    for (var i = 0; i < rawFft.length; i++) {
      final magnitude = rawFft[i].abs();
      if (magnitude <= 0) {
        result[i] = 0.0;
        continue;
      }
      // Convert to decibels, clamp, then map to [0, 1].
      final db = 20.0 * math.log(magnitude) / math.ln10;
      result[i] = ((db - minDb) / -minDb).clamp(0.0, 1.0);
    }
    return result;
  }

  // ─── Band Isolation ─────────────────────────────────────────────────

  /// Splits a normalised FFT array into three frequency bands.
  ///
  /// [sampleRate] is typically 44100 Hz.
  ({List<double> bass, List<double> mid, List<double> high}) isolateBands(
    List<double> fft, {
    int sampleRate = 44100,
  }) {
    final binCount = fft.length;
    if (binCount == 0) {
      return (bass: <double>[], mid: <double>[], high: <double>[]);
    }
    final hzPerBin = (sampleRate / 2) / binCount;
    final bassEnd = (AppConstants.bassCutoff / hzPerBin).round().clamp(0, binCount);
    final midEnd = (AppConstants.midCutoff / hzPerBin).round().clamp(0, binCount);

    return (
      bass: fft.sublist(0, bassEnd),
      mid: fft.sublist(bassEnd, midEnd),
      high: fft.sublist(midEnd),
    );
  }

  // ─── Smoothing ──────────────────────────────────────────────────────

  /// Exponential moving-average smoothing between two consecutive frames.
  ///
  /// [factor] of `0.0` means no smoothing (instant response), while `0.95`
  /// produces a very soft, trailing motion.
  List<double> smoothData(
    List<double> current,
    List<double> previous,
    double factor,
  ) {
    if (previous.isEmpty || previous.length != current.length) {
      return List<double>.from(current);
    }
    final result = List<double>.filled(current.length, 0.0);
    for (var i = 0; i < current.length; i++) {
      result[i] = previous[i] * factor + current[i] * (1.0 - factor);
    }
    return result;
  }

  // ─── Resampling ─────────────────────────────────────────────────────

  /// Down-samples (or up-samples) [data] to exactly [targetBars] values
  /// using simple linear interpolation.
  List<double> resampleBands(List<double> data, int targetBars) {
    if (data.isEmpty) return List<double>.filled(targetBars, 0.0);
    if (data.length == targetBars) return List<double>.from(data);

    final result = List<double>.filled(targetBars, 0.0);
    final ratio = data.length / targetBars;
    for (var i = 0; i < targetBars; i++) {
      final pos = i * ratio;
      final low = pos.floor().clamp(0, data.length - 1);
      final high = (low + 1).clamp(0, data.length - 1);
      final t = pos - low;
      result[i] = data[low] * (1.0 - t) + data[high] * t;
    }
    return result;
  }

  // ─── Composite helper ───────────────────────────────────────────────

  /// Full pipeline: normalise → resample to [barCount] bars.
  ///
  /// Smoothing is handled externally by the caller who holds the previous
  /// frame reference.
  List<double> processRaw(List<double> rawFft, {required int barCount}) {
    final normalised = normalizeFFT(rawFft);
    return resampleBands(normalised, barCount);
  }
}
