import 'package:dosh/core/strings.dart';
import 'package:dosh/ui/widgets/level_complete_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    Strings.testOverride = {
      'level_complete': 'Decқal!',
      'continue': 'Devam',
      'share': 'Paylaş',
    };
  });

  testWidgets('onShare verilmezse paylaş bağlantısı gösterilmez', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelCompletePanel(
            earned: 20,
            stars: 3,
            bestStreak: 2,
            onContinue: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Paylaş'), findsNothing);
  });

  testWidgets('onShare verilirse paylaş bağlantısı gösterilir ve tıklanabilir', (tester) async {
    var shared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelCompletePanel(
            earned: 20,
            stars: 3,
            bestStreak: 2,
            onContinue: () {},
            onShare: () => shared = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Paylaş'), findsOneWidget);
    await tester.tap(find.text('Paylaş'));
    expect(shared, isTrue);
  });
}
