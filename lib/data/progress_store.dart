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

  static Future<ProgressStore> create() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  int get coins => _prefs.getInt(_kCoins) ?? GameConfig.startCoins;
  int get levelIndex => _prefs.getInt(_kLevelIndex) ?? 0;
  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;

  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);
  Future<void> setLevelIndex(int value) => _prefs.setInt(_kLevelIndex, value);
  Future<void> setSoundOn(bool value) => _prefs.setBool(_kSoundOn, value);

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
}
