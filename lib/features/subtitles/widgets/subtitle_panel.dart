import 'dart:ui' as ui;

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.subtitles_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SUBTITLES & SYNC',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      color: Color(0xFFEDEDF0),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close panel',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => ref
                      .read(activeDrawerProvider.notifier)
                      .state = ActiveDrawerPanel.none,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Color(0x28FFFFFF), height: 20),
            const SizedBox(height: 2),

            // Load External Subtitles - Sleek Right-Angle Button
            Material(
              color: const Color(0xFF1B1C26),
              borderRadius: BorderRadius.zero,
              child: InkWell(
                borderRadius: BorderRadius.zero,
                onTap: () async {
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    border:
                        Border.all(color: const Color(0x38FFFFFF), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_upload_outlined,
                          size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text(
                        'Load External Subtitles (.srt, .ass, .vtt)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEDEDF0),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const SubtitleTrackPicker(),
            const Divider(height: 28, color: Color(0x28FFFFFF)),

            // Vertical Position Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vertical Position',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF0),
                  ),
                ),
                Text(
                  '${subtitle.verticalPosition.round()}%',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Values over 100% position subtitles in the lower letterbox',
              style: TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
            Slider(
              value: subtitle.verticalPosition,
              min: 10.0,
              max: 105.0,
              onChanged: notifier.setVerticalPosition,
            ),

            const SizedBox(height: 10),

            // Font Size / Scale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Font Size / Scale',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF0),
                  ),
                ),
                Text(
                  '${subtitle.fontSize.round()} px',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Slider(
              value: subtitle.fontSize,
              min: 14.0,
              max: 54.0,
              onChanged: notifier.setFontSize,
            ),

            const SizedBox(height: 10),

            // Background Box Opacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Background Box Opacity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF0),
                  ),
                ),
                Text(
                  '${(subtitle.backgroundOpacity * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Slider(
              value: subtitle.backgroundOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: notifier.setBackgroundOpacity,
            ),

            const Divider(height: 28, color: Color(0x28FFFFFF)),

            // Subtitle Sync Offset
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtitle Sync Offset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDF0),
                  ),
                ),
                Text(
                  '${(subtitle.delaySeconds * 1000).round()} ms',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SyncStepButton(
                    label: '-100 ms',
                    onTap: () => notifier.adjustDelay(-0.1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SyncStepButton(
                    label: 'Reset',
                    onTap: notifier.resetDelay,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SyncStepButton(
                    label: '+100 ms',
                    onTap: () => notifier.adjustDelay(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SyncStepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1C26),
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(color: const Color(0x38FFFFFF), width: 0.8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEDEDF0),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
