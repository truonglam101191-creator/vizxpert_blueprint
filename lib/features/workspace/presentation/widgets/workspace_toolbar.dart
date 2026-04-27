import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Layout preset configurations.
enum LayoutPreset {
  standard('Standard', 'Default balanced layout'),
  compact('Compact', 'Narrow panels, max canvas'),
  wide('Wide', 'Wider panels for detailed editing'),
  cinematic('Cinematic', 'Full canvas, hide panels');

  const LayoutPreset(this.label, this.description);
  final String label;
  final String description;
}

/// Current state of panel visibility and sizes.
class LayoutConfig {
  const LayoutConfig({
    this.showSidebar = true,
    this.showProperties = true,
    this.showTimeline = true,
    this.sidebarWidth = 220.0,
    this.propertiesWidth = 280.0,
    this.timelineHeight = 130.0,
  });

  final bool showSidebar;
  final bool showProperties;
  final bool showTimeline;
  final double sidebarWidth;
  final double propertiesWidth;
  final double timelineHeight;

  LayoutConfig copyWith({
    bool? showSidebar,
    bool? showProperties,
    bool? showTimeline,
    double? sidebarWidth,
    double? propertiesWidth,
    double? timelineHeight,
  }) {
    return LayoutConfig(
      showSidebar: showSidebar ?? this.showSidebar,
      showProperties: showProperties ?? this.showProperties,
      showTimeline: showTimeline ?? this.showTimeline,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      propertiesWidth: propertiesWidth ?? this.propertiesWidth,
      timelineHeight: timelineHeight ?? this.timelineHeight,
    );
  }

  /// Preset layouts.
  static LayoutConfig fromPreset(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.standard:
        return const LayoutConfig();
      case LayoutPreset.compact:
        return const LayoutConfig(
          sidebarWidth: 180,
          propertiesWidth: 240,
          timelineHeight: 90,
        );
      case LayoutPreset.wide:
        return const LayoutConfig(
          sidebarWidth: 280,
          propertiesWidth: 360,
          timelineHeight: 160,
        );
      case LayoutPreset.cinematic:
        return const LayoutConfig(
          showSidebar: false,
          showProperties: false,
          showTimeline: false,
        );
    }
  }
}

/// Toolbar tray at the top of the workspace.
///
/// Provides:
/// - Panel visibility toggles (Sidebar, Properties, Timeline)
/// - Layout presets (Standard, Compact, Wide, Cinematic)
/// - Reset layout button
class WorkspaceToolbar extends StatelessWidget {
  const WorkspaceToolbar({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onPresetSelected,
    required this.onResetLayout,
  });

  final LayoutConfig config;
  final ValueChanged<LayoutConfig> onConfigChanged;
  final ValueChanged<LayoutPreset> onPresetSelected;
  final VoidCallback onResetLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ── Panel toggles ──────────────────────────────────────────
          _ToolbarToggle(
            icon: Icons.view_sidebar_rounded,
            label: 'Sidebar',
            isActive: config.showSidebar,
            onTap: () => onConfigChanged(
              config.copyWith(showSidebar: !config.showSidebar),
            ),
          ),
          const SizedBox(width: 2),
          _ToolbarToggle(
            icon: Icons.tune_rounded,
            label: 'Properties',
            isActive: config.showProperties,
            onTap: () => onConfigChanged(
              config.copyWith(showProperties: !config.showProperties),
            ),
          ),
          const SizedBox(width: 2),
          _ToolbarToggle(
            icon: Icons.linear_scale_rounded,
            label: 'Timeline',
            isActive: config.showTimeline,
            onTap: () => onConfigChanged(
              config.copyWith(showTimeline: !config.showTimeline),
            ),
          ),

          // ── Separator ──────────────────────────────────────────────
          const _ToolbarSeparator(),

          // ── Layout presets ─────────────────────────────────────────
          _LayoutPresetMenu(onPresetSelected: onPresetSelected),

          const SizedBox(width: 4),

          // ── Reset button ───────────────────────────────────────────
          _ToolbarIconButton(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Reset Layout',
            onTap: onResetLayout,
          ),

          const Spacer(),

          // ── Keyboard shortcuts hint ────────────────────────────────
          Text(
            '⌘1 Sidebar  ⌘2 Properties  ⌘3 Timeline  ⌘0 Reset',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted.withValues(alpha: 0.6),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle button ──────────────────────────────────────────────────────────

class _ToolbarToggle extends StatefulWidget {
  const _ToolbarToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_ToolbarToggle> createState() => _ToolbarToggleState();
}

class _ToolbarToggleState extends State<_ToolbarToggle> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : (_hovering
                      ? AppColors.surface.withValues(alpha: 0.5)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
            border: widget.isActive
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isActive
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isActive
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
}

// ─── Layout preset menu ─────────────────────────────────────────────────────

class _LayoutPresetMenu extends StatelessWidget {
  const _LayoutPresetMenu({required this.onPresetSelected});

  final ValueChanged<LayoutPreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LayoutPreset>(
      onSelected: onPresetSelected,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      offset: const Offset(0, 32),
      tooltip: 'Layout Presets',
      itemBuilder: (_) => LayoutPreset.values.map((preset) {
        return PopupMenuItem(
          value: preset,
          child: Row(
            children: [
              Icon(
                _presetIcon(preset),
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    preset.description,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_customize_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Layout',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  IconData _presetIcon(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.standard:
        return Icons.view_module_rounded;
      case LayoutPreset.compact:
        return Icons.view_compact_rounded;
      case LayoutPreset.wide:
        return Icons.view_sidebar_rounded;
      case LayoutPreset.cinematic:
        return Icons.fullscreen_rounded;
    }
  }
}

// ─── Small helper widgets ───────────────────────────────────────────────────

class _ToolbarSeparator extends StatelessWidget {
  const _ToolbarSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.divider,
    );
  }
}

class _ToolbarIconButton extends StatefulWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hovering
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovering ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
