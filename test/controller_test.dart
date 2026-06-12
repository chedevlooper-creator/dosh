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

Level _levelWithBonus() => Level(
      // да tek ızgara kelimesi, 'ад' bonus: letters=['д','а'] ile kurulabilir.
      id: 3,
      letters: ['д', 'а'],
      words: [
        PlacedWord(word: 'да', row: 0, col: 0, direction: WordDirection.across),
      ],
      bonusWords: ['ад'],
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
    // _onLevelCompleted async fire-and-forget; event sıralı yazma sonrası gelir.
    for (var i = 0; i < 5; i++) {
      await Future.delayed(Duration.zero);
    }
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
    // _onLevelCompleted async fire-and-forget; event sıralı yazma sonrası gelir.
    for (var i = 0; i < 5; i++) {
      await Future.delayed(Duration.zero);
    }
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

  test(
      'seviye tamamlanınca persist timer iptal edilir ve veriler anında yazılır',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();
    // Tek seviyeli listede (_levelIndex+1) % 1 = 0 olur; 2 seviyeli setle
    // levelIndex'in gerçekten değiştiğini doğrulayabiliriz.
    final game = GameController(
      levels: [
        _daLevel(),
        Level(
          id: 99,
          letters: ['а', 'б'],
          words: [
            PlacedWord(
                word: 'аб', row: 0, col: 0, direction: WordDirection.across),
          ],
        ),
      ],
      store: store,
    );
    final events = <GameEvent>[];
    game.events.listen(events.add);

    // İpucu: bu solvedWords/coins'i günceller ve _schedulePersist çağırır.
    // 800ms debounce var — biz hemen seviyeyi bitiriyoruz.
    game.useHint();
    game.useHint(); // ikinci ipucu → "да" tamamen dolar → seviye biter

    expect(game.levelDone, isTrue);

    // _onLevelCompleted async fire-and-forget tetiklendi. SharedPreferences
    // mock'u microtask olarak çalışır; birden fazla event loop turu bekle.
    for (var i = 0; i < 10; i++) {
      await Future.delayed(Duration.zero);
    }

    expect(events.whereType<LevelCompleted>(), hasLength(1));

    // Store'da: hücreler temizlendi, levelIndex ilerledi.
    expect(store.solvedWordsFor(_daLevel().id), isEmpty,
        reason: 'clearLevelProgress çağrılmalı');
    expect(store.revealedCellsFor(_daLevel().id), isEmpty,
        reason: 'clearLevelProgress çağrılmalı');
    expect(store.levelIndex, 1, reason: 'seviye ilerletilmeli');

    // Dispose'da da flush beklemeden veriler yazılmış olmalı.
    game.dispose();
  });

  test('nextLevel timer iptal eder — stale write riskini kapatır', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();

    // İki seviyeli yap: birinci bitince ikinciye geçer.
    final level1 = _daLevel();
    final level2 = Level(
      id: 99,
      letters: ['а', 'б'],
      words: [PlacedWord(word: 'аб', row: 0, col: 0, direction: WordDirection.across)],
    );
    final game = GameController(levels: [level1, level2], store: store);

    // Seviye 1'i bitir, hemen nextLevel çağır (timer henüz ateşlenmeden).
    game.useHint();
    game.useHint();
    expect(game.levelDone, isTrue);
    game.nextLevel();
    // nextLevel sırasında timer iptal edildi, level1 verileri yazılmamalı
    // (seviye zaten bitti, clearLevelProgress çağrıldı).
    await Future.delayed(Duration.zero);

    // Şu an seviye 2'deyiz, henüz çözüm yok.
    expect(game.level, level2);
    expect(game.solvedWords, isEmpty);

    // Dispose ile kapat — herhangi bir stale write olmamalı.
    game.dispose();
  });

  test('bonus kelime çözünce bonus event tetiklenir, success değil', () async {
    // _levelWithBonus: letters=[д,а], words=[да], bonusWords=[ад].
    // "ад" geçerli: теkerin harfleri çark sırasıyla d, a → "да" kuruluyor;
    // oyuncu a, d sırasıyla girmeli → "ад".
    final game = await _newGame(_levelWithBonus());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    game.enterBubble(1); // а
    game.enterBubble(0); // д → "ад"
    game.releaseSelection();

    // Bonus event tetiklendi, success değil.
    expect(events.whereType<BonusWordFound>(), hasLength(1));
    expect(events.whereType<WordSolved>(), isEmpty,
        reason: 'bonus ızgara dışı, success animasyonu tetiklenmemeli');
    expect(game.foundBonusWords, contains('ад'));

    // Bonus coin ödülü verildi.
    expect(events.whereType<CoinsGained>(), hasLength(1));
    expect(game.coins,
        GameConfig.startCoins + GameConfig.bonusWordCoins);

    game.dispose();
  });

  test(
      'bonus sonra grid kelime çözünce success tetiklenir, bonus iptal olmaz',
      () async {
    final game = await _newGame(_levelWithBonus());
    final events = <GameEvent>[];
    game.events.listen(events.add);

    // Önce bonus bul
    game.enterBubble(1); // а
    game.enterBubble(0); // д
    game.releaseSelection();
    expect(events.whereType<BonusWordFound>(), hasLength(1));

    // Şimdi asıl ızgara kelimesini çöz → success animasyonu tetiklenir.
    game.enterBubble(0); // д
    game.enterBubble(1); // а
    game.releaseSelection();

    // _onLevelCompleted async; event loop'un boşalmasını bekle.
    for (var i = 0; i < 10; i++) {
      await Future.delayed(Duration.zero);
    }

    // Bonus + WordSolved + CoinsGained (bonus + grid coin)
    expect(events.whereType<BonusWordFound>(), hasLength(1));
    expect(events.whereType<WordSolved>(), hasLength(1));
    // İlk bonus 10 + grid 2×5 = 10+10 = 20 coin
    expect(game.coins, GameConfig.startCoins + GameConfig.bonusWordCoins +
        2 * GameConfig.coinsPerGrapheme);

    game.dispose();
  });

  test('granular notifier: streakListenable sadece streak değişince tetiklenir',
      () async {
    final game = await _newGame(_malxLevel());
    var streakNotifications = 0;
    game.streakListenable.addListener(() => streakNotifications++);

    // Yanlış kelime → streak 1'den 0'a düşer.
    _submitByIndexes(game, [0, 1, 2, 3]); // малх, streak 1
    expect(streakNotifications, 1, reason: 'streak 0→1');
    _submitByIndexes(game, [2, 0]); // yanlış
    expect(streakNotifications, 2, reason: 'streak 1→0');

    game.dispose();
  });

  test(
      'granular notifier: coinsListenable sadece coin değişince tetiklenir',
      () async {
    final game = await _newGame(_malxLevel());
    var coinNotifications = 0;
    game.coinsListenable.addListener(() => coinNotifications++);

    // Doğru kelime çöz → coin değişimi olmalı.
    _submitByIndexes(game, [0, 1, 2, 3]);
    expect(coinNotifications, greaterThan(0));
    final before = coinNotifications;

    // Karıştırma coin etkilemez.
    game.shuffle();
    expect(coinNotifications, before, reason: 'shuffle coin değiştirmez');

    game.dispose();
  });

  test(
      'granular notifier: selectionListenable her baloncuk değişiminde tetiklenir',
      () async {
    final game = await _newGame(_malxLevel());
    var notifications = 0;
    game.selectionListenable.addListener(() => notifications++);

    expect(game.enterBubble(0), isTrue, reason: 'ilk seçim değişiklik');
    expect(notifications, 1);
    expect(game.enterBubble(1), isTrue);
    expect(notifications, 2);
    expect(game.enterBubble(1), isFalse,
        reason: 'aynı baloncuğa tekrar = değişiklik yok');
    expect(notifications, 2);
    expect(game.enterBubble(0), isTrue, reason: 'geri kayma (undo)');
    expect(notifications, 3);

    game.dispose();
  });

  test('AlreadyFound tekrarı mistakes sayacını artırmaz', () async {
    final game = await _newGame(_malxLevel());
    final before = game.mistakes;

    // İlk kez çöz
    _submitByIndexes(game, [0, 1, 2, 3]);
    expect(game.solvedWords, contains('малх'));

    final mistakesAfterSolve = game.mistakes;
    // Aynı kelimeyi tekrar dene
    _submitByIndexes(game, [0, 1, 2, 3]);
    expect(game.mistakes, mistakesAfterSolve,
        reason: 'AlreadyFound hata sayılmamalı');
    expect(game.mistakes, before, reason: 'hiç hata olmamalı');

    game.dispose();
  });
}
