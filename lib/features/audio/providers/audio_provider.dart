import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/eq_state.dart';
import '../../../services/player_service.dart';
import '../../player/providers/player_provider.dart';

final eqPresetsProvider = FutureProvider<List<EqPreset>>((ref) async {
  final jsonText =
      await rootBundle.loadString('assets/presets/eq_presets.json');
  final decoded = jsonDecode(jsonText);
  if (decoded is! List) {
    throw const FormatException('EQ presets must be a JSON array.');
  }

  final presets = decoded.map((entry) {
    if (entry is! Map) {
      throw const FormatException('Each EQ preset must be a JSON object.');
    }
    final preset = EqPreset.fromJson(Map<String, dynamic>.from(entry));
    if (preset.gains.length != EqState.defaultFrequencies.length) {
      throw FormatException('Preset "${preset.name}" must contain five gains.');
    }
    return preset;
  }).toList(growable: false);

  return presets;
});

class AudioNotifier extends StateNotifier<EqState> {
  final PlayerService _playerService;

  AudioNotifier(this._playerService) : super(const EqState());

  Future<void> setPreamp(double db) {
    state = state.copyWith(
      preampDb: db.clamp(-12.0, 12.0).toDouble(),
      activePreset: 'Custom',
    );
    return _playerService.applyAudioSettings(state);
  }

  Future<void> setBandGain(int index, double db) {
    if (index < 0 || index >= state.gains.length) return Future.value();
    final updated = List<double>.from(state.gains);
    updated[index] = db.clamp(-12.0, 12.0).toDouble();
    state = state.copyWith(gains: updated, activePreset: 'Custom');
    return _playerService.applyAudioSettings(state);
  }

  Future<void> applyPreset(EqPreset preset) {
    if (preset.gains.length != state.frequencies.length) {
      throw ArgumentError('Preset must contain one gain per EQ band.');
    }
    state = state.copyWith(
      gains: List<double>.from(preset.gains),
      activePreset: preset.name,
    );
    return _playerService.applyAudioSettings(state);
  }

  Future<void> setAudioDelay(double seconds) {
    state = state.copyWith(audioDelaySec: seconds.clamp(-5.0, 5.0).toDouble());
    return _playerService.applyAudioSettings(state);
  }

  Future<void> toggleCompressor(bool enabled) {
    state = state.copyWith(compressor: enabled);
    return _playerService.applyAudioSettings(state);
  }

  Future<void> resetAll() {
    state = const EqState();
    return _playerService.applyAudioSettings(state);
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, EqState>((ref) {
  return AudioNotifier(ref.watch(playerServiceProvider));
});
