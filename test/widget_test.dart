import 'package:dosh/app.dart';
import 'package:dosh/data/models.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Level _malxLevel() => Level(
      id: 1,
      letters: ['м', 'а', 'л', 'х'],
      words: [
        PlacedWord(
            word: 'малх', row: 0, col: 0, direction: WordDirection.across),
        PlacedWord(word: 'лам', row: 0, col: 2, direction: WordDirection.down),
        PlacedWord(
            word: 'мах', row: 2, col: 2, direction: WordDirection.across),
      ],
    );

Future<ProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore.create();
}

void main() {
  testWidgets('oyun ekranı kurulur: başlık anahtarı ve çark harfleri görünür',
      (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(DoshApp(levels: [_malxLevel()], store: store));
    await tester.pump();

    // Çeçence çevirisi olmayan başlık, teknik anahtar olarak görünür.
    expect(find.text('level_1'), findsOneWidget);
    expect(find.text('М'), findsOneWidget);
    expect(find.text('А'), findsOneWidget);
    expect(find.text('Л'), findsOneWidget);
    expect(find.text('Х'), findsOneWidget);
    // Coin kutusu başlangıç değeri
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('sürükleyerek kelime çözmek grid ve coin kutusunu günceller',
      (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(DoshApp(levels: [_malxLevel()], store: store));
    await tester.pump();

    final m = tester.getCenter(find.text('М'));
    final a = tester.getCenter(find.text('А'));
    final l = tester.getCenter(find.text('Л'));
    final x = tester.getCenter(find.text('Х'));

    final gesture = await tester.startGesture(m);
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.moveTo(a);
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.moveTo(l);
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.moveTo(x);
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();

    // Yerleşme + başarı animasyonları tamamlansın
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 900));

    // 'М' artık hem çark baloncuğunda hem çözülen hücrede
    expect(find.text('М'), findsNWidgets(2));
    // 100 + 4 harf × 5 coin
    expect(find.text('120'), findsOneWidget);
  });
}
