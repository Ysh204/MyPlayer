import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/time_formatter.dart';
import '../../audio/widgets/equalizer_panel.dart';
import '../../playlist/widgets/playlist_panel.dart';
import '../../settings/widgets/playback_settings_dialog.dart';
import '../../subtitles/providers/subtitle_provider.dart';
import '../../subtitles/widgets/subtitle_panel.dart';
import '../providers/playback_preferences_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/osd_overlay.dart';
import '../widgets/track_picker.dart';

const _contextMenuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xF2161822)),
  shadowColor: WidgetStatePropertyAll(Colors.black87),
  elevation: WidgetStatePropertyAll(20),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6, horizontal: 4)),
  minimumSize: WidgetStatePropertyAll(Size(224, 0)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      side: BorderSide(color: Color(0x28FFFFFF), width: 0.8),
    ),
  ),
);

const _contextMenuButtonStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(Color(0xFFEDEDF0)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.5)),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),
  minimumSize: WidgetStatePropertyAll(Size(224, 30)),
  alignment: AlignmentDirectional.centerStart,
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WindowListener {
  static const _recentFilesKey = 'recent_media_files';

  final MenuController _contextMenuController = MenuController();
  bool _showControls = true;
  bool _isFullScreen = false;
  Timer? _hideTimer;
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    ref.listenManual<PlaybackPreferences>(
      playbackPreferencesProvider,
      (previous, next) => _runAction(
        () => ref
            .read(playerServiceProvider)
            .setPrecisionSeeking(next.precisionSeeking),
      ),
      fireImmediately: true,
    );
    unawaited(_restoreRecentFiles());
    unawaited(_checkFullscreenState());
  }

  @override
  void onWindowClose() async {
    await _quitApp();
  }

  Future<void> _quitApp() async {
    try {
      final playerService = ref.read(playerServiceProvider);
      await playerService.stop();
      await playerService.dispose();
    } catch (_) {}
    await windowManager.destroy();
    exit(0);
  }

  Future<void> _checkFullscreenState() async {
    final fs = await windowManager.isFullScreen();
    if (mounted) setState(() => _isFullScreen = fs);
  }

  Future<void> _restoreRecentFiles() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentFiles = preferences.getStringList(_recentFilesKey) ?? [];
    });
  }

  Future<void> _rememberRecentFiles(List<String> paths) async {
    final recent = List<String>.from(_recentFiles);
    for (final path in paths.reversed) {
      recent.remove(path);
      recent.insert(0, path);
    }
    if (recent.length > 12) recent.removeRange(12, recent.length);
    if (mounted) setState(() => _recentFiles = recent);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentFilesKey, recent);
  }

  void _bumpControlsVisibility() {
    if (!_showControls && mounted) {
      setState(() => _showControls = true);
    }
    _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          ref.read(activeDrawerProvider) == ActiveDrawerPanel.none &&
          !_contextMenuController.isOpen) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onContextMenuOpened() {
    _hideTimer?.cancel();
    if (mounted && !_showControls) setState(() => _showControls = true);
  }

  Future<void> _openMediaPaths(
    List<String> paths, {
    bool addToQueue = false,
  }) async {
    final selectedPaths = paths.where((path) => path.isNotEmpty).toList();
    if (selectedPaths.isEmpty) return;

    final notifier = ref.read(playbackProvider.notifier);
    if (addToQueue) {
      for (final path in selectedPaths) {
        await notifier.addToQueue(path);
      }
      ref.read(osdProvider.notifier).show(
            text: 'Added ${selectedPaths.length} to Playlist',
            icon: Icons.playlist_add_check_rounded,
          );
    } else if (selectedPaths.length == 1) {
      await notifier.openFile(selectedPaths.single);
      ref.read(osdProvider.notifier).show(
            text: 'Opening Media',
            subtext: p.basename(selectedPaths.single),
            icon: Icons.movie_rounded,
          );
    } else {
      await notifier.openFiles(selectedPaths);
      ref.read(osdProvider.notifier).show(
            text: 'Opened Playlist (${selectedPaths.length} items)',
            icon: Icons.playlist_play_rounded,
          );
    }
    await _rememberRecentFiles(selectedPaths);
    _bumpControlsVisibility();
  }

  Future<void> _pickMediaFile({bool allowMultiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: allowMultiple,
      allowedExtensions: [
        'mp4',
        'mkv',
        'webm',
        'avi',
        'mov',
        'mp3',
        'flac',
        'm4a',
        'wav',
        'ogg',
        'opus',
        'wmv',
        'mpeg',
        'mpg',
        'm4v',
        '3gp',
      ],
    );
    if (result != null) {
      final paths = result.files
          .map((file) => file.path)
          .whereType<String>()
          .toList(growable: false);
      await _openMediaPaths(paths);
    }
  }

  Future<void> _pickFilesToQueue() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        'mp4',
        'mkv',
        'webm',
        'avi',
        'mov',
        'mp3',
        'flac',
        'm4a',
        'wav',
        'ogg',
        'opus',
        'wmv',
        'mpeg',
        'mpg',
        'm4v',
        '3gp',
      ],
    );
    if (result != null) {
      final paths = result.files
          .map((file) => file.path)
          .whereType<String>()
          .toList(growable: false);
      await _openMediaPaths(paths, addToQueue: true);
    }
  }

  Future<void> _pickExternalAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'aac',
        'ac3',
        'eac3',
        'flac',
        'm4a',
        'mp3',
        'ogg',
        'opus',
        'wav',
        'wma',
      ],
    );
    final path = result?.files.firstOrNull?.path;
    if (path != null) {
      await ref.read(playbackProvider.notifier).loadExternalAudio(path);
    }
  }

  Future<void> _pickExternalSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
    );
    final path = result?.files.firstOrNull?.path;
    if (path != null) {
      await ref.read(subtitleProvider.notifier).loadExternalSubtitle(path);
      ref.read(osdProvider.notifier).show(
            text: 'Subtitles Loaded',
            subtext: p.basename(path),
            icon: Icons.subtitles_rounded,
          );
    }
  }

  void _runAction(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action error: $error'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }());
  }

  Widget _menuItem(
    String label,
    VoidCallback? onPressed, {
    String? shortcut,
    IconData? leading,
  }) {
    return MenuItemButton(
      style: _contextMenuButtonStyle,
      onPressed: onPressed,
      leadingIcon: leading != null
          ? Icon(leading, size: 16, color: Colors.white70)
          : const SizedBox(width: 16),
      trailingIcon: shortcut == null
          ? null
          : Text(
              shortcut,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _submenu(String label, List<Widget> children, {IconData? leading}) {
    return SubmenuButton(
      style: _contextMenuButtonStyle,
      menuStyle: _contextMenuStyle,
      leadingIcon: leading != null
          ? Icon(leading, size: 16, color: Colors.white70)
          : const SizedBox(width: 16),
      menuChildren: children,
      child: Text(label),
    );
  }

  Widget _menuDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        child: Divider(height: 1, color: Color(0x20FFFFFF)),
      );

  List<Widget> _buildContextMenu() {
    final preferences = ref.watch(playbackPreferencesProvider);
    final tracks =
        ref.watch(playerTracksProvider).valueOrNull ?? const Tracks();
    final currentTrack =
        ref.watch(playerCurrentTrackProvider).valueOrNull ?? const Track();
    final playlist = ref.watch(playerPlaylistProvider).valueOrNull;
    final playback = ref.watch(playbackProvider);
    final notifier = ref.read(playbackProvider.notifier);

    return [
      _submenu(
        'File',
        [
          _menuItem('Open Media File…', () => _runAction(_pickMediaFile),
              shortcut: 'Ctrl+O', leading: Icons.folder_open_rounded),
          _menuItem(
            'Open Files as Playlist…',
            () => _runAction(() => _pickMediaFile(allowMultiple: true)),
            leading: Icons.playlist_play_rounded,
          ),
          _submenu(
            'Recent Files',
            _recentFiles.isEmpty
                ? [_menuItem('No recent files', null)]
                : _recentFiles
                    .map(
                      (path) => _menuItem(
                        p.basename(path),
                        () => _runAction(() => _openMediaPaths([path])),
                      ),
                    )
                    .toList(),
            leading: Icons.history_rounded,
          ),
          _menuDivider(),
          _menuItem('Load External Audio…', () => _runAction(_pickExternalAudio),
              leading: Icons.audiotrack_outlined),
          _menuItem(
            'Load External Subtitles…',
            () => _runAction(_pickExternalSubtitle),
            leading: Icons.subtitles_outlined,
          ),
          _menuDivider(),
          _menuItem('Close Media', () => _runAction(notifier.stop),
              leading: Icons.stop_rounded),
        ],
        leading: Icons.folder_outlined,
      ),
      _submenu(
        'Playback',
        [
          _menuItem(
            'Play / Pause',
            () => _runAction(notifier.playOrPause),
            shortcut: 'Space',
            leading: Icons.play_arrow_rounded,
          ),
          _menuItem('Stop', () => _runAction(notifier.stop),
              leading: Icons.stop_rounded),
          _menuDivider(),
          _menuItem(
            'Seek Backward (${preferences.seekStepSeconds}s)',
            () => _runAction(() => notifier.seekBy(
                  Duration(seconds: -preferences.seekStepSeconds),
                )),
            shortcut: preferences.seekBackwardKeyLabel,
            leading: Icons.replay_rounded,
          ),
          _menuItem(
            'Seek Forward (${preferences.seekStepSeconds}s)',
            () => _runAction(() => notifier.seekBy(
                  Duration(seconds: preferences.seekStepSeconds),
                )),
            shortcut: preferences.seekForwardKeyLabel,
            leading: Icons.forward_rounded,
          ),
          _menuItem(
            'Seek -30 seconds',
            () => _runAction(() => notifier.seekBy(const Duration(seconds: -30))),
          ),
          _menuItem(
            'Seek +30 seconds',
            () => _runAction(() => notifier.seekBy(const Duration(seconds: 30))),
          ),
          _menuDivider(),
          _menuItem(
            'Previous Item',
            playlist != null && playlist.index > 0
                ? () => _runAction(notifier.previous)
                : null,
            leading: Icons.skip_previous_rounded,
          ),
          _menuItem(
            'Next Item',
            playlist != null && playlist.index < playlist.medias.length - 1
                ? () => _runAction(notifier.next)
                : null,
            leading: Icons.skip_next_rounded,
          ),
          _menuDivider(),
          _submenu(
            'Playback Speed',
            [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
              final isCurrent = playback.speed == rate;
              return _menuItem(
                '${rate}x${rate == 1.0 ? ' (Normal)' : ''}',
                () => _runAction(() => notifier.setRate(rate)),
                leading: isCurrent ? Icons.check_rounded : null,
              );
            }).toList(),
            leading: Icons.speed_rounded,
          ),
        ],
        leading: Icons.play_circle_outline_rounded,
      ),
      _submenu(
        'Audio',
        [
          _submenu('Audio Track', _audioTrackItems(tracks, currentTrack)),
          _menuItem(
            playback.volume > 0 ? 'Mute' : 'Unmute',
            () => _runAction(notifier.toggleMute),
            shortcut: 'M',
            leading: playback.volume > 0
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
          ),
          _menuItem(
            'Audio Equalizer & DSP…',
            () => _showPanel(ActiveDrawerPanel.audio),
            leading: Icons.graphic_eq_rounded,
          ),
          _menuItem('Load External Audio…', () => _runAction(_pickExternalAudio)),
        ],
        leading: Icons.volume_up_outlined,
      ),
      _submenu(
        'Subtitles',
        [
          _submenu('Subtitle Track', _subtitleTrackItems(tracks, currentTrack)),
          _menuItem(
            'Subtitle Settings & Sync…',
            () => _showPanel(ActiveDrawerPanel.subtitles),
            leading: Icons.tune_rounded,
          ),
          _menuItem(
            'Load External Subtitles…',
            () => _runAction(_pickExternalSubtitle),
            leading: Icons.file_upload_outlined,
          ),
        ],
        leading: Icons.subtitles_outlined,
      ),
      _submenu(
        'Video',
        [
          _submenu('Video Track', _videoTrackItems(tracks, currentTrack)),
          _menuItem('Save Current Frame…', () => _runAction(_saveScreenshot),
              leading: Icons.camera_alt_outlined),
          _menuItem(
            _isFullScreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
            () => _runAction(_toggleFullscreen),
            shortcut: 'F / F11',
            leading: _isFullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
          ),
        ],
        leading: Icons.videocam_outlined,
      ),
      _submenu(
        'Playlist',
        [
          _menuItem(
            'View Playlist',
            () => _showPanel(ActiveDrawerPanel.playlist),
            leading: Icons.queue_music_rounded,
          ),
          _menuItem(
            'Add Files to Playlist…',
            () => _runAction(_pickFilesToQueue),
            leading: Icons.add_rounded,
          ),
          _menuItem(
            'Clear Playlist',
            playlist?.medias.isNotEmpty == true
                ? () => _runAction(notifier.clearQueue)
                : null,
            leading: Icons.delete_outline_rounded,
          ),
        ],
        leading: Icons.queue_music_outlined,
      ),
      _menuDivider(),
      _menuItem(
        'Playback & Shortcuts…',
        _showPlaybackSettings,
        leading: Icons.tune_rounded,
      ),
      _menuItem('Media Properties…', _showProperties,
          leading: Icons.info_outline_rounded),
      _menuItem('Keyboard Shortcuts Reference', _showKeyboardShortcuts,
          leading: Icons.keyboard_outlined),
      _menuDivider(),
      _menuItem(
        'Exit',
        () => _runAction(_quitApp),
        shortcut: 'Alt+F4',
        leading: Icons.exit_to_app_rounded,
      ),
    ];
  }

  List<Widget> _videoTrackItems(Tracks tracks, Track current) {
    if (tracks.video.isEmpty) {
      return [_menuItem('Default Video', null, leading: Icons.check_rounded)];
    }
    return tracks.video
        .map(
          (track) => _menuItem(
            trackLabel(
              track.id,
              title: track.title,
              language: track.language,
              codec: track.codec,
              isDefault: track.isDefault,
            ),
            () => _runAction(
                () => ref.read(playbackProvider.notifier).setVideoTrack(track)),
            leading: current.video.id == track.id ? Icons.check_rounded : null,
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _audioTrackItems(Tracks tracks, Track current) {
    final list = <Widget>[
      _menuItem(
        'Automatic',
        () => _runAction(() => ref
            .read(playbackProvider.notifier)
            .setAudioTrack(AudioTrack.auto())),
        leading: current.audio.id == 'auto' ? Icons.check_rounded : null,
      ),
      _menuItem(
        'Off (Disable Audio)',
        () => _runAction(() => ref
            .read(playbackProvider.notifier)
            .setAudioTrack(AudioTrack.no())),
        leading: current.audio.id == 'no' ? Icons.check_rounded : null,
      ),
    ];

    for (final track in tracks.audio) {
      if (track.id == 'auto' || track.id == 'no') continue;
      list.add(
        _menuItem(
          trackLabel(
            track.id,
            title: track.title,
            language: track.language,
            codec: track.codec,
            isDefault: track.isDefault,
          ),
          () => _runAction(
              () => ref.read(playbackProvider.notifier).setAudioTrack(track)),
          leading: current.audio.id == track.id ? Icons.check_rounded : null,
        ),
      );
    }
    return list;
  }

  List<Widget> _subtitleTrackItems(Tracks tracks, Track current) {
    final list = <Widget>[
      _menuItem(
        'Automatic',
        () => _runAction(() => ref
            .read(playbackProvider.notifier)
            .setSubtitleTrack(SubtitleTrack.auto())),
        leading: current.subtitle.id == 'auto' ? Icons.check_rounded : null,
      ),
      _menuItem(
        'Off (Disable Subtitles)',
        () => _runAction(() => ref
            .read(playbackProvider.notifier)
            .setSubtitleTrack(SubtitleTrack.no())),
        leading: current.subtitle.id == 'no' ? Icons.check_rounded : null,
      ),
    ];

    for (final track in tracks.subtitle) {
      if (track.id == 'auto' || track.id == 'no') continue;
      list.add(
        _menuItem(
          trackLabel(
            track.id,
            title: track.title,
            language: track.language,
            codec: track.codec,
            isDefault: track.isDefault,
          ),
          () => _runAction(
            () => ref.read(playbackProvider.notifier).setSubtitleTrack(track),
          ),
          leading: current.subtitle.id == track.id ? Icons.check_rounded : null,
        ),
      );
    }
    return list;
  }

  void _showPanel(ActiveDrawerPanel panel) {
    ref.read(activeDrawerProvider.notifier).state = panel;
    _bumpControlsVisibility();
  }

  Future<void> _toggleFullscreen() async {
    final fullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!fullscreen);
    if (mounted) setState(() => _isFullScreen = !fullscreen);
    ref.read(osdProvider.notifier).show(
          text: !fullscreen ? 'Fullscreen' : 'Windowed',
          icon: !fullscreen
              ? Icons.fullscreen_rounded
              : Icons.fullscreen_exit_rounded,
        );
  }

  void _handleEscape() {
    if (_contextMenuController.isOpen) {
      _contextMenuController.close();
      return;
    }
    final activeDrawer = ref.read(activeDrawerProvider);
    if (activeDrawer != ActiveDrawerPanel.none) {
      ref.read(activeDrawerProvider.notifier).state = ActiveDrawerPanel.none;
      return;
    }
    if (_isFullScreen) {
      _toggleFullscreen();
    }
  }

  Future<void> _saveScreenshot() async {
    final bytes = await ref.read(playbackProvider.notifier).screenshot();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video frame available to capture.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save frame',
      fileName: 'my_player_frame.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes, flush: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Frame saved to ${p.basename(path)}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showProperties() {
    final playlist = ref.read(playerPlaylistProvider).valueOrNull;
    final tracks = ref.read(playerTracksProvider).valueOrNull ?? const Tracks();
    final current =
        ref.read(playerCurrentTrackProvider).valueOrNull ?? const Track();
    final duration =
        ref.read(playerDurationProvider).valueOrNull ?? Duration.zero;
    final media = playlist == null || playlist.medias.isEmpty
        ? null
        : playlist.medias[playlist.index.clamp(0, playlist.medias.length - 1)];
    final lines = <String>[
      'File: ${media == null ? 'No media loaded' : media.uri}',
      'Duration: ${formatDuration(duration)}',
      'Video tracks: ${tracks.video.length}',
      'Audio tracks: ${tracks.audio.length}',
      'Subtitle tracks: ${tracks.subtitle.length}',
      'Current Audio: ${trackLabel(current.audio.id, title: current.audio.title, language: current.audio.language)}',
      'Current Subtitles: ${trackLabel(current.subtitle.id, title: current.subtitle.title, language: current.subtitle.language)}',
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 20, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Media Properties'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SelectableText(
            lines.join('\n\n'),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcuts() {
    final preferences = ref.read(playbackPreferencesProvider);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard_outlined, size: 20, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ShortcutRow('Open file', 'Ctrl+O'),
                const _ShortcutRow('Play / Pause', 'Space'),
                _ShortcutRow(
                  'Seek backward (${preferences.seekStepSeconds}s)',
                  preferences.seekBackwardKeyLabel,
                ),
                _ShortcutRow(
                  'Seek forward (${preferences.seekStepSeconds}s)',
                  preferences.seekForwardKeyLabel,
                ),
                _ShortcutRow(
                  'Volume down (${preferences.volumeStepPercent.round()}%)',
                  preferences.volumeDownKeyLabel,
                ),
                _ShortcutRow(
                  'Volume up (${preferences.volumeStepPercent.round()}%)',
                  preferences.volumeUpKeyLabel,
                ),
                const _ShortcutRow('Toggle mute', 'M'),
                const _ShortcutRow('Toggle fullscreen', 'F / F11'),
                const _ShortcutRow('Exit fullscreen / Close panel', 'Esc'),
                const _ShortcutRow('Context menu', 'Right-Click'),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSettings() {
    showDialog<void>(
      context: context,
      builder: (_) => const PlaybackSettingsDialog(),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _hideTimer?.cancel();
    _contextMenuController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = ref.watch(playerVideoControllerProvider);
    final activeDrawer = ref.watch(activeDrawerProvider);
    final subtitle = ref.watch(subtitleProvider);
    final playback = ref.watch(playbackProvider);
    final playbackPreferences = ref.watch(playbackPreferencesProvider);
    final playlist = ref.watch(playerPlaylistProvider).valueOrNull;
    final buffering = ref.watch(playerBufferingProvider).valueOrNull ?? false;
    final hasMedia = playlist != null && playlist.medias.isNotEmpty;

    // Listen to media_kit errors to display a clean notification
    ref.listen<AsyncValue<String>>(playerErrorProvider, (prev, next) {
      next.whenData((errorMsg) {
        if (errorMsg.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playback warning: $errorMsg'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      });
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space):
            ref.read(playbackProvider.notifier).playOrPause,
        SingleActivator(
          LogicalKeyboardKey(playbackPreferences.seekForwardKeyId),
        ): () => ref.read(playbackProvider.notifier).seekBy(
              Duration(seconds: playbackPreferences.seekStepSeconds),
            ),
        SingleActivator(
          LogicalKeyboardKey(playbackPreferences.seekBackwardKeyId),
        ): () => ref.read(playbackProvider.notifier).seekBy(
              Duration(seconds: -playbackPreferences.seekStepSeconds),
            ),
        SingleActivator(
          LogicalKeyboardKey(playbackPreferences.volumeUpKeyId),
        ): () => ref.read(playbackProvider.notifier).changeVolumeBy(
              playbackPreferences.volumeStepPercent,
            ),
        SingleActivator(
          LogicalKeyboardKey(playbackPreferences.volumeDownKeyId),
        ): () => ref.read(playbackProvider.notifier).changeVolumeBy(
              -playbackPreferences.volumeStepPercent,
            ),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            _runAction(_pickMediaFile),
        const SingleActivator(LogicalKeyboardKey.keyF): () =>
            _runAction(_toggleFullscreen),
        const SingleActivator(LogicalKeyboardKey.f11): () =>
            _runAction(_toggleFullscreen),
        const SingleActivator(LogicalKeyboardKey.keyM): () =>
            ref.read(playbackProvider.notifier).toggleMute(),
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              // Immediately close context menu whenever user clicks anywhere else
              if (_contextMenuController.isOpen) {
                _contextMenuController.close();
              }
            },
            child: MenuAnchor(
              controller: _contextMenuController,
              consumeOutsideTap: true,
              style: _contextMenuStyle,
              menuChildren: _buildContextMenu(),
              onOpen: _onContextMenuOpened,
              onClose: _scheduleControlsHide,
              child: DropTarget(
                onDragDone: (details) => _runAction(
                  () => _openMediaPaths(
                    details.files.map((file) => file.path).toList(),
                  ),
                ),
                child: MouseRegion(
                  cursor: _showControls
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.none,
                  onHover: (_) => _bumpControlsVisibility(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_contextMenuController.isOpen) {
                        _contextMenuController.close();
                        return;
                      }
                      if (activeDrawer != ActiveDrawerPanel.none) {
                        ref.read(activeDrawerProvider.notifier).state =
                            ActiveDrawerPanel.none;
                      } else {
                        _bumpControlsVisibility();
                      }
                    },
                    onDoubleTap: () {
                      if (_contextMenuController.isOpen) {
                        _contextMenuController.close();
                        return;
                      }
                      _toggleFullscreen();
                    },
                    onSecondaryTapDown: (details) {
                      if (_contextMenuController.isOpen) {
                        _contextMenuController.close();
                      }
                      _contextMenuController.open(
                        position: details.localPosition,
                      );
                    },
                    child: Stack(
                      children: [
                        // Video Player layer
                        Positioned.fill(
                          child: Video(
                            controller: videoController,
                            controls: NoVideoControls,
                            subtitleViewConfiguration:
                                SubtitleViewConfiguration(
                              style: TextStyle(
                                fontSize: subtitle.fontSize,
                                color: subtitle.textColor,
                                backgroundColor: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  subtitle.backgroundOpacity,
                                ),
                                height: 1.35,
                              ),
                              padding: EdgeInsets.only(
                                bottom: (105 - subtitle.verticalPosition)
                                        .clamp(0.0, 95.0) *
                                    4.0,
                                left: 24,
                                right: 24,
                              ),
                            ),
                          ),
                        ),

                        // Empty state when no media is loaded
                        if (!hasMedia)
                          _EmptyStateOverlay(
                            onOpenFile: _pickMediaFile,
                            onOpenPlaylist: () =>
                                _pickMediaFile(allowMultiple: true),
                          ),

                        // Buffering indicator
                        if (buffering && hasMedia)
                          const Center(
                            child: IgnorePointer(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // OSD HUD overlay
                        const OsdOverlay(),

                        // Floating minimal & cool playbar (IINA style)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: 20,
                          right: 20,
                          bottom: _showControls ? 20 : -130,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            opacity: _showControls ? 1.0 : 0.0,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 640,
                                  minWidth: 380,
                                ),
                                child: MouseRegion(
                                  onEnter: (_) => _hideTimer?.cancel(),
                                  onExit: (_) => _scheduleControlsHide(),
                                  child: _BottomControlsBar(
                                    onOpenFile: _pickMediaFile,
                                    onShowPlaybackSettings:
                                        _showPlaybackSettings,
                                    onToggleFullscreen: _toggleFullscreen,
                                    isFullScreen: _isFullScreen,
                                    volume: playback.volume,
                                    speed: playback.speed,
                                    activeDrawer: activeDrawer,
                                    hasMedia: hasMedia,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Side drawers
                        if (activeDrawer == ActiveDrawerPanel.audio)
                          const Positioned(
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: EqualizerPanel(),
                          ),
                        if (activeDrawer == ActiveDrawerPanel.subtitles)
                          const Positioned(
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: SubtitlePanel(),
                          ),
                        if (activeDrawer == ActiveDrawerPanel.playlist)
                          Positioned(
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child:
                                PlaylistPanel(onAddFiles: _pickFilesToQueue),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateOverlay extends StatelessWidget {
  final Future<void> Function() onOpenFile;
  final Future<void> Function() onOpenPlaylist;

  const _EmptyStateOverlay({
    required this.onOpenFile,
    required this.onOpenPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          color: const Color(0xD812141C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FFFFFF), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 30,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x28FFFFFF)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 28,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Media Loaded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Drop video files here or select an option below',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0x28FFFFFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onOpenFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text(
                    'Open File',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onOpenPlaylist,
                  icon: const Icon(Icons.playlist_play_rounded, size: 18),
                  label: const Text(
                    'Playlist',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Ctrl+O: Open • Space: Play • F: Fullscreen',
              style: TextStyle(fontSize: 10.5, color: Colors.white30),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControlsBar extends ConsumerStatefulWidget {
  final Future<void> Function({bool allowMultiple}) onOpenFile;
  final VoidCallback onShowPlaybackSettings;
  final VoidCallback onToggleFullscreen;
  final bool isFullScreen;
  final double volume;
  final double speed;
  final ActiveDrawerPanel activeDrawer;
  final bool hasMedia;

  const _BottomControlsBar({
    required this.onOpenFile,
    required this.onShowPlaybackSettings,
    required this.onToggleFullscreen,
    required this.isFullScreen,
    required this.volume,
    required this.speed,
    required this.activeDrawer,
    required this.hasMedia,
  });

  @override
  ConsumerState<_BottomControlsBar> createState() => _BottomControlsBarState();
}

class _BottomControlsBarState extends ConsumerState<_BottomControlsBar> {
  double? _scrubPositionMs;
  bool _isDragging = false;
  Timer? _clearScrubTimer;

  @override
  void dispose() {
    _clearScrubTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playbackProvider.notifier);
    final preferences = ref.watch(playbackPreferencesProvider);
    final position =
        ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration =
        ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final playing = ref.watch(playerPlayingProvider).valueOrNull ?? false;
    final playlist = ref.watch(playerPlaylistProvider).valueOrNull;

    final maxMs =
        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final sliderMs = (_scrubPositionMs ?? currentMs).clamp(0.0, maxMs);
    final displayedPosition = Duration(milliseconds: sliderMs.round());

    final canPrevious = playlist != null &&
        playlist.medias.isNotEmpty &&
        playlist.index > 0;
    final canNext = playlist != null &&
        playlist.medias.isNotEmpty &&
        playlist.index < playlist.medias.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEE141620),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Controls (Volume, Transport, Actions)
          Row(
            children: [
              // Volume Icon (click to toggle mute)
              IconButton(
                tooltip: widget.volume > 0 ? 'Mute (M)' : 'Unmute (M)',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  widget.volume == 0
                      ? Icons.volume_off_rounded
                      : (widget.volume < 50
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded),
                  color: widget.volume == 0
                      ? Colors.white38
                      : const Color(0xFFEDEDF0),
                ),
                onPressed: playerNotifier.toggleMute,
              ),

              const SizedBox(width: 2),

              // Volume Slider
              SizedBox(
                width: 60,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: const Color(0x28FFFFFF),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4.5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Focus(
                    canRequestFocus: false,
                    child: Slider(
                      value: widget.volume.clamp(0.0, 150.0),
                      min: 0.0,
                      max: 150.0,
                      onChanged: playerNotifier.setVolume,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              SizedBox(
                width: 32,
                child: Text(
                  '${widget.volume.round()}%',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white54),
                ),
              ),

              const Spacer(),

              // Playlist Previous button
              IconButton(
                tooltip:
                    canPrevious ? 'Previous in playlist' : 'No previous item',
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: canPrevious ? playerNotifier.previous : null,
              ),

              const SizedBox(width: 4),

              // Seek Backward button
              IconButton(
                tooltip:
                    'Seek backward ${preferences.seekStepSeconds}s (${preferences.seekBackwardKeyLabel})',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.replay_rounded),
                onPressed: widget.hasMedia
                    ? () => playerNotifier.seekBy(
                          Duration(seconds: -preferences.seekStepSeconds),
                        )
                    : null,
              ),

              const SizedBox(width: 6),

              // Play / Pause sleek circular button
              Material(
                color: const Color(0x22F59E0B),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: playerNotifier.playOrPause,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: Icon(
                      playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 22,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Seek Forward button
              IconButton(
                tooltip:
                    'Seek forward ${preferences.seekStepSeconds}s (${preferences.seekForwardKeyLabel})',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.forward_rounded),
                onPressed: widget.hasMedia
                    ? () => playerNotifier.seekBy(
                          Duration(seconds: preferences.seekStepSeconds),
                        )
                    : null,
              ),

              const SizedBox(width: 4),

              // Playlist Next button
              IconButton(
                tooltip: canNext ? 'Next in playlist' : 'No next item',
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: canNext ? playerNotifier.next : null,
              ),

              const Spacer(),

              // Playback Speed dropdown
              PopupMenuButton<double>(
                tooltip: 'Speed',
                initialValue: widget.speed,
                onSelected: playerNotifier.setRate,
                itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map((rate) => PopupMenuItem(
                          value: rate,
                          child: Row(
                            children: [
                              if (widget.speed == rate)
                                const Icon(Icons.check_rounded,
                                    size: 16, color: Color(0xFFF59E0B))
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text('${rate}x${rate == 1.0 ? ' (Normal)' : ''}'),
                            ],
                          ),
                        ))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0x28FFFFFF)),
                  ),
                  child: Text(
                    '${widget.speed}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Fullscreen button
              IconButton(
                tooltip: widget.isFullScreen
                    ? 'Exit fullscreen (F)'
                    : 'Fullscreen (F)',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  widget.isFullScreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                ),
                onPressed: widget.onToggleFullscreen,
              ),

              // Playlist panel toggle
              IconButton(
                tooltip: 'Playlist',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.queue_music_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.playlist
                      ? const Color(0xFFF59E0B)
                      : Colors.white70,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.playlist
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.playlist,
              ),

              // Equalizer panel toggle
              IconButton(
                tooltip: 'Audio Equalizer',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.graphic_eq_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.audio
                      ? const Color(0xFFF59E0B)
                      : Colors.white70,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.audio
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.audio,
              ),

              // Subtitles panel toggle
              IconButton(
                tooltip: 'Subtitles',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.subtitles_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.subtitles
                      ? const Color(0xFFF59E0B)
                      : Colors.white70,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.subtitles
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.subtitles,
              ),

              // Playback settings button
              IconButton(
                tooltip: 'Settings',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                onPressed: widget.onShowPlaybackSettings,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Row 2: Seek Bar Row with timestamps
          Row(
            children: [
              Text(
                formatDuration(displayedPosition),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: const Color(0x28FFFFFF),
                      thumbColor: const Color(0xFFF59E0B),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4.5,
                        elevation: 1,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10.0,
                      ),
                    ),
                    child: Focus(
                      canRequestFocus: false,
                      child: Slider(
                        value: sliderMs,
                        min: 0.0,
                        max: maxMs,
                        onChangeStart: (value) {
                          _isDragging = true;
                          _clearScrubTimer?.cancel();
                          setState(() => _scrubPositionMs = value);
                        },
                        onChanged: (value) {
                          setState(() => _scrubPositionMs = value);
                        },
                        onChangeEnd: (value) {
                          _isDragging = false;
                          _clearScrubTimer?.cancel();
                          setState(() => _scrubPositionMs = value);
                          unawaited(playerNotifier.seekTo(
                            Duration(milliseconds: value.round()),
                          ));
                          _clearScrubTimer = Timer(
                            const Duration(milliseconds: 900),
                            () {
                              if (mounted && !_isDragging) {
                                setState(() => _scrubPositionMs = null);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                formatDuration(duration),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String label;
  final String shortcut;

  const _ShortcutRow(this.label, this.shortcut);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF22222C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF333342)),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
