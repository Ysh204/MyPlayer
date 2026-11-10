import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/providers/player_provider.dart';
import '../../player/widgets/track_picker.dart';
import '../providers/subtitle_provider.dart';

class SubtitlePanel extends ConsumerWidget {
  const SubtitlePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = ref.watch(subtitleProvider);
    final notifier = ref.read(subtitleProvider.notifier);

    return Container(
      width: 380,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xF214141A),
        border: Border(left: BorderSide(color: Color(0xFF2E2E3C))),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subtitles_rounded,
                    size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SUBTITLES & SYNC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close panel',
                  iconSize: 20,
                  onPressed: () => ref
                      .read(activeDrawerProvider.notifier)
                      .state = ActiveDrawerPanel.none,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2E2E3C), height: 16),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22222D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Load External Subtitles (.srt, .ass, .vtt)'),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final path = result.files.first.path;
                    if (path != null) {
                      await notifier.loadExternalSubtitle(path);
                      ref.read(osdProvider.notifier).show(
                            text: 'Subtitles Loaded',
                            subtext: path.split(RegExp(r'[/\\]')).last,
                            icon: Icons.subtitles_rounded,
                          );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            const SubtitleTrackPicker(),
            const Divider(height: 28, color: Color(0xFF2E2E3C)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vertical Position',
                    style: TextStyle(fontSize: 12.5)),
                Text(
                  '${subtitle.verticalPosition.round()}%',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const Text(
              'Values over 100% position subtitles in the lower letterbox',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            Slider(
              value: subtitle.verticalPosition,
              min: 10.0,
              max: 105.0,
              onChanged: notifier.setVerticalPosition,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Font Size / Scale',
                    style: TextStyle(fontSize: 12.5)),
                Text(
                  '${subtitle.fontSize.round()} px',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
            Slider(
              value: subtitle.fontSize,
              min: 14.0,
              max: 54.0,
              onChanged: notifier.setFontSize,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Background Box Opacity',
                    style: TextStyle(fontSize: 12.5)),
                Text(
                  '${(subtitle.backgroundOpacity * 100).round()}%',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
            Slider(
              value: subtitle.backgroundOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: notifier.setBackgroundOpacity,
            ),
            const Divider(height: 28, color: Color(0xFF2E2E3C)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtitle Sync Offset',
                    style: TextStyle(fontSize: 12.5)),
                Text(
                  '${(subtitle.delaySeconds * 1000).round()} ms',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B3B4A)),
                  ),
                  onPressed: () => notifier.adjustDelay(-0.1),
                  child: const Text('-100 ms'),
                ),
                TextButton(
                  onPressed: notifier.resetDelay,
                  child: const Text('Reset'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B3B4A)),
                  ),
                  onPressed: () => notifier.adjustDelay(0.1),
                  child: const Text('+100 ms'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
