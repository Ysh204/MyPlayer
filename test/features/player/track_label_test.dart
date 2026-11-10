import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/features/player/widgets/track_picker.dart';

void main() {
  group('trackLabel', () {
    test('handles special track ids', () {
      expect(trackLabel('auto'), 'Automatic (Default)');
      expect(trackLabel('no'), 'Off (Disabled)');
    });

    test('formats track with full metadata', () {
      final label = trackLabel(
        '1',
        title: 'English Commentary',
        language: 'en',
        codec: 'aac',
        isDefault: true,
      );
      expect(label, 'English Commentary • en • AAC • Default');
    });

    test('deduplicates title and language when identical', () {
      final label = trackLabel(
        '2',
        title: 'Spanish',
        language: 'Spanish',
        codec: 'ac3',
      );
      expect(label, 'Spanish • AC3');
    });

    test('falls back to track id when no title or language is present', () {
      final label = trackLabel('3', codec: 'opus');
      expect(label, 'Track 3 • OPUS');
    });
  });
}

