# CLAUDE.md

Guidance for AI assistants working in this repository.

## Project overview

**Дош (Dosh)** is a Words-of-Wonders–style word puzzle game in **Chechen**
(letter wheel + crossword grid), built with **Flutter** from a single codebase.

- Target platforms: **Android, iOS, Windows**. `web` is used only for local
  development/preview.
- Package name / app id: `dosh` (see `pubspec.yaml`).
- Dart SDK: `^3.5.0`. Dependencies: `audioplayers`, `shared_preferences`.

### Language conventions in this repo

- **UI chrome text is Turkish** (e.g. `Başla`, `Seviye 1`, `Ses`) — the game
  is authored for a Turkish-speaking audience playing in Chechen.
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
genuine Chechen source. Otherwise leave it out.

## Architecture

Layered, with a UI-independent game core. Data flows up via `ChangeNotifier`
(`notifyListeners`) for state and a broadcast `Stream<GameEvent>` for one-shot
effects (sounds, animations).

```
lib/
  main.dart              # bootstrap: orientation lock, load i18n/levels/store, runApp
  app.dart               # DoshApp: Home <-> Game switch, owns GameSound
  core/
    graphemes.dart       # Chechen grapheme tokenizer + normalize() (palochka)
    strings.dart         # Strings: tiny i18n (key -> real Chechen, else key)
    constants.dart       # GameConfig: coin economy + layout constants
  data/
    models.dart          # Cell, PlacedWord, Level (+ JSON + validate())
    level_repository.dart # loads & validates assets/levels/levels.json
    progress_store.dart  # ProgressStore: coins/level/sound via SharedPreferences
  game/
    game_controller.dart # GameController: rules, selection, scoring, hints, shuffle
  audio/
    game_sound.dart      # GameSound: SoundCue -> AudioPlayer, mute toggle persisted
  ui/
    theme.dart           # AppColors palette + buildTheme()
    screens/             # home_screen.dart, game_screen.dart
    widgets/             # letter_wheel, crossword_grid, word_capsule, coin_box,
                         # info_strip, top_bar, round_icon_button,
                         # scenic_background, effects/confetti_burst
assets/
  i18n/ce.json           # localization keys -> Chechen
  levels/levels.json     # level definitions (validated at load + in tests)
  fonts/                 # NotoSans (full Cyrillic + palochka Ӏ)
  audio/                 # *.wav sound cues
  backgrounds/           # optional scenic photo
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
  selection (back-tracking to the previous bubble undoes the last pick).
  `_solve` awards `graphemes.length * coinsPerGrapheme` coins; hint-completed
  words give **no** coin reward. Emits `GameEvent`s on a `sync` broadcast stream
  so the UI's animation triggers stay deterministic.

- **Levels (`data/models.dart`).** `Level.validate()` enforces invariants:
  every word ≥ 2 graphemes, buildable from the wheel `letters`, and intersecting
  cells must agree on their grapheme (`targetByCell` throws on conflict).
  `LevelRepository.load()` runs `validate()` on every level at startup, and the
  level test loads the real asset — so a bad level breaks the build's tests.

- **Persistence (`data/progress_store.dart`).** Coins, current level index, and
  sound on/off are stored in `SharedPreferences` (works on all platforms).
  Defaults: `startCoins = 100`.

- **Economy (`core/constants.dart`).** `startCoins=100`, `hintCost=25`,
  `coinsPerGrapheme=5`, `maxContentWidth=520` (caps the play column on
  wide/desktop screens).

## Development workflow

Run Flutter directly. **Do not rely on `setup.sh` / `test.sh` / `.claude/launch.json`**
as-is — they hardcode a contributor's local macOS Flutter path
(`/Users/isahamid/...`) and project directory, which won't exist here. They are
kept as a record of the intended verify chain (`pub get` → `analyze` → `test`).

```bash
flutter pub get            # install dependencies
flutter analyze            # static analysis (flutter_lints, see analysis_options.yaml)
flutter test               # run all tests
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
- `controller_test.dart` — game rules: correct/wrong words, coin rewards,
  already-found, hints, hint-completed level finish, shuffle, nextLevel reset.
- `widget_test.dart` — home→game flow, wheel letters render, drag-to-solve
  updates grid + coin box; confirms missing translations show the technical key.

## Adding a level

Edit `assets/levels/levels.json`. Each level:

```json
{
  "id": 4,
  "letters": ["х", "ь", "о"],
  "words": [
    { "word": "хьо", "row": 0, "col": 0, "dir": "across" }
  ]
}
```

- Digraphs are single elements in `letters` (e.g. `"хь"`, not `"х","ь"`).
- `dir` is `"across"` or `"down"`. Coordinates are absolute grid `row`/`col`;
  the grid auto-crops to the used bounds.
- Every word must be buildable from `letters`, and intersecting cells must carry
  the same grapheme. `flutter test` verifies this automatically — run it.
- Add real Chechen for the level title (`level_<id>`) and any `info_<word>`
  footnotes in `assets/i18n/ce.json`; omit if you don't have a real source.

> Note: `home_screen.dart`'s `_MiniGrid` has a hardcoded solved-cell preview for
> `level.id == 1` to match the reference design; other levels fall back to
> showing the first word. Keep this in mind if you renumber level 1.

## Conventions & gotchas

- New user-facing strings go through `Strings.t` / `Strings.tOrNull` with a key
  in `ce.json`. Never hardcode invented Chechen.
- New assets must be registered under `flutter:` in `pubspec.yaml`.
- Audio and orientation lock fail silently off their supported platforms (e.g.
  in tests / web); preserve that — game flow must not depend on them.
- The scenic background is currently vector-drawn
  (`ui/widgets/scenic_background.dart`); to use a real photo, add it under
  `assets/backgrounds/`, register it, and follow the in-file guidance.

## Git workflow

- Develop on the designated feature branch; create it locally if needed.
- Commit with clear messages; push with `git push -u origin <branch>`.
- Do **not** open a pull request unless explicitly asked.
