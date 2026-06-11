import 'package:flutter/material.dart';

import 'audio/game_sound.dart';
import 'core/strings.dart';
import 'data/models.dart';
import 'data/progress_store.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

class DoshApp extends StatefulWidget {
  const DoshApp({
    super.key,
    required this.levels,
    required this.store,
    this.showHome = true,
  });

  final List<Level> levels;
  final ProgressStore store;
  final bool showHome;

  @override
  State<DoshApp> createState() => _DoshAppState();
}

class _DoshAppState extends State<DoshApp> {
  late final GameSound _sound;
  late bool _showHome;

  @override
  void initState() {
    super.initState();
    _sound = GameSound(store: widget.store);
    _showHome = widget.showHome;
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showHome
            ? HomeScreen(
                key: const ValueKey('home'),
                levels: widget.levels,
                store: widget.store,
                sound: _sound,
                onStart: () {
                  _sound.play(SoundCue.tap);
                  setState(() => _showHome = false);
                },
              )
            : GameScreen(
                key: const ValueKey('game'),
                levels: widget.levels,
                store: widget.store,
                sound: _sound,
                onHome: () {
                  _sound.play(SoundCue.tap);
                  setState(() => _showHome = true);
                },
              ),
      ),
    );
  }
}
