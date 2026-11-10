import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/title_cleaner.dart';

/// Minimal, elegant, translucent top window bar designed for MyPlayer Pro.
/// Features glassmorphism gradient fade, cleaned media title typography,
/// drag-to-move, and studio right-angle window caption controls.
class TopWindowBar extends StatelessWidget {
  final String? mediaUri;
  final int? playlistIndex;
  final int? playlistTotal;
  final bool isMaximized;
  final bool isFullScreen;
  final bool visible;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;

  const TopWindowBar({
    super.key,
    required this.mediaUri,
    this.playlistIndex,
    this.playlistTotal,
    required this.isMaximized,
    required this.isFullScreen,
    required this.visible,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onClose,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final hasMedia = mediaUri != null && mediaUri!.trim().isNotEmpty;
    final rawName = hasMedia ? mediaUri!.split(RegExp(r'[\\/]')).last : '';
    final cleanedTitle = hasMedia ? cleanMediaTitle(rawName) : 'MyPlayer Pro';

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        opacity: visible ? 1.0 : 0.0,
        child: MouseRegion(
          onEnter: (_) => onHoverEnter(),
          onExit: (_) => onHoverExit(),
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xEE090A0E),
                      Color(0xBF0A0B10),
                      Color(0x550A0B10),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.8, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    // Draggable branding and media title
                    Expanded(
                      child: DragToMoveArea(
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              // Sleek obsidian app badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0x18FFFFFF),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      size: 11,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'MYPLAYER PRO',
                                      style: TextStyle(
                                        color: Color(0xFFD3D6E0),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (hasMedia) ...[
                                Container(
                                  width: 1,
                                  height: 12,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  color: const Color(0x24FFFFFF),
                                ),
                                if (playlistTotal != null &&
                                    playlistTotal! > 1 &&
                                    playlistIndex != null) ...[
                                  Text(
                                    '[${playlistIndex! + 1}/$playlistTotal]',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Tooltip(
                                    message: rawName,
                                    waitDuration:
                                        const Duration(milliseconds: 600),
                                    child: Text(
                                      cleanedTitle,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFECEEF4),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Windows caption buttons (Minimize, Maximize / Restore, Close)
                    if (isDesktop) ...[
                      _CaptionButton(
                        icon: const Icon(
                          Icons.horizontal_rule_rounded,
                          size: 13,
                        ),
                        tooltip: 'Minimize',
                        onPressed: () => windowManager.minimize(),
                      ),
                      _CaptionButton(
                        icon: Icon(
                          isFullScreen
                              ? Icons.fullscreen_exit_rounded
                              : (isMaximized
                                  ? Icons.filter_none_rounded
                                  : Icons.crop_square_sharp),
                          size: isFullScreen
                              ? 15
                              : (isMaximized ? 11.5 : 12.5),
                        ),
                        tooltip: isFullScreen
                            ? 'Exit Fullscreen'
                            : (isMaximized ? 'Restore' : 'Maximize'),
                        onPressed: () async {
                          if (isFullScreen) {
                            onToggleFullscreen();
                          } else {
                            final max = await windowManager.isMaximized();
                            if (max) {
                              await windowManager.unmaximize();
                            } else {
                              await windowManager.maximize();
                            }
                          }
                        },
                      ),
                      _CaptionButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 15,
                        ),
                        tooltip: 'Close',
                        isClose: true,
                        onPressed: onClose,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _hovered
        ? (widget.isClose
            ? const Color(0xFFC42B1C)
            : const Color(0x18FFFFFF))
        : Colors.transparent;

    final iconColor = _hovered
        ? Colors.white
        : const Color(0xFF9EA2B2);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            onTap: widget.onPressed,
            child: SizedBox(
              width: widget.isClose ? 44 : 40,
              height: 36,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: iconColor,
                  ),
                  child: widget.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
