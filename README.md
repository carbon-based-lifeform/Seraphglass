# Seraphglass — Forever 0.15.0-beta

Dark fantasy UI for World of Warcraft Forever: reflective liquid orbs, painted angel artwork, a unified equipment/inventory window, four five-button action rows, and bronze/crimson native UI accents. Built from [RothUI wow12.0](https://github.com/zorker/rothui/tree/master/wow12.0), with no external oUF dependency.

## Install this build

1. Exit WoW. Replace the existing `Interface/AddOns/Seraphglass` folder with this version. Disable/remove the older `RothForever` copy so both cannot load together.
2. The path must end in `AddOns/Seraphglass/Seraphglass.toc`, with `media` beside the Lua files. A GitHub ZIP's `Seraphglass-main` folder must be renamed to `Seraphglass`.
3. Enable Seraphglass and enter the game. Chat should say **Seraphglass 0.15.0-beta loaded**. Run `/sgui status` to check the version, client build, and each module.
4. Press **B**. Equipment and bags should open together in the angel frame. `/sgui bags` also toggles the window and reports initialization problems.

Target interface: `16001`. Implementation checked against Blizzard's **forever branch**, client `1.60.1.69977`, source commit `c6e89983189e4f626f549204a23c2d2bea93080a`. This is a beta client; in-game validation is still required.

## Fixed in 0.15

The custom equipment buttons requested a nonexistent `ItemButtonTemplate`. Forever defines `ItemButton` as an intrinsic type; passing the nonexistent template could abort inventory initialization before bag hooks were installed. The port now uses that intrinsic directly, waits for native bags and combat to finish, and marks initialization complete only after the unified frame is connected. Failures are printed in chat and included in `/sgui status`.

Each equipment slot uses its own explicit inventory ID and reads its icon from `GetInventoryItemTexture`. Empty slots show the correct placeholder. Head, Chest, Waist, Legs and Feet form the center column; weapons flank Legs, with rings and trinkets at the bottom. The native combined inventory grid sits below, with native search, sorting, tooltips, money, and item interaction. There is no 3D model. Protected layout changes defer until combat ends.

Empty action buttons were disappearing because the native `SetShowGrid` path ignores insecure callers. The addon now sets the supported grid attribute outside combat. All four rows show their first five slots even when empty. Native spell execution, bindings, paging, cooldowns and vehicle visibility are retained. Slots 6–12 on these four bars are hidden; move desired actions to the first five slots. Other enabled bars keep their positions and receive the same thin bronze wrapping.

## RothUI feature coverage

| Upstream component | Seraphglass implementation |
| --- | --- |
| `oUF_Diablo` player health/power | Liquid glass orbs, power colors, native power interpolation, self-target/menu/tooltip, movable HUD. Instant health changes plus white flash and slow crimson trail follow the requested design. |
| Player low-health highlight | Native color curve adds a crimson glass warning below 31% health; readable-health fallback on clients without curves. |
| Player dispellable-debuff highlight | Native `CustomAuraContainerTemplate` handles `HARMFUL\|DISPELLABLE` and colors the glass by debuff type, including restricted aura handling inside Blizzard's engine. |
| Player absorbs | Blizzard shield texture, incoming healing, clipped orb boundary and readable-value overshield indication. |
| `rLayout/chat` | Dark backing, edit box above chat, free arrow-key movement, hidden chat button strips, temporary-window styling. |
| `rLayout/darkmode` | Bronze target/focus/boss/minimap/quest/status-bar accents, compact party/raid health blending, buff borders, action-button wraps, smaller additive spell-proc overlays. |
| `rLayout/tooltip` | Bronze framing and class/reaction name colors; native guild, level, AFK and item information retained. No secret tooltip strings are rebuilt. |
| `rLayout/spellalert` | Focus cast/channel/empower sound, optional via `/sgui option focus off`. |
| `rLayout/vignette` | Local chat and screen alerts for minimap vignettes, per-zone deduplication and upstream name exclusions. Feature-gated when the API is absent. |
| `rLayout/statedriver` | Optional Ctrl visibility for bags/micro menu and Alt for tracking bars. The four main rows retain their native visibility; literal upstream Shift/combat bar rules would conflict with the requested layout. |
| Options | Saved alert/visibility toggles and version/module diagnostics. HUD position/scale remain session-only. |

The `wow12.0/oUF_Diablo` layout spawns the **player only**; its party code is commented out. There is no additional target/focus/raid layout waiting to be copied from this folder. Those frames retain Blizzard's functionality with Seraphglass styling.

`rModelOrbTemplate`, `rModelOrbConfig`, `rModelDB` and `rModelViewer` implement configurable 3D model scenes and their authoring tools. Seraphglass replaces their orb presentation with the approved liquid/glass art; their editors and model database are not bundled. `rRadialProgressTest` and `rSettingsExample` are development examples. Older standalone oUF elements, LootRollMover and ncImprovedMerchant supplied separately are not part of this `wow12.0` feature port.

## Commands

| Command | Effect |
| --- | --- |
| `/sgui status` | Installed version, client build, module readiness/errors |
| `/sgui bags` | Toggle unified inventory |
| `/sgui bars` | Reapply the four-row layout outside combat |
| `/sgui option focus on/off` | Focus cast sound |
| `/sgui option vignette on/off` | Minimap vignette alerts |
| `/sgui option lowhealth on/off` | Low-health glass warning |
| `/sgui option dispel on/off` | Dispellable-debuff glass warning |
| `/sgui option visibility on/off` | Optional Roth auxiliary visibility; off by default |
| `/sgui show` / `hide` | Show/hide orb HUD |
| `/sgui art` | Toggle orb figure artwork |
| `/sgui scale 0.8` | HUD scale from 0.5 to 1.5, outside combat |
| `/sgui unlock` / `lock` | Move HUD using center handle |
| `/sgui playerframe hide` / `show` | Hide/restore Blizzard player unit frame using a secure visibility driver |

`/seraphglass` is an alias. New toggles use `SeraphglassDB` SavedVariables; persistence depends on the beta client's save/restore behavior. Enabling native combined bags and additional bars changes their Blizzard preferences.

## Validation and limits

Run `luahbtex --luaonly RegressionTests.lua` from the addon folder. The regression harness checks the actual Forever intrinsic/template distinction, all 19 equipment IDs/icons, empty-slot restoration and clicks, delayed native loading, combat deferral, combined-mode CVar reentry, unified open/close, repeat initialization, and 20 visible empty action slots. This file is not loaded by the addon.

All shipped Lua files pass syntax checks. These checks are **not a WoW runtime test**: restricted execution, native aura rendering, bag interactions in combat, Edit Mode and visual alignment need an in-game check. If something fails, run `/console scriptErrors 1`, then `/reload`, and send the exact error plus `/sgui status` output. Optional APIs report unavailable instead of preventing inventory loading.

RothUI fill textures and adapted code are credited to zork/Erik Raetz under the included MIT license. Angel/figure art was generated for this independent addon.
