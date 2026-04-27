import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/overlay_item.dart';
import '../../providers/overlay_provider.dart';

/// Interactive wrapper that renders drag handles around an [OverlayItem].
///
/// Supports:
/// - **Move**: drag the body to reposition
/// - **Resize**: drag corner/edge handles to resize
/// - **Select**: tap to select
class DraggableOverlay extends ConsumerStatefulWidget {
  const DraggableOverlay({
    super.key,
    required this.item,
    required this.canvasSize,
    required this.isSelected,
  });

  final OverlayItem item;
  final Size canvasSize;
  final bool isSelected;

  @override
  ConsumerState<DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends ConsumerState<DraggableOverlay> {
  /// Which handle is being dragged (null = moving the whole item).
  _HandleType? _activeHandle;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.isLocked && !widget.isSelected) return const SizedBox.shrink();

    final rect = item.absoluteRect(widget.canvasSize);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: item.rotation,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => ref.read(overlayProvider.notifier).selectItem(item.id),
          onPanStart: item.isLocked ? null : _onPanStart,
          onPanUpdate: item.isLocked ? null : _onPanUpdate,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Transparent hit area for the whole item
              Container(
                width: rect.width,
                height: rect.height,
                color: Colors.transparent,
              ),

              // Selection handles (only when selected)
              if (widget.isSelected && !item.isLocked) ...[
                // Border
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6C63FF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Corner handles
                _buildHandle(_HandleType.topLeft, Alignment.topLeft),
                _buildHandle(_HandleType.topRight, Alignment.topRight),
                _buildHandle(_HandleType.bottomLeft, Alignment.bottomLeft),
                _buildHandle(_HandleType.bottomRight, Alignment.bottomRight),

                // Edge handles
                _buildHandle(_HandleType.top, Alignment.topCenter),
                _buildHandle(_HandleType.bottom, Alignment.bottomCenter),
                _buildHandle(_HandleType.left, Alignment.centerLeft),
                _buildHandle(_HandleType.right, Alignment.centerRight),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(_HandleType type, Alignment alignment) {
    const size = 10.0;
    final isCorner = [
      _HandleType.topLeft,
      _HandleType.topRight,
      _HandleType.bottomLeft,
      _HandleType.bottomRight,
    ].contains(type);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: (_) => _activeHandle = type,
        onPanUpdate: _onHandleUpdate,
        onPanEnd: (_) => _activeHandle = null,
        child: Container(
          width: isCorner ? size : 8,
          height: isCorner ? size : 8,
          transform: Matrix4.translationValues(
            alignment.x * -size / 2,
            alignment.y * -size / 2,
            0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _activeHandle = null; // body drag
    ref.read(overlayProvider.notifier).selectItem(widget.item.id);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle != null) return; // handled by _onHandleUpdate
    if (widget.item.isLocked) return;

    final notifier = ref.read(overlayProvider.notifier);
    final item = widget.item;
    final dx = details.delta.dx / widget.canvasSize.width;
    final dy = details.delta.dy / widget.canvasSize.height;

    notifier.updatePosition(
      item.id,
      Offset(
        (item.position.dx + dx).clamp(0.0, 1.0 - item.size.width),
        (item.position.dy + dy).clamp(0.0, 1.0 - item.size.height),
      ),
    );
  }

  void _onHandleUpdate(DragUpdateDetails details) {
    if (_activeHandle == null || widget.item.isLocked) return;

    final notifier = ref.read(overlayProvider.notifier);
    final item = widget.item;
    final dx = details.delta.dx / widget.canvasSize.width;
    final dy = details.delta.dy / widget.canvasSize.height;

    var newPos = item.position;
    var newSize = item.size;
    const minSize = 0.03;

    switch (_activeHandle!) {
      case _HandleType.topLeft:
        newPos = Offset(item.position.dx + dx, item.position.dy + dy);
        newSize = Size(
          (item.size.width - dx).clamp(minSize, 1.0),
          (item.size.height - dy).clamp(minSize, 1.0),
        );
      case _HandleType.topRight:
        newPos = Offset(item.position.dx, item.position.dy + dy);
        newSize = Size(
          (item.size.width + dx).clamp(minSize, 1.0),
          (item.size.height - dy).clamp(minSize, 1.0),
        );
      case _HandleType.bottomLeft:
        newPos = Offset(item.position.dx + dx, item.position.dy);
        newSize = Size(
          (item.size.width - dx).clamp(minSize, 1.0),
          (item.size.height + dy).clamp(minSize, 1.0),
        );
      case _HandleType.bottomRight:
        newSize = Size(
          (item.size.width + dx).clamp(minSize, 1.0),
          (item.size.height + dy).clamp(minSize, 1.0),
        );
      case _HandleType.top:
        newPos = Offset(item.position.dx, item.position.dy + dy);
        newSize = Size(item.size.width, (item.size.height - dy).clamp(minSize, 1.0));
      case _HandleType.bottom:
        newSize = Size(item.size.width, (item.size.height + dy).clamp(minSize, 1.0));
      case _HandleType.left:
        newPos = Offset(item.position.dx + dx, item.position.dy);
        newSize = Size((item.size.width - dx).clamp(minSize, 1.0), item.size.height);
      case _HandleType.right:
        newSize = Size((item.size.width + dx).clamp(minSize, 1.0), item.size.height);
    }

    notifier.updatePosition(item.id, newPos);
    notifier.updateSize(item.id, newSize);
  }
}

enum _HandleType {
  topLeft, topRight, bottomLeft, bottomRight,
  top, bottom, left, right,
}
