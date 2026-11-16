# HOSE SURVIVORS — Technical Architecture

**Engine:** Godot 4.6 (GL Compatibility renderer) · **Language:** typed GDScript ·
**Target:** Windows PC · **No third-party addons.**

## 1. Principles

- **Data-driven.** Characters, weapons, projectiles, enemies, upgrades and stages
  are `Resource` files in `resources/`. Tuning never requires code changes.
- **Behavior by composition.** Generic systems know nothing about specific content.
  A weapon's attack pattern (`WeaponData.behavior`), an enemy's AI
  (`EnemyData.behavior`) and a character's passive (`CharacterData.passive_script`)
  are pluggable scripts referenced from data.
- **Signals for cross-system talk.** Systems emit on the `Events` bus; nobody holds
  references to UI or to unrelated systems.
- **Explicit context, no tree searches.** A `GameContext` object carrying the live
  systems is passed into anything that needs them. There are no `get_node("/root/…")`
  or group lookups in gameplay code.
- **Manager loops, not per-entity scripts.** Enemies, projectiles and pickups are
  pooled "dumb" nodes updated by one loop each. This is the main performance lever.

## 2. Folder layout

```
assets/        sprites/ audio/ fonts/ shaders/   (all placeholders are generated; see ASSET_GUIDE.md)
resources/     characters/ weapons/ projectiles/ enemies/ upgrades/ stages/   (.tres data)
scenes/        game.tscn, ui/main_menu.tscn, ui/character_select.tscn
scripts/
  autoload/    Events, InputSetup, SaveManager, AudioManager, RunState, UiTheme, Router
  data/        Resource class definitions (CharacterData, WeaponData, EnemyData, …)
  core/        StatBlock, Stats, SpatialGrid, ObjectPool, GameContext
  components/  HealthComponent
  player/      Player, WeaponController, PassiveAbility, passives/
  weapons/     Weapon (base), HoseWeapon
  enemies/     Enemy, EnemyManager, SpawnDirector, behaviors/
  projectiles/ Projectile, ProjectileManager
  pickups/     Pickup, PickupManager
  progression/ UpgradeSystem, UpgradeOffer
  effects/     ParticleField, RingField, DamageNumbers, GameCamera, TelegraphZone
  world/       Ground
  ui/          Hud, LevelUpScreen, PauseMenu, EndScreen, menus, PixelBar
  game/        Game (run orchestrator)
tests/         unit tests, headless run simulation, screenshot tool
tools/         placeholder art + audio generators (Python)
```

Scenes are intentionally thin: each `.tscn` is a root node with a script, and the
node tree is built in code. That keeps scene files merge-friendly and makes every
reference greppable. Final art drops in by replacing files in `assets/` (same
paths/frame layout) or by pointing a `.tres` at a new texture.

## 3. Autoloads

| Autoload | Responsibility |
|---|---|
| `Events` | Global signal bus (kills, damage, XP, level-up, boss, announcements, run start/end) |
| `InputSetup` | Registers `move_*` and `pause` actions for keyboard + gamepad at startup |
| `SaveManager` | JSON save in `user://save.json`: coins, unlocks, lifetime stats, settings. Version-tolerant merge |
| `AudioManager` | `play(&"id")` sound hooks → `assets/audio/sfx/<id>.wav`; voice pool, per-id throttling, music |
| `RunState` | The current run: clock, kills, coins, XP/level curve, boss phase, result |
| `UiTheme` | Builds the UI `Theme`, palette constants, pixel-font label factory |
| `Router` | Scene changes with fade; carries the chosen character/stage into the game scene |

## 4. A run at runtime

```
Game (Node2D, scripts/game/game.gd)
├─ GameCamera                    follow + trauma shake
├─ Ground            z -10       repeating tile; props placed in Entities
├─ RingField         z  -5       shockwave rings, puddles
├─ Hazards           z  -4       TelegraphZone nodes (boss attacks)
├─ PickupManager     z  -3       pooled Pickup sprites
├─ Entities (y-sorted)
│   ├─ Player ── HealthComponent, WeaponController ── Weapon…, PassiveAbility
│   ├─ EnemyManager (y-sorted) ── pooled Enemy sprites
│   └─ stage props
├─ ProjectileManager z   2       pooled Projectile sprites (both teams)
├─ ParticleField     z   3
├─ DamageNumbers     z   4
├─ SpawnDirector
└─ CanvasLayers: vignette, Hud, LevelUpScreen, PauseMenu, EndScreen
```

`Game._ready` builds this, fills a `GameContext`, calls `setup(ctx)` on each system
and starts `RunState`. Flow control (level-up queue, crates, pause gating, victory,
defeat) lives in `Game` and is driven entirely by `Events` signals.

### Frame update

1. `Player` reads input (or `input_override` for bots), moves, regenerates.
2. Each `Weapon` behavior aims/fires through `ctx.projectiles.spawn(...)`.
3. `EnemyManager._process`: for every active enemy — behavior velocity, knockback,
   soft separation, animation, timers, contact damage, far-away recycling — then
   rebuilds the `SpatialGrid`.
