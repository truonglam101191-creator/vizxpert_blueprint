import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Inline colour picker with HSL sliders and preset swatches.
class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    this.label = 'Color',
    this.presets,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final String label;

  /// Optional preset swatches. If null, defaults to [AppColors.backgroundPresets].
  final Map<String, Color>? presets;

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late HSLColor _hsl;
  bool _showSliders = false;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.currentColor);
  }

  @override
  void didUpdateWidget(covariant ColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _hsl = HSLColor.fromColor(widget.currentColor);
    }
  }

  void _updateHSL(HSLColor hsl) {
    setState(() => _hsl = hsl);
    widget.onColorChanged(hsl.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final presets = widget.presets ?? AppColors.backgroundPresets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label + current color swatch ─────────────────────────────
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showSliders = !_showSliders),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.currentColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.panelBorder, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Preset swatches ──────────────────────────────────────────
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.entries.map((e) {
            final isSelected = widget.currentColor.toARGB32() == e.value.toARGB32();
            return Tooltip(
              message: e.key,
              child: GestureDetector(
                onTap: () {
                  setState(() => _hsl = HSLColor.fromColor(e.value));
                  widget.onColorChanged(e.value);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: e.value,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.panelBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // ── HSL sliders (expandable) ─────────────────────────────────
        if (_showSliders) ...[
          const SizedBox(height: 12),
          _HslSlider(
            label: 'H',
            value: _hsl.hue,
            max: 360,
            activeColor: _hsl.toColor(),
            onChanged: (v) => _updateHSL(_hsl.withHue(v)),
          ),
          _HslSlider(
            label: 'S',
            value: _hsl.saturation * 100,
            max: 100,
            activeColor: _hsl.toColor(),
            onChanged: (v) =>
                _updateHSL(_hsl.withSaturation((v / 100).clamp(0.0, 1.0))),
          ),
          _HslSlider(
            label: 'L',
            value: _hsl.lightness * 100,
            max: 100,
            activeColor: _hsl.toColor(),
            onChanged: (v) =>
                _updateHSL(_hsl.withLightness((v / 100).clamp(0.0, 1.0))),
          ),
        ],
      ],
    );
  }
}

// ─── Tiny HSL slider row ────────────────────────────────────────────────────

class _HslSlider extends StatelessWidget {
  const _HslSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
                  activeTrackColor: activeColor,
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                ),
            child: Slider(
              value: value.clamp(0, max),
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.toInt().toString(),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
