/// Çeçen Kiril alfabesinin oyun içi grafem ("oyun harfi") işlemleri.
///
/// Çeçen alfabesinde аь, гӀ, кх gibi iki karakterle yazılan birimler tek harf
/// sayılır. Çark baloncukları, bulmaca hücreleri ve kelime eşleştirme bu
/// grafemler üzerinden çalışır.
library;

/// Palochka — U+04C0 (Ӏ). Küçük varyantı (U+04CF) ve Latin i/I yazımları
/// [normalize] içinde bu karaktere indirgenir.
const String palochka = 'Ӏ';

/// İki karakterle yazılan Çeçen harfleri (digraf envanteri).
/// Palochka içerenler: гӀ, кӀ, пӀ, тӀ, хӀ, цӀ, чӀ.
const List<String> chechenDigraphs = [
  'аь',
  'гӀ',
  'кх',
  'къ',
  'кӀ',
  'оь',
  'пӀ',
  'тӀ',
  'уь',
  'хь',
  'хӀ',
  'цӀ',
  'чӀ',
  'юь',
  'яь',
];

final Set<String> _digraphSet = chechenDigraphs.map(normalize).toSet();

/// Kelimeyi küçük harfe çevirir ve palochka varyantlarını (U+04CF, Latin i/I)
/// tek biçime (U+04C0) indirger. Veri ve kod hangi varyantla yazılmış olursa
/// olsun eşleştirme tutarlı kalır.
String normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp('[ӀӏiI]'), palochka)
      .trim();
}

/// [input] kelimesini oyun grafemlerine böler (en-uzun-eşleşme).
///
/// Örnek: `малх → [м, а, л, х]`, `цӀа → [цӀ, а]`, `хьо → [хь, о]`.
List<String> splitGraphemes(String input) {
  final w = normalize(input);
  final result = <String>[];
  var i = 0;
  while (i < w.length) {
    if (i + 1 < w.length && _digraphSet.contains(w.substring(i, i + 2))) {
      result.add(w.substring(i, i + 2));
      i += 2;
    } else {
      result.add(w[i]);
      i += 1;
    }
  }
  return result;
}

/// Baloncuk ve hücrelerdeki gösterim biçimi (büyük harf; palochka sabit kalır).
String displayGrapheme(String grapheme) => grapheme.toUpperCase();
