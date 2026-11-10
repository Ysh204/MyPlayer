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
    final key = await showDialog<LogicalKeyboardKey>(
      context: context,
      builder: (_) => const _CaptureShortcutDialog(),
    );
    if (key == null || !context.mounted) return;

    final label = key.keyLabel.isNotEmpty
        ? key.keyLabel
        : key.debugName ?? 'Key ${key.keyId.toRadixString(16)}';
    final accepted = await ref
        .read(playbackPreferencesProvider.notifier)
        .setShortcut(shortcut, key, label);
    if (!accepted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That key is already assigned or reserved.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(playbackPreferencesProvider);
    final notifier = ref.read(playbackPreferencesProvider.notifier);

    return AlertDialog(
      title: const Text('Playback & shortcuts'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsRow(
                title: 'Skip amount',
                subtitle: 'Distance moved by the seek keys',
                trailing: DropdownButton<int>(
                  value: preferences.seekStepSeconds,
                  items: const [2, 3, 5, 10, 15, 30]
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
                subtitle: 'Volume change for each key press',
                trailing: DropdownButton<double>(
                  value: preferences.volumeStepPercent,
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
                title: const Text('Frame-accurate seeking'),
                subtitle:
                    const Text('Seek to the requested frame more closely'),
                value: preferences.precisionSeeking,
                onChanged: notifier.setPrecisionSeeking,
              ),
              const Divider(height: 24),
              const Text(
                'Keyboard shortcuts',
                style: TextStyle(fontWeight: FontWeight.w600),
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
          onPressed: notifier.reset,
          child: const Text('Restore defaults'),
        ),
        TextButton(
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
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
          Expanded(child: Text(title)),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(keyLabel),
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
      title: const Text('Assign shortcut'),
      content: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: const SizedBox(
          width: 320,
          height: 54,
          child: Center(child: Text('Press any key, or Esc to cancel')),
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
