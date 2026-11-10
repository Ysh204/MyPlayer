import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/features/player/providers/player_provider.dart';

void main() {
  group('OsdNotifier', () {
    test('starts with hidden state', () {
      final notifier = OsdNotifier();
      expect(notifier.state.visible, isFalse);
      expect(notifier.state.text, isEmpty);
      notifier.dispose();
    });

    test('shows osd message with sequence increment', () {
      final notifier = OsdNotifier();
      notifier.show(
        text: '+5s',
        subtext: '00:15 / 01:00',
        icon: Icons.fast_forward_rounded,
        progress: 0.5,
      );

      expect(notifier.state.visible, isTrue);
      expect(notifier.state.text, '+5s');
      expect(notifier.state.subtext, '00:15 / 01:00');
      expect(notifier.state.icon, Icons.fast_forward_rounded);
      expect(notifier.state.progress, 0.5);
      expect(notifier.state.sequence, 1);

      notifier.show(
        text: 'Volume: 80%',
        icon: Icons.volume_up_rounded,
      );

      expect(notifier.state.visible, isTrue);
      expect(notifier.state.text, 'Volume: 80%');
      expect(notifier.state.sequence, 2);

      notifier.hide();
      expect(notifier.state.visible, isFalse);
      notifier.dispose();
    });
  });
}

