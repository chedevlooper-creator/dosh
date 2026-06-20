import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ekran görüntüsündeki tasarıma birebir uyan, **vektör tabanlı** arka plan.
///
/// *Fotoğraf bağımlılığı yoktur* — Kafkas dağ manzarası tamamen
/// `CustomPainter` ile çizilir. Üst yarıda net dağ ve kule manzarası,
/// alt yarıda ise eğimli bir beyaz sınırla ayrılmış, bulanıklaştırılmış
/// (blur) ve gölgeli oyun alanı bulunur.
///
/// [theme] parametresi ile farklı renk paletlerinde çizim yapılabilir
/// (ileride gece/orman teması için).
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({
    super.key,
    this.showPlayArea = true,
    this.theme = SceneTheme.caucasus,
  });

  /// Oyun ekranındaki okunabilir alan için kullanılan alt blur katmanı.
  final bool showPlayArea;

  /// Manzara teması (renk paleti).
  final SceneTheme theme;

  @override
  Widget build(BuildContext context) {
    String imagePath;
    switch (theme) {
      case SceneTheme.caucasus:
        imagePath = 'assets/images/caucasus_bg.png';
        break;
      case SceneTheme.night:
        imagePath = 'assets/images/night_bg.png';
        break;
      case SceneTheme.forest:
        imagePath = 'assets/images/forest_bg.png';
        break;
      case SceneTheme.autumn:
        imagePath = 'assets/images/autumn_bg.png';
        break;
      case SceneTheme.winter:
        imagePath = 'assets/images/winter_bg.png';
        break;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Premium 4K Image Background Backdrop
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),

        // 2. Weather & Atmospheric Effects Overlay (tema değişince crossfade)
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutQuad,
            switchOutCurve: Curves.easeInQuad,
            child: CustomPaint(
              key: ValueKey('scene_${theme.name}'),
              painter: _MountainScenePainter(theme: theme),
              size: Size.infinite,
            ),
          ),
        ),

        if (showPlayArea) ...{
          // 3. Alt Eğimli Bölüm (Bulanık ve gölgeli alan - frosted glass)
          Positioned.fill(
            child: ClipPath(
              clipper: const _CurveSeparatorClipper(),
              child: kIsWeb
                  ? Container(
                      color: const Color(0xEC0B132B), // Very dark frosted navy
                    )
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      child: Container(
                        color: const Color(0x2BFFFFFF),
                      ),
                    ),
            ),
          ),

          // 4. Eğim Sınırı Üzerindeki Beyaz Kalın Kontur ve Yumuşak Gölge
          const Positioned.fill(
            child: CustomPaint(
              painter: _CurveSeparatorPainter(),
              size: Size.infinite,
            ),
          ),
        },
      ],
    );
  }
}

/// Manzara teması seçenekleri.
enum SceneTheme {
  /// Kafkas Dağları — altın saat gökyüzü, yeşil/mavi dağlar (mevcut).
  caucasus,

  /// Gece — koyu lacivert gökyüzü, yıldızlar, hilal.
  night,

  /// Orman — yeşil tonlar, çam ağaçları, akarsu.
  forest,

  /// Sonbahar Vadisi — turuncu/kahverengi tonlar, yaprak dökümü.
  autumn,

  /// Karlı Kış — kar kaplı dağlar, kar yağışı.
  winter,
}

/// Tema bazlı renk paleti döndürür.
class _ScenePalette {
  const _ScenePalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.skyHorizon,
    required this.ridgeFar,
    required this.ridgeFarDark,
    required this.ridgeMid,
    required this.ridgeMidDark,
    required this.ridgeNear,
    required this.ridgeNearDark,
    required this.tower,
    required this.towerLight,
    required this.eagle,
    required this.starColor,
    required this.moonColor,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color skyHorizon;
  final Color ridgeFar;
  final Color ridgeFarDark;
  final Color ridgeMid;
  final Color ridgeMidDark;
  final Color ridgeNear;
  final Color ridgeNearDark;
  final Color tower;
  final Color towerLight;
  final Color eagle;
  final Color starColor;
  final Color moonColor;

