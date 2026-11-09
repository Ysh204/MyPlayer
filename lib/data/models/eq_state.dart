class EqPreset {
  final String name;
  final List<double> gains;

  const EqPreset({required this.name, required this.gains});

  factory EqPreset.fromJson(Map<String, dynamic> json) {
    final rawGains = json['gains'];
    if (json['name'] is! String || rawGains is! List) {
      throw const FormatException('Invalid equalizer preset.');
    }

    return EqPreset(
      name: json['name'] as String,
      gains: rawGains.map((value) {
        if (value is! num) {
          throw const FormatException('Equalizer gains must be numbers.');
        }
        return value.toDouble();
      }).toList(growable: false),
    );
  }
}

class EqState {
  static const List<int> defaultFrequencies = [60, 230, 910, 3600, 14000];

  final List<int> frequencies;
  final List<double> gains;
  final double preampDb;
  final double audioDelaySec;
  final bool compressor;
  final String activePreset;

  const EqState({
    this.frequencies = defaultFrequencies,
    this.gains = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.preampDb = 0.0,
    this.audioDelaySec = 0.0,
    this.compressor = false,
    this.activePreset = 'Flat',
  });

  EqState copyWith({
    List<double>? gains,
    double? preampDb,
    double? audioDelaySec,
    bool? compressor,
    String? activePreset,
  }) {
    return EqState(
      frequencies: frequencies,
      gains: gains ?? this.gains,
      preampDb: preampDb ?? this.preampDb,
      audioDelaySec: audioDelaySec ?? this.audioDelaySec,
      compressor: compressor ?? this.compressor,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}
