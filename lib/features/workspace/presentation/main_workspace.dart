import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';
import '../../audio_processing/providers/fft_provider.dart';
import '../providers/ui_config_provider.dart';
import 'widgets/canvas_preview.dart';
import 'widgets/properties_panel.dart';
import 'widgets/sidebar_panel.dart';
import 'widgets/timeline_panel.dart';
import 'widgets/workspace_toolbar.dart';

/// Root workspace layout — DAW-style three-column + timeline shell.
///
/// ```
/// ┌────────────────────────────────────────────────┐
/// │              Toolbar Tray                       │
/// ├──────────┬──────────────────────┬──────────────┤
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
  LayoutConfig _layoutConfig = const LayoutConfig();

  @override
  void initState() {
    super.initState();

    // Start FFT ticker after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fftProvider.notifier).start(this);
    });
  }

  void _applyPreset(LayoutPreset preset) {
    setState(() => _layoutConfig = LayoutConfig.fromPreset(preset));
  }

  void _resetLayout() {
    setState(() => _layoutConfig = const LayoutConfig());
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () {
          setState(
            () => _layoutConfig = _layoutConfig.copyWith(
              showSidebar: !_layoutConfig.showSidebar,
            ),
          );
        },
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () {
          setState(
            () => _layoutConfig = _layoutConfig.copyWith(
              showProperties: !_layoutConfig.showProperties,
            ),
          );
        },
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () {
          setState(
            () => _layoutConfig = _layoutConfig.copyWith(
              showTimeline: !_layoutConfig.showTimeline,
            ),
          );
        },
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
            _resetLayout,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.scaffold,
          body: Column(
            children: [
              // ── Toolbar Tray ──────────────────────────────────────────
              WorkspaceToolbar(
                config: _layoutConfig,
                onConfigChanged: (c) => setState(() => _layoutConfig = c),
                onPresetSelected: _applyPreset,
                onResetLayout: _resetLayout,
              ),

              // ── Main area (sidebar + canvas + properties) ─────────────
              Expanded(
                child: Row(
                  children: [
                    // ── Sidebar ─────────────────────────────────────────
                    if (_layoutConfig.showSidebar) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _layoutConfig.sidebarWidth,
                        child: const SidebarPanel(),
                      ),
                      _VerticalResizeHandle(
                        onDrag: (dx) => setState(() {
                          _layoutConfig = _layoutConfig.copyWith(
                            sidebarWidth: (_layoutConfig.sidebarWidth + dx)
                                .clamp(
                                  AppConstants.sidebarMinWidth,
                                  AppConstants.sidebarMaxWidth,
                                ),
                          );
                        }),
                      ),
                    ],

                    // ── Canvas ──────────────────────────────────────────
                    const Expanded(child: CanvasPreview()),

                    // ── Properties ──────────────────────────────────────
                    if (_layoutConfig.showProperties) ...[
                      _VerticalResizeHandle(
                        onDrag: (dx) => setState(() {
                          _layoutConfig = _layoutConfig.copyWith(
                            propertiesWidth:
                                (_layoutConfig.propertiesWidth - dx).clamp(
                                  AppConstants.propertiesMinWidth,
                                  AppConstants.propertiesMaxWidth,
                                ),
                          );
                        }),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _layoutConfig.propertiesWidth,
                        child: const PropertiesPanel(),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Timeline ──────────────────────────────────────────────
              if (_layoutConfig.showTimeline) ...[
                _HorizontalResizeHandle(
                  onDrag: (dy) => setState(() {
                    _layoutConfig = _layoutConfig.copyWith(
                      timelineHeight: (_layoutConfig.timelineHeight - dy).clamp(
                        AppConstants.timelineMinHeight,
                        AppConstants.timelineMaxHeight,
                      ),
                    );
                  }),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _layoutConfig.timelineHeight,
                  child: const TimelinePanel(),
                ),
              ],
            ],
          ),
        ),
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