  static const caucasus = _ScenePalette(
    skyTop: Color(0xFF3F86C7),
    skyMid: Color(0xFF79B8E6),
    skyBottom: Color(0xFFCfe7F2),
    skyHorizon: Color(0xFFF6E3BE),
    ridgeFar: Color(0xFFA9C6DD),
    ridgeFarDark: Color(0xFF8FB2CC),
    ridgeMid: Color(0xFF6FA098),
    ridgeMidDark: Color(0xFF55857E),
    ridgeNear: Color(0xFF2F6B51),
    ridgeNearDark: Color(0xFF1F4A38),
    tower: Color(0xFF1B3A2E),
    towerLight: Color(0xFF2A5243),
    eagle: Color(0xCC2B3A45),
    starColor: Colors.transparent,
    moonColor: Colors.transparent,
  );

  static const night = _ScenePalette(
    skyTop: Color(0xFF0A1628),
    skyMid: Color(0xFF12223F),
    skyBottom: Color(0xFF1C3A5E),
    skyHorizon: Color(0xFF2A5280),
    ridgeFar: Color(0xFF1A2F4A),
    ridgeFarDark: Color(0xFF15273E),
    ridgeMid: Color(0xFF122338),
    ridgeMidDark: Color(0xFF0E1B2B),
    ridgeNear: Color(0xFF0A141F),
    ridgeNearDark: Color(0xFF060E18),
    tower: Color(0xFF0A141F),
    towerLight: Color(0xFF1A3050),
    eagle: Color(0x99406080),
    starColor: Color(0xCCFFFFFF),
    moonColor: Color(0xFFFFF4C8),
  );

  static const forest = _ScenePalette(
    skyTop: Color(0xFF5B9F6B),
    skyMid: Color(0xFF7EBD8C),
    skyBottom: Color(0xFFB5DAB8),
    skyHorizon: Color(0xFFD4E8C8),
    ridgeFar: Color(0xFF6E9B6E),
    ridgeFarDark: Color(0xFF587F58),
    ridgeMid: Color(0xFF3D7A3D),
    ridgeMidDark: Color(0xFF2E5E2E),
    ridgeNear: Color(0xFF1E4D1E),
    ridgeNearDark: Color(0xFF143714),
    tower: Color(0xFF1A3A1A),
    towerLight: Color(0xFF2A522A),
    eagle: Color(0xAA2B452B),
    starColor: Colors.transparent,
    moonColor: Colors.transparent,
  );

  static const autumn = _ScenePalette(
    skyTop: Color(0xFFC84B31),
    skyMid: Color(0xFFD9B48F),
    skyBottom: Color(0xFFF3EAC2),
    skyHorizon: Color(0xFFFFD56B),
    ridgeFar: Color(0xFFD08C60),
    ridgeFarDark: Color(0xFFB57C50),
    ridgeMid: Color(0xFF99582A),
    ridgeMidDark: Color(0xFF6F3C1A),
    ridgeNear: Color(0xFF432818),
    ridgeNearDark: Color(0xFF2B190E),
    tower: Color(0xFF2B190E),
    towerLight: Color(0xFF8F5E36),
    eagle: Color(0xCC3E2723),
    starColor: Colors.transparent,
    moonColor: Colors.transparent,
  );

  static const winter = _ScenePalette(
    skyTop: Color(0xFF1D3557),
    skyMid: Color(0xFF457B9D),
    skyBottom: Color(0xFFA8DADC),
    skyHorizon: Color(0xFFF1FAEE),
    ridgeFar: Color(0xFFBDE0FE),
    ridgeFarDark: Color(0xFFA2D2FF),
    ridgeMid: Color(0xFF8E9AAF),
    ridgeMidDark: Color(0xFF6C757D),
    ridgeNear: Color(0xFF495057),
    ridgeNearDark: Color(0xFF343A40),
    tower: Color(0xFF212529),
    towerLight: Color(0xFFE9C46A),
    eagle: Color(0xCC212529),
    starColor: Colors.transparent,
    moonColor: Colors.transparent,
  );

  factory _ScenePalette.forTheme(SceneTheme theme) {
    switch (theme) {
      case SceneTheme.caucasus:
        return caucasus;
      case SceneTheme.night:
        return night;
      case SceneTheme.forest:
        return forest;
      case SceneTheme.autumn:
        return autumn;
      case SceneTheme.winter:
        return winter;
    }
  }
}

/// Dağ manzarasını çizen CustomPainter (fotoğrafsız, tamamen vektör).
class _MountainScenePainter extends CustomPainter {
  const _MountainScenePainter({required this.theme});

