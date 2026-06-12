import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/game_sound.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/coin_box.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/effects/confetti_burst.dart';
import '../widgets/info_strip.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/level_complete_panel.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/scenic_background.dart';
import '../widgets/top_bar.dart';
import '../widgets/tutorial_guide.dart';
import '../widgets/word_capsule.dart';

/// Ana oyun ekranı: arka plan, üst bar, crossword, kelime kapsülü, harf
/// çarkı (karıştırma + ipucu), coin kutusu ve alt bilgi şeridi.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.sound,
    required this.theme,
    this.onHome,
    this.startIndex = 0,
    this.isDailyChallenge = false,
    this.onTutorialComplete,
  });

  final List<Level> levels;
  final ProgressStore store;
  final GameSound sound;
  final SceneTheme theme;
  final VoidCallback? onHome;

  /// Galeriden seçilen seviye indeksi. 0 ise store.levelIndex kullanılır.
  final int startIndex;

  /// Günlük challenge modu: bitince ana sayfaya dön + bonus coin.
  final bool isDailyChallenge;

  /// Tutorial tamamlandığında çağrılır (yalnızca seviye 0 için).
  final VoidCallback? onTutorialComplete;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _game;
  late final StreamSubscription<GameEvent> _eventSub;

  int _shakeTick = 0;
  int _successTick = 0;
  int _bonusTick = 0;
  String _successWord = '';
  int _gainTick = 0;
  int _lastGain = 0;
  int _comboTick = 0;
  int _comboAmount = 0;
  int _comboStreak = 0;
  int _confettiTick = 0;
  int _levelEarned = 0;
  bool _showComplete = false;
  bool _challengeBonusApplied = false;
  Timer? _advanceTimer;

  /// Son bulunan bonus kelime — alt bilgi şeridinde açıklaması gösterilir;
  /// ızgaradan yeni bir kelime çözülünce yerini ona bırakır.
  String? _lastBonusWord;

  @override
  void initState() {
    super.initState();
    _game = GameController(
      levels: widget.levels,
      store: widget.store,
      startIndex: widget.startIndex,
    );
    _eventSub = _game.events.listen(_onGameEvent);
  }

  void _onGameEvent(GameEvent event) {
    switch (event) {
      case WrongWord():
        widget.sound.play(SoundCue.wrong);
        HapticFeedback.mediumImpact();
        setState(() => _shakeTick++);
      case WordSolved(:final word):
        widget.sound.play(SoundCue.solve);
        HapticFeedback.lightImpact();
        setState(() {
          _successTick++;
          _successWord = word.word.toUpperCase();
          _lastBonusWord = null;
        });
      case BonusWordFound(:final word):
        widget.sound.play(SoundCue.solve);
        HapticFeedback.lightImpact();
        setState(() {
          // Bonus kelime: success animasyonu YOK (kapsül hâlâ seçimde
          // gösterilecek), sadece bonus-specific altın pulse tetiklenir.
          _bonusTick++;
          _successWord = word.toUpperCase();
          _lastBonusWord = word;
        });
      case CoinsGained(:final amount):
        widget.sound.play(SoundCue.coin);
        setState(() {
          _gainTick++;
          _lastGain = amount;
          _levelEarned += amount;
        });
      case ComboBonus(:final amount, :final streak):
        HapticFeedback.mediumImpact();
        setState(() {
          _comboTick++;
          _comboAmount = amount;
          _comboStreak = streak;
        });
      case LevelCompleted():
        widget.sound.play(SoundCue.complete);
        HapticFeedback.heavyImpact();
        setState(() => _confettiTick++);
        if (_game.level.id == 0) {
          // Tutorial seviyesi: LevelCompletePanel gösterilmez,
          // TutorialGuide "tamamlama" adımını kendisi yönetir.
        } else {
          if (widget.isDailyChallenge && !_challengeBonusApplied) {
            _challengeBonusApplied = true;
            final bonus = GameConfig.dailyChallengeBonus;
            _levelEarned += bonus;
            final newCoins = _game.coins + bonus;
            _game.coinsListenable.value = newCoins;
            unawaited(widget.store.setCoins(newCoins));
            unawaited(widget.store.markDailyChallengeDone());
          }
          // Normal seviye: harfler yerleşip konfeti başladıktan sonra
          // kutlama paneli açılır.
          _advanceTimer?.cancel();
          _advanceTimer = Timer(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _showComplete = true);
          });
        }
      case HintRevealed():
        widget.sound.play(SoundCue.hint);
      case AlreadyFound():
        widget.sound.play(SoundCue.wrong);
        // Tekrar girilen kelimede de görsel uyarı: kapsül sallanır.
        setState(() => _shakeTick++);
    }
  }

  void _enterBubble(int letterIndex) {
    if (_game.enterBubble(letterIndex)) {
      widget.sound.play(SoundCue.tap);
      HapticFeedback.selectionClick();
    }
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
          ScenicBackground(showPlayArea: false, theme: widget.theme),
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
          // Tutorial rehberi (seviye 0)
          if (_game.level.id == 0)
            Positioned.fill(
              child: TutorialGuide(
                controller: _game,
                onComplete: widget.onTutorialComplete ?? () {},
                onSkip: widget.onTutorialComplete ?? () {},
              ),
            ),
          Positioned.fill(
            child: _ComboBonusBurst(
              trigger: _comboTick,
              amount: _comboAmount,
              streak: _comboStreak,
            ),
          ),
          if (_showComplete)
            Positioned.fill(
              child: LevelCompletePanel(
                earned: _levelEarned,
                stars: _game.performanceStars,
                bestStreak: _game.bestStreak,
                allDone: _game.isLastLevel,
                onContinue: _continueNext,
              ),
            ),
        ],
      ),
    );
  }

  void _continueNext() {
    if (_game.level.id == 0) {
      // Tutorial seviyesi tamamlandı — dışarıya bildir.
      widget.onTutorialComplete?.call();
      return;
    }
    if (widget.isDailyChallenge) {
      // Günlük challenge: ana sayfaya dön.
      widget.onHome?.call();
      return;
    }
    widget.sound.play(SoundCue.tap);
    setState(() {
      _showComplete = false;
      _levelEarned = 0;
    });
    _game.nextLevel();
  }

  Widget _buildGameColumn(BoxConstraints constraints) {
    final wheelSize = min(
      min(constraints.maxWidth * 0.62, 265.0),
      constraints.maxHeight * 0.36,
    );
    final level = _game.level;
    final infoText = _game.lastSolved == null
        ? (_game.foundBonusWords.isNotEmpty
            ? Strings.tOrNull('info_$_lastBonusWord')
            : null)
        : Strings.tOrNull(_game.lastSolved!.infoKey);

    return Column(
      children: [
        ListenableBuilder(
          listenable: widget.sound,
          builder: (context, _) => TopBar(
            title:
                '${Strings.t('level_${_game.levelNumber}')}  ${_game.solvedWords.length}/${_game.level.distinctWordCount}',
            onBack: widget.onHome,
            onSettings: widget.sound.toggle,
            settingsIcon: widget.sound.enabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
          ),
        ),
        const SizedBox(height: 2),
        // Sadece streak değiştiğinde rebuild olur (granüler dinleme).
        ListenableBuilder(
          listenable: _game.streakListenable,
          builder: (context, _) => _StreakMeter(streak: _game.streak),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: _GridAura()),
                Positioned.fill(child: _SolveAura(trigger: _successTick)),
                CrosswordGrid(
                  key: ValueKey('grid_${level.id}'),
                  controller: _game,
                ),
              ],
            ),
          ),
        ),
        // Sadece seçim değiştiğinde rebuild olur (granüler dinleme).
        ListenableBuilder(
          listenable: _game.selectionListenable,
          builder: (context, _) => WordCapsule(
            text: _game.currentWord.toUpperCase(),
            shakeTick: _shakeTick,
            successTick: _successTick,
            bonusTick: _bonusTick,
            successText: _successWord,
          ),
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
              // Sadece coin değiştiğinde rebuild olur (granüler dinleme).
              ListenableBuilder(
                listenable: _game.coinsListenable,
                builder: (context, _) => CoinBox(
                  coins: _game.coins,
                  gainTick: _gainTick,
                  lastGain: _lastGain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _StreakMeter extends StatelessWidget {
  const _StreakMeter({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final visible = streak > 0;
    var activeDots = streak % GameConfig.comboMilestone;
    if (visible && activeDots == 0) activeDots = GameConfig.comboMilestone;

    return AnimatedSize(
      duration: AppMotion.base,
      curve: AppMotion.enter,
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.base,
                  child: Container(
                    key: ValueKey(streak),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1E2B33),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.goldLight,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '×$streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            shadows: kSoftTextShadow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (var i = 0; i < GameConfig.comboMilestone; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 3,
                            ),
                            child: AnimatedContainer(
                              duration: AppMotion.fast,
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < activeDots
                                    ? AppColors.goldLight
                                    : const Color(0x45FFFFFF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ComboBonusBurst extends StatefulWidget {
  const _ComboBonusBurst({
    required this.trigger,
    required this.amount,
    required this.streak,
  });

  final int trigger;
  final int amount;
  final int streak;

  @override
  State<_ComboBonusBurst> createState() => _ComboBonusBurstState();
}

class _ComboBonusBurstState extends State<_ComboBonusBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980),
  );

  @override
  void didUpdateWidget(covariant _ComboBonusBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating) return const SizedBox.shrink();
          return CustomPaint(
            painter: _ComboBonusBurstPainter(
              t: _controller.value,
              amount: widget.amount,
              streak: widget.streak,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ComboBonusBurstPainter extends CustomPainter {
  const _ComboBonusBurstPainter({
    required this.t,
    required this.amount,
    required this.streak,
  });

  final double t;
  final int amount;
  final int streak;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    final origin = Offset(size.width * 0.5, size.height * 0.58);

    final ringPaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.55 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(origin, 42 + 96 * eased, ringPaint);

    final spark = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    for (var i = 0; i < 18; i++) {
      final a = -pi + i * 2 * pi / 18;
      final d = 44 + 84 * eased;
      spark.color = (i.isEven ? AppColors.goldLight : Colors.white)
          .withValues(alpha: 0.95 * fade);
      canvas.drawLine(
        origin + Offset(cos(a), sin(a)) * d,
        origin + Offset(cos(a), sin(a)) * (d + 13),
        spark,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '×$streak  '),
          TextSpan(text: '+$amount'),
        ],
        style: TextStyle(
          color: Colors.white.withValues(alpha: fade),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.45 * fade),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      origin - Offset(textPainter.width / 2, 86 + 24 * eased),
    );
  }

  @override
  bool shouldRepaint(covariant _ComboBonusBurstPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.amount != amount ||
      oldDelegate.streak != streak;
}

class _SolveAura extends StatefulWidget {
  const _SolveAura({required this.trigger});

  final int trigger;

  @override
  State<_SolveAura> createState() => _SolveAuraState();
}

class _SolveAuraState extends State<_SolveAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void didUpdateWidget(covariant _SolveAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating) return const SizedBox.shrink();
          return CustomPaint(
            painter: _SolveAuraPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SolveAuraPainter extends CustomPainter {
  const _SolveAuraPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (0.18 + eased * 0.42);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldLight.withValues(alpha: 0.42 * fade),
          AppColors.gold.withValues(alpha: 0.18 * fade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    final sweepPaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.78 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.82,
      height: size.height * 0.58,
    );
    canvas.drawArc(
        rect, -pi * 0.92 + eased * pi * 1.2, pi * 0.42, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SolveAuraPainter oldDelegate) =>
      oldDelegate.t != t;
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
