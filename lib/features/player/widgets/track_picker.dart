import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../providers/player_provider.dart';

class AudioTrackPicker extends ConsumerWidget {
  const AudioTrackPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available =
        ref.watch(playerTracksProvider).valueOrNull?.audio ?? const [];
    final selected = ref.watch(playerCurrentTrackProvider).valueOrNull?.audio;

    final trackList = <AudioTrack>[
      AudioTrack.auto(),
      AudioTrack.no(),
      ...available.where((t) => t.id != 'auto' && t.id != 'no'),
    ];

    final selectedId = trackList.any((t) => t.id == selected?.id)
        ? selected!.id
        : trackList.first.id;

    return _TrackPickerDropdown(
      label: 'Audio Track',
      icon: Icons.music_note,
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

    final trackList = <SubtitleTrack>[
      SubtitleTrack.auto(),
      SubtitleTrack.no(),
      ...available.where((t) => t.id != 'auto' && t.id != 'no'),
    ];

    final selectedId = trackList.any((t) => t.id == selected?.id)
        ? selected!.id
        : trackList.first.id;

    return _TrackPickerDropdown(
      label: 'Subtitle Track',
      icon: Icons.subtitles,
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
  final IconData icon;
  final List<_TrackOption> tracks;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _TrackPickerDropdown({
    required this.label,
    required this.icon,
    required this.tracks,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTrack = tracks.firstWhere(
      (t) => t.id == selectedId,
      orElse: () => tracks.isNotEmpty
          ? tracks.first
          : const _TrackOption('', 'None'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.white60,
              ),
            ),
            Text(
              '${tracks.length} options',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          tooltip: 'Select $label',
          initialValue: selectedId,
          onSelected: onSelected,
          color: const Color(0xF8151620),
          elevation: 16,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0x38FFFFFF), width: 0.8),
          ),
          itemBuilder: (context) => tracks.map((track) {
            final isSelected = track.id == selectedId;
            return PopupMenuItem<String>(
              value: track.id,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : Colors.white24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      track.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.15,
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEDEDF0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C26),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: const Color(0x38FFFFFF), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedTrack.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEDEDF0),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: Colors.white60,
                ),
              ],
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
