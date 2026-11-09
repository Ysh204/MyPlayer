import 'package:media_kit/media_kit.dart';

import '../data/models/subtitle_style_model.dart';
import 'mpv_properties.dart';

class SubtitleService {
  final Player _player;

  const SubtitleService(this._player);

  Future<void> applySubtitleFraming(SubtitleConfig config) async {
    await MpvProperties.setProperty(
      _player,
      'sub-pos',
      config.verticalPosition.round().toString(),
    );
    await MpvProperties.setProperty(
      _player,
      'sub-scale',
      config.scale.toStringAsFixed(2),
    );
    await MpvProperties.setProperty(
      _player,
      'sub-delay',
      config.delaySeconds.toStringAsFixed(3),
    );
  }

  Future<void> loadExternalSubtitle(String path) async {
    await _player.setSubtitleTrack(SubtitleTrack.uri(path));
  }
}
