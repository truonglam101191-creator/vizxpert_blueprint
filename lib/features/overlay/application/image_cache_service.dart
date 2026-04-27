import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Caches decoded [ui.Image] instances keyed by file path.
///
/// Used by overlay painters and the export pipeline to avoid
/// re-decoding the same image every frame.
class ImageCacheService {
  ImageCacheService._();

  static final ImageCacheService instance = ImageCacheService._();

  final Map<String, ui.Image> _cache = {};

  /// Returns a cached [ui.Image] for [path], loading it if needed.
  Future<ui.Image?> getImage(String path) async {
    if (_cache.containsKey(path)) return _cache[path];

    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      _cache[path] = image;
      return image;
    } catch (e) {
      debugPrint('ImageCacheService: Failed to load $path — $e');
      return null;
    }
  }

  /// Check if an image is already cached.
  bool isCached(String path) => _cache.containsKey(path);

  /// Get a cached image synchronously (returns null if not yet loaded).
  ui.Image? getCachedImage(String path) => _cache[path];

  /// Evict a single image from cache.
  void evict(String path) {
    _cache.remove(path)?.dispose();
  }

  /// Dispose all cached images and clear the cache.
  void disposeAll() {
    for (final img in _cache.values) {
      img.dispose();
    }
    _cache.clear();
  }
}
