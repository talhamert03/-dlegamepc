# Autopilot — development plan for unattended shifts

The product owner is away. Each scheduled shift Claude works through this list as a senior game developer,
designer and tester. Goal: a polished, premium PC idle RPG that is ready to ship.

## Rules for every shift

1. Branch: `claude/party-grinding-game-design-kdffl4` only. Pull it first, never merge to main, never open a PR.
2. Pick the first unchecked item in **Backlog** (or the item marked *in progress*). Work in small, finished steps.
3. Before every commit: `godot --headless res://tests/TestRunner.tscn` must pass, and visual work is checked with
   screenshots (`--screenshot` flags in `scripts/ui/main.gd`). Never commit broken code; never skip or weaken tests.
4. Commit + push after each finished step. Tick the item here, add a line to **Shift log** (date, what, result).
5. Taste or business decisions (prices, monetisation, removing content, big design changes) are not taken alone:
   write them under **Questions for the owner** and move on to the next item.
6. Turkish first: every new text has `tr` and `en` in `data/strings.json`; consistent terms (eşya, yetenek, can…).
7. Keep the premium look: UISkin / Fancy controls, carved frames, no plain web-like widgets.
8. Patch notes: add the player-facing changes of the day to `data/patch_notes.json`.
9. A shift is a full working block, not one task: after an item is finished, go straight to the next one and keep
   going until the usage limit stops the session or the next shift is about to start. Never end a shift early
   because "a step is done". Commit + push after every finished step (small commits), so a cut-off by the usage
   limit loses at most the step in progress; the next shift picks it up from the log.
10. When the backlog is empty, play the game again end to end (bot + screenshots), find the weakest part and add
    new items — the work only ends when the game is ready to ship.

## Backlog (in order)

- [x] 1. Tavern: card-flip reveal when a hero is recruited (rarity glow, special SSR reveal, sound)
- [x] 2. Chest opening: lid burst, rarity light, items fly into the bag, skippable
- [x] 3. Pets window redesign (stable stalls, name plates, owned glow, clear bonuses)
- [x] 4. Stash window redesign (iron-bound chest interior, tab plates, sort/filter)
- [x] 5. Blacksmith: Combine, Salvage and Craft tabs rebuilt to the Enhance tab's standard
- [x] 6. Steam achievements wired (ids, unlock calls, offline queue, docs for Steamworks setup)
- [x] 7. Text / translation sweep: every string TR+EN, terms, clipping at 1.5x/2x, tooltips
- [x] 8. Economy check with the balance bot: gold/XP curves, tavern prices, blacksmith costs, shop value
- [x] 9. Full playthrough Normal -> Nightmare -> Hell (bot + manual screenshots): walls, boredom spots, fixes
- [x] 10. First-hour experience pass: pacing, tutorial hints, unlock highlights, goal ribbon wording
- [x] 11. Combat feel: per-class hit effects, crit feedback, skill VFX audit, boss telegraphs
- [x] 12. Remaining windows audit: away report, growth, runes, party, portrait — premium consistency
- [x] 13. Audio pass: missing SFX, volume balance, UI sounds on every control
- [x] 14. Performance: idle CPU/GPU, draw calls, long-session memory, 144 fps focus mode
- [x] 15. Endgame: tower floors, paragon, Hell rewards — reasons to keep playing
- [x] 16. Accessibility: text-size option, colour-blind safe rarity marks, key rebinding view
- [x] 17. Polish round: every panel at 1.5x/2x/2.5x, no clipping, no overlaps, consistent spacing
- [x] 18. Surfaces not yet reviewed: title screen, taskbar mini bar, item tooltip, right-click menu, confirm cards, toasts
- [x] 19. Resistance clarity: party resistances vs the zone's damage types (world card, status), red warning when short
- [x] 20. Seal economy: can a player reach SSR heroes (8 seals at lv30)? seal income per hour, tavern pacing
- [x] 21. Remove the unreachable windows (party, portrait, old skills) after moving anything still useful
- [x] 22. Session variety: daily quest pool, achievement pacing over the first 10 hours, small surprises
- [x] 23. Hero barks: merged pools, wire legendary / idle / night / boss-down, 100+ class lines
- [x] 24. Treasure goblin achievements (catch 1 / 25) + Steam icon kit refresh
- [x] 25. Personal join / level-up lines for every recruitable hero (48), from their descriptions

## PRIORITY: Visual quality pass 2 (owner request 2026-10-09) — work top to bottom
Owner: "Windows only, stop spending time on Linux. Much more visible visual change: every window, the bag, the rune page,
buttons, menus, popups must feel premium. Change ALL fonts, the current ones are hard to read. Senior-level, every detail."
Rule for every item: before/after screenshots at 2x AND 4x, TR and EN, nothing clipped; commit per item.
- [x] 73. Windows only: Linux export + artifact removed from CI, README updated
- [x] 74. New type system: Rubik (UI 500/600), Eczar (titles 700/800), Lora (prose 500); retune every size, kill the Cinzel-era
      uppercase-and-shrink hacks, check all 18 panels + strip + tooltip + title/intro
- [x] 75. Window frame v2: richer carved frame, title ribbon, inner bevel, ambient light; one shared component, all panels
- [x] 76. Buttons v2: primary / secondary / danger / icon buttons with clear hover, press, disabled states; one family everywhere
- [x] 77. Tabs, segmented controls, toggles, sliders v2 (same family as the buttons)
- [x] 78. Bag / inventory v2: slot wells, rarity frames, item hover, filters bar, capacity bar, sort/sell row
- [x] 79. Hero panel v2: equipment ring around the portrait, slot silhouettes, stat strip
- [x] 80. Rune page v2: background map, node art, connections, purchased glow, detail card
- [x] 81. Popups v2: confirm, tooltip, context menu, toasts, away report, recruit reveal: one family, entrance animation
- [x] 82. Blacksmith, tavern, shop, world, growth, quests, codex, settings: content pass in the new style
- [x] 83. Control panel + strip HUD in the new type and button family
- [x] 84. Final consistency audit: spacing grid, colours, every panel side by side at 2x / 4x

## Visual pass 3 (keeps the owner's "clearly visible, premium" direction going)

- [x] 85. Item tooltip v2: rarity header band, item art in a jewel well, gem dividers, compare arrows aligned in a column
- [x] 86. Strip HUD plaques (zone, goal, quick buttons) in the popup/medallion family
- [x] 87. World panel: stage medallions, path, selected-stage card in the new family
- [x] 88. Panel open/close: frame glint + content fade, consistent with popups
- [x] 89. Shop cards and supporter detail: frame + button family pass
- [x] 90. Title screen menu plaques and intro window in the new family

## Replay backlog 3 (shift 2026-10-09 09:03, sub-tabs and special screens replayed)

- [x] 91. Status > Skills: the "Class advance" button sits on top of the level-30 row's four skill icons (hides them); move it beside the row label / into the row header
- [x] 92. Status > Skills: tier rows are flat dark boxes; recessed wells with a gilded rule, unlocked rows lit, locked rows dimmed with the lock
- [x] 93. Away report: best-loot slots and level-up portraits in the jewel-slot / button family
- [x] 94. Codex > Bestiary: unknown entries are bare "?" boxes; recessed wells with a faint silhouette / crest and a hover state
- [x] 95. Town signposts (Tavern / Shop) and tower floor plaque in the HUD plate family