4. `ProjectileManager._process`: moves projectiles; player shots query the grid,
   enemy shots test only the player.
5. `PickupManager._process`: magnetism and collection.
6. `SpawnDirector`: waves, scripted events, boss, difficulty scaling.

## 5. Key systems

**Stats** — `StatBlock` holds base values and FLAT / PERCENT / MULT modifiers with a
cache: `(base + flat) × (1 + Σpct) × Πmult`. Stat names live in `Stats`. Tag-scoped
damage is free-form: a weapon tagged `water` multiplies by `damage_water`.

**Weapons** — `Weapon` (base node) resolves effective damage/cooldown/count/area/
knockback/duration/pierce/range from `WeaponData` + accumulated level bonuses + the
owner's `StatBlock`. Subclasses implement only the pattern. `HoseWeapon` is one
behavior used by two data files (Holy Hose and Hose of Judgment).
`WeaponController` adds, levels and evolves weapons generically.

**Enemies** — `EnemyData` + an `EnemyBehavior` resource
(`ChaseBehavior`, `AccelerateNearBehavior`, `WobbleBehavior`,
`GreatDryingBehavior`). Behaviors are shared instances; per-enemy state lives in
`enemy.state`. Shields, elite health bars, hit flash (shared shader material) and
batched damage numbers are generic features driven by data.

**Spawning** — `StageData` lists `SpawnWave`s (interval/batch interpolated over a
time window, optional clustering) and `StageEvent`s (elite arrivals,
encirclements), plus the final boss and scaling rates.

**Upgrades** — `UpgradeSystem.build_candidates()` produces `UpgradeOffer`s: weapon
level-ups, new weapons, evolutions (when `can_evolve`), passives (respecting max
level and slot caps). `roll_offers(n)` does weighted sampling without replacement
and pads with fallback consumables. `apply()` routes to weapons or the `StatBlock`.

**Passives** — `PassiveAbility` node subclass configured by
`CharacterData.passive_params`; exposes `get_status_text()` for the HUD.

**Effects** — `ParticleField`, `RingField` and `DamageNumbers` each draw everything
in a single `_draw` from packed arrays with hard caps.

**UI** — code-built Controls sharing `UiTheme.theme`. Note: Godot themes do not
propagate through `CanvasLayer`, so each layer's root Control assigns the theme.

## 6. Performance

| Technique | Where |
|---|---|
| One update loop per entity type instead of per-node scripts | `EnemyManager`, `ProjectileManager`, `PickupManager` |
| Object pooling (no allocation after warm-up) | `ObjectPool`; enemies, projectiles, pickups, stage props |
| Uniform spatial hash, rebuilt once per frame | `SpatialGrid` — hits, targeting, separation |
| No physics bodies/areas at all | Circle tests against the grid |
| Bounded neighbour checks for separation | 5 per enemy, same cell only |
| Hard caps | 350 enemies (per stage), 900 projectiles, 700 particles, 350 XP pickups (overflow merges), 70 damage numbers |
| Batched damage numbers | Hits within 0.18 s on one enemy merge into one number |
| Shared hit-flash material | Only flashing sprites break batching |

**Measured** (headless, `tests/sim_run`, includes all game logic but no rendering):
≈0.8–1.1 ms average per frame over a full run peaking at 290–350 simultaneous
enemies. GPU-side performance on real hardware still has to be profiled; the
software renderer in CI is not representative.

## 7. Testing

| Command | What it checks |
|---|---|
| `godot --headless --import` | Project imports and every script parses |
| `godot --headless --fixed-fps 60 res://tests/run_tests.tscn` | 22 unit/integration tests (stats, grid, pool, health, XP curve, offers, evolution, damage, shields, pierce, pickups, armor/death, stage data) |
| `godot --headless --fixed-fps 60 res://tests/sim_run.tscn -- --god` | A bot plays the full 10 minutes, kills the boss, reaches the victory screen |
| `… sim_run.tscn -- --bot=idle --then-restart` | Defeat flow, then restart into a second run |
| `xvfb-run -a godot … res://tests/screenshot.tscn -- --scene=… --at=…` | Screenshots for visual review |

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| GDScript CPU cost with 500+ enemies and many weapons | Manager loops + grid already in place; next steps if profiling demands: stagger behavior updates, move hot loops to `MultiMeshInstance2D` rendering or a GDExtension |
| Balance cannot be verified by bots | Bots only prove completability; human playtests are a Phase 1 follow-up |
| Placeholder art sets the wrong expectations | All placeholders are generated and clearly labelled; specs in `ASSET_GUIDE.md` |
| Code-built UI is harder for non-programmers to restyle | Styles are centralised in `UiTheme`; screens can be migrated to `.tscn` when a UI artist joins |
| Canon drift for characters without visual reference | Silhouettes until reference art exists |
| Save format changes | Versioned JSON with default-merge on load |
