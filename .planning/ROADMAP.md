# Roadmap: Дош (Dosh)

**Defined:** 2026-06-17
**Current phase:** Phase 6 (Content)

## Phase 1 — Core Game Engine ✓
Build the letter wheel, crossword grid, grapheme system, word validation, and basic game loop. Implement Chechen digraph tokenization.

*Requirements: GAME-01 through GAME-08, PROG-01 through PROG-05*
*Status: Complete*

## Phase 2 — UI Polish ✓
Build all screens: gallery, settings, stats, dictionary. Turkish UI strings, scenic background with themes, tutorial guide overlay.

*Requirements: UI-01 through UI-08*
*Status: Complete*

## Phase 3 — Audio ✓
Sound cues for all game events: tap, solve, wrong, hint, complete, coin. Mute toggle.

*Requirements: AUDIO-01 through AUDIO-05*
*Status: Complete*

## Phase 4 — Platform ✓
Android, iOS, Windows builds working. App icon, splash screen, orientation lock.

*Requirements: PLAT-01 through PLAT-05*
*Status: Complete*

## Phase 5 — Quality ✓
Test suite: grapheme tokenizer, game controller, scoring, levels validation, widget flow. CI-ready.

*Requirements: QUAL-01 through QUAL-06*
*Status: Complete*

## Phase 6 — Content ✅
Add levels 21-30 from generated_levels_21_30.json. Integrate curated word lists for bonus candidates. Add info_* meanings where sources available.

*Requirements: CONT-01 through CONT-03*
*Status: Complete*

### Completed items:
- ✅ Levels 21-30 already integrated (richer content than generated version)
- ✅ All 31 levels validated via Level.validate()
- ✅ flutter test: 43/43 PASS
- ✅ bonus_candidates.json: 21-30 added, 0-20 synced with actual bonus words (531 total)

## Phase 7 — Game Improvement Spec (Future)
Implement features from game-improvement-spec.md. Animation polish, additional themes, UX refinements.

*Requirements: IMPR-01 through IMPR-03*
*Status: Planned*

---
*Roadmap defined: 2026-06-17*
*Last updated: 2026-06-17 after GSD init*
