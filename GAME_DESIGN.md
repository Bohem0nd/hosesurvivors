# HOSE SURVIVORS — Game Design

A humorous 2D bullet-heaven roguelite set in the Cinematic Universe of Jon Hose.
This document is the design reference; `ROADMAP.md` says what is built when, and
`TODO.md` tracks status.

## 1. Pillars

1. **Hosing must feel incredible.** Every hit knocks back, flashes, splashes, pops
   a number and leaves the ground wet. The first weapon is the benchmark for all others.
2. **Absurd, played straight.** Superhero-trailer gravitas applied to timesheets,
   Outlook invites and hydration. The game never winks first.
3. **Readable chaos.** Hundreds of enemies, but the player, danger telegraphs and
   pickups are always legible.
4. **Fun without the lore.** In-jokes are seasoning; the loop stands on its own.

## 2. Premise

The Council of Hose has fractured. The Dry Memes are spreading. The Church of the
Holy Hose is under siege. An endless army is trying to bring about **the Great
Drying**. Jon Hose and his allies survive escalating waves, evolve their weapons,
defeat bosses and restore moisture to the Hoseverse.

## 3. Core loop

Pick a hero → enter a stage → move (weapons fire automatically) → kill enemies →
collect XP droplets → level up → pick 1 of 3 upgrades → repeat while the stage
escalates → elites at set times → boss when the clock hits the stage duration →
kill the boss to win. Dying or winning banks **Hose Coins** for meta progression.

| Input | Action |
|---|---|
| WASD / arrows / left stick / d-pad | Move (8-directional, instant response) |
| ESC / P / Start | Pause |
| Mouse / arrows / stick + A | Menus |

## 4. Characters

Every character is a `CharacterData` resource: stats, sprite, starting weapon,
passive script and unlock rule. Only Jon Hose is playable in Phase 1; the others
appear on the roster as locked silhouettes.

| Hero | Title | HP | Speed | Starting weapon | Passive | Identity |
|---|---|---|---|---|---|---|
| **Jon Hose** | The Original | 100 | 90 | The Holy Hose | **Pressure Builds** — +1% damage & knockback per 10 s survived (cap +60%) | Area control, water |
| Ass Man | The Glute Guardian | 130 | 84 | Cheek Clap | Glute Force — periodic push-back shockwaves | Close-range AoE, knockback |
| The Crackler | The Electric Menace | 85 | 98 | Arc Discharge | Overcharged — successive hits extend chains | Chain lightning |
| Quakewalker | The Seismic Stride | 120 | 80 | Seismic Step | Heavy Footed — movement builds seismic energy | Movement-driven AoE |
| The Memeweaver | The Digital Sorcerer | 80 | 92 | Meme Barrage | Viral Spread — attacks may duplicate | Projectile multiplication |
| The Shopkeeper | The Supplier | 100 | 88 | Discount Arsenal | Employee Discount — better prices, extra upgrade chances | Economy, randomness |

**Canon appearances** (do not deviate): see `ASSET_GUIDE.md` §Characters. Where canon
gives no visual description (Memeweaver, Shopkeeper) the game shows a silhouette
rather than inventing one.

## 5. Weapons and evolutions

Weapons are `WeaponData` resources (damage, cooldown, projectile count, range, area,
knockback, duration, pierce, max level, per-level bonuses, evolution link) plus a
behavior script. An evolution is offered on level-up once the weapon is at max
level **and** the required passive is owned.

| Weapon | Pattern | Evolves into | Requires | Status |
|---|---|---|---|---|
| The Holy Hose | Sweeping bursts of piercing water droplets at the nearest enemy | **The Hose of Judgment** — sustained double torrent, pierces everything | Industrial Pressure | **Implemented** |
| Cheek Clap | Circular shockwave | Glute Force Trauma — concentric shockwaves | TBD | Phase 2/3 |
| Arc Discharge | Chain lightning | The Crackening — lightning storms | TBD | Phase 2/3 |
| Seismic Step | Quake every few steps | The Final Footstep — fissures | TBD | Phase 2/3 |
| Meme Barrage | Homing memes | The Viral Apocalypse — multiplying memes (capped) | TBD | Phase 2/3 |
| Outlook Overload | Meeting-invite projectiles | Mandatory Attendance — screen-wide calendar | Inbox Zero | Phase 2 |
| Teams Notification | Interrupting pings | The Meeting That Never Ends — persistent zone | Mandatory Overtime | Phase 2 |
| Kristall Overdose | Rapid carbonated shots | 767 Cans Later — can storm | Hydration Nation | Phase 2 |

### The Holy Hose (levels)

