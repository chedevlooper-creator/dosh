import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'models.dart';

/// Coin ve seviye ilerlemesinin kalıcı saklanması (tüm platformlarda çalışır).
///
/// Bölüm içi ilerleme (çözülen kelimeler, açılan ipucu hücreleri, bulunan
/// bonus kelimeler) seviye kimliğine göre saklanır; böylece uygulama
/// kapatılıp açıldığında oyuncu kaldığı yerden devam eder.
class ProgressStore {
  ProgressStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kCoins = 'coins';
  static const _kLevelIndex = 'level_index';
  static const _kSoundOn = 'sound_on';
  static const _kGiftDay = 'gift_day';
  static const _kWordsPrefix = 'level_words_';
  static const _kCellsPrefix = 'level_cells_';
  static const _kBonusPrefix = 'level_bonus_';
  static const _kStarsPrefix = 'level_stars_';
  static const _kTutorialDone = 'tutorial_done';
  static const _kThemeIndex = 'theme_index';

  static Future<ProgressStore> create() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  int get coins => _prefs.getInt(_kCoins) ?? GameConfig.startCoins;
  int get levelIndex => _prefs.getInt(_kLevelIndex) ?? 0;
  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;

  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);
  Future<void> setLevelIndex(int value) => _prefs.setInt(_kLevelIndex, value);
  Future<void> setSoundOn(bool value) => _prefs.setBool(_kSoundOn, value);

  // --- Seviye yıldızları (galeri için) ---------------------------------

  /// Seviye tamamlandığında kazanılan yıldız sayısı (0-3). Galeri
  /// ekranında gösterilir; seviyeye tekrar girilirse yıldız korunur
  /// (mevcut performanstan yüksekse güncellenir).
  int starsFor(int levelId) => _prefs.getInt('$_kStarsPrefix$levelId') ?? 0;

  Future<void> setStarsFor(int levelId, int stars) async {
    final current = starsFor(levelId);
    if (stars > current) {
      await _prefs.setInt('$_kStarsPrefix$levelId', stars);
    }
  }

  // --- Tema -----------------------------------------------------------------

  /// 0=caucasus (varsayılan), 1=night, 2=forest
  int get themeIndex => _prefs.getInt(_kThemeIndex) ?? 0;

  Future<void> setThemeIndex(int value) =>
      _prefs.setInt(_kThemeIndex, value.clamp(0, 2));

  // --- Seviye kilit sistemi -------------------------------------------------

  /// Tutorial seviyesi (id=0) için yıldız varsa tutorial tamamlanmış demektir.
  bool get tutorialDone => _prefs.getBool(_kTutorialDone) ?? false;

  Future<void> setTutorialDone(bool value) =>
      _prefs.setBool(_kTutorialDone, value);

  /// Bir seviyenin oynanabilir olup olmadığını döndürür.
  ///
  /// Kural:
  ///   - id=0 (tutorial): her zaman açık (galeride gösterilmez)
  ///   - id=1: tutorialDone veya starsFor(0) > 0 ise açık
  ///   - id>=2: starsFor(id-1) > 0 ise açık (önceki tamamlanmış)
  bool isLevelUnlocked(int levelId) {
    if (levelId == 0) return true;
    if (levelId == 1) return tutorialDone || starsFor(0) > 0;
    return starsFor(levelId - 1) > 0;
  }

  // --- Bölüm içi ilerleme -------------------------------------------------

  List<String> solvedWordsFor(int levelId) =>
      _prefs.getStringList('$_kWordsPrefix$levelId') ?? const [];

  List<String> bonusWordsFor(int levelId) =>
      _prefs.getStringList('$_kBonusPrefix$levelId') ?? const [];

  /// Açılan ipucu hücreleri `"satır:sütun"` biçiminde saklanır.
  List<Cell> revealedCellsFor(int levelId) {
    final raw = _prefs.getStringList('$_kCellsPrefix$levelId') ?? const [];
    final cells = <Cell>[];
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final row = int.tryParse(parts[0]);
      final col = int.tryParse(parts[1]);
      if (row == null || col == null) continue;
      cells.add(Cell(row, col));
    }
    return cells;
  }

  Future<void> setSolvedWordsFor(int levelId, Iterable<String> words) =>
      _prefs.setStringList('$_kWordsPrefix$levelId', words.toList());

  Future<void> setBonusWordsFor(int levelId, Iterable<String> words) =>
      _prefs.setStringList('$_kBonusPrefix$levelId', words.toList());

  Future<void> setRevealedCellsFor(int levelId, Iterable<Cell> cells) =>
      _prefs.setStringList(
        '$_kCellsPrefix$levelId',
        [for (final c in cells) '${c.row}:${c.col}'],
      );

  /// Seviye tamamlanınca o seviyenin ara ilerlemesi temizlenir; böylece
  /// seviyeye (döngüde) tekrar gelindiğinde temiz başlanır.
  Future<void> clearLevelProgress(int levelId) async {
    await _prefs.remove('$_kWordsPrefix$levelId');
    await _prefs.remove('$_kCellsPrefix$levelId');
    await _prefs.remove('$_kBonusPrefix$levelId');
  }

  // --- Sıfırlama ------------------------------------------------------------

  /// Tüm kayıtlı verileri temizler (ses tercihi hariç, dışarıdan korunmalı).
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // --- İstatistikler -------------------------------------------------------

  static const _kBestStreak = 'best_streak';
  static const _kTotalWordsSolved = 'stat_total_words';
  static const _kTotalBonusWords = 'stat_total_bonus';
  static const _kTotalCoinsEarned = 'stat_coins_earned';
  static const _kTotalCoinsSpent = 'stat_coins_spent';
  static const _kTotalHintsUsed = 'stat_hints_used';

  /// Tüm zamanların en iyi serisi.
  int get bestStreak => _prefs.getInt(_kBestStreak) ?? 0;

  Future<void> setBestStreak(int value) async {
    final current = bestStreak;
    if (value > current) {
      await _prefs.setInt(_kBestStreak, value);
    }
  }

  // --- Kümülatif istatistik sayaçları ---------------------------------------

  /// Toplam kazanılan coin (tüm zamanlar).
  int get totalCoinsEarned => _prefs.getInt(_kTotalCoinsEarned) ?? 0;

  /// Toplam harcanan coin (ipucu için).
  int get totalCoinsSpent => _prefs.getInt(_kTotalCoinsSpent) ?? 0;

  /// Toplam kullanılan ipucu sayısı.
  int get totalHintsUsed => _prefs.getInt(_kTotalHintsUsed) ?? 0;

  /// Toplam çözülen kelime sayısı (grid, tüm zamanlar).
  int get totalWordsEver => _prefs.getInt(_kTotalWordsSolved) ?? 0;

  /// Toplam bulunan bonus kelime sayısı (tüm zamanlar).
  int get totalBonusEver => _prefs.getInt(_kTotalBonusWords) ?? 0;

  Future<void> addCoinsEarned(int amount) async {
    await _prefs.setInt(_kTotalCoinsEarned, totalCoinsEarned + amount);
  }

  Future<void> addCoinsSpent(int amount) async {
    await _prefs.setInt(_kTotalCoinsSpent, totalCoinsSpent + amount);
  }

  Future<void> addHintUsed() async {
    await _prefs.setInt(_kTotalHintsUsed, totalHintsUsed + 1);
  }

  Future<void> addWordSolved({bool isBonus = false}) async {
    final key = isBonus ? _kTotalBonusWords : _kTotalWordsSolved;
    final current = isBonus ? totalBonusEver : totalWordsEver;
    await _prefs.setInt(key, current + 1);
  }

  // --- Hesaplanan istatistikler ---------------------------------------------

  /// Toplam çözülen eşsiz kelime sayısı (tutorial hariç tüm seviyeler).
  int totalWordsSolved(int levelCount) {
    var total = 0;
    for (var id = 1; id < levelCount; id++) {
      total += solvedWordsFor(id).length;
    }
    return total;
  }

  /// Toplam bulunan bonus kelime sayısı (tutorial hariç).
  int totalBonusWords(int levelCount) {
    var total = 0;
    for (var id = 1; id < levelCount; id++) {
      total += bonusWordsFor(id).length;
    }
    return total;
  }

  /// Tamamlanan seviye sayısı (yıldız > 0 olan).
  int completedLevels(int levelCount) {
    var count = 0;
    for (var id = 1; id < levelCount; id++) {
      if (starsFor(id) > 0) count++;
    }
    return count;
  }

  /// Yıldız dağılımı: [1-yıldız, 2-yıldız, 3-yıldız] seviye sayıları.
  List<int> starDistribution(int levelCount) {
    final dist = [0, 0, 0];
    for (var id = 1; id < levelCount; id++) {
      final s = starsFor(id);
      if (s >= 1 && s <= 3) dist[s - 1]++;
    }
    return dist;
  }

  // --- Sözlük için yardımcı -------------------------------------------------

  /// Çözülen tüm kelimeleri (grid + bonus, tutorial dahil) toplar.
  /// Her öğe: (kelime, seviyeId, isBonus).
  List<(String word, int levelId, bool isBonus)> allSolvedWords(int levelCount) {
    final result = <(String, int, bool)>[];
    for (var id = 0; id < levelCount; id++) {
      for (final w in solvedWordsFor(id)) {
        result.add((w, id, false));
      }
      for (final w in bonusWordsFor(id)) {
        result.add((w, id, true));
      }
    }
    return result;
  }

  // --- Günlük hediye -------------------------------------------------------

  /// Gün karşılaştırması yerel saate göre epoch-gün sayısıyla yapılır.
  static int epochDay(DateTime now) =>
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Bugünün hediyesi alınabilir mi?
  bool giftAvailable(DateTime now) =>
      (_prefs.getInt(_kGiftDay) ?? -1) != epochDay(now);

  Future<void> markGiftClaimed(DateTime now) =>
      _prefs.setInt(_kGiftDay, epochDay(now));

  // --- Günlük challenge -----------------------------------------------------

  static const _kChallengeDay = 'challenge_day';

  /// Bugünün challenge'ı tamamlandı mı?
  bool get dailyChallengeDone {
    final day = _prefs.getInt(_kChallengeDay);
    return day == epochDay(DateTime.now());
  }

  /// Seviyeler listesinden bugünkü challenge seviyesinin indeksini döndürür.
  /// Tutorial (id=0) dahil edilmez, kalan seviyeler epochDay ile taranır.
  static int dailyLevelIndex(int totalLevels) {
    final gameLevels = totalLevels - 1; // tutorial hariç
    if (gameLevels <= 0) return 1;
    // Her gün aynı seviye seçilsin diye epoch day kullanılır.
    final day = epochDay(DateTime.now());
    // +1 çünkü id=0 tutorial, aralık [1, totalLevels-1]
    return 1 + (day % gameLevels);
  }

  /// Challenge tamamlandı olarak işaretler.
  Future<void> markDailyChallengeDone() async {
    await _prefs.setInt(_kChallengeDay, epochDay(DateTime.now()));
  }
}
