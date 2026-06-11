import 'package:dosh/core/constants.dart';
import 'package:dosh/data/models.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:dosh/game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Level _malxLevel() => Level(
      id: 1,
      letters: ['м', 'а', 'л', 'х'],
      words: [
        PlacedWord(
            word: 'малх', row: 0, col: 0, direction: WordDirection.across),
        PlacedWord(word: 'лам', row: 0, col: 2, direction: WordDirection.down),
        PlacedWord(
            word: 'мах', row: 2, col: 2, direction: WordDirection.across),
      ],
    );

Level _daLevel() => Level(
      id: 2,
      letters: ['д', 'а'],
      words: [
        PlacedWord(word: 'да', row: 0, col: 0, direction: WordDirection.across),
      ],
    );

Future<GameController> _newGame(Level level) async {
  SharedPreferences.setMockInitialValues({});
  final store = await ProgressStore.create();
  return GameController(levels: [level], store: store);
}

void _submitByIndexes(GameController game, List<int> indexes) {
  for (final index in indexes) {
    game.enterBubble(index);
  }
  game.releaseSelection();
}

void main() {
  test('doğru kelime çözülür ve coin kazandırır', () async {
    final game = await _newGame(_malxLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    game.enterBubble(0); // м
    game.enterBubble(1); // а
    game.enterBubble(2); // л
    game.enterBubble(3); // х
    expect(game.currentWord, 'малх');
    game.releaseSelection();

    expect(game.solvedWords, contains('малх'));
    expect(
      game.coins,
      GameConfig.startCoins + 4 * GameConfig.coinsPerGrapheme,
    );
    expect(events.whereType<WordSolved>(), hasLength(1));
    expect(events.whereType<CoinsGained>(), hasLength(1));
    expect(game.selection, isEmpty);
  });

  test('yanlış kelime WrongWord üretir, coin değişmez', () async {
    final game = await _newGame(_malxLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    game.enterBubble(2); // л
    game.enterBubble(0); // м
    game.releaseSelection();

    expect(game.solvedWords, isEmpty);
    expect(game.coins, GameConfig.startCoins);
    expect(events.whereType<WrongWord>(), hasLength(1));
  });

  test('üçlü seri kombo bonusu verir', () async {
    final game = await _newGame(_malxLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    _submitByIndexes(game, [0, 1, 2, 3]); // малх
    expect(game.streak, 1);
    _submitByIndexes(game, [2, 1, 0]); // лам
    expect(game.streak, 2);
    _submitByIndexes(game, [0, 1, 3]); // мах

    expect(game.streak, 3);
    expect(game.bestStreak, 3);
    expect(game.performanceStars, 3);
    expect(
      game.coins,
      GameConfig.startCoins +
          10 * GameConfig.coinsPerGrapheme +
          GameConfig.comboBonusCoins,
    );

    final comboEvents = events.whereType<ComboBonus>().toList();
    expect(comboEvents, hasLength(1));
    expect(comboEvents.single.streak, 3);
    expect(comboEvents.single.amount, GameConfig.comboBonusCoins);
  });

  test('yanlış kelime seriyi kırar ve yıldız skorunu düşürür', () async {
    final game = await _newGame(_malxLevel());

    _submitByIndexes(game, [0, 1, 2, 3]); // малх
    expect(game.streak, 1);

    _submitByIndexes(game, [2, 0]); // yanlış

    expect(game.streak, 0);
    expect(game.mistakes, 1);
    expect(game.performanceStars, 2);
  });

  test('önceki baloncuğa geri kayma son seçimi geri alır', () async {
    final game = await _newGame(_malxLevel());

    game.enterBubble(0);
    game.enterBubble(1);
    game.enterBubble(0); // geri kayma

    expect(game.selection, [0]);
  });

  test('çözülmüş kelime tekrar girilirse AlreadyFound', () async {
    final game = await _newGame(_malxLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    for (final i in [0, 1, 2, 3]) {
      game.enterBubble(i);
    }
    game.releaseSelection();
    final coinsAfterSolve = game.coins;

    for (final i in [0, 1, 2, 3]) {
      game.enterBubble(i);
    }
    game.releaseSelection();

    expect(events.whereType<AlreadyFound>(), hasLength(1));
    expect(game.coins, coinsAfterSolve);
  });

  test('ipucu coin düşürür ve bir hücre açar', () async {
    final game = await _newGame(_malxLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    expect(game.canHint, isTrue);
    game.useHint();

    expect(game.coins, GameConfig.startCoins - GameConfig.hintCost);
    expect(game.revealedCells, hasLength(1));
    expect(events.whereType<HintRevealed>(), hasLength(1));
  });

  test('ipucuyla tamamen dolan kelime çözülür ve seviye biter', () async {
    final game = await _newGame(_daLevel());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    game.useHint();
    game.useHint();

    expect(game.solvedWords, contains('да'));
    expect(game.levelDone, isTrue);
    expect(events.whereType<LevelCompleted>(), hasLength(1));
    // İpucuyla çözümde coin ödülü verilmez: 100 - 2×25
    expect(game.coins, GameConfig.startCoins - 2 * GameConfig.hintCost);
  });

  test('karıştırma harf kümesini korur, sırayı değiştirir', () async {
    final game = await _newGame(_malxLevel());
    final before = List<int>.from(game.wheelOrder);

    game.shuffle();

    expect(game.wheelOrder, isNot(orderedEquals(before)));
    expect(List<int>.from(game.wheelOrder)..sort(), [0, 1, 2, 3]);
  });

  test('ızgarada tekrar eden kelimeyle seviye tamamlanabilir', () async {
    // дош iki kez yerleşmiş: çözülünce iki yerleşim de dolar ve seviye
    // benzersiz kelime sayısı (2) üzerinden tamamlanır.
    final level = Level(
      id: 9,
      letters: ['д', 'о', 'ш', 'о'],
      words: [
        PlacedWord(
            word: 'дош', row: 0, col: 0, direction: WordDirection.across),
        PlacedWord(
            word: 'дош', row: 2, col: 0, direction: WordDirection.across),
        PlacedWord(word: 'до', row: 0, col: 0, direction: WordDirection.down),
      ],
    );
    final game = await _newGame(level);
    final events = <GameEvent>[];
    game.events.listen(events.add);

    expect(level.distinctWordCount, 2);

    game.enterBubble(0); // д
    game.enterBubble(1); // о
    game.enterBubble(2); // ш
    game.releaseSelection();

    // İkinci дош yerleşimi de otomatik dolu sayılır.
    expect(game.cellFilled(const Cell(2, 0)), isTrue);
    expect(game.levelDone, isFalse);

    game.enterBubble(0); // д
    game.enterBubble(1); // о
    game.releaseSelection();

    expect(game.levelDone, isTrue);
    expect(events.whereType<LevelCompleted>(), hasLength(1));
  });

  test('nextLevel durumu sıfırlar', () async {
    final game = await _newGame(_daLevel());
    game.useHint();
    game.useHint();
    expect(game.levelDone, isTrue);

    // Store işlemlerinin tamamlanması için bekle
    await Future.delayed(Duration.zero);
    game.nextLevel(); // tek seviyeli listede başa sarar

    expect(game.solvedWords, isEmpty);
    expect(game.revealedCells, isEmpty);
    expect(game.levelDone, isFalse);
  });
}
