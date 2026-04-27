import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Collapsible section used inside the Properties Panel.
///
/// Header row with title + chevron, tapping toggles the body visibility
/// with a smooth animation.
class PanelSection extends StatefulWidget {
  const PanelSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<PanelSection> createState() => _PanelSectionState();
}

class _PanelSectionState extends State<PanelSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconTurns = _controller.drive(
      Tween(begin: 0.0, end: 0.25).chain(CurveTween(curve: Curves.easeInOut)),
    );
    if (_expanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                RotationTransition(
                  turns: _iconTurns,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
        // ── Body ─────────────────────────────────────────────────────
        ClipRect(
          child: FadeTransition(
            opacity: _heightFactor,
            child: SizeTransition(
              sizeFactor: _heightFactor,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: widget.child,
              ),
            ),
          ),
        ),
        // Divider
        const Divider(height: 1),
      ],
    );
  }
}
