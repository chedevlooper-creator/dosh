# Дош — Yayın Rehberi (Store Publishing)

Bu belge oyunu **Google Play**, **App Store** ve **Windows**'ta yayınlamak için
gereken her adımı içerir. Kodla ilgili tüm yayın hazırlıkları **tamamlandı**;
geriye kalan adımlar senin hesaplarını ve imza sertifikalarını gerektiren,
makinede yapılması gereken işlerdir.

---

## 0. ÖNCE BUNU OKU — İmza anahtarını KAYBETME

Android yükleme anahtarı oluşturuldu:

- **Anahtar deposu:** `android/app/upload-keystore.jks`
- **Ayar dosyası:** `android/key.properties`
- **Şifre / alias:** `key.properties` içinde (alias: `upload`, şifre: `Dosh!Upload2026`)

> ⚠️ **KRİTİK:** Bu iki dosya `.gitignore`'dadır, depoya **girmez** ve yalnızca
> bu bilgisayarda durur. **`upload-keystore.jks` dosyasını ve şifresini güvenli
> bir yere yedekle** (parola yöneticisi + harici disk/bulut). Bu anahtarı
> kaybedersen Google Play'de uygulamanı **bir daha asla güncelleyemezsin** —
> yeni bir uygulama olarak baştan yayınlaman gerekir. Şifreyi de
> `Dosh!Upload2026`'dan kendi güçlü şifrenle değiştirip `key.properties`'i
> güncellemen önerilir (anahtarı yeniden oluşturman gerekmez; sadece depo
> şifresini `keytool -storepasswd` ile değiştir).

`key.properties` veya `upload-keystore.jks` **yoksa** sürüm derlemesi otomatik
olarak debug anahtarına düşer (depo herkeste derlenir) ama o çıktı **mağazaya
yüklenemez**.

---

## 1. Kod tarafında YAPILANLAR (hazır)

| Konu | Durum |
|---|---|
| Sürüm numarası | `1.0.0+1` (pubspec.yaml) |
| Uygulama adı (tüm platformlar) | **Дош** (Android label, iOS CFBundleName, Windows başlık) |
| Android paket adı | `com.dosh.dosh` *(ilk yüklemeden önce değiştirilebilir — sonra sabit)* |
| Android release imzalama | ✅ `upload-keystore.jks` + `key.properties` ile yapılandırıldı |
| iOS yönelim | Yalnız portrait (Dart kilidiyle tutarlı) |
| iOS ihracat uyumu | `ITSAppUsesNonExemptEncryption=false` — yükleme sorusu atlanır |
| Uygulama ikonu / splash | Üretildi (Android adaptive, iOS, web, Windows .ico) |
| Gizlilik politikası | `GIZLILIK.md` — veri toplanmıyor (yereldeki ayarlar hariç) |
| Statik analiz | `flutter analyze` → 0 sorun |
| Testler | `flutter test` → 43/43 geçiyor |
| Windows release derlemesi | ✅ Başarılı (`build/windows/x64/runner/Release/dosh.exe`) |

---

## 2. Google Play (Android)

### 2.1 İmzalı AAB üret

Android SDK kurulu bir makinede (bu bilgisayarda Android SDK yok):

