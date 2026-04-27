import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/overlay_item.dart';
import '../domain/text_overlay.dart';
import '../domain/image_overlay.dart';
import '../domain/shape_overlay.dart';

// ─── State ──────────────────────────────────────────────────────────────────

@immutable
class OverlayState {
  const OverlayState({
    this.items = const [],
    this.selectedItemId,
    this.backgroundImagePath,
  });

  /// All overlay items sorted by zIndex before painting.
  final List<OverlayItem> items;

  /// Currently selected item id (null = nothing selected).
  final String? selectedItemId;

  /// Optional background image path (rendered below visualizer).
  final String? backgroundImagePath;

  /// The currently selected item, or null.
  OverlayItem? get selectedItem {
    if (selectedItemId == null) return null;
    try {
      return items.firstWhere((e) => e.id == selectedItemId);
    } catch (_) {
      return null;
    }
  }

  /// Items sorted by zIndex for rendering.
  List<OverlayItem> get sortedItems {
    final sorted = List<OverlayItem>.from(items);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sorted;
  }

  OverlayState copyWith({
    List<OverlayItem>? items,
    String? selectedItemId,
    String? backgroundImagePath,
    bool clearSelection = false,
    bool clearBackground = false,
  }) {
    return OverlayState(
      items: items ?? this.items,
      selectedItemId:
          clearSelection ? null : (selectedItemId ?? this.selectedItemId),
      backgroundImagePath: clearBackground
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class OverlayNotifier extends Notifier<OverlayState> {
  @override
  OverlayState build() => const OverlayState();

  // ── Helpers ────────────────────────────────────────────────────────

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${random.nextInt(99999).toString().padLeft(5, '0')}';
  }

  int _nextZIndex() {
    if (state.items.isEmpty) return 0;
    return state.items.map((e) => e.zIndex).reduce(max) + 1;
  }

  // ── Add items ──────────────────────────────────────────────────────

  void addText({TextOverlay? template}) {
    final item = (template ?? TextOverlay(id: _generateId())).copyWith(
      id: _generateId(),
      zIndex: _nextZIndex(),
    );
    state = state.copyWith(
      items: [...state.items, item],
      selectedItemId: item.id,
    );
  }

  void addImage({required String imagePath}) {
    final item = ImageOverlay(
      id: _generateId(),
      imagePath: imagePath,
      zIndex: _nextZIndex(),
    );
    state = state.copyWith(
      items: [...state.items, item],
      selectedItemId: item.id,
    );
  }

  void addShape({ShapeType shapeType = ShapeType.rectangle}) {
    final item = ShapeOverlay(
      id: _generateId(),
      shapeType: shapeType,
      zIndex: _nextZIndex(),
    );
    state = state.copyWith(
      items: [...state.items, item],
      selectedItemId: item.id,
    );
  }

  // ── Remove ─────────────────────────────────────────────────────────

  void removeItem(String id) {
    final newItems = state.items.where((e) => e.id != id).toList();
    state = OverlayState(
      items: newItems,
      selectedItemId:
          state.selectedItemId == id ? null : state.selectedItemId,
      backgroundImagePath: state.backgroundImagePath,
    );
  }

  // ── Update ─────────────────────────────────────────────────────────

  void updateItem(String id, OverlayItem Function(OverlayItem) updater) {
    final newItems = state.items.map((item) {
      if (item.id == id) return updater(item);
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  // ── Selection ──────────────────────────────────────────────────────

  void selectItem(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedItemId: id);
    }
  }

  void clearSelection() => selectItem(null);

  // ── Transform ──────────────────────────────────────────────────────

  void updatePosition(String id, Offset position) {
    updateItem(id, (item) => item.copyWith(position: position));
  }

  void updateSize(String id, Size size) {
    updateItem(id, (item) => item.copyWith(size: size));
  }

  void updateRotation(String id, double rotation) {
    updateItem(id, (item) => item.copyWith(rotation: rotation));
  }

  void updateOpacity(String id, double opacity) {
    updateItem(id, (item) => item.copyWith(opacity: opacity));
  }

  void toggleVisibility(String id) {
    updateItem(id, (item) => item.copyWith(isVisible: !item.isVisible));
  }

  void toggleLock(String id) {
    updateItem(id, (item) => item.copyWith(isLocked: !item.isLocked));
  }

  // ── Layer ordering ─────────────────────────────────────────────────

  void moveToFront(String id) {
    updateItem(id, (item) => item.copyWith(zIndex: _nextZIndex()));
  }

  void moveToBack(String id) {
    final minZ = state.items.isEmpty
        ? 0
        : state.items.map((e) => e.zIndex).reduce(min) - 1;
    updateItem(id, (item) => item.copyWith(zIndex: minZ));
  }

  void moveUp(String id) {
    final sorted = state.sortedItems;
    final idx = sorted.indexWhere((e) => e.id == id);
    if (idx < 0 || idx >= sorted.length - 1) return;
    final above = sorted[idx + 1];
    updateItem(id, (item) => item.copyWith(zIndex: above.zIndex + 1));
  }

  void moveDown(String id) {
    final sorted = state.sortedItems;
    final idx = sorted.indexWhere((e) => e.id == id);
    if (idx <= 0) return;
    final below = sorted[idx - 1];
    updateItem(id, (item) => item.copyWith(zIndex: below.zIndex - 1));
  }

  // ── Background image ──────────────────────────────────────────────

  void setBackgroundImage(String? path) {
    if (path == null) {
      state = state.copyWith(clearBackground: true);
    } else {
      state = state.copyWith(backgroundImagePath: path);
    }
  }

  // ── Duplicate ──────────────────────────────────────────────────────

  void duplicateItem(String id) {
    final item = state.items.firstWhere((e) => e.id == id);
    final newId = _generateId();
    final shifted = item.copyWith(
      id: newId,
      position: Offset(
        (item.position.dx + 0.03).clamp(0.0, 0.9),
        (item.position.dy + 0.03).clamp(0.0, 0.9),
      ),
      zIndex: _nextZIndex(),
    );
    state = state.copyWith(
      items: [...state.items, shifted],
      selectedItemId: newId,
    );
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final overlayProvider =
    NotifierProvider<OverlayNotifier, OverlayState>(OverlayNotifier.new);
