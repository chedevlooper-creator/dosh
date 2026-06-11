import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Çok hafif yerelleştirme katmanı.
///
/// Tasarım kuralı: bir anahtarın gerçek Çeçence karşılığı yoksa kullanıcıya
/// teknik anahtarın kendisi gösterilir; uydurma metin asla yazılmaz.
abstract final class Strings {
  static Map<String, String> _map = const {};

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/ce.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _map = decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      _map = const {};
    }
  }

  /// Çevirisi varsa gerçek Çeçence, yoksa anahtarın kendisi.
  static String t(String key) => _map[key] ?? key;

  /// Çevirisi yoksa null — içerik alanları (alt bilgi gibi) hiç gösterilmez.
  static String? tOrNull(String key) => _map[key];

  @visibleForTesting
  static set testOverride(Map<String, String> values) => _map = values;
}
