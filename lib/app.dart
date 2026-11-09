import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/player/screens/player_screen.dart';

class MyPlayerApp extends StatelessWidget {
  const MyPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPlayer Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const PlayerScreen(),
    );
  }
}
