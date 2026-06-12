import 'package:dosh/core/constants.dart';
import 'package:dosh/core/scoring.dart';
import 'package:dosh/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scoring.forWordSolve', () {
    PlacedWord make(String word) => PlacedWord(
          word: word,
          row: 0,
          col: 0,
          direction: WordDirection.across,
        );

    test('ipucuyla çözüm ödül getirmez', () {
      final reward =
          Scoring.forWordSolve(make('дош'), byHint: true, newStreak: 1);
      expect(reward.coinGain, 0);
      expect(reward.comboGain, 0);
      expect(reward.total, 0);
    });

    test('her grafem için sabit coin kazancı', () {
      final reward =
          Scoring.forWordSolve(make('дош'), byHint: false, newStreak: 1);
      expect(reward.coinGain, 3 * GameConfig.coinsPerGrapheme);
      expect(reward.comboGain, 0);
    });

    test('seri milestone olduğunda kombo bonusu eklenir', () {
      final reward =
          Scoring.forWordSolve(make('дош'), byHint: false, newStreak: 3);
      expect(reward.coinGain, 3 * GameConfig.coinsPerGrapheme);
      expect(reward.comboGain, GameConfig.comboBonusCoins);
    });

    test('milestone dışındaki serilerde kombo yok', () {
      final reward =
          Scoring.forWordSolve(make('дош'), byHint: false, newStreak: 4);
      expect(reward.comboGain, 0);
    });
  });

  group('Scoring.stars', () {
    test('temiz oyun 3 yıldız', () {
      expect(Scoring.stars(mistakes: 0, hintsUsed: 0), 3);
    });

    test('az hata ve ipucu 2 yıldız', () {
      expect(Scoring.stars(mistakes: 2, hintsUsed: 1), 2);
      expect(Scoring.stars(mistakes: 1, hintsUsed: 0), 2);
    });

    test('diğer durumlar 1 yıldız', () {
      expect(Scoring.stars(mistakes: 3, hintsUsed: 0), 1);
      expect(Scoring.stars(mistakes: 0, hintsUsed: 2), 1);
    });
  });

  test('Scoring.hintCost oyun sabitine eşittir', () {
    expect(Scoring.hintCost(), GameConfig.hintCost);
  });

  test('Scoring.bonusWord oyun sabitine eşittir', () {
    expect(Scoring.bonusWord(), GameConfig.bonusWordCoins);
  });
}
