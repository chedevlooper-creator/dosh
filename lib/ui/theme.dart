import 'package:flutter/material.dart';

/// Oyunun renk paleti (tasarım spesifikasyonu §10).
abstract final class AppColors {
  // Gökyüzü / arka plan — altın saat (golden hour) atmosferi
  static const Color skyTop = Color(0xFF3F86C7);
  static const Color skyMid = Color(0xFF79B8E6);
  static const Color skyBottom = Color(0xFFCfe7F2);
  static const Color skyHorizon = Color(0xFFF6E3BE);

  // Altın tonları (harf baloncukları, bulunan kelimeler, kapsül)
  static const Color gold = Color(0xFFF5B62B);
  static const Color goldLight = Color(0xFFFFD75E);
  static const Color goldDark = Color(0xFFD9961A);
  static const Color goldBorder = Color(0xFFD9961A);

  // Manzara katmanları (vektör çizim renkleri - geriye dönük uyumluluk için korundu)
  static const Color ridgeFar = Color(0xFFA9C6DD);
  static const Color ridgeFarDark = Color(0xFF8FB2CC);
  static const Color snowCap = Color(0xFFF4F9FC);
  static const Color mist = Color(0xFFDCEAF2);
  static const Color ridgeMid = Color(0xFF6FA098);
  static const Color ridgeMidDark = Color(0xFF55857E);
  static const Color ridgeNear = Color(0xFF2F6B51);
  static const Color ridgeNearDark = Color(0xFF1F4A38);
  static const Color tower = Color(0xFF1B3A2E);
  static const Color towerLight = Color(0xFF2A5243);
  static const Color eagle = Color(0xCC2B3A45);

  // Metin ve kartlar
  static const Color ink = Color(0xFF122C3D); // Navy / koyu lacivert metin
  static const Color cardWhite = Color(0xD9FFFFFF);
  // Boş hücre: keskin fotoğraf üzerinde okunabilirlik için %65 opak
  // koyu gri-mavi (buzlu cam hissi; ince ışık konturuyla birlikte çalışır).
  static const Color cellEmpty = Color(0xA61E2B33);
  static const Color wheelDisc = Color(0xFFF2EAD8); // Krem rengi çark zemini
  static const Color wheelBorder = Color(0xFFE5D5BA); // Çark kenar rengi
  static const Color barButton = Color(0xFFFBF6EB); // Krem rengi buton arka planı
  static const Color barButtonBorder = Color(0xFFE9DCC4); // Krem buton kenar rengi
  static const Color barButtonHover = Color(0xFFF5EAD2);
  static const Color darkPill = Color(0xFF1E2B33); // Seviye rozet/bilgi zemini
}

/// Başlıklarda kullanılan serif kimlik (ana ekran diliyle uyumlu).
/// Georgia, Android'de bulunmadığında fallback devreye girer; ileride
/// PT Serif gibi Kiril+palochka kapsamalı bir serif bundle edilirse
/// yalnızca bu sabit değişir.
abstract final class AppText {
  static const String displayFamily = 'Georgia';
  static const List<String> displayFallback = ['NotoSans'];
}

/// Tüm bileşenlerin paylaştığı animasyon ritmi — "uyumlu" hissin kaynağı:
/// aynı tip hareket her yerde aynı süre ve eğriyle oynar.
abstract final class AppMotion {
  /// Anlık geri bildirim: hover, basma, seçim büyümesi.
  static const Duration fast = Duration(milliseconds: 120);

  /// Durum geçişleri: renk/gölge değişimi, kapsül görünümü.
  static const Duration base = Duration(milliseconds: 240);

  /// Yerleşme/pop animasyonları: hücreye harf inişi, panel girişi.
  static const Duration pop = Duration(milliseconds: 380);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve popCurve = Curves.easeOutBack;
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSans',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold),
      scaffoldBackgroundColor: const Color(0xFFE4EFF5),
    );

/// Okunabilirlik için yumuşak metin gölgesi.
const List<Shadow> kSoftTextShadow = [
  Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1.5)),
];
