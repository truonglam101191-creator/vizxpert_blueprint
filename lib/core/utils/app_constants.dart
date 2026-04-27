import 'package:flutter/material.dart';

/// App-wide constants for VizXpert.
abstract final class AppConstants {
  // ─── FFT ────────────────────────────────────────────────────────────
  static const int fftSize256 = 256;
  static const int fftSize512 = 512;
  static const int fftSize1024 = 1024;
  static const int defaultFftSize = fftSize256;

  /// Number of FFT bins actually usable (first half of FFT output).
  static const int usableBins = defaultFftSize ~/ 2;

  // ─── Frequency Band Boundaries (Hz) ────────────────────────────────
  static const double bassCutoff = 250.0;
  static const double midCutoff = 2000.0;
  // Anything above midCutoff → high band (strings, flutes, etc.)

  // ─── FPS ────────────────────────────────────────────────────────────
  static const int fps30 = 30;
  static const int fps60 = 60;
  static const int defaultFps = fps30;

  // ─── Resolutions ───────────────────────────────────────────────────
  static const Size resolution1080p = Size(1920, 1080);
  static const Size resolution4K = Size(3840, 2160);
  static const Size defaultResolution = resolution1080p;

  static const Map<String, Size> resolutionPresets = {
    '1080p (1920×1080)': resolution1080p,
    '4K (3840×2160)': resolution4K,
  };

  static const Map<String, int> fpsPresets = {
    '30 FPS': fps30,
    '60 FPS': fps60,
  };

  // ─── Panel Sizes ───────────────────────────────────────────────────
  static const double sidebarWidth = 220.0;
  static const double sidebarMinWidth = 180.0;
  static const double sidebarMaxWidth = 320.0;

  static const double propertiesWidth = 280.0;
  static const double propertiesMinWidth = 240.0;
  static const double propertiesMaxWidth = 400.0;

  static const double timelineHeight = 130.0;
  static const double timelineMinHeight = 80.0;
  static const double timelineMaxHeight = 200.0;

  static const double panelBorderWidth = 1.0;
  static const double resizeHandleWidth = 6.0;

  // ─── Visualizer Defaults ───────────────────────────────────────────
  static const int defaultBarCount = 64;
  static const int minBarCount = 16;
  static const int maxBarCount = 128;

  static const double defaultIntensity = 1.0;
  static const double minIntensity = 0.1;
  static const double maxIntensity = 2.5;

  static const double defaultSmoothing = 0.65;
  static const double minSmoothing = 0.0;
  static const double maxSmoothing = 0.95;

  // ─── Animation ─────────────────────────────────────────────────────
  static const Duration positionPollInterval = Duration(milliseconds: 100);
  static const double targetFrameRate = 60.0;

  // ─── Export ────────────────────────────────────────────────────────
  static const String framePrefixPattern = 'frame_%05d.png';
}
