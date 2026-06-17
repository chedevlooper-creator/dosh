import 'dart:math';

import '../core/graphemes.dart';

/// Bulmaca ızgarasında bir hücre konumu.
class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row,$col)';
}

enum WordDirection { across, down }

/// Bulmacaya yerleştirilmiş tek bir kelime.
class PlacedWord {
  PlacedWord({
    required String word,
    required this.row,
    required this.col,
    required this.direction,
  })  : word = normalize(word),
        graphemes = splitGraphemes(word);

  final String word;
  final List<String> graphemes;
  final int row;
  final int col;
  final WordDirection direction;

  /// Gerçek Çeçence açıklamanın i18n anahtarı (yoksa alt bilgi gösterilmez).
  String get infoKey => 'info_$word';

  List<Cell> get cells => [
        for (var i = 0; i < graphemes.length; i++)
          direction == WordDirection.across
              ? Cell(row, col + i)
              : Cell(row + i, col),
      ];

  factory PlacedWord.fromJson(Map<String, dynamic> json) => PlacedWord(
        word: json['word'] as String,
        row: json['row'] as int,
        col: json['col'] as int,
        direction: (json['dir'] as String) == 'down'
            ? WordDirection.down
            : WordDirection.across,
      );
}

/// Bir bölüm: çark harfleri + yerleştirilmiş kelimeler.
class Level {
  Level({
    required this.id,
    required List<String> letters,
    required this.words,
    List<String> bonusWords = const [],
    this.pack = 0,
  })  : letters = [for (final l in letters) normalize(l)],
        bonusWords = {for (final w in bonusWords) normalize(w)};

  final int id;

  /// Tematik paket indeksi (0: tutorial, 1: doğa/hayvan, 2: yiyecek/renk, 3: nesne/kavram, 4: zor/karışık).
  final int pack;

  /// Çark grafemleri (digraflar tek eleman).
  final List<String> letters;

  final List<PlacedWord> words;

  /// Izgarada yer almayan ama çarktan kurulabilen geçerli kelimeler.
  /// İçerik kuralı: yalnızca gerçek Çeçence kelimeler eklenir.
  final Set<String> bonusWords;

  /// Hücre → hedef grafem. Kesişim çakışmalarında hata fırlatır.
  late final Map<Cell, String> targetByCell = _buildTargets();

  /// Aynı kelime ızgaraya birden fazla kez yerleşebilir (ör. дош×2);
  /// oyun tamamlanması benzersiz kelime sayısı üzerinden ölçülür.
  late final int distinctWordCount = words.map((w) => w.word).toSet().length;

  late final int minRow = targetByCell.keys.map((c) => c.row).reduce(min);
  late final int maxRow = targetByCell.keys.map((c) => c.row).reduce(max);
  late final int minCol = targetByCell.keys.map((c) => c.col).reduce(min);
  late final int maxCol = targetByCell.keys.map((c) => c.col).reduce(max);
  int get rowCount => maxRow - minRow + 1;
  int get colCount => maxCol - minCol + 1;

  Map<Cell, String> _buildTargets() {
    final map = <Cell, String>{};
    for (final word in words) {
      final cells = word.cells;
      for (var i = 0; i < cells.length; i++) {
        final existing = map[cells[i]];
        if (existing != null && existing != word.graphemes[i]) {
          throw StateError(
            'Seviye $id: ${cells[i]} hücresinde çakışma '
            '("$existing" / "${word.graphemes[i]}")',
          );
        }
        map[cells[i]] = word.graphemes[i];
      }
    }
    return map;
  }

  /// İçerik tutarlılık kontrolü; hatalı seviye verisinde açıklayıcı hata verir.
  void validate() {
    if (words.isEmpty) {
      throw StateError('Seviye $id: kelime listesi boş');
    }
    targetByCell; // kesişim kontrolünü tetikler
    final texts = <String>{};
    for (final word in words) {
      if (word.graphemes.length < 2) {
        throw StateError('Seviye $id: "${word.word}" çok kısa');
      }
      // Birden fazla kez bulunma kontrolü kaldırıldı (ekran görüntüsündeki ızgara yerleşimine uyum için)
      texts.add(word.word);
      final pool = List<String>.from(letters);
      for (final grapheme in word.graphemes) {
        if (!pool.remove(grapheme)) {
          throw StateError(
            'Seviye $id: "${word.word}" çark harflerinden kurulamıyor '
            '(eksik: "$grapheme")',
          );
        }
      }
    }
    for (final bonus in bonusWords) {
      final graphemes = splitGraphemes(bonus);
      if (graphemes.length < 2) {
        throw StateError('Seviye $id: bonus "$bonus" çok kısa');
      }
      if (texts.contains(bonus)) {
        throw StateError(
          'Seviye $id: bonus "$bonus" zaten ızgara kelimesi',
        );
      }
      final pool = List<String>.from(letters);
      for (final grapheme in graphemes) {
        if (!pool.remove(grapheme)) {
          throw StateError(
            'Seviye $id: bonus "$bonus" çark harflerinden kurulamıyor '
            '(eksik: "$grapheme")',
          );
        }
      }
    }
  }

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as int,
        letters: [for (final l in (json['letters'] as List)) l as String],
        words: [
          for (final w in (json['words'] as List))
            PlacedWord.fromJson(w as Map<String, dynamic>),
        ],
        bonusWords: [
          for (final b in (json['bonus'] as List? ?? const [])) b as String,
        ],
        pack: (json['pack'] as int?) ?? 0,
      );
}
