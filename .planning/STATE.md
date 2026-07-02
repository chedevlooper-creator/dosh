# STATE.md

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-17)

**Core value:** Players solve Chechen word puzzles in a polished, native-quality mobile game experience while naturally learning Chechen vocabulary.

## Current Status: Phase 7 Complete ✅

### Phase 6 — Content (Done)
- Levels 21-100 already integrated (101 total levels, IDs 0–100)
- Non-Chechen words removed from levels 62, 80, 81, 88, 89, 94 (was: Russian)
- 112 info_* word meanings in ce.json
- i18n: added level_52..level_100 keys to ce.json

### Phase 7 — Game Improvement (Done)
- **71 new levels (31-100)** — no word repetition with existing levels
- **101 total levels** (0-100) with increasing difficulty curve
- **Stats screen expanded**: lifetime counters
- **GameController updated**: auto-increment counters
- **Info strip**: every solved word shows meaning for 3 seconds
- **Daily challenge card**: shows level number + coin reward
- **Thematic packs**: 4 packs in gallery
- **Store-ready assets**: new app icon, adaptive icons, splash screen, feature graphic, store listing copy (TR/EN/CE)
- **Free publishing pipeline**: web build verified, Netlify config, GitHub Actions workflow for Pages + Netlify + APK release, landing page, itch.io & F-Droid templates
- **Level model**: added `pack` field
- **i18n**: added `level_0` + level_1..level_100 keys, plus stats keys
- **levels_test.dart updated**: bonus curve test adapted for 101 levels
- **flutter test 43/43 PASS** ✅

### Not started
- Liderlik tablosu (yerel offline)
- Sesli telaffuz (TTS)
- Seviye editörü / topluluk içeriği
- Mağaza gönderimi (işlem kullanıcı tarafından yapılacak)

## Recent Decisions

- All levels use simple across-only grid (no crossword intersections) — avoids digraph overlap issues with automated generation
- Palochka (Ӏ/ӏ) normalization applied consistently: `ӏ` replaced with U+04C0 `Ӏ` in levels.json
- No invented Chechen words — all content from verified word lists
- Gallery uses grouped `CustomScrollView` instead of flat grid for better navigation at 50+ levels

## Blockers

None identified.

---
*Last updated: 2026-07-02 — 101 levels, Russian words removed, all level_* keys in ce.json, info strip, daily challenge card, thematic packs, all tests passing*
