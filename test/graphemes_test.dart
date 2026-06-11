import 'package:dosh/core/graphemes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitGraphemes', () {
    test('basit kelimeleri tek karakterlere böler', () {
      expect(splitGraphemes('малх'), ['м', 'а', 'л', 'х']);
      expect(splitGraphemes('лам'), ['л', 'а', 'м']);
      expect(splitGraphemes('корта'), ['к', 'о', 'р', 'т', 'а']);
    });

    test('digrafları tek grafem sayar', () {
      expect(splitGraphemes('хьо'), ['хь', 'о']);
      expect(splitGraphemes('цӀа'), ['цӀ', 'а']);
      expect(
        splitGraphemes('уьстагӀ'),
        ['уь', 'с', 'т', 'а', 'гӀ'],
      );
    });

    test('büyük harfi ve palochka varyantlarını normalize eder', () {
      expect(splitGraphemes('МАЛХ'), ['м', 'а', 'л', 'х']);
      // Küçük palochka (U+04CF) → standart (U+04C0)
      expect(splitGraphemes('цӏа'), ['цӀ', 'а']);
      // Latin I ile yazılmış palochka da normalize edilir
      expect(splitGraphemes('цIа'), ['цӀ', 'а']);
    });
  });

  test('displayGrapheme büyük harf gösterimi üretir', () {
    expect(displayGrapheme('м'), 'М');
    expect(displayGrapheme('хь'), 'ХЬ');
    expect(displayGrapheme('цӀ'), 'ЦӀ');
  });
}
