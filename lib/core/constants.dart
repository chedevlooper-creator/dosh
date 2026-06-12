/// Oyun ekonomisi ve genel düzen sabitleri.
abstract final class GameConfig {
  static const int startCoins = 100;
  static const int hintCost = 25;
  static const int coinsPerGrapheme = 5;

  /// Izgarada olmayan ama geçerli olan bonus kelimenin sabit ödülü.
  static const int bonusWordCoins = 10;

  /// Arka arkaya doğru çözümlerde verilen kombo ödülü.
  static const int comboMilestone = 3;
  static const int comboBonusCoins = 15;

  /// Ana ekrandaki hazine sandığından günde bir kez alınan hediye.
  static const int dailyGiftCoins = 100;

  /// Günlük challenge tamamlandığında kazanılan bonus coin.
  static const int dailyChallengeBonus = 75;

  /// Geniş ekranlarda (Windows/tablet) oyun kolonunun maksimum genişliği.
  static const double maxContentWidth = 520;
}
