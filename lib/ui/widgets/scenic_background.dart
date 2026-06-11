import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Kodla çizilen tam ekran Kafkas manzarası — tamamen vektörel olduğu için
/// her çözünürlükte (4K dahil) keskin render edilir.
///
/// Üç katman:
///  1. Statik sahne: altın saat gökyüzü, karlı zirveler, sis bantları,
///     Vainakh kule kompleksi, ön sıradağlar (bir kez boyanır).
///  2. Canlı gökyüzü: süzülen bulutlar, süzülen kartal, nefes alan güneş
///     ışıması (tek yavaş animasyon döngüsü, kendi katmanında repaint).
///  3. Okunabilirlik overlay'i: vinyet + dikey gradyan.
///
/// Gerçek fotoğraf kullanmak için: görseli `assets/backgrounds/` altına
/// koyup pubspec'e ekleyin ve 1. katmanın yerine blur'lu `Image.asset`
/// yerleştirin; overlay katmanı aynen kalmalıdır.
class ScenicBackground extends StatefulWidget {
  const ScenicBackground({super.key});

  @override
  State<ScenicBackground> createState() => _ScenicBackgroundState();
}

class _ScenicBackgroundState extends State<ScenicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(
            painter: _SceneStaticPainter(),
            size: Size.infinite,
            isComplex: true,
            willChange: false,
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _life,
            builder: (context, _) => CustomPaint(
              painter: _SkyLifePainter(_life.value),
              size: Size.infinite,
            ),
          ),
        ),
        const RepaintBoundary(
          child: CustomPaint(
            painter: _OverlayPainter(),
            size: Size.infinite,
            willChange: false,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. KATMAN — statik sahne
// ---------------------------------------------------------------------------

class _SceneStaticPainter extends CustomPainter {
  const _SceneStaticPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Altın saat gökyüzü
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyTop,
            AppColors.skyMid,
            AppColors.skyBottom,
            AppColors.skyHorizon,
          ],
          stops: [0, 0.34, 0.56, 0.72],
        ).createShader(rect),
    );

    // Güneş çekirdeği (ışıma halkası canlı katmanda nefes alır)
    final sun = Offset(w * 0.76, h * 0.155);
    canvas.drawCircle(sun, w * 0.052, Paint()..color = const Color(0xE6FFF7DC));
    canvas.drawCircle(sun, w * 0.085, Paint()..color = const Color(0x33FFF0BE));

    // Uzak sıradağ + karlı zirveler
    const farPoints = [
      (0.00, 0.50), (0.10, 0.41), (0.22, 0.48), (0.34, 0.375),
      (0.46, 0.46), (0.58, 0.395), (0.72, 0.47), (0.85, 0.405), (1.00, 0.48),
    ];
    _ridge(canvas, size, farPoints, AppColors.ridgeFar, AppColors.ridgeFarDark);
    _snowCap(canvas, size, 0.10, 0.41);
    _snowCap(canvas, size, 0.34, 0.375);
    _snowCap(canvas, size, 0.58, 0.395);
    _snowCap(canvas, size, 0.85, 0.405);

    // Sis bandı 1 (uzak ile orta sıra arasında)
    _mistBand(canvas, size, 0.50, 0.07, 0.55);

    // Orta sıradağ
    _ridge(
      canvas,
      size,
      const [
        (0.00, 0.60), (0.14, 0.52), (0.28, 0.58), (0.42, 0.50),
        (0.55, 0.57), (0.68, 0.51), (0.82, 0.58), (1.00, 0.53),
      ],
      AppColors.ridgeMid,
      AppColors.ridgeMidDark,
    );

    // Sis bandı 2
    _mistBand(canvas, size, 0.625, 0.05, 0.45);

    // Vainakh kule kompleksi (önce arkadakiler, hafif pusla)
    _residentialTower(canvas, size, cx: 0.695, baseY: 0.715, bodyH: 0.115);
    _battleTower(canvas, size,
        cx: 0.815, baseY: 0.705, bodyH: 0.135, haze: 0.45);
    _battleTower(canvas, size, cx: 0.745, baseY: 0.725, bodyH: 0.215);

    // Ön sıradağ (kule tabanlarını gömer)
    _ridge(
      canvas,
      size,
      const [
        (0.00, 0.74), (0.12, 0.69), (0.26, 0.73), (0.40, 0.68),
        (0.56, 0.74), (0.70, 0.70), (0.84, 0.75), (1.00, 0.71),
      ],
      AppColors.ridgeNear,
      AppColors.ridgeNearDark,
    );
  }

  void _ridge(
    Canvas canvas,
    Size size,
    List<(double, double)> points,
    Color top,
    Color bottom,
  ) {
    final w = size.width;
    final h = size.height;
    final path = Path()..moveTo(points.first.$1 * w, points.first.$2 * h);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.$1 + curr.$1) / 2 * w;
      final midY = (prev.$2 + curr.$2) / 2 * h;
      path.quadraticBezierTo(prev.$1 * w, prev.$2 * h, midX, midY);
      if (i == points.length - 1) {
        path.lineTo(curr.$1 * w, curr.$2 * h);
      }
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(path.getBounds()),
    );
  }

  void _snowCap(Canvas canvas, Size size, double px, double py) {
    final w = size.width;
    final h = size.height;
    final cx = px * w;
    final cy = py * h;
    final half = w * 0.034;
    final drop = h * 0.030;
    final path = Path()
      ..moveTo(cx - half, cy + drop)
      // alt kenar hafif zikzaklı: erimiş kar çizgisi
      ..lineTo(cx - half * 0.45, cy + drop * 0.66)
      ..lineTo(cx - half * 0.12, cy + drop * 0.92)
      ..lineTo(cx + half * 0.25, cy + drop * 0.60)
      ..lineTo(cx + half * 0.6, cy + drop * 0.88)
      ..lineTo(cx + half, cy + drop * 0.55)
      ..lineTo(cx, cy - h * 0.004)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.snowCap.withAlpha(235));
  }

  void _mistBand(
      Canvas canvas, Size size, double cy, double thickness, double opacity) {
    final rect = Rect.fromLTWH(
      0,
      (cy - thickness / 2) * size.height,
      size.width,
      thickness * size.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.mist.withAlpha(0),
            AppColors.mist.withAlpha((255 * opacity).round()),
            AppColors.mist.withAlpha(0),
          ],
        ).createShader(rect),
    );
  }

  /// Savaş kulesi (бӀов): incelen gövde, taş derzleri, mazgallar, dendanlı
  /// saçak ve basamaklı piramit çatı — Vainakh mimarisinin imzası.
  void _battleTower(
    Canvas canvas,
    Size size, {
    required double cx,
    required double baseY,
    required double bodyH,
    double haze = 0.0,
  }) {
    final w = size.width;
    final h = size.height;
    final centerX = cx * w;
    final bottom = baseY * h;
    final top = bottom - bodyH * h;
    final baseHalf = w * 0.0315;
    final topHalf = w * 0.0195;

    Color shade(Color c) => haze == 0
        ? c
        : Color.lerp(c, AppColors.ridgeMid, haze)!;

    final bodyPaint = Paint()..color = shade(AppColors.tower);
    final lightPaint = Paint()..color = shade(AppColors.towerLight);

    // Gövde
    final body = Path()
      ..moveTo(centerX - baseHalf, bottom)
      ..lineTo(centerX - topHalf, top)
      ..lineTo(centerX + topHalf, top)
      ..lineTo(centerX + baseHalf, bottom)
      ..close();
    canvas.drawPath(body, bodyPaint);

    // Taş derz çizgileri (gövdeye doku)
    final seam = Paint()
      ..color = shade(AppColors.towerLight).withAlpha(110)
      ..strokeWidth = max(1.0, w * 0.0012);
    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final y = bottom - bodyH * h * t;
      final half = baseHalf + (topHalf - baseHalf) * t;
      canvas.drawLine(
        Offset(centerX - half * 0.92, y),
        Offset(centerX + half * 0.92, y),
        seam,
      );
    }

    // Mazgal pencereler + küçük kemerli pencere (ışık sızar)
    final window = Paint()..color = const Color(0x66F3E9C8);
    for (var i = 0; i < 3; i++) {
      final wy = top + bodyH * h * (0.30 + i * 0.20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, wy),
            width: w * 0.0052,
            height: w * 0.015,
          ),
          const Radius.circular(2),
        ),
        window,
      );
    }
    // Kemerli üst pencere
    final archY = top + bodyH * h * 0.14;
    final archR = w * 0.006;
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: Offset(centerX, archY), radius: archR),
          pi,
          pi,
        )
        ..addRect(Rect.fromLTRB(
            centerX - archR, archY, centerX + archR, archY + archR * 1.6)),
      window,
    );

    // Köşe dayanakları (machicolation) — saçağın altında dört çıkıntı
    final corbelW = w * 0.0058;
    final corbelH = bodyH * h * 0.045;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawRect(
        Rect.fromLTWH(
          centerX + dx * (topHalf * 1.18) - corbelW / 2,
          top - corbelH * 0.3,
          corbelW,
          corbelH,
        ),
        lightPaint,
      );
    }

    // Saçak + dendan (kale dişi)
    final corniceHalf = topHalf * 1.5;
    final corniceH = bodyH * h * 0.05;
    canvas.drawRect(
      Rect.fromLTRB(
        centerX - corniceHalf,
        top - corniceH,
        centerX + corniceHalf,
        top,
      ),
      bodyPaint,
    );

    // Basamaklı piramit çatı (üç kademe + tepe taşı)
    final roofBase = top - corniceH;
    final roofH = bodyH * h * 0.22;
    for (var step = 0; step < 3; step++) {
      final t0 = step / 3;
      final t1 = (step + 1) / 3;
      final half0 = corniceHalf * (1 - t0 * 0.92);
      final half1 = corniceHalf * (1 - t1 * 0.92);
      final y0 = roofBase - roofH * t0;
      final y1 = roofBase - roofH * t1;
      canvas.drawPath(
        Path()
          ..moveTo(centerX - half0, y0)
          ..lineTo(centerX - half1, y1)
          ..lineTo(centerX + half1, y1)
          ..lineTo(centerX + half0, y0)
          ..close(),
        step.isEven ? bodyPaint : lightPaint,
      );
    }
    // Tepe taşı (цӀогал)
    canvas.drawCircle(
      Offset(centerX, roofBase - roofH - w * 0.002),
      w * 0.0035,
      bodyPaint,
    );
  }

  /// Konut kulesi (гӀала): daha kısa, geniş, düz damlı.
  void _residentialTower(
    Canvas canvas,
    Size size, {
    required double cx,
    required double baseY,
    required double bodyH,
  }) {
    final w = size.width;
    final h = size.height;
    final centerX = cx * w;
    final bottom = baseY * h;
    final top = bottom - bodyH * h;
    final baseHalf = w * 0.040;
    final topHalf = w * 0.034;

    final paint = Paint()..color = AppColors.tower.withAlpha(225);
    canvas.drawPath(
      Path()
        ..moveTo(centerX - baseHalf, bottom)
        ..lineTo(centerX - topHalf, top)
        ..lineTo(centerX + topHalf, top)
        ..lineTo(centerX + baseHalf, bottom)
        ..close(),
      paint,
    );
    // Düz dam korkuluğu
    canvas.drawRect(
      Rect.fromLTRB(
        centerX - topHalf * 1.12,
        top - bodyH * h * 0.05,
        centerX + topHalf * 1.12,
        top,
      ),
      paint,
    );
    // İki küçük pencere
    final window = Paint()..color = const Color(0x59F3E9C8);
    for (final dx in [-0.45, 0.45]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + dx * topHalf, top + bodyH * h * 0.38),
            width: w * 0.0048,
            height: w * 0.011,
          ),
          const Radius.circular(1.5),
        ),
        window,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SceneStaticPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 2. KATMAN — canlı gökyüzü (bulutlar, kartal, güneş nefesi)
