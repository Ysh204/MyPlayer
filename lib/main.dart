import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'features/player/providers/player_provider.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  String? screenshotPath;
  ActiveDrawerPanel? initialDrawer;
  final List<String> initialMediaPaths = [];

  for (final arg in args) {
    if (arg.startsWith('--screenshot=')) {
      screenshotPath = arg.substring('--screenshot='.length);
    } else if (arg == '--drawer=audio' || arg == '--drawer=equalizer') {
      initialDrawer = ActiveDrawerPanel.audio;
    } else if (arg == '--drawer=playlist') {
      initialDrawer = ActiveDrawerPanel.playlist;
    } else if (arg == '--drawer=subtitles') {
      initialDrawer = ActiveDrawerPanel.subtitles;
    } else if (!arg.startsWith('--') && arg.trim().isNotEmpty) {
      initialMediaPaths.add(arg.trim());
    }
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 760),
      minimumSize: Size(800, 500),
      center: true,
      backgroundColor: Colors.black,
      title: 'MyPlayer Pro',
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await windowManager.setPreventClose(true);
  }

  runApp(
    ProviderScope(
      child: MyPlayerApp(
        screenshotPath: screenshotPath,
        initialDrawer: initialDrawer,
        initialMediaPaths: initialMediaPaths,
      ),
    ),
  );
}
