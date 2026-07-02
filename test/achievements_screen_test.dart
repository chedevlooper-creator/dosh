import 'package:dosh/core/strings.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:dosh/ui/screens/achievements_screen.dart';
import 'package:dosh/ui/widgets/scenic_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Strings.testOverride = {
      'achievements': 'Başarımlar',
      'achievements_unlocked': 'başarım açıldı',
      'achievements_tier_bronze': 'Bronz',
      'achievements_tier_silver': 'Gümüş',
      'achievements_tier_gold': 'Altın',
      'achievements_tier_locked': 'Kilitli',
      'ach_words_title': 'Kelime Ustası',
      'ach_words_unit': 'kelime çöz',
      'ach_bonus_title': 'Bonus Avcısı',
      'ach_bonus_unit': 'bonus kelime bul',
      'ach_coins_title': 'Altın Toplayıcı',
      'ach_coins_unit': 'coin kazan',
      'ach_streak_title': 'Seri Ustası',
      'ach_streak_unit': 'art arda doğru çöz',
      'ach_levels_title': 'Seviye Kaşifi',
      'ach_levels_unit': 'seviye tamamla',
      'ach_perfect_title': 'Mükemmeliyetçi',
      'ach_perfect_unit': 'seviyeyi 3 yıldızla bitir',
      'ach_timeAttack_title': 'Hız Ustası',
      'ach_timeAttack_unit': 'puan topla (Zamana Karşı)',
      'ach_tutorial_title': 'İlk Adım',
      'ach_tutorial_unit': 'öğreticiyi tamamla',
    };
  });

  Future<ProgressStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    return ProgressStore.create();
  }

  testWidgets('tüm başarım kartları başlıklarıyla render edilir', (tester) async {
    final store = await freshStore();
    var backTapped = false;

    // Tüm kartların taşmadan render edilmesi için uzun bir görünüm alanı.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AchievementsScreen(
          store: store,
          theme: SceneTheme.caucasus,
          levelCount: 11,
          onBack: () => backTapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Başarımlar'), findsOneWidget);
    expect(find.text('Kelime Ustası'), findsOneWidget);
    expect(find.text('Bonus Avcısı'), findsOneWidget);
    expect(find.text('Altın Toplayıcı'), findsOneWidget);
    expect(find.text('Seri Ustası'), findsOneWidget);
    expect(find.text('Seviye Kaşifi'), findsOneWidget);
    expect(find.text('Mükemmeliyetçi'), findsOneWidget);
    expect(find.text('Hız Ustası'), findsOneWidget);
    expect(find.text('İlk Adım'), findsOneWidget);

    // Hiçbir ilerleme yokken özet "0/8 başarım açıldı" gösterir.
    expect(find.text('0/8 başarım açıldı'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backTapped, isTrue);
  });

  testWidgets('kazanılan başarım kademesi doğru gösterilir', (tester) async {
    SharedPreferences.setMockInitialValues({
      'stat_total_words': 12, // words bronze eşiği (10) aşıldı
      'tutorial_done': true, // tutorial tek seferlik başarım tamamlandı
    });
    final store = await ProgressStore.create();

    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AchievementsScreen(
          store: store,
          theme: SceneTheme.caucasus,
          levelCount: 11,
          onBack: () {},
        ),
      ),
    );
    await tester.pump();

    // words + tutorial en az bronz/tamamlandı -> 2/8 açıldı.
    expect(find.text('2/8 başarım açıldı'), findsOneWidget);
    expect(find.text('Bronz'), findsOneWidget);
    expect(find.text('Altın'), findsOneWidget); // tek seferlik tutorial -> gold
  });
}
