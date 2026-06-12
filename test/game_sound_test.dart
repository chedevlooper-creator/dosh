import 'package:dosh/audio/game_sound.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _newStore({bool soundOn = true}) async {
  SharedPreferences.setMockInitialValues({'sound_on': soundOn});
  return ProgressStore.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AudioPlayer platform channel çağrılarını boşa çıkar; testlerde
  // gerçek ses çalmak yerine yalnızca state machine'i doğruluyoruz.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
  });

  group('GameSound.enabled state machine', () {
    test('başlangıçta store\'daki değer okunur', () async {
      final store = await _newStore(soundOn: true);
      final sound = GameSound(store: store);
      expect(sound.enabled, isTrue);
      sound.dispose();
    });

    test('başlangıçta kapalıysa enabled false', () async {
      final store = await _newStore(soundOn: false);
      final sound = GameSound(store: store);
      expect(sound.enabled, isFalse);
      sound.dispose();
    });

    test('toggle enabled\'ı tersine çevirir, store\'a yazar', () async {
      final store = await _newStore(soundOn: true);
      final sound = GameSound(store: store);

      await sound.toggle();
      expect(sound.enabled, isFalse);
      expect(store.soundOn, isFalse);

      await sound.toggle();
      expect(sound.enabled, isTrue);
      expect(store.soundOn, isTrue);

      sound.dispose();
    });

    test('toggle notifyListeners çağırır', () async {
      final store = await _newStore(soundOn: true);
      final sound = GameSound(store: store);
      var notifications = 0;
      sound.addListener(() => notifications++);

      await sound.toggle();
      await sound.toggle();

      expect(notifications, 2);
      sound.dispose();
    });
  });

  group('GameSound.play', () {
    test('ses kapalıyken play hiçbir şey yapmaz (hata atmaz)', () async {
      final store = await _newStore(soundOn: false);
      final sound = GameSound(store: store);
      expect(sound.enabled, isFalse);
      // AudioPlayer yaratmadan çağır — _enabled guard'ı sayesinde hiçbir
      // şey tetiklenmemeli.
      sound.play(SoundCue.tap);
      sound.dispose();
    });
  });
}
