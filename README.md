# Seraphglass Orbs — 0.21.0-beta

An **orb-only addon for World of Warcraft Forever**. Health and power live inside reflective glass spheres with layered liquid, bronze guardian frames, and restrained combat effects. There is no inventory replacement, action-bar layout, central angel painting, damage-meter skin, chat/tooltip skin, minimap change, or vignette alert system.

## Install / migrate from the whole-UI version

Exit WoW and replace the **entire** `Interface/AddOns/Seraphglass` folder with this build. The final path must be `AddOns/Seraphglass/Seraphglass.toc`. Disable the old `RothForever` addon if it remains installed. Restart and check `/sgui status` for **0.21.0-beta**.

A restart removes the previous version's runtime hooks, reparenting, visibility drivers and frame changes. This build hides Blizzard's player unit frame by default using a secure visibility driver; `/sgui playerframe show` restores it and saves that preference. Native bag and extra-action-bar preferences enabled by older builds may remain enabled: use Blizzard's settings to choose them. The old addon never recorded their original values, so this version cannot reliably restore those preferences automatically.

## Orb features

- **Living liquid:** three independently rotating, circularly masked texture layers per orb, 24 rising motes, reflective glass highlights, and the existing flanking sculpted guardians. The native fill clips the effects as resources fall.
- **Low-health warning:** a strong crimson glow pulses below **20% health**. A native color curve handles restricted combat health without Lua comparisons. Reduced-motion mode leaves a steady warning instead.
- **Power color:** blue mana, gold energy, red rage, violet insanity and other power types. Switch to class colors or set a custom RGB tint.
- **Shield crescent:** Blizzard's `raidframe-shield-fill` and `RaidFrame-Shield-Overlay` textures follow the inner-facing half of the health orb's rim. A native status bar controls its rising height and clamps shields above maximum health. An additional overshield cue appears when the overcap amount is readable. This crescent represents shields relative to maximum health; it does not occupy the health liquid.
- **Incoming healing and damage trail:** healing extends above the current health inside the glass. Damage drops immediately, flashes white briefly, then drains a darker red trail over roughly a second. Restricted combat health uses the native interpolation fallback.
- **Curved player cast ring:** a gold arc traces the power orb during a cast; a pale blue arc drains for channels. Native duration objects pass progress directly to the radial texture API. The ring and spell name disappear when casting stops. Blizzard's own cast bar is left intact.
- **Secondary resources:** small glass gems form a lower semicircle for combo points, Holy Power, Soul Shards, Chi, Arcane Charges or Essence when the class/spec exposes them. Death Knights receive six rune gems with native cooldown swipes. Unsupported/inactive resources are hidden. These are resource indicators, not extra action buttons.
- **Independent orb placement:** `/sgui unlock` reveals a separate handle over each orb. Drag either orb; its sculpture, cast/shield rings, class gems and status icons follow it. `/sgui lock` hides the handles. Positions and scale survive reloads. Layout changes are blocked during combat; handles disappear automatically in combat.
- **Health-orb status medallions:** combat swords pulse quickly; the resting icon breathes slowly. Death or incoming resurrection replaces that state icon when needed. Small leadership/assistant, assigned group role, PvP and raid-marker badges follow the upper/inner rim. Only applicable badges appear. Reduced motion keeps these icons steady.

The experimental 3D model viewports have been removed, including the old saved `models` option. The glass uses only circularly masked liquid textures and particles.

PoE-style mana reservation is **not simulated**. WoW does not expose a generic reserved-mana pool, and runes are a separate resource. The orb always reflects the actual current resource and its native maximum.

## Controls

| Command | Result |
| --- | --- |
| `/sgui status` | Version, client build and orb-module diagnostics |
| `/sgui option motion off` | Stop cosmetic liquid motion, motes and status-icon pulses; retain resource updates |
| `/sgui option lowhealth on/off` | 20% pulse / steady warning |
| `/sgui option resources on/off` | Class-resource semicircle |
| `/sgui option cast on/off` | Player cast/channel ring |
| `/sgui option indicators on/off` | Health-orb status medallions |
| `/sgui option figures on/off` | Sculpted guardian artwork |
| `/sgui color power` | Color follows active resource type |
| `/sgui color class` | Player-class color |
| `/sgui color 0.2 0.4 1` | Custom power-orb RGB, each component 0–1 |
| `/sgui scale 0.8` | Scale orb HUD outside combat (0.5–1.5) |
| `/sgui unlock` / `lock` | Show/hide both independent orb drag handles |
| `/sgui reset` | Restore both default orb positions and scale outside combat |
| `/sgui show` / `hide` | Show/hide HUD outside combat |
| `/sgui art` | Toggle guardian figures |
| `/sgui playerframe hide` / `show` | Native player-frame visibility; hidden by default, preference saved |

`/seraphglass` is an alias. Orb options, colors, independent positions, scale and player-frame preference use SavedVariables. Position settings are shared across characters. No keybindings are reassigned. Click an orb to target yourself; right-click for the player menu.

## Implementation and validation

Target: interface `16001`; API signatures checked against Blizzard's `forever` source, client `1.60.1.69977`. All loaded modules are orb-related: Core, the orb HUD, Layout, Effects, Resources, and Indicators.

Run `luahbtex --luaonly OrbTests.lua` from this directory. The mock checks orb-only startup without retired whole-UI modules, independent saved movement, deferred player-frame changes, status transitions, removed model creation, circular masks, overcap inputs, color modes, reduced motion, and opaque health/resource/cast-duration pass-through. All Lua files pass syntax checks. These checks cannot validate actual rendering or WoW's restricted execution environment; in-game checks are still necessary, especially dragging at different UI scales, casts/channels in combat, and rune cooldowns.

If a feature fails, enable `/console scriptErrors 1`, reload, and retain its exact error plus `/sgui status`. Features requiring unavailable APIs report that limitation.

Original fill, glass, glow and radial textures come from [zork's RothUI wow12.0](https://github.com/zorker/rothui/tree/master/wow12.0), under the included MIT license (Erik Raetz). The sculpted guardian artwork was generated for Seraphglass. This is an independent addon, not an upstream RothUI release.
