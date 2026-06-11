import 'dart:math';
import 'package:flutter/material.dart';

import '../../audio/game_sound.dart';
import '../../core/constants.dart';
import '../../core/graphemes.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// Ekran görüntüsündeki tasarıma birebir uyan ana giriş ekranı.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.sound,
    required this.onStart,
  });

  final List<Level> levels;
  final ProgressStore store;
  final GameSound sound;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final level = levels[store.levelIndex % levels.length];
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Eğimli ayırıcı katmanları barındıran fotoğraf arka planı
          const ScenicBackground(),

          // Üst bar: Ses ve Altın kapsülleri (Krem renkli)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _HomeTopRow(
              coins: store.coins,
              sound: sound,
            ),
          ),

          // Başlık Bloğu: Dağ çizgileri, "Дош" başlığı ve alt süsleme çizgisi
          Positioned(
            top: height * 0.12,
            left: 0,
            right: 0,
            child: const _TitleBlock(),
          ),

          // Başla Butonu: Altın degrade ve geleneksel desenli kenarlar
          Positioned(
            top: height * 0.41,
            left: 0,
            right: 0,
            child: Center(
              child: _StartButton(
                key: const ValueKey('home_play'),
                onTap: onStart,
              ),
            ),
          ),

          // Seviye Rozeti: Eğim sınırının tam üzerine oturur
          Positioned(
            top: height * 0.55,
            left: 0,
            right: 0,
            child: Center(
              child: _LevelBadge(
                label: 'Seviye ${level.id}',
              ),
            ),
          ),

          // Alt Panel: Izgara Önizleme ve Harf Çarkı
          Positioned(
            top: height * 0.62,
            bottom: height * 0.12,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol: Izgara
                Expanded(
                  child: Center(
                    child: _MiniGrid(level: level),
                  ),
                ),
                const SizedBox(width: 8),
                // Sağ: Krem çark disk
                SizedBox(
                  width: height * 0.21,
                  height: height * 0.21,
                  child: _MiniWheel(letters: level.letters),
                ),
              ],
            ),
          ),

          // Alt Bar Butonları: İpucu, Karıştır, Hazine Sandığı
          Positioned(
            bottom: 15,
            left: 16,
            right: 16,
            child: _BottomActionBar(coins: store.coins),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Üst Bar Widget'ları
// ===========================================================================

class _HomeTopRow extends StatelessWidget {
  const _HomeTopRow({required this.coins, required this.sound});

  final int coins;
  final GameSound sound;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoundPill(sound: sound),
        const Spacer(),
        _CoinPill(coins: coins),
      ],
    );
  }
}

class _SoundPill extends StatelessWidget {
  const _SoundPill({required this.sound});

  final GameSound sound;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sound,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: sound.toggle,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.barButton,
              border: Border.all(color: AppColors.barButtonBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sound.enabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
                const Text(
                  'Ses',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.barButton,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.barButtonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CoinIcon(size: 20),
          const SizedBox(width: 8),
          Text(
            '$coins',
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

// ===========================================================================
// Başlık Bloğu
// ===========================================================================

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İnce altın dağ çizgileri
        CustomPaint(
          size: const Size(130, 34),
          painter: const _MountainOutlinePainter(),
        ),
        const SizedBox(height: 2),
        // Georgia serif yazı tipiyle Дош başlığı
        const Text(
          'Дош',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: Color(0xFF122C3D),
            fontSize: 74,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        // Altın düğümlü alt çizgi
        CustomPaint(
          size: const Size(190, 10),
          painter: const _UnderlinePainter(),
        ),
      ],
    );
  }
}

class _MountainOutlinePainter extends CustomPainter {
  const _MountainOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = const Color(0xFFD9961A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Sol küçük zirve
    final pathLeft = Path()
      ..moveTo(cx - 55, 34)
      ..lineTo(cx - 28, 16)
      ..lineTo(cx, 32);
    canvas.drawPath(pathLeft, paint);

    // Orta büyük zirve
    final pathCenter = Path()
      ..moveTo(cx - 32, 32)
      ..lineTo(cx, 10)
      ..lineTo(cx + 32, 32);
    canvas.drawPath(pathCenter, paint);

    // Sağ küçük zirve
    final pathRight = Path()
      ..moveTo(cx, 32)
      ..lineTo(cx + 28, 18)
      ..lineTo(cx + 55, 34);
    canvas.drawPath(pathRight, paint);
  }

