import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Alt sağdaki coin kutusu. Coin kazanıldığında parlama/pulse animasyonu
/// oynar ve yukarı süzülen "+N" yazısı gösterir.
class CoinBox extends StatefulWidget {
  const CoinBox({
    super.key,
    required this.coins,
    required this.gainTick,
    required this.lastGain,
  });

  final int coins;
  final int gainTick;
  final int lastGain;

  @override
  State<CoinBox> createState() => _CoinBoxState();
}

class _CoinBoxState extends State<CoinBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(covariant CoinBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gainTick != oldWidget.gainTick) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = _pulse.value;
        final animating = _pulse.isAnimating;
        // Kısa büyüme-küçülme + altın parlama
        final scale = animating ? 1 + 0.14 * sin(pi * min(v * 1.6, 1.0)) : 1.0;
        final glow = animating ? (1 - v) : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.darkPill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                  boxShadow: [
                    if (glow > 0)
                      BoxShadow(
                        color: AppColors.gold
                            .withAlpha((150 * glow).round()),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kazançta coin kendi ekseninde döner (yazı tarafı flip)
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        animating
                            ? _flipScale(min(v * 1.5, 1.0))
                            : 1.0,
                        1.0,
                        1.0,
                      ),
                      child: const _CoinIcon(size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        shadows: kSoftTextShadow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (animating)
              Positioned(
                top: -16 - 18 * Curves.easeOut.transform(v),
                child: Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                  child: Text(
                    '+${widget.lastGain}',
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: kSoftTextShadow,
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

/// Tam tur coin dönüşü: cos eğrisi; kenarda tamamen incelmesin diye taban.
double _flipScale(double p) {
  final c = cos(2 * pi * p);
  return c.abs() < 0.06 ? (c.isNegative ? -0.06 : 0.06) : c;
}

/// Basit, özgün coin ikonu: altın disk + iç halka + "Д" damgası (Дош).
class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _CoinPainter(),
    );
  }
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.goldDark],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r * 0.80,
      Paint()
        ..color = const Color(0x99FFF1C2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14,
    );

    // "Д" damgası — oyunun adı (Дош) gibi gerçek bir Çeçen harfi
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Д',
        style: TextStyle(
          fontSize: size.width * 0.58,
          fontWeight: FontWeight.w800,
          color: AppColors.goldDark,
          fontFamily: 'NotoSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      c - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter oldDelegate) => false;
}
