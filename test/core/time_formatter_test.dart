import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/core/utils/time_formatter.dart';

void main() {
  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('formats seconds and minutes under one hour', () {
      expect(formatDuration(const Duration(seconds: 45)), '00:45');
      expect(formatDuration(const Duration(minutes: 5, seconds: 12)), '05:12');
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats durations over one hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(
        formatDuration(const Duration(hours: 12, minutes: 34, seconds: 56)),
        '12:34:56',
      );
    });

    test('handles negative durations safely as zero', () {
      expect(formatDuration(const Duration(seconds: -10)), '00:00');
    });
  });
}

