/// Oyun ekonomisi ve genel düzen sabitleri.
abstract final class GameConfig {
  static const int startCoins = 100;
  static const int hintCost = 25;
  static const int coinsPerGrapheme = 5;

  /// Geniş ekranlarda (Windows/tablet) oyun kolonunun maksimum genişliği.
  static const double maxContentWidth = 520;
}
