import 'dart:ui';
import 'package:flutter/material.dart';

/// Ekran görüntüsündeki tasarıma birebir uyan, fotoğraf tabanlı arka plan.
/// Üst yarıda net dağ ve kule manzarası, alt yarıda ise eğimli bir beyaz sınırla
/// ayrılmış, bulanıklaştırılmış (blur) ve gölgeli oyun alanı bulunur.
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Net Arka Plan Görseli (Tüm ekrana yayılır)
        Image.asset(
          'assets/backgrounds/caucasus.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.3), // Kuleleri ve zirveleri ortalar
        ),

        // 2. Alt Eğimli Bölüm (Bulanık ve gölgeli alan)
        Positioned.fill(
          child: ClipPath(
            clipper: const _CurveSeparatorClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(
                // Ekran görüntüsündeki yumuşak krem rengi yarı şeffaf katman
                color: const Color(0x33FBF6EB),
              ),
            ),
          ),
        ),

        // 3. Eğim Sınırı Üzerindeki Beyaz Kalın Kontur ve Yumuşak Gölge
        const Positioned.fill(
          child: CustomPaint(
            painter: _CurveSeparatorPainter(),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

/// Alt oyun alanını sınırlayan eğriyi kesen Clipper.
/// Sol ve sağ köşelerde ekran yüksekliğinin %51'inden başlar, ortada %59'a kadar kavis yapar.
class _CurveSeparatorClipper extends CustomClipper<Path> {
  const _CurveSeparatorClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final yStart = size.height * 0.51;
    final yCenter = size.height * 0.59;

    path.moveTo(0, yStart);
    // Tek bir yumuşak parabolik kavis
    path.quadraticBezierTo(size.width / 2, yCenter, size.width, yStart);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CurveSeparatorClipper oldClipper) => false;
}

/// Eğim sınırı üzerine beyaz çizgi ve derinlik katan gölge çizen Painter.
class _CurveSeparatorPainter extends CustomPainter {
  const _CurveSeparatorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final yStart = size.height * 0.51;
    final yCenter = size.height * 0.59;
    final w = size.width;

    // 1. Yumuşak Alt Gölgelendirme (Derinlik efekti)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    path.moveTo(0, yStart + 1.5);
    path.quadraticBezierTo(w / 2, yCenter + 1.5, w, yStart + 1.5);
    canvas.drawPath(path, shadowPaint);

    // 2. Kalın Beyaz/Krem Çizgi (Ekran görüntüsündeki gibi)
    final borderPaint = Paint()
      ..color = const Color(0xFFFBF6EB)
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
