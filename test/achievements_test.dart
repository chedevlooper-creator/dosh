import 'package:dosh/core/achievements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const def = AchievementDef(id: 'words', bronze: 10, silver: 50, gold: 150);

  group('Achievements.tierFor', () {
    test('eşik altında none döner', () {
      expect(Achievements.tierFor(def, 0), AchievementTier.none);
      expect(Achievements.tierFor(def, 9), AchievementTier.none);
    });

    test('bronz eşiğinde ve üstünde bronze döner', () {
      expect(Achievements.tierFor(def, 10), AchievementTier.bronze);
      expect(Achievements.tierFor(def, 49), AchievementTier.bronze);
    });

    test('gümüş eşiğinde ve üstünde silver döner', () {
      expect(Achievements.tierFor(def, 50), AchievementTier.silver);
      expect(Achievements.tierFor(def, 149), AchievementTier.silver);
    });

    test('altın eşiğinde ve üstünde gold döner', () {
      expect(Achievements.tierFor(def, 150), AchievementTier.gold);
      expect(Achievements.tierFor(def, 10000), AchievementTier.gold);
    });
  });

  group('AchievementProgress.progressToNext', () {
    test('none kademesinde bronza olan ilerleme oranı', () {
      final p = Achievements.progressFor(def, 5);
      expect(p.tier, AchievementTier.none);
      expect(p.nextThreshold, 10);
      expect(p.progressToNext, closeTo(0.5, 0.001));
    });

    test('bronz kademesinde gümüşe olan ilerleme oranı', () {
      final p = Achievements.progressFor(def, 30);
      expect(p.tier, AchievementTier.bronze);
      expect(p.nextThreshold, 50);
      // (30-10)/(50-10) = 0.5
      expect(p.progressToNext, closeTo(0.5, 0.001));
    });

    test('altın kademede nextThreshold null ve ilerleme 1.0', () {
      final p = Achievements.progressFor(def, 200);
      expect(p.tier, AchievementTier.gold);
      expect(p.nextThreshold, isNull);
      expect(p.progressToNext, 1.0);
      expect(p.isMaxed, isTrue);
    });
  });

  group('AchievementDef.isSingleTier', () {
    test('üç eşik de eşitse tek seferlik başarımdır', () {
      const single = AchievementDef(id: 'tutorial', bronze: 1, silver: 1, gold: 1);
      expect(single.isSingleTier, isTrue);
      expect(def.isSingleTier, isFalse);
    });
  });

  group('Achievements.unlockedCount', () {
    test('sadece none olmayan kademeleri sayar', () {
      final list = [
        Achievements.progressFor(def, 0),
        Achievements.progressFor(def, 10),
        Achievements.progressFor(def, 200),
      ];
      expect(Achievements.unlockedCount(list), 2);
    });
  });
}