## Replay backlog 4 (shift 2026-10-09, battle strip replay: tutorial, boss, elites, statuses, toasts)

- [x] 96. Elite / mini-boss name plates overlapped when the units stood together (Kızgın Tavşan over Yeşil Slime): strip lays them out side by side, leader line when nudged
- [x] 97. Tutorial / bark speech bubble in the popup family (leather + slim walnut frame, brass tail, speaker in a jewel tile)
- [x] 98. Dialog replay (sell-all, loot filter, shop detail, chest open, ending, quest done): modal cards still used the old iron 'ornate' frame -> popup family; UISkin.ornate itself redrawn as a slim gilded section frame with brass corner fittings (hero sheet, Status parchment, shop sign, loot well)
- [x] 99. Taskbar (mini) mode: bar frame = slim walnut 9-slice (0.4x), zone plate in the HUD plate style, chest bubble in the popup family with a brass tail and a wash of the chest colour
- [x] 100. Status panel cards (hero header, summary stat chips, skill detail) still used a cold purple-grey fill: new UISkin.card (raised warm lacquer, lit top lip, bronze/accent bezel)
- [x] 101. Formation stage: flat purple 'dusk' fill -> a slice of the current zone's HD panorama (tower = void), ground line on the slots, slow drift, dimmed for readability
- [x] 102. Chest showcase as a treasure vault: slate wall, velvet drape with folds and shaded edges, a light shaft in the chest's colour, stone plinth with a gilded edge; shelf chests sit in wells, chosen/hovered lit in the chest colour
- [x] 103. Blacksmith enhance stage as a smithy: slate wall, warm forge light from the left, brick hearth with an arched mouth and flickering flame tongues (the anvil, embers and glow stay)

## Replay backlog 5 (shift 2026-10-10 09:03, intro + first minutes replay)

- [x] 104. Intro: flying crystal shards wore hard-edged translucent discs (read as bubbles) -> 4-step soft glow + a bright facet edge; letterbox bars feathered into the picture instead of a hard black cut
- [x] 105. Notification bursts (several achievements at once) stacked a tower of plates over the windows: same-title toasts within their life fold into one plate ('×3', newest detail), at most 3 plates (oldest hurries out), the rest settle down smoothly when one leaves
- [x] 106. World panel leftovers: act selectors on UISkin.tab, difficulty plate = brown button with a difficulty-coloured inner rule, tower plate = blue button (disabled while locked), map in a well with the section frame, zone card = UISkin.card, enemy previews (UITheme.slot_button, shared) = jewel-slot wells, readiness well washed in the verdict colour
- [x] 107. Skill effects were faint on the bright strip (anthem a few tiny notes, arcane orb a dot, blade storm a pale ring, comet barely visible): SkillFx gets an additive bloom layer (the _add material existed but was never assigned) fed by halos at columns, impacts, orbs, domes, bolts and marks; anthem = pulsing gold ring + edged notes, arcane orb = bigger orb with sparkling arc trail and turning rune ring, blade storm = four whirling steel crescents, comet = tapered flame tail, burning head and a ground shock ring
- [x] 108. Battle banners ('Boss approaching...', 'X arrived!', zone name) were a flat dark box: now a ribbon of the window-title family (crimson with cream text for bosses, walnut with gold text otherwise) with folded tails and a soft shadow; UISkin.ribbon takes optional colours
- [x] 109. Boss HP gauge: recessed channel, glossy blood fill with a pale damage trail and a bright leading edge, gilded bezel with spiked brass end caps, name on a small title ribbon tucked behind the gauge, skull in a red seal
- [x] 110. Level-up and loot beam effects were thin pale strokes: additive blend for both; level-up = 3-layer pillar, golden ground ring racing out, climbing four-point stars; loot beam = taller 3-layer column in the rarity colour that rises in, glowing ground pool with a slow ripple. New --vfxshot screenshot flag
- [x] 111. Tavern rarity tags (flat grey/blue/gold pills with dark text) -> enamel badges in a gilded bezel with a gloss line and cream title-font text, SSR with a gold jewel

## Visual overhaul backlog (owner request, 2026-10-07) — work top to bottom

Every item ends with screenshots at 2x and 4x (and 5x where it matters), TR and EN, before/after kept in the log.

**A. HD quality**
- [x] 26. Battle backgrounds: 128 strips are 480x84 and blur at 4K — upscale to >= 1920x336 (AI upscale if credits allow, otherwise a careful Lanczos + detail pass), keep the parallax layers
- [x] 27. Item icons (100 painted, 96 px) and skill icons (159, 96 px): 192 px masters where possible, sharper mipmaps, check every icon at 5x
- [x] 28. Hero portraits / full art (48, 315x560 and 202x360): upscale for tavern cards, recruit reveal and Hero window at 4K
- [x] 29. Enemy and boss paintings (112, 322x360) and pets (10): upscale, check the living-illustration rig still lines up
- [x] 30. UI glyph icons (76, 80 px, ui_hd): redraw or upscale to 160 px, one consistent stroke weight and lighting
- [x] 31. Fonts at every scale: hinting / oversampling check, no blurry 7 px text at 2x, pixel-snapped labels

**B. Windows (frames and layout)**
- [x] 32. Window frame v2: richer carved corners, per-window crest in the title ribbon, subtle animated rim light on focus
- [x] 33. Hero window: equipment slots with slot-shaped silhouettes, portrait frame ornament, party switcher chips
- [x] 34. Status window: attribute rows with engraved plates, skill tree tier pillars, detail card art
- [x] 35. Blacksmith, Stash, Pets, Chests: second pass to the same finish (materials shelf, anvil scene, stable lights)
- [x] 36. World map: hand-painted map look per act, path animation between nodes, cleared-zone laurel
- [x] 37. Tavern and Shop: card hover lift, rarity foil on SR/SSR cards, shelf lighting
- [x] 38. Growth, Runes, Quests, Codex, Settings, DPS, Away: consistency audit (spacing grid, section plaques, scroll bars)
- [x] 39. Scroll bars, tabs, sliders, toggles, tooltips: one themed set everywhere (no default Godot widget left)

**C. Menus and screens**
- [x] 40. Title screen: animated key art (light rays, drifting embers), logo shine, menu plaque hover/press animation
- [x] 41. Intro cinematic: panel transitions, text reveal, music sync, skip button style
- [x] 42. Ending screen, confirm cards, context menu, toasts, recruit reveal: final polish pass
- [x] 43. Bottom control panel (taskbar side): medallion icons redrawn, hover glow, notification badges

**D. Icons and identity**
- [x] 44. App / taskbar / tray icon at 16-256 px, Steam library capsule set (header, capsule, hero, logo)
- [x] 45. Status effect, element and stat icons: one family (fire, cold, lightning, chaos, holy, stun, poison...)
- [x] 46. Currency and material icons (gold, seals, shards, badges, dusts, essences): redraw as a matched set

**E. Battle strip**
- [x] 47. Unit readability at 2x-5x: outline, shadow, HP bar style, name plates for elites/bosses
- [x] 48. Skill VFX second pass per class (impact frames, glow, particles at high scale)
- [x] 49. HUD plaques (zone, goal ribbon, boss bar) re-rendered crisp at 5x
- [x] 50. Weather and zone atmosphere per act, kept subtle

