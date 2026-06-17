import 'package:dosh/data/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('levels.json yüklenir ve tüm seviyeler tutarlıdır', () async {
    // load() her seviyede validate() çağırır: kelimeler çark harflerinden
    // kurulabilmeli, kesişimler çakışmamalı, kelimeler benzersiz olmalı.
    final levels = await LevelRepository.load();

    expect(levels, isNotEmpty);
    final ids = levels.map((l) => l.id).toSet();
    expect(ids.length, levels.length,
        reason: 'seviye id değerleri benzersiz olmalı');
  });

  test('bonus sayısı seviye ile kademeli artar (zorluk eğrisi)', () async {
    final levels = await LevelRepository.load();
    // Zorluk eğrisi: genel olarak bonus sayısı seviye ilerledikçe artar.
    // Tutorial (id=0) hariç. Kesin monotonik olmak zorunda değil ama
    // son 10 seviye ilk 10 seviyeden belirgin fazla olmalı.
    final gameLevels = levels.where((l) => l.id != 0).toList();
    final first10 = gameLevels.take(10).map((l) => l.bonusWords.length).fold(0, (a, b) => a + b);
    final last10 = gameLevels.skip(gameLevels.length - 10).map((l) => l.bonusWords.length).fold(0, (a, b) => a + b);
    expect(last10, greaterThan(first10),
        reason: 'son 10 seviye bonusu ($last10), ilk 10 seviyeden ($first10) fazla olmalı');
    expect(last10, greaterThanOrEqualTo(15),
        reason: 'son 10 seviye toplam bonus $last10, 15+ olmalı');
  });

  test('bonus kelimelerin toplam sayısı en az 30', () async {
    final levels = await LevelRepository.load();
    final total = levels
        .map((l) => l.bonusWords.length)
        .fold<int>(0, (a, b) => a + b);
    expect(total, greaterThanOrEqualTo(30),
        reason: 'mevcut bonus kelime sayısı: $total');
  });
}
