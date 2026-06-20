# Дош (Dosh) — Geliştirme Spesifikasyonu

> **Hazırlanma tarihi:** 11 Haziran 2026  
> **Proje:** Çeçence kelime bulmaca oyunu (Words of Wonders tarzı)  
> **Platform:** Flutter — Android, iOS, Windows (her biri eşit öncelikli)  
> **Para modeli:** Tamamen ücretsiz  
> **Hedef kitle:** Çeçen diasporası (Türkçe konuşan)  

---

## 1. Vizyon ve Strateji

### 1.1 Amaç

Çeçen diasporası için zengin, eğlenceli ve eğitici bir kelime bulmaca deneyimi sunmak. Oyun tamamen ücretsiz kalacak, hiçbir para kazanma mekanizması eklenmeyecek.

### 1.2 Öncelik

**İçerik zenginleştirme** en yüksek öncelik:
- Yeni seviyeler (mevcut 14 → 40-50 seviye)
- Mevcut seviyelere bonus kelimeler
- Türkçe kelime açıklamaları (info_ anahtarları)

---

## 2. Dil ve Yerelleştirme

### 2.1 Arayüz Dili

| Bileşen | Dil | Açıklama |
|---------|-----|----------|
| Butonlar, menüler, UI metinleri | **Türkçe** | `assets/i18n/tr.json` yeni dosya |
| Bulmaca kelimeleri | **Çeçence (Cyrillic)** | Değişmez, gerçek Çeçence |
| Kelime açıklamaları | **Türkçe** | `info_` anahtarları Türkçe doldurulacak |

### 2.2 Dosya Yapısı

```
assets/i18n/
  tr.json      # YENİ: Türkçe UI (buton, menü, başlık, mesaj)
  ce.json      # MEVCUT: Çeçence içerik anahtarları (şimdilik kalabilir, legacy)
```

- `Strings.t()` metodu, `TR/ce.json` yerine `tr.json`'ı yükleyecek şekilde güncellenecek.
- `ce.json` eski sürüm uyumluluğu için korunabilir veya içeriği `tr.json`'a taşınır.

### 2.3 Türkçe Çeviri Anahtarları (tr.json için tahmini liste)

Anahtarların çoğu zaten kullanılıyor — yalnızca değerler Türkçeleştirilecek:

| Anahtar | Türkçe (öneri) |
|---------|----------------|
| `app_title` | "Dosh" |
| `start` | "Başla" |
| `sound` | "Ses" |
| `home_subtitle` | "Çeçence Kelime" |
| `level_progress` | "İlerleme" |
| `level_N` | "Seviye N" |
| `level_complete` | "Tebrikler!" |
| `continue` | "Devam Et" |
| `hint_reveal` | "Harfi Göster" |
| `hint_cell` | "Hücreyi Aç" |
| `hint_solve` | "Kelimeyi Çöz" |
| `coins` | "Altın" |
| `shuffle` | "Karıştır" |
| `back` | "Geri" |
| `settings` | "Ayarlar" |
| `stats` | "İstatistikler" |
| `all_done` | "Tüm seviyeler tamamlandı! 🎉" |
| `bonus_found` | "Bonus kelime bulundu!" |
| `daily_gift` | "Günlük Hediye" |
| `streak` | "Seri" |
| `best_streak` | "En İyi Seri" |
| `hint_cost` | "Maliyet: N coin" |
| `confirm_hint` | "N coin harcansın mı?" |
| `seconds` | "saniye" |
| `today` | "Bugün" |

---

## 3. İçerik Artışı

### 3.1 Seviye Sayısı

| Durum | Sayı |
|-------|------|
| Mevcut | 14 seviye |
| Hedef | **40-50 seviye** (~30+ yeni) |
| Yeni seviye kaynağı | **Kullanıcı tarafından sağlanacak** Çeçence kelime listeleri |

### 3.2 Seviye Yapısı (Korunacak)

Her seviye şunları içerir:
- Çark harfleri (`letters`: 4-16 arası)
- Izgara kelimeleri (`words`: en az 2 kelime, ızgarada yerleşimli)
- Bonus kelimeler (`bonus`: mevcut seviyelere 1-3, yenilere 1-3)
- `Level.validate()` tüm içerik tutarlılığını otomatik kontrol eder (testlerde)

