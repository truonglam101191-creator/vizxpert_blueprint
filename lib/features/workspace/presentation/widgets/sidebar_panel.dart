import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/audio_provider.dart';
import '../../../export/providers/export_provider.dart';
import '../../../overlay/domain/shape_overlay.dart';
import '../../../overlay/providers/overlay_provider.dart';
import '../../providers/ui_config_provider.dart';

/// Left sidebar: logo, audio import, overlay tools, visualizer mode, export.
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  Future<void> _importAudio(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac'],
      dialogTitle: 'Import Audio File',
    );
    if (result != null && result.files.single.path != null) {
      final notifier = ref.read(audioProvider.notifier);
      await notifier.initEngine();
      await notifier.loadFile(result.files.single.path!);
    }
  }

  Future<void> _importImage(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: 'Add Image Overlay',
    );
    if (result != null && result.files.single.path != null) {
      ref.read(overlayProvider.notifier).addImage(
            imagePath: result.files.single.path!,
          );
    }
  }

  Future<void> _setBackgroundImage(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: 'Set Background Image',
    );
    if (result != null && result.files.single.path != null) {
      ref.read(overlayProvider.notifier).setBackgroundImage(
            result.files.single.path!,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final uiConfig = ref.watch(uiConfigProvider);
    final exportState = ref.watch(exportProvider);

    return Container(
      color: AppColors.panelBackground,
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'VizXpert',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Import Audio ─────────────────────────────────────────────
          _SidebarButton(
            icon: Icons.audio_file_rounded,
            label: 'Import Audio',
            onTap: () => _importAudio(ref),
          ),

          // ── Loaded file info ─────────────────────────────────────────
          if (audioState.hasFile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        audioState.fileName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // ── Overlay Tools Section ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERLAY TOOLS',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          _SidebarButton(
            icon: Icons.text_fields_rounded,
            label: 'Add Text',
            onTap: () => ref.read(overlayProvider.notifier).addText(),
          ),
          _SidebarButton(
            icon: Icons.add_photo_alternate_rounded,
            label: 'Add Image',
            onTap: () => _importImage(ref),
          ),

          // Shape submenu
          _ShapeMenuButton(
            onShapeSelected: (type) =>
                ref.read(overlayProvider.notifier).addShape(shapeType: type),
          ),

          _SidebarButton(
            icon: Icons.wallpaper_rounded,
            label: 'Background Image',
            onTap: () => _setBackgroundImage(ref),
          ),

          const Divider(height: 1),

          // ── Visualizer Mode ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISUALIZER MODE',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _ModeToggle(
                  selected: uiConfig.visualizerType,
                  onChanged: (type) =>
                      ref.read(uiConfigProvider.notifier).setVisualizerType(type),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Export ────────────────────────────────────────────────────
          if (exportState.isExporting)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: exportState.progress,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exportState.status == ExportStatus.preparingFrames
                        ? 'Capturing frames… ${(exportState.progress * 100).toInt()}%'
                        : 'Encoding video…',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            )
          else if (exportState.status == ExportStatus.done)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Export complete!',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          _SidebarButton(
            icon: Icons.movie_creation_rounded,
            label: 'Export Video',
            accent: true,
            enabled: audioState.hasFile && !exportState.isExporting,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature ready!')),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: accent
            ? (enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          hoverColor: accent
              ? AppColors.primaryLight.withValues(alpha: 0.2)
              : AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: accent
                        ? AppColors.textOnAccent
                        : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? (accent
                            ? AppColors.textOnAccent
                            : AppColors.textPrimary)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeMenuButton extends StatelessWidget {
  const _ShapeMenuButton({required this.onShapeSelected});

  final ValueChanged<ShapeType> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: PopupMenuButton<ShapeType>(
          onSelected: onShapeSelected,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          offset: const Offset(0, 36),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: ShapeType.rectangle,
              child: Row(
                children: [
                  Icon(Icons.crop_square_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Rectangle', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: ShapeType.circle,
              child: Row(
                children: [
                  Icon(Icons.circle_outlined, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Circle', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: ShapeType.triangle,
              child: Row(
                children: [
                  Icon(Icons.change_history_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Triangle', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: ShapeType.line,
              child: Row(
                children: [
                  Icon(Icons.horizontal_rule_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Line', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.category_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(
                  'Add Shape',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selected, required this.onChanged});

  final VisualizerType selected;
  final ValueChanged<VisualizerType> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildItem(VisualizerType type) {
      final isSelected = type == selected;
      IconData icon;
      String label;
      switch (type) {
        case VisualizerType.bars:
          icon = Icons.equalizer_rounded;
          label = 'Bars';
          break;
        case VisualizerType.circular:
          icon = Icons.donut_large_rounded;
          label = 'Circular';
          break;
        case VisualizerType.symmetricBars:
          icon = Icons.graphic_eq_rounded;
          label = 'Symmetric';
          break;
        case VisualizerType.wave:
          icon = Icons.waves_rounded;
          label = 'Wave';
          break;
      }

      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                  : Border.all(color: Colors.transparent),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Row(
              children: [
                buildItem(VisualizerType.bars),
                const SizedBox(width: 4),
                buildItem(VisualizerType.circular),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                buildItem(VisualizerType.symmetricBars),
                const SizedBox(width: 4),
                buildItem(VisualizerType.wave),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
