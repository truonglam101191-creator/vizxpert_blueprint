import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../audio_processing/providers/fft_provider.dart';
import '../../../rendering/presentation/visualizer_painter.dart';
import '../../providers/ui_config_provider.dart';

/// The main canvas area showing the real-time visualizer preview.
///
/// Maintains its own rotation angle for the circular visualiser and
/// delegates painting to [VisualizerPainterFactory].
class CanvasPreview extends ConsumerStatefulWidget {
  const CanvasPreview({super.key});

  @override
  ConsumerState<CanvasPreview> createState() => _CanvasPreviewState();
}

class _CanvasPreviewState extends ConsumerState<CanvasPreview>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0.0;
  late final Ticker _rotationTicker;

  @override
  void initState() {
    super.initState();
    // Slow continuous rotation for circular mode (~6 deg/s).
    _rotationTicker = createTicker((elapsed) {
      setState(() {
        _rotationAngle = elapsed.inMilliseconds / 1000.0 * 0.1; // radians/s
      });
    });
    _rotationTicker.start();
  }

  @override
  void dispose() {
    _rotationTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fftState = ref.watch(fftProvider);
    final uiConfig = ref.watch(uiConfigProvider);

    return Container(
      color: AppColors.scaffold,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
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
            child: CustomPaint(
              painter: VisualizerPainterFactory.create(
                config: uiConfig,
                fftBars: fftState.bars,
                rotationAngle: _rotationAngle,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}
