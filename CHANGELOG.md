# Changelog

## [Unreleased]

### Added
- Mobile and tablet support for the web build:
  - Floating virtual joystick (touch anywhere, drag to move) and an on-screen pause button.
  - The viewport adapts to the screen's shape (from 640×360 up to 864×480), so phones
    and tablets have no black bars. Desktop keeps integer pixel scaling.
  - HUD pinned to the screen edges; menus stay centred.
  - Bigger buttons and touch hints when playing by touch. On character select, a tap
    selects a hero and BEGIN HOSING starts the run.
  - Auto-pause when the app loses focus or the device is rotated to portrait, plus a
    "rotate your device" prompt.
  - FULLSCREEN button on the web title screen; mobile web-app meta tags; no page
    bounce, text selection or long-press menus.
- Touch tests (`tests/unit/test_touch.gd`) and a `--touch` flag for the screenshot tool.

## [0.1.0] — Phase 1: playable vertical slice

### Added
- Godot 4.6 project (GL Compatibility, 640×360 internal resolution, integer-scaled to 1080p).
- **Jon Hose** as a fully data-driven playable character with the *Pressure Builds* passive.
- **The Holy Hose**: target-seeking, sweeping bursts of piercing water with knockback,
  hit flash, splashes, puddles, batched damage numbers and a trailing hose.
  Eight levels, evolving into **The Hose of Judgment** (requires Industrial Pressure).
- Enemies: Dry One, Unregistered Hours, The Thirsty; elite Corporate Bureaucrat
  (regenerating shield, drops a Supply Crate); boss **The Great Drying**
  (telegraphed drought zones, dust nova, summons, enrage at 50%).
- Stage **The Dry Wastelands**: endless scrolling ground, deterministic props,
  a 10-minute wave/event timeline and time-based enemy scaling.
- XP droplets (three tiers), Hose Coins, Kristall heals, magnets, supply crates.
- Level-up screen with three weighted choices; 11 passive upgrades; evolution offers;
  consumable fallbacks when everything is maxed.
- HUD (XP, health, timer, kills, coins, build icons, passive status, boss bar,
  announcement banner with letterbox), pause menu, victory/defeat screens.
- Main menu and character select with the five future heroes shown as locked.
- Persistent save (`user://save.json`): Hose Coins and lifetime stats.
- Keyboard and gamepad input; audio hook system with generated placeholder SFX and music.
- Tests: 22 unit/integration tests, a headless bot that plays full runs, a
  defeat-and-restart check, and a screenshot tool.
- Docs: GAME_DESIGN, ARCHITECTURE, ROADMAP, TODO, ASSET_GUIDE.

### Notes
- All art and audio are generated placeholders (`tools/gen_art.py`, `tools/gen_audio.py`).
- Verified headless only; see TODO "Needs a human".
