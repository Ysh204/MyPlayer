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

  Future<void> stop() => player.stop();

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

  Future<void> dispose() => player.dispose();
}
