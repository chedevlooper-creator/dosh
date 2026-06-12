# Дош (Dosh) — Oyun Geliştirme Spesifikasyonu

> **Proje:** Дош — Çeçence kelime bulmaca oyunu (Words of Wonders tarzı)
> **Hedef platformlar:** Android, iOS, Windows (web yalnızca geliştirme/preview)
> **Hedef kitle:** Türkçe konuşup Çeçence öğrenmek isteyenler
> **Yayın planı:** App Store / Google Play'de yayınlanacak
> **Gelir modeli:** Tamamen ücretsiz, reklam veya satın alma yok
> **Güncelleme:** 12 Haziran 2026 — Kullanıcı onayı ile son hal

---

## 1. İçerik Geliştirmeleri

### 1.1 Seviye Sayısı Artırımı (20 → 30)

**Mevcut durum:** 20 seviye, 60 benzersiz kelime.
**Hedef:** 30 seviye — mevcut 20 seviye **korunacak**, üzerine **10 yeni seviye** eklenecek.

**Yaklaşım:**
- Mevcut `levels.json`'daki 20 seviye aynen kalır
- Seviye id'leri 21-30 arası yeni seviyeler eklenir
- Yeni seviyeler mevcut wordlist'lerden oluşturulacak

**Mevcut kelime kaynakları:**
- `cechen_curated_for_game.txt` — 223 adet oyuna uygun, kategorize edilmiş kelime (2-6 graphemes)
- `cechen_full_wordlist.txt` — 1218 kelime (tüm liste)
- `cechen_words_master.txt` — 658 yeni benzersiz kelime (oyundaki 60 hariç)
- `cechen_new_words_from_web.txt` — Web'den toplanmış 200 yeni kelime
- `bonus_candidates.json` — Mevcut 20 seviye için bonus kelime adayları

**Seviye oluşturma kuralları:**
- Her seviye 2-8 harfli bir çark + 2-5 kelime (ızgara düzeninde)
- Kelimeler 2-6 grapheme uzunluğunda
- Digraflar (аь, гӀ, кх, тӀ, хь, цӀ, vb.) tek harf sayılır
- Tüm kelimeler gerçek Çeçence (uydurma asla)
- Seviyeler kademeli zorluk: ilk seviyeler kısa kelimeler, ilerledikçe uzar
- Her seviyede 2-8 bonus kelime (çark harflerinden kurulabilen ekstra kelimeler)
- `validate()` tüm tutarlılık kontrollerini yapacak (kesişim çakışması, harf mevcudiyeti)

### 1.2 Kelime Anlamları / Sözlük

**Mevcut durum:** `ce.json`'da `info_*` anahtarları tamamen boş. Bilgi şeridi hiçbir zaman görünmüyor.

**Hedef:**
- `assets/i18n/ce.json` dosyasına her kelime için `info_<word>` anahtarı eklenecek
- Anlamlar Türkçe olacak (hedef kitle Türkçe konuşanlar)
- Kaynak: `cechen_curated_for_game.txt` içindeki kategoriler ve anlamlar
- `english_terms.json` İngilizce karşılıklardan referans alınacak

**Sözlük özelliği (oyun içi):**
- Oyuncunun çözdüğü kelimelerin anlamlarını gösteren bir bölüm (seviye bazlı)
- Galeri ekranında "📖 Sözlük" butonu
- Çözülen kelimeler ilerledikçe sözlük otomatik genişler
- Her kelime: Çeçence yazılışı + Türkçe anlamı + (varsa) kategorisi

### 1.3 Bonus Kelime Sistemi (Geliştirme)

**Mevcut durum:** 20 seviyede bonus kelimeler tanımlanmış ama `ce.json`'da hiçbir `info_*` anahtarı yok.

**Hedef:**
- Tüm bonus kelimelere (mevcut + yeni) `info_<word>` anahtarları eklenecek
- Yeni seviyeler için bonus kelime havuzu oluşturulacak
- Bonus kelime bulma görsel geri bildirimi mevcut haliyle korunacak

