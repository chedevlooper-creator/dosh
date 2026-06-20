#!/bin/bash
# Дош — güvenli git senkronizasyonu. Çıktı: git_log.txt
# Sıra: yerel işi commit'le -> rebase'li pull -> push.
# Çakışma olursa rebase iptal edilir ve rapor edilir (hiçbir şey kaybolmaz).
cd "/Users/isahamid/adsız klasör 2" || exit 1

{
  echo "=== 1/4 Durum ==="
  git status --short
  echo ""

  echo "=== 2/4 Yerel işi commit'le ==="
  git add -A
  if git diff --cached --quiet; then
    echo "Commit'lenecek değişiklik yok."
  else
    git commit -m "Oyun: ana ekran, Çeçen grafem motoru, görsel katman, testler

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
  fi
  echo ""

  echo "=== 3/4 Uzaktan al (rebase) ==="
  if git pull --rebase --allow-unrelated-histories origin main; then
    echo "Pull başarılı."
  else
    echo "PULL ÇAKIŞMASI — rebase iptal ediliyor (yerel commit güvende):"
    git status --short
    git rebase --abort 2>/dev/null
  fi
  echo ""

  echo "=== 4/4 Gönder ==="
  git push -u origin main || echo "PUSH BAŞARISIZ (yetki/ağ?) — yerel commit güvende."
  echo ""
  echo "=== BİTTİ ==="
  git log --oneline -5
} 2>&1 | tee git_log.txt
