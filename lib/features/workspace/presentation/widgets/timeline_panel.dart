import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/audio_provider.dart';

/// Bottom timeline panel: seekable progress slider, time display, transport controls.
class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final notifier = ref.read(audioProvider.notifier);

    final posMs = audio.position.inMilliseconds.toDouble();
    final durMs = audio.duration.inMilliseconds.toDouble();
    final sliderMax = durMs > 0 ? durMs : 1.0;

    return Container(
      color: AppColors.panelBackground,
      child: Column(
        children: [
          const Divider(height: 1),

          // ── Waveform-like progress area ───────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Slider ────────────────────────────────────────
                  SliderTheme(
                    data: Theme.of(context).sliderTheme.copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surface,
                          thumbColor: AppColors.textPrimary,
                        ),
                    child: Slider(
                      value: posMs.clamp(0, sliderMax),
                      max: sliderMax,
                      onChanged: audio.hasFile
                          ? (v) => notifier
                              .seek(Duration(milliseconds: v.round()))
                          : null,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ── Time + transport ──────────────────────────────
                  Row(
                    children: [
                      // Time display
                      Text(
                        _formatDuration(audio.position),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                      ),
                      Text(
                        ' / ${_formatDuration(audio.duration)}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                      ),

                      const Spacer(),

                      // ── Transport controls ─────────────────────────
                      _TransportButton(
                        icon: Icons.skip_previous_rounded,
                        onPressed: audio.hasFile
                            ? () =>
                                notifier.seek(Duration.zero)
                            : null,
                        tooltip: 'Rewind',
                      ),
                      const SizedBox(width: 6),
                      _PlayButton(
                        isPlaying: audio.isPlaying,
                        enabled: audio.hasFile,
                        onPressed: audio.hasFile
                            ? () => notifier.togglePlayPause()
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _TransportButton(
                        icon: Icons.stop_rounded,
                        onPressed: audio.hasFile
                            ? () => notifier.stop()
                            : null,
                        tooltip: 'Stop',
                      ),
                      const SizedBox(width: 6),
                      _TransportButton(
                        icon: Icons.skip_next_rounded,
                        onPressed: audio.hasFile
                            ? () => notifier
                                .seek(audio.duration)
                            : null,
                        tooltip: 'Forward',
                      ),
                    ],
                  ),
                ],
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
    return '$minutes:$seconds';
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
        color: enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 26,
              color: AppColors.textOnAccent,
            ),
          ),
        ),
      ),
    );
  }
}
