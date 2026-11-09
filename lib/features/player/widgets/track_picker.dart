import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../providers/player_provider.dart';

class AudioTrackPicker extends ConsumerWidget {
  const AudioTrackPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(playerTracksProvider).valueOrNull?.audio;
    final tracks = available == null || available.isEmpty
        ? const [AudioTrack('auto', null, null), AudioTrack('no', null, null)]
        : available;
    final selected = ref.watch(playerCurrentTrackProvider).valueOrNull?.audio;
    final selectedId = tracks.any((track) => track.id == selected?.id)
        ? selected!.id
        : tracks.first.id;

    return _TrackPickerDropdown(
      label: 'Audio track',
      tracks: tracks
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
        final track = tracks.firstWhere((item) => item.id == id);
        ref.read(playbackProvider.notifier).setAudioTrack(track);
      },
    );
  }
}

class SubtitleTrackPicker extends ConsumerWidget {
  const SubtitleTrackPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(playerTracksProvider).valueOrNull?.subtitle;
    final tracks = available == null || available.isEmpty
        ? const [
            SubtitleTrack('auto', null, null),
            SubtitleTrack('no', null, null),
          ]
        : available;
    final selected =
        ref.watch(playerCurrentTrackProvider).valueOrNull?.subtitle;
    final selectedId = tracks.any((track) => track.id == selected?.id)
        ? selected!.id
        : tracks.first.id;

    return _TrackPickerDropdown(
      label: 'Subtitle track',
      tracks: tracks
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
        final track = tracks.firstWhere((item) => item.id == id);
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
        Text(label, style: const TextStyle(fontSize: 13)),
        DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: tracks
              .map(
                (track) => DropdownMenuItem(
                  value: track.id,
                  child: Text(track.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (id) {
            if (id != null) onSelected(id);
          },
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
  if (id == 'auto') return 'Automatic';
  if (id == 'no') return 'Off';

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
