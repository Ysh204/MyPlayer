import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/player/providers/player_provider.dart';
import 'features/player/screens/player_screen.dart';

class MyPlayerApp extends ConsumerStatefulWidget {
  final String? screenshotPath;
  final ActiveDrawerPanel? initialDrawer;
  final List<String>? initialMediaPaths;

  const MyPlayerApp({
    super.key,
    this.screenshotPath,
    this.initialDrawer,
    this.initialMediaPaths,
  });

  @override
  ConsumerState<MyPlayerApp> createState() => _MyPlayerAppState();
}

class _MyPlayerAppState extends ConsumerState<MyPlayerApp> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeDrawerProvider.notifier).state = widget.initialDrawer!;
      });
    }
    final path = widget.screenshotPath;
    if (path != null) {
      _scheduleScreenshot(path);
    }
  }

  void _scheduleScreenshot(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        final boundary = _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File(path);
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(byteData.buffer.asUint8List());
          }
        }
      } catch (e) {
        stderr.writeln('Screenshot error: $e');
      } finally {
        exit(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPlayer Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return RepaintBoundary(
          key: _boundaryKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: PlayerScreen(initialMediaPaths: widget.initialMediaPaths),
    );
  }
}
