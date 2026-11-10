import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _arrowDownKeyId = 0x00100000301;
const _arrowLeftKeyId = 0x00100000302;
const _arrowRightKeyId = 0x00100000303;
const _arrowUpKeyId = 0x00100000304;

enum PlaybackShortcut { seekBackward, seekForward, volumeDown, volumeUp }

class PlaybackPreferences {
  final int seekStepSeconds;
  final double volumeStepPercent;
  final bool precisionSeeking;
  final int seekBackwardKeyId;
  final String seekBackwardKeyLabel;
  final int seekForwardKeyId;
  final String seekForwardKeyLabel;
  final int volumeDownKeyId;
  final String volumeDownKeyLabel;
  final int volumeUpKeyId;
  final String volumeUpKeyLabel;

  const PlaybackPreferences({
    this.seekStepSeconds = 5,
    this.volumeStepPercent = 5,
    this.precisionSeeking = true,
    this.seekBackwardKeyId = _arrowLeftKeyId,
    this.seekBackwardKeyLabel = 'Left Arrow',
    this.seekForwardKeyId = _arrowRightKeyId,
    this.seekForwardKeyLabel = 'Right Arrow',
    this.volumeDownKeyId = _arrowDownKeyId,
    this.volumeDownKeyLabel = 'Down Arrow',
    this.volumeUpKeyId = _arrowUpKeyId,
    this.volumeUpKeyLabel = 'Up Arrow',
  });

  static const defaults = PlaybackPreferences();

  PlaybackPreferences copyWith({
    int? seekStepSeconds,
    double? volumeStepPercent,
    bool? precisionSeeking,
    int? seekBackwardKeyId,
    String? seekBackwardKeyLabel,
    int? seekForwardKeyId,
    String? seekForwardKeyLabel,
    int? volumeDownKeyId,
    String? volumeDownKeyLabel,
    int? volumeUpKeyId,
    String? volumeUpKeyLabel,
  }) {
    return PlaybackPreferences(
      seekStepSeconds: seekStepSeconds ?? this.seekStepSeconds,
      volumeStepPercent: volumeStepPercent ?? this.volumeStepPercent,
      precisionSeeking: precisionSeeking ?? this.precisionSeeking,
      seekBackwardKeyId: seekBackwardKeyId ?? this.seekBackwardKeyId,
      seekBackwardKeyLabel: seekBackwardKeyLabel ?? this.seekBackwardKeyLabel,
      seekForwardKeyId: seekForwardKeyId ?? this.seekForwardKeyId,
      seekForwardKeyLabel: seekForwardKeyLabel ?? this.seekForwardKeyLabel,
      volumeDownKeyId: volumeDownKeyId ?? this.volumeDownKeyId,
      volumeDownKeyLabel: volumeDownKeyLabel ?? this.volumeDownKeyLabel,
      volumeUpKeyId: volumeUpKeyId ?? this.volumeUpKeyId,
      volumeUpKeyLabel: volumeUpKeyLabel ?? this.volumeUpKeyLabel,
    );
  }
}

class PlaybackPreferencesNotifier extends StateNotifier<PlaybackPreferences> {
  static const _seekStepKey = 'playback_seek_step_seconds';
  static const _volumeStepKey = 'playback_volume_step_percent';
  static const _precisionSeekKey = 'playback_precision_seeking';
  static const _seekBackwardKeyId = 'shortcut_seek_backward_key_id';
  static const _seekBackwardKeyLabel = 'shortcut_seek_backward_key_label';
  static const _seekForwardKeyId = 'shortcut_seek_forward_key_id';
  static const _seekForwardKeyLabel = 'shortcut_seek_forward_key_label';
  static const _volumeDownKeyId = 'shortcut_volume_down_key_id';
  static const _volumeDownKeyLabel = 'shortcut_volume_down_key_label';
  static const _volumeUpKeyId = 'shortcut_volume_up_key_id';
  static const _volumeUpKeyLabel = 'shortcut_volume_up_key_label';

