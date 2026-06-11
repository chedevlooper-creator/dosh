#!/bin/bash
# Дош — kurulum + doğrulama zinciri. Çıktı: setup_log.txt
FLUTTER=/Users/isahamid/development/flutter/bin/flutter
cd "/Users/isahamid/adsız klasör 2" || exit 1

{
  echo "=== 1/4 Font indirme (Noto Sans — tam Kiril + palochka Ӏ) ==="
  mkdir -p assets/fonts
  dl() {
    # $1: hedef dosya, $2..: aday URL'ler (ilki başarılı olana kadar dene)
    local out=$1; shift
    for url in "$@"; do
      if curl -fL --retry 2 --connect-timeout 15 -o "$out" "$url"; then
        echo "OK: $out  <=  $url"
        return 0
      fi
    done
    echo "UYARI: $out indirilemedi (analyze/test yine de çalışır; build için gerekir)"
    return 1
  }
  dl assets/fonts/NotoSans-Regular.ttf \
    "https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-Regular.ttf" \
    "https://raw.githubusercontent.com/googlefonts/noto-fonts/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf"
  dl assets/fonts/NotoSans-Bold.ttf \
    "https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-Bold.ttf" \
    "https://raw.githubusercontent.com/googlefonts/noto-fonts/main/hinted/ttf/NotoSans/NotoSans-Bold.ttf"
  ls -la assets/fonts/

  echo ""
  echo "=== 2/4 flutter pub get ==="
  "$FLUTTER" pub get

  echo ""
  echo "=== 3/4 flutter analyze ==="
  "$FLUTTER" analyze

  echo ""
  echo "=== 4/4 flutter test ==="
  "$FLUTTER" test

  echo ""
  echo "=== BİTTİ (çıkış kodları yukarıda) ==="
} 2>&1 | tee setup_log.txt
