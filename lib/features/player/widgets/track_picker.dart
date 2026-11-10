import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../providers/player_provider.dart';

class AudioTrackPicker extends ConsumerWidget {
  const AudioTrackPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(playerTracksProvider).valueOrNull?.audio ?? const [];
    final selected = ref.watch(playerCurrentTrackProvider).valueOrNull?.audio;

    // Always include Auto and Off options
    final trackList = <AudioTrack>[
      AudioTrack.auto(),
      AudioTrack.no(),
      ...available.where((t) => t.id != 'auto' && t.id != 'no'),
    ];

    final selectedId = trackList.any((t) => t.id == selected?.id)
        ? selected!.id
        : trackList.first.id;

    return _TrackPickerDropdown(
      label: 'Audio track',
      tracks: trackList
          .map((track) => _TrackOption(
                track.id,
                trackLabel(
                  track.id,
                  title: track.title,
                  language: track.language,
                  codec: track.codec,
                  isDefault: track.isDefault,
                ),
              ))
          .toList(growable: false),
      selectedId: selectedId,
      onSelected: (id) {
        final track = trackList.firstWhere((item) => item.id == id);
        ref.read(playbackProvider.notifier).setAudioTrack(track);
      },
    );
  }
}

class SubtitleTrackPicker extends ConsumerWidget {
  const SubtitleTrackPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available =
        ref.watch(playerTracksProvider).valueOrNull?.subtitle ?? const [];
    final selected =
        ref.watch(playerCurrentTrackProvider).valueOrNull?.subtitle;

    // Always include Auto and Off options
    final trackList = <SubtitleTrack>[
      SubtitleTrack.auto(),
      SubtitleTrack.no(),
      ...available.where((t) => t.id != 'auto' && t.id != 'no'),
    ];

    final selectedId = trackList.any((t) => t.id == selected?.id)
        ? selected!.id
        : trackList.first.id;

    return _TrackPickerDropdown(
      label: 'Subtitle track',
      tracks: trackList
          .map((track) => _TrackOption(
                track.id,
                trackLabel(
                  track.id,
                  title: track.title,
                  language: track.language,
                  codec: track.codec,
                  isDefault: track.isDefault,
                ),
              ))
          .toList(growable: false),
      selectedId: selectedId,
      onSelected: (id) {
        final track = trackList.firstWhere((item) => item.id == id);
        ref.read(playbackProvider.notifier).setSubtitleTrack(track);
      },
    );
  }
}

class _TrackPickerDropdown extends StatelessWidget {
  final String label;
  final List<_TrackOption> tracks;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _TrackPickerDropdown({
    required this.label,
    required this.tracks,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF22222A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF333342)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              isExpanded: true,
              isDense: true,
              dropdownColor: const Color(0xFF22222A),
              borderRadius: BorderRadius.circular(8),
              style: const TextStyle(fontSize: 12.5, color: Colors.white),
              items: tracks
                  .map(
                    (track) => DropdownMenuItem(
                      value: track.id,
                      child: Text(
                        track.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: track.id == selectedId
                              ? const Color(0xFFF59E0B)
                              : Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (id) {
                if (id != null) onSelected(id);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackOption {
  final String id;
  final String label;

  const _TrackOption(this.id, this.label);
}

String trackLabel(
  String id, {
  String? title,
  String? language,
  String? codec,
  bool? isDefault,
}) {
  if (id == 'auto') return 'Automatic (Default)';
  if (id == 'no') return 'Off (Disabled)';

  final parts = <String>[];
  final cleanTitle = title?.trim();
  final cleanLanguage = language?.trim();
  final cleanCodec = codec?.trim();
  if (cleanTitle != null && cleanTitle.isNotEmpty) parts.add(cleanTitle);
  if (cleanLanguage != null &&
      cleanLanguage.isNotEmpty &&
      cleanLanguage != cleanTitle) {
    parts.add(cleanLanguage);
  }
  if (parts.isEmpty) parts.add('Track $id');
  if (cleanCodec != null && cleanCodec.isNotEmpty) {
    parts.add(cleanCodec.toUpperCase());
  }
  if (isDefault == true) parts.add('Default');
  return parts.join(' • ');
}
