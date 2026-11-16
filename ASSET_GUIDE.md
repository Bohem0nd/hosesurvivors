# HOSE SURVIVORS — Asset Guide

Everything under `assets/sprites` and `assets/audio` is a **generated placeholder**
(`tools/gen_art.py`, `tools/gen_audio.py`). To replace one, overwrite the file
with the same name and frame layout — no code or data changes needed. To use a
different size or frame count, edit the matching `.tres` in `resources/`.

## Global art rules

- Internal resolution **640×360**, integer-scaled. Draw at 1:1; never pre-scale.
- PNG, RGBA, nearest-neighbour. No anti-aliasing, no soft alpha except shadows/vignette.
- Sprite sheets are **horizontal strips** of equal-width frames.
- Characters and enemies face **right**; the game flips them.
- 1-px dark outline on actors so they read on the sandy ground.
- Light from the top-left.
- Palette anchors: ground sand `#A07850`, water `#54ACFF` / `#C8EAFF`, brass `#D6A840`,
  UI navy `#12162B`, danger red `#E2483C`.

## Characters (`assets/sprites/characters/`)

| File | Frame | Frames | Notes |
|---|---|---|---|
| `jon_hose.png` | 16×24 | 6 (idle ×2, walk ×4) | Placeholder exists |
| `locked_silhouette.png` | 16×24 | 1 | Roster silhouette for locked heroes |

Target for final art: 24×32 or 32×32 per frame, idle 4 f, walk 6–8 f, hurt 1 f,
death 4–6 f. Frame ranges are set on `CharacterData` (`frame_count`, `idle_frames`, `walk_frames`).

**Canon (must be respected):**

- **Jon Hose** — muscular, heavily built; short dark-brown hair; fitted black
  T-shirt; dark pants; enormous industrial hose with a brass-and-black nozzle.
- **Ass Man** — glossy royal-blue bodysuit, large gold "ASS MAN" lettering,
  metallic gold gloves, boots and belt.
- **The Crackler** — youthful; short dark buzz cut; black leather jacket;
  bright blue lightning-bolt emblem; electric-blue energy around him.
- **Quakewalker** — stern; close-cropped dark hair; dark work clothes; heavy boots.
- **The Memeweaver** — *no canon appearance supplied.* Do not invent; request reference.
- **The Shopkeeper** — friendly middle-aged man; *further details needed.*

## Weapons (`assets/sprites/weapons/`)

| File | Size | Notes |
|---|---|---|
| `hose_nozzle.png` | 16×8 | Points right; rotates around its left third. Brass + black |
| `water_droplet.png` | 13×5 | Points right; bright head, darker tail |
| `judgment_torrent.png` | 16×6 | Evolved droplet; white core, gold tail |
| `dust_orb.png` | 8×6 | Boss projectile; spins |

Icons for weapons/upgrades: `assets/sprites/ui/icons/<id>.png`, **16×16**, with a
1-px dark frame. One per upgrade id in `resources/upgrades/` and weapon id in `resources/weapons/`.

## Enemies (`assets/sprites/enemies/`)

| File | Frame | Frames | Brief |
|---|---|---|---|
| `dry_one.png` | 16×16 | 2 | Cracked, sand-coloured husk with ember eyes |
| `unregistered_hours.png` | 16×16 | 2 | Furious floating timesheet, red "overdue" marks |
| `thirsty.png` | 16×16 | 2 | Gaunt purple figure, gaping mouth, lolling tongue |
| `bureaucrat.png` | 20×25 | 2 | Grey suit, red tie, glasses, briefcase |
| `great_drying.png` | 64×64 | 2 | Colossal cracked sun-baked face, horns of dust, glowing eyes |

Final targets: 4-frame walk loops, optional 1-frame hurt. `EnemyData.hframes` and
`anim_fps` control playback; `radius` is the gameplay hit circle (keep art within it ±30%).

## Pickups (`assets/sprites/pickups/`)

`xp_small.png` 6×5 (blue) · `xp_medium.png` 8×8 (green) · `xp_large.png` 10×10 (gold) ·
`coin.png` 8×8 · `kristall.png` 8×12 (sparkling-water can) · `magnet.png` 10×7 ·
`supply_crate.png` 16×12. Hierarchy must stay obvious: bigger + warmer = more valuable.

## Environment (`assets/sprites/environment/`)

| File | Size | Notes |
|---|---|---|
| `wasteland_ground.png` | 128×128 | **Must tile seamlessly** on both axes |
| `dead_bush.png` | 20×18 | Props are anchored at bottom-centre |
| `broken_pipe.png` | 40×14 | |
| `barrel.png` | 14×18 | |
| `monument.png` | 34×44 | Ruined Council of Hose monument |
| `skull.png` | 7×6 | |

Props and their spawn weights are listed on `resources/stages/dry_wastelands.tres`.

## Effects / UI

`effects/shadow.png` 16×6 soft blob · `effects/vignette.png` 640×360 overlay ·
`ui/icon.png` 128×128 app icon. UI panels are drawn with theme styleboxes
(`scripts/autoload/ui_theme.gd`); no 9-patch art is required yet.

## Fonts (`assets/fonts/`)

Press Start 2P (titles) and Silkscreen (body), both SIL Open Font License; licence
texts sit next to the files. Use sizes in multiples of 8.

## Audio

Format: WAV or OGG, mono is fine for SFX. A sound hook is just a filename:
`AudioManager.play(&"water_hit")` plays `assets/audio/sfx/water_hit.wav` (or `.ogg`).
Missing files are skipped silently, so hooks can be added before sounds exist.

| Hook id | Trigger | Direction for final sound |
|---|---|---|
| `hose_spray` | Hose burst starts | Pressurised hiss with body, ~0.4 s |
| `water_hit` | Droplet hits enemy (throttled) | Short wet slap, pitch-varied |
| `enemy_death` | Enemy dies | Dry crumble / pop |
| `xp_pickup` | XP collected | Tiny rising blip |
| `coin_pickup` | Coin collected | Bright two-note chime |
| `heal` | Kristall collected | Can crack + fizz |
| `level_up` | Level-up screen opens | Triumphant arpeggio |
| `evolution` | Weapon evolves | Big rising fanfare |
| `player_hurt` | Player takes damage | Low thud + grunt |
| `elite_intro` | Elite or encirclement event | Ominous three-note sting |
| `boss_intro` | Boss arrives | Deep drone/roar, ~1.5 s |
| `telegraph` | Boss attack wind-up | Rising warning tone |
| `boss_attack` | Zone detonates / nova fires | Heavy dusty impact |
| `crate_open` | Crate or magnet collected | Sparkly reveal |
| `ui_move`, `ui_select` | Menu focus / confirm | Short clicks |
| `victory`, `defeat` | Run ends | Fanfare / sad descent |

Music: `assets/audio/music/wasteland_loop.wav` — a seamless loop referenced by the
stage resource. Target: energetic, original retro electronic/metal, 140–160 BPM.

## Licensing

Only original or properly licensed assets. Record the source and licence of any
third-party file next to it (as done for the fonts).
