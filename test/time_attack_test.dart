import 'package:dosh/audio/game_sound.dart';
import 'package:dosh/core/strings.dart';
import 'package:dosh/data/models.dart';
import 'package:dosh/data/progress_store.dart';
import 'package:dosh/ui/screens/time_attack_screen.dart';
import 'package:dosh/ui/widgets/scenic_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Level _mockLevel() => Level(
      id: 1,
      letters: ['м', 'а', 'л', 'х'],
      words: [
        PlacedWord(
            word: 'малх', row: 0, col: 0, direction: WordDirection.across),
        PlacedWord(word: 'лам', row: 0, col: 2, direction: WordDirection.down),
      ],
      bonusWords: ['мах'],
    );

void main() {
  late ProgressStore store;
  late GameSound sound;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'coins': 100,
      'time_attack_high_score': 50,
    });
    store = await ProgressStore.create();
    sound = GameSound(store: store);
    Strings.testOverride = {
      'time_attack_title': 'Zamana Karşı',
      'time_attack_score': 'Puan: %d',
      'time_attack_high_score': 'Rekor: %d',
      'time_attack_high_score_label': 'Rekor',
      'time_attack_ready': 'Кечло!',
      'time_attack_go': 'Başla',
      'time_attack_game_over': 'Süre Bitti',
      'time_attack_new_record': 'Yeni Rekor',
      'time_attack_earned_coins': 'Coin: %d',
      'time_attack_restart': 'Yeniden',
      'time_attack_home': 'Ana Sayfa',
      'time_attack_already_found': 'Zaten Bulundu',
      'time_attack_invalid_word': 'Geçersiz',
    };
  });

  Widget _buildTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('TimeAttackScreen: 3-2-1 Countdown and Game Start',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        TimeAttackScreen(
          levels: [_mockLevel()],
          store: store,
          sound: sound,
          theme: SceneTheme.caucasus,
          onBack: () {},
        ),
      ),
    );

    // Başlangıçta geri sayım ekranı açık olmalı ve 3 göstermeli
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Кечло!'), findsOneWidget); // time_attack_ready

    // 1 saniye geçsin -> 2 göstermeli
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    // 1 saniye geçsin -> 1 göstermeli
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    // 1 saniye geçsin -> Oyun başlamalı
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3'), findsNothing);
    expect(find.text('Кечло!'), findsNothing);

    // Oyun aktif olmalı, zamanlayıcı 60'tan geri saymaya başlamalı
    final state = tester.state<State<StatefulWidget>>(find.byType(TimeAttackScreen)) as dynamic;
    expect(state.isPlaying, isTrue);
    expect(state.timeLeft, 60);
  });

  testWidgets('TimeAttackScreen: Correct Word scoring and time additions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        TimeAttackScreen(
          levels: [_mockLevel()],
          store: store,
          sound: sound,
          theme: SceneTheme.caucasus,
          onBack: () {},
        ),
      ),
    );

    // Geri sayımı atla
    await tester.pump(const Duration(seconds: 3));

    final state = tester.state<State<StatefulWidget>>(find.byType(TimeAttackScreen)) as dynamic;

    // 'м', 'а', 'л', 'х' harflerinin indeksleri çarkta:
    // mockLevel'da letters: ['м', 'а', 'л', 'х']
    // 'лам' kelimesini oluşturmak için indeksler: [2, 1, 0] (л=2, а=1, м=0)
    state.enterBubble(2);
    state.enterBubble(1);
    state.enterBubble(0);
    state.releaseSelection();

    await tester.pump();

    // 'лам' geçerli bir kelime olduğundan score artmalı, +3 saniye kazanılmalı
    expect(state.score, 30); // 3 harf * 10
    expect(state.timeLeft, 63); // 60 + 3
    expect(state.foundWords.contains('лам'), isTrue);

    // Tekrar girildiğinde score ve süre değişmemeli
    state.enterBubble(2);
    state.enterBubble(1);
    state.enterBubble(0);
    state.releaseSelection();

    await tester.pump();
    expect(state.score, 30);
    expect(state.timeLeft, 63);
  });

  testWidgets('TimeAttackScreen: Wrong Word reduces time',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        TimeAttackScreen(
          levels: [_mockLevel()],
          store: store,
          sound: sound,
          theme: SceneTheme.caucasus,
          onBack: () {},
        ),
      ),
    );

    // Geri sayımı atla
    await tester.pump(const Duration(seconds: 3));

    final state = tester.state<State<StatefulWidget>>(find.byType(TimeAttackScreen)) as dynamic;

    // Yanlış bir kelime gir (örneğin 'мх' - letters'dan m-x)
    state.enterBubble(0);
    state.enterBubble(3);
    state.releaseSelection();

    await tester.pump();

    // Wrong word should deduct 1 second
    expect(state.score, 0);
    expect(state.timeLeft, 59); // 60 - 1
  });

  testWidgets('TimeAttackScreen: Game Over and High Score check',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        TimeAttackScreen(
          levels: [_mockLevel()],
          store: store,
          sound: sound,
          theme: SceneTheme.caucasus,
          onBack: () {},
        ),
      ),
    );

    // Geri sayımı atla
    await tester.pump(const Duration(seconds: 3));

    final state = tester.state<State<StatefulWidget>>(find.byType(TimeAttackScreen)) as dynamic;

    // Skor yapalım
    state.enterBubble(2);
    state.enterBubble(1);
    state.enterBubble(0);
    state.releaseSelection(); // +30 puan, skor = 30

    // 'mah' bonus kelimesini yapalım (м=0, а=1, х=3)
    state.enterBubble(0);
    state.enterBubble(1);
    state.enterBubble(3);
    state.releaseSelection(); // +30 puan, skor = 60 (yeni rekor çünkü high_score=50'ydi)

    await tester.pump();

    // Süreyi 0'a getirip tetikleyelim
    state.timeLeft = 0;
    // Bir saniye daha pompalayarak timer'ın tetiklenmesini simüle et
    await tester.pump(const Duration(seconds: 1));

    // Oyun bitmiş olmalı
    expect(state.isGameOver, isTrue);
    expect(store.timeAttackHighScore, 60); // Rekor kaydedilmeli
    expect(store.coins, 106); // 100 + 60~/10 = 106 coins
  });

  testWidgets('TimeAttackScreen: Refresh wheel power-up',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        TimeAttackScreen(
          levels: [_mockLevel()],
          store: store,
          sound: sound,
          theme: SceneTheme.caucasus,
          onBack: () {},
        ),
      ),
    );

    // Geri sayımı atla
    await tester.pump(const Duration(seconds: 3));

    final state = tester.state<State<StatefulWidget>>(find.byType(TimeAttackScreen)) as dynamic;

    expect(store.coins, 100);

    // Çarkı yenileyelim (15 coin düşmeli)
    state.refreshWheel();
    await tester.pump();

    expect(store.coins, 85); // 100 - 15
  });
}
