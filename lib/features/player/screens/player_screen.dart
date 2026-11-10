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
import '../widgets/track_picker.dart';

const _contextMenuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xFF242424)),
  shadowColor: WidgetStatePropertyAll(Colors.black87),
  elevation: WidgetStatePropertyAll(12),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
  minimumSize: WidgetStatePropertyAll(Size(238, 0)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  ),
  side: WidgetStatePropertyAll(BorderSide(color: Color(0xFF444444))),
);

const _contextMenuButtonStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(Color(0xFFE5E5E5)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.5)),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 14, vertical: 3),
  ),
  minimumSize: WidgetStatePropertyAll(Size(238, 30)),
  alignment: AlignmentDirectional.centerStart,
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  static const _recentFilesKey = 'recent_media_files';

  final MenuController _contextMenuController = MenuController();
  bool _showControls = true;
  Timer? _hideTimer;
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
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
    if (!_showControls && mounted) setState(() => _showControls = true);
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
    } else if (selectedPaths.length == 1) {
      await notifier.openFile(selectedPaths.single);
    } else {
      await notifier.openFiles(selectedPaths);
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
    }
  }

  void _runAction(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not complete that action: $error')),
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
      leadingIcon: leading == null ? null : Icon(leading, size: 16),
      trailingIcon: shortcut == null
          ? null
          : Text(
              shortcut,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _submenu(String label, List<Widget> children) {
    return SubmenuButton(
      style: _contextMenuButtonStyle,
      menuStyle: _contextMenuStyle,
      menuChildren: children,
      child: Text(label),
    );
  }

  Widget _menuDivider() => const SizedBox(
        width: 238,
        height: 5,
        child: Divider(height: 1, color: Color(0xFF454545)),
      );

  List<Widget> _buildContextMenu() {
    final preferences = ref.watch(playbackPreferencesProvider);
    final tracks =
        ref.watch(playerTracksProvider).valueOrNull ?? const Tracks();
    final currentTrack =
        ref.watch(playerCurrentTrackProvider).valueOrNull ?? const Track();
    final playlist = ref.watch(playerPlaylistProvider).valueOrNull;
    final notifier = ref.read(playbackProvider.notifier);

    return [
      _menuItem(
        'Quick Open File…',
        () => _runAction(_pickMediaFile),
        shortcut: 'Ctrl+O',
      ),
      _menuDivider(),
      _submenu('File', [
        _menuItem('Open media file…', () => _runAction(_pickMediaFile)),
        _menuItem(
          'Open files as playlist…',
          () => _runAction(() => _pickMediaFile(allowMultiple: true)),
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
        ),
        _menuItem('Load external audio…', () => _runAction(_pickExternalAudio)),
        _menuItem(
          'Load external subtitles…',
          () => _runAction(_pickExternalSubtitle),
        ),
      ]),
      _submenu('Play', [
        _menuItem('Play / Pause', () => _runAction(notifier.playOrPause)),
        _menuItem('Stop', () => _runAction(notifier.stop)),
        _menuItem('Previous item', () => _runAction(notifier.previous)),
        _menuItem('Next item', () => _runAction(notifier.next)),
        _menuDivider(),
        _submenu('Playback speed', [
          for (final rate in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
            _menuItem(
              '${rate}x',
              () => _runAction(() => notifier.setRate(rate)),
            ),
        ]),
      ]),
      _submenu('View', [
        _menuItem('Toggle fullscreen', () => _runAction(_toggleFullscreen)),
        _menuItem(
          _showControls ? 'Hide controls' : 'Show controls',
          _toggleControls,
        ),
      ]),
      _submenu('Video', [
        _submenu('Video track', _videoTrackItems(tracks, currentTrack)),
      ]),
      _submenu('Audio', [
        _submenu('Audio track', _audioTrackItems(tracks, currentTrack)),
        _menuItem('Load external audio…', () => _runAction(_pickExternalAudio)),
        _menuItem(
            'Audio DSP & equalizer', () => _showPanel(ActiveDrawerPanel.audio)),
      ]),
      _submenu('Subtitles', [
        _submenu('Subtitle track', _subtitleTrackItems(tracks, currentTrack)),
        _menuItem(
          'Load external subtitles…',
          () => _runAction(_pickExternalSubtitle),
        ),
        _menuItem(
          'Subtitle framing & sync',
          () => _showPanel(ActiveDrawerPanel.subtitles),
        ),
      ]),
      _submenu('Video Track', _videoTrackItems(tracks, currentTrack)),
      _submenu('Audio Track', _audioTrackItems(tracks, currentTrack)),
      _submenu('Subtitle Track', _subtitleTrackItems(tracks, currentTrack)),
      _submenu('Navigate', [
        _menuItem(
          'Back ${preferences.seekStepSeconds} seconds',
          () => _runAction(() => notifier.seekBy(
                Duration(seconds: -preferences.seekStepSeconds),
              )),
        ),
        _menuItem(
          'Forward ${preferences.seekStepSeconds} seconds',
          () => _runAction(() => notifier.seekBy(
                Duration(seconds: preferences.seekStepSeconds),
              )),
        ),
        _menuItem(
          'Back 30 seconds',
          () => _runAction(() => notifier.seekBy(const Duration(seconds: -30))),
        ),
        _menuItem(
          'Forward 30 seconds',
          () => _runAction(() => notifier.seekBy(const Duration(seconds: 30))),
        ),
      ]),
      _submenu('Capture', [
        _menuItem('Save current frame…', () => _runAction(_saveScreenshot)),
      ]),
      _submenu('Filters', [
        _menuItem(
            'Audio DSP & equalizer', () => _showPanel(ActiveDrawerPanel.audio)),
      ]),
      _submenu('Playlists', [
        _menuItem(
          'Open playlist…',
          () => _runAction(() => _pickMediaFile(allowMultiple: true)),
        ),
        _menuItem(
            'Add files to playlist…', () => _runAction(_pickFilesToQueue)),
        _menuItem(
            'Show playlist', () => _showPanel(ActiveDrawerPanel.playlist)),
        _menuItem(
          'Clear playlist',
          playlist?.medias.isNotEmpty == true
              ? () => _runAction(notifier.clearQueue)
              : null,
        ),
      ]),
      _menuDivider(),
      _menuItem('Properties…', _showProperties),
      _menuItem('Playback & shortcuts…', _showPlaybackSettings),
      _menuItem('Keyboard shortcuts', _showKeyboardShortcuts),
      _menuItem('Exit', () => _runAction(windowManager.close),
          shortcut: 'Alt+F4'),
    ];
  }

  List<Widget> _videoTrackItems(Tracks tracks, Track current) => tracks.video
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
          leading: current.video.id == track.id ? Icons.check : null,
        ),
      )
      .toList(growable: false);

  List<Widget> _audioTrackItems(Tracks tracks, Track current) => tracks.audio
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
              () => ref.read(playbackProvider.notifier).setAudioTrack(track)),
          leading: current.audio.id == track.id ? Icons.check : null,
        ),
      )
      .toList(growable: false);

  List<Widget> _subtitleTrackItems(Tracks tracks, Track current) =>
      tracks.subtitle
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
                () =>
                    ref.read(playbackProvider.notifier).setSubtitleTrack(track),
              ),
              leading: current.subtitle.id == track.id ? Icons.check : null,
            ),
          )
          .toList(growable: false);

  void _showPanel(ActiveDrawerPanel panel) {
    ref.read(activeDrawerProvider.notifier).state = panel;
    _bumpControlsVisibility();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _bumpControlsVisibility();
  }

  Future<void> _toggleFullscreen() async {
    final fullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!fullscreen);
  }

  Future<void> _saveScreenshot() async {
    final bytes = await ref.read(playbackProvider.notifier).screenshot();
    if (bytes == null) throw StateError('There is no video frame to capture.');

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
        SnackBar(content: Text('Frame saved to $path')),
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
      'Audio: ${trackLabel(current.audio.id, title: current.audio.title, language: current.audio.language)}',
      'Subtitles: ${trackLabel(current.subtitle.id, title: current.subtitle.title, language: current.subtitle.language)}',
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media properties'),
        content: SizedBox(
          width: 480,
          child: SelectableText(lines.join('\n')),
        ),
        actions: [
          TextButton(
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
        title: const Text('Keyboard shortcuts'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ShortcutRow('Open file', 'Ctrl+O'),
              const _ShortcutRow('Play / Pause', 'Space'),
              _ShortcutRow(
                'Seek backward ${preferences.seekStepSeconds} seconds',
                preferences.seekBackwardKeyLabel,
              ),
              _ShortcutRow(
                'Seek forward ${preferences.seekStepSeconds} seconds',
                preferences.seekForwardKeyLabel,
              ),
              _ShortcutRow(
                'Volume down ${preferences.volumeStepPercent.round()}%',
                preferences.volumeDownKeyLabel,
              ),
              _ShortcutRow(
                'Volume up ${preferences.volumeStepPercent.round()}%',
                preferences.volumeUpKeyLabel,
              ),
              const _ShortcutRow('Toggle fullscreen', 'F11'),
              const _ShortcutRow('Context menu', 'Right-click'),
            ],
          ),
        ),
        actions: [
          TextButton(
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
        const SingleActivator(LogicalKeyboardKey.f11): () =>
            _runAction(_toggleFullscreen),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: MenuAnchor(
            controller: _contextMenuController,
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
                onHover: (_) => _bumpControlsVisibility(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (activeDrawer != ActiveDrawerPanel.none) {
                      ref.read(activeDrawerProvider.notifier).state =
                          ActiveDrawerPanel.none;
                    } else {
                      _bumpControlsVisibility();
                    }
                  },
                  onDoubleTap: ref.read(playbackProvider.notifier).playOrPause,
                  onSecondaryTapDown: (details) => _contextMenuController.open(
                      position: details.localPosition),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Video(
                          controller: videoController,
                          controls: NoVideoControls,
                          subtitleViewConfiguration: SubtitleViewConfiguration(
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
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        left: 0,
                        right: 0,
                        bottom: _showControls ? 0 : -130,
                        child: _BottomControlsBar(
                          onOpenFile: _pickMediaFile,
                          onShowPlaybackSettings: _showPlaybackSettings,
                          volume: playback.volume,
                          speed: playback.speed,
                          activeDrawer: activeDrawer,
                        ),
                      ),
                      if (activeDrawer == ActiveDrawerPanel.audio)
                        const Positioned(
                          top: 0,
                          bottom: 88,
                          right: 0,
                          child: EqualizerPanel(),
                        ),
                      if (activeDrawer == ActiveDrawerPanel.subtitles)
                        const Positioned(
                          top: 0,
                          bottom: 88,
                          right: 0,
                          child: SubtitlePanel(),
                        ),
                      if (activeDrawer == ActiveDrawerPanel.playlist)
                        Positioned(
                          top: 0,
                          bottom: 88,
                          right: 0,
                          child: PlaylistPanel(onAddFiles: _pickFilesToQueue),
                        ),
                    ],
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

class _BottomControlsBar extends ConsumerStatefulWidget {
  final Future<void> Function({bool allowMultiple}) onOpenFile;
  final VoidCallback onShowPlaybackSettings;
  final double volume;
  final double speed;
  final ActiveDrawerPanel activeDrawer;

  const _BottomControlsBar({
    required this.onOpenFile,
    required this.onShowPlaybackSettings,
    required this.volume,
    required this.speed,
    required this.activeDrawer,
  });

  @override
  ConsumerState<_BottomControlsBar> createState() => _BottomControlsBarState();
}

class _BottomControlsBarState extends ConsumerState<_BottomControlsBar> {
  double? _scrubPositionMs;
  Timer? _clearScrubTimer;

  @override
  void dispose() {
    _clearScrubTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playbackProvider.notifier);
    final position =
        ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration =
        ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final playing = ref.watch(playerPlayingProvider).valueOrNull ?? false;
    final maxMs =
        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final sliderMs = (_scrubPositionMs ?? currentMs).clamp(0.0, maxMs);
    final displayedPosition = Duration(milliseconds: sliderMs.round());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.92),
            Color.fromRGBO(0, 0, 0, 0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(formatDuration(displayedPosition),
                  style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: sliderMs,
                  min: 0.0,
                  max: maxMs,
                  onChanged: (value) {
                    setState(() => _scrubPositionMs = value);
                  },
                  onChangeEnd: (value) {
                    _clearScrubTimer?.cancel();
                    setState(() => _scrubPositionMs = value);
                    unawaited(playerNotifier.seekTo(
                      Duration(milliseconds: value.round()),
                    ));
                    _clearScrubTimer = Timer(
                      const Duration(milliseconds: 900),
                      () {
                        if (mounted) setState(() => _scrubPositionMs = null);
                      },
                    );
                  },
                ),
              ),
              Text(formatDuration(duration),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Open media file',
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: widget.onOpenFile,
              ),
              IconButton(
                tooltip: 'Previous item',
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: playerNotifier.previous,
              ),
              IconButton(
                iconSize: 32,
                icon: Icon(
                  playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                ),
                color: const Color(0xFFF59E0B),
                onPressed: playerNotifier.playOrPause,
              ),
              IconButton(
                tooltip: 'Next item',
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: playerNotifier.next,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.volume_up_rounded, size: 20),
              SizedBox(
                width: 110,
                child: Slider(
                  value: widget.volume,
                  min: 0.0,
                  max: 150.0,
                  onChanged: playerNotifier.setVolume,
                ),
              ),
              Text('${widget.volume.round()}%',
                  style: const TextStyle(fontSize: 12)),
              const Spacer(),
              PopupMenuButton<double>(
                tooltip: 'Playback speed',
                initialValue: widget.speed,
                onSelected: playerNotifier.setRate,
                itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map((rate) => PopupMenuItem(
                          value: rate,
                          child: Text('${rate}x'),
                        ))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${widget.speed}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Playback & shortcuts',
                icon: const Icon(Icons.tune_rounded),
                onPressed: widget.onShowPlaybackSettings,
              ),
              IconButton(
                tooltip: 'Playlist',
                icon: Icon(
                  Icons.queue_music_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.playlist
                      ? const Color(0xFFF59E0B)
                      : Colors.white,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.playlist
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.playlist,
              ),
              IconButton(
                tooltip: 'Audio equalizer and sync',
                icon: Icon(
                  Icons.graphic_eq_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.audio
                      ? const Color(0xFFF59E0B)
                      : Colors.white,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.audio
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.audio,
              ),
              IconButton(
                tooltip: 'Subtitle framing and sync',
                icon: Icon(
                  Icons.subtitles_rounded,
                  color: widget.activeDrawer == ActiveDrawerPanel.subtitles
                      ? const Color(0xFFF59E0B)
                      : Colors.white,
                ),
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    widget.activeDrawer == ActiveDrawerPanel.subtitles
                        ? ActiveDrawerPanel.none
                        : ActiveDrawerPanel.subtitles,
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Text(shortcut, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
