import 'dart:typed_data';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  (ref) => ref.watch(playerServiceProvider).player.stream.position,
);

final playerDurationProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerServiceProvider).player.stream.duration,
);

final playerPlayingProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerServiceProvider).player.stream.playing,
);

final playerTracksProvider = StreamProvider<Tracks>(
  (ref) => ref.watch(playerServiceProvider).player.stream.tracks,
);

final playerCurrentTrackProvider = StreamProvider<Track>(
  (ref) => ref.watch(playerServiceProvider).player.stream.track,
);

final playerPlaylistProvider = StreamProvider<Playlist>(
  (ref) => ref.watch(playerServiceProvider).player.stream.playlist,
);

class PlaybackControlsState {
  final double speed;
  final double volume;

  const PlaybackControlsState({this.speed = 1.0, this.volume = 100.0});

  PlaybackControlsState copyWith({double? speed, double? volume}) {
    return PlaybackControlsState(
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackControlsState> {
  final PlayerService _playerService;
  Duration? _pendingSeekTarget;
  Timer? _seekCommitTimer;
  Timer? _pendingSeekExpiryTimer;

  PlaybackNotifier(this._playerService) : super(const PlaybackControlsState());

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

  Future<void> playOrPause() => _playerService.playOrPause();

  Future<void> seekTo(Duration position) {
    final target = _boundedPosition(position);
    _seekCommitTimer?.cancel();
    _seekCommitTimer = null;
    _rememberSeekTarget(target);
    return _playerService.seek(target);
  }

  Future<void> seekBy(Duration offset) {
    final currentPosition =
        _pendingSeekTarget ?? _playerService.player.state.position;
    final target = _boundedPosition(currentPosition + offset);
    _rememberSeekTarget(target);
    _seekCommitTimer?.cancel();
    _seekCommitTimer = Timer(const Duration(milliseconds: 75), () {
      _seekCommitTimer = null;
      unawaited(_playerService.seek(target));
    });
    return Future<void>.value();
  }

  Future<void> setRate(double rate) async {
    await _playerService.setRate(rate);
    state = state.copyWith(speed: rate);
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = volume.clamp(0.0, 150.0).toDouble();
    state = state.copyWith(volume: safeVolume);
    await _playerService.setVolume(safeVolume);
  }

  Future<void> changeVolumeBy(double step) => setVolume(state.volume + step);

  Duration _boundedPosition(Duration position) {
    final safePosition = position.isNegative ? Duration.zero : position;
    final duration = _playerService.player.state.duration;
    if (duration > Duration.zero && safePosition > duration) return duration;
    return safePosition;
  }

  void _rememberSeekTarget(Duration target) {
    _pendingSeekTarget = target;
    _pendingSeekExpiryTimer?.cancel();
    _pendingSeekExpiryTimer = Timer(const Duration(milliseconds: 1200), () {
      _pendingSeekTarget = null;
      _pendingSeekExpiryTimer = null;
    });
  }

  void _clearPendingSeek() {
    _seekCommitTimer?.cancel();
    _seekCommitTimer = null;
    _pendingSeekExpiryTimer?.cancel();
    _pendingSeekExpiryTimer = null;
    _pendingSeekTarget = null;
  }

  Future<void> setAudioTrack(AudioTrack track) =>
      _playerService.setAudioTrack(track);

  Future<void> setVideoTrack(VideoTrack track) =>
      _playerService.setVideoTrack(track);

  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      _playerService.setSubtitleTrack(track);

  Future<void> loadExternalAudio(String path) =>
      _playerService.loadExternalAudio(path);

  @override
  void dispose() {
    _clearPendingSeek();
    super.dispose();
  }
}

final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackControlsState>((ref) {
  return PlaybackNotifier(ref.watch(playerServiceProvider));
});

enum ActiveDrawerPanel { none, audio, subtitles, playlist }

final activeDrawerProvider = StateProvider<ActiveDrawerPanel>(
  (ref) => ActiveDrawerPanel.none,
);
