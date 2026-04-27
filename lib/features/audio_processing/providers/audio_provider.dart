import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../../core/utils/app_constants.dart';

// ─── State ──────────────────────────────────────────────────────────────────

enum PlaybackStatus { idle, playing, paused, stopped }

@immutable
class AudioState {
  const AudioState({
    this.filePath,
    this.fileName,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final String? filePath;
  final String? fileName;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;

  bool get hasFile => filePath != null;
  bool get isPlaying => status == PlaybackStatus.playing;

  AudioState copyWith({
    String? filePath,
    String? fileName,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
  }) {
    return AudioState(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class AudioNotifier extends Notifier<AudioState> {
  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _source;
  SoundHandle? _handle;
  Timer? _positionTimer;

  @override
  AudioState build() => const AudioState();

  // ── Lifecycle ──────────────────────────────────────────────────────

  Future<void> initEngine() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }
    _soloud.setVisualizationEnabled(true);
  }

  // ── File loading ───────────────────────────────────────────────────

  Future<void> loadFile(String path) async {
    await stop();

    // Dispose previous source
    if (_source != null) {
      _soloud.disposeSource(_source!);
      _source = null;
    }

    _source = await _soloud.loadFile(path);
    final dur = _soloud.getLength(_source!);
    final name = path.split('/').last;

    state = AudioState(
      filePath: path,
      fileName: name,
      status: PlaybackStatus.stopped,
      duration: dur,
    );
  }

  // ── Transport controls ─────────────────────────────────────────────

  Future<void> play() async {
    if (_source == null) return;

    if (state.status == PlaybackStatus.paused && _handle != null) {
      _soloud.setPause(_handle!, false);
    } else {
      _handle = _soloud.play(_source!);
    }

    state = state.copyWith(status: PlaybackStatus.playing);
    _startPositionPolling();
  }

  Future<void> pause() async {
    if (_handle == null) return;
    _soloud.setPause(_handle!, true);
    _stopPositionPolling();
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    if (_handle != null) {
      _soloud.stop(_handle!);
      _handle = null;
    }
    _stopPositionPolling();
    state = state.copyWith(
      status: state.hasFile ? PlaybackStatus.stopped : PlaybackStatus.idle,
      position: Duration.zero,
    );
  }

  Future<void> seek(Duration position) async {
    if (_handle == null) return;
    _soloud.seek(_handle!, position);
    state = state.copyWith(position: position);
  }

  // ── Position polling ───────────────────────────────────────────────

  void _startPositionPolling() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(
      AppConstants.positionPollInterval,
      (_) => _pollPosition(),
    );
  }

  void _stopPositionPolling() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _pollPosition() {
    if (_handle == null || !state.isPlaying) return;

    final pos = _soloud.getPosition(_handle!);
    if (pos >= state.duration && state.duration > Duration.zero) {
      stop();
      return;
    }
    state = state.copyWith(position: pos);
  }

  // ── Mute (for export) ─────────────────────────────────────────────

  void setVolume(double volume) {
    if (_handle != null) {
      _soloud.setVolume(_handle!, volume);
    }
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final audioProvider =
    NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);