  @override
  bool shouldRepaint(covariant _MountainOutlinePainter oldDelegate) => false;
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFFD9961A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Sol yatay çizgi
    canvas.drawLine(Offset(0, cy), Offset(cx - 14, cy), paint);
    // Sağ yatay çizgi
    canvas.drawLine(Offset(cx + 14, cy), Offset(size.width, cy), paint);

    // Ortadaki altın süs düğümü
    final knotPaint = Paint()
      ..color = const Color(0xFFD9961A)
      ..style = PaintingStyle.fill;

    final knotPath = Path()
      ..moveTo(cx, cy - 5)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 5)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(knotPath, knotPaint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) => false;
}

// ===========================================================================
// Başla Butonu ve Süslemeleri
// ===========================================================================

class _StartButton extends StatelessWidget {
  const _StartButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE489), Color(0xFFF5B62B), Color(0xFFD9961A)],
          ),
          border: Border.all(color: const Color(0xFFFFF6D8), width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ButtonOrnament(),
            SizedBox(width: 14),
            Text(
              'Başla',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Color(0xFF122C3D),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 14),
            _ButtonOrnament(),
          ],
        ),
      ),
    );
  }
}

class _ButtonOrnament extends StatelessWidget {
  const _ButtonOrnament();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: const _ButtonOrnamentPainter(),
    );
  }
}

class _ButtonOrnamentPainter extends CustomPainter {
  const _ButtonOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF6D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Dış baklava deseni
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(path, paint);

    // İç çizgiler
    canvas.drawLine(Offset(cx - r / 2, cy), Offset(cx + r / 2, cy), paint);
    canvas.drawLine(Offset(cx, cy - r / 2), Offset(cx, cy + r / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _ButtonOrnamentPainter oldDelegate) => false;
}

// ===========================================================================
// Alt Panel: Seviye Rozeti + Mini Izgara + Çark
// ===========================================================================

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF122C3D), // Koyu lacivert
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9961A), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFD75E),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFD75E),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final solvedCells = _getSolvedCells(level);

    final minR = level.minRow;
    final maxR = level.maxRow;
    final minC = level.minCol;
    final maxC = level.maxCol;

    final rows = maxR - minR + 1;
    final cols = maxC - minC + 1;

    // Küçük cihazlar için hücre boyutunu dinamik küçült
    const cell = 24.0;
    const gap = 3.0;

    final totalW = cols * cell + (cols - 1) * gap;
    final totalH = rows * cell + (rows - 1) * gap;

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        children: [
          for (final c in level.targetByCell.keys) ...[
            Positioned(
              left: (c.col - minC) * (cell + gap),
              top: (c.row - minR) * (cell + gap),
              child: Container(
                width: cell,
                height: cell,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: solvedCells.containsKey(c)
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.goldLight, AppColors.gold],
                        )
                      : null,
                  color: solvedCells.containsKey(c) ? null : AppColors.cellEmpty,
                  boxShadow: [
                    if (solvedCells.containsKey(c))
                      const BoxShadow(
                        color: Color(0x33D9961A),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    else
                      const BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                  ],
                ),
                child: solvedCells.containsKey(c)
                    ? Text(
                        solvedCells[c]!,
                        style: const TextStyle(
                          color: Color(0xFF122C3D),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<Cell, String> _getSolvedCells(Level level) {
    if (level.id == 1) {
      // Seviye 1 için ekran görüntüsündeki çözülmüş kelimeler ("дош", "шод", "до")
      return {
        const Cell(2, 1): 'Д',
        const Cell(2, 2): 'О',
        const Cell(2, 3): 'Ш',
        const Cell(4, 3): 'Ш',
        const Cell(4, 4): 'О',
        const Cell(4, 5): 'Д',
        const Cell(5, 5): 'Д',
        const Cell(6, 5): 'О',
      };
    }
    // Diğer seviyeler için varsayılan olarak ilk kelimeyi çözülmüş göster
    final firstWord = level.words.first;
    final map = <Cell, String>{};
    for (var i = 0; i < firstWord.cells.length; i++) {
      map[firstWord.cells[i]] = firstWord.graphemes[i].toUpperCase();
    }
    return map;
  }
}

class _MiniWheel extends StatelessWidget {
  const _MiniWheel({required this.letters});

  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final radius = size / 2;
        final letterRadius = radius * 0.70;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Krem renkli çark diski
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.wheelDisc,
                border: Border.all(
                  color: AppColors.wheelBorder,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),

            // Orta motif
            const Positioned.fill(
              child: CustomPaint(
                painter: _OrnamentPainter(),
              ),
            ),

            // Harfler doğrudan disk üzerine yerleştirilir (baloncuksuz)
            for (var i = 0; i < letters.length; i++) ...[
              Builder(
                builder: (context) {
                  final angle = -pi / 2 + 2 * pi * i / letters.length;
                  final x = radius + cos(angle) * letterRadius - 16;
                  final y = radius + sin(angle) * letterRadius - 16;
                  return Positioned(
                    left: x,
                    top: y,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        displayGrapheme(letters[i]),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          color: Color(0xFF122C3D),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // İç süsleme halkaları
    final ring = Paint()
      ..color = const Color(0x26D9961A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.40, ring);
    canvas.drawCircle(center, radius * 0.25, ring);

    // Geleneksel kıvrım çizgileri
    final horn = Paint()
      ..color = const Color(0x4DD9961A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(pi / 4 + 2 * pi * i / 4);
      canvas.translate(0, -radius * 0.32);
      final d = radius * 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(-d, 0), radius: d),
        -pi / 2,
        pi * 1.25,
        false,
        horn,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(d, 0), radius: d),
        -pi / 2,
        -pi * 1.25,
        false,
        horn,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) => false;
}

// ===========================================================================
// Alt Kısım Butonları
// ===========================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // İpucu (100)
        _HomeActionButton(
          icon: const Icon(
            Icons.lightbulb_outline_rounded,
            size: 26,
            color: Color(0xFF122C3D),
          ),
          cost: 100,
          onTap: () {},
        ),
        // Karıştır
        _HomeActionButton(
          icon: const Icon(
            Icons.shuffle_rounded,
            size: 28,
            color: Color(0xFF122C3D),
          ),
          cost: 0,
          onTap: () {},
        ),
        // Hazine Sandığı (100)
        _HomeActionButton(
          icon: const _TreasureIcon(size: 26),
          cost: 100,
          onTap: () {},
        ),
      ],
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.icon,
    required this.cost,
    required this.onTap,
  });

  final Widget icon;
  final int cost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Krem renkli dairesel buton
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.barButton,
            border: Border.all(
              color: AppColors.barButtonBorder,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: icon,
              ),
            ),
          ),
        ),
        if (cost > 0) ...[
          const SizedBox(height: 6),
          // Butonun altındaki altın kapsül
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD75E), Color(0xFFD9961A)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFB07B14),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CoinIcon(size: 11),
                const SizedBox(width: 4),
                Text(
                  '$cost',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TreasureIcon extends StatelessWidget {
  const _TreasureIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _TreasurePainter(),
    );
  }
}

