import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/progress_store.dart';

enum SoundCue { tap, shuffle, hint, wrong, solve, coin, complete }

class GameSound extends ChangeNotifier {
  GameSound({required ProgressStore store})
      : _store = store,
        _enabled = store.soundOn {
    for (final player in _players.values) {
      unawaited(player.setReleaseMode(ReleaseMode.stop));
    }
  }

  final ProgressStore _store;
  bool _enabled;

  bool get enabled => _enabled;

  final Map<SoundCue, AudioPlayer> _players = {
    for (final cue in SoundCue.values) cue: AudioPlayer(playerId: cue.name),
  };

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
    final player = _players[cue];
    final asset = _assets[cue];
    if (player == null || asset == null) return;
    unawaited(
      _restart(player, asset, volume: _volumes[cue] ?? 0.45),
    );
  }

  Future<void> toggle() async {
    _enabled = !_enabled;
    notifyListeners();
    await _store.setSoundOn(_enabled);
    if (_enabled) play(SoundCue.tap);
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

  @override
  void dispose() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    super.dispose();
  }
}
