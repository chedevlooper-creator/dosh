/// Başarım (rozet) sistemi — UI'dan bağımsız, saf hesaplama.
///
/// Her başarım üç kademeli (bronz/gümüş/altın) bir eşik dizisine sahiptir;
/// tek seferlik başarımlar (ör. öğreticiyi bitirme) üç eşiği de aynı
/// değere ayarlayarak "tamamlandı/tamamlanmadı" biçiminde kullanılabilir.
library;

enum AchievementTier { none, bronze, silver, gold }

/// Bir başarımın sabit tanımı: kimlik + üç kademe eşiği.
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.bronze,
    required this.silver,
    required this.gold,
  });

  final String id;
  final int bronze;
  final int silver;
  final int gold;

  /// Bronz/gümüş/altın eşikleri aynıysa tek seferlik (binary) başarımdır.
  bool get isSingleTier => bronze == gold;
}

/// Bir başarımın oyuncunun mevcut verisine göre hesaplanmış durumu.
class AchievementProgress {
  const AchievementProgress({
    required this.def,
    required this.value,
    required this.tier,
  });

  final AchievementDef def;
  final int value;
  final AchievementTier tier;

  bool get isMaxed => tier == AchievementTier.gold;

  int? get nextThreshold {
    switch (tier) {
      case AchievementTier.none:
        return def.bronze;
      case AchievementTier.bronze:
        return def.silver;
      case AchievementTier.silver:
        return def.gold;
      case AchievementTier.gold:
        return null;
    }
  }

  int get _prevThreshold {
    switch (tier) {
      case AchievementTier.none:
        return 0;
      case AchievementTier.bronze:
        return def.bronze;
      case AchievementTier.silver:
        return def.silver;
      case AchievementTier.gold:
        return def.gold;
    }
  }

  /// 0.0-1.0 arası: bir sonraki kademeye ne kadar yaklaşıldığı.
  /// Zaten altın kademedeyse 1.0 döner.
  double get progressToNext {
    final next = nextThreshold;
    if (next == null) return 1.0;
    final span = next - _prevThreshold;
    if (span <= 0) return 1.0;
    return ((value - _prevThreshold) / span).clamp(0.0, 1.0);
  }
}

abstract final class Achievements {
  static const List<AchievementDef> defs = [
    AchievementDef(id: 'words', bronze: 10, silver: 50, gold: 150),
    AchievementDef(id: 'bonus', bronze: 5, silver: 25, gold: 75),
    AchievementDef(id: 'coins', bronze: 200, silver: 1000, gold: 5000),
    AchievementDef(id: 'streak', bronze: 3, silver: 6, gold: 10),
    AchievementDef(id: 'levels', bronze: 5, silver: 20, gold: 50),
    AchievementDef(id: 'perfect', bronze: 5, silver: 20, gold: 40),
    AchievementDef(id: 'timeAttack', bronze: 50, silver: 150, gold: 300),
    AchievementDef(id: 'tutorial', bronze: 1, silver: 1, gold: 1),
  ];

  static AchievementTier tierFor(AchievementDef def, int value) {
    if (value >= def.gold) return AchievementTier.gold;
    if (value >= def.silver) return AchievementTier.silver;
    if (value >= def.bronze) return AchievementTier.bronze;
    return AchievementTier.none;
  }

  static AchievementProgress progressFor(AchievementDef def, int value) =>
      AchievementProgress(def: def, value: value, tier: tierFor(def, value));

  /// Kaç başarım en az bronz kademeye ulaşmış (özet sayaç için).
  static int unlockedCount(Iterable<AchievementProgress> all) =>
      all.where((p) => p.tier != AchievementTier.none).length;
}
