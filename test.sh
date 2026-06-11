#!/bin/bash
# Дош — analyze + test; çıktı: test_log.txt
FLUTTER=/Users/isahamid/development/flutter/bin/flutter
cd "/Users/isahamid/adsız klasör 2" || exit 1
{
  echo "=== flutter analyze ==="
  "$FLUTTER" analyze
  echo ""
  echo "=== flutter test ==="
  "$FLUTTER" test
  echo ""
  echo "=== BİTTİ ==="
} 2>&1 | tee test_log.txt