```bash
flutter build appbundle --release
# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

Anahtar deposu yerinde olduğundan AAB otomatik olarak yükleme anahtarıyla
imzalanır.

### 2.2 Play Console'da yapman gerekenler (senin hesabın)

1. [Google Play Console](https://play.google.com/console) hesabı (tek seferlik 25 USD).
2. Yeni uygulama oluştur → adı **Дош**, dil Türkçe.
3. **Play App Signing**'i aç (önerilir) — Google son imzayı yönetir, sen yükleme
   anahtarıyla yüklersin.
4. `app-release.aab` dosyasını **Internal testing**'e yükleyip kendi cihazında dene.
5. Mağaza kaydı (aşağıdaki §5 metinleri), ekran görüntüleri (§4), içerik
   derecelendirme anketi, hedef kitle, **gizlilik politikası URL'si** (§3) gir.
6. Production'a gönder.

> targetSdk Flutter 3.44 ile 35'tir (Play'in Ağustos 2025 şartını karşılar).

---

## 3. Gizlilik politikası (Play ZORUNLU)

`GIZLILIK.md` hazır ve doğru: oyun **hiçbir kişisel veri toplamaz**, internet
kullanmaz, reklam/analitik içermez; yalnız cihazda (SharedPreferences) ilerleme
ve ses ayarı saklar. Bunu bir URL'de yayınla (en kolayı):

- GitHub deposunda `GIZLILIK.md` → **GitHub Pages** veya ham dosya bağlantısı, ya da
- ücretsiz bir sayfa (Google Sites, Notion public page).

O URL'yi hem Play Console hem App Store Connect'e gir.

---

## 4. Ekran görüntüleri

`test/goldens/` altında gerçek render'lı görüntüler üretiliyor (1170×2532 —
6.5" telefon için uygun):

```bash
flutter test --dart-define=GOLDEN=true --update-goldens test/screenshot_test.dart
```

- **Play:** en az 2 telefon görüntüsü (16:9–9:16, min 320px). `home_mobile.png`,
  `game_mobile.png` doğrudan kullanılabilir. Ayrıca 512×512 uygulama ikonu
  (`web/icons/Icon-512.png`) ve 1024×500 öne çıkan görsel gerekir (tasarlanmalı).
- **App Store:** 6.5" (1284×2778) ve 5.5" setleri istenebilir; golden boyutlarını
  bu çözünürlüklere göre `screenshot_test.dart`'taki `physicalSize`'ı değiştirerek
  yeniden üret.

---

## 5. Mağaza metinleri (Türkçe — öneri)

**Uygulama adı:** Дош — Çeçence Kelime Bulmaca

**Kısa açıklama (80 karakter):**
Harf çarkını çevir, gerçek Çeçence kelimeleri keşfet. Ücretsiz, reklamsız.

**Tam açıklama:**
> Дош, Words of Wonders tarzı bir kelime bulmaca oyunudur — ama tamamen
> **Çeçence (Нохчийн мотт)**. Harf çarkındaki harfleri birleştirerek çengel
> bulmacayı doldur, her seviyede yeni kelimeler ve anlamları öğren.
>
> • 30+ özenle hazırlanmış seviye, kademeli zorluk
> • Çeçen digrafları (хь, кӀ, гӀ …) oyunda tek harf
> • Günlük görev, bonus kelimeler, kombo ödülleri, yıldız sistemi
> • Çözdüğün kelimelerin anlamlarıyla büyüyen sözlük
> • Tamamen **ücretsiz**, reklamsız, internet gerektirmez
>
> Tüm kelimeler doğrulanmış gerçek Çeçencedir — uydurma içerik yoktur.

---

## 6. App Store (iOS)

iOS derlemesi **macOS + Xcode** gerektirir (Windows'ta yapılamaz):

```bash
flutter build ipa --release
```

Senin yapman gerekenler:
1. [Apple Developer Program](https://developer.apple.com) üyeliği (yıllık 99 USD).
2. Xcode'da `ios/Runner.xcworkspace` → **Signing & Capabilities** → kendi
   **Team**'ini seç (otomatik imzalama).
3. Bundle id `com.dosh.dosh`'ı App Store Connect'te kaydet.
4. Archive → App Store Connect'e yükle, TestFlight'ta dene, mağaza kaydını
   doldur (§5 metinleri, §4 görüntüleri, §3 gizlilik URL'si), incelemeye gönder.

---

## 7. Windows

Çalışan sürüm derlemesi mevcut:

```bash
flutter build windows --release
# Çıktı: build/windows/x64/runner/Release/  (dosh.exe + DLL'ler)
```

- **Doğrudan dağıtım:** `Release` klasörünü zip'le veya bir kurulumcu
  (Inno Setup / MSIX) ile paketle.
- **Microsoft Store:** `msix` paketi gerekir. `dev_dependencies`'e `msix` ekleyip
  `msix_config` yazıp `dart run msix:create` çalıştır; mağaza için bir kod imzalama
  sertifikası gerekir. (Bu repoya henüz eklenmedi — opsiyonel.)

---

## 8. Yayın öncesi son kontrol listesi

- [ ] `upload-keystore.jks` + şifre **yedeklendi** (en kritik adım)
- [ ] `applicationId` (`com.dosh.dosh`) nihai mi? İlk yüklemeden sonra sabit
- [ ] `GIZLILIK.md` bir URL'de yayınlandı
- [ ] Ekran görüntüleri + 512px ikon + 1024×500 öne çıkan görsel hazır
- [ ] Internal/TestFlight testinde gerçek cihazda denendi
- [ ] İçerik derecelendirme + hedef kitle anketleri dolduruldu
- [ ] Her yeni sürümde `pubspec.yaml`'daki `+build` numarasını artır
