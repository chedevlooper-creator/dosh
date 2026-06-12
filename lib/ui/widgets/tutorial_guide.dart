import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../theme.dart';

/// Tutorial adım kimlikleri.
enum _TutorialStep {
  welcome,
  wheelDrag,
  wordSolved,
  shuffleHint,
  complete,
}

/// Oyun ekranının üstüne binen interaktif rehber katmanı.
///
/// Adım adım kullanıcıya oyun mekaniklerini öğretir: çark kullanımı,
/// kelime çözme, ipucu/karıştır butonları. Her adım oyun olaylarına
/// göre otomatik veya manuel olarak ilerler.
class TutorialGuide extends StatefulWidget {
  const TutorialGuide({
    super.key,
    required this.controller,
    required this.onComplete,
    required this.onSkip,
  });

  final GameController controller;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  State<TutorialGuide> createState() => _TutorialGuideState();
}

class _TutorialGuideState extends State<TutorialGuide>
    with TickerProviderStateMixin {
  _TutorialStep _step = _TutorialStep.welcome;
  StreamSubscription<GameEvent>? _eventSub;
  late final AnimationController _pulseCtrl;

  // Adım değişim animasyonu
  late final AnimationController _fadeCtrl;

  // Hedef alanların ekran pozisyonları (LayoutBuilder ile hesaplanır)
  Rect _wheelRect = Rect.zero;
  Rect _shuffleRect = Rect.zero;
  Rect _hintRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _eventSub = widget.controller.events.listen(_onGameEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fadeCtrl.forward();
    });
  }

  void _onGameEvent(GameEvent event) {
    if (!mounted) return;
    switch (event) {
      case WordSolved _:
        if (_step == _TutorialStep.wheelDrag) {
          _advance(to: _TutorialStep.wordSolved);
        }
      case LevelCompleted _:
        if (_step == _TutorialStep.shuffleHint) {
          _advance(to: _TutorialStep.complete);
        }
      default:
        break;
    }
  }

  void _advance({_TutorialStep? to}) {
    final next = to ?? _nextStep();
    if (next == null) return;
    setState(() {
      _step = next;
      _fadeCtrl.forward(from: 0);
    });
  }

  _TutorialStep? _nextStep() {
    final order = _TutorialStep.values;
    final idx = order.indexOf(_step);
    if (idx < order.length - 1) return order[idx + 1];
    return null;
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// LayoutBuilder'dan gelen constrained alan içinde çark/buton
  /// konumlarını hesaplar.
  void _layoutTargets(BoxConstraints constraints) {
    final cw = constraints.maxWidth;
    final ch = constraints.maxHeight;

    // Çark: oyun kolonunun alt yarısında, ortalanmış
    // GameScreen'deki gerçek hesapla aynı: min(cw * 0.62, 265.0)
    final wheelSize = min(cw * 0.62, 265.0).clamp(120.0, 265.0);
    final wheelLeft = (cw - wheelSize) / 2;
    final wheelTop = ch * 0.58 - wheelSize / 2;
    _wheelRect = Rect.fromLTWH(wheelLeft, wheelTop, wheelSize, wheelSize);

    // Karıştır butonu: çarkın solunda
    final btnSize = 54.0;
    _shuffleRect = Rect.fromLTWH(
      wheelLeft - btnSize - 12,
      wheelTop + (wheelSize - btnSize) / 2,
      btnSize,
      btnSize,
    );

    // İpucu butonu: çarkın sağında
    _hintRect = Rect.fromLTWH(
      wheelLeft + wheelSize + 12,
      wheelTop + (wheelSize - btnSize) / 2,
      btnSize,
      btnSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutTargets(constraints);
        return FadeTransition(
          opacity: _fadeCtrl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Koyu overlay (hedef alan delikli)
              Positioned.fill(
                child: CustomPaint(
                  painter: _OverlayPainter(
                    hole: _currentHole,
                    pulse: _pulseCtrl.value,
                    holeRadius: _currentHoleRadius,
                  ),
                ),
              ),
              // Adım içeriği
              Positioned.fill(child: _buildStepContent(constraints)),
              // Skip butonu (welcome dışında)
              if (_step != _TutorialStep.welcome)
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: _SkipButton(onTap: widget.onSkip),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Mevcut adımın delik pozisyonu.
  Rect? get _currentHole => switch (_step) {
        _TutorialStep.welcome => null,
        _TutorialStep.wheelDrag => _wheelRect,
        _TutorialStep.wordSolved => null,
        _TutorialStep.shuffleHint => _wheelRect,
        _TutorialStep.complete => null,
      };

  double get _currentHoleRadius => switch (_step) {
        _TutorialStep.welcome => 0,
        _TutorialStep.wheelDrag => 0,
        _TutorialStep.wordSolved => 0,
        _TutorialStep.shuffleHint => 0,
        _TutorialStep.complete => 0,
      };

  Widget _buildStepContent(BoxConstraints constraints) {
    switch (_step) {
      case _TutorialStep.welcome:
        return _buildWelcome(constraints);
      case _TutorialStep.wheelDrag:
        return _buildWheelDrag(constraints);
      case _TutorialStep.wordSolved:
        return _buildWordSolved(constraints);
      case _TutorialStep.shuffleHint:
        return _buildShuffleHint(constraints);
      case _TutorialStep.complete:
        return _buildComplete(constraints);
    }
  }

  // ── Adım 0: Karşılama ──────────────────────────────────────────────

  Widget _buildWelcome(BoxConstraints constraints) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          child: _TutorialCard(
            icon: Icons.celebration_rounded,
            iconColor: AppColors.gold,
            title: Strings.t('tutorial_welcome_title'),
            body: Strings.t('tutorial_welcome_body'),
            label: Strings.t('tutorial_welcome_btn'),
            onTap: () => _advance(to: _TutorialStep.wheelDrag),
          ),
        ),
      ),
    );
  }

  // ── Adım 1: Çark sürükleme ─────────────────────────────────────────

  Widget _buildWheelDrag(BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Çark etrafında parlayan hale
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final pulse = 0.2 + 0.2 * sin(2 * pi * _pulseCtrl.value);
              return CustomPaint(
                painter: _RipplePainter(
                  center: _wheelRect.center,
                  radius: _wheelRect.width / 2 + 24,
                  pulse: pulse,
                ),
              );
            },
          ),
        ),
        // Aşağıdan yukarı ok + bilgi kartı
        Positioned(
          bottom: constraints.maxHeight * 0.15,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ArrowPointer(
                direction: _ArrowDirection.up,
                size: 32,
                color: AppColors.goldLight,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: _InstructionBubble(
                  title: Strings.t('tutorial_drag_title'),
                  body: Strings.t('tutorial_drag_body'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _continueLabel => Strings.tOrNull('tutorial_continue') ?? 'Devam';

  // ── Adım 2: Kelime çözüldü ─────────────────────────────────────────

  Widget _buildWordSolved(BoxConstraints constraints) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: _TutorialCard(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.gold,
          title: Strings.t('tutorial_word_title'),
          body: Strings.t('tutorial_word_body'),
          label: _continueLabel,
          onTap: () => _advance(to: _TutorialStep.shuffleHint),
        ),
      ),
    );
  }

  // ── Adım 3: İpucu + Karıştır ───────────────────────────────────────

  Widget _buildShuffleHint(BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Karıştır butonu vurgusu
        Positioned(
          left: _shuffleRect.left - 6,
          top: _shuffleRect.top - 6,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final pulse = 0.15 + 0.12 * sin(2 * pi * _pulseCtrl.value);
              return Container(
                width: _shuffleRect.width + 12,
                height: _shuffleRect.height + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: pulse),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldLight.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // İpucu butonu vurgusu
        Positioned(
          left: _hintRect.left - 6,
          top: _hintRect.top - 6,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final pulse = 0.15 + 0.12 * sin(2 * pi * (_pulseCtrl.value + 0.3));
              return Container(
                width: _hintRect.width + 12,
                height: _hintRect.height + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: pulse),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldLight.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Bilgi kartı (üst kısımda)
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: _InstructionBubble(
              title: Strings.t('tutorial_tools_title'),
              body: Strings.t('tutorial_tools_body'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Adım 4: Tutorial tamamlandı ────────────────────────────────────

  Widget _buildComplete(BoxConstraints constraints) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: _TutorialCard(
          icon: Icons.rocket_launch_rounded,
          iconColor: AppColors.gold,
          title: Strings.t('tutorial_complete_title'),
          body: Strings.t('tutorial_complete_body'),
          label: Strings.t('tutorial_complete_btn'),
          onTap: widget.onComplete,
        ),
      ),
    );
  }
}

// ── Yardımcı widget'lar ──────────────────────────────────────────────

/// Overlay karartma ressamı: isteğe bağlı delikle.
class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.hole,
    required this.pulse,
    required this.holeRadius,
  });

  final Rect? hole;
  final double pulse;
  final double holeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xB30E1A22);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (hole != null) {
      final holePath = Path()
        ..addOval(hole!.inflate(8 + pulse * 12));
      final finalPath = Path.combine(
        PathOperation.difference,
        outer,
        holePath,
      );
      canvas.drawPath(finalPath, paint);
    } else {
      canvas.drawPath(outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.pulse != pulse;
}

/// Çark etrafında yayılan dalga halkası.
class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.center,
    required this.radius,
    required this.pulse,
  });

  final Offset center;
  final double radius;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.4 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius + 10 * pulse, paint);
    canvas.drawCircle(
      center,
      radius + 10 * pulse + 12,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.2 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Bilgi balonu (basit metin kartı).
class _InstructionBubble extends StatelessWidget {
  const _InstructionBubble({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xF0FBF6EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppText.displayFamily,
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Büyük kart (ikon + başlık + açıklama + buton).
class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF0), Color(0xFFFBF6EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.goldDark, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 48),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppText.displayFamily,
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 200,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE489),
                    Color(0xFFF5B62B),
                    Color(0xFFD9961A),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFF6D8),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppText.displayFamily,
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ok işareti (yukarı/aşağı/sol/sağ).
enum _ArrowDirection { up, down, left, right }

class _ArrowPointer extends StatelessWidget {
  const _ArrowPointer({
    required this.direction,
    required this.size,
    required this.color,
  });

  final _ArrowDirection direction;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double angle = 0;
    switch (direction) {
      case _ArrowDirection.up:
        angle = 0;
      case _ArrowDirection.down:
        angle = pi;
      case _ArrowDirection.left:
        angle = -pi / 2;
      case _ArrowDirection.right:
        angle = pi / 2;
    }
    return Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.arrow_drop_down_rounded,
        color: color,
        size: size,
      ),
    );
  }
}

/// Sağ üstte görünen "Atla" butonu.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = Strings.tOrNull('tutorial_skip') ?? 'Atla';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xAAFBF6EB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xAAFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.skip_next_rounded, size: 18, color: AppColors.ink),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