  final SceneTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == SceneTheme.night) {
      _drawStars(canvas, size, const Color(0xCCFFFFFF));
      _drawAurora(canvas, size);
    }

    if (theme == SceneTheme.autumn) {
      _drawFallingLeaves(canvas, size);
    }

    if (theme == SceneTheme.winter) {
      _drawSnowfall(canvas, size);
    }
  }

  void _drawStars(Canvas canvas, Size size, Color color) {
    if (color == Colors.transparent) return;
    final random = math.Random(42);

    // Samanyolu: çapraz yoğun yıldız bandı
    final milkyPaint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    final milkyPath = Path();
    final milkyWidth = size.width * 0.35;
    final milkyStart = Offset(size.width * 0.15, 0);
    final milkyEnd = Offset(size.width, size.height * 0.55);
    milkyPath.moveTo(milkyStart.dx - milkyWidth / 2, milkyStart.dy);
    milkyPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.2,
      milkyEnd.dx - milkyWidth / 2, milkyEnd.dy,
    );
    milkyPath.quadraticBezierTo(
      size.width * 0.5 + milkyWidth, size.height * 0.2,
      milkyEnd.dx + milkyWidth / 2, milkyEnd.dy,
    );
    milkyPath.lineTo(milkyStart.dx + milkyWidth / 2, milkyStart.dy);
    milkyPath.close();
    canvas.drawPath(milkyPath, milkyPaint);

    // Ana yıldız alanı (100+ yıldız)
    final starPaint = Paint()..color = color;
    for (var i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.55;
      final r = 0.3 + random.nextDouble() * 2.0;
      // Parlak yıldızlara hafif ışıma
      if (r > 1.5) {
        final glow = Paint()
          ..color = color.withAlpha(25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(x, y), r * 3, glow);
      }
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  void _drawMoon(Canvas canvas, Size size, Color color) {
    if (color == Colors.transparent) return;
    final cx = size.width * 0.78;
    final cy = size.height * 0.10;
    final r = size.shortestSide * 0.04;

    final moonPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), r, moonPaint);

    // Hilal efekti: koyu bir daire ile kes
    final shadowPaint = Paint()..color = const Color(0xFF0A1628);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.15), r * 0.82, shadowPaint);

    // Işık halesi
    final glowPaint = Paint()
      ..color = color.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), r * 2.5, glowPaint);
  }

  void _drawRidge(
    Canvas canvas,
    Size size,
    Color fill,
    Color shadow, {
    required List<Offset> points,
    required double? snowLine,
    Color snowColor = const Color(0xFFF4F9FC),
  }) {
    if (points.length < 2) return;
    final path = Path();
    final mapped = points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    path.moveTo(mapped.first.dx, size.height);
    for (final p in mapped) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(mapped.last.dx, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = fill);

    // Gölgelendirme (sağ-alt yamaç)
    final shadowPath = Path();
    shadowPath.moveTo(mapped.first.dx * 1.02, size.height);
    for (final p in mapped) {
      final skewed = Offset(p.dx + size.width * 0.02, p.dy + size.height * 0.01);
      shadowPath.lineTo(skewed.dx, skewed.dy);
    }
    shadowPath.lineTo(mapped.last.dx * 1.02, size.height);
    shadowPath.close();
    canvas.drawPath(shadowPath, Paint()..color = shadow);

    // Kar tepeleri
    if (snowLine != null) {
      final snowPath = Path();
      var inSnow = false;
      for (var i = 0; i < mapped.length; i++) {
        if (mapped[i].dy < size.height * snowLine) {
          if (!inSnow) {
            inSnow = true;
            // Sol kenar: zirvenin solundaki eğim
            final prev = (i > 0) ? mapped[i - 1] : mapped[i];
            final midDy = (prev.dy + mapped[i].dy) / 2;
            snowPath.moveTo((prev.dx + mapped[i].dx) / 2, midDy);
            snowPath.lineTo(mapped[i].dx, mapped[i].dy);
          } else {
            snowPath.lineTo(mapped[i].dx, mapped[i].dy);
          }
        } else {
          if (inSnow) {
            inSnow = false;
            // Sağ kenar: zirveden iniş
            final next = (i < mapped.length - 1) ? mapped[i] : mapped[i - 1];
            final midDy = (next.dy + mapped[i].dy) / 2;
            snowPath.lineTo((next.dx + mapped[i - 1].dx) / 2, midDy);
            snowPath.close();
          }
        }
      }
      if (inSnow) {
        snowPath.lineTo(mapped.last.dx, size.height * snowLine);
        snowPath.close();
      }
      canvas.drawPath(snowPath, Paint()..color = snowColor);
    }
  }

  void _drawTowerHill(Canvas canvas, Size size, _ScenePalette p) {
    final w = size.width;
    final h = size.height;

    // Tepe (tower'ın üzerinde durduğu yükselti)
    final hillPath = Path()
      ..moveTo(w * 0.58, h * 0.70)
      ..quadraticBezierTo(w * 0.64, h * 0.58, w * 0.72, h * 0.60)
      ..lineTo(w * 0.72, h * 0.70)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = p.ridgeNear);

    // Kule gövdesi
    final towerBase = w * 0.64;
    final towerTop = h * 0.38;
    final towerW = w * 0.045;
    final towerPath = Path()
      ..moveTo(towerBase, h * 0.62) // sol alt
      ..lineTo(towerBase, towerTop) // sol üst
      ..lineTo(towerBase, towerTop - h * 0.025) // sol üst çıkıntı
      ..lineTo(towerBase + towerW / 2, towerTop - h * 0.05) // tepe
      ..lineTo(towerBase + towerW, towerTop - h * 0.025) // sağ üst çıkıntı
      ..lineTo(towerBase + towerW, towerTop) // sağ üst
      ..lineTo(towerBase + towerW, h * 0.62) // sağ alt
      ..close();
    canvas.drawPath(towerPath, Paint()..color = p.tower);

    // Kule ışıkları (küçük dikdörtgen pencereler)
    final lightPaint = Paint()..color = p.towerLight;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.48 + i * 0.045);
      final windowRect = Rect.fromLTWH(
        towerBase + towerW * 0.2,
        y,
        towerW * 0.6,
        h * 0.025,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, const Radius.circular(1.0)),
        lightPaint,
      );
    }

    // Tepe ışığı (kulenin altında)
    final glowPaint = Paint()
      ..color = const Color(0x30FFD75E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(towerBase + towerW / 2, h * 0.53),
      towerW * 0.8,
      glowPaint,
    );
  }

  void _drawEagle(Canvas canvas, Size size, Color color) {
    if (color == Colors.transparent) return;

    final cx = size.width * 0.40;
    final cy = size.height * 0.18;
    final scale = size.shortestSide * 0.0008;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Kartal silueti (kanatlar açık)
    final eaglePath = Path()
      // Sol kanat
      ..moveTo(-40, -8)
      ..quadraticBezierTo(-60, -30, -100, -20)
      ..quadraticBezierTo(-80, -14, -55, -6)
      // Sol gövde
      ..quadraticBezierTo(-30, -4, -10, 2)
      // Kafa
      ..quadraticBezierTo(-6, -6, 0, -8)
      ..quadraticBezierTo(6, -6, 10, 2)
      // Sağ gövde
      ..quadraticBezierTo(30, -4, 55, -6)
      // Sağ kanat
      ..quadraticBezierTo(80, -14, 100, -20)
      ..quadraticBezierTo(60, -30, 40, -8)
      ..close();

    canvas.drawPath(eaglePath, paint);
    canvas.restore();
  }

  void _drawAurora(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Aurora borealis: 3 dalgalı yarı saydam kuşak
    final auroraColors = [
      const Color(0x30A8E6CF), // açık yeşil
      const Color(0x259E7BB5), // mor
      const Color(0x20B8E6A0), // açık yeşil
    ];

    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      final yBase = h * (0.08 + layer * 0.04);
      final phaseOffset = layer * 1.5;

      path.moveTo(0, yBase + math.sin(phaseOffset) * h * 0.03);

      for (var x = 0.0; x <= 1.0; x += 0.02) {
        final y = yBase +
            math.sin(x * 12 + phaseOffset) * h * 0.025 +
            math.sin(x * 5 + phaseOffset * 0.7) * h * 0.015;
        path.lineTo(x * w, y);
      }

      // Alt kenar için aşağı in
      for (var x = 1.0; x >= 0.0; x -= 0.02) {
        final y = yBase +
            h * 0.06 +
            math.sin(x * 12 + phaseOffset + 0.5) * h * 0.02;
        path.lineTo(x * w, y);
      }
      path.close();

      final paint = Paint()
        ..color = auroraColors[layer]
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawPath(path, paint);
    }
  }

  void _drawForestRiver(Canvas canvas, Size size, _ScenePalette p) {
    final w = size.width;
    final h = size.height;

    // Ana akarsu yolu (dağlardan ovaya)
    final riverPaint = Paint()
      ..color = const Color(0x8060A0C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(w * 0.22, h * 0.44);
    riverPath.quadraticBezierTo(w * 0.30, h * 0.50, w * 0.35, h * 0.52);
    riverPath.quadraticBezierTo(w * 0.42, h * 0.55, w * 0.45, h * 0.58);
    riverPath.quadraticBezierTo(w * 0.52, h * 0.60, w * 0.55, h * 0.64);
    riverPath.quadraticBezierTo(w * 0.62, h * 0.66, w * 0.70, h * 0.72);
    canvas.drawPath(riverPath, riverPaint);

    // İç çizgi (su parlaklığı) — aynı yolu tekrar çiz
    final highlightPaint = Paint()
      ..color = const Color(0x60FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.01;
    canvas.drawPath(riverPath, highlightPaint);

    // Su ışıltıları (beyaz noktalar)
    final sparklePaint = Paint()..color = const Color(0x80FFFFFF);
    final random = math.Random(7);
    for (var i = 0; i < 15; i++) {
      final t = 0.15 + random.nextDouble() * 0.7;
      final x = w * (0.25 + t * 0.45) + random.nextDouble() * w * 0.04;
      final y = h * (0.47 + t * 0.25) + random.nextDouble() * h * 0.02;
      final r = 0.8 + random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, sparklePaint);
    }
  }

  void _drawForestTrees(Canvas canvas, Size size, _ScenePalette p) {
    final w = size.width;
    final h = size.height;
    final random = math.Random(17);

    // Ağaç grupları: (x, baseY, scale) - ön dağ sırasına yakın
    final treePositions = [
      (dx: 0.06, baseY: 0.64, scale: 1.0),
      (dx: 0.10, baseY: 0.68, scale: 0.7),
      (dx: 0.15, baseY: 0.60, scale: 1.2),
      (dx: 0.20, baseY: 0.62, scale: 0.8),
      (dx: 0.24, baseY: 0.64, scale: 1.1),
      (dx: 0.30, baseY: 0.58, scale: 1.3),
      (dx: 0.35, baseY: 0.62, scale: 0.7),
      (dx: 0.42, baseY: 0.60, scale: 0.9),
      (dx: 0.50, baseY: 0.56, scale: 1.1),
      (dx: 0.55, baseY: 0.60, scale: 0.8),
      (dx: 0.62, baseY: 0.54, scale: 1.2),
      (dx: 0.68, baseY: 0.58, scale: 0.9),
      (dx: 0.75, baseY: 0.58, scale: 1.0),
      (dx: 0.80, baseY: 0.62, scale: 0.7),
      (dx: 0.85, baseY: 0.58, scale: 1.1),
      (dx: 0.90, baseY: 0.60, scale: 0.8),
    ];

    // Döngü dışı: değişmeyen Paint'ler tek seferde oluştur
    final shadowPaint = Paint()
      ..color = p.ridgeNearDark.withValues(alpha: 0.3);
    final trunkPaint = Paint()..color = const Color(0xFF3A2A1A);
    final tipPaint = Paint()
      ..color = const Color(0x30FFFFFF);

    for (final pos in treePositions) {
      final x = pos.dx * w;
      final treeH = h * 0.10 * pos.scale;
      final baseY = pos.baseY * h;
      final sOff = w * 0.008; // gölge kayması

      // Gölge (ağacın sağ altına)
      final shadowPath = Path();
      for (var tier = 0; tier < 3; tier++) {
        final t = tier / 3.0;
        final yBase = baseY - treeH * (0.12 + t * 0.65);
        final tierW = treeH * (0.30 - t * 0.15);
        final tierH = treeH * 0.28;
        shadowPath.addPolygon([
          Offset(x + sOff, yBase - tierH + sOff),
          Offset(x - tierW + sOff, yBase + sOff),
          Offset(x + tierW + sOff, yBase + sOff),
        ], true);
      }
      canvas.drawPath(shadowPath, shadowPaint);

      // Ağaç gövdesi
      final trunkW = treeH * 0.06;
      canvas.drawRect(
        Rect.fromLTWH(x - trunkW / 2, baseY - treeH * 0.12, trunkW, treeH * 0.12),
        trunkPaint,
      );

      // 3 katmanlı üçgen dallar (çam ağacı)
      final treePaint = Paint()
        ..color = Color.fromRGBO(
          0x1A - random.nextInt(8),
          0x4D + random.nextInt(12),
          0x1A - random.nextInt(8),
          1.0,
        );

      for (var tier = 0; tier < 3; tier++) {
        final t = tier / 3.0;
        final yBase = baseY - treeH * (0.12 + t * 0.65);
        final tierW = treeH * (0.30 - t * 0.15);
        final tierH = treeH * 0.28;

        final branchPath = Path()
          ..moveTo(x, yBase - tierH)
          ..lineTo(x - tierW, yBase)
          ..lineTo(x + tierW, yBase)
          ..close();
        canvas.drawPath(branchPath, treePaint);
      }

      // Tepe ışığı
      canvas.drawCircle(
        Offset(x, baseY - treeH * 0.82),
        treeH * 0.02,
        tipPaint,
      );
    }
  }

  void _drawFallingLeaves(Canvas canvas, Size size) {
    final random = math.Random(101);
    final leafColors = [
      const Color(0xFFE65100), // Koyu turuncu
      const Color(0xFFF57C00), // Orta turuncu
      const Color(0xFFFFB74D), // Sarı-turuncu
      const Color(0xFFD84315), // Kırmızımsı turuncu
      const Color(0xFF8D6E63), // Kurumuş kahverengi yaprak
    ];

    for (var i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.70;
      final leafW = 8.0 + random.nextDouble() * 12.0;
      final leafH = 4.0 + random.nextDouble() * 8.0;
      final rotation = random.nextDouble() * 2 * math.pi;
      final color = leafColors[random.nextInt(leafColors.length)];

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      // Yaprak şekli (iki bezıyer eğrisi ile)
      final path = Path()
        ..moveTo(-leafW / 2, 0)
        ..quadraticBezierTo(0, -leafH, leafW / 2, 0)
        ..quadraticBezierTo(0, leafH, -leafW / 2, 0)
        ..close();

      canvas.drawPath(path, paint);

      // Damar detayı (ince çizgi)
      final veinPaint = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(-leafW / 2, 0), Offset(leafW / 2, 0), veinPaint);

      canvas.restore();
    }
  }

  void _drawSnowfall(Canvas canvas, Size size) {
    final random = math.Random(202);
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (var i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.70;
      final r = 1.0 + random.nextDouble() * 3.0;

      // Bazı büyük kar tanelerine soft blur verelim (yakın planda uçuşan kar hissi)
      if (r > 3.0) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(Offset(x, y), r * 1.8, glowPaint);
      }
      canvas.drawCircle(Offset(x, y), r, snowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MountainScenePainter oldDelegate) =>
      oldDelegate.theme != theme;
}

/// Alt oyun alanını sınırlayan eğriyi kesen Clipper.
class _CurveSeparatorClipper extends CustomClipper<Path> {
  const _CurveSeparatorClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final yStart = size.height * 0.51;
    final yCenter = size.height * 0.59;

    path.moveTo(0, yStart);
    path.quadraticBezierTo(size.width / 2, yCenter, size.width, yStart);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CurveSeparatorClipper oldClipper) => false;
}

/// Eğim sınırı üzerine beyaz çizgi ve gölge çizen Painter.
class _CurveSeparatorPainter extends CustomPainter {
  const _CurveSeparatorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final yStart = size.height * 0.51;
    final yCenter = size.height * 0.59;
    final w = size.width;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    path.moveTo(0, yStart + 1.5);
    path.quadraticBezierTo(w / 2, yCenter + 1.5, w, yStart + 1.5);
    canvas.drawPath(path, shadowPaint);

    final borderPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final borderPath = Path();
    borderPath.moveTo(0, yStart);
    borderPath.quadraticBezierTo(w / 2, yCenter, w, yStart);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurveSeparatorPainter oldDelegate) => false;
}
