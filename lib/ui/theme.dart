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

  // Manzara katmanları
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
  static const Color ink = Color(0xFF232A33);
  static const Color cardWhite = Color(0xD9FFFFFF); // ~%85 beyaz
  static const Color cellEmpty = Color(0xCCFFFFFF);
  static const Color wheelDisc = Color(0x59FFFFFF); // yarı şeffaf çark zemini
  static const Color barButton = Color(0x59FFFFFF);
  static const Color barButtonHover = Color(0x8CFFFFFF);
  static const Color darkPill = Color(0x4D1E2B33); // başlık/bilgi/coin zemini
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSans',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold),
      scaffoldBackgroundColor: AppColors.skyBottom,
    );

/// Okunabilirlik için yumuşak metin gölgesi.
const List<Shadow> kSoftTextShadow = [
  Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1.5)),
];
