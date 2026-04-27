import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_constants.dart';
import '../../providers/ui_config_provider.dart';
import 'color_picker_widget.dart';
import 'panel_section.dart';

/// Right properties panel: sliders and colour pickers for live configuration.
class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(uiConfigProvider);
    final notifier = ref.read(uiConfigProvider.notifier);

    return Container(
      color: AppColors.panelBackground,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'PROPERTIES',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable body ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ─── Visualizer section ────────────────────────────
                PanelSection(
                  title: 'Visualizer',
                  child: Column(
                    children: [
                      _LabeledSlider(
                        label: 'Intensity',
                        value: config.intensity,
                        min: AppConstants.minIntensity,
                        max: AppConstants.maxIntensity,
                        onChanged: notifier.setIntensity,
                        displayValue:
                            '${(config.intensity * 100).toInt()}%',
                      ),
                      const SizedBox(height: 8),
                      _LabeledSlider(
                        label: 'Bar Count',
                        value: config.barCount.toDouble(),
                        min: AppConstants.minBarCount.toDouble(),
                        max: AppConstants.maxBarCount.toDouble(),
                        onChanged: (v) => notifier.setBarCount(v.round()),
                        displayValue: config.barCount.toString(),
                      ),
                      const SizedBox(height: 8),
                      _LabeledSlider(
                        label: 'Smoothing',
                        value: config.smoothing,
                        min: AppConstants.minSmoothing,
                        max: AppConstants.maxSmoothing,
                        onChanged: notifier.setSmoothing,
                        displayValue:
                            '${(config.smoothing * 100).toInt()}%',
                      ),
                    ],
                  ),
                ),

                // ─── Colors section ─────────────────────────────────
                PanelSection(
                  title: 'Colors',
                  child: Column(
                    children: [
                      ColorPickerWidget(
                        label: 'Background',
                        currentColor: config.backgroundColor,
                        onColorChanged: (c) =>
                            notifier.setBackgroundColor(c),
                      ),
                      const SizedBox(height: 14),
                      ColorPickerWidget(
                        label: 'Bar Start',
                        currentColor: config.barColorStart,
                        onColorChanged: notifier.setBarColorStart,
                        presets: const {
                          'Purple': AppColors.primary,
                          'Coral': AppColors.secondary,
                          'Cyan': AppColors.cyan,
                          'Teal': AppColors.teal,
                          'Gold': Color(0xFFFFD700),
                          'White': Color(0xFFEEEEEE),
                        },
                      ),
                      const SizedBox(height: 14),
                      ColorPickerWidget(
                        label: 'Bar End',
                        currentColor: config.barColorEnd,
                        onColorChanged: notifier.setBarColorEnd,
                        presets: const {
                          'Cyan': AppColors.cyan,
                          'Purple': AppColors.primary,
                          'Pink': AppColors.secondary,
                          'Teal': AppColors.teal,
                          'Lime': Color(0xFFA8FF00),
                          'White': Color(0xFFEEEEEE),
                        },
                      ),
                      const SizedBox(height: 10),
                      // Gradient toggle
                      Row(
                        children: [
                          Text(
                            'Gradient',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 24,
                            child: Switch(
                              value: config.useGradient,
                              onChanged: notifier.setUseGradient,
                              activeThumbColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Export section ──────────────────────────────────
                PanelSection(
                  title: 'Export Settings',
                  child: Column(
                    children: [
                      // Resolution dropdown
                      _LabeledDropdown<String>(
                        label: 'Resolution',
                        value: AppConstants.resolutionPresets.entries
                            .firstWhere(
                                (e) => e.value == config.resolution)
                            .key,
                        items: AppConstants.resolutionPresets.keys.toList(),
                        onChanged: (key) {
                          if (key != null) {
                            notifier.setResolution(
                                AppConstants.resolutionPresets[key]!);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // FPS dropdown
                      _LabeledDropdown<String>(
                        label: 'Frame Rate',
                        value: AppConstants.fpsPresets.entries
                            .firstWhere((e) => e.value == config.fps)
                            .key,
                        items: AppConstants.fpsPresets.keys.toList(),
                        onChanged: (key) {
                          if (key != null) {
                            notifier
                                .setFps(AppConstants.fpsPresets[key]!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.displayValue,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String displayValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayValue,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 28,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.panelBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(
                          e.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              iconSize: 14,
              isDense: true,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
