import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/time_formatter.dart';
import '../../../services/player_service.dart';

final playerServiceProvider = Provider<PlayerService>((ref) {
  final service = PlayerService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final playerVideoControllerProvider = Provider<VideoController>(
  (ref) => ref.watch(playerServiceProvider).videoController,
);

final playerPositionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerServiceProvider).positionStream,
);

final playerDurationProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerServiceProvider).durationStream,
);

final playerBufferProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerServiceProvider).bufferStream,
);

final playerBufferingProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerServiceProvider).bufferingStream,
);

final playerPlayingProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerServiceProvider).playingStream,
);

final playerCompletedProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerServiceProvider).completedStream,
);

final playerTracksProvider = StreamProvider<Tracks>(
  (ref) => ref.watch(playerServiceProvider).tracksStream,
);

final playerCurrentTrackProvider = StreamProvider<Track>(
  (ref) => ref.watch(playerServiceProvider).currentTrackStream,
);

final playerPlaylistProvider = StreamProvider<Playlist>(
  (ref) => ref.watch(playerServiceProvider).playlistStream,
);

final playerErrorProvider = StreamProvider<String>(
  (ref) => ref.watch(playerServiceProvider).errorStream,
);

// OSD (On-Screen Display) State & Notifier
class OsdState {
  final String text;
  final String? subtext;
  final IconData icon;
  final double? progress;
  final int sequence;
  final bool visible;

  const OsdState({
    required this.text,
    this.subtext,
    required this.icon,
    this.progress,
    required this.sequence,
    this.visible = true,
  });

  static const hidden = OsdState(
    text: '',
    icon: Icons.info_outline,
    sequence: 0,
    visible: false,
  );
}

class OsdNotifier extends StateNotifier<OsdState> {
  Timer? _hideTimer;
  int _sequence = 0;

  OsdNotifier() : super(OsdState.hidden);

