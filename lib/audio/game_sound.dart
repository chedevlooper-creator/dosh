import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/progress_store.dart';

enum SoundCue { tap, shuffle, hint, wrong, solve, coin, complete }

class GameSound extends ChangeNotifier {
  GameSound({required ProgressStore store})
      : _store = store,
        _enabled = store.soundOn;

  final ProgressStore _store;
  bool _enabled;

  bool get enabled => _enabled;

  // Player'lar ilk kullanımda yaratılır: ses kapalıyken (ve testlerde) hiç
  // platform kanalı açılmaz; uygulama başlangıcı da hafifler.
  final Map<SoundCue, AudioPlayer> _players = {};
  AudioPlayer? _homeAmbience;
  bool _homeAmbienceRequested = false;
  bool _homeAmbiencePlaying = false;

  AudioPlayer _playerFor(SoundCue cue) => _players.putIfAbsent(cue, () {
        final player = AudioPlayer(playerId: cue.name);
        unawaited(player.setReleaseMode(ReleaseMode.stop));
        return player;
      });

  static const Map<SoundCue, String> _assets = {
    SoundCue.tap: 'audio/tap.wav',
    SoundCue.shuffle: 'audio/tap.wav',
    SoundCue.hint: 'audio/hint.wav',
    SoundCue.wrong: 'audio/wrong.wav',
    SoundCue.solve: 'audio/solve.wav',
    SoundCue.coin: 'audio/coin.wav',
    SoundCue.complete: 'audio/complete.wav',
  };

  static const Map<SoundCue, double> _volumes = {
    SoundCue.tap: 0.42,
    SoundCue.shuffle: 0.36,
    SoundCue.hint: 0.48,
    SoundCue.wrong: 0.42,
    SoundCue.solve: 0.52,
    SoundCue.coin: 0.42,
    SoundCue.complete: 0.56,
  };

  void play(SoundCue cue) {
    if (!_enabled) return;
    final asset = _assets[cue];
    if (asset == null) return;
    unawaited(
      _restart(_playerFor(cue), asset, volume: _volumes[cue] ?? 0.45),
    );
  }

  void startHomeAmbience() {
    _homeAmbienceRequested = true;
    if (!_enabled || _homeAmbiencePlaying) return;
    unawaited(_playHomeAmbience());
  }

  void stopHomeAmbience() {
    _homeAmbienceRequested = false;
    _homeAmbiencePlaying = false;
    final player = _homeAmbience;
    if (player != null) unawaited(player.stop());
  }

  Future<void> toggle() async {
    _enabled = !_enabled;
    notifyListeners();
    await _store.setSoundOn(_enabled);
    if (_enabled) {
      play(SoundCue.tap);
      // Kullanıcı o anda home'daysa ambience tekrar başlasın; oyun
      // ekranındaysa home'a dönünce zaten startHomeAmbience çağrılacak.
      if (_homeAmbienceRequested) {
        startHomeAmbience();
      }
    } else {
      // Ses kapatılınca ambience de durmalı — _playHomeAmbience içindeki
      // !_enabled guard'ı sayesinde yarış durumu oluşmaz.
      _homeAmbiencePlaying = false;
      final player = _homeAmbience;
      if (player != null) await player.stop();
    }
  }

  Future<void> _restart(
    AudioPlayer player,
    String asset, {
    required double volume,
  }) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Ses motoru test ortamında veya izin verilmeyen web durumlarında sessizce
      // başarısız olabilir; oyun akışı bundan etkilenmemeli.
    }
  }

  Future<void> _playHomeAmbience() async {
    final player = _homeAmbience ??= AudioPlayer(playerId: 'home_ambience');
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      // Play öncesi tekrar kontrol: toggle ile ses kapatılmış veya
      // stopHomeAmbience çağrılmış olabilir — yarış koşulunu önle.
      if (!_enabled || !_homeAmbienceRequested) {
        _homeAmbiencePlaying = false;
        return;
      }
      await player.play(
        AssetSource('audio/birds.wav'),
        volume: 0.16,
      );
      // Play sonrası tekrar kontrol: play() sırasında toggle edilmiş olabilir.
      if (_enabled && _homeAmbienceRequested) {
        _homeAmbiencePlaying = true;
      } else {
        _homeAmbiencePlaying = false;
        await player.stop();
      }
    } catch (_) {
      // Web'de kullanıcı etkileşimi olmadan ortam sesi engellenebilir.
      _homeAmbiencePlaying = false;
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    final ambience = _homeAmbience;
    if (ambience != null) unawaited(ambience.dispose());
    super.dispose();
  }
}
