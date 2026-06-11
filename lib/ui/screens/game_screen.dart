import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../../game/game_controller.dart';
import '../widgets/coin_box.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/effects/confetti_burst.dart';
import '../widgets/info_strip.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/scenic_background.dart';
import '../widgets/top_bar.dart';
import '../widgets/word_capsule.dart';

/// Ana oyun ekranı: arka plan, üst bar, crossword, kelime kapsülü, harf
/// çarkı (karıştırma + ipucu), coin kutusu ve alt bilgi şeridi.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levels, required this.store});

  final List<Level> levels;
  final ProgressStore store;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _game;
  late final StreamSubscription<GameEvent> _eventSub;

  int _shakeTick = 0;
  int _successTick = 0;
  String _successWord = '';
  int _gainTick = 0;
  int _lastGain = 0;
  int _confettiTick = 0;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _game = GameController(levels: widget.levels, store: widget.store);
    _eventSub = _game.events.listen(_onGameEvent);
  }

  void _onGameEvent(GameEvent event) {
    switch (event) {
      case WrongWord():
        setState(() => _shakeTick++);
      case WordSolved(:final word):
        setState(() {
          _successTick++;
          _successWord = word.word.toUpperCase();
        });
      case CoinsGained(:final amount):
        setState(() {
          _gainTick++;
          _lastGain = amount;
        });
      case LevelCompleted():
        setState(() => _confettiTick++);
        _advanceTimer?.cancel();
        _advanceTimer = Timer(const Duration(milliseconds: 2300), () {
          if (mounted) _game.nextLevel();
        });
      case AlreadyFound():
      case HintRevealed():
        break; // görsel karşılığı diğer bileşenlerde otomatik
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _eventSub.cancel();
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan tüm pencereye yayılır (geniş ekranda da).
          const ScenicBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: GameConfig.maxContentWidth,
                    ),
                    child: ListenableBuilder(
                      listenable: _game,
                      builder: (context, _) => _buildGameColumn(constraints),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(child: ConfettiBurst(trigger: _confettiTick)),
        ],
      ),
    );
  }

  Widget _buildGameColumn(BoxConstraints constraints) {
    final wheelSize = min(
      min(constraints.maxWidth * 0.62, 265.0),
      constraints.maxHeight * 0.36,
    );
    final level = _game.level;
    final infoText = _game.lastSolved == null
        ? null
        : Strings.tOrNull(_game.lastSolved!.infoKey);

    return Column(
      children: [
        TopBar(title: Strings.t('level_${_game.levelNumber}')),
        const SizedBox(height: 2),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: CrosswordGrid(
              key: ValueKey('grid_${level.id}'),
              controller: _game,
            ),
          ),
        ),
        WordCapsule(
          text: _game.currentWord.toUpperCase(),
          shakeTick: _shakeTick,
          successTick: _successTick,
          successText: _successWord,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Center(
                child: RoundIconButton(
                  icon: Icons.shuffle_rounded,
                  size: 54,
                  onTap: _game.shuffle,
                ),
              ),
            ),
            LetterWheel(
              key: ValueKey('wheel_${level.id}'),
              letters: level.letters,
              order: _game.wheelOrder,
              selection: _game.selection,
              size: wheelSize,
              enabled: !_game.levelDone,
              onEnterBubble: _game.enterBubble,
              onRelease: _game.releaseSelection,
            ),
            Expanded(
              child: Center(
                child: RoundIconButton(
                  icon: Icons.lightbulb_rounded,
                  size: 54,
                  badge: '${GameConfig.hintCost}',
                  enabled: _game.canHint,
                  pulse: true,
                  onTap: _game.useHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: InfoStrip(text: infoText)),
              const SizedBox(width: 10),
              CoinBox(
                coins: _game.coins,
                gainTick: _gainTick,
                lastGain: _lastGain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
