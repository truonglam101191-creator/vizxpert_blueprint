import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../overlay/domain/overlay_item.dart';
import '../../../overlay/domain/text_overlay.dart';
import '../../../overlay/domain/image_overlay.dart';
import '../../../overlay/domain/shape_overlay.dart';
import '../../../overlay/domain/visualizer_overlay.dart';
import '../../../overlay/providers/overlay_provider.dart';
import '../../providers/ui_config_provider.dart';
import 'color_picker_widget.dart';
import 'panel_section.dart';

/// Right properties panel: visualizer config + dynamic overlay editor.
class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(uiConfigProvider);
    final notifier = ref.read(uiConfigProvider.notifier);
    final overlayState = ref.watch(overlayProvider);
    final selectedItem = overlayState.selectedItem;

    return Container(
      color: AppColors.panelBackground,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
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
                // ── Selected Overlay Editor (dynamic) ───────────────
                if (selectedItem != null) ...[
                  _OverlayEditorSection(
                    item: selectedItem,
                    overlayNotifier: ref.read(overlayProvider.notifier),
                  ),
                  const Divider(height: 1),
                ],

                // ─── Colors section ─────────────────────────────────
                PanelSection(
                  title: 'Colors',
                  child: Column(
                    children: [
                      ColorPickerWidget(
                        label: 'Background',
                        currentColor: config.backgroundColor,
                        onColorChanged: (c) => notifier.setBackgroundColor(c),
                      ),
                    ],
                  ),
                ),

                // ─── Export section ──────────────────────────────────
                PanelSection(
                  title: 'Export Settings',
                  child: Column(
                    children: [
                      _LabeledDropdown<String>(
                        label: 'Resolution',
                        value: AppConstants.resolutionPresets.entries
                            .firstWhere((e) => e.value == config.resolution)
                            .key,
                        items: AppConstants.resolutionPresets.keys.toList(),
                        onChanged: (key) {
                          if (key != null) {
                            notifier.setResolution(
                              AppConstants.resolutionPresets[key]!,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _LabeledDropdown<String>(
                        label: 'Frame Rate',
                        value: AppConstants.fpsPresets.entries
                            .firstWhere((e) => e.value == config.fps)
                            .key,
                        items: AppConstants.fpsPresets.keys.toList(),
                        onChanged: (key) {
                          if (key != null) {
                            notifier.setFps(AppConstants.fpsPresets[key]!);
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

// ─── Overlay Editor Section ─────────────────────────────────────────────────

class _OverlayEditorSection extends StatelessWidget {
  const _OverlayEditorSection({
    required this.item,
    required this.overlayNotifier,
  });

  final OverlayItem item;
  final OverlayNotifier overlayNotifier;

  @override
  Widget build(BuildContext context) {
    return PanelSection(
      title: _sectionTitle,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type-specific controls
          if (item is TextOverlay)
            _buildTextEditor(context, item as TextOverlay),
          if (item is ImageOverlay)
            _buildImageEditor(context, item as ImageOverlay),
          if (item is ShapeOverlay)
            _buildShapeEditor(context, item as ShapeOverlay),
          if (item is VisualizerOverlay)
            _buildVisualizerEditor(context, item as VisualizerOverlay),

          const Divider(height: 20),

          // ── Common transform controls ──────────────────────────────
          _LabeledSlider(
            label: 'Position X',
            value: item.position.dx,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => overlayNotifier.updatePosition(
              item.id,
              Offset(v, item.position.dy),
            ),
            displayValue: '${(item.position.dx * 100).toInt()}%',
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Position Y',
            value: item.position.dy,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => overlayNotifier.updatePosition(
              item.id,
              Offset(item.position.dx, v),
            ),
            displayValue: '${(item.position.dy * 100).toInt()}%',
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Width',
            value: item.size.width,
            min: 0.01,
            max: 1.0,
            onChanged: (v) =>
                overlayNotifier.updateSize(item.id, Size(v, item.size.height)),
            displayValue: '${(item.size.width * 100).toInt()}%',
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Height',
            value: item.size.height,
            min: 0.01,
            max: 1.0,
            onChanged: (v) =>
                overlayNotifier.updateSize(item.id, Size(item.size.width, v)),
            displayValue: '${(item.size.height * 100).toInt()}%',
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Opacity',
            value: item.opacity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => overlayNotifier.updateOpacity(item.id, v),
            displayValue: '${(item.opacity * 100).toInt()}%',
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Rotation',
            value: item.rotation * 180 / 3.14159,
            min: -180,
            max: 180,
            onChanged: (v) =>
                overlayNotifier.updateRotation(item.id, v * 3.14159 / 180),
            displayValue: '${(item.rotation * 180 / 3.14159).toInt()}°',
          ),

          const SizedBox(height: 10),

          // ── Layer & Action buttons ─────────────────────────────────
          Row(
            children: [
              _MiniIconButton(
                icon: Icons.vertical_align_top_rounded,
                tooltip: 'Move to Front',
                onTap: () => overlayNotifier.moveToFront(item.id),
              ),
              _MiniIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: 'Move Up',
                onTap: () => overlayNotifier.moveUp(item.id),
              ),
              _MiniIconButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: 'Move Down',
                onTap: () => overlayNotifier.moveDown(item.id),
              ),
              _MiniIconButton(
                icon: Icons.vertical_align_bottom_rounded,
                tooltip: 'Move to Back',
                onTap: () => overlayNotifier.moveToBack(item.id),
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: item.isVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                tooltip: item.isVisible ? 'Hide' : 'Show',
                onTap: () => overlayNotifier.toggleVisibility(item.id),
              ),
              _MiniIconButton(
                icon: item.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                tooltip: item.isLocked ? 'Unlock' : 'Lock',
                onTap: () => overlayNotifier.toggleLock(item.id),
              ),
              _MiniIconButton(
                icon: Icons.copy_rounded,
                tooltip: 'Duplicate',
                onTap: () => overlayNotifier.duplicateItem(item.id),
              ),
              const Spacer(),
              _MiniIconButton(
                icon: Icons.delete_rounded,
                tooltip: 'Delete',
                color: AppColors.error,
                onTap: () => overlayNotifier.removeItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _sectionTitle {
    switch (item.type) {
      case OverlayType.text:
        return '✏️ Text Overlay';
      case OverlayType.image:
        return '🖼 Image Overlay';
      case OverlayType.shape:
        return '🔷 Shape Overlay';
      case OverlayType.visualizer:
        return '🌊 Visualizer Overlay';
    }
  }

  // ── Text editor ──────────────────────────────────────────────────────────

  Widget _buildTextEditor(BuildContext context, TextOverlay textItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text content
        TextField(
          controller: TextEditingController(text: textItem.text),
          onChanged: (v) => overlayNotifier.updateItem(
            textItem.id,
            (item) => (item as TextOverlay).copyWith(text: v),
          ),
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Text',
            labelStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.panelBorder),
            ),
            contentPadding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(height: 10),

        // Font family
        _LabeledDropdown<String>(
          label: 'Font',
          value: textItem.fontFamily,
          items: const [
            'Inter',
            'Roboto',
            'Montserrat',
            'Playfair Display',
            'Poppins',
            'Outfit',
            'Lato',
            'Oswald',
          ],
          onChanged: (v) {
            if (v != null) {
              overlayNotifier.updateItem(
                textItem.id,
                (item) => (item as TextOverlay).copyWith(fontFamily: v),
              );
            }
          },
        ),
        const SizedBox(height: 8),

        // Font size
        _LabeledSlider(
          label: 'Font Size',
          value: textItem.fontSize,
          min: 8,
          max: 200,
          onChanged: (v) => overlayNotifier.updateItem(
            textItem.id,
            (item) => (item as TextOverlay).copyWith(fontSize: v),
          ),
          displayValue: '${textItem.fontSize.toInt()}px',
        ),
        const SizedBox(height: 8),

        // Font weight
        _LabeledDropdown<String>(
          label: 'Weight',
          value: _fontWeightLabel(textItem.fontWeight),
          items: const ['Light', 'Regular', 'Medium', 'Bold', 'Black'],
          onChanged: (v) {
            if (v != null) {
              overlayNotifier.updateItem(
                textItem.id,
                (item) => (item as TextOverlay).copyWith(
                  fontWeight: _fontWeightFromLabel(v),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Text color
        ColorPickerWidget(
          label: 'Text Color',
          currentColor: textItem.textColor,
          onColorChanged: (c) => overlayNotifier.updateItem(
            textItem.id,
            (item) => (item as TextOverlay).copyWith(textColor: c),
          ),
          presets: const {
            'White': Colors.white,
            'Black': Colors.black,
            'Cyan': AppColors.cyan,
            'Purple': AppColors.primary,
            'Gold': Color(0xFFFFD700),
            'Coral': AppColors.secondary,
          },
        ),
        const SizedBox(height: 8),

        // Shadow toggle
        Row(
          children: [
            Text('Shadow', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            SizedBox(
              height: 24,
              child: Switch(
                value: textItem.hasShadow,
                onChanged: (v) => overlayNotifier.updateItem(
                  textItem.id,
                  (item) => (item as TextOverlay).copyWith(hasShadow: v),
                ),
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Image editor ─────────────────────────────────────────────────────────

  Widget _buildImageEditor(BuildContext context, ImageOverlay imageItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File path
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.image_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  imageItem.imagePath.split('/').last,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Border radius
        _LabeledSlider(
          label: 'Border Radius',
          value: imageItem.borderRadius,
          min: 0,
          max: 100,
          onChanged: (v) => overlayNotifier.updateItem(
            imageItem.id,
            (item) => (item as ImageOverlay).copyWith(borderRadius: v),
          ),
          displayValue: '${imageItem.borderRadius.toInt()}',
        ),
        const SizedBox(height: 8),

        // Border width
        _LabeledSlider(
          label: 'Border Width',
          value: imageItem.borderWidth,
          min: 0,
          max: 10,
          onChanged: (v) => overlayNotifier.updateItem(
            imageItem.id,
            (item) => (item as ImageOverlay).copyWith(borderWidth: v),
          ),
          displayValue: imageItem.borderWidth.toStringAsFixed(1),
        ),
      ],
    );
  }

  // ── Shape editor ─────────────────────────────────────────────────────────

  Widget _buildShapeEditor(BuildContext context, ShapeOverlay shapeItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shape type
        _LabeledDropdown<String>(
          label: 'Shape',
          value: shapeItem.shapeType.name,
          items: ShapeType.values.map((e) => e.name).toList(),
          onChanged: (v) {
            if (v != null) {
              overlayNotifier.updateItem(
                shapeItem.id,
                (item) => (item as ShapeOverlay).copyWith(
                  shapeType: ShapeType.values.firstWhere((e) => e.name == v),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Fill color
        ColorPickerWidget(
          label: 'Fill Color',
          currentColor: shapeItem.fillColor,
          onColorChanged: (c) => overlayNotifier.updateItem(
            shapeItem.id,
            (item) => (item as ShapeOverlay).copyWith(fillColor: c),
          ),
          presets: const {
            'Transparent': Color(0x00000000),
            'White 20%': Color(0x33FFFFFF),
            'White 50%': Color(0x80FFFFFF),
            'Cyan': AppColors.cyan,
            'Purple': AppColors.primary,
            'Gold': Color(0xFFFFD700),
          },
        ),
        const SizedBox(height: 8),

        // Stroke color
        ColorPickerWidget(
          label: 'Stroke Color',
          currentColor: shapeItem.strokeColor,
          onColorChanged: (c) => overlayNotifier.updateItem(
            shapeItem.id,
            (item) => (item as ShapeOverlay).copyWith(strokeColor: c),
          ),
        ),
        const SizedBox(height: 8),

        // Stroke width
        _LabeledSlider(
          label: 'Stroke Width',
          value: shapeItem.strokeWidth,
          min: 0,
          max: 20,
          onChanged: (v) => overlayNotifier.updateItem(
            shapeItem.id,
            (item) => (item as ShapeOverlay).copyWith(strokeWidth: v),
          ),
          displayValue: shapeItem.strokeWidth.toStringAsFixed(1),
        ),
        const SizedBox(height: 8),

        // Border radius (rectangle only)
        if (shapeItem.shapeType == ShapeType.rectangle)
          _LabeledSlider(
            label: 'Corner Radius',
            value: shapeItem.borderRadius,
            min: 0,
            max: 100,
            onChanged: (v) => overlayNotifier.updateItem(
              shapeItem.id,
              (item) => (item as ShapeOverlay).copyWith(borderRadius: v),
            ),
            displayValue: '${shapeItem.borderRadius.toInt()}',
          ),
      ],
    );
  }

  // ── Visualizer editor ────────────────────────────────────────────────────

  Widget _buildVisualizerEditor(
    BuildContext context,
    VisualizerOverlay vizItem,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intensity
        _LabeledSlider(
          label: 'Intensity',
          value: vizItem.intensity,
          min: AppConstants.minIntensity,
          max: AppConstants.maxIntensity,
          onChanged: (v) => overlayNotifier.updateItem(
            vizItem.id,
            (item) => (item as VisualizerOverlay).copyWith(intensity: v),
          ),
          displayValue: '${(vizItem.intensity * 100).toInt()}%',
        ),
        const SizedBox(height: 8),

        // Bar Count
        _LabeledSlider(
          label: 'Bar Count',
          value: vizItem.barCount.toDouble(),
          min: AppConstants.minBarCount.toDouble(),
          max: AppConstants.maxBarCount.toDouble(),
          onChanged: (v) => overlayNotifier.updateItem(
            vizItem.id,
            (item) => (item as VisualizerOverlay).copyWith(barCount: v.round()),
          ),
          displayValue: vizItem.barCount.toString(),
        ),
        const SizedBox(height: 8),

        // Smoothing
        _LabeledSlider(
          label: 'Smoothing',
          value: vizItem.smoothing,
          min: AppConstants.minSmoothing,
          max: AppConstants.maxSmoothing,
          onChanged: (v) => overlayNotifier.updateItem(
            vizItem.id,
            (item) => (item as VisualizerOverlay).copyWith(smoothing: v),
          ),
          displayValue: '${(vizItem.smoothing * 100).toInt()}%',
        ),
        const SizedBox(height: 12),

        // Colors
        ColorPickerWidget(
          label: 'Bar Start',
          currentColor: vizItem.colorStart,
          onColorChanged: (c) => overlayNotifier.updateItem(
            vizItem.id,
            (item) => (item as VisualizerOverlay).copyWith(colorStart: c),
          ),
        ),
        const SizedBox(height: 12),
        ColorPickerWidget(
          label: 'Bar End',
          currentColor: vizItem.colorEnd,
          onColorChanged: (c) => overlayNotifier.updateItem(
            vizItem.id,
            (item) => (item as VisualizerOverlay).copyWith(colorEnd: c),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Gradient', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            SizedBox(
              height: 24,
              child: Switch(
                value: vizItem.useGradient,
                onChanged: (v) => overlayNotifier.updateItem(
                  vizItem.id,
                  (item) =>
                      (item as VisualizerOverlay).copyWith(useGradient: v),
                ),
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Auto Rotate (Circular)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            SizedBox(
              height: 24,
              child: Switch(
                value: vizItem.autoRotate,
                onChanged: (v) => overlayNotifier.updateItem(
                  vizItem.id,
                  (item) => (item as VisualizerOverlay).copyWith(autoRotate: v),
                ),
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _fontWeightLabel(FontWeight w) {
    if (w == FontWeight.w300) return 'Light';
    if (w == FontWeight.w400) return 'Regular';
    if (w == FontWeight.w500) return 'Medium';
    if (w == FontWeight.w700) return 'Bold';
    if (w == FontWeight.w900) return 'Black';
    return 'Regular';
  }

  static FontWeight _fontWeightFromLabel(String label) {
    switch (label) {
      case 'Light':
        return FontWeight.w300;
      case 'Medium':
        return FontWeight.w500;
      case 'Bold':
        return FontWeight.w700;
      case 'Black':
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }
}

// ─── Mini icon button ───────────────────────────────────────────────────────

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ───────────────────────────────────────────────────────

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
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
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
                  .map(
                    (e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              iconSize: 14,
              isDense: true,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
