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

## Ücretsiz Yayınlama Rehberi

Mağaza ücreti ödemeden oyunu dağıtmak için:

### 1. Web / PWA (en kolay)

**Netlify ile (önerilen):**
1. [netlify.com](https://netlify.com)'da hesap aç.
2. "Add new site" → "Import an existing project" → GitHub repo'nu seç.
3. Build command: `flutter build web --release`  
   Publish directory: `build/web`
4. Deploy. Site otomatik her `main` push'unda güncellenir.
5. Opsiyonel: `NETLIFY_AUTH_TOKEN` ve `NETLIFY_SITE_ID` repo secrets olarak ekle, `.github/workflows/release.yml` hem GitHub Pages hem Netlify'e deploy eder.

**Landing page:** `/landing.html` adresinde oyun tanıtĴmĴ ve APK indirme linki vardır.  
**APK redirect:** `/apk` adresi GitHub Releases'teki son APK'ye yönlendirir.

**GitHub Pages ile (alternatif):**

### 2. Android APK — GitHub Releases
Git repoda yeni bir tag at:
```bash
git tag v1.0.0
git push origin v1.0.0
```
GitHub Actions otomatik olarak APK'yi Release'e yükler. Kullanıcılar APK'yı indirip yükleyebilir.

### 3. itch.io (indie oyun mağazası)
- itch.io'da hesap aç.
- `store_listing/itch_io.md` içeriğini kopyala.
- APK ve web dosyalarını yükle, fiyat: **Free**.

### 4. F-Droid (açık kaynak Android mağazası)
- Repoya bir `LICENSE` dosyası ekle (MIT/GPL).
- `fastlane/F-Droid.md` içindeki metadata şablonunu kullan.
- https://gitlab.com/fdroid/fdroiddata 'ye MR gönder.

### Önemli Notlar
- Google Play (25$) ve App Store (99$/yıl) ücretlidir.
- GitHub Actions workflow için repo **public** olmalıdır.
- `YOUR_USERNAME` yerine kendi GitHub kullanıcı adını yaz.

## İçerik kuralları (önemli)

- **Sahte Çeçence asla yazılmaz.** Bulmaca kelimeleri ve kelime açıklamaları
  yalnĴzca doğrulanmış gerçek Çeçencedir.
- Arayüz metinleri şimdilik Türkçe yer tutucudur (`assets/i18n/ce.json`).
  Gerçek Çeçence çeviriler hazır olduğunda yalnızca bu dosya güncellenir.
  Bir anahtarın karşılığı yoksa ekranda anahtarın kendisi görünür.
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