### 3.3 Bonus Kelimeler

- Mevcut 14 seviyenin **her birine** 1-3 bonus kelime eklenecek
- Yeni seviyelere de 1-3 bonus kelime
- Bonus kelime ödülü: +10 coin (sabit)
- Bonus kelimeler ızgarayı değiştirmez, sadece çark harflerinden kurulabilir olmalıdır

### 3.4 Kelime Açıklamaları (Türkçe)

- Her seviyedeki her kelime için `info_<kelime>` anahtarı **Türkçe açıklama** ile doldurulacak
- Açıklamalar: kelimenin anlamı, varsa kısa kültürel not
- Örnek: `"info_малх": "Güneş"` veya `"info_бӏаьрг": "Göz"`

---

## 4. Yeni Özellikler

### 4.1 Seviye Haritası (Manzara Üzerinde Yol)

**Mevcut durum:** Oyuncu kaldığı seviyeden devam eder, seviye seçme ekranı yoktur.

**Hedef:** Ana ekrana bir seviye haritası eklenmesi.

**Tasarım prensipleri:**
- Mevcut manzara (dağ/kule) arka planı **korunacak**, harita üzerine bindirilecek
- Kıvrımlı bir patika/rota üzerinde her durak bir seviye (40-50 durak)
- Tamamlanan seviyeler altın renkli, kilitli olanlar gri/koyu
- Oyuncu tıklayarak dilediği tamamlanmış seviyeye gidebilir
- Kilitli seviyeler gösterilir ancak tıklanamaz
- Mevcut oynanabilir seviye bir ok/pulse ile vurgulanır

**Scroll davranışı:**
- Ekran büyüklüğüne göre kaydırılabilir (yatay veya dikey)
- Çok sayıda seviyede performans için `ListView` veya `CustomScrollView`

**Bileşenler:**
- `LevelMapScreen` — yeni ekran (veya ana ekranın içinde bir mod)
- `PathPainter` — vektör çizim rotası (`CustomPainter`)
- `LevelNode` widget — her seviye durağı (daire, yıldız, kilit simgesi)

### 4.2 İpucu Sistemi (3 Kademeli)

**Mevcut durum:** Tek tür ipucu — rastgele bir hücre açar (25 coin).

**Hedef:** 3 kademeli ipucu sistemi:

| Kademe | İşlem | Maliyet | Açıklama |
|--------|-------|---------|----------|
| 1 | **Bir harfi göster** | 10 coin | Rastgele bir çözülmemiş kelimenin bir harfini (hücrede) gösterir |
| 2 | **Bir hücre aç** | 25 coin | Mevcut sistemin aynısı |
| 3 | **Kelimeyi çöz** | 50 coin | Rastgele bir çözülmemiş kelimenin tamamını çözer (coin verilmez) |

**Mantıksal kısıtlar:**
- Kademe 1-3: coin yeterliyse kullanılabilir
- Kademe 3: çözülmemiş kelime varsa kullanılabilir
- İpucu kullanımı **seriyi sıfırlar** (streak = 0)
- İpucuyla çözülen kelime **coin ödülü vermez**
- Her ipucu kullanımı `hintsUsed` sayacını artırır (performans yıldızını etkiler)

**UI değişiklikleri:**
- İpucu butonu tıklandığında bir seçim menüsü (popup/bottomsheet) açılir
- Her seçeneğin maliyeti ve etkisi gösterilir
- İpucu butonunda rozet: varsayılan "25" yerine "10/25/50" veya en düşük maliyetli kademe gösterilebilir

### 4.3 Profil / İstatistik Ekranı

**Hedef:** Oyuncunun genel başarılarını gösteren bir ekran.

