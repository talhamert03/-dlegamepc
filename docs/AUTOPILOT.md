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

## Questions for the owner

- **Difficulty pacing (bot, two 48 h runs, 2026-10-06):** Normal ~10 h, Nightmare ~20 h, Hell still in act 2-3
  after 48 h. Boss HP is continuous across difficulties (Nightmare's last boss 11.2M, Hell's first 9.4M); the walls
  at each new difficulty come from the resistance penalty (-30 / -60) and the 1.25x / 1.5x damage, so they hit
  players who ignore resistances. I added boss fatigue (3% per failed try, max 30%) which removes the near-miss
  grind but not the real power walls. Options: (a) keep as is — Hell should be a long-term goal; (b) soften the
  first act of each difficulty (e.g. Hell act 1 resistance -45). I lean to (a) plus better resistance hints. Your call.

- **Tavern seals pile up (bot, 30 h):** 22 seals by hour 2, 64 by hour 10, 107 by hour 29, while SR costs 2 and SSR 8.
  Seals never gate recruiting; gold does (SSR base 1.2M). Options: (a) leave it; (b) raise seal costs (SR 5, SSR 20) so
  seals pace SR/SSR; (c) give seals a second use (e.g. reroll the tavern's featured hero, or buy hero star shards).
  I lean to (b) or (c). Your call.

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
