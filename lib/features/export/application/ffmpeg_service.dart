import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service to interact with a locally-installed FFmpeg CLI.
///
/// Supports auto-detection and auto-download on:
///   • macOS  (arm64 / x86_64)
///   • Windows (x86_64)
///   • Linux  (x86_64)
///
/// On mobile platforms (Android / iOS) FFmpeg CLI is not available;
/// callers should integrate `ffmpeg_kit_flutter` or similar instead.
class FFmpegService {
  const FFmpegService();

  // ─── Platform detection helpers ──────────────────────────────────────────

  /// Returns the expected binary file name for the current OS.
  String get _binaryName {
    if (Platform.isWindows) return 'ffmpeg.exe';
    return 'ffmpeg'; // macOS, Linux
  }

  /// Returns `true` when the current platform can use a CLI binary.
  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  // ─── Resolve existing installation ───────────────────────────────────────

  /// Get the resolved FFmpeg binary path.
  ///
  /// Search order:
  /// 1. System PATH (`which` / `where`)
  /// 2. Common install locations (platform-specific)
  /// 3. App-local download directory
  Future<String?> ffmpegPath() async {
    if (!_isDesktop) return null; // Mobile/web – not supported

    // 1. System PATH lookup
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, [_binaryName]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim().split('\n').first.trim();
        if (path.isNotEmpty && File(path).existsSync()) return path;
      }
    } catch (_) {}

    // 2. Platform-specific common install locations
    final fallbacks = _platformFallbackPaths();
    for (final path in fallbacks) {
      if (File(path).existsSync()) return path;
    }

    // 3. App-local downloaded binary
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final localBin = File('${appDocs.path}/vizxpert_ffmpeg/$_binaryName');
      if (localBin.existsSync()) return localBin.path;
    } catch (_) {}

    return null;
  }

  /// Returns known fallback paths depending on the platform.
  List<String> _platformFallbackPaths() {
    if (Platform.isMacOS) {
      return ['/opt/homebrew/bin/ffmpeg', '/usr/local/bin/ffmpeg'];
    }
    if (Platform.isLinux) {
      return ['/usr/bin/ffmpeg', '/usr/local/bin/ffmpeg', '/snap/bin/ffmpeg'];
    }
    if (Platform.isWindows) {
      final programFiles =
          Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
      final programFilesX86 =
          Platform.environment['ProgramFiles(x86)'] ??
          r'C:\Program Files (x86)';
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ??
          r'C:\Users\Default\AppData\Local';
      return [
        r'C:\ffmpeg\bin\ffmpeg.exe',
        '$programFiles\\ffmpeg\\bin\\ffmpeg.exe',
        '$programFilesX86\\ffmpeg\\bin\\ffmpeg.exe',
        '$localAppData\\ffmpeg\\bin\\ffmpeg.exe',
      ];
    }
    return [];
  }

  // ─── Auto-download ───────────────────────────────────────────────────────

  /// Ensure FFmpeg is available. If not found locally, auto-downloads it.
  ///
  /// Returns the absolute path to the ffmpeg binary, or `null` if both
  /// local resolution and download fail.
  Future<String?> ensureAvailable({
    void Function(double progress)? onDownloadProgress,
  }) async {
    if (!_isDesktop) {
      debugPrint('FFmpegService: CLI not supported on this platform.');
      return null;
    }

    // 1. Try to find an existing installation
    final existing = await ffmpegPath();
    if (existing != null) return existing;

    // 2. Not found → download automatically
    return downloadFFmpeg(onProgress: onDownloadProgress);
  }

  /// Download FFmpeg locally if not found.
  ///
  /// Downloads the correct binary for the current OS + architecture.
  Future<String?> downloadFFmpeg({
    void Function(double progress)? onProgress,
  }) async {
    if (!_isDesktop) return null;

    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final ffmpegDir = Directory('${appDocs.path}/vizxpert_ffmpeg');
      if (!ffmpegDir.existsSync()) {
        ffmpegDir.createSync(recursive: true);
      }

      final ffmpegFile = File('${ffmpegDir.path}/$_binaryName');
      if (ffmpegFile.existsSync()) {
        return ffmpegFile.path;
      }

      // Resolve the download URL for this platform
      final downloadUrl = _downloadUrl();
      if (downloadUrl == null) {
        debugPrint('FFmpegService: No download URL for this platform.');
        return null;
      }

      final archiveExt = Platform.isWindows ? 'zip' : 'zip';
      final archiveFile = File('${ffmpegDir.path}/ffmpeg_download.$archiveExt');

      // ── Download ──────────────────────────────────────────────────
      final client = HttpClient();
      // Follow redirects (GitHub releases use them)
      client.autoUncompress = false;
      final request = await client.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 302) {
        debugPrint(
          'FFmpegService: Download failed with status ${response.statusCode}',
        );
        return null;
      }

      final contentLength = response.contentLength;
      int received = 0;

      final sink = archiveFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress((received / contentLength).clamp(0.0, 1.0));
        }
      }
      await sink.close();

      // ── Extract ─────────────────────────────────────────────────
      final extracted = await _extractArchive(archiveFile.path, ffmpegDir.path);

      if (!extracted) {
        debugPrint('FFmpegService: Extraction failed.');
        return null;
      }

      // ── Find the binary inside extracted contents ───────────────
      final resolvedBin = await _findBinaryInDir(ffmpegDir.path);
      if (resolvedBin == null) {
        debugPrint('FFmpegService: Binary not found after extraction.');
        return null;
      }

      // Move to expected location if not already there
      if (resolvedBin != ffmpegFile.path) {
        File(resolvedBin).copySync(ffmpegFile.path);
      }

      // ── Make executable (Unix) ──────────────────────────────────
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', ffmpegFile.path]);
      }

      // ── Clean up archive ────────────────────────────────────────
      if (archiveFile.existsSync()) archiveFile.deleteSync();

      // Clean up any extracted subdirectories
      for (final entity in ffmpegDir.listSync()) {
        if (entity is Directory) {
          entity.deleteSync(recursive: true);
        } else if (entity is File && entity.path != ffmpegFile.path) {
          // Keep only the binary
          final name = entity.uri.pathSegments.last;
          if (name != _binaryName) {
            entity.deleteSync();
          }
        }
      }

      return ffmpegFile.path;
    } catch (e) {
      debugPrint('FFmpegService: Download error: $e');
      return null;
    }
  }

  /// Returns the download URL for the current platform, or `null` if
  /// the platform/architecture is not supported for auto-download.
  String? _downloadUrl() {
    if (Platform.isMacOS) {
      // evermeet.cx provides static macOS builds (universal binary)
      return 'https://evermeet.cx/ffmpeg/getrelease/zip';
    }

    if (Platform.isWindows) {
      // BtbN/FFmpeg-Builds – Windows x64 GPL release
      return 'https://github.com/BtbN/FFmpeg-Builds/releases/download/'
          'latest/ffmpeg-master-latest-win64-gpl.zip';
    }

    if (Platform.isLinux) {
      // BtbN/FFmpeg-Builds – Linux x64 GPL release
      return 'https://github.com/BtbN/FFmpeg-Builds/releases/download/'
          'latest/ffmpeg-master-latest-linux64-gpl.tar.xz';
    }

    return null;
  }

  /// Extract a zip or tar.xz archive.
  Future<bool> _extractArchive(String archivePath, String destDir) async {
    ProcessResult result;

    if (archivePath.endsWith('.tar.xz')) {
      // Linux: tar.xz
      result = await Process.run('tar', ['-xf', archivePath, '-C', destDir]);
    } else {
      // macOS / Windows: zip
      if (Platform.isWindows) {
        // PowerShell Expand-Archive
        result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Expand-Archive',
          '-Path',
          '"$archivePath"',
          '-DestinationPath',
          '"$destDir"',
          '-Force',
        ]);
      } else {
        result = await Process.run('unzip', ['-o', archivePath, '-d', destDir]);
      }
    }

    return result.exitCode == 0;
  }

  /// Recursively search for the ffmpeg binary inside a directory.
  Future<String?> _findBinaryInDir(String dirPath) async {
    final dir = Directory(dirPath);
    final target = _binaryName;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.uri.pathSegments.last == target) {
        return entity.path;
      }
    }
    return null;
  }

  // ─── Encoding ────────────────────────────────────────────────────────────

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
    if (!_isDesktop) {
      return const FFmpegResult(
        success: false,
        message:
            'FFmpeg CLI is not supported on mobile platforms. '
            'Use ffmpeg_kit_flutter instead.',
      );
    }

    // Use ensureAvailable to guarantee FFmpeg is present (auto-downloads if needed)
    final ffmpeg = await ensureAvailable();
    if (ffmpeg == null) {
      return const FFmpegResult(
        success: false,
        message: 'FFmpeg not found and auto-download failed.',
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
          message:
              'FFmpeg exited with code $exitCode:\n${stderrBuffer.toString().split('\n').last}',
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

  // ─── Cleanup ─────────────────────────────────────────────────────────────

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
