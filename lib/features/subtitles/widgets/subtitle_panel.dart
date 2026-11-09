import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/widgets/track_picker.dart';
import '../providers/subtitle_provider.dart';

class SubtitlePanel extends ConsumerWidget {
  const SubtitlePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = ref.watch(subtitleProvider);
    final notifier = ref.read(subtitleProvider.notifier);

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
          const Text(
            'SUBTITLE FRAMING & SYNC',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.subtitles_outlined),
              label: const Text('Load External .SRT / .ASS / .VTT'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
                );
                if (result != null && result.files.isNotEmpty) {
                  final path = result.files.first.path;
                  if (path != null) await notifier.loadExternalSubtitle(path);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          const SubtitleTrackPicker(),
          const Divider(height: 24, color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vertical Framing Position',
                  style: TextStyle(fontSize: 13)),
              Text(
                '${subtitle.verticalPosition.round()}%',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text(
            'Push above 100% to drop subtitles into the bottom black bar',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          Slider(
            value: subtitle.verticalPosition,
            min: 10.0,
            max: 105.0,
            onChanged: notifier.setVerticalPosition,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtitle Scale / Font Size',
                  style: TextStyle(fontSize: 13)),
              Text('${subtitle.fontSize.round()} px'),
            ],
          ),
          Slider(
            value: subtitle.fontSize,
            min: 14.0,
            max: 54.0,
            onChanged: notifier.setFontSize,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Framing Box Opacity', style: TextStyle(fontSize: 13)),
              Text('${(subtitle.backgroundOpacity * 100).round()}%'),
            ],
          ),
          Slider(
            value: subtitle.backgroundOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: notifier.setBackgroundOpacity,
          ),
          const Divider(height: 32, color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtitle Delay Sync', style: TextStyle(fontSize: 13)),
              Text(
                '${(subtitle.delaySeconds * 1000).round()} ms',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () => notifier.adjustDelay(-0.1),
                child: const Text('-100 ms'),
              ),
              TextButton(
                  onPressed: notifier.resetDelay, child: const Text('Reset')),
              OutlinedButton(
                onPressed: () => notifier.adjustDelay(0.1),
                child: const Text('+100 ms'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
