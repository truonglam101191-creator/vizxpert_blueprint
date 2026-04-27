import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/audio_provider.dart';
import '../../../overlay/providers/overlay_provider.dart';
import '../../../overlay/domain/text_overlay.dart';
import '../../../overlay/domain/image_overlay.dart';
import '../../../overlay/domain/shape_overlay.dart';

/// Bottom timeline panel: seekable progress slider, time display, transport controls.
class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final notifier = ref.read(audioProvider.notifier);
    final overlayState = ref.watch(overlayProvider);
    final overlayNotifier = ref.read(overlayProvider.notifier);

    final posMs = audio.position.inMilliseconds.toDouble();
    final durMs = audio.duration.inMilliseconds.toDouble();
    final sliderMax = durMs > 0 ? durMs : 1.0;

    // Display top layer at the top of the list
    final reversedItems = overlayState.sortedItems.reversed.toList();

    return Container(
      color: AppColors.panelBackground,
      child: Column(
        children: [
          const Divider(height: 1),

          // ── Waveform-like progress area & transport ──────────────
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Slider ────────────────────────────────────────
                  SizedBox(
                    height: 20,
                    child: SliderTheme(
                      data: Theme.of(context).sliderTheme.copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surface,
                        thumbColor: AppColors.textPrimary,
                      ),
                      child: Slider(
                        value: posMs.clamp(0, sliderMax),
                        max: sliderMax,
                        onChanged: audio.hasFile
                            ? (v) => notifier.seek(
                                Duration(milliseconds: v.round()),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // ── Time + transport ──────────────────────────────
                  Row(
                    children: [
                      // Time display
                      Text(
                        _formatDuration(audio.position),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' / ${_formatDuration(audio.duration)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),

                      const Spacer(),

                      // ── Transport controls ─────────────────────────
                      _TransportButton(
                        icon: Icons.skip_previous_rounded,
                        onPressed: audio.hasFile
                            ? () => notifier.seek(Duration.zero)
                            : null,
                        tooltip: 'Rewind',
                      ),
                      const SizedBox(width: 4),
                      _PlayButton(
                        isPlaying: audio.isPlaying,
                        enabled: audio.hasFile,
                        onPressed: audio.hasFile
                            ? () => notifier.togglePlayPause()
                            : null,
                      ),
                      const SizedBox(width: 4),
                      _TransportButton(
                        icon: Icons.stop_rounded,
                        onPressed: audio.hasFile ? () => notifier.stop() : null,
                        tooltip: 'Stop',
                      ),
                      const SizedBox(width: 4),
                      _TransportButton(
                        icon: Icons.skip_next_rounded,
                        onPressed: audio.hasFile
                            ? () => notifier.seek(audio.duration)
                            : null,
                        tooltip: 'Forward',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Layer List (Timeline Tracks) ──────────────────────────
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                buildDefaultDragHandles: false,
                itemCount:
                    reversedItems.length +
                    1, // +1 for the visualizer track at the bottom
                onReorder: (oldIndex, newIndex) {
                  // We only allow reordering the overlay items (indices 0 to reversedItems.length - 1)
                  // The last item (Visualizer) cannot be reordered.
                  if (oldIndex == reversedItems.length ||
                      newIndex > reversedItems.length) {
                    return;
                  }
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final item = reversedItems.removeAt(oldIndex);
                  reversedItems.insert(newIndex, item);

                  // Now reversedItems is top-to-bottom. We want zIndex to be lowest at the end of the list.
                  // So we reverse it back to get sortedItems (lowest to highest)
                  final newlySorted = reversedItems.reversed.toList();

                  // Update zIndex via notifier
                  // We bypass reorderItems and just update all items' zIndex
                  for (int i = 0; i < newlySorted.length; i++) {
                    overlayNotifier.updateItem(
                      newlySorted[i].id,
                      (item) => item.copyWith(zIndex: i),
                    );
                  }
                },
                itemBuilder: (context, index) {
                  if (index == reversedItems.length) {
                    // Visualizer track (locked at bottom)
                    return _LayerItemWidget(
                      key: const ValueKey('visualizer_track'),
                      title: 'Spectrum',
                      icon: Icons.waves_rounded,
                      isSelected: false,
                      isLocked: true,
                      onTap: () {},
                      index: index,
                    );
                  }

                  final item = reversedItems[index];
                  final isSelected = item.id == overlayState.selectedItemId;

                  IconData iconData;
                  String title;
                  if (item is TextOverlay) {
                    iconData = Icons.title_rounded;
                    title = item.text.isNotEmpty ? item.text : 'Text';
                  } else if (item is ImageOverlay) {
                    iconData = Icons.image_rounded;
                    title = 'Image';
                  } else if (item is ShapeOverlay) {
                    iconData = item.shapeType == ShapeType.circle
                        ? Icons.circle_outlined
                        : Icons.square_outlined;
                    title = 'Shape';
                  } else {
                    iconData = Icons.layers_rounded;
                    title = 'Layer';
                  }

                  return _LayerItemWidget(
                    key: ValueKey(item.id),
                    title: title,
                    icon: iconData,
                    isSelected: isSelected,
                    isLocked: false,
                    onTap: () => overlayNotifier.selectItem(item.id),
                    index: index,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }
}

// ─── Transport button widgets ───────────────────────────────────────────────

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.surface,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null
                  ? AppColors.transportIcon
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.enabled,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying ? 'Pause' : 'Play',
      child: Material(
        color: enabled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 26,
              color: AppColors.textOnAccent,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Layer Item Widget ──────────────────────────────────────────────────────

class _LayerItemWidget extends StatelessWidget {
  const _LayerItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
    required this.index,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.surface : Colors.transparent;
    final borderColor = isSelected ? AppColors.primary : AppColors.divider;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLocked)
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  )
                else
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: AppColors.textMuted,
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
