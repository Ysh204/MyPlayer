import 'dart:typed_data';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

import '../data/models/eq_state.dart';
import '../data/models/subtitle_style_model.dart';
import 'audio_filter_builder.dart';
import 'mpv_properties.dart';
import 'subtitle_service.dart';

class PlayerService {
  late final Player player;
  late final VideoController videoController;
  late final SubtitleService subtitleService;

  PlayerService() {
    player = Player(
      configuration: const PlayerConfiguration(title: 'MyPlayer Pro'),
    );
    videoController = VideoController(player);
    subtitleService = SubtitleService(player);
  }

  // Stream accessors for player state
  Stream<Playlist> get playlistStream => player.stream.playlist;
  Stream<bool> get playingStream => player.stream.playing;
  Stream<bool> get completedStream => player.stream.completed;
  Stream<Duration> get positionStream => player.stream.position;
  Stream<Duration> get durationStream => player.stream.duration;
  Stream<Duration> get bufferStream => player.stream.buffer;
  Stream<bool> get bufferingStream => player.stream.buffering;
  Stream<double> get volumeStream => player.stream.volume;
  Stream<double> get rateStream => player.stream.rate;
  Stream<Tracks> get tracksStream => player.stream.tracks;
  Stream<Track> get currentTrackStream => player.stream.track;
  Stream<String> get errorStream => player.stream.error;

  Duration get currentPosition => player.state.position;
  Duration get currentDuration => player.state.duration;
  Playlist get currentPlaylist => player.state.playlist;
  Tracks get currentTracks => player.state.tracks;
  Track get currentTrack => player.state.track;
  double get currentVolume => player.state.volume;
  double get currentRate => player.state.rate;
  bool get isPlaying => player.state.playing;

  Future<void> openFile(String path) => player.open(Media(path));

  Future<void> openFiles(List<String> paths) {
    final medias = paths.map(Media.new).toList(growable: false);
    return player.open(Playlist(medias));
  }

  Future<void> addToQueue(String path) async {
    if (player.state.playlist.medias.isEmpty) {
      await openFile(path);
      return;
    }
    await player.add(Media(path));
  }

  Future<void> next() => player.next();

  Future<void> previous() => player.previous();

  Future<void> stop() async {
    try {
      await player.setVolume(0);
    } catch (_) {}
    await player.stop();
  }

  Future<void> jumpTo(int index) => player.jump(index);

  Future<void> moveInQueue(int from, int to) => player.move(from, to);

  Future<void> removeFromQueue(int index) => player.remove(index);

  Future<void> clearQueue() async {
    while (player.state.playlist.medias.isNotEmpty) {
      await player.remove(player.state.playlist.medias.length - 1);
    }
  }

  Future<Uint8List?> screenshot() => player.screenshot(format: 'image/png');

  Future<void> playOrPause() => player.playOrPause();

  Future<void> seek(Duration position) =>
      player.seek(position.isNegative ? Duration.zero : position);

  Future<void> setRate(double rate) => player.setRate(rate);

  Future<void> setVolume(double volume) => player.setVolume(volume);

  Future<void> setPrecisionSeeking(bool enabled) =>
      MpvProperties.setProperty(player, 'hr-seek', enabled ? 'yes' : 'no');

  Future<void> setAudioTrack(AudioTrack track) => player.setAudioTrack(track);

  Future<void> setVideoTrack(VideoTrack track) => player.setVideoTrack(track);

  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      player.setSubtitleTrack(track);

  Future<void> loadExternalAudio(String path) => player.setAudioTrack(
        AudioTrack.uri(path, title: p.basenameWithoutExtension(path)),
      );

  Future<void> applyAudioSettings(EqState eq) async {
    await MpvProperties.setProperty(player, 'af', buildAudioFilter(eq));
    await MpvProperties.setProperty(
      player,
      'audio-delay',
      eq.audioDelaySec.toStringAsFixed(3),
    );
  }

  Future<void> applySubtitleSettings(SubtitleConfig config) =>
      subtitleService.applySubtitleFraming(config);

  Future<void> loadSubtitleFile(String path) =>
      subtitleService.loadExternalSubtitle(path);

  Future<void> dispose() async {
    try {
      await player.setVolume(0);
      await player.stop();
    } catch (_) {}
    await player.dispose();
  }
}