| Lv | Bonus |
|---|---|
| 1 | 4.5 dmg/droplet, 26 droplets/s, 0.5 s burst, 0.9 s recharge, pierce 1, range 150 |
| 2 | +2 damage |
| 3 | +1 jet |
| 4 | +40% burst length, +15% reach |
| 5 | +1 pierce, +2 damage |
| 6 | 20% faster recharge |
| 7 | +3 damage, +30% knockback |
| 8 | +1 jet |
| EVO | Hose of Judgment: 2 jets, 13 dmg, pierces all, 1.8 s torrents |

## 6. Upgrades

Level-up offers three weighted, distinct choices. Maxed or invalid options never
appear; when nothing is left, consumables (Coffee Break, Petty Cash) fill in.
Limits: 6 weapons, 6 passives. Rarity tiers are modelled in data but unused so far.

| Passive | Effect per level | Max |
|---|---|---|
| Industrial Pressure | +20% water damage | 5 |
| Mandatory Overtime | +15% attack speed | 5 |
| Administrative Immunity | +10% damage resistance | 5 |
| Inbox Zero | −8% cooldowns | 5 |
| Hydration Nation | +0.6 HP/s | 5 |
| Council Approval | +1 projectile | 2 |
| Unpaid Overtime | +15% XP | 5 |
| The Hose Must Flow | +15% area and reach | 5 |
| Sprint Planning | +10% move speed | 5 |
| Protein Shake | +20 max HP | 5 |
| Magnetic Personality | +30% pickup radius | 5 |

Stat formula: `(base + flat) × (1 + Σpercent) × Πmult`.

## 7. Enemies

| Enemy | Tier | Behavior | Notes | Status |
|---|---|---|---|---|
| Dry One | Normal | Chase | The baseline husk | **Implemented** |
| Unregistered Hours | Normal | Weaving chase, arrives in clusters | Fast, fragile timesheets | **Implemented** |
| The Thirsty | Normal | Chase, sprints when close | Punishes standing still | **Implemented** |
| Corporate Bureaucrat | Elite | Chase + regenerating shield | Drops a Supply Crate (free upgrade) | **Implemented** |
| The Great Drying | Boss | Drought zones, dust nova, summons; enrages at 50% | Final boss of the Wastelands | **Implemented** |
| Meeting Invites, Outlook Demons, Corrupted Memes | Normal | Swarm / pack / erratic | | Phase 2 |
| SNORRI.EXE, The Chairman | Boss | Digital barrages / paperwork summons | | Phase 3 |

Boss attacks are always telegraphed: ground circles fill before detonating, and the
boss strobes white before a nova.

## 8. Stage: The Dry Wastelands (10:00)

Cracked earth, dead bushes, broken pipes, rusted barrels and ruined Council of Hose
monuments on an endless scrolling plain.

| Time | Event |
|---|---|
| 0:00 | Dry Ones trickle in, ramping all run |
| 1:00 | Unregistered Hours clusters begin |
| 2:30 | The Thirsty join |
| 3:00 | Elite: Corporate Bureaucrat |
| 5:00 | **Timesheet Audit** — encirclement by Unregistered Hours |
| 6:00 | Elite |
| 8:00 | **Middle Management** — two elites |
| 9:00 | **Last Call** — encirclement by The Thirsty |
| 10:00 | Boss: **The Great Drying**. Kill it to win. |

Enemy health grows +32%/min and damage +8%/min. Population cap: 350.

Future stages: The Council Chambers, Microsoft Teams Meeting Hell, The Church of
the Holy Hose, Hólmsheiði Prison, Stockholm+ Hotel, The HoseZone Layer, The Final Drying.

## 9. Pickups

| Pickup | Effect |
|---|---|
| XP droplet (blue / green / gold) | 1 / 4+ / 20+ XP |
| Hose Coin | Persistent currency |
| Kristall can | Heal 25 |
| Magnet | Vacuum all XP and coins |
| Supply Crate | Free 3-choice upgrade (elite drop) |

## 10. Meta progression (Phase 4)

Hose Coins persist today (`user://save.json`) along with lifetime stats. Planned
spends: character unlocks, permanent stat upgrades, rerolls/banishes, achievements.

## 11. Presentation

640×360 internal resolution, integer-scaled to 1920×1080. Navy + brass UI with
water-blue accents; Press Start 2P for titles, Silkscreen for body. Boss arrivals
get letterbox bars and a warning banner. Audio is all hook-driven
(`AudioManager.play(&"id")`); see `ASSET_GUIDE.md`.

## 12. Open design questions

- Elite/boss roster per stage and whether stages have unique modifiers.
- Evolution requirements for the non-Hose weapons.
- Whether The Shopkeeper introduces a mid-run shop or works through crates only.
- Final look of The Memeweaver and The Shopkeeper (needs canon reference).
