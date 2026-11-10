import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/providers/playback_preferences_provider.dart';

class PlaybackSettingsDialog extends ConsumerWidget {
  const PlaybackSettingsDialog({super.key});

  Future<void> _captureShortcut(
    BuildContext context,
    WidgetRef ref,
    PlaybackShortcut shortcut,
  ) async {
    final notifier = ref.read(playbackPreferencesProvider.notifier);
    final key = await showDialog<LogicalKeyboardKey>(
      context: context,
      builder: (_) => const _CaptureShortcutDialog(),
    );
    if (key == null || !context.mounted) return;

    final label = _formatKeyLabel(key);
    final validation = notifier.validateShortcut(shortcut, key);
    if (!validation.success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.conflictMessage ?? 'Key cannot be assigned.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final accepted = await notifier.setShortcut(shortcut, key, label);
    if (!accepted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That key is already assigned or reserved.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  String _formatKeyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) return 'Left Arrow';
    if (key == LogicalKeyboardKey.arrowRight) return 'Right Arrow';
    if (key == LogicalKeyboardKey.arrowUp) return 'Up Arrow';
    if (key == LogicalKeyboardKey.arrowDown) return 'Down Arrow';
    if (key == LogicalKeyboardKey.pageUp) return 'Page Up';
    if (key == LogicalKeyboardKey.pageDown) return 'Page Down';
    if (key == LogicalKeyboardKey.home) return 'Home';
    if (key == LogicalKeyboardKey.end) return 'End';
    if (key.keyLabel.isNotEmpty) return key.keyLabel.toUpperCase();
    return key.debugName ?? 'Key 0x${key.keyId.toRadixString(16)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(playbackPreferencesProvider);
    final notifier = ref.read(playbackPreferencesProvider.notifier);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, size: 20, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Playback & Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsRow(
                title: 'Skip amount',
                subtitle: 'Seconds to seek on each seek-key press or skip button',
                trailing: DropdownButton<int>(
                  value: preferences.seekStepSeconds,
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: const Color(0xFF22222A),
                  items: const [2, 3, 5, 10, 15, 30, 60]
                      .map((seconds) => DropdownMenuItem(
                            value: seconds,
                            child: Text('$seconds sec'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) notifier.setSeekStepSeconds(value);
                  },
                ),
              ),
              _SettingsRow(
                title: 'Volume key step',
                subtitle: 'Volume percentage change on each volume-key press',
                trailing: DropdownButton<double>(
                  value: preferences.volumeStepPercent,
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: const Color(0xFF22222A),
                  items: const [1.0, 2.0, 5.0, 10.0, 15.0, 20.0]
                      .map((step) => DropdownMenuItem(
                            value: step,
                            child: Text('${step.round()}%'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) notifier.setVolumeStepPercent(value);
                  },
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFFF59E0B),
                title: const Text('Frame-accurate seeking'),
                subtitle: Text(
                  'Seek to the requested keyframe or exact frame more closely',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
                value: preferences.precisionSeeking,
                onChanged: notifier.setPrecisionSeeking,
              ),
              const Divider(height: 28, color: Color(0xFF2E2E3C)),
              const Row(
                children: [
                  Text(
                    'Customizable Shortcuts',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Spacer(),
                  Text(
                    'Click to rebind',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ShortcutSettingRow(
                title: 'Seek backward',
                keyLabel: preferences.seekBackwardKeyLabel,
                onPressed: () => _captureShortcut(
                  context,
                  ref,
                  PlaybackShortcut.seekBackward,
                ),
              ),
              _ShortcutSettingRow(
                title: 'Seek forward',
                keyLabel: preferences.seekForwardKeyLabel,
                onPressed: () => _captureShortcut(
                  context,
                  ref,
                  PlaybackShortcut.seekForward,
                ),
              ),
              _ShortcutSettingRow(
                title: 'Volume down',
                keyLabel: preferences.volumeDownKeyLabel,
                onPressed: () => _captureShortcut(
                  context,
                  ref,
                  PlaybackShortcut.volumeDown,
                ),
              ),
              _ShortcutSettingRow(
                title: 'Volume up',
                keyLabel: preferences.volumeUpKeyLabel,
                onPressed: () => _captureShortcut(
                  context,
                  ref,
                  PlaybackShortcut.volumeUp,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await notifier.reset();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings restored to defaults.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('Restore defaults'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 11.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _ShortcutSettingRow extends StatelessWidget {
  final String title;
  final String keyLabel;
  final VoidCallback onPressed;

  const _ShortcutSettingRow({
    required this.title,
    required this.keyLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              side: const BorderSide(color: Color(0xFF3B3B4A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              keyLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureShortcutDialog extends StatefulWidget {
  const _CaptureShortcutDialog();

  @override
  State<_CaptureShortcutDialog> createState() => _CaptureShortcutDialogState();
}

class _CaptureShortcutDialogState extends State<_CaptureShortcutDialog> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Shortcut capture');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  KeyEventResult _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if ({
      LogicalKeyboardKey.shiftLeft.keyId,
      LogicalKeyboardKey.shiftRight.keyId,
      LogicalKeyboardKey.controlLeft.keyId,
      LogicalKeyboardKey.controlRight.keyId,
      LogicalKeyboardKey.altLeft.keyId,
      LogicalKeyboardKey.altRight.keyId,
      LogicalKeyboardKey.metaLeft.keyId,
      LogicalKeyboardKey.metaRight.keyId,
    }.contains(event.logicalKey.keyId)) {
      return KeyEventResult.handled;
    }
    Navigator.of(context).pop(event.logicalKey);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Shortcut'),
      content: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: const SizedBox(
          width: 320,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_outlined, size: 36, color: Color(0xFFF59E0B)),
                SizedBox(height: 12),
                Text(
                  'Press any key on your keyboard',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  'Press Esc to cancel',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
