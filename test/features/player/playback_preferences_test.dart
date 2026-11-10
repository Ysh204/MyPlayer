import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/features/player/providers/playback_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlaybackPreferencesNotifier', () {
    test('has expected default configuration', () {
      final notifier = PlaybackPreferencesNotifier();
      final state = notifier.state;

      expect(state.seekStepSeconds, 5);
      expect(state.volumeStepPercent, 5.0);
      expect(state.precisionSeeking, isTrue);
      expect(state.seekBackwardKeyLabel, 'Left Arrow');
      expect(state.seekForwardKeyLabel, 'Right Arrow');
      expect(state.volumeDownKeyLabel, 'Down Arrow');
      expect(state.volumeUpKeyLabel, 'Up Arrow');
    });

    test('updates seek step and volume step', () async {
      final notifier = PlaybackPreferencesNotifier();

      await notifier.setSeekStepSeconds(10);
      expect(notifier.state.seekStepSeconds, 10);

      await notifier.setVolumeStepPercent(10.0);
      expect(notifier.state.volumeStepPercent, 10.0);

      await notifier.setPrecisionSeeking(false);
      expect(notifier.state.precisionSeeking, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('playback_seek_step_seconds'), 10);
      expect(prefs.getDouble('playback_volume_step_percent'), 10.0);
      expect(prefs.getBool('playback_precision_seeking'), false);
    });

    test('detects reserved key conflicts', () {
      final notifier = PlaybackPreferencesNotifier();

      final spaceValidation = notifier.validateShortcut(
        PlaybackShortcut.seekForward,
        LogicalKeyboardKey.space,
      );
      expect(spaceValidation.success, isFalse);
      expect(spaceValidation.conflictMessage, contains('reserved'));

      final fValidation = notifier.validateShortcut(
        PlaybackShortcut.seekBackward,
        LogicalKeyboardKey.keyF,
      );
      expect(fValidation.success, isFalse);
      expect(fValidation.conflictMessage, contains('reserved'));

      final escValidation = notifier.validateShortcut(
        PlaybackShortcut.volumeUp,
        LogicalKeyboardKey.escape,
      );
      expect(escValidation.success, isFalse);
      expect(escValidation.conflictMessage, contains('reserved'));
    });

    test('detects duplicate shortcut key conflicts', () {
      final notifier = PlaybackPreferencesNotifier();

      // Right arrow is already assigned to Seek Forward
      final conflict = notifier.validateShortcut(
        PlaybackShortcut.volumeUp,
        LogicalKeyboardKey.arrowRight,
      );
      expect(conflict.success, isFalse);
      expect(conflict.conflictMessage, contains('Seek Forward'));
    });

    test('allows and persists valid shortcut reassignments', () async {
      final notifier = PlaybackPreferencesNotifier();

      final result = await notifier.setShortcut(
        PlaybackShortcut.seekForward,
        LogicalKeyboardKey.keyL,
        'L',
      );
      expect(result, isTrue);
      expect(notifier.state.seekForwardKeyId, LogicalKeyboardKey.keyL.keyId);
      expect(notifier.state.seekForwardKeyLabel, 'L');

      // Now verify persistence
      final reloaded = PlaybackPreferencesNotifier();
      await reloaded.load();
      expect(reloaded.state.seekForwardKeyId, LogicalKeyboardKey.keyL.keyId);
      expect(reloaded.state.seekForwardKeyLabel, 'L');
    });

    test('reset restores default values', () async {
      final notifier = PlaybackPreferencesNotifier();
      await notifier.setSeekStepSeconds(30);
      await notifier.setVolumeStepPercent(15.0);
      await notifier.setShortcut(
        PlaybackShortcut.seekBackward,
        LogicalKeyboardKey.keyJ,
        'J',
      );

      await notifier.reset();
      expect(notifier.state.seekStepSeconds, 5);
      expect(notifier.state.volumeStepPercent, 5.0);
      expect(notifier.state.seekBackwardKeyLabel, 'Left Arrow');
    });
  });
}

