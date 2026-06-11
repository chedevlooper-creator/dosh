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
}