**İstatistikler:**
| Metrik | Kaynak | Açıklama |
|--------|--------|----------|
| Toplam coin | `store.coins` | Mevcut |
| Çözülen toplam kelime | Yeni sayaç | Tüm seviyelerdeki çözülen benzersiz kelimeler |
| En iyi seri (streak) | Yeni sayaç | Tüm zamanların en yüksek serisi |
| Tamamlanan seviye sayısı | `store.levelIndex` baz alınarak | Kaç seviye bitirilmiş |
| Toplam ipucu kullanımı | Yeni sayaç | Oyun boyunca kaç ipucu kullanılmış |
| Toplam yanlış deneme | Yeni sayaç | Oyun boyunca kaç yanlış kelime denenmiş |

**UI:**
- Ana ekranda bir "İstatistikler" butonu (küçük bir ikon)
- Açılan panel/kart: basit, temiz, kartvizit tarzı
- Metrikler simgelerle birlikte gösterilir

### 4.4 Oyun Döngüsü Değişikliği

**Mevcut durum:** Son seviyeden sonra 1. seviyeye döner (`% levels.length`).

**Hedef:** Sıralı oyun:
- Son seviye tamamlandığında "Tüm seviyeler tamamlandı! 🎉" mesajı
- Oyuncu ana ekrana döner
- Dilediği tamamlanmış seviyeyi (haritadan) tekrar oynayabilir
- Tekrar oynanan seviyelerde coin kazanılabilir (mevcut mekanik korunur)

---

## 5. Seviye Haritası Detaylı Tasarım

### 5.1 Ekran Akışı (Güncellenmiş)

```
Ana Ekran (HomeScreen)
  ├── Üst: ses butonu, günlük hediye, coin göstergesi
  ├── Orta: logo "Дош" + "Çeçence Kelime"
  ├── Alt: Seviye Haritası butonu (veya doğrudan harita)
  └── Alt: Başla butonu (mevcut seviyeye gider)

Seviye Haritası (LevelMapScreen) [YENİ]
  ├── Manzara üzerinde patika rotası
  ├── 40-50 seviye düğümü
  └── Her düğüm: tamamlandı (altın) / kilitli (gri) / aktif (pulse)

Oyun Ekranı (GameScreen)
  └── Değişiklik: 3 kademeli ipucu menüsü

Bölüm Tamamlama Paneli (LevelCompletePanel)
  └── Mevcut panel + "Harita" butonu

Profil/İstatistik (StatsPanel) [YENİ]
  └── Ana ekrandan erişilebilir
```

### 5.2 Patika Rotası

Patika, haritanın sol altından başlayıp sağ üste doğru kıvrılarak ilerler:

```
[Rota]  14 ── 15 ── 16 ... ── 40
         │                      
        13                      
         │                      
   7 ── 8 ── 9 ── 10 ── 11 ── 12
   │                            
   6                            
   │                            
   1 ── 2 ── 3 ── 4 ── 5       
         (başlangıç)            
```

- Tamamlanan seviyeler: altın parlayan daire
- Aktif seviye: büyük, nabız atan daire (üzerinde ok)
- Kilitli: küçük, koyu, kilit simgesi
- Her seviye düğümünün yanında küçük bir numara

---

## 6. Ekonomi ve Oyun İçi Metrikler

### 6.1 Mevcut (Korunacak)

| Parametre | Değer |
|-----------|-------|
| Başlangıç coini | 100 |
| İpucu maliyeti (hücre aç) | 25 |
| Harf başına kazanç | 5 |
| Bonus kelime | 10 |
| Günlük hediye | 100 |
| Kombo eşiği | 3 doğru |
| Kombo bonusu | 15 |

### 6.2 Yeni (Eklenecek)

| Parametre | Değer |
|-----------|-------|
| İpucu — harf göster | 10 coin |
| İpucu — kelime çöz | 50 coin |

---

## 7. Dosya Değişiklik Listesi

### 7.1 Yeni Dosyalar

| # | Dosya | Açıklama |
|---|-------|----------|
| 1 | `assets/i18n/tr.json` | Türkçe UI metinleri |
| 2 | `lib/ui/screens/level_map_screen.dart` | Seviye haritası ekranı |
| 3 | `lib/ui/widgets/level_map_path.dart` | Patika rotası çizimi (CustomPainter) |
| 4 | `lib/ui/widgets/level_node.dart` | Seviye düğümü widget'ı |
| 5 | `lib/ui/widgets/hint_menu.dart` | 3 kademeli ipucu menüsü |
| 6 | `lib/ui/widgets/stats_panel.dart` | İstatistik paneli |
| 7 | `lib/data/stats_store.dart` | İstatistik kalıcı saklama |

