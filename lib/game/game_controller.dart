import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/scoring.dart';
import '../data/models.dart';
import '../data/progress_store.dart';

const _persistDebounce = Duration(milliseconds: 800);

/// Tek seferlik görsel efektleri tetikleyen oyun olayları.
sealed class GameEvent {}

class WrongWord extends GameEvent {}

class AlreadyFound extends GameEvent {}

class WordSolved extends GameEvent {
  WordSolved(this.word, {required this.byHint});
  final PlacedWord word;
  final bool byHint;
}

/// Izgarada olmayan ama geçerli olan bonus kelime bulundu.
class BonusWordFound extends GameEvent {
  BonusWordFound(this.word);
  final String word;
}

class CoinsGained extends GameEvent {
  CoinsGained(this.amount);
  final int amount;
}

class ComboBonus extends GameEvent {
  ComboBonus({required this.streak, required this.amount});
  final int streak;
  final int amount;
}

class HintRevealed extends GameEvent {
  HintRevealed(this.cell);
  final Cell cell;
}

class LevelCompleted extends GameEvent {}

/// Oyun durumu ve kuralları: seçim, doğrulama, ödül, ipucu, karıştırma.
class GameController extends ChangeNotifier {
  GameController({
    required this.levels,
    required this.store,
    Random? random,
    int startIndex = -1,
  }) : _random = random ?? Random() {
    // startIndex >= 0 ise galeriden gelen seçim, aksi store.levelIndex.
    _levelIndex = (startIndex >= 0
            ? startIndex
            : store.levelIndex % levels.length) %
        levels.length;
    _coins = store.coins;
    coinsListenable.value = _coins;
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
  int _streak = 0;
  int _bestStreak = 0;
  int _mistakes = 0;
  int _hintsUsed = 0;

  // Granular ValueNotifier'lar: UI'ın sadece ilgili alan değişiminde
  // rebuild olması için. Mevcut ChangeNotifier uyumluluğu korunur (yine
  // notifyListeners() tüm state'ler için çağrılıyor); bu notifier'lar
  // UI tarafında seçici dinleme için kullanılacak.
  final ValueNotifier<int> coinsListenable = ValueNotifier<int>(0);
  final ValueNotifier<int> streakListenable = ValueNotifier<int>(0);
  final ValueNotifier<List<int>> selectionListenable =
      ValueNotifier<List<int>>(const []);
  final ValueNotifier<PlacedWord?> lastSolvedListenable =
      ValueNotifier<PlacedWord?>(null);

  final Set<String> solvedWords = {};
  final Set<Cell> revealedCells = {};

  /// Bu seviyede bulunan bonus kelimeler (tekrar ödül verilmez).
  final Set<String> foundBonusWords = {};

  Timer? _persistTimer;

  /// Aktif seçim: `level.letters` indeksleri (çarktaki baloncuklar).
  final List<int> selection = [];

  /// Baloncukların çark üzerindeki yerleşim permütasyonu.
  late List<int> wheelOrder;

  /// Son çözülen kelime — ızgara yerleşme animasyonunun gecikme sırası için.
  PlacedWord? lastSolved;

  Level get level => levels[_levelIndex];
  int get levelNumber => level.id;
  int get coins => _coins;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;

  /// Bölüm sonu yıldız skoru: temiz oyun 3, az hata/ipucu 2, aksi 1.
  int get performanceStars =>
      Scoring.stars(mistakes: _mistakes, hintsUsed: _hintsUsed);

  // Aynı kelime ızgarada birden çok kez yer alabilir; solvedWords bir Set
  // olduğu için karşılaştırma benzersiz kelime sayısıyla yapılmalı.
  bool get levelDone => solvedWords.length == level.distinctWordCount;
  bool get isLastLevel => _levelIndex == levels.length - 1;
  String get currentWord => selection.map((i) => level.letters[i]).join();

  void _initLevel() {
    // Yeni seviyeye geçerken eski persist zamanlayıcısı beklemede olabilir;
    // iptal et ki eski seviyenin üzerine yazma veya yarış koşulu olmasın.
    _persistTimer?.cancel();
    _persistTimer = null;
    solvedWords.clear();
    revealedCells.clear();
    foundBonusWords.clear();
    selection.clear();
    lastSolved = null;
    _streak = 0;
    _bestStreak = 0;
    _mistakes = 0;
    _hintsUsed = 0;
    streakListenable.value = 0;
    selectionListenable.value = const [];
    lastSolvedListenable.value = null;
    wheelOrder = List.generate(level.letters.length, (i) => i);
    _restoreProgress();
  }

  /// Kayıtlı ara ilerlemeyi geri yükler (uygulama kapanıp açıldığında
  /// oyuncu kaldığı yerden devam eder). Seviye verisi değişmişse artık
  /// geçersiz olan kayıtlar elenir; olaylar tetiklenmez, coin verilmez.
  void _restoreProgress() {
    final validWords = {for (final w in level.words) w.word};
    for (final word in store.solvedWordsFor(level.id)) {
      if (validWords.contains(word)) solvedWords.add(word);
    }
    for (final cell in store.revealedCellsFor(level.id)) {
      if (level.targetByCell.containsKey(cell)) revealedCells.add(cell);
    }
    for (final word in store.bonusWordsFor(level.id)) {
      if (level.bonusWords.contains(word)) foundBonusWords.add(word);
    }
    // Beklenmedik durum (ör. seviye verisi küçülmüş): tamamlanmış görünen
    // kayıtla başlamak paneli kilitleyeceği için temiz başlanır.
    if (levelDone) {
      solvedWords.clear();
      revealedCells.clear();
      foundBonusWords.clear();
      unawaited(store.clearLevelProgress(level.id));
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _flushPersist);
  }

  void _flushPersist() {
    _persistTimer = null;
    unawaited(store.setSolvedWordsFor(level.id, solvedWords));
    unawaited(store.setRevealedCellsFor(level.id, revealedCells));
    unawaited(store.setBonusWordsFor(level.id, foundBonusWords));
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
  /// Seçim değiştiyse `true`, aksi halde `false` döner (UI ses/haptic için).
  bool enterBubble(int letterIndex) {
    if (levelDone) return false;
    assert(letterIndex >= 0 && letterIndex < level.letters.length);
    if (selection.isEmpty) {
      selection.add(letterIndex);
    } else if (selection.last == letterIndex) {
      return false;
    } else if (selection.length >= 2 &&
        selection[selection.length - 2] == letterIndex) {
      selection.removeLast();
    } else if (!selection.contains(letterIndex)) {
      selection.add(letterIndex);
    } else {
      return false;
    }
    selectionListenable.value = List<int>.unmodifiable(selection);
    notifyListeners();
    return true;
  }

  /// Parmak/imleç bırakıldığında seçimi değerlendirir.
  void releaseSelection() {
    if (selection.isEmpty) return;
    final count = selection.length;
    final word = currentWord;
    selection.clear();
    selectionListenable.value = const [];
    notifyListeners();
    if (count < 2) return;
    _submit(word);
  }

  void _submit(String word) {
    if (solvedWords.contains(word) || foundBonusWords.contains(word)) {
      // Tekrar girilen kelime hata sayılmaz — kullanıcı yanlış yapmadı,
      // sadece hatırlıyor. Görsel geri bildirim yeterli.
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
      if (level.bonusWords.contains(word)) {
        _foundBonus(word);
      } else {
        _registerMiss();
        _events.add(WrongWord());
      }
      return;
    }
    _solve(match, byHint: false);
  }

  /// Izgara dışı geçerli kelime: küçük sabit ödül, ızgara değişmez.
  void _foundBonus(String word) {
    foundBonusWords.add(word);
    _schedulePersist();
    final reward = Scoring.bonusWord();
    _coins += reward;
    coinsListenable.value = _coins;
    unawaited(store.setCoins(_coins));
    _events.add(BonusWordFound(word));
    _events.add(CoinsGained(reward));
    notifyListeners();
  }

  void _registerMiss() {
    _mistakes++;
    final changed = _streak != 0;
    _streak = 0;
    if (changed) {
      streakListenable.value = 0;
      notifyListeners();
    }
  }

  void _solve(PlacedWord word, {required bool byHint}) {
    solvedWords.add(word.word);
    lastSolved = word;
    lastSolvedListenable.value = word;
    if (byHint) {
      _streak = 0;
    } else {
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
    }
    streakListenable.value = _streak;
    final reward = Scoring.forWordSolve(word, byHint: byHint, newStreak: _streak);
    _events.add(WordSolved(word, byHint: byHint));
    if (reward.total > 0) {
      _coins += reward.total;
      coinsListenable.value = _coins;
      unawaited(store.setCoins(_coins));
      if (reward.comboGain > 0) {
        _events.add(ComboBonus(streak: _streak, amount: reward.comboGain));
      }
      _events.add(CoinsGained(reward.total));
    }
    notifyListeners();
    if (levelDone) {
      // Fire-and-forget: UI tarafı event'i dinler, persist yazımı sıralıdır.
      unawaited(_onLevelCompleted());
    } else {
      _schedulePersist();
    }
  }

  /// Seviye tamamlanma anı: bekleyen persist zamanlayıcısı varsa iptal et,
  /// son durumu sıralı (setSolved → setRevealed → setBonus → clear → setIndex)
  /// yaz ve `LevelCompleted` event'ini tetikle. Sıralama önemli: clearProgress
  /// setLevelIndex'ten önce olmalı, yoksa motor yarış durumu yaratabilir.
  Future<void> _onLevelCompleted() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      await store.setSolvedWordsFor(level.id, solvedWords);
      await store.setRevealedCellsFor(level.id, revealedCells);
      await store.setBonusWordsFor(level.id, foundBonusWords);
      // Galeri için yıldız performansını kaydet (sadece daha iyiyse günceller).
      await store.setStarsFor(level.id, performanceStars);
      await store.clearLevelProgress(level.id);
      await store.setLevelIndex((_levelIndex + 1) % levels.length);
      // Tüm zamanların en iyi serisini güncelle
      await store.setBestStreak(_bestStreak);
    } catch (e, st) {
      debugPrint('Seviye tamamlama yazması başarısız: $e\n$st');
    }
    // dispose() ile _events kapatılmış olabilir; kapalı controller'a add
    // exception atar, sadece hâlâ açıksa gönder.
    if (!_events.isClosed) {
      _events.add(LevelCompleted());
    }
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
      _coins >= Scoring.hintCost() &&
      _hintCandidates().isNotEmpty;

  /// Coin karşılığı rastgele bir hücreyi açar; ipucuyla tamamen dolan
  /// kelimeler çözülmüş sayılır (ek coin ödülü verilmez).
  void useHint() {
    if (!canHint) return;
    final candidates = _hintCandidates();
    final cell = candidates[_random.nextInt(candidates.length)];
    revealedCells.add(cell);
    _hintsUsed++;
    _streak = 0;
    streakListenable.value = 0;
    _coins -= Scoring.hintCost();
    coinsListenable.value = _coins;
    unawaited(store.setCoins(_coins));
    _events.add(HintRevealed(cell));
    for (final word in level.words) {
      if (!solvedWords.contains(word.word) && word.cells.every(cellFilled)) {
        _solve(word, byHint: true);
      }
    }
    if (!levelDone) _schedulePersist();
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
    // Kapanışta bekleyen persist varsa yaz — uygulama GC'lenirken veri kaybı
    // olmasın. Async setXxx zaten fire-and-forget, dispose sonrası motorun
    // dispose'ı bekleyebilir.
    if (_persistTimer != null) {
      _persistTimer!.cancel();
      _flushPersist();
    }
    coinsListenable.dispose();
    streakListenable.dispose();
    selectionListenable.dispose();
    lastSolvedListenable.dispose();
    _events.close();
    super.dispose();
  }
}
