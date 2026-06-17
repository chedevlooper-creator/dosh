# Дош (Dosh)

## What This Is

**Дош** is a Words-of-Wonders–style word puzzle game in **Chechen** (letter wheel + crossword grid), built with **Flutter** from a single codebase. Target platforms: Android, iOS, Windows. The audience is Turkish speakers learning Chechen — free, no ads or purchases.

## Core Value

Players solve Chechen word puzzles in a polished, native-quality mobile game experience while naturally learning Chechen vocabulary.

## Business Context

<!-- Non-monetized community project — delete if needed later -->
- **Customer**: Turkish speakers learning Chechen (Kafkas diaspora)
- **Revenue model**: None (free, no ads, no purchases)
- **Success metric**: Positive App Store / Play Store reviews from the community
- **Strategy notes**: Community-driven word list; content quality over monetization

## Requirements

### Validated

- Letter wheel + crossword grid game mechanic (Words-of-Wonders style)
- Chechen grapheme tokenizer (digraph support: аь, гӀ, кх, къ, кӀ, оь, пӀ, тӀ, уь, хь, хӀ, цӀ, чӀ, юь, яь)
- Level system with tutorial (id 0), sequential unlock
- Coin economy with combo bonuses, daily gift, daily challenge
- Star rating (1-3⭐ per level)
- Turkish UI chrome, real Chechen puzzle content
- Audio cues (tap, solve, wrong, hint, complete, coin)
- Scenic background with theme variants
- Gallery (level select), Settings, Stats, Dictionary screens
- Persistence via SharedPreferences
- Off-grid bonus words
- Tutorial guide

### Active

- [ ] Level 21-30 content (generated_levels_21_30.json ready)
- [ ] Additional curated Chechen word lists integrated
- [ ] Game improvement spec features (see game-improvement-spec.md)

### Out of Scope

- Monetization / ads / purchases — the app is free community tool
- English-only mode — UI is Turkish, content is Chechen
- Multiplayer or leaderboards — single-player puzzle game

## Context

Built as a community tool for the Chechen diaspora in Turkey. Available on Google Play, Apple App Store, and Windows. Word sources are vetted Chechen word lists (cechen_curated_for_game.txt, cechen_words_master.txt, etc.) — never invented. The golden rule: every user-visible string is either real Chechen or a technical key.

## Constraints

- **Tech Stack**: Flutter/Dart (^3.5.0), single codebase
- **Content**: Real Chechen only (Cyrillic) — no placeholder or invented words
- **Platform**: Android, iOS, Windows (web for dev/preview only)
- **Audio**: audioplayers package (silent fallback on unsupported platforms)
- **Persistence**: SharedPreferences only (no server/backend)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Single Flutter codebase | Cross-platform without duplication | ✓ Good |
| Real Chechen only | Cultural integrity, no fake content | ✓ Good |
| Turkish UI / Chechen content | Target audience = Turkish speakers | ✓ Good |
| No monetization | Community tool, trust | ✓ Good |
| Local persistence only | No accounts, no server costs | ✓ Good |

---
*Last updated: 2026-06-17 after GSD init*
