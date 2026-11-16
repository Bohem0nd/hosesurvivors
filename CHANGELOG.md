# Changelog

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