  PlaybackPreferencesNotifier() : super(PlaybackPreferences.defaults);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = PlaybackPreferences(
      seekStepSeconds: preferences.getInt(_seekStepKey) ??
          PlaybackPreferences.defaults.seekStepSeconds,
      volumeStepPercent: preferences.getDouble(_volumeStepKey) ??
          PlaybackPreferences.defaults.volumeStepPercent,
      precisionSeeking: preferences.getBool(_precisionSeekKey) ??
          PlaybackPreferences.defaults.precisionSeeking,
      seekBackwardKeyId: preferences.getInt(_seekBackwardKeyId) ??
          PlaybackPreferences.defaults.seekBackwardKeyId,
      seekBackwardKeyLabel: preferences.getString(_seekBackwardKeyLabel) ??
          PlaybackPreferences.defaults.seekBackwardKeyLabel,
      seekForwardKeyId: preferences.getInt(_seekForwardKeyId) ??
          PlaybackPreferences.defaults.seekForwardKeyId,
      seekForwardKeyLabel: preferences.getString(_seekForwardKeyLabel) ??
          PlaybackPreferences.defaults.seekForwardKeyLabel,
      volumeDownKeyId: preferences.getInt(_volumeDownKeyId) ??
          PlaybackPreferences.defaults.volumeDownKeyId,
      volumeDownKeyLabel: preferences.getString(_volumeDownKeyLabel) ??
          PlaybackPreferences.defaults.volumeDownKeyLabel,
      volumeUpKeyId: preferences.getInt(_volumeUpKeyId) ??
          PlaybackPreferences.defaults.volumeUpKeyId,
      volumeUpKeyLabel: preferences.getString(_volumeUpKeyLabel) ??
          PlaybackPreferences.defaults.volumeUpKeyLabel,
    );
  }

  Future<void> setSeekStepSeconds(int value) async {
    state = state.copyWith(seekStepSeconds: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_seekStepKey, value);
  }

  Future<void> setVolumeStepPercent(double value) async {
    state = state.copyWith(volumeStepPercent: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_volumeStepKey, value);
  }

  Future<void> setPrecisionSeeking(bool value) async {
    state = state.copyWith(precisionSeeking: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_precisionSeekKey, value);
  }

  Future<bool> setShortcut(
    PlaybackShortcut shortcut,
    LogicalKeyboardKey key,
    String label,
  ) async {
    final otherKeys = switch (shortcut) {
      PlaybackShortcut.seekBackward => [
          state.seekForwardKeyId,
          state.volumeDownKeyId,
          state.volumeUpKeyId,
        ],
      PlaybackShortcut.seekForward => [
          state.seekBackwardKeyId,
          state.volumeDownKeyId,
          state.volumeUpKeyId,
        ],
      PlaybackShortcut.volumeDown => [
          state.seekBackwardKeyId,
          state.seekForwardKeyId,
          state.volumeUpKeyId,
        ],
      PlaybackShortcut.volumeUp => [
          state.seekBackwardKeyId,
          state.seekForwardKeyId,
          state.volumeDownKeyId,
        ],
    };
    final reservedKeys = {
      LogicalKeyboardKey.space.keyId,
      LogicalKeyboardKey.f11.keyId,
    };
    if (otherKeys.contains(key.keyId) || reservedKeys.contains(key.keyId)) {
      return false;
    }

    switch (shortcut) {
      case PlaybackShortcut.seekBackward:
        state = state.copyWith(
          seekBackwardKeyId: key.keyId,
          seekBackwardKeyLabel: label,
        );
        break;
      case PlaybackShortcut.seekForward:
        state = state.copyWith(
          seekForwardKeyId: key.keyId,
          seekForwardKeyLabel: label,
        );
        break;
      case PlaybackShortcut.volumeDown:
        state = state.copyWith(
          volumeDownKeyId: key.keyId,
          volumeDownKeyLabel: label,
        );
        break;
      case PlaybackShortcut.volumeUp:
        state = state.copyWith(
          volumeUpKeyId: key.keyId,
          volumeUpKeyLabel: label,
        );
        break;
    }
    await _saveShortcuts();
    return true;
  }

  Future<void> reset() async {
    state = PlaybackPreferences.defaults;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_seekStepKey, state.seekStepSeconds);
    await preferences.setDouble(_volumeStepKey, state.volumeStepPercent);
    await preferences.setBool(_precisionSeekKey, state.precisionSeeking);
    await _saveShortcuts(preferences);
  }

  Future<void> _saveShortcuts([SharedPreferences? preferences]) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    await store.setInt(_seekBackwardKeyId, state.seekBackwardKeyId);
    await store.setString(
      _seekBackwardKeyLabel,
      state.seekBackwardKeyLabel,
    );
    await store.setInt(_seekForwardKeyId, state.seekForwardKeyId);
    await store.setString(_seekForwardKeyLabel, state.seekForwardKeyLabel);
    await store.setInt(_volumeDownKeyId, state.volumeDownKeyId);
    await store.setString(_volumeDownKeyLabel, state.volumeDownKeyLabel);
    await store.setInt(_volumeUpKeyId, state.volumeUpKeyId);
    await store.setString(_volumeUpKeyLabel, state.volumeUpKeyLabel);
  }
}

final playbackPreferencesProvider =
    StateNotifierProvider<PlaybackPreferencesNotifier, PlaybackPreferences>(
        (ref) {
  final notifier = PlaybackPreferencesNotifier();
  unawaited(notifier.load());
  return notifier;
});
