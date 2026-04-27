import 'dart:io';

/// Service to interact with a locally-installed FFmpeg CLI.
class FFmpegService {
  const FFmpegService();

  /// Verify that FFmpeg is available on the system PATH.
  Future<bool> checkAvailable() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      return result.exitCode == 0 &&
          (result.stdout as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get the resolved FFmpeg binary path.
  Future<String?> ffmpegPath() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }

  /// Encode a directory of sequential PNGs + an audio file into an MP4.
  ///
  /// [framesDir]   – absolute path to the directory containing frame_XXXXX.png
  /// [audioPath]   – absolute path to the source audio file
  /// [outputPath]  – absolute path for the resulting .mp4
  /// [fps]         – frames per second
  /// [resolution]  – target width×height (e.g. 1920×1080)
  /// [onProgress]  – optional callback with estimated 0.0–1.0 progress
  Future<FFmpegResult> encodeVideo({
    required String framesDir,
    required String audioPath,
    required String outputPath,
    required int fps,
    required ({int width, int height}) resolution,
    void Function(double progress)? onProgress,
  }) async {
    final ffmpeg = await ffmpegPath();
    if (ffmpeg == null) {
      return const FFmpegResult(
        success: false,
        message: 'FFmpeg not found. Install via: brew install ffmpeg',
      );
    }

    final framePattern = '$framesDir/frame_%05d.png';
    final args = [
      '-y', // overwrite
      '-framerate', '$fps',
      '-i', framePattern,
      '-i', audioPath,
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '18',
      '-pix_fmt', 'yuv420p',
      '-vf', 'scale=${resolution.width}:${resolution.height}',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-shortest',
      outputPath,
    ];

    try {
      final process = await Process.start(ffmpeg, args);

      // FFmpeg writes progress to stderr
      final stderrBuffer = StringBuffer();
      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        stderrBuffer.write(data);
        // Very rough progress estimation from FFmpeg output
        if (onProgress != null) {
          _parseProgress(data, onProgress);
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        return FFmpegResult(
          success: true,
          message: 'Video saved to $outputPath',
        );
      } else {
        return FFmpegResult(
          success: false,
          message: 'FFmpeg exited with code $exitCode:\n${stderrBuffer.toString().split('\n').last}',
        );
      }
    } catch (e) {
      return FFmpegResult(success: false, message: 'FFmpeg error: $e');
    }
  }

  void _parseProgress(String data, void Function(double) onProgress) {
    // Try to extract "frame= NNN" from FFmpeg output
    final frameMatch = RegExp(r'frame=\s*(\d+)').firstMatch(data);
    if (frameMatch != null) {
      // We don't know total frames here, caller must handle.
      // Just emit the frame number as a fraction assuming ~5000 frames max.
      final frame = int.tryParse(frameMatch.group(1)!) ?? 0;
      onProgress((frame / 5000).clamp(0.0, 1.0));
    }
  }

  /// Clean up temporary frame files.
  Future<void> cleanupFrames(String framesDir) async {
    final dir = Directory(framesDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// Result of an FFmpeg operation.
class FFmpegResult {
  const FFmpegResult({required this.success, this.message = ''});

  final bool success;
  final String message;
}
