import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../theme.dart';

/// Seviye tamamlanınca açılan kutlama paneli: kazanılan coin özeti ve
/// devam butonu. Krem kart + lacivert başlık + altın buton (ana ekranın
/// görsel diliyle uyumlu). Arkadaki scrim oyun alanına dokunuşu engeller.
class LevelCompletePanel extends StatelessWidget {
  const LevelCompletePanel({
    super.key,
    required this.earned,
    required this.stars,
    required this.bestStreak,
    this.allDone = false,
    required this.onContinue,
  });

  /// Bu seviyede kazanılan toplam coin (0 ise satır gizlenir).
  final int earned;

  /// Bölüm performansı: 1-3 arası yıldız.
  final int stars;

  /// Bölüm içindeki en yüksek doğru kelime serisi.
  final int bestStreak;

  /// Tüm seviyeler tamamlandı mı? (döngüsel oyunda farklı mesaj)
  final bool allDone;

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // alttaki oyuna dokunuşu yutar
      child: Container(
        color: const Color(0xB30E1A22),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF0), AppColors.barButton],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.goldDark, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TowerSeal(size: 72),
                const SizedBox(height: 12),
                CustomPaint(
                  size: const Size(150, 12),
                  painter: const _DividerOrnamentPainter(),
                ),
                const SizedBox(height: 14),
                Text(
                  Strings.t('level_complete'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppText.displayFamily,
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _StarScore(stars: stars),
                if (bestStreak > 1) ...[
                  const SizedBox(height: 10),
                  _BestStreak(streak: bestStreak),
                ],
                if (earned > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _PanelCoin(size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '+$earned',
                        style: const TextStyle(
                          color: AppColors.goldDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: onContinue,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 200,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
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
                    child: Text(
                      Strings.t('continue'),
                      style: const TextStyle(
                        fontFamily: AppText.displayFamily,
                        color: AppColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarScore extends StatelessWidget {
  const _StarScore({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final clamped = stars.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i <= clamped ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.goldDark,
              size: i == 2 ? 30 : 26,
            ),
          ),
      ],
    );
  }
}

class _BestStreak extends StatelessWidget {
  const _BestStreak({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x141E2B33),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x24D9961A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.goldDark,
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '×$streak',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerSeal extends StatelessWidget {
  const _TowerSeal({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _TowerSealPainter(),
    );
  }
}

class _TowerSealPainter extends CustomPainter {
  const _TowerSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sealRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9A8), AppColors.goldDark],
        ).createShader(sealRect),
    );
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..color = const Color(0xAAFFF7D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final towerPaint = Paint()..color = AppColors.ink;
    final lightPaint = Paint()..color = const Color(0xFFFFF4C8);
    final base = size.height * 0.74;

    final tower = Path()
      ..moveTo(size.width * 0.34, base)
      ..lineTo(size.width * 0.38, size.height * 0.35)
      ..lineTo(size.width * 0.50, size.height * 0.23)
      ..lineTo(size.width * 0.62, size.height * 0.35)
      ..lineTo(size.width * 0.66, base)
      ..close();
    canvas.drawPath(tower, towerPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.47,
          size.height * 0.58,
          size.width * 0.06,
          size.height * 0.16,
        ),
        const Radius.circular(1.5),
      ),
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.43),
      size.width * 0.035,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TowerSealPainter oldDelegate) => false;
}

/// Kart üstündeki ince altın çizgi + baklava motifi.
class _DividerOrnamentPainter extends CustomPainter {
  const _DividerOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final line = Paint()
      ..color = AppColors.goldDark
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, cy), Offset(cx - 12, cy), line);
    canvas.drawLine(Offset(cx + 12, cy), Offset(size.width, cy), line);

    final knot = Paint()..color = AppColors.goldDark;
    final path = Path()
      ..moveTo(cx, cy - 5)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 5)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(path, knot);
  }

  @override
  bool shouldRepaint(covariant _DividerOrnamentPainter oldDelegate) => false;
}

/// Panel içi küçük coin görseli.
class _PanelCoin extends StatelessWidget {
  const _PanelCoin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.goldDark],
        ),
      ),
      child: Center(
        child: Text(
          'Д',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF8C5E0A),
            fontFamily: AppText.displayFamily,
          ),
        ),
      ),
    );
  }
}
