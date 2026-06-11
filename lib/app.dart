import 'package:flutter/material.dart';

import 'core/strings.dart';
import 'data/models.dart';
import 'data/progress_store.dart';
import 'ui/screens/game_screen.dart';
import 'ui/theme.dart';

class DoshApp extends StatelessWidget {
  const DoshApp({super.key, required this.levels, required this.store});

  final List<Level> levels;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: GameScreen(levels: levels, store: store),
    );
  }
}