// ---------------------------------------------------------------------------

class _SkyLifePainter extends CustomPainter {
  const _SkyLifePainter(this.t);

  /// 0..1 — 60 saniyelik döngü.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Güneş ışıması nefesi (6 sn periyot)
    final sun = Offset(w * 0.76, h * 0.155);
    final breath = 0.55 + 0.20 * sin(2 * pi * t * 10);
    final glowR = w * 0.30;
    canvas.drawCircle(
      sun,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0BE).withAlpha((120 * breath).round()),
            const Color(0xFFFFE9A8).withAlpha((36 * breath).round()),
            const Color(0x00FFE9A8),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: sun, radius: glowR)),
    );

    // Bulut kümeleri: farklı hız/yükseklik, kenardan sarmalı (parallax)
    _cloud(canvas, size, phase: 0.10, speed: 1.0, y: 0.105, scale: 1.00, a: 66);
    _cloud(canvas, size, phase: 0.45, speed: 1.6, y: 0.205, scale: 0.74, a: 88);
    _cloud(canvas, size, phase: 0.78, speed: 0.7, y: 0.295, scale: 1.25, a: 48);

    _eagle(canvas, size);
  }

  void _cloud(
    Canvas canvas,
    Size size, {
    required double phase,
    required double speed,
    required double y,
    required double scale,
    required int a,
  }) {
    final w = size.width;
    final cx = ((phase + t * speed) % 1.0) * (w * 1.3) - w * 0.15;
    final cy = y * size.height;
    final r = w * 0.085 * scale;

    void puff(double dx, double dy, double pr) {
      final c = Offset(cx + dx * r, cy + dy * r);
      canvas.drawCircle(
        c,
        pr * r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withAlpha(a),
              Colors.white.withAlpha((a * 0.5).round()),
              Colors.white.withAlpha(0),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(Rect.fromCircle(center: c, radius: pr * r)),
      );
    }

    puff(-1.0, 0.18, 0.78);
    puff(-0.25, -0.18, 0.95);
    puff(0.55, 0.05, 0.85);
    puff(1.15, 0.26, 0.62);
  }

  /// Süzülen kartal silueti: yavaş geçiş + hafif kanat çırpışı.
  void _eagle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final x = (-0.12 + ((t * 1.0) % 1.0) * 1.24) * w;
    final y = (0.165 + 0.045 * sin(t * 2 * pi * 3)) * h;
    final span = w * 0.020;
    // Süzülme ağırlıklı, ara ara çırpış
    final flap = sin(t * 2 * pi * 36) * 0.30 * (0.4 + 0.6 * sin(t * 2 * pi));

    final paint = Paint()
      ..color = AppColors.eagle
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, w * 0.0022)
      ..strokeCap = StrokeCap.round;

    final body = Offset(x, y);
    final path = Path()
      ..moveTo(body.dx - span, body.dy - span * (0.30 + flap))
      ..quadraticBezierTo(
        body.dx - span * 0.45,
        body.dy + span * (0.22 - flap * 0.5),
        body.dx,
        body.dy,
      )
      ..quadraticBezierTo(
        body.dx + span * 0.45,
        body.dy + span * (0.22 - flap * 0.5),
        body.dx + span,
        body.dy - span * (0.30 + flap),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkyLifePainter oldDelegate) =>
      oldDelegate.t != t;
}

// ---------------------------------------------------------------------------
// 3. KATMAN — okunabilirlik overlay'i (vinyet + dikey gradyan)
// ---------------------------------------------------------------------------

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Dikey gradyan: üstte hafif, ortada şeffaf, altta derin (OLED kontrastı)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x3D14283A),
            Color(0x00000000),
            Color(0x1A0E2A20),
            Color(0x8C0B241B),
          ],
          stops: [0, 0.26, 0.52, 1],
        ).createShader(rect),
    );

    // Köşe vinyeti
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: const [Color(0x00000000), Color(0x33000000)],
          stops: const [0.62, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) => false;
}
