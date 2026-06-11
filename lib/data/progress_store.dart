import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Coin ve seviye ilerlemesinin kalıcı saklanması (tüm platformlarda çalışır).
class ProgressStore {
  ProgressStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kCoins = 'coins';
  static const _kLevelIndex = 'level_index';
  static const _kSoundOn = 'sound_on';

  static Future<ProgressStore> create() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  int get coins => _prefs.getInt(_kCoins) ?? GameConfig.startCoins;
  int get levelIndex => _prefs.getInt(_kLevelIndex) ?? 0;
  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;

  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);
  Future<void> setLevelIndex(int value) => _prefs.setInt(_kLevelIndex, value);
  Future<void> setSoundOn(bool value) => _prefs.setBool(_kSoundOn, value);
}
