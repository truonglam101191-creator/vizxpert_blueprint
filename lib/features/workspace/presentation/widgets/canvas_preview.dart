import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/fft_provider.dart';
import '../../../overlay/application/image_cache_service.dart';
import '../../../overlay/domain/overlay_item.dart';
import '../../../overlay/presentation/widgets/draggable_overlay.dart';
import '../../../overlay/providers/overlay_provider.dart';
import '../../../rendering/presentation/painters/overlay_compositor.dart';
import '../../../rendering/presentation/visualizer_painter.dart';
import '../../providers/ui_config_provider.dart';

/// The main canvas area showing the real-time visualizer preview.
///
/// Multi-layer rendering stack:
/// 1. Background (color + optional image)
/// 2. Visualizer (bar/circular CustomPaint)
/// 3. Overlay items (text, image, shape via compositor)
/// 4. Interactive drag handles (Flutter widgets)
class CanvasPreview extends ConsumerStatefulWidget {
  const CanvasPreview({super.key});

  @override
  ConsumerState<CanvasPreview> createState() => _CanvasPreviewState();
}

class _CanvasPreviewState extends ConsumerState<CanvasPreview>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0.0;
  late final Ticker _rotationTicker;
  ui.Image? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _rotationTicker = createTicker((elapsed) {
      setState(() {
        _rotationAngle = elapsed.inMilliseconds / 1000.0 * 0.1;
      });
    });
    _rotationTicker.start();
  }

  @override
  void dispose() {
    _rotationTicker.dispose();
    super.dispose();
  }

  void _loadBackgroundIfNeeded(String? path) {
    if (path == null) {
      _backgroundImage = null;
      return;
    }
    if (ImageCacheService.instance.isCached(path)) {
      _backgroundImage = ImageCacheService.instance.getCachedImage(path);
      return;
    }
    // Async load
    ImageCacheService.instance.getImage(path).then((img) {
      if (mounted && img != null) {
        setState(() => _backgroundImage = img);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fftState = ref.watch(fftProvider);
    final uiConfig = ref.watch(uiConfigProvider);
    final overlayState = ref.watch(overlayProvider);

    // Load background image if changed
    _loadBackgroundIfNeeded(overlayState.backgroundImagePath);

    // Also preload overlay images
    for (final item in overlayState.items) {
      if (item.type == OverlayType.image) {
        final imgItem = item as dynamic;
        if (!ImageCacheService.instance.isCached(imgItem.imagePath)) {
          ImageCacheService.instance.getImage(imgItem.imagePath).then((_) {
            if (mounted) setState(() {});
          });
        }
      }
    }

    return Container(
      color: AppColors.scaffold,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return GestureDetector(
                // Tap on empty area to deselect
                onTap: () =>
                    ref.read(overlayProvider.notifier).clearSelection(),
                child: Container(
                  decoration: BoxDecoration(
                    color: uiConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.panelBorder.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // ── Layer 1: Visualizer ──────────────────────
                      Positioned.fill(
                        child: CustomPaint(
                          painter: VisualizerPainterFactory.create(
                            config: uiConfig,
                            fftBars: fftState.bars,
                            rotationAngle: _rotationAngle,
                          ),
                          size: Size.infinite,
                        ),
                      ),

                      // ── Layer 2: Overlay compositor ──────────────
                      Positioned.fill(
                        child: CustomPaint(
                          painter: OverlayCompositorPainter(
                            overlayItems: overlayState.sortedItems,
                            canvasSize: canvasSize,
                            selectedItemId: null, // handles drawn by widgets
                            backgroundImage: _backgroundImage,
                          ),
                          size: Size.infinite,
                        ),
                      ),

                      // ── Layer 3: Interactive drag handles ────────
                      ...overlayState.sortedItems
                          .where((item) => item.isVisible)
                          .map((item) => DraggableOverlay(
                                key: ValueKey(item.id),
                                item: item,
                                canvasSize: canvasSize,
                                isSelected:
                                    item.id == overlayState.selectedItemId,
                              )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
