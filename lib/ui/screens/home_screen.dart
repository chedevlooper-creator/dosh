import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/game_sound.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// Oyunun ana giriş ekranı: manzara, marka başlığı, seviye durumu ve başlatma.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.sound,
    required this.theme,
    required this.onStart,
    this.onDailyChallenge,
    this.onTimeAttack,
    this.onStats,
    this.onDictionary,
    this.onSettings,
  });

  final List<Level> levels;
  final ProgressStore store;
  final GameSound sound;
  final SceneTheme theme;
  final VoidCallback onStart;
  final VoidCallback? onDailyChallenge;
  final VoidCallback? onTimeAttack;
  final VoidCallback? onStats;
  final VoidCallback? onDictionary;
  final VoidCallback? onSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _coins;
  late bool _giftAvailable;
  int _giftBurstTick = 0;

  @override
  void initState() {
    super.initState();
    _coins = widget.store.coins;
    _giftAvailable = widget.store.giftAvailable(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.sound.startHomeAmbience();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sound != widget.sound) {
      oldWidget.sound.stopHomeAmbience();
      widget.sound.startHomeAmbience();
    }
  }

  @override
  void dispose() {
    widget.sound.stopHomeAmbience();
    super.dispose();
  }

  Future<void> _claimGift() async {
    if (!_giftAvailable) return;
    final now = DateTime.now();
    final nextCoins = _coins + GameConfig.dailyGiftCoins;
    setState(() {
      _coins = nextCoins;
      _giftAvailable = false;
      _giftBurstTick++;
    });
    widget.sound.play(SoundCue.coin);
    await widget.store.setCoins(nextCoins);
    await widget.store.markGiftClaimed(now);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.levels.isEmpty
        ? 0
        : widget.store.levelIndex.clamp(0, widget.levels.length - 1).toInt();
    final levelNumber = currentIndex + 1;
    final totalLevels = widget.levels.length;
    final progress = totalLevels == 0 ? 0.0 : levelNumber / totalLevels;

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => widget.sound.startHomeAmbience(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ScenicBackground(showPlayArea: false, theme: widget.theme),
            const _HomeReadabilityOverlay(),
            const _FlyingBirds(),
            Positioned.fill(child: _GiftClaimBurst(trigger: _giftBurstTick)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: GameConfig.maxContentWidth,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 700;
                      final veryCompact = constraints.maxHeight < 610;
                      final tiny = constraints.maxHeight < 520;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          tiny ? 8 : (compact ? 10 : 14),
                          18,
                          tiny ? 8 : (compact ? 14 : 22),
                        ),
                        child: Column(
                          children: [
                            _HomeTopRow(
                              coins: _coins,
                              sound: widget.sound,
                              giftAvailable: _giftAvailable,
                              onGift: _claimGift,
                              onStats: widget.onStats,
                              onDictionary: widget.onDictionary,
                              onSettings: widget.onSettings,
                            ),
                            SizedBox(
                              height: tiny ? 4 : (veryCompact ? 22 : 42),
                            ),
                            _TitleBlock(compact: compact, tiny: tiny),
                            if (!tiny)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _DailyChallengeCard(
                                    done: widget.store.dailyChallengeDone,
                                    levelNumber: ProgressStore.dailyLevelIndex(widget.levels.length),
                                    onTap: widget.onDailyChallenge ?? () {},
                                  ),
                                  _TimeAttackCard(
                                    highScore: widget.store.timeAttackHighScore,
                                    onTap: widget.onTimeAttack ?? () {},
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _HomeActionBand(
                              levelTitle: Strings.t('level_$levelNumber'),
                              levelNumber: levelNumber,
                              totalLevels: totalLevels,
                              progress: progress,
                              enabled: totalLevels > 0,
                              onStart: widget.onStart,
                              compact: tiny,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftClaimBurst extends StatefulWidget {
  const _GiftClaimBurst({required this.trigger});

  final int trigger;

  @override
  State<_GiftClaimBurst> createState() => _GiftClaimBurstState();
}

class _GiftClaimBurstState extends State<_GiftClaimBurst>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  );

  @override
  void didUpdateWidget(covariant _GiftClaimBurst oldWidget) {
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
            painter: _GiftClaimBurstPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _GiftClaimBurstPainter extends CustomPainter {
  const _GiftClaimBurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.73, size.height * 0.08);
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: fade * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(origin, 20 + 56 * eased, ringPaint);

    final sparkPaint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final angle = -pi * 0.9 + i * pi * 1.8 / 17;
      final dist = 16 + 70 * eased;
      final p1 = origin + Offset(cos(angle), sin(angle)) * dist;
      final p2 = origin + Offset(cos(angle), sin(angle)) * (dist + 8);
      sparkPaint
        ..color = (i.isEven ? AppColors.goldLight : Colors.white)
            .withValues(alpha: fade)
        ..strokeWidth = i.isEven ? 2.2 : 1.5;
      canvas.drawLine(p1, p2, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GiftClaimBurstPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _HomeReadabilityOverlay extends StatelessWidget {
  const _HomeReadabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x300A1B25),
            Color(0x000A1B25),
            Color(0x180A1B25),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _FlyingBirds extends StatefulWidget {
  const _FlyingBirds();

  @override
  State<_FlyingBirds> createState() => _FlyingBirdsState();
}

class _FlyingBirdsState extends State<_FlyingBirds>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionSettings.reduced(context)) {
      return const IgnorePointer(
        child: CustomPaint(
          painter: _BirdsPainter(progress: 0.22),
          size: Size.infinite,
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BirdsPainter(progress: _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BirdFlight {
  const _BirdFlight({
    required this.offset,
    required this.height,
    required this.size,
    required this.speed,
  });

  final double offset;
  final double height;
  final double size;
  final double speed;
}

class _BirdsPainter extends CustomPainter {
  const _BirdsPainter({required this.progress});

  final double progress;

  static const _flights = [
    _BirdFlight(offset: 0.00, height: 0.16, size: 0.72, speed: 1.00),
    _BirdFlight(offset: 0.19, height: 0.12, size: 0.46, speed: 0.86),
    _BirdFlight(offset: 0.41, height: 0.22, size: 0.56, speed: 1.12),
    _BirdFlight(offset: 0.64, height: 0.18, size: 0.38, speed: 0.94),
    _BirdFlight(offset: 0.81, height: 0.26, size: 0.60, speed: 1.06),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final birdPaint = Paint()
      ..color = const Color(0xB8122C3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPaint = Paint()
      ..color = const Color(0x7AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final flight in _flights) {
      final phase = (progress * flight.speed + flight.offset) % 1.0;
      final x = -size.width * 0.18 + phase * size.width * 1.36;
      final wave = sin((phase + flight.offset) * pi * 2);
      final y = size.height * (flight.height + wave * 0.018);
      final birdSize = size.shortestSide * 0.045 * flight.size;
      final flap = sin((progress * 9 + flight.offset) * pi * 2);

      canvas.save();
      canvas.translate(x, y);
      canvas.scale(birdSize / 18);
      _drawBird(canvas, highlightPaint, flap);
      _drawBird(canvas, birdPaint, flap);
      canvas.restore();
    }
  }

  void _drawBird(Canvas canvas, Paint paint, double flap) {
    final wingLift = 5 + flap * 4;
    final path = Path()
      ..moveTo(-17, 2)
      ..quadraticBezierTo(-8, -wingLift, 0, 0)
      ..quadraticBezierTo(8, -wingLift, 17, 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BirdsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _HomeTopRow extends StatelessWidget {
  const _HomeTopRow({
    required this.coins,
    required this.sound,
    required this.giftAvailable,
    required this.onGift,
    this.onStats,
    this.onDictionary,
    this.onSettings,
  });

  final int coins;
  final GameSound sound;
  final bool giftAvailable;
  final VoidCallback onGift;
  final VoidCallback? onStats;
  final VoidCallback? onDictionary;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoundPill(sound: sound, onStats: onStats, onDictionary: onDictionary, onSettings: onSettings),
        const Spacer(),
        _GiftPill(available: giftAvailable, onTap: onGift),
        const SizedBox(width: 10),
        _CoinPill(coins: coins),
      ],
    );
  }
}

class _GiftPill extends StatelessWidget {
  const _GiftPill({required this.available, required this.onTap});

  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: available ? 1 : 0.52,
      child: Material(
        color: const Color(0xDDFBF6EB),
        shape: const CircleBorder(side: BorderSide(color: Color(0xAAFFFFFF))),
        elevation: available ? 8 : 2,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: available ? onTap : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              if (available)
                Positioned(
                  right: -6,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.goldLight, AppColors.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFFF6D8),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '+${GameConfig.dailyGiftCoins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundPill extends StatelessWidget {
  const _SoundPill({required this.sound, this.onStats, this.onDictionary, this.onSettings});

  final GameSound sound;
  final VoidCallback? onStats;
  final VoidCallback? onDictionary;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sound,
      builder: (context, _) {
        final label = Strings.t('sound');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: label,
              child: Semantics(
                button: true,
                label: label,
                child: Material(
                  color: const Color(0xDDFBF6EB),
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xAAFFFFFF)),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0x33000000),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: sound.toggle,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        sound.enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: AppColors.ink,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              label: 'İstatistik',
              button: true,
              child: Material(
                color: const Color(0xDDFBF6EB),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xAAFFFFFF)),
                ),
                elevation: 8,
                shadowColor: const Color(0x33000000),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onStats,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.ink,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              label: 'Sözlük',
              button: true,
              child: Material(
                color: const Color(0xDDFBF6EB),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xAAFFFFFF)),
                ),
                elevation: 8,
                shadowColor: const Color(0x33000000),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDictionary,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.ink,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              label: 'Ayarlar',
              button: true,
              child: Material(
                color: const Color(0xDDFBF6EB),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xAAFFFFFF)),
                ),
                elevation: 8,
                shadowColor: const Color(0x33000000),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSettings,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.settings_rounded,
                      color: AppColors.ink,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xEAFBF6EB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xAAFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CoinMark(size: 22),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.compact, required this.tiny});

  final bool compact;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final titleSize = tiny ? 52.0 : (compact ? 68.0 : 84.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(
            tiny ? 92 : (compact ? 118 : 140),
            tiny ? 22 : (compact ? 30 : 36),
          ),
          painter: const _MountainOutlinePainter(),
        ),
        SizedBox(height: tiny ? 2 : (compact ? 4 : 6)),
        Text(
          'Дош',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppText.displayFamily,
            fontFamilyFallback: AppText.displayFallback,
            color: AppColors.ink,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 0.95,
            shadows: const [
              Shadow(
                color: Color(0x99FFFFFF),
                blurRadius: 16,
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Color(0x33000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: tiny ? 4 : 8),
        CustomPaint(
          size: Size(tiny ? 128 : (compact ? 168 : 198), 10),
          painter: const _UnderlinePainter(),
        ),
        if (!tiny) ...[
          const SizedBox(height: 12),
          Text(
            Strings.t('home_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xF0122C3D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: Color(0xCCFFFFFF),
                  blurRadius: 12,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeActionBand extends StatelessWidget {
  const _HomeActionBand({
    required this.levelTitle,
    required this.levelNumber,
    required this.totalLevels,
    required this.progress,
    required this.enabled,
    required this.onStart,
    required this.compact,
  });

  final String levelTitle;
  final int levelNumber;
  final int totalLevels;
  final double progress;
  final bool enabled;
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEAFBF6EB),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xAAFFFFFF), width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(10, compact ? 6 : 8, 12, compact ? 6 : 8),
              child: Row(
                children: [
                  _LevelBadge(levelNumber: levelNumber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: totalLevels == 0
                          ? '0/0'
                          : '$levelNumber/$totalLevels',
                      value: '${(progress * 100).round()}%',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  levelTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                totalLevels == 0
                                    ? '0/0'
                                    : '$levelNumber/$totalLevels',
                                style: const TextStyle(
                                  color: Color(0xCC122C3D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _ProgressTrack(progress: progress),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        SizedBox(
          width: compact ? 176 : 204,
          child: _StartButton(
            key: const ValueKey('home_play'),
            enabled: enabled,
            onTap: onStart,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
        ),
        border: Border.all(color: const Color(0xFFFFF3CC), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$levelNumber',
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE5D5BA)),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldDark,
                      AppColors.gold,
                      AppColors.goldLight,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    super.key,
    required this.enabled,
    required this.onTap,
    required this.compact,
  });

  final bool enabled;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: compact ? 46 : 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: enabled
                  ? const [
                      Color(0xFFFFE489),
                      AppColors.gold,
                      AppColors.goldDark,
                    ]
                  : const [
                      Color(0xFFE1D8C8),
                      Color(0xFFCFC4B3),
                    ],
            ),
            border: Border.all(color: const Color(0xFFFFF6D8), width: 2),
            boxShadow: [
              if (enabled)
                const BoxShadow(
                  color: Color(0x3B000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Strings.t('start'),
                      style: TextStyle(
                        fontFamily: AppText.displayFamily,
                        fontFamilyFallback: AppText.displayFallback,
                        color: AppColors.ink,
                        fontSize: compact ? 18 : 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.ink,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinMark extends StatelessWidget {
  const _CoinMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _CoinMarkPainter(),
    );
  }
}

class _CoinMarkPainter extends CustomPainter {
  const _CoinMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.goldDark],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius * 0.76,
      Paint()
        ..color = const Color(0x99FFF1C2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.16,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinMarkPainter oldDelegate) => false;
}

class _MountainOutlinePainter extends CustomPainter {
  const _MountainOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseline = size.height - 1;
    final paint = Paint()
      ..color = AppColors.goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx - size.width * 0.43, baseline)
      ..lineTo(cx - size.width * 0.23, size.height * 0.48)
      ..lineTo(cx - size.width * 0.03, baseline * 0.92)
      ..lineTo(cx, size.height * 0.18)
      ..lineTo(cx + size.width * 0.24, baseline * 0.92)
      ..lineTo(cx + size.width * 0.42, size.height * 0.54)
      ..lineTo(cx + size.width * 0.48, baseline);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MountainOutlinePainter oldDelegate) => false;
}

/// Günlük challenge kartı — home ekranında başlık altında gösterilir.
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.done,
    required this.levelNumber,
    required this.onTap,
  });

  final bool done;
  final int levelNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: done
          ? 'Günlük challenge tamamlandı'
          : 'Günlük challenge seviye $levelNumber',
      button: !done,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: done ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: done
                    ? const [Color(0xFF5A8F6A), Color(0xFF4A7B58)]
                    : const [Color(0xFFFFD580), AppColors.gold, AppColors.goldDark],
              ),
              border: Border.all(
                color: done ? const Color(0xFF8FBF9E) : const Color(0xFFFFF6D8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (done ? const Color(0x335A8F6A) : const Color(0x33000000))
                      .withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.star_rounded,
                  color: done ? const Color(0xFFD4F0DA) : AppColors.ink,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      done ? Strings.t('daily_challenge_done') : Strings.t('daily_challenge'),
                      style: TextStyle(
                        color: done ? const Color(0xFFD4F0DA) : AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Strings.t('level')} $levelNumber',
                      style: TextStyle(
                        color: (done ? const Color(0xFFD4F0DA) : AppColors.ink)
                            .withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!done) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.ink,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${GameConfig.dailyChallengeBonus}',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = AppColors.goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, cy), Offset(cx - 15, cy), paint);
    canvas.drawLine(Offset(cx + 15, cy), Offset(size.width, cy), paint);

    final knotPaint = Paint()
      ..color = AppColors.goldDark
      ..style = PaintingStyle.fill;
    final knot = Path()
      ..moveTo(cx, cy - 5)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 5)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(knot, knotPaint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) => false;
}

/// Zamana Karşı Yarış kartı — home ekranında başlık altında gösterilir.
class _TimeAttackCard extends StatelessWidget {
  const _TimeAttackCard({
    required this.highScore,
    required this.onTap,
  });

  final int highScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zamana karşı yarış, en yüksek skor $highScore',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF7043), Color(0xFFF4511E)],
              ),
              border: Border.all(
                color: const Color(0xFFFFCCBC),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33F4511E).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppColors.ink,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Strings.t('time_attack_title'),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Strings.t('time_attack_high_score').replaceAll('%d', highScore.toString()),
                      style: TextStyle(
                        color: AppColors.ink.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
