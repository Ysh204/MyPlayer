import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/eq_state.dart';
import '../../player/providers/player_provider.dart';
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
      width: 380,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xF412131A),
        border: Border(left: BorderSide(color: Color(0x38FFFFFF), width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 20,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AUDIO EQUALIZER & DSP',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    color: Color(0xFFEDEDF0),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFF59E0B),
                ),
                onPressed: notifier.resetAll,
                child: const Text('Reset', style: TextStyle(fontSize: 11)),
              ),
              IconButton(
                tooltip: 'Close panel',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => ref
                    .read(activeDrawerProvider.notifier)
                    .state = ActiveDrawerPanel.none,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const Divider(color: Color(0x28FFFFFF), height: 16),
          const AudioTrackPicker(),
          const SizedBox(height: 12),
          presets.when(
            data: (items) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((preset) => _presetChip(eq, notifier, preset))
                  .toList(),
            ),
            loading: () => const SizedBox(
              height: 28,
              child: Center(child: LinearProgressIndicator(minHeight: 2)),
            ),
            error: (error, stackTrace) => const Text(
              'Could not load EQ presets.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          const Divider(height: 24, color: Color(0x28FFFFFF)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preamp Boost',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEDEDF0),
                ),
              ),
              Text(
                '${eq.preampDb >= 0 ? '+' : ''}${eq.preampDb.toStringAsFixed(1)} dB',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
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
          const SizedBox(height: 6),
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
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.white70,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      ),
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
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white54,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 20, color: Color(0x28FFFFFF)),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: const Color(0xFFF59E0B),
            title: const Text(
              'Night Mode (Dynamic Compression)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEDEDF0),
              ),
            ),
            subtitle: const Text(
              'Levels dialogue and softens loud sound effects',
              style: TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
            value: eq.compressor,
            onChanged: notifier.toggleCompressor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Sync: ${(eq.audioDelaySec * 1000).round()} ms',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEDEDF0),
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease audio delay by 50ms',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.white70),
                    onPressed: () =>
                        notifier.setAudioDelay(eq.audioDelaySec - 0.05),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Increase audio delay by 50ms',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white70),
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
    final isSelected = eq.activePreset == preset.name;
    return ChoiceChip(
      label: Text(
        preset.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFEDEDF0),
          letterSpacing: 0.2,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0x28F59E0B),
      backgroundColor: const Color(0xFF1B1C26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: Color(0x38FFFFFF),
          width: 0.8,
        ),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFF59E0B) : const Color(0x38FFFFFF),
        width: 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (_) => notifier.applyPreset(preset),
    );
  }
}
