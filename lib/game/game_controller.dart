import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/models.dart';
import '../data/progress_store.dart';

/// Tek seferlik görsel efektleri tetikleyen oyun olayları.
sealed class GameEvent {}

class WrongWord extends GameEvent {}

class AlreadyFound extends GameEvent {}

class WordSolved extends GameEvent {
  WordSolved(this.word, {required this.byHint});
  final PlacedWord word;
  final bool byHint;
}

class CoinsGained extends GameEvent {
  CoinsGained(this.amount);
  final int amount;
}

class HintRevealed extends GameEvent {
  HintRevealed(this.cell);
  final Cell cell;
}

class LevelCompleted extends GameEvent {}

/// Oyun durumu ve kuralları: seçim, doğrulama, ödül, ipucu, karıştırma.
class GameController extends ChangeNotifier {
  GameController({required this.levels, required this.store, Random? random})
      : _random = random ?? Random() {
    _levelIndex = store.levelIndex % levels.length;
    _coins = store.coins;
    _initLevel();
  }

  final List<Level> levels;
  final ProgressStore store;
  final Random _random;

  // Senkron yayın: olaylar aynı çağrı zinciri içinde işlenir, animasyon
  // tetikleyicileri build sırasına göre deterministik kalır.
  final _events = StreamController<GameEvent>.broadcast(sync: true);
  Stream<GameEvent> get events => _events.stream;

  late int _levelIndex;
  int _coins = 0;

  final Set<String> solvedWords = {};
  final Set<Cell> revealedCells = {};

  /// Aktif seçim: `level.letters` indeksleri (çarktaki baloncuklar).
  final List<int> selection = [];

  /// Baloncukların çark üzerindeki yerleşim permütasyonu.
  late List<int> wheelOrder;

  /// Son çözülen kelime — ızgara yerleşme animasyonunun gecikme sırası için.
  PlacedWord? lastSolved;

  Level get level => levels[_levelIndex];
  int get levelNumber => level.id;
  int get coins => _coins;
  bool get levelDone => solvedWords.length == level.words.length;
  String get currentWord => selection.map((i) => level.letters[i]).join();

  void _initLevel() {
    solvedWords.clear();
    revealedCells.clear();
    selection.clear();
    lastSolved = null;
    wheelOrder = List.generate(level.letters.length, (i) => i);
  }

  /// Hücre dolu mu: ipucuyla açılmış ya da çözülen bir kelimenin parçası.
  bool cellFilled(Cell cell) {
    if (revealedCells.contains(cell)) return true;
    for (final word in level.words) {
      if (solvedWords.contains(word.word) && word.cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  /// Parmak/imleç bir baloncuğun üzerine geldiğinde.
  /// Sondan bir önceki baloncuğa geri dönüş son seçimi geri alır.
  void enterBubble(int letterIndex) {
    if (levelDone) return;
    assert(letterIndex >= 0 && letterIndex < level.letters.length);
    if (selection.isEmpty) {
      selection.add(letterIndex);
      notifyListeners();
      return;
    }
    if (selection.last == letterIndex) return;
    if (selection.length >= 2 &&
        selection[selection.length - 2] == letterIndex) {
      selection.removeLast();
      notifyListeners();
      return;
    }
    if (!selection.contains(letterIndex)) {
      selection.add(letterIndex);
      notifyListeners();
    }
  }

  /// Parmak/imleç bırakıldığında seçimi değerlendirir.
  void releaseSelection() {
    if (selection.isEmpty) return;
    final count = selection.length;
    final word = currentWord;
    selection.clear();
    notifyListeners();
    if (count < 2) return;
    _submit(word);
  }

  void _submit(String word) {
    if (solvedWords.contains(word)) {
      _events.add(AlreadyFound());
      return;
    }
    PlacedWord? match;
    for (final candidate in level.words) {
      if (candidate.word == word) {
        match = candidate;
        break;
      }
    }
    if (match == null) {
      _events.add(WrongWord());
      return;
    }
    _solve(match, byHint: false);
  }

  void _solve(PlacedWord word, {required bool byHint}) {
    solvedWords.add(word.word);
    lastSolved = word;
    _events.add(WordSolved(word, byHint: byHint));
    if (!byHint) {
      final gain = word.graphemes.length * GameConfig.coinsPerGrapheme;
      _coins += gain;
      unawaited(store.setCoins(_coins));
      _events.add(CoinsGained(gain));
    }
    notifyListeners();
    if (levelDone) _events.add(LevelCompleted());
  }

  List<Cell> _hintCandidates() {
    final cells = <Cell>{};
    for (final word in level.words) {
      if (solvedWords.contains(word.word)) continue;
      for (final cell in word.cells) {
        if (!cellFilled(cell)) cells.add(cell);
      }
    }
    return cells.toList();
  }

  bool get canHint =>
      !levelDone &&
      _coins >= GameConfig.hintCost &&
      _hintCandidates().isNotEmpty;

  /// Coin karşılığı rastgele bir hücreyi açar; ipucuyla tamamen dolan
  /// kelimeler çözülmüş sayılır (ek coin ödülü verilmez).
  void useHint() {
    if (!canHint) return;
    final candidates = _hintCandidates();
    final cell = candidates[_random.nextInt(candidates.length)];
    revealedCells.add(cell);
    _coins -= GameConfig.hintCost;
    unawaited(store.setCoins(_coins));
    _events.add(HintRevealed(cell));
    for (final word in level.words) {
      if (!solvedWords.contains(word.word) && word.cells.every(cellFilled)) {
        _solve(word, byHint: true);
      }
    }
    notifyListeners();
  }

  void shuffle() {
    if (level.letters.length < 2) return;
    // Yeni liste: widget tarafı eski/yeni sırayı karşılaştırıp animasyon
    // başlatabilsin diye yerinde karıştırma yapılmaz.
    final next = List<int>.from(wheelOrder);
    do {
      next.shuffle(_random);
    } while (listEquals(next, wheelOrder));
    wheelOrder = next;
    notifyListeners();
  }

  void nextLevel() {
    _levelIndex = (_levelIndex + 1) % levels.length;
    unawaited(store.setLevelIndex(_levelIndex));
    _initLevel();
    notifyListeners();
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