### 7.2 Değiştirilecek Dosyalar

| # | Dosya | Değişiklik |
|---|-------|------------|
| 1 | `lib/core/strings.dart` | tr.json yükleme mantığı |
| 2 | `lib/core/constants.dart` | Yeni ipucu maliyet sabitleri |
| 3 | `lib/data/progress_store.dart` | İstatistik sayaçları için kalıcı alanlar |
| 4 | `lib/game/game_controller.dart` | 3 kademeli ipucu, istatistik takibi |
| 5 | `lib/ui/screens/home_screen.dart` | Harita + istatistik butonları, seviye listesi yerine harita |
| 6 | `lib/ui/screens/game_screen.dart` | İpucu menüsü entegrasyonu |
| 7 | `lib/ui/widgets/level_complete_panel.dart` | "Harita" butonu |
| 8 | `lib/app.dart` | Yeni ekran rotaları |
| 9 | `assets/i18n/ce.json` | info_ anahtarları Türkçe açıklamalarla doldurulacak (veya tr.json'a taşınacak) |
| 10 | `assets/levels/levels.json` | Bonus kelimeler + yeni seviyeler |
| 11 | `pubspec.yaml` | tr.json asset kaydı |

---

## 8. Uygulama Sırası (Önerilen)

| Aşama | İş | Bağımlılık |
|-------|----|------------|
| **1** | tr.json oluştur + Strings yükleme mantığını TR'ye çevir | Yok |
| **2** | Mevcut 14 seviyeye bonus kelimeler ekle | Aşama 1 |
| **3** | Mevcut 14 seviyeye info_ Türkçe açıklamaları ekle | Aşama 1 |
| **4** | 3 kademeli ipucu (constants + game_controller + hint_menu) | Yok |
| **5** | İpucu menüsü UI (hint_menu.dart) + game_screen entegrasyonu | Aşama 4 |
| **6** | Seviye haritası (level_map_screen, path, node) | Yok |
| **7** | Anasayfa + harita + oyun arası geçişler | Aşama 6 |
| **8** | Oyun döngüsü: sıralı final mesajı | Yok |
| **9** | İstatistik sistemi (stats_store + stats_panel) | Aşama 4 (sayaçlar) |
| **10** | ~30+ yeni seviye ekle | Kullanıcı kelime listesini sağlamalı |
| **11** | Son test, analiz, ve görsel doğrulama | Tüm aşamalar |

---

## 9. Test Stratejisi

Her aşamada aşağıdakiler çalıştırılmalıdır:
- `flutter analyze` — statik analiz
- `flutter test` — mevcut testler + aşamaya özgü yeni testler
- Seviye validasyon testi (`levels_test.dart`) — yeni seviyeler için otomatik çalışır
- Widget testleri (`widget_test.dart`) — yeni ekranlar için güncellenmeli

---

## 10. Kullanıcı Tarafından Sağlanacak İçerik

- Çeçence kelime listeleri (yeni seviyeler için)
- Kelimelerin kategorileri/grupları (varsa)
- Varsa özel seviye tasarımı fikirleri (örn. "aile üyeleri", "hayvanlar" gibi tematik seviyeler)

---

## 11. Açık Sorular / Karar Bekleyenler

- [ ] Yeni seviyeler için kelime listesi **kullanıcı tarafından sağlanacak**
- [ ] İstatistiklerde "toplam çözülen kelime" geriye dönük (backfill) olarak mı hesaplansın, yoksa sadece yeni kayıtlardan mı başlasın? *(Cevap: sadece yeni kayıtlardan)*
- [ ] Seviye haritası ana ekrana mı entegre olsun yoksa ayrı bir ekran mı? *(Öneri: ayrı bir ekran, ana ekrandan butonla erişim)*
- [ ] Günlük hediye miktarı (100 coin) artsın mı? *(Şimdilik değişmesin)*
