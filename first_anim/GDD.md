# Autobattle — Game Design Document

## 1. Overview

Prototype auto-battler / combat sandbox built on the Panthera animation system in Defold. One player-controlled "Survivor" auto-fights waves of enemies with zero direct input during combat — the player configures loadout and difficulty beforehand, then presses Play and watches the simulation resolve.

Two scenes:
- **autobattle** — the real game loop (setup → battle → result).
- **sandbox** — a dev/test scene for animation and rig iteration, not part of the game loop.

## 2. Core Loop

1. **Setup (idle phase):** player picks a Fight (1–3), a Wave number (difficulty multiplier, unbounded), and a loadout (weapon / body / head skin).
2. **Play:** press PLAY → player and enemy group spawn, phase = `running`.
3. **Resolve:** each unit auto-targets the nearest enemy, walks into range, attacks on cooldown. No manual control during the fight beyond Pause and Speed (1x/2x/4x).
4. **End:** phase = `finished` on Victory (all enemies dead) or Defeat (player dead). Reset returns to idle.

Phases: `idle → running ⇄ paused → finished → idle`. Fight/Wave selection is locked while a battle is in progress or paused.

## 3. Entities

### Player — "Survivor"
Base stats ([data/player.json](data/player.json)): HP 100, move speed 130, attack speed 100, damage 10, defense 0. Default loadout: AK-47, Kevlar armor, gasmask.

### Unit types ([data/units.json](data/units.json))
- **human** — bipedal rig, uses weapons (melee/ranged), has a muzzle for ranged weapons.
- **rat** — quadruped rig, no weapons, fixed melee (range 110, hit delay 0.3s). Reused (via `scale`/`tint`) for Rat / Dog / Boar / Burelom — same rig, different stat block and visual scale.

### Enemy templates ([data/enemies.json](data/enemies.json))
| Enemy | Unit | HP | Move | AtkSpd | Dmg | Def | Weapon |
|---|---|---|---|---|---|---|---|
| Rat | rat | 30 | 130 | 120 | 4 | 0 | – |
| Dog | rat | 50 | 115 | 100 | 6 | 5 | – |
| Boar | rat | 120 | 75 | 60 | 12 | 20 | – |
| Burelom (Boss) | rat | 250 | 60 | 40 | 25 | 40 | – |
| Bandit | human | 40 | 120 | 110 | 5 | 0 | bat |
| Bandit Geared | human | 60 | 100 | 100 | 8 | 10 | stabbing_common |
| Bandit Assault | human | 140 | 70 | 55 | 14 | 25 | tire_iron |
| Bandit Sniper | human | 45 | 95 | 70 | 18 | 2 | AK-47 |

### Weapons ([data/weapons.json](data/weapons.json))
Types: `impact` (bat, tire iron), `stabbing` (knives), `pistol`, `rifle` (AK-47, M4 — 3-round burst + 10% slow-on-hit for 0.5s), `shotgun` (splash radius 180, hits up to 5 targets, 50% damage mult, knockback), `fists` (unarmed fallback). Each weapon defines attack range, hit delay, and (for ranged) muzzle offset + fire delays for the cosmetic bullet.

### Skins ([data/skins.json](data/skins.json))
Cosmetic attachment slots on the human rig: body (none / Kevlar armor) and head (none / gasmask). Purely visual, no stat effect.

### Fights / Waves ([data/waves.json](data/waves.json))
3 hand-authored enemy compositions ("Fights"):
1. Bandit + 2 Rats
2. 2 Dogs + Bandit Sniper
3. Bandit Assault + Burelom (Boss)

## 4. Difficulty Scaling

Enemy **HP** and **Damage** only are scaled at spawn (AttackSpeed and Defense stay archetypal, so unit "shape" is preserved):

```
scale = Growth(wave) * RandomFactor * FightModifier
Growth(n) = 1 + 0.05 * n^0.7
RandomFactor ~ U(0.85, 1.35), rolled once per battle (shared by every enemy in the fight)
FightModifier = 0.8 / 1.0 / 1.2  for Fight 1 / 2 / 3
```

Wave is an unbounded difficulty knob the player can dial up independent of which Fight (enemy composition) is selected.

## 5. Combat Rules

- **Damage:** `FinalDamage = floor(Damage * DamageMult * 100 / (100 + Defense) + 0.5)`, applied per target (so shotgun splash is mitigated by each target's own defense).
- **Targeting:** always nearest enemy; no aggro/threat system.
- **Attack cycle:** walk into `attack_range` → wait `RANGE_ENTRY_DELAY` (0.3s) settle → attack on cooldown (`attack_speed` stat) → hit lands after weapon `hit_delay`.
- **Burst weapons** (rifles): total damage split across 3 timed shots.
- **Splash** (shotgun): player-only, hits up to `max_targets` enemies within `splash_radius` of the primary target.
- **Slow:** rifle hits apply a temporary move-speed debuff (10% for 0.5s).
- **Knockback:** cosmetic recoil only, no logical displacement — doesn't affect the FSM.
- Units are depth-sorted back-to-front by Y each frame so rigs never visually interleave.

## 6. Presentation / FX
- Floating damage numbers on hit ([modules/dmg_number.lua](modules/dmg_number.lua)).
- Cosmetic flying projectiles for ranged weapons layered over the hitscan resolution ([modules/projectile.lua](modules/projectile.lua)).
- Hit sparkles, muzzle flash, smoke puffs, ground smudges on death ([rigs/human](rigs/human), [rigs/shared](rigs/shared)).
- Discrete tinted spawn zones per role (player / melee / ranged / boss) for readability.

## 7. Control Panel (autobattle_panel.gui)
- Play / Pause, Speed toggle (1x/2x/4x), Reset.
- Fight select (1–3), Wave number input.
- Loadout pickers: weapon, body skin, head skin (only entries with `show_in_ui = true` are listed).
- Scrolling battle log (trimmed to `theme.log_max_lines`).
- Status banner (Ready / Battle in progress / Victory / Defeat / Paused).

## 8. Not Yet Implemented / Open Questions
- No persistence, meta-progression, or currency — every session starts from defaults.
- No player skill/ability system beyond equipped weapon.
- Only 3 Fights authored; Wave scaling is the only long-term difficulty lever.
- `sandbox` scene exists purely for animation/rig testing, not a real second mode.
