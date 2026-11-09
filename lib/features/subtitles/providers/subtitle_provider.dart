import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/subtitle_style_model.dart';
import '../../../services/player_service.dart';
import '../../player/providers/player_provider.dart';

class SubtitleNotifier extends StateNotifier<SubtitleConfig> {
  final PlayerService _playerService;

  SubtitleNotifier(this._playerService) : super(const SubtitleConfig());

  Future<void> setVerticalPosition(double position) {
    state = state.copyWith(
        verticalPosition: position.clamp(10.0, 105.0).toDouble());
    return _playerService.applySubtitleSettings(state);
  }

  Future<void> setFontSize(double size) {
    final safeSize = size.clamp(14.0, 54.0).toDouble();
    state = state.copyWith(fontSize: safeSize, scale: safeSize / 24.0);
    return _playerService.applySubtitleSettings(state);
  }

  void setBackgroundOpacity(double opacity) {
    state =
        state.copyWith(backgroundOpacity: opacity.clamp(0.0, 1.0).toDouble());
  }

  Future<void> adjustDelay(double deltaSeconds) {
    state = state.copyWith(
      delaySeconds:
          (state.delaySeconds + deltaSeconds).clamp(-5.0, 5.0).toDouble(),
    );
    return _playerService.applySubtitleSettings(state);
  }

  Future<void> resetDelay() {
    state = state.copyWith(delaySeconds: 0.0);
    return _playerService.applySubtitleSettings(state);
  }

  Future<void> loadExternalSubtitle(String path) async {
    await _playerService.loadSubtitleFile(path);
    state = state.copyWith(externalFilePath: path);
    await _playerService.applySubtitleSettings(state);
  }
}

final subtitleProvider =
    StateNotifierProvider<SubtitleNotifier, SubtitleConfig>((ref) {
  return SubtitleNotifier(ref.watch(playerServiceProvider));
});
