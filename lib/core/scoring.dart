import '../data/models.dart';
import 'constants.dart';

/// Bir kelime çözümünün ödülünü temsil eder.
class SolveReward {
  const SolveReward({required this.coinGain, required this.comboGain});
  final int coinGain;
  final int comboGain;
  int get total => coinGain + comboGain;

  const SolveReward.empty()
      : coinGain = 0,
        comboGain = 0;
}

/// Oyun puanlama kurallarını yalıtılmış, test edilebilir saf fonksiyonlar
/// olarak sunan use case. GameController sahiplik/olay mantığını yürütür;
/// bu sınıf yalnızca "şu girdiyle şu ödül çıkar" sorusuna cevap verir.
abstract final class Scoring {
  /// Bir kelime çözüldüğünde/çözüldüğündeki ödülü hesaplar.
  /// `newStreak` ipucu kullanılmadıysa geçerli güncel seri sayısıdır.
  static SolveReward forWordSolve(
    PlacedWord word, {
    required bool byHint,
    required int newStreak,
  }) {
    if (byHint) return const SolveReward.empty();
    final coinGain = word.graphemes.length * GameConfig.coinsPerGrapheme;
    final comboGain = newStreak % GameConfig.comboMilestone == 0
        ? GameConfig.comboBonusCoins
        : 0;
    return SolveReward(coinGain: coinGain, comboGain: comboGain);
  }

  /// İpucu kullanımının coin maliyeti.
  static int hintCost() => GameConfig.hintCost;

  /// Izgara dışı geçerli bonus kelime ödülü.
  static int bonusWord() => GameConfig.bonusWordCoins;

  /// Temiz oyun 3⭐, az hata/ipucu 2⭐, aksi 1⭐.
  static int stars({required int mistakes, required int hintsUsed}) {
    if (mistakes == 0 && hintsUsed == 0) return 3;
    if (mistakes <= 2 && hintsUsed <= 1) return 2;
    return 1;
  }
}
