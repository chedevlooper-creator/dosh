import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/game_sound.dart';
import 'core/strings.dart';
import 'data/models.dart';
import 'data/progress_store.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/gallery_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/stats_screen.dart';
import 'ui/screens/dictionary_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/scenic_background.dart';

enum _AppScreen { home, gallery, game, settings, stats, dictionary }

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
  late _AppScreen _screen;
  int _pickedIndex = 0;
  bool _isDailyChallenge = false;
  late int _themeIndex;

  @override
  void initState() {
    super.initState();
    _sound = GameSound(store: widget.store);
    _themeIndex = widget.store.themeIndex;
    _screen = widget.showHome ? _AppScreen.home : _AppScreen.game;
    _isDailyChallenge = false;
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    widget.store.setThemeIndex(index);
    HapticFeedback.selectionClick();
  }

  SceneTheme get _theme => SceneTheme.values[_themeIndex];

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
        child: _buildScreen(),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case _AppScreen.home:
        return HomeScreen(
          key: const ValueKey('home'),
          levels: widget.levels,
          store: widget.store,
          sound: _sound,
          theme: _theme,
          onStart: _goGallery,
          onDailyChallenge: _startDailyChallenge,
          onStats: _goStats,
          onDictionary: _goDictionary,
          onSettings: _goSettings,
        );
      case _AppScreen.gallery:
        return GalleryScreen(
          key: const ValueKey('gallery'),
          levels: widget.levels,
          store: widget.store,
          theme: _theme,
          onPick: (i) {
            _pickedIndex = i;
            _sound.play(SoundCue.tap);
            setState(() => _screen = _AppScreen.game);
          },
          onBack: _goHome,
        );
      case _AppScreen.game:
        return GameScreen(
          key: const ValueKey('game'),
          levels: widget.levels,
          store: widget.store,
          sound: _sound,
          theme: _theme,
          startIndex: _pickedIndex,
          isDailyChallenge: _isDailyChallenge,
          onHome: _goHome,
          onTutorialComplete: _onTutorialComplete,
        );
      case _AppScreen.stats:
        return StatsScreen(
          key: const ValueKey('stats'),
          store: widget.store,
          theme: _theme,
          levelCount: widget.levels.length,
          onBack: _goHome,
        );
      case _AppScreen.dictionary:
        return DictionaryScreen(
          key: const ValueKey('dictionary'),
          store: widget.store,
          theme: _theme,
          levelCount: widget.levels.length,
          onBack: _goHome,
        );
      case _AppScreen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          store: widget.store,
          sound: _sound,
          themeIndex: _themeIndex,
          onThemeChanged: _setTheme,
          onHowToPlay: _onHowToPlay,
          onBack: _goHome,
        );
    }
  }

  void _goHome() {
    _sound.play(SoundCue.tap);
    setState(() => _screen = _AppScreen.home);
  }

  void _goSettings() {
    _sound.play(SoundCue.tap);
    setState(() => _screen = _AppScreen.settings);
  }

  void _goStats() {
    _sound.play(SoundCue.tap);
    setState(() => _screen = _AppScreen.stats);
  }

  void _goDictionary() {
    _sound.play(SoundCue.tap);
    setState(() => _screen = _AppScreen.dictionary);
  }

  void _goGallery() {
    _sound.play(SoundCue.tap);        if (widget.store.tutorialDone) {
          setState(() => _screen = _AppScreen.gallery);
        } else {
          _pickedIndex = 0;
          _isDailyChallenge = false;
          setState(() => _screen = _AppScreen.game);
        }
  }

  void _startDailyChallenge() {
    _sound.play(SoundCue.tap);
    _pickedIndex = ProgressStore.dailyLevelIndex(widget.levels.length);
    _isDailyChallenge = true;
    setState(() => _screen = _AppScreen.game);
  }

  void _onHowToPlay() {
    _sound.play(SoundCue.tap);
    _pickedIndex = 0;
    _isDailyChallenge = false;
    setState(() => _screen = _AppScreen.game);
  }

  void _onTutorialComplete() async {
    await widget.store.setTutorialDone(true);
    if (!mounted) return;
    _sound.play(SoundCue.tap);
    setState(() => _screen = _AppScreen.gallery);
  }
}