class _TreasurePainter extends CustomPainter {
  const _TreasurePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gövde
    final body = Rect.fromLTWH(w * 0.05, h * 0.42, w * 0.90, h * 0.52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B5A2B), Color(0xFF5A3818)],
        ).createShader(body),
    );

    // Kapak
    final lid = Path()
      ..moveTo(w * 0.05, h * 0.45)
      ..quadraticBezierTo(w * 0.5, h * 0.15, w * 0.95, h * 0.45)
      ..lineTo(w * 0.95, h * 0.48)
      ..lineTo(w * 0.05, h * 0.48)
      ..close();
    canvas.drawPath(
      lid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA87037), Color(0xFF7B4920)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Altın bantlar
    final band = Paint()
      ..color = const Color(0xFFFFD75E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05;
    canvas.drawLine(Offset(w * 0.05, h * 0.45), Offset(w * 0.95, h * 0.45), band);
    canvas.drawLine(Offset(w * 0.05, h * 0.76), Offset(w * 0.95, h * 0.76), band);

    // Kilit
    final lock = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: w * 0.22,
      height: w * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lock, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFD75E),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.62),
      w * 0.045,
      Paint()..color = const Color(0xFF5A3818),
    );
  }

  @override
  bool shouldRepaint(covariant _TreasurePainter oldDelegate) => false;
}

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
      r * 0.78,
      Paint()
        ..color = const Color(0x99FFF1C2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16,
    );
    // "Д" logosu
    final tp = TextPainter(
      text: TextSpan(
        text: 'Д',
        style: TextStyle(
          fontSize: size.width * 0.56,
          fontWeight: FontWeight.w900,
          color: AppColors.goldDark,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      c - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter oldDelegate) => false;
}
