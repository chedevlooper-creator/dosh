# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**Дош (Dosh)** is a Words-of-Wonders–style word puzzle game in **Chechen**
(letter wheel + crossword grid), built with **Flutter** from a single codebase.

- Target platforms: **Android, iOS, Windows**. `web` is used only for local
  development/preview.
- Audience: Turkish speakers learning Chechen. Free, no ads or purchases.
- Dart SDK: `^3.5.0`. Runtime deps: `audioplayers`, `shared_preferences`.
  Dev deps include `flutter_launcher_icons` and `flutter_native_splash`
  (icon/splash configured in `pubspec.yaml`).
- `game-improvement-spec.md` is the user-approved feature spec — consult it
  before changing game behavior or content.

### Language conventions in this repo

- **UI chrome text is Turkish** (e.g. `Başla`, `Seviye 1`, `Ses`).
- **Code comments, doc comments, README, and error messages are in Turkish.**
  Match this when editing existing files; do not rewrite Turkish comments into
  English.
- **Puzzle content is real Chechen** (Cyrillic). See the content rule below.

## The golden content rule: never invent Chechen

> Every user-visible string is either **real Chechen** or a **technical
> localization key** (like `level_1`). Fake/placeholder Chechen is never written.

- `assets/i18n/ce.json` maps key → real Chechen text. If a key is missing,
  `Strings.t(key)` returns the **key itself** so the gap is visible on screen
  (never a guessed translation).
- A solved word's footnote is read from `info_<word>` (e.g. `info_малх`) via
  `Strings.tOrNull`. If that key is absent, the info strip is simply hidden —
  it never shows made-up text.

When adding words or levels, only add an `info_*` translation if you have a
genuine Chechen source. Otherwise leave it out. Word-list source files live at
the repo root (`cechen_curated_for_game.txt`, `cechen_words_master.txt`,
`cechen_full_wordlist.txt`, `cechen_new_words_from_web.txt`,
`bonus_candidates.json`, `english_terms.json`) — draw new content from these,
never from imagination. `fetch_words.py` is the scraper that produced the
web word list.

## Architecture

Layered, with a UI-independent game core. Data flows up via `ChangeNotifier`
(`notifyListeners`) for state and a broadcast `Stream<GameEvent>` for one-shot
effects (sounds, animations).

```
lib/
  main.dart              # bootstrap: orientation lock, load i18n/levels/store, runApp
  app.dart               # DoshApp: screen switcher (home/gallery/game/settings/
                         # stats/dictionary), owns GameSound + theme index
  core/
    graphemes.dart       # Chechen grapheme tokenizer + normalize() (palochka)
    strings.dart         # Strings: tiny i18n (key -> real Chechen, else key)
    constants.dart       # GameConfig: coin economy + layout constants
    scoring.dart         # Scoring: pure reward/star functions (no state)
  data/
    models.dart          # Cell, PlacedWord, Level (+ JSON + validate(), bonusWords)
    level_repository.dart # loads & validates assets/levels/levels.json
    progress_store.dart  # coins, stars, solved words, streaks, daily state, theme
  game/
    game_controller.dart # GameController: rules, selection, hints, shuffle, events
  audio/
    game_sound.dart      # GameSound: SoundCue -> AudioPlayer, mute toggle persisted
  ui/
    theme.dart           # AppColors palette + buildTheme() + SceneTheme variants
    screens/             # home, gallery (level select), game, settings, stats,
                         # dictionary (solved-word meanings)
    widgets/             # letter_wheel, crossword_grid, word_capsule, coin_box,
                         # info_strip, top_bar, level_complete_panel,
                         # tutorial_guide, scenic_background, effects/confetti_burst
assets/
  i18n/ce.json           # localization keys -> Chechen (+ info_* word meanings)
  levels/levels.json     # level definitions (validated at load + in tests)
  fonts/                 # NotoSans (full Cyrillic + palochka Ӏ)
  audio/                 # *.wav sound cues
  icon/                  # app icon source + generate_icon.py
```

### Key concepts

- **Graphemes (`core/graphemes.dart`).** Chechen digraphs (аь, гӀ, кх, къ, кӀ,
  оь, пӀ, тӀ, уь, хь, хӀ, цӀ, чӀ, юь, яь) count as **one game letter**.
  `splitGraphemes` does longest-match tokenization. `normalize` lowercases and
  folds all palochka variants (U+04CF, Latin `i`/`I`) to the canonical
  `Ӏ` (U+04C0) so data and code match regardless of how they were typed. Wheel
  bubbles, grid cells, and word matching all operate on graphemes.

- **GameController (`game/game_controller.dart`).** The single source of game
  truth, UI-independent and unit-tested. `enterBubble`/`releaseSelection` drive
  selection (back-tracking to the previous bubble undoes the last pick). Emits
  `GameEvent`s on a `sync` broadcast stream so UI animation triggers stay
  deterministic.