  void show({
    required String text,
    String? subtext,
    required IconData icon,
    double? progress,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    _hideTimer?.cancel();
    _sequence++;
    state = OsdState(
      text: text,
      subtext: subtext,
      icon: icon,
      progress: progress,
      sequence: _sequence,
      visible: true,
    );
    _hideTimer = Timer(duration, () {
      if (mounted) {
        state = OsdState.hidden;
      }
    });
  }

  void hide() {
    _hideTimer?.cancel();
    state = OsdState.hidden;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

final osdProvider = StateNotifierProvider<OsdNotifier, OsdState>((ref) {
  return OsdNotifier();
});

class PlaybackControlsState {
  final double speed;
  final double volume;
  final Duration? pendingSeekTarget;

  const PlaybackControlsState({
    this.speed = 1.0,
    this.volume = 100.0,
    this.pendingSeekTarget,
  });

  PlaybackControlsState copyWith({
    double? speed,
    double? volume,
    Duration? pendingSeekTarget,
    bool clearPendingSeek = false,
  }) {
    return PlaybackControlsState(
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      pendingSeekTarget:
          clearPendingSeek ? null : (pendingSeekTarget ?? this.pendingSeekTarget),
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackControlsState> {
  static const _savedVolumeKey = 'player_saved_volume';

  final PlayerService _playerService;
  final Ref _ref;
  Duration? _pendingSeekTarget;
  Duration _accumulatedSeekOffset = Duration.zero;
  Timer? _seekCommitTimer;
  Timer? _pendingSeekExpiryTimer;
  double _lastNonZeroVolume = 100.0;

  PlaybackNotifier(this._playerService, this._ref)
      : super(const PlaybackControlsState()) {
    unawaited(_restoreSavedVolume());
  }

  Future<void> _restoreSavedVolume() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedVolume = preferences.getDouble(_savedVolumeKey);
      if (savedVolume != null && savedVolume >= 0.0) {
        state = state.copyWith(volume: savedVolume);
        if (savedVolume > 0) _lastNonZeroVolume = savedVolume;
        await _playerService.setVolume(savedVolume);
      }
    } catch (_) {}
  }

  Future<void> openFile(String path) {
    _clearPendingSeek();
    return _playerService.openFile(path);
  }

  Future<void> openFiles(List<String> paths) {
    _clearPendingSeek();
    return _playerService.openFiles(paths);
  }

  Future<void> addToQueue(String path) => _playerService.addToQueue(path);

  Future<void> next() {
    _clearPendingSeek();
    return _playerService.next();
  }

  Future<void> previous() {
    _clearPendingSeek();
    return _playerService.previous();
  }

  Future<void> stop() {
    _clearPendingSeek();
    return _playerService.stop();
  }

  Future<void> jumpTo(int index) => _playerService.jumpTo(index);

  Future<void> moveInQueue(int from, int to) =>
      _playerService.moveInQueue(from, to);

  Future<void> removeFromQueue(int index) =>
      _playerService.removeFromQueue(index);

  Future<void> clearQueue() => _playerService.clearQueue();

  Future<Uint8List?> screenshot() => _playerService.screenshot();

  Future<void> playOrPause() async {
    await _playerService.playOrPause();
    final isPlaying = _playerService.isPlaying;
    _ref.read(osdProvider.notifier).show(
          text: isPlaying ? 'Pause' : 'Play',
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        );
  }

  Future<void> seekTo(Duration position, {bool showOsd = true}) {
    final target = _boundedPosition(position);
    _clearPendingSeek();
    _rememberSeekTarget(target);

    if (showOsd) {
      final total = _playerService.currentDuration;
      _ref.read(osdProvider.notifier).show(
            text: '${formatDuration(target)} / ${formatDuration(total)}',
            icon: Icons.fast_forward_rounded,
          );
    }

    return _playerService.seek(target);
  }

  Future<void> seekBy(Duration offset) {
    final basePosition =
        _pendingSeekTarget ?? _playerService.currentPosition;
    final target = _boundedPosition(basePosition + offset);
    _accumulatedSeekOffset += offset;
    _rememberSeekTarget(target);

    // Subtle OSD feedback showing accumulated offset and target position
    final isForward = _accumulatedSeekOffset >= Duration.zero;
    final sign = isForward ? '+' : '-';
    final offsetSeconds = _accumulatedSeekOffset.inSeconds.abs();
    final total = _playerService.currentDuration;

    _ref.read(osdProvider.notifier).show(
          text: '$sign${offsetSeconds}s',
          subtext: '${formatDuration(target)} / ${formatDuration(total)}',
          icon: isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
        );

    // Coalesce rapid seek-key presses so libmpv receives a single seek after tapping stops
    _seekCommitTimer?.cancel();
    _seekCommitTimer = Timer(const Duration(milliseconds: 90), () {
      _seekCommitTimer = null;
      _accumulatedSeekOffset = Duration.zero;
      unawaited(_playerService.seek(target));
    });

    return Future<void>.value();
  }

  Future<void> setRate(double rate) async {
    await _playerService.setRate(rate);
    state = state.copyWith(speed: rate);
    _ref.read(osdProvider.notifier).show(
          text: '${rate}x',
          subtext: rate == 1.0 ? 'Normal Speed' : null,
          icon: Icons.speed_rounded,
        );
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = volume.clamp(0.0, 150.0).toDouble();
    if (safeVolume > 0) _lastNonZeroVolume = safeVolume;
    state = state.copyWith(volume: safeVolume);
    await _playerService.setVolume(safeVolume);

    final isMuted = safeVolume == 0.0;
    _ref.read(osdProvider.notifier).show(
          text: isMuted ? 'Muted' : 'Volume: ${safeVolume.round()}%',
          progress: safeVolume / 100.0,
          icon: isMuted
              ? Icons.volume_off_rounded
              : (safeVolume < 50
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded),
        );

    unawaited(_persistVolume(safeVolume));
  }

  Future<void> toggleMute() async {
    if (state.volume > 0) {
      _lastNonZeroVolume = state.volume;
      await setVolume(0);
    } else {
      await setVolume(_lastNonZeroVolume > 0 ? _lastNonZeroVolume : 100.0);
    }
  }

  Future<void> changeVolumeBy(double step) => setVolume(state.volume + step);

  Future<void> _persistVolume(double volume) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble(_savedVolumeKey, volume);
    } catch (_) {}
  }

  Duration _boundedPosition(Duration position) {
    final safePosition = position.isNegative ? Duration.zero : position;
    final duration = _playerService.currentDuration;
    if (duration > Duration.zero && safePosition > duration) return duration;
    return safePosition;
  }

  void _rememberSeekTarget(Duration target) {
    _pendingSeekTarget = target;
    state = state.copyWith(pendingSeekTarget: target);
    _pendingSeekExpiryTimer?.cancel();
    _pendingSeekExpiryTimer = Timer(const Duration(milliseconds: 1200), () {
      _pendingSeekTarget = null;
      if (mounted) {
        state = state.copyWith(clearPendingSeek: true);
      }
      _pendingSeekExpiryTimer = null;
    });
  }

  void _clearPendingSeek() {
    _seekCommitTimer?.cancel();
    _seekCommitTimer = null;
    _pendingSeekExpiryTimer?.cancel();
    _pendingSeekExpiryTimer = null;
    _pendingSeekTarget = null;
    _accumulatedSeekOffset = Duration.zero;
    if (mounted) {
      state = state.copyWith(clearPendingSeek: true);
    }
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    await _playerService.setAudioTrack(track);
    _ref.read(osdProvider.notifier).show(
          text: 'Audio: ${track.title ?? track.language ?? track.id}',
          icon: Icons.audiotrack_rounded,
        );
  }

  Future<void> setVideoTrack(VideoTrack track) async {
    await _playerService.setVideoTrack(track);
    _ref.read(osdProvider.notifier).show(
          text: 'Video Track: ${track.id}',
          icon: Icons.videocam_rounded,
        );
  }

  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    await _playerService.setSubtitleTrack(track);
    final label = track.id == 'no'
        ? 'Off'
        : (track.id == 'auto' ? 'Auto' : (track.title ?? track.language ?? track.id));
    _ref.read(osdProvider.notifier).show(
          text: 'Subtitles: $label',
          icon: Icons.subtitles_rounded,
        );
  }

  Future<void> loadExternalAudio(String path) async {
    await _playerService.loadExternalAudio(path);
    _ref.read(osdProvider.notifier).show(
          text: 'Loaded Audio Track',
          subtext: path.split(RegExp(r'[/\\]')).last,
          icon: Icons.audiotrack_rounded,
        );
  }

  @override
  void dispose() {
    _clearPendingSeek();
    super.dispose();
  }
}

final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackControlsState>((ref) {
  return PlaybackNotifier(ref.watch(playerServiceProvider), ref);
});

enum ActiveDrawerPanel { none, audio, subtitles, playlist }

final activeDrawerProvider = StateProvider<ActiveDrawerPanel>(
  (ref) => ActiveDrawerPanel.none,
);