---

## 2. Kullanıcı Deneyimi (UX) Geliştirmeleri

### 2.1 Tutorial — Ayrı Tutorial Seviyesi (id=0)

**Mevcut durum:** Hiçbir eğitim/yönlendirme yok. Oyuncu oyuna atılıyor.

**Hedef — Ayrı bir tutorial seviyesi (id=0):**
- Seviye listesinin başında (id=0) özel bir tutorial seviyesi
- Bitince Seviye 1 otomatik açılır
- Adım adım interaktif rehberlik:
  1. Karşılama mesajı: "Hoş geldin! Çarktaki harfleri sürükleyerek kelime oluştur."
  2. Çark vurgusu: Çarkın etrafında parlayan hale, "Parmağını burada sürükle"
  3. İlk kelime için harflere sürükleme yönlendirmesi (ok + "Şu harfleri birleştir")
  4. Başarılı çözüm sonrası: "Tebrikler! Şimdi diğer kelimeleri bul."
  5. İpucu butonu tanıtımı: "Takılırsan bu butonu kullan (25 coin)"
  6. Karıştırma butonu tanıtımı: "Harfleri karıştırmak için bu butonu kullan"
  7. Seviye tamamlama: "Seviyeyi geçtin! Star kazandın⭐"

**Teknik yaklaşım:**
- `Level` modeline `isTutorial: bool` alanı eklenebilir
- `GameScreen`'de `tutorialMode` state'i
- Tutorial override'ları: ipucu ücretsiz, karıştırma vurgulu
- `ProgressStore`'a `tutorialDone` flag'i (sadece ilk açılışta)
- İleride "Nasıl Oynanır" butonuyla tutorial'a tekrar erişim

### 2.2 Seviye Kilitleme Sistemi

**Mevcut durum:** Galeri ekranında tüm seviyeler açık. Oyuncu istediği seviyeyi seçebiliyor.

**Hedef — Sıralı kilit sistemi:**
- Tutorial (id=0) her zaman açık
- Seviye 1, tutorial bitince açılır
- Sonraki her seviye ancak bir önceki tamamlanınca açılır
- Tamamlanan seviyeler tekrar oynanabilir (en yüksek yıldız korunur)
- Galeride kilitli seviyeler: 🔒 kilit ikonu + gri rozet
- `store.levelIndex` referans alınarak "son açılan seviye" belirlenir
- Kilitli seviyeye tıklayınca: "Önceki seviyeyi tamamla" mesajı

### 2.3 Birden Fazla Tema (3 Tema — Seçilebilir)

**Mevcut durum:** Tek bir Kafkas dağ manzarası (`caucasus.png`, dosya eksik).

**Hedef — 3 seçilebilir tema:**
1. **🏔️ Kafkas Dağları** (mevcut, vektöre dönüştürülecek) — Altın saat, dağ + kule görseli
2. **🌙 Gece** — Koyu mavi gece, yıldızlar, hilal
3. **🌲 Orman** — Yeşil tonlar, çam ağaçları, akarsu

**Teknik yaklaşım:**
- `caucasus.png` kaldırılacak, `CustomPainter` tabanlı vektör çizime geçilecek
- `ScenicBackground` widget'ı parametrik: `theme: GameTheme` alacak
- Her tema için ayrı `CustomPainter` sınıfı
- `AppColors` paleti temaya göre değişecek (en azından arka plan renkleri)
- Tema tercihi `ProgressStore`'a kaydedilecek
- Ana ekranda / ayarlarda tema değiştirme butonu
- Varsayılan tema: Kafkas Dağları

### 2.4 Ayarlar Ekranı