## Replay backlog (added 2026-10-07 after the visual overhaul replay)
- [x] 51. Pets panel: empty collection says where pets come from; Added Damage tooltip said "flat" but the stat is a percent
- [x] 52. English pass: every panel and the strip with --lang=en at 1x and 4x, fix overflow / clipped labels
- [x] 53. Status icons over units: screenshot flag that applies statuses, check size and spacing at 2x-5x
- [x] 54. Damage numbers vs. elite name plates and the boss bar: keep numbers from covering plates
- [x] 55. Item tooltip at 4x: frame, affix rows, compare column, set / legendary text
- [x] 56. Shop product art: use the new material icons (seals, shards, essences) where products grant them

## Replay backlog 2 (shift 2026-10-07 16:21)
- [x] 72. One-time Kael tip per element when the zone hits with an element the party resists below 25% (waits for the intro hint, retried each wave so barks/tips do not swallow it)
- [x] 71. test_version_stamps_agree: patch notes "current" == project.godot version == Windows exe file_version (fails CI on drift; negative-checked)
- [x] 70. Unit tests (38/38, incl. save/backup fallback and Steam Cloud ordering) pass on the Windows engine under Wine; optional GODOT_WIN step in windows_smoke.sh
- [x] 69. Release builds ignore test flags (--fresh wiped the save, --allheroes/--level/--gear via --screenshot bypassed progression + leaderboard); only --lang=, --colorblind, --title remain; debug builds or IDLEPARTY_DEV=1 keep all
- [x] 68. *.import files were git-ignored, so CI re-imported all 1648 assets with defaults: no mipmaps on 676 textures, no lossy on 52 -> CI build blurrier when scaled and 48 MB bigger than what was tested. Now committed; fresh-clone export == local export
- [x] 67. tools/windows_smoke.sh: export + Wine headless boot (600 / 4000 frames) + Xvfb screenshot, fails on Godot errors; run before handing a build to the owner
- [x] 65. Windows exe icon + version info: modify_resources on, CI installs Wine + rcedit and writes the editor setting, then checks the stamp with pefile
- [x] 66. Exported builds logged 5 "Expected Image data size" errors: title-screen silhouettes built with create_from_data(mipmaps=false) on mipmapped portrait data -> empty rim light. clear_mipmaps + 256 px copy
- [x] 64. docs/WINDOWS_TEST.md: Turkish first-run checklist for the owner (transparency, click-through, taskbar mode, tray, audio, CPU, save); linked from README
- [x] 63. Version stamps aligned to 0.2.7 (project.godot said 0.2.0, the Windows exe file/product version 0.1.0.0); README corrected: the exe embeds the pck, one file
- [x] 62. README: "download and play" section at the top (owner downloaded the source ZIP and could not find the game)
- [x] 61. Settings scale row lists only scales that fit this screen
- [x] 60. Forced UI scale could exceed the screen (5x on 1080p = 2360 px strip); capped by max_fit_scale()
- [x] 59. Long-run log audit (80 s at 6x, full party): only benign warnings; removed the one real one (full-rect anchors on Main while WindowManager sets its size)
- [x] 58. Town showed the last zone's name + stage tag + wave pips on the plaque; now "Stonebridge Town" only
- [x] 57. Tutorial bubble could slide 35 px into the control block (clamp used 395 instead of the 360 px battle view)

## Questions for the owner
- Version numbers: patch notes, project.godot and the exe properties had drifted apart (0.2.7 / 0.2.0 / 0.1.0). I aligned them to 0.2.7. Should CI stamp the exe version from patch_notes "current" automatically on every build? (recommend: yes)

- **Difficulty pacing (bot, updated 2026-10-06 night):** with boss fatigue and treasure goblins the baseline bot now
  reaches Hell's final boss at ~47 h (Normal ~9 h, Nightmare ~22 h). A what-if run with Hell resistance -45 instead of
  -60 was not faster (run-to-run luck dominates). I now recommend keeping the penalties as they are. Your call.

