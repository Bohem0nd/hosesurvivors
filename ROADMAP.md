# HOSE SURVIVORS — Roadmap

Status key: ✅ done · 🟡 partly done · ⬜ not started

## Phase 1 — Playable vertical slice ✅ (v0.1.0)

**Milestone definition:** start from the main menu, play Jon Hose through a full
10-minute run in The Dry Wastelands, win or lose, restart without errors.

| # | Deliverable | Status |
|---|---|---|
| 1 | Main menu | ✅ |
| 2 | Playable Jon Hose (data-driven character) | ✅ |
| 3 | Responsive 8-directional movement, keyboard + gamepad | ✅ |
| 4 | Seamless scrolling arena with props | ✅ |
| 5 | Automatic Holy Hose attacks | ✅ |
| 6 | Three enemy archetypes (Dry One, Unregistered Hours, The Thirsty) | ✅ |
| 7 | Spawning and difficulty scaling | ✅ |
| 8 | Health and damage systems | ✅ |
| 9 | XP pickups | ✅ |
| 10 | Leveling with three-choice upgrades | ✅ |
| 11 | Five functional upgrades (11 shipped) | ✅ |
| 12 | Elite enemy (Corporate Bureaucrat) | ✅ |
| 13 | Boss (The Great Drying) | ✅ |
| 14 | 10-minute survival objective | ✅ |
| 15 | Victory and defeat screens | ✅ |
| 16 | Placeholder visuals and sound hooks | ✅ |
| + | Character select, pause menu, save file, evolution system + Hose of Judgment, supply crates, automated tests | ✅ (pulled forward) |

**Exit follow-ups (need a human):** playtest on Windows hardware for feel,
difficulty and GPU performance.

## Phase 2 — Combat expansion ⬜

- Weapons: Outlook Overload, Teams Notification, Kristall Overdose (+ evolutions)
- Generic weapon behaviors: aimed projectile, orbit, aura/shockwave, homing, zone
- Enemies: Meeting Invites, Outlook Demons, Corrupted Memes; a second elite
- Passive equipment with unique effects (on-kill, on-hit, thresholds)
- Rarity tiers on the level-up screen; reroll / banish / skip
- Hit-stop on big hits, status effects (soaked, stunned), crit numbers
- Balance pass from playtests

## Phase 3 — Hoseverse expansion ⬜

- Ass Man, The Crackler, Quakewalker, The Memeweaver, The Shopkeeper (weapons + passives)
- Unlock flow on the character select screen
- Stages: The Council Chambers, Microsoft Teams Meeting Hell (then the rest)
- Bosses: SNORRI.EXE, The Chairman
- Stage select screen

## Phase 4 — Meta progression 🟡

- ✅ Persistent currency (Hose Coins) and lifetime stats saved
- ⬜ Permanent upgrade shop
- ⬜ Character unlock purchases / conditions
- ⬜ Achievements
- ⬜ Progression balancing

## Phase 5 — Polish 🟡

- ⬜ Final artwork and animations (see `ASSET_GUIDE.md`)
- ⬜ Sound design and original soundtrack
- 🟡 Controller support (movement, pause and menus work; needs rebinding UI + glyphs)
- ⬜ Options menu (volume, screen shake, fullscreen), accessibility options
- ⬜ Performance profiling on target hardware
- ⬜ Windows export preset, icon, installer/Steam packaging

## Dependencies

| Dependency | Needed for | State |
|---|---|---|
| Godot 4.6 stable | Everything | Verified (4.6.stable.official) |
| Godot Windows export templates | Shipping builds | Not installed in the dev container |
| Python 3 + Pillow | Regenerating placeholder assets only | Optional |
| Press Start 2P, Silkscreen (SIL OFL) | UI fonts | Bundled with licences |
| Canon reference art | Final character sprites | Needed from the Hoseverse owners |
