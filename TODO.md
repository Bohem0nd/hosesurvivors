# TODO

## Done (v0.1.0 — Phase 1)

- [x] Project structure, autoloads, data resource classes
- [x] Design, architecture, roadmap and asset docs
- [x] Placeholder art + audio generators (`tools/`)
- [x] Jon Hose: movement, animation, health, i-frames, regen, armor
- [x] Pressure Builds passive
- [x] Holy Hose (8 levels) and Hose of Judgment evolution
- [x] Pooled enemies with spatial grid, separation, knockback, hit flash
- [x] Dry One, Unregistered Hours, The Thirsty
- [x] Corporate Bureaucrat elite (regenerating shield, supply crate)
- [x] The Great Drying boss (drought zones, dust nova, summons, enrage)
- [x] Stage timeline for The Dry Wastelands with scaling
- [x] XP droplets, coins, Kristall heal, magnet, supply crate
- [x] Level-up screen with weighted offers; 11 passives; consumable fallbacks
- [x] HUD, boss bar, announcement banner, pause menu, end screens
- [x] Main menu, character select (locked roster)
- [x] Save file (coins, lifetime stats)
- [x] Keyboard + gamepad input
- [x] Unit tests, headless full-run simulation, restart check, screenshot tool

## Needs a human (cannot be verified in a headless container)

- [ ] Play it on Windows: movement feel, hose feel, readability at 1080p
- [ ] Difficulty pass — bots show the run is completable and losable, not that it is *fun*
- [ ] Listen to the placeholder audio mix (never played through real speakers)
- [ ] Gamepad test on real hardware
- [ ] Play on a real phone and tablet (tested only in an emulated Pixel 7 in headless Chromium)
- [ ] Frame-time profile with a GPU at 300+ enemies
- [ ] Install export templates and produce a Windows build

## Known issues

- [ ] Godot reports one leaked `AudioStreamWAV` at shutdown when music is playing (cosmetic)
- [ ] Late game is much easier than the first three minutes once the hose evolves
- [ ] Stage props have no collision and can hide small pickups
- [ ] Boss can be obscured by a dense horde
- [ ] No options menu yet: volume and screen shake are only editable in `user://save.json`

## Next up (Phase 2)

- [ ] Generic `ProjectileWeapon`, `AuraWeapon`, `OrbitWeapon` behaviors
- [ ] Outlook Overload, Teams Notification, Kristall Overdose
- [ ] Meeting Invites, Outlook Demons, Corrupted Memes
- [ ] Rarity tiers, reroll/banish
- [ ] Options menu
- [ ] Hit-stop and status effects
- [ ] Windows export preset

## Later

- [ ] Remaining five characters (Phase 3)
- [ ] More stages and bosses (Phase 3)
- [ ] Meta shop, unlocks, achievements (Phase 4)
- [ ] Final art, music, accessibility (Phase 5)
