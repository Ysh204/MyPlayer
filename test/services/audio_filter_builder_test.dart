import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/data/models/eq_state.dart';
import 'package:my_player/services/audio_filter_builder.dart';

void main() {
  group('buildAudioFilter', () {
    test('returns an empty string when all audio effects are disabled', () {
      const state = EqState();
      expect(buildAudioFilter(state), isEmpty);
    });

    test('builds a lavfi graph with preamp, active bands, and compressor', () {
      const state = EqState(
        preampDb: 4.5,
        gains: [6.0, 0.0, -2.5, 0.0, 3.0],
        compressor: true,
      );

      expect(
        buildAudioFilter(state),
        'lavfi=[volume=4.5dB,'
        'equalizer=f=60:width_type=o:w=1:g=6.0,'
        'equalizer=f=910:width_type=o:w=1:g=-2.5,'
        'equalizer=f=14000:width_type=o:w=1:g=3.0,'
        'acompressor]',
      );
    });

    test('rejects mismatched frequency and gain lists', () {
      const state = EqState(gains: [2.0]);
      expect(() => buildAudioFilter(state), throwsArgumentError);
    });
  });
}
