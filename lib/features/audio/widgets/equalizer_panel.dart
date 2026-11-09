import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/eq_state.dart';
import '../../player/widgets/track_picker.dart';
import '../providers/audio_provider.dart';

class EqualizerPanel extends ConsumerWidget {
  const EqualizerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(audioProvider);
    final notifier = ref.read(audioProvider.notifier);
    final presets = ref.watch(eqPresetsProvider);

    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(18, 18, 21, 0.94),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AUDIO DSP & EQUALIZER',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              TextButton(
                  onPressed: notifier.resetAll, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 12),
          const AudioTrackPicker(),
          const SizedBox(height: 8),
          presets.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((preset) => _presetChip(eq, notifier, preset))
                  .toList(),
            ),
            loading: () => const SizedBox(
              height: 32,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (error, stackTrace) => const Text(
              'Could not load EQ presets.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const Divider(height: 28, color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preamp Boost', style: TextStyle(fontSize: 13)),
              Text(
                '${eq.preampDb >= 0 ? '+' : ''}${eq.preampDb.toStringAsFixed(1)} dB',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: eq.preampDb,
            min: -12.0,
            max: 12.0,
            onChanged: notifier.setPreamp,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(eq.frequencies.length, (index) {
                final frequency = eq.frequencies[index];
                final label = frequency >= 1000
                    ? '${(frequency / 1000).toStringAsFixed(1)}k'
                    : '${frequency}Hz';
                return Column(
                  children: [
                    Text(
                      '${eq.gains[index].toStringAsFixed(1)}dB',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: eq.gains[index],
                          min: -12.0,
                          max: 12.0,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (value) =>
                              notifier.setBandGain(index, value),
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 24, color: Colors.white12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Night Mode (Compressor)',
                style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Boosts whispers, tames loud explosions',
              style: TextStyle(fontSize: 11),
            ),
            value: eq.compressor,
            onChanged: notifier.toggleCompressor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Audio Sync: ${(eq.audioDelaySec * 1000).round()} ms'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () =>
                        notifier.setAudioDelay(eq.audioDelaySec - 0.05),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () =>
                        notifier.setAudioDelay(eq.audioDelaySec + 0.05),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(EqState eq, AudioNotifier notifier, EqPreset preset) {
    return ChoiceChip(
      label: Text(preset.name, style: const TextStyle(fontSize: 12)),
      selected: eq.activePreset == preset.name,
      onSelected: (_) => notifier.applyPreset(preset),
    );
  }
}
