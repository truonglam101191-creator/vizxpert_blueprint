import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';
import '../../audio_processing/providers/fft_provider.dart';
import '../providers/ui_config_provider.dart';
import 'widgets/canvas_preview.dart';
import 'widgets/properties_panel.dart';
import 'widgets/sidebar_panel.dart';
import 'widgets/timeline_panel.dart';

/// Root workspace layout — DAW-style three-column + timeline shell.
///
/// ```
/// ┌──────────┬──────────────────────┬──────────────┐
/// │ Sidebar  │   Canvas Preview     │  Properties  │
/// │          │                      │  Panel       │
/// ├──────────┴──────────────────────┴──────────────┤
/// │                Timeline                        │
/// └────────────────────────────────────────────────┘
/// ```
class MainWorkspace extends ConsumerStatefulWidget {
  const MainWorkspace({super.key});

  @override
  ConsumerState<MainWorkspace> createState() => _MainWorkspaceState();
}

class _MainWorkspaceState extends ConsumerState<MainWorkspace>
    with TickerProviderStateMixin {
  double _sidebarWidth = AppConstants.sidebarWidth;
  double _propertiesWidth = AppConstants.propertiesWidth;
  double _timelineHeight = AppConstants.timelineHeight;

  @override
  void initState() {
    super.initState();

    // Start FFT ticker after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fftProvider.notifier).start(this);
      _syncFftConfig();
    });
  }

  void _syncFftConfig() {
    final config = ref.read(uiConfigProvider);
    ref.read(fftProvider.notifier).updateConfig(
          barCount: config.barCount,
          smoothing: config.smoothing,
          intensity: config.intensity,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Keep FFT config in sync with UI config
    ref.listen(uiConfigProvider, (_, next) {
      ref.read(fftProvider.notifier).updateConfig(
            barCount: next.barCount,
            smoothing: next.smoothing,
            intensity: next.intensity,
          );
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Main area (sidebar + canvas + properties) ─────────────
          Expanded(
            child: Row(
              children: [
                // ── Sidebar ─────────────────────────────────────────
                SizedBox(
                  width: _sidebarWidth,
                  child: const SidebarPanel(),
                ),
                _VerticalResizeHandle(
                  onDrag: (dx) => setState(() {
                    _sidebarWidth = (_sidebarWidth + dx).clamp(
                      AppConstants.sidebarMinWidth,
                      AppConstants.sidebarMaxWidth,
                    );
                  }),
                ),

                // ── Canvas ──────────────────────────────────────────
                const Expanded(child: CanvasPreview()),

                _VerticalResizeHandle(
                  onDrag: (dx) => setState(() {
                    _propertiesWidth = (_propertiesWidth - dx).clamp(
                      AppConstants.propertiesMinWidth,
                      AppConstants.propertiesMaxWidth,
                    );
                  }),
                ),

                // ── Properties ──────────────────────────────────────
                SizedBox(
                  width: _propertiesWidth,
                  child: const PropertiesPanel(),
                ),
              ],
            ),
          ),

          // ── Horizontal resize handle for timeline ─────────────────
          _HorizontalResizeHandle(
            onDrag: (dy) => setState(() {
              _timelineHeight = (_timelineHeight - dy).clamp(
                AppConstants.timelineMinHeight,
                AppConstants.timelineMaxHeight,
              );
            }),
          ),

          // ── Timeline ──────────────────────────────────────────────
          SizedBox(
            height: _timelineHeight,
            child: const TimelinePanel(),
          ),
        ],
      ),
    );
  }
}

// ─── Resize handles ─────────────────────────────────────────────────────────

class _VerticalResizeHandle extends StatefulWidget {
  const _VerticalResizeHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_VerticalResizeHandle> createState() => _VerticalResizeHandleState();
}

class _VerticalResizeHandleState extends State<_VerticalResizeHandle> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: AppConstants.resizeHandleWidth,
          color: _hovering
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
    );
  }
}

class _HorizontalResizeHandle extends StatefulWidget {
  const _HorizontalResizeHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_HorizontalResizeHandle> createState() =>
      _HorizontalResizeHandleState();
}

class _HorizontalResizeHandleState extends State<_HorizontalResizeHandle> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onVerticalDragUpdate: (d) => widget.onDrag(d.delta.dy),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: AppConstants.resizeHandleWidth,
          color: _hovering
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
    );
  }
}
