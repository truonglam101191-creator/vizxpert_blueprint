import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/audio_provider.dart';
import '../../../overlay/providers/overlay_provider.dart';
import '../../../overlay/domain/overlay_item.dart';
import '../../../overlay/domain/text_overlay.dart';
import '../../../overlay/domain/image_overlay.dart';
import '../../../overlay/domain/shape_overlay.dart';
import '../../../overlay/domain/visualizer_overlay.dart';

/// Bottom timeline panel: seekable progress slider, time display, transport controls,
/// and draggable time-range tracks for each overlay.
class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final notifier = ref.read(audioProvider.notifier);
    final overlayState = ref.watch(overlayProvider);

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

          // ── Track list with draggable time bars ─────────────────
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                buildDefaultDragHandles: false,
                itemCount: reversedItems.length,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex -= 1;

                  final item = reversedItems.removeAt(oldIndex);
                  reversedItems.insert(newIndex, item);

                  // reversedItems is top→bottom; reverse to get lowest→highest zIndex
                  final newlySorted = reversedItems.reversed.toList();
                  final overlayNotifier = ref.read(overlayProvider.notifier);
                  for (int i = 0; i < newlySorted.length; i++) {
                    overlayNotifier.updateItem(
                      newlySorted[i].id,
                      (item) => item.copyWith(zIndex: i),
                    );
                  }
                },
                itemBuilder: (context, index) {
                  final item = reversedItems[index];
                  final isSelected = item.id == overlayState.selectedItemId;

                  IconData iconData;
                  String title;
                  Color trackColor;
                  if (item is TextOverlay) {
                    iconData = Icons.title_rounded;
                    title = item.text.isNotEmpty ? item.text : 'Text';
                    trackColor = const Color(0xFF4CAF50);
                  } else if (item is ImageOverlay) {
                    iconData = Icons.image_rounded;
                    title = 'Image';
                    trackColor = const Color(0xFF2196F3);
                  } else if (item is ShapeOverlay) {
                    iconData = item.shapeType == ShapeType.circle
                        ? Icons.circle_outlined
                        : Icons.square_outlined;
                    title = 'Shape';
                    trackColor = const Color(0xFFFF9800);
                  } else if (item is VisualizerOverlay) {
                    iconData = Icons.waves_rounded;
                    title = 'Visualizer';
                    trackColor = AppColors.primary;
                  } else {
                    iconData = Icons.layers_rounded;
                    title = 'Layer';
                    trackColor = const Color(0xFF9E9E9E);
                  }

                  return _TimelineTrack(
                    key: ValueKey(item.id),
                    item: item,
                    title: title,
                    icon: iconData,
                    trackColor: trackColor,
                    isSelected: isSelected,
                    totalDurationMs: durMs > 0 ? durMs.toInt() : 60000,
                    index: index,
                    onTap: () =>
                        ref.read(overlayProvider.notifier).selectItem(item.id),
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
    final hundredths = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
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

// ─── Timeline Track with Draggable Bar ──────────────────────────────────────

class _TimelineTrack extends ConsumerStatefulWidget {
  const _TimelineTrack({
    super.key,
    required this.item,
    required this.title,
    required this.icon,
    required this.trackColor,
    required this.isSelected,
    required this.totalDurationMs,
    required this.index,
    required this.onTap,
  });

  final OverlayItem item;
  final String title;
  final IconData icon;
  final Color trackColor;
  final bool isSelected;
  final int totalDurationMs;
  final int index;
  final VoidCallback onTap;

  @override
  ConsumerState<_TimelineTrack> createState() => _TimelineTrackState();
}

class _TimelineTrackState extends ConsumerState<_TimelineTrack> {
  static const double _labelWidth = 120.0;
  static const double _handleWidth = 8.0;
  static const double _trackHeight = 36.0;

  _DragMode? _dragMode;

  double get _startFraction => widget.item.startTimeMs / widget.totalDurationMs;

  double get _endFraction =>
      (widget.item.endTimeMs ?? widget.totalDurationMs) /
      widget.totalDurationMs;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected ? AppColors.surface : Colors.transparent;
    final borderColor = widget.isSelected
        ? AppColors.primary
        : AppColors.divider;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: _trackHeight,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            // ── Drag handle for reordering ─────────────────────────
            ReorderableDragStartListener(
              index: widget.index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            // ── Label section ──────────────────────────────────────
            SizedBox(
              width: _labelWidth - 28, // account for drag handle
              child: Row(
                children: [
                  Icon(widget.icon, size: 14, color: widget.trackColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Vertical divider ──────────────────────────────────
            Container(width: 1, color: AppColors.divider),

            // ── Track area with draggable bar ─────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  final barLeft = _startFraction * trackWidth;
                  final barRight = _endFraction * trackWidth;
                  final barWidth = (barRight - barLeft).clamp(
                    _handleWidth * 2,
                    trackWidth,
                  );

                  return GestureDetector(
                    onHorizontalDragStart: (d) => _onDragStart(d, trackWidth),
                    onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
                    onHorizontalDragEnd: (_) => _dragMode = null,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        // Track background
                        Positioned.fill(
                          child: Container(
                            color: AppColors.surface.withValues(alpha: 0.3),
                          ),
                        ),

                        // Time bar (visual only, not the gesture source)
                        Positioned(
                          left: barLeft,
                          top: 4,
                          bottom: 4,
                          width: barWidth,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.trackColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: widget.isSelected
                                      ? widget.trackColor
                                      : widget.trackColor.withValues(
                                          alpha: 0.7,
                                        ),
                                  width: widget.isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left handle
                                  MouseRegion(
                                    cursor: SystemMouseCursors.resizeColumn,
                                    child: Container(
                                      width: _handleWidth,
                                      decoration: BoxDecoration(
                                        color: widget.trackColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          bottomLeft: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Middle (time label)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '${_formatMs(widget.item.startTimeMs)} → ${_formatMs(widget.item.endTimeMs ?? widget.totalDurationMs)}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white70,
                                          fontFamily: 'monospace',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Right handle
                                  MouseRegion(
                                    cursor: SystemMouseCursors.resizeColumn,
                                    child: Container(
                                      width: _handleWidth,
                                      decoration: BoxDecoration(
                                        color: widget.trackColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(3),
                                          bottomRight: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDragStart(DragStartDetails details, double trackWidth) {
    final localX = details.localPosition.dx;
    final barLeft = _startFraction * trackWidth;
    final barRight = _endFraction * trackWidth;

    // Check if touching the left handle zone
    if (localX >= barLeft && localX <= barLeft + _handleWidth) {
      _dragMode = _DragMode.left;
    }
    // Check if touching the right handle zone
    else if (localX >= barRight - _handleWidth && localX <= barRight) {
      _dragMode = _DragMode.right;
    }
    // Check if touching the bar body
    else if (localX > barLeft + _handleWidth &&
        localX < barRight - _handleWidth) {
      _dragMode = _DragMode.body;
    }
    // Touching outside the bar → no drag
    else {
      _dragMode = null;
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_dragMode == null || trackWidth <= 0) return;

    final deltaMs = (details.delta.dx / trackWidth * widget.totalDurationMs)
        .round();
    final item = widget.item;
    final currentStart = item.startTimeMs;
    final currentEnd = item.endTimeMs ?? widget.totalDurationMs;
    final notifier = ref.read(overlayProvider.notifier);

    switch (_dragMode!) {
      case _DragMode.left:
        final newStart = (currentStart + deltaMs).clamp(0, currentEnd - 500);
        notifier.updateTimeRange(item.id, startTimeMs: newStart);
      case _DragMode.right:
        final newEnd = (currentEnd + deltaMs).clamp(
          currentStart + 500,
          widget.totalDurationMs,
        );
        notifier.updateTimeRange(item.id, endTimeMs: newEnd);
      case _DragMode.body:
        final duration = currentEnd - currentStart;
        var newStart = currentStart + deltaMs;
        var newEnd = currentEnd + deltaMs;
        if (newStart < 0) {
          newStart = 0;
          newEnd = duration;
        }
        if (newEnd > widget.totalDurationMs) {
          newEnd = widget.totalDurationMs;
          newStart = newEnd - duration;
        }
        notifier.updateTimeRange(
          item.id,
          startTimeMs: newStart,
          endTimeMs: newEnd,
        );
    }
  }

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

enum _DragMode { left, right, body }