**Mevcut durum:** Sadece ses açma/kapama butonu (top bar ve home screen'de).

**Hedef — Kapsamlı ayarlar:**
- Ses açma/kapama (mevcut)
- Tema seçimi (3 tema arasından)
- "Nasıl Oynanır" butonu (tutorial tekrarı)
- Oyun sıfırlama (onay dialog'u ile — tüm ilerlemeyi sil)

---

## 3. Yeni Oyun Mekanikleri (Öncelik Sırasına Göre)

### 3.1 Günlük Challenge (En Yüksek Öncelik)

**Mevcut durum:** Yok.

**Hedef:**
- Her gün mevcut 30 seviyeden 1'i rastgele seçilir (henüz tamamlanmamış olsa bile)
- Bonus coin ödülü (ör. 50 coin) — günde bir kez
- Her gün sıfırlanır (yerel saat bazlı, `epochDay` mantığı mevcut — `giftAvailable` benzeri)
- `ProgressStore`'a `challengeDate` + `challengeLevelId` kaydı
- Ana ekranda özel bir "🎯 Günlük Challenge" kartı
- Tamamlanınca ayrı bir kutlama animasyonu

### 3.2 İstatistikler

**Mevcut durum:** Hiçbir istatistik toplanmıyor.

**Hedef — Detaylı oyuncu istatistikleri:**
- Toplam çözülen kelime (ana + bonus ayrı)
- Toplam kazanılan coin
- Toplam harcanan coin (ipucu)
- En yüksek streak
- Toplam ipucu kullanımı
- Yıldız dağılımı (kaç tane 3⭐, 2⭐, 1⭐)
- Toplam tamamlanan seviye
- Galeri ekranında "📊 İstatistikler" butonu

**Saklama:**
- `ProgressStore`'a yeni stat alanları eklenecek

### 3.3 Kelime Sözlüğü

(Bkz. Madde 1.2)
- Galeriden "📖 Sözlük" butonu ile erişim
- Seviye bazlı veya alfabetik liste
- Her kelime: Çeçence + Türkçe anlam + kategori
- Sadece çözülen kelimeler görünür

### 3.4 Liderlik Tablosu (Yerel)

**Mevcut durum:** Yok.

**Hedef — Yerel (offline) liderlik:**
- Oyuncunun kendi rekorları: en yüksek streak, en hızlı seviye tamamlama
- Cihazda yerel "kendine karşı yarış"
- İleride (opsiyonel) Game Center / Google Play Games entegrasyonu

---

## 4. Teknik İyileştirmeler

### 4.1 caucasus.png → Vektör Çizim Dönüşümü

**Mevcut sorun:** `assets/backgrounds/caucasus.png` dosyası mevcut değil. `scenic_background.dart` referans veriyor, `errorBuilder` sayesinde oyun çökmüyor ama görsel yok.

**Yapılacak:**
- `ScenicBackground` widget'ı `Image.asset` yerine `CustomPainter` tabanlı vektör çizime dönüştürülecek
- Mevcut `assets/backgrounds/` dizini ve `pubspec.yaml` referansı temizlenecek
- Vektör çizim: dağ siluetleri, kule, gökyüzü gradyanı — mevcut `home_screen.dart`'daki `_MountainOutlinePainter` benzeri yaklaşım
- Her tema için ayrı `CustomPainter` sınıfı
- Not: Android/iOS asset sorunu da böylece tamamen çözülmüş olur

### 4.2 Hata Yönetimi

**Mevcut durum:** Sadece `_Bootstrap`'ta hata ekranı var.

**Hedef:**
- `GameController`'da kritik hata durumları için try-catch
- `debugPrint` kullanımı korunacak (yayın öncesi loglama)

### 4.3 Performans

**Mevcut iyi uygulamalar korunacak:**
- Granüler `ValueNotifier`'lar (coins, streak, selection)
- `RepaintBoundary` kullanımı
- `AnimatedBuilder` ile optimize yeniden çizim

### 4.4 Test Geliştirmeleri

**Mevcut durum:** 6 test dosyası, kapsamlı controller testleri.

**Hedef:**
- Yeni seviyeler için test (validation)
- Tutorial için widget testleri
- Günlük challenge için birim testleri
- Tema değiştirme için widget testleri
- Seviye kilit sistemi için testler

---

## 5. Uygulama Fazları (Güncellenmiş)

### Faz 1 — İçerik (Yüksek Öncelik)
1. `caucasus.png`'yi vektör `CustomPainter`'a dönüştür
2. 10 yeni seviye oluştur (mevcut wordlist'lerden, id:21-30)
3. `ce.json`'a info_* ve yeni level_* anahtarlarını ekle
4. Seviye kilit sistemini ekle (sıralı kilit)

### Faz 2 — Kullanıcı Deneyimi (Orta Öncelik)
5. Tutorial seviyesi (id=0) — ayrı, interaktif
6. Ayarlar ekranı (ses + tema + sıfırlama + nasıl oynanır)
7. 3 temayı tamamla (Gece + Orman vektör çizimleri)

### Faz 3 — Yeni Mekanikler (Orta Öncelik)
8. Günlük challenge (mevcut seviyelerden rastgele)
9. İstatistikler
10. Kelime sözlüğü (Türkçe anlamlarla)
11. Liderlik tablosu (yerel)

### Faz 4 — Yayın Hazırlığı (Düşük Öncelik)
12. Uygulama ikonu (özel Çeçen motifli)
13. Splash screen
14. App Store / Google Play listing metinleri
15. Hata raporlama (opsiyonel)

---

## 6. Mevcut Kod Yapısı Referansı

```
lib/
  app.dart                          # Ekran yöneticisi (Home ↔ Gallery ↔ Game)
  main.dart                         # Bootstrap: asset yükleme, orientation lock
  core/
    constants.dart                  # Oyun sabitleri (coin, hint, pricing)
    graphemes.dart                  # Çeçence grafem tokenizer + normalize
    scoring.dart                    # Puanlama kuralları (saf fonksiyonlar)
    strings.dart                    # İ18n (key → Çeçence)
  data/
    models.dart                     # Cell, PlacedWord, Level (+ JSON + validate)
    level_repository.dart           # Seviye yükleme + doğrulama
    progress_store.dart             # SharedPreferences ile kalıcılık
  game/
    game_controller.dart            # Oyun motoru (seçim, çözüm, ipucu, karıştırma)
  audio/
    game_sound.dart                 # Ses yönetimi (6 efekt + ambience)
  ui/
    screens/
      home_screen.dart              # Ana ekran (manzara, başlık, seviye durumu)
      gallery_screen.dart           # Galeri (tüm seviyeler, yıldızlar, kilit)
      game_screen.dart              # Oyun ekranı (çark, ızgaralı bulmaca)
    theme.dart                      # AppColors, AppText, AppMotion, ThemeData
    widgets/
      letter_wheel.dart             # Harf çarkı (sürükle-seç, shuffle animasyonu)
      crossword_grid.dart           # Crossword ızgarası (hücreler, pop-in)
      word_capsule.dart             # Seçim kapsülü (sallanma, başarı, bonus)
      coin_box.dart                 # Coin kutusu (+N animasyonu)
      info_strip.dart               # Kelime bilgi şeridi
      top_bar.dart                  # Üst bar (geri, başlık, ses)
      round_icon_button.dart        # Yuvarlak buton (hover, pulse, rozet)
      scenic_background.dart        # Vektör tabanlı arka plan (3 tema)
      level_complete_panel.dart     # Seviye tamamlama paneli
      effects/confetti_burst.dart   # Konfeti efekti
```

---

## 7. Veri Modeli Değişiklikleri

### ProgressStore'a eklenecekler:

```dart
// Seviye kilidi için
int lastUnlockedLevel();

// Tema tercihi
static const _kTheme = 'theme';
int get themeIndex;
Future<void> setThemeIndex(int value);

// İstatistikler
static const _kTotalWords = 'stat_total_words';
static const _kTotalBonus = 'stat_total_bonus';
static const _kTotalCoinsEarned = 'stat_coins_earned';
static const _kTotalHintsUsed = 'stat_hints_used';
static const _kTotalLevelsCompleted = 'stat_levels_done';
static const _kBestStreak = 'stat_best_streak';

// Tutorial
static const _kTutorialDone = 'tutorial_done';
bool get tutorialDone;
Future<void> setTutorialDone(bool value);

// Günlük challenge
static const _kChallengeDate = 'challenge_date';
static const _kChallengeLevel = 'challenge_level';
bool challengeAvailable(DateTime now);
int? challengeLevelId(DateTime now);
Future<void> markChallengeDone(DateTime now);
```

### Tema Veri Modeli

```dart
enum GameTheme {
  caucasus,   // 🏔️ Kafkas Dağları (varsayılan)
  night,      // 🌙 Gece
  forest,     // 🌲 Orman
}
```

### Level Modeli'ne eklenecek:

```dart
class Level {
  // ... mevcut alanlar
  final bool isTutorial;  // tutorial seviyesi mi?
}
```

---

## 8. İçerik Planı — 30 Seviye

### Kaynak wordlist'ler

| Kaynak | Kelime Sayısı | Kullanım |
|--------|---------------|----------|
| Mevcut 20 seviye (levels.json) | ~60 | Korunacak |
| Yeni seviyeler için havuz | 223+ (curated) + 658 (master) + 200 (web) | Yeni 10 seviye |

### Zorluk eğrisi

| Seviye Aralığı | Çark Harf Sayısı | Ortalama Kelime Uzunluğu | Kelime Sayısı |
|----------------|-------------------|-------------------------|---------------|
| Tutorial (id=0) | 3 | 2 grapheme | 2 |
| 1-10 (başlangıç) | 3-5 | 2-3 grapheme | 2-3 |
| 11-20 (orta) | 5-8 | 3-4 grapheme | 3-4 |
| 21-30 (ileri) | 6-10 | 4-5 grapheme | 4-5 |

---

## 9. i18n (ce.json) Genişletme Planı

Mevcut anahtarlar + eklenecekler:

```json
{
  "app_title": "Дош",
  "start": "ДӀадоладе",
  "sound": "Аз",
  "home_subtitle": "Нохчийн дош",
  "level_1"..."level_30": "1"..."30",
  "level_complete": "Декъал!",
  "continue": "Кхин дӀа",
  
  "gallery": "Галерей",
  "settings": "Нисдарш",
  "dictionary": "Дешнийн",
  "statistics": "Статистика",
  "daily_challenge": "ХӀора дийнахьа",
  "how_to_play": "Ловзар",
  "level_locked": "ТӀекхача",
  "theme": "Кеп",
  "reset_progress": "Юхадаккха",
  "reset_confirm": "Бакъ дуй?",
  "stars": "Седа",
  "words_solved": "Кхочушдина дешнаш",
  "best_streak": "Уггаре дукха",
  
  // info_* anahtarları — her kelime için
  "info_малх": "Güneş",
  "info_лам": "Dağ",
  // ... tüm yeni seviye kelimeleri
}
```

---

## 10. Zaman Tahmini

| Faz | Tahmini Süre | Bağımlılıklar |
|-----|-------------|---------------|
| **Faz 1 — İçerik** | **~2 gün** | Wordlist analizi |
| **Faz 2 — Kullanıcı Deneyimi** | **~2-3 gün** | Faz 1 tamamlanmalı |
| **Faz 3 — Yeni Mekanikler** | **~3-4 gün** | Faz 1-2 tamamlanmalı |
| **Faz 4 — Yayın Hazırlığı** | **~1 gün** | Tüm fazlar tamamlanmalı |
| **Toplam** | **~8-10 gün** | |

---

*Spec son güncelleme: 12 Haziran 2026 (kullanıcı onayı ile güncellendi)*
*Kararlar: 30 seviye, mevcut koru+ekle, vektör çizim, ayrı tutorial (id=0), 3 tema, önce günlük challenge, yayın hazırlığı dahil*
