import 'package:flutter/material.dart';

/// Curated color palette for VizXpert — professional dark-mode audio visualizer.
abstract final class AppColors {
  // ─── Base / Background ──────────────────────────────────────────────
  static const Color scaffold = Color(0xFF0A0A1A);
  static const Color panelBackground = Color(0xFF12122A);
  static const Color surface = Color(0xFF1A1A3E);
  static const Color surfaceLight = Color(0xFF222255);
  static const Color panelBorder = Color(0xFF2A2A5A);
  static const Color divider = Color(0xFF1E1E4A);

  // ─── Accents ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color teal = Color(0xFF00E5A0);

  // ─── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF555577);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ─── Semantic ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // ─── Visualizer Defaults ────────────────────────────────────────────
  static const Color barStart = Color(0xFF6C63FF);
  static const Color barEnd = Color(0xFF00D4FF);
  static const Color barGlow = Color(0x806C63FF);

  /// Default gradient used for visualizer bars.
  static const List<Color> visualizerGradient = [barStart, barEnd];

  // ─── Canvas Background Presets ──────────────────────────────────────
  static const Map<String, Color> backgroundPresets = {
    'Midnight': Color(0xFF0A0A1A),
    'Deep Space': Color(0xFF0D1117),
    'Pastel Pink': Color(0xFF2A1A28),
    'Sepia': Color(0xFF1E1A14),
    'Forest': Color(0xFF0A1A14),
    'Violet Dusk': Color(0xFF1A0A2A),
    'Ocean Floor': Color(0xFF0A1A2A),
    'Warm Ember': Color(0xFF2A1A0A),
  };

  // ─── Slider / Interactive ───────────────────────────────────────────
  static const Color sliderActive = primary;
  static const Color sliderInactive = Color(0xFF2A2A5A);
  static const Color sliderThumb = Color(0xFFE8E8F0);

  // ─── Transport Controls ─────────────────────────────────────────────
  static const Color transportBg = Color(0xFF161630);
  static const Color transportIcon = Color(0xFFCCCCDD);
  static const Color transportPlayIcon = Color(0xFF6C63FF);
}
