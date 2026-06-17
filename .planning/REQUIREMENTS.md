# Requirements: Дош (Dosh)

**Defined:** 2026-06-17
**Core Value:** Players solve Chechen word puzzles in a polished, native-quality mobile game experience while naturally learning Chechen vocabulary.

## v1 Requirements

### Game Engine

- [x] **GAME-01**: Player can select letters from a wheel to form words
- [x] **GAME-02**: Correct words appear on the crossword grid
- [x] **GAME-03**: Player can shuffle the letter wheel
- [x] **GAME-04**: Player can use hints to reveal a letter
- [x] **GAME-05**: Wrong selections are rejected with feedback
- [x] **GAME-06**: Level completes when all grid words are solved
- [x] **GAME-07**: Off-grid bonus words can be found for extra coins
- [x] **GAME-08**: Chechen digraphs (аь, гӀ, etc.) count as one letter

### Progression

- [x] **PROG-01**: Tutorial level (id 0) teaches the game
- [x] **PROG-02**: Levels unlock sequentially when previous has stars
- [x] **PROG-03**: Star rating (1-3⭐) per level
- [x] **PROG-04**: Coins earned from solving words with combo bonuses
- [x] **PROG-05**: Daily gift and daily challenge

### Content

- [ ] **CONT-01**: Level 21-30 with real Chechen words
- [ ] **CONT-02**: Word meanings (info_*) for solved words where source available
- [ ] **CONT-03**: Bonus word candidates integrated from curated lists

### UI/UX

- [x] **UI-01**: Gallery screen to select levels
- [x] **UI-02**: Game screen with wheel, grid, coin box, info strip
- [x] **UI-03**: Settings screen (sound, theme, language)
- [x] **UI-04**: Stats screen (coins, words solved, streaks)
- [x] **UI-05**: Dictionary screen (solved word meanings)
- [x] **UI-06**: Turkish UI text, Chechen puzzle content
- [x] **UI-07**: Scenic background with theme variants
- [x] **UI-08**: Tutorial guide overlay

### Audio

- [x] **AUDIO-01**: Tap sound on letter selection
- [x] **AUDIO-02**: Solve sound on word completion
- [x] **AUDIO-03**: Wrong sound on invalid word
- [x] **AUDIO-04**: Hint sound, complete jingle, coin sound
- [x] **AUDIO-05**: Mute toggle persisted

### Platform

- [x] **PLAT-01**: Runs on Android
- [x] **PLAT-02**: Runs on iOS
- [x] **PLAT-03**: Runs on Windows
- [x] **PLAT-04**: App icon and splash screen configured
- [x] **PLAT-05**: Orientation lock (portrait on mobile)

### Quality

- [x] **QUAL-01**: Level validation at load (all words buildable, intersections correct)
- [x] **QUAL-02**: Unit tests for grapheme tokenizer
- [x] **QUAL-03**: Unit tests for game controller rules
- [x] **QUAL-04**: Unit tests for scoring math
- [x] **QUAL-05**: Widget test for home→game flow
- [x] **QUAL-06**: Levels test loads real levels.json

## v2 Requirements

### Game Improvement

- **IMPR-01**: Game improvement spec features (see game-improvement-spec.md)
- **IMPR-02**: Animation polish on word solve
- **IMPR-03**: Additional background themes

### Content

- **CONT-04**: More levels (31+)
- **CONT-05**: Category/themed level packs

## Out of Scope

| Feature | Reason |
|---------|--------|
| Monetization / ads | Free community tool, no revenue model |
| Multiplayer | Single-player word puzzle |
| Server/backend | No accounts, local persistence only |
| English-only mode | Target audience = Turkish speakers |
| Social features | Not needed for word puzzle experience |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GAME-01 through GAME-08 | Phase 1 (Core) | Complete |
| PROG-01 through PROG-05 | Phase 1 (Core) | Complete |
| UI-01 through UI-08 | Phase 2 (UI) | Complete |
| AUDIO-01 through AUDIO-05 | Phase 3 (Audio) | Complete |
| PLAT-01 through PLAT-05 | Phase 4 (Platform) | Complete |
| QUAL-01 through QUAL-06 | Phase 5 (Quality) | Complete |
| CONT-01 through CONT-03 | Phase 6 (Content) | In Progress |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-17*
*Last updated: 2026-06-17 after GSD init*
