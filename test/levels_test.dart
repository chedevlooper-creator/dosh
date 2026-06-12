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
    // Zorluk eğrisi: ilk 5 seviye az, sonraki 5 orta, son 5 fazla.
    // Tutorial seviyesi (id=0) bonus eğrisine dahil değil; ondan sonraki
    // seviyeler monotonik artmalı.
    final gameLevels = levels.where((l) => l.id != 0).toList();
    int lastBonus = -1;
    for (final level in gameLevels) {
      // Genel olarak monotonik artmalı veya eşit kalmalı (kademeli artış).
      expect(level.bonusWords.length, greaterThanOrEqualTo(lastBonus),
          reason:
              'seviye ${level.id}: ${level.bonusWords.length} bonus, önceki: $lastBonus');
      lastBonus = level.bonusWords.length;
    }
    // İlk 5 seviye ortalama az (max 2), son 5 seviye ortalama çok (min 4).
    final first5 = gameLevels.take(5).map((l) => l.bonusWords.length).fold(0, (a, b) => a + b);
    // 30 seviyede son 5 seviye için
    final last5 = gameLevels.skip(gameLevels.length - 5).map((l) => l.bonusWords.length).fold(0, (a, b) => a + b);
    expect(first5, lessThanOrEqualTo(10),
        reason: 'ilk 5 seviye toplam bonus $first5, 10\'dan az olmalı');
    expect(last5, greaterThanOrEqualTo(20),
        reason: 'son 5 seviye toplam bonus $last5, 20+ olmalı');
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
