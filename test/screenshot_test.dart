import 'package:dosh/app.dart';
import 'package:dosh/core/strings.dart';
import 'package:dosh/data/level_repository.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Görsel doğrulama ekran görüntüleri (golden) üretir. Normal test
/// koşusunda atlanır; üretmek için:
///
///   flutter test --dart-define=GOLDEN=true --update-goldens \
///     test/screenshot_test.dart
///
/// Çıktılar: test/goldens/*.png
const bool _capture = bool.fromEnvironment('GOLDEN');

Future<void> _loadFonts() async {
  final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  // Georgia test ortamında yoktur; ekran görüntüsünde kutu (Ahem) yerine
  // gerçek glif görmek için aynı dosyaları her iki aile adına da yükleriz.
  for (final family in ['NotoSans', 'Georgia']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(regular))
      ..addFont(Future.value(bold));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ana ekran + oyun ekranı görüntüleri (mobil ve masaüstü)',
    (tester) async {
      SharedPreferences.setMockInitialValues({'sound_on': false});
      final store = await ProgressStore.create();

      await tester.runAsync(() async {
        await _loadFonts();
        await Strings.load();
      });
      final levels = await tester.runAsync(LevelRepository.load);

      // Mobil dikey (iPhone 14 oranı)
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(DoshApp(levels: levels!, store: store));
      await tester.pump();

      // Arka plan fotoğrafının çözülmesini bekle (golden'da boş kalmasın)
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/backgrounds/caucasus.png'),
          tester.element(find.byType(MaterialApp)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_mobile.png'),
      );

      // Oyun ekranına geç
      await tester.tap(find.byKey(const ValueKey('home_play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/game_mobile.png'),
      );

      // Geniş masaüstü penceresi (Windows davranışı)
      tester.view.physicalSize = const Size(1280 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/game_desktop.png'),
      );
    },
    skip: !_capture,
  );
}
