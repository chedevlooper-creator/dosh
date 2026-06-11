import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Seviyeleri asset'ten yükler ve içerik tutarlılığını doğrular.
abstract final class LevelRepository {
  static Future<List<Level>> load() async {
    final raw = await rootBundle.loadString('assets/levels/levels.json');
    final levels = [
      for (final item in (json.decode(raw) as List))
        Level.fromJson(item as Map<String, dynamic>),
    ];
    if (levels.isEmpty) {
      throw StateError('levels.json boş — en az bir seviye gerekli');
    }
    for (final level in levels) {
      level.validate();
    }
    return levels;
  }
}