- **Scoring (`core/scoring.dart`).** Pure functions, separate from controller
  state: word solve pays `graphemes × coinsPerGrapheme` plus a combo bonus
  every `comboMilestone` consecutive no-hint solves; hint-completed words pay
  **nothing**; off-grid bonus words pay a flat `bonusWordCoins`. Stars:
  3⭐ clean level, 2⭐ ≤2 mistakes & ≤1 hint, else 1⭐. All amounts live in
  `GameConfig` (`core/constants.dart`), including the daily gift and daily
  challenge bonus.

- **Levels (`data/models.dart` + `assets/levels/levels.json`).** Level id 0 is
  the **tutorial** (always unlocked, hidden in the gallery); ids 1+ unlock
  sequentially once the previous level has stars. Each level also carries
  `bonus` words — valid off-grid words buildable from the wheel.
  `Level.validate()` enforces invariants: every word ≥ 2 graphemes, buildable
  from the wheel `letters`, intersecting cells agree on their grapheme, and
  bonus words are not duplicates of grid words. `LevelRepository.load()`
  validates every level at startup, and `levels_test.dart` loads the real
  asset — a bad level breaks the test suite.

- **Persistence (`data/progress_store.dart`).** Everything player-visible is in
  `SharedPreferences`: coins, per-level stars and solved words, tutorial-done,
  best streak, daily gift/challenge state, and theme index. It also derives
  stats (totals, completed counts) and the deterministic
  `dailyLevelIndex(...)` used by the daily challenge.

## Development workflow

Run Flutter directly. **Do not rely on `setup.sh` / `test.sh` / `.claude/launch.json`**
as-is — they hardcode a contributor's local macOS Flutter path
(`/Users/isahamid/...`) and project directory, which won't exist here. They are
kept as a record of the intended verify chain (`pub get` → `analyze` → `test`).

```bash
flutter pub get            # install dependencies
flutter analyze            # static analysis (flutter_lints, see analysis_options.yaml)
flutter test               # run all tests
flutter test test/controller_test.dart   # run a single test file
flutter run -d web-server  # local dev/preview in a browser
flutter run -d windows     # Windows desktop
flutter run                # connected Android/iOS device
```

**Always run `flutter analyze` and `flutter test` before committing.** The test
suite is the safety net for content correctness, not just code.

### Tests (`test/`)

- `graphemes_test.dart` — tokenization, digraphs, palochka/case normalization.
- `levels_test.dart` — loads the real `levels.json`, asserts validation passes
  and ids are unique.
- `controller_test.dart` — game rules: correct/wrong words, rewards, hints,
  bonus words, shuffle, nextLevel reset.
- `scoring_test.dart` — reward math, combo milestones, star thresholds.
- `game_sound_test.dart` — sound cue mapping and mute persistence.
- `widget_test.dart` — home→game flow, drag-to-solve updates grid + coin box;
  confirms missing translations show the technical key.
- `screenshot_test.dart` — renders screens for visual capture.

## Adding a level

Edit `assets/levels/levels.json`. Each level:

```json
{
  "id": 4,
  "letters": ["х", "ь", "о"],
  "words": [
    { "word": "хьо", "row": 0, "col": 0, "dir": "across" }
  ],
  "bonus": ["хо"]
}
```

- Digraphs are single elements in `letters` (e.g. `"хь"`, not `"х","ь"`).
- `dir` is `"across"` or `"down"`. Coordinates are absolute grid `row`/`col`;
  the grid auto-crops to the used bounds.
- Every word (grid and bonus) must be buildable from `letters`; intersecting
  cells must carry the same grapheme; bonus words must not duplicate grid
  words. `flutter test` verifies all of this — run it.
- Keep id 0 as the tutorial; new levels get the next sequential id (unlock
  order follows ids).
- Add real Chechen for the level title (`level_<id>`) and any `info_<word>`
  footnotes in `assets/i18n/ce.json`; omit if you don't have a real source.

## Conventions & gotchas

- New user-facing strings go through `Strings.t` / `Strings.tOrNull` with a key
  in `ce.json`. Never hardcode invented Chechen.
- New assets must be registered under `flutter:` in `pubspec.yaml`.
- Audio and orientation lock fail silently off their supported platforms (e.g.
  in tests / web); preserve that — game flow must not depend on them.
- The scenic background is vector-drawn with selectable `SceneTheme` variants
  (`ui/widgets/scenic_background.dart`, theme picked in settings).

## Git workflow

- Develop on the designated feature branch; create it locally if needed.
- Commit with clear messages; push with `git push -u origin <branch>`.
- Do **not** open a pull request unless explicitly asked.
