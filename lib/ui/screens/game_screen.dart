import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/game_sound.dart';
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
  const GameScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.sound,
    this.onHome,
  });

  final List<Level> levels;
  final ProgressStore store;
  final GameSound sound;
  final VoidCallback? onHome;

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
        widget.sound.play(SoundCue.wrong);
        setState(() => _shakeTick++);
      case WordSolved(:final word):
        widget.sound.play(SoundCue.solve);
        setState(() {
          _successTick++;
          _successWord = word.word.toUpperCase();
        });
      case CoinsGained(:final amount):
        widget.sound.play(SoundCue.coin);
        setState(() {
          _gainTick++;
          _lastGain = amount;
        });
      case LevelCompleted():
        widget.sound.play(SoundCue.complete);
        setState(() => _confettiTick++);
        _advanceTimer?.cancel();
        _advanceTimer = Timer(const Duration(milliseconds: 2300), () {
          if (mounted) _game.nextLevel();
        });
      case HintRevealed():
        widget.sound.play(SoundCue.hint);
      case AlreadyFound():
        widget.sound.play(SoundCue.wrong);
        break; // görsel karşılığı diğer bileşenlerde otomatik
    }
  }

  void _enterBubble(int letterIndex) {
    final before = List<int>.from(_game.selection);
    _game.enterBubble(letterIndex);
    if (!_sameSelection(before, _game.selection)) {
      widget.sound.play(SoundCue.tap);
    }
  }

  bool _sameSelection(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _shuffle() {
    widget.sound.play(SoundCue.shuffle);
    _game.shuffle();
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
          const Positioned.fill(child: _GameLightOverlay()),
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
        ListenableBuilder(
          listenable: widget.sound,
          builder: (context, _) => TopBar(
            title: Strings.t('level_${_game.levelNumber}'),
            onBack: widget.onHome,
            onSettings: widget.sound.toggle,
            settingsIcon: widget.sound.enabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: _GridAura()),
                CrosswordGrid(
                  key: ValueKey('grid_${level.id}'),
                  controller: _game,
                ),
              ],
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
                  onTap: _shuffle,
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
              onEnterBubble: _enterBubble,
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

class _GameLightOverlay extends StatelessWidget {
  const _GameLightOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GameLightOverlayPainter());
  }
}

class _GameLightOverlayPainter extends CustomPainter {
  const _GameLightOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.58);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.45,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x2EFFE7A0), Color(0x00FFE7A0)],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.shortestSide * 0.45),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GameLightOverlayPainter oldDelegate) => false;
}

class _GridAura extends StatelessWidget {
  const _GridAura();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GridAuraPainter());
  }
}

class _GridAuraPainter extends CustomPainter {
  const _GridAuraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.92,
        height: size.height * 0.72,
      ),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x30FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _GridAuraPainter oldDelegate) => false;
}
