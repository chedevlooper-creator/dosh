# Дош — Çeçence Kelime Bulmaca Oyunu

Words-of-Wonders tarzı (harf çarkı + crossword) özgün bir Çeçence kelime oyunu.
Hedef platformlar: **Android, iOS, Windows** (Flutter tek kod tabanı).

## Çalıştırma

```bash
flutter pub get
flutter run -d web-server   # lokal geliştirme/önizleme (tarayıcı)
flutter run -d windows      # Windows PC üzerinde
flutter run                 # bağlı Android/iOS cihazda
```

## İçerik kuralları (önemli)

- **Sahte Çeçence asla yazılmaz.** Kullanıcıya görünen her metin ya gerçek
  Çeçencedir ya da teknik localization anahtarıdır (`level_1` gibi).
- `assets/i18n/ce.json` — anahtar → gerçek Çeçence metin. Anahtar yoksa
  ekranda anahtarın kendisi görünür.
- Çözülen kelimenin alt bilgisi `info_<kelime>` anahtarından okunur
  (ör. `info_малх`). Anahtar yoksa alt bilgi şeridi hiç görünmez.

## Seviye ekleme

`assets/levels/levels.json` — her seviye:

```json
{
  "id": 4,
  "letters": ["х", "ь", ...],          // çark grafemleri (digraflar tek eleman: "хь")
  "words": [
    { "word": "хьо", "row": 0, "col": 0, "dir": "across" }
  ]
}
```

- Çeçen digrafları (аь, гӀ, кх, къ, кӀ, оь, пӀ, тӀ, уь, хь, хӀ, цӀ, чӀ, юь, яь)
  oyunda **tek harf** sayılır; `lib/core/graphemes.dart` kelimeleri otomatik böler.
- Tüm kelimeler çark harflerinden kurulabilmeli; kesişen hücreler aynı grafemi
  taşımalı. `flutter test` bu tutarlılığı otomatik doğrular.

## Arka plan görseli

Şu an arka plan kodla çizilen Kafkas manzarasıdır
(`lib/ui/widgets/scenic_background.dart`). Gerçek fotoğraf kullanmak için
`assets/backgrounds/` klasörüne görsel ekleyip pubspec'e kaydedin ve
`ScenicBackground` içindeki yönergeyi izleyin.

## Yapı

```
lib/core      # i18n, Çeçen grafem tokenizer, sabitler
lib/data      # seviye modelleri + yükleme + kalıcı ilerleme
lib/game      # oyun durumu/kuralları (GameController)
lib/ui        # tema, ekran, widget'lar, efektler
assets        # i18n, seviyeler, fontlar
```
