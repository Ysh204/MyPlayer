import '../data/models/eq_state.dart';

/// Builds one FFmpeg libavfilter graph for mpv's `af` property.
///
/// The graph is empty when there are no active effects, which clears the
/// existing audio filter chain when applied to the player.
String buildAudioFilter(EqState eq) {
  if (eq.gains.length != eq.frequencies.length) {
    throw ArgumentError('EQ gains and frequencies must have the same length.');
  }

  final filters = <String>[];

  if (eq.preampDb.abs() >= 0.05) {
    filters.add('volume=${eq.preampDb.toStringAsFixed(1)}dB');
  }

  for (var i = 0; i < eq.frequencies.length; i++) {
    final gain = eq.gains[i];
    if (gain.abs() >= 0.05) {
      filters.add(
        'equalizer=f=${eq.frequencies[i]}:width_type=o:w=1:g=${gain.toStringAsFixed(1)}',
      );
    }
  }

  if (eq.compressor) {
    filters.add('acompressor');
  }

  return filters.isEmpty ? '' : 'lavfi=[${filters.join(',')}]';
}
