import 'package:flutter/material.dart';

/// Oyunun renk paleti (tasarım spesifikasyonu §10).
abstract final class AppColors {
  // Gökyüzü / arka plan — altın saat (golden hour) atmosferi
  static const Color skyTop = Color(0xFF2E6FB5);
  static const Color skyMid = Color(0xFF6FB0E4);
  static const Color skyBottom = Color(0xFFC9E5F4);
  static const Color skyHorizon = Color(0xFFFAE3B2);

  // Altın tonları (harf baloncukları, bulunan kelimeler, kapsül)
  static const Color gold = Color(0xFFF5B62B);
  static const Color goldLight = Color(0xFFFFD75E);
  static const Color goldDark = Color(0xFFD9961A);
  static const Color goldBorder = Color(0xFFC8880F);
  static const Color goldDeep = Color(0xFFA86F08);

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
  static const Color inkSoft = Color(0xFF3A576B); // İkincil metin
  static const Color cardWhite = Color(0xE6FFFFFF);
  // Boş hücre: keskin manzara üzerinde okunabilirlik için %65 opak
  // koyu gri-mavi (buzlu cam hissi; ince ışık konturuyla birlikte çalışır).
  static const Color cellEmpty = Color(0xA61E2B33);
  static const Color wheelDisc = Color(0xFFF4EDDD); // Krem rengi çark zemini
  static const Color wheelDiscEdge = Color(0xFFE9DCC0); // Çark dış kenar tonu
  static const Color wheelBorder = Color(0xFFE5D5BA); // Çark kenar rengi
  static const Color barButton = Color(0xFFFBF6EB); // Krem rengi buton arka planı
  static const Color barButtonBorder = Color(0xFFE9DCC4); // Krem buton kenar rengi
  static const Color barButtonHover = Color(0xFFF5EAD2);
  static const Color darkPill = Color(0xE61C2A33); // Seviye rozet/bilgi zemini
  static const Color glassDark = Color(0x731A2B38); // Koyu buzlu cam yüzey
  static const Color glassLine = Color(0x40FFFFFF); // Cam yüzey üst ışık konturu
}

/// Paylaşılan gradyanlar — altın yüzeylerin "ışıklı" derinlik hissi
/// tek kaynaktan gelir; buton, hücre ve kapsüller aynı dili konuşur.
abstract final class AppGradients {
  /// Altın buton/pill: üstten ışık alan parlak altın.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Basılı/vurgulu altın durumu (biraz daha koyu).
  static const LinearGradient goldPressed = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.gold, AppColors.goldDark],
  );

  /// Krem yüzey: hafif sıcak, üstte daha açık.
  static const LinearGradient cream = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEFBF3), Color(0xFFF3EAD6)],
  );

  /// Çark diski: merkezden kenara doğru hafif koyulaşan krem.
  static const RadialGradient wheel = RadialGradient(
    center: Alignment(-0.25, -0.35),
    radius: 1.1,
    colors: [Color(0xFFFDF8EC), AppColors.wheelDisc, AppColors.wheelDiscEdge],
    stops: [0.0, 0.62, 1.0],
  );
}

/// Katmanlı gölge takımları — düz tek gölge yerine yumuşak çift gölge
/// (yakın temas gölgesi + geniş ortam gölgesi) 2026 derinlik dili.
abstract final class AppShadows {
  /// Kartlar ve paneller.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x29102433), blurRadius: 22, offset: Offset(0, 10)),
  ];

  /// Yüzen küçük öğeler (buton, rozet, hücre).
  static const List<BoxShadow> chip = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x24102433), blurRadius: 10, offset: Offset(0, 4)),
  ];

  /// Altın öğelerin sıcak ışıması.
  static const List<BoxShadow> goldGlow = [
    BoxShadow(color: Color(0x59F5B62B), blurRadius: 18, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x33A86F08), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Basılı durum: gölge toplanır.
  static const List<BoxShadow> pressed = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// Köşe yarıçapı ölçeği — tutarlı yuvarlaklık dili.
abstract final class AppRadii {
  static const double s = 10;
  static const double m = 14;
  static const double l = 20;
  static const double xl = 28;
}

/// Başlıklarda kullanılan serif kimlik (ana ekran diliyle uyumlu).
/// PT Serif pakete gömülüdür: tam Kiril + palochka (Ӏ) kapsamı; eksik
/// glif olursa NotoSans devreye girer.
abstract final class AppText {
  static const String displayFamily = 'PTSerif';
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

/// Sistem "azaltılmış hareket" tercihini kontrol eden tek nokta.
/// `MediaQuery.disableAnimationsOf(context)` ile birlikte kullanılır;
/// animasyon yapan widget'lar bunu okuyup süreleri 0'a indirir.
abstract final class MotionSettings {
  /// Build context'ten: kullanıcı sistem ayarı olarak "azaltılmış hareket"
  /// isteyse true. Animasyon yapan widget'lar bu bayrakla süreleri 0'a çeker.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Animasyon süresini reduced modda 0 yapar, aksi normal süre.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSans',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold),
      scaffoldBackgroundColor: const Color(0xFFE4EFF5),
      splashFactory: InkSparkle.splashFactory,
    );

/// Okunabilirlik için yumuşak metin gölgesi.
const List<Shadow> kSoftTextShadow = [
  Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1.5)),
];

/// Açık zemin üzerindeki büyük başlıklar için çift katmanlı gölge.
const List<Shadow> kDisplayTextShadow = [
  Shadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
  Shadow(color: Color(0x4D102433), blurRadius: 14, offset: Offset(0, 4)),
];
