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
- [ ] 5. Blacksmith: Combine, Salvage and Craft tabs rebuilt to the Enhance tab's standard
- [ ] 6. Steam achievements wired (ids, unlock calls, offline queue, docs for Steamworks setup)
- [ ] 7. Text / translation sweep: every string TR+EN, terms, clipping at 1.5x/2x, tooltips
- [ ] 8. Economy check with the balance bot: gold/XP curves, tavern prices, blacksmith costs, shop value
- [ ] 9. Full playthrough Normal -> Nightmare -> Hell (bot + manual screenshots): walls, boredom spots, fixes
- [ ] 10. First-hour experience pass: pacing, tutorial hints, unlock highlights, goal ribbon wording
- [ ] 11. Combat feel: per-class hit effects, crit feedback, skill VFX audit, boss telegraphs
- [ ] 12. Remaining windows audit: away report, growth, runes, party, portrait — premium consistency
- [ ] 13. Audio pass: missing SFX, volume balance, UI sounds on every control
- [ ] 14. Performance: idle CPU/GPU, draw calls, long-session memory, 144 fps focus mode
- [ ] 15. Endgame: tower floors, paragon, Hell rewards — reasons to keep playing
- [ ] 16. Accessibility: text-size option, colour-blind safe rarity marks, key rebinding view
- [ ] 17. Polish round: every panel at 1.5x/2x/2.5x, no clipping, no overlaps, consistent spacing

## Questions for the owner

(none yet)

## Shift log

- 2026-10-06 — plan written, schedule set (4 shifts a day, Europe/Istanbul 08:52 / 12:52 / 16:52 / 20:52).
- 2026-10-06 shift 1 — #1 hero card-flip reveal (tavern + store), rarity-specific build-up, frames checked.
- 2026-10-06 shift 1 — #2 chest opening: seam light, rays, sparks/coins, rewards leap out, best-item beam, click to skip. (Fly-to-bag dropped: chests live in their own tab.)
- 2026-10-06 shift 1 — #3 pets stable: stalls with plates, collection bar, detail card with level pips; window 236x262.
- 2026-10-06 shift 1 — #4 stash: chest-interior bed, tab plates (coin/gem/lock), capacity bar, Sort, centred unlock price; window 206x262.