- **Tavern seals pile up (bot, 30 h):** 22 seals by hour 2, 64 by hour 10, 107 by hour 29, while SR costs 2 and SSR 8.
  Seals never gate recruiting; gold does (SSR base 1.2M). Options: (a) leave it; (b) raise seal costs (SR 5, SSR 20) so
  seals pace SR/SSR; (c) give seals a second use (e.g. reroll the tavern's featured hero, or buy hero star shards).
  I lean to (b) or (c). Your call.

- **Download size (updated 2026-10-08):** the Windows download is now a 196 MB zip / 261 MB exe (CI had been ignoring the
  per-asset import settings; fixed in #68). Portraits and boss art are already lossy. Switching the remaining HD art
  (backgrounds, battle sprites, items) to lossy WebP ~0.9 would likely bring it to ~100-120 MB with barely visible change. Want it?

## Shift log

- 2026-10-06 — plan written, schedule set (4 shifts a day, Europe/Istanbul 08:52 / 12:52 / 16:52 / 20:52).
- 2026-10-06 shift 1 — #1 hero card-flip reveal (tavern + store), rarity-specific build-up, frames checked.
- 2026-10-06 shift 1 — #2 chest opening: seam light, rays, sparks/coins, rewards leap out, best-item beam, click to skip. (Fly-to-bag dropped: chests live in their own tab.)
- 2026-10-06 shift 1 — #3 pets stable: stalls with plates, collection bar, detail card with level pips; window 236x262.
- 2026-10-06 shift 1 — #4 stash: chest-interior bed, tab plates (coin/gem/lock), capacity bar, Sort, centred unlock price; window 206x262.
- 2026-10-06 shift 1 — #5 blacksmith combine/salvage/craft rebuilt to the enhance standard; Fancy.small_button added.
- 2026-10-06 shift 1 — #6 Steam achievements: startup sync for offline unlocks, 41 icon pairs + CSV (steam/achievements), docs/STEAM_ACHIEVEMENTS.md, id format test. Needs a real Steam build to verify.
- 2026-10-06 shift 1 — #7 text sweep: tools/i18n_audit.py (no missing keys, no half translations), F.lv() for level tags, MISS/BLOCK translated, EN overflow fixes (shop sign, rune title, tavern hint, quest wording).
- 2026-10-06 shift 1 — #8 economy: bot now recruits SR/SSR like a player and enhances 6 slots; 24 h run: Normal ~10 h, Nightmare done at ~23.5 h, Hell starts. Gold no longer hoarded. Found and fixed: hero star-up (soul shard sink + 2 achievements) was only in an unreachable window — now a star plate under the portrait in the Hero window. Nightmare walls -> question for the owner.
- 2026-10-06 shift 1 — #12 windows: away report rebuilt (time plaque, counting tiles, level-up chips, loot pop-in), growth guild cards + account tiles, language-switch script error fixed. Party and portrait windows are not reachable from any button (formation lives in the Hero window) — left in place, star-up moved out of them.
- 2026-10-06 shift 1 — #10 first hour: speech bubbles with portraits, one-time tips (chests, smith, runes) that survive the tutorial end, bot gets the Lyra gift. #11 combat: audited hit/crit/hitstop/shake/telegraph paths (all present), damage numbers now stack instead of overlapping. Boss fatigue added (3%/fail, max 30%).
- 2026-10-06 shift 1 — #9 playthrough: two 48 h bot runs through Normal, Nightmare, Hell; boss HP continuous, walls from resistance/damage multipliers (question for the owner). #13 audio: achievement toast + chime, tower sounds, combat sfx trimmed to one loudness (enemy blunt/dark hits were 5 dB louder than hero hits). No new sound files (Higgsfield credits 0).
- 2026-10-06 shift 1 — #14 performance: new --perf=SECS [--speed=N] probe. 30 game-minutes at 6x: memory 44.5 -> 46.3 MB and flat, objects flat, 0 orphan nodes (no leak). Battle sim ~14 us/frame, unit views + strip ~0.15 ms/frame. Strip draws ~600-700 calls (fine on a GPU; this container renders in software). Idle 15 fps unfocused, 30 in taskbar mode, 30/60/144 focused already in settings.
- 2026-10-06 shift 1 — #15 endgame: reviewed tower (star dust -> +13..+15 enhancing, badges and pets every 10 floors, mythic essence every 50, leaderboard), paragon (stat points past the cap), Hell. Tower button tooltip now lists the next reward floors.
- 2026-10-06 shift 1 — #16 accessibility: the unused `colorblind` setting now draws a rarity shape on every item slot (toggle in Settings), full hotkey list. Text size = the UI scale option (2x-5x). Key rebinding not built (hotkeys are listed read-only).
- 2026-10-06 shift 1 — #17 polish: every window shot in English; fixed the skill cooldown spilling out of the card, the 'E' equipped marker, the empty chests pedestal. Found three windows nothing opens (party, portrait, old skills window) — their features live in Hero / Status now.
- 2026-10-06 shift 1 — #18 surfaces: title menu gets ornate plaque buttons (Fancy.plaque_button), bulk sell rows drawn (checkbox, rarity gem, count), confirm cards use the wooden buttons; tooltip, toasts, context menu already custom. #19: already covered by ZoneInfo (readiness verdict, weakest hero's effective resistance, stuck hints naming the element and target).
- 2026-10-06 shift 1 — #21: removed party_panel, portrait_panel and the old hero_panel (skills) — nothing opened them; star-up already moved to the Hero window, skills live in Status, formation in the Hero window.
- 2026-10-06 shift 1 — #20 seals: plentiful (100+ by day 2), never the gate -> question for the owner.
- 2026-10-06 shift 1 — #22 variety: daily pool 6 -> 9 (chests, elites, salvage), Treasure Goblin event (0.8% of waves from zone 2: approaches, lingers 1.4 s, runs; caught = 12x elite gold + golden chest), gilded look and flee turn.
- 2026-10-06 shift 1 — #23 barks: 15 -> 151 lines; legendary/idle/night lines were never triggered, now wired (boss down, legendary drop, idle every 2-4 min).
- 2026-10-06 shift 1 — #24: ACH_TREASURE_1, ACH_TREASURE_25, ACH_ELITES_500 (44 achievements), Steam icon kit + CSV regenerated. New Steamworks entries needed when the app is set up.
- 2026-10-06 shift 1 — #25: a personal join line for all 48 heroes (from signature + faction), always spoken on joining; test guards it. Barks: 193 lines.
- 2026-10-06 shift 1 — goal ribbon after level 25: zone boss, empty party slot, class advancement, next difficulty, tower reward floor; long goals shrink to fit. Recruit card shows the hero's greeting.
- 2026-10-06 shift 3 — codex What's New as cards in the reading font; strings of removed windows dropped; item tooltip header with icon in a rarity-lit slot; fixed double % in affix labels ('+%15 % Savunma'), test guards it; static check of all 159 skill texts clean; runes window reviewed at mid game.
- 2026-10-06 shift 3 — Windows export (Godot 4.4.1 templates) builds cleanly: one 236 MB exe with the pack embedded. Not run on Windows (no machine here).
- 2026-10-06 shift 3 — achievements show rewards, bestiary tips (kills, element, zones), quest refresh countdown + midnight renewal, daily gift countdown, unused PopupMenu helper removed. 24 h regression bot: clean, 36 boss fails (fatigue working).
- 2026-10-06 shift 3 — 48 h baseline vs Hell res -45 what-if: baseline reaches Hell a4_z10 at 47 h; softer res gave no gain -> recommend no change.
- 2026-10-07 — owner asked for a full visual overhaul list: items 26-50 added (HD quality, windows, menus, icons, battle strip). Shifts now start at 12:00.
- 2026-10-07 shift — #26: the game already used HD panoramas (1075x336, 4x); rebuilt all 29 from the 1344 px masters at native 1344x420 (5x, JPEG q95 4:4:4), HD_BG_SCALE 4 -> 5, importer gets --offline. 4K screenshot sharp, ground line unchanged. The 480x84 strips are only a fallback and never used (every zone has HD art). Higgsfield credits still 0.
- 2026-10-07 shift — #27: item icons re-cut from the 1024 px sheets at 144 px (native cells ~140 px, were shrunk to 96), family icons regenerated; procedural skill icons rebuilt at 192 px. Checked at 4x.
- 2026-10-07 shift — #28: portraits rebuilt at native size from art_src/raw/heroes (~640x1017, tools/art/rebuild_portraits.py) and imported as lossy WebP q0.92: 15 MB imported instead of ~67 MB lossless at 560 px. Title poster, recruit card, Hero bust sharp at 4K. Battle sprites (360 px) and head icons (128 px) already fit 5x.
- 2026-10-07 shift — #29: battle sprites (360 px) and pets (240 px) already reach 1:1 at 5x in their views. The intro cinematic drew 4 act bosses ~3x larger than their sprites at 4K: new hd/boss_art at native size (tools/art/rebuild_boss_art.py, lossy import, 6.4 MB), SpriteLib.boss_art() with sprite fallback.
- 2026-10-07 shift — #30: the 50 vector UI glyphs (build_ui_hd.py, 0..100 grid) rendered at 128 px instead of 56; same design, logical sizes come from metadata so nothing moved. Checked control panel and Hero bar at 4x.
- 2026-10-07 shift — #31: the window uses CONTENT_SCALE_MODE_CANVAS_ITEMS, so fonts are rasterised at the final size (no upscaled text); all 14 fonts use light hinting + subpixel positioning. Smallest text is 6 logical px (12 px at 2x). No change needed.
- 2026-10-07 shift — #32: PanelWindow draws emblem seals (per-window icon, PANEL_ICON) beside the title ribbon and a light sweep around the inner rule on open / raise (tween, subclasses' _process untouched). --sweepshot flag.
- 2026-10-07 shift — #33: portrait gets gilded corner brackets with gold studs and a ruby keystone; empty slots already show slot silhouettes, party chips already carry alerts.
- 2026-10-07 shift — #34: Status attributes on engraved plates (main stat gilded), ornamental section headings with rules, zebra stat rows, drawn + buttons. Skill tab was already rebuilt earlier.
- 2026-10-07 shift — #35: forge embers rising over the enhance anvil and a breathing forge glow; the enhance stage was only redrawn on the combine tab (fixed). Stash, Pets, Chests were rebuilt on 2026-10-06 and reviewed again, no change.
- 2026-10-07 shift — #36: animated gold trail over the opened road (node 1 to the furthest open zone), laurel under cleared medallions. Per-act painted maps already exist (map_act1..4).
- 2026-10-07 shift — #37: tavern cards lift + brighten on hover, slanted foil band sweeps SR (silver) / SSR (gold) cards, card names shrink to fit (Archmage Thalor). Shop shelves get lantern spill + lit plank edges. --tavernfilter= flag.
- 2026-10-07 shift — #38: audited Growth, Runes, Quests, Codex, Settings, DPS, Away side by side. Settings/Quests/DPS/Away/Codex already share section plaques, Fancy.bar and card wells; the outlier was Growth factions (bare text + hsep), now cards with faction spine, crest and gilded rim when active. Scroll bars left to #39.
- 2026-10-07 shift — #39: VScrollBar track/grabber and TooltipPanel/TooltipLabel now drawn by GameStyleBox (scroll, grab, tip kinds); root window gets the theme so popup tooltips inherit it. Tabs (W.tabs), toggles and sliders (Fancy) were already themed. --tipshot draws a sample tooltip (real ones are popup windows the capture misses).
- 2026-10-07 shift — #40: title poster gets 6 breathing god rays and 34 stateless embers drawn over the vignette; Fancy.plaque_button adds a hover light sweep (tween on meta) and a press squash with back-ease spring. Logo shine and lightning already existed. Screenshot mode now also saves title_hover.png.
- 2026-10-07 shift — #41: intro letterbox slides in over 0.7 s, beat openings are eyelid wipes with a gold seam instead of a flat black fade, ui_travel whoosh per beat, music switches to boss at beat 2 and town at beat 4, Skip is a Fancy plaque. Text reveal + subtitle plate + beat dots already existed. Screenshot mode saves intro_open.png.
- 2026-10-07 shift — #42: ending panel (now 340x210) redrawn on HD scenes (throne+Morvath, void, temple, town at dawn with party portraits, meadow + red eyes), faceted crystal, subtitle plate, beat dots. W.confirm sizes to text, top medallion (! danger / ? normal), veil fade + card pop. ContextMenu drop-in + hover diamond. Toasts and recruit reveal reviewed, no change. --polishshot flag.
- 2026-10-07 shift — #43: new g_mug glyph (build_ui_hd.py) for Tavern medallion + window seal, medallion hover halo + brighter/larger glyph, Tavern badge when any locked hero is affordable (Tavern.can_afford), system icon row and gold/level row inset away from the frame's corner gems (they overlapped power/menu icons and Sv text).
- 2026-10-07 shift — #44: tools/art/build_store_art.py builds the icon (crystal + sword medallion, simplified < 48 px) as icon.png 256 + icon.ico 16..256 (export_presets application/icon set; Godot only stamps the .exe icon when rcedit is configured, Windows untested) and the Steam set in steam/store_art: header 920x430, small 462x174, main 1232x706, vertical 748x896, library 600x900, library hero 3840x1240 (no text, background upscaled + blurred), library logo 1280. All from the game's own forest scene + portraits + Cinzel fonts.
- 2026-10-07 shift — #45: tools/art/build_status_icons.py -> 16 st_* enamel-disc icons (6 elements, 9 statuses, buff). Unit status pips (were 2x2 squares) now 5 px icons, max 4; world threat chips use them. Emoji in text (fonts had none, fell back to system glyphs) removed; DejaVuSans-Bold bundled (Bitstream Vera licence in assets/fonts) as fallback for every UI font so ✓ ★ ⚔ ▶ ✖ match on all OSes; ⌛/🔒 (not in DejaVu) replaced. Strip pips not caught in a screenshot yet.
- 2026-10-07 shift — #46: tools/art/build_material_icons.py paints mat_<id> for gold + 9 materials (shared light, outline, shadow); gold.png now the coin stack (build_ui_hd skips its old ring glyph). Quests, Codex rewards, Blacksmith costs, tavern seal counter and guild purse use them; three essences no longer share the gem glyph.
- 2026-10-07 shift — #47: reviewed the strip at 4x: shadows, framed HP bars and shader outlines (elite purple, boss red, treasure gold) were already in. Added name plates (element disc + name) for elites and mini-bosses (visual.miniboss flag from the sim). Found blocky square hit sparks (vfx_node._px) -> #48, and floating skill names tucked behind the zone plaque -> #49. --elites flag.
- 2026-10-07 shift — #48: VfxNode._px is now a haloed soft dot (fixes every square spark), _shaft gradient for level-up / loot beam / summon, hit gets a core flash + rays, crit a flash + ring, burst an expanding ring, lightning a glow pass, meteor a halo, telegraph a warning triangle. SkillFx columns (holy beam, sun burst) and blizzard haze use edge-fading gradients instead of rects. Checked all 23 SkillFx kinds at 4x via --fxtest=all.
- 2026-10-07 shift — #49: plaques, goal ribbon and boss bar are vector-drawn and already crisp at 4x (checked 3840x2160). Fixed layering: SkillFx z 24 (relative -> 44, over the HUD at 40) now 4; floating texts start no higher than y 21 so skill names clear the plaque. unit_hd dissolve noise cells shrunk to ~1/3 logical px (death frame not caught in a shot).
- 2026-10-07 shift — #50: bug found: weather was drawn in StripView._draw, i.e. under the HD background sprite child, so it never showed. Moved to its own Node2D layer between background and units, redrawn as soft shapes (circles/ellipses), sizes tuned at 4x, and mapped the 11 themes that had none (meadow/town pollen, temple motes, camp/throne/temple_dark embers, harbor fog, ruins/library/hall/castle dust). Visual backlog 26-50 complete.
- 2026-10-07 shift — replay after #50: hero/stats/bag/stash/pets/chests reviewed at Lv55 with gear. Fixed: pets empty state lists sources, Added Damage tooltip (percent, negatives from the Treasure Hunter's Ring are by design). Added replay backlog 51-56.
- 2026-10-07 shift — #52: all 15 panels + strip shot with --lang=en. Only overflows: quest CLAIM text (now shrinks to fit the seal) and simultaneous skill names overlapping (number stacking now uses label widths and a longer window for wide labels, and stacks downwards when the plaque clamp would merge them).
- 2026-10-07 shift — #53: --statusshot puts 2-4 long statuses on the first enemies; at 2x and 4x the 5 px st_* icons read clearly over the bar, spacing ok, max 4 respected. No change needed.
- 2026-10-07 shift — #54: damage/skill numbers over plated units start 9 px higher (above the plate); plates of tall elites clamp below strip y 15 so they never hide under the goal ribbon. Boss bar already protected by the y 21 floor from #49. Heavy fights still crowd numbers a little (by design: stacking caps at 3).
- 2026-10-07 shift — #55: item tooltip at 4x is crisp (fonts at final size). Added a rarity accent (gradient band + top line, none for common/plain text tips); fixed lowercase TR affix name 'can' -> 'Can'. Compare column not shown in this shot (item not wearable by Kael).
- 2026-10-07 shift — #56: checked all shop tabs: no product grants seals, shards or essences (packs give heroes, chests, gold, supporter bonuses, the hourglass), so no material icon belongs there. No change. Replay backlog 51-56 done; visual + replay work this shift: #37-#56.
- 2026-10-07 shift 16:21 — #57: tutorial speech bubble clamped to the battle view (356 - width). Checked with --tutorial at 4 s and 12 s.
- 2026-10-07 shift 16:21 — #58: plaque in town shows town_name, hides the stage tag and wave pips (restored by _on_phase on leaving). Checked with --town at 4x.
- 2026-10-07 shift 16:21 — replay: town, Endless Tower (new --tower flag), World 2-4 maps reviewed, no issues. Perf probe: 1080p 60 fps / 4K ~20 fps under xvfb software rendering; TIME_PROCESS grows with resolution so it is render-bound on llvmpipe, not script-bound; ~600 canvas draw calls. Needs a check on real GPU hardware (owner).
- 2026-10-07 shift 20:03 — #59: 80 s run at 6x speed: no script errors; warnings are dummy audio / V-Sync (headless) and exit-time leaks. Main.tscn had full-rect anchors while WindowManager assigns desktop.size -> 'non-equal opposite anchors' warning; anchors dropped, layout identical in a screenshot.
- 2026-10-07 shift 20:03 — #60: compute_scale caps Settings 'scale' at max_fit_scale() (strip width + strip + tallest panel height must fit the usable rect). --scale=N flag: 1080p 5x -> 2.5x, 4K 5x -> 5x, layout checked. The Settings row still highlights the chosen value (5x) while 2.5x is used; owner may want a note there. Taskbar mini mode (--mini) re-checked, fine.
- 2026-10-07 shift 20:03 — #61: Settings 'Scale' only offers Auto + the 2x..5x steps <= max_fit_scale() (1080p: Auto/2x; 4K: all). Withdrew the owner question about it (UX detail, not a product call). Note: --scale persists in settings; reset with --scale=0.
- 2026-10-08 shift 12:03 — #62: README gets a Turkish step-by-step 'Oyunu indir ve oyna' section (Actions -> latest green CI -> IdleParty-windows artifact -> extract -> exe; SmartScreen note; source-ZIP warning).
- 2026-10-08 shift 12:03 — #63: config/version 0.2.7, Windows file_version/product_version 0.2.7.0 (Explorer > Properties showed 0.1). Nothing reads config/version at runtime. README step 4: single-file exe (embed_pck=true), not exe + pck. Owner question added: keep version stamps in sync per release by hand or bump automatically from patch_notes current?
- 2026-10-08 shift 12:03 — #64: reviewed Windows paths (gl_compatibility + per-pixel transparency, passthrough polygon, tray via StatusIndicator on Windows, user dir %APPDATA%/IdleParty, Steam off because no GodotSteam addon). Wrote docs/WINDOWS_TEST.md for the owner's first run.
- 2026-10-08 shift 12:03 — #65/#66: exported the Windows build here, stamped it via Wine + rcedit (icon groups now point at our 6 icons, FileVersion 0.2.7.0, ProductName set), and booted the exe under Wine headless for 600 frames: that surfaced 5 image-size errors (title silhouettes; only in exported builds, not in the editor). Fixed; Wine run is clean apart from exit-time leak notices. CI step mirrors the local setup; the CI result itself is checked next push.
- 2026-10-08 shift 12:03 — #67: Windows smoke script added and passing (saves go to %APPDATA%/IdleParty/saves with 2 backups; the exe under Wine renders the same layout as Linux). Notes: wineserver must be restarted between headless and Xvfb runs; WASAPI/no-audio errors are Wine environment noise.
- 2026-10-08 shift 12:03 — CI run 157 verified by downloading IdleParty-windows: ProductName/FileVersion stamped, all 6 RT_ICON entries are our PNGs. Note: CI exe is 309 MB vs 261 MB in a local export of the same commit (both embed the pck) — worth a look under the download-size question.
- 2026-10-08 shift 12:03 — #68: removed *.import from game/.gitignore and committed 1648 .import files. Verified with a fresh clone (no .godot cache): import + Windows export gives the same pack as local (162.7 MB data, exe 261 MB vs CI's 309 MB before). Owners' earlier downloads were built without mipmaps on HD art.
- 2026-10-08 shift 12:03 — #69: Main.user_args() filters flags in release builds; windows_smoke.sh sets IDLEPARTY_DEV=1. CI run 160 (with .import files): Windows zip 244 -> 196 MB, Linux 236 -> 188 MB.
- 2026-10-08 shift 12:03 — #69 verified on the Windows release exe under Wine: '--fresh --screenshot' without IDLEPARTY_DEV is ignored (game keeps running, no screenshots, save untouched); with IDLEPARTY_DEV=1 screenshot mode runs.
- 2026-10-08 shift 16:20 — 8 h balance bot: act 4 zone 6 at 8 h, lv 37, 143 deaths; boss fails a2_z10 / a3_z05 at 3% hp (fine). a3_z06 is the softest wall (5.5-6.25 h, deaths 81->136). Seals 50 at 8 h. Both fall under the open owner questions (pacing, seals); no change.
- 2026-10-08 shift 16:20 — #70: save path reviewed (tmp + rename, sha256 checksum, 3 backups, fallback chain, cloud newer-wins). Ran the test suite with Godot_v4.4.1 win64 console under Wine: 38 passed, 0 failed. Offline sim reviewed: capped at 12 h (+bonuses), clock rollback ignored, item count capped.
- 2026-10-08 shift 16:20 — #71: version guard test (39 tests now). Colorblind mode re-checked after the visual overhaul: rarity shapes still drawn on every slot, tooltips name the rarity; no change.
- 2026-10-08 shift 16:20 — full windows_smoke.sh with GODOT_WIN: export OK, Wine boots clean, Windows-engine unit tests 39/39, screenshot rendered -> OK.
- 2026-10-08 shift 16:20 — Windows release exe under Wine: title poster (rim light back after #66) and intro beat 3 render correctly. Remaining open items are owner decisions (pacing, seals, download size, auto version stamp) and a real-Windows test by the owner (docs/WINDOWS_TEST.md).
- 2026-10-08 shift 20:03 — text audit: every data/*.json pair has tr+en, no empty strings, all dynamic keys (chest_/guild_/quest_/ready_/shop_badge_/shop_tab_/skill_/weight_) resolve. a3_z06 death spike: double-element zone (chaos + fire); [corrected later: chaos already appears in a3_z02/a3_z04, so not 'first chaos']. Noted for the pacing question.
- 2026-10-08 shift 20:03 — #72: Tutorial._check_elements on zone change + each wave; key elem_<el>; string tut_element (TR/EN). Verified in a run at a3_z06: the tip fires ~24 s in, after the intro. First version was overwritten by the wave-1 intro hint, fixed by letting the intro go first.
- 2026-10-09 — owner: Windows only; visual quality pass 2 is top priority (#73-84). #73 done.
- 2026-10-09 — #74: fonts compared in-context (10 body, 12 title, 5 prose candidates; Almendra/Amaranth lack ş). Chosen Rubik 500/600 (+1 px word spacing via FontVariation: words ran together at 7-8 px), Eczar 700/800, Lora 500, static instances cut from the variable fonts with fontTools, OFL files added. UITheme.upper() fixes Turkish caps (to_upper gave EVCIL, DIZILIS). Checked all 14 panels + tooltip + strip + title/intro at 2x TR; 4K EN sweep via new tools/shoot_panels.sh pending review.
- 2026-10-09 — #74 4K EN sweep (16 panels + strip) reviewed: readable, no clipping. Removed 6 unused font families (Fira, Alegreya, Nunito, Jersey10, Pixelify, Tiny5) from the build; Cinzel kept only for the Steam art script.
- 2026-10-09 — #75: painted HD window materials (tools/art/build_frame_hd.py, 6 px per logical px): walnut 9-slice with a gold rule, mitred corners and brass/ruby corner fittings, plus a seamless leather tile. UISkin.panel draws them (edges repeated a whole number of times so the grain never seams), keeps the band/crest/ribbon/tooled rule; vector frame, studs and corner caps removed. All 16 panels + strip checked at 2x TR, quests at 4x EN; tests 39/39.
- 2026-10-09 — #76: one button family in UISkin.button (dark outline, gilded bezel / bronze on wooden kinds, lacquered face with gloss band, turned-plank end shading, faint grain on wood; hover = HSV brighten + two-ring halo, pressed = sinks 1 px under an inner shadow, disabled = dull stone). Fancy.small_button now draws through it; icon buttons dim and spring on press. New --gallery screenshot mode (DebugGallery) shows every colour x state plus tabs/toggles/segmented/slider/bar; checked at 2x and 4x, all 16 panels at 2x.
- 2026-10-09 — #77: new UISkin.groove (recessed channel) and UISkin.tab. Active tab = raised crimson button of the #76 family with a gold pointer, inactive = recessed groove whose rim lights on hover; segmented = groove with the chosen segment as a raised gold button and engraved dividers; toggle = groove with a lit emerald channel and sheen; slider = groove, glossy gold fill, quarter ticks; bars = groove, glass sheen, bright leading edge. Gallery at 2x/4x + all 16 panels at 2x checked.
- 2026-10-09 — #78: item slots are jewel tiles now (rarity bevel frame, deep face lit by a smooth 8-step rarity glow, glass highlight, gilded corner brackets on legendary/mythic; empty = recessed well; hover = gold ring + halo). Rarity passed through from tooltip and blacksmith too. New Fancy.capacity pill (green -> amber at 75% -> red at 95%, tooltip explains auto-sell when full, checked against GameState.add_loot) replaces the bare 50/60 text in hero + inventory panels; +10 plate redrawn as a gold button beside it. 2x TR sweep + 4x zoom.
- 2026-10-09 — #79: portrait is a lit stage now (faction-tinted backdrop, 9-step spotlight, faint rays, floor shadow, side vignettes), name on a dark glass plate with a gilded rule + lozenge, level on a bronze-rimmed plaque sized to the text. New painted HD parchment tile (fibres, mottling, specks; build_frame_hd.py) used by every UISkin.parchment (hero sheet, Status list, ...). Equipment ring/silhouettes come from #78 slots. Stat strip not added: the DPS line + Status panel already carry it and the portrait has no spare row at 2x.
- 2026-10-09 — #80: rune board on a painted HD veined-slate tile (marble veins from a turbulence-bent sine, seamless) that pans with the board, an engraved summoning circle round the core (3 slowly turning rings, ticks, rune dashes, warm glow), edge vignette. Links: lit = energy channel (glow, colour, white core) with a pulse flowing outwards; open = engraved groove; locked = faint scratch. Stones: octagon with drop shadow, inner bevel, inner light when learned, breathing halo; core gets a gold ring, capstones 8 orbiting gems. Rank gauge sunk into the stone rim (segments <= 5 ranks, bar above; the old pips ran into the neighbours). Detail card: branch-colour header wash, the real stone, rank pips. Checked 2x TR + 4x EN with --runes.
- 2026-10-09 — #81: one popup family, UISkin.popup(k): the window materials scaled down (soft shadow, HD leather, walnut 9-slice at k x size so the brass/ruby corners stay; frame9 got a scale). Used by theme tooltips, UIFrame tooltip (item tooltips), context menu (hover row = the orange button), toasts (icon in a well) and confirm cards (k 0.6, gilded rule over the buttons, 4 px taller so text never sits on it). Away report is a PanelWindow (frame v2 already); recruit reveal checked: the quote looked cut but a toast was covering it (expected z order). Entrance animations already existed (context menu scale/fade, confirm pop, toast fade). 2x TR + 4x EN.
- 2026-10-09 — #82: content sweep of all 16 panels in the new family. Tavern rarity filter = Fancy.segmented (was loose gold/brown buttons); faction Active/Inactive pill = green button / empty groove and no longer stretched to the header height; growth intro text padded off the frame; every W.tabs strip reserves 3 px for the active tab's pointer (it touched the next row in blacksmith/codex/settings). Blacksmith, world, shop, quests, codex, settings, pets, stats, chests already pick up frame/buttons/tabs/slots/bars from #75-#81; no other stray styles found.
- 2026-10-09 — #83: medallion v2 (control panel, hero bottom bar, strip quick buttons): eight rivets on the bronze bezel, a gloss crescent on the disc, inner shadow when pressed, the same two-ring halo as the buttons on hover. Control panel/strip frames come from #75 (UIFrame strip kind = UISkin.panel); zone + goal plaques and fonts already match. Checked strip + hero bar at 4x.
- 2026-10-09 — #84: audit sweeps: all 16 panels + strip at 2x TR and 4x EN (shoot_panels.sh), gallery at 2x/4x, popups at 2x TR/4x EN. One fix: segmented plaques had 5 px text padding, so the raised gold segment crowded its label (Türkçe, Taskbar, 15, All); now 7 px, settings rows still fit in TR and EN. Leftover: label() still clamps font_title >= 13 to 11 (Cinzel era); only the strip banner uses 13 and the clamp keeps it inside the strip, so it stays. Visual pass 2 (#73-#84) complete.
- 2026-10-09 — #85: item tooltip dividers are gilded rules fading at both ends with a gem in the rarity colour (legendary orange, set green), never two in a row; compare line leads with ▲/▼; sell price has the gold icon; a legendary's description is hidden when it only restates its stat line. New --itemtip screenshot flag (random legendary + compare). 2x TR/EN, 4x EN.
- 2026-10-09 — Windows smoke (Wine) caught 13824x 'Invalid polygon data, triangulation failed': the #83 medallion gloss crescent crossed itself near its ends (inner arc started above the outer one). Inner arc now shares the end points and skips them; 0 errors. tools/shoot_panels.sh now keeps per-panel logs and prints engine errors (ALSA noise filtered); gallery, runes, popups, itemtip, recruit reveal scanned clean.
- 2026-10-09 — #86: zone and goal plaques share one _plate(): smoked glass, lit top lip, bronze bezel, a gilded lozenge at each end. Stage tag stays a flat enamel tag with a lit edge (the button bevel at 8 px tall made '1-1' muddy, tried and reverted). Quick buttons are medallions (#83). 4x TR.
- 2026-10-09 — #87: world stage picker in the button family (chosen = gold, open = wood, boss = red lacquer, locked = groove; green 'you are here' ring kept); DPS-need gauge on a groove with a lit fill edge. Windows smoke re-run after the polygon fix: == OK, exported exe renders the HD frame/leather/parchment under Wine.
- 2026-10-09 — #88: open/close already had scale+fade (window_manager) and a light sweep on open/focus; the sweep now runs along the new gold rule (5.6 px in, it was still on the old 2.6 px pinstripe, i.e. over the wood) and only one sweep tween lives at a time (open + focus used to fight over _sweep). An extra sweep trigger from window_manager was tried and removed as redundant (panel_window already defers one on open).
- 2026-10-09 — #89: shop category tabs moved onto UISkin.tab (raised crimson + gold pointer / recessed groove), the chosen one keeps a wash of its category velvet; cards, ribbons and price plates already matched. 4x TR.
- 2026-10-09 — #90: title/intro cinema window framed by the windows' painted walnut 9-slice at 1.4x (gold rule on the picture edge, brass/ruby corners) instead of the thin vector ornate border; menu plaques kept. One title run logged an intermittent 'triangulation failed': UISkin.rrect now drops repeated vertices (rad == half side made two corners meet) and returns nothing for zero-size rects, fill/stroke skip empty shapes; 4 title runs + full 16-panel sweep clean.
- 2026-10-09 09:03 shift — replay of sub-tabs/special screens (hero formation/chests, status skills, smith enhance/salvage/craft, growth guild/account, codex bestiary/news, away, tower, town; no engine errors) -> backlog #91-#95. #91: the class-advance call-out now seals its row (smoked pane over the skills, gold seal-plate with gilded rules and lozenges across the row) instead of a small button pasted over the icons. #92: tier rows are recessed wells; reached tiers glow warm with a bronze rim, tiers ahead stay cold and dim. 4x TR.
- 2026-10-09 — #93: away report: levelled-up heroes are green jewel tiles with a soft glow and a '+n' enamel pill (was a flat box + floating text); 'Best loot' caption gets a bronze rule and end lozenges. Loot slots were already ItemSlots (jewel family). 4x TR.
- 2026-10-09 — #94: bestiary bug + redesign. The creature art was mirrored with a negative-width rect, which misplaces AtlasTexture frames: unknown entries showed empty cells while sprite fragments leaked past the grid's right edge. Now mirrored with draw_set_transform on its own layer; unknown entries use a new silhouette.gdshader (flat cool colour, sprite alpha kept) so only the outline shows; known entries get a warm lamp (red for bosses); bosses wear a small red skull seal instead of a red outline; '?' moved to the corner; cells react to hover. 4x TR.
- 2026-10-09 — #95: town signs keep their chains/sway/rivets but the plank is now the painted walnut from frame_9.png (same grain as every window, brightened on hover); the tower floor plaque already uses the #86 plate. 4x TR.
- 2026-10-09 — battle strip replay (tutorial, boss, elites, --statusshot, toast; no engine errors) -> #96 #97, both done: StripView._spread_plates() lays elite/mini-boss plates left to right with a 2 px gap, centred on their units and clamped to the strip, UnitView draws a leader line when a plate is nudged > 3 px; the speech bubble uses UISkin.popup with a brass tail and the speaker in a jewel tile. 4x TR.
- 2026-10-09 — #98: dialog replay. Sell-all and loot-filter cards (hero panel) and the shop detail card were fill + iron 'ornate' (grey-green iron corner squares): now UISkin.popup(0.6). UISkin.ornate (still used for sections inside windows) redrawn: dark cut, bronze rule with lit inner edge, small brass L-fittings with a rivet, lozenges mid-edge; the iron palette is gone from it. Ending, chest opening, quest claim checked: already fine. 4x TR + 16-panel sweep, no engine errors.
- 2026-10-09 — #99: taskbar mini mode joined the family (it still had the thin vector border, a flat label and a purple-stroked bubble). Checked with --mini.
- 2026-10-09 — #100: code sweep for leftover old-palette fills (#2E2630, #2C2430, #1B1C23, #2A2228...): only the Status panel's three cards were left; they use the new UISkin.card. Default PanelContainer navy stylebox is unused (only the --tipshot sample builds one with the tooltip box). 2x TR, both Status tabs.
- 2026-10-09 — #101: formation stage draws the current zone's HD panorama (assets/hd/bg/<theme>.jpg, cached per theme) cropped to the bottom so the path meets the slot line, drifting slowly, tinted 0.78 + a top shade; old flat fill kept as fallback. 4x TR with 5 heroes.
- 2026-10-09 — #102: chest showcase redrawn as a vault (slate via UISkin._tile; the first try sampled a region past the 576 px texture and came out flat grey). Opening sequence checked frame by frame (--chestopen 0.35/1.15/2.6 s). 4x TR.
- 2026-10-09 — #103: enhance stage backdrop (first hearth try was a rounded orange pill that read as a button; redrawn as an arch with animated flames). 4x TR.
- 2026-10-09 — regression sweep after #91-#103: all 16 panels + strip at 4x EN (no engine errors, no clipping; EN 'Advance' seal fits), Windows smoke under Wine == OK, control panel/full-party battle checked at 4x. Tavern section banners deliberately kept (same language as the Status 'CLASS ABILITIES' banner).
- 2026-10-10 09:03 shift — backlog empty, replayed the intro (6 beats). #104 done (shard glow, feathered letterbox). 2x TR.
- 2026-10-10 — #105: Toast merges same-title notices (count in the title, life restarted, quieter sound), MAX_STACK 3, slot index recomputed from _live each frame with a lerp. Checked with the lv40 burst (3 achievements -> one '×3' plate).
- 2026-10-10 — first-minute check: stills showed Kael pale/translucent at 8-10 s and looked like early deaths. Probed: quiet sim of the first 60 s (min HP 268/342, 0 deaths), 1 h balance bot (0 deaths in the first 15 min), and two real-time runs with a temporary death print: no deaths. The pale look is the white hit-flash shader caught mid-frame. No change.
- 2026-10-10 — #106: world panel top half had kept the pre-v2 look (iron map frame with rivets, flat crimson act tabs, flat plates). Done; slot_button change also reaches the other 2 callers. 2x + 4x TR.
- 2026-10-10 — #107: --fxtest=all (23 effects) scanned, no engine errors; before/after checked at 4x for the four weakest.
- 2026-10-10 — #108: banners checked at 4x TR (boss approach, boss arrived) and EN (zone name).
- 2026-10-10 — #109: first pass drew the name ribbon on top and its folded tails covered the bar; now drawn before the gauge (text after). 4x TR.
- 2026-10-10 — #108 follow-up: the crimson ribbon was chosen by guessing from the text colour, so a legendary drop (orange) got the boss ribbon; _show_banner now takes an explicit danger flag (boss incoming / arrived, party wiped).
- 2026-10-10 — #110: checked at 4x on the meadow; additive orange reads yellow on green grass (expected for light), the epic beam keeps its violet.
- 2026-10-10 — #111 + checks: 'Okcu' on a tavern card looked like a missing ç, but the cedilla was only clipped by the scroll view's bottom edge (all 6 fonts cover çÇşŞğĞıİöÖüÜâîû, checked with fontTools). Windows smoke after #107-#110: == OK. Additive VFX checked on the dark tower too.
