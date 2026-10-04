# Launch roadmap (game side)

Store page, trailer and community work come later; this list is what the game itself needs.

## Faz 0 — before release

- [ ] **Windows test** on a real machine (overlay, click-through, Steam overlay, scaling 1.5x / 2x / 2.5x)
- [ ] **Steam Cloud save**: save file in the Steam user folder, conflict prompt (local vs cloud, newer wins by default), backup kept
- [ ] **First 30 minutes polish**
  - [ ] first companion (Lyra) as a tutorial reward around minute 10; other tavern prices unchanged
  - [ ] the first boss feels like an event (banner, music, slow-mo on the kill, chest rain)
  - [ ] a clear goal on screen at all times (next unlock: hero / zone / feature)
  - [ ] each early feature (blacksmith, runes, tavern, chests) unlocked with a short highlight instead of all at once
- [ ] Steam achievements (codex achievements -> Steamworks)
- [ ] Real Steam payments (backend /init, /finalize)
- [ ] Crash reporting + opt-in anonymous analytics (D1/D7, first purchase, quit zone)
- [ ] Text size option in settings

## Visual pass — every window as fantasy as the hero/bag window

Reference look: hero/bag window, tavern, store, world map (carved wood, gold trim, velvet/leather, custom-drawn controls).

| Window / area | Today | Planned |
|---|---|---|
| Battle strip HUD | zone name in a flat blue box, plain green HP bars, generic round buttons | carved zone plaque with stage pips, framed HP/mana bars with damage trail, boss HP bar with name ribbon, medallion buttons |
| Settings | rows of small flat buttons (web form) | book-like layout with section headers, toggle switches and sliders drawn as brass levers |
| Statistics (DPS) | huge plain text, mostly empty | ledger page: per-hero DPS bars with portraits, gold/XP per hour, session totals |
| Quests | grey bars and grey buttons | notice-board parchments pinned on wood, wax-seal claim button, reward icons |
| Codex | plain list | tome pages: achievement medallions (locked/unlocked), bestiary cards with art |
| Pets | flat silhouettes | stable stalls with name plates, glow on owned pets |
| Stash | plain grid | iron-bound chest interior, tab plates |
| Blacksmith | plain grid | anvil scene, sparks on success, cracked effect on failure |
| Growth | dense text rows | faction banners with crests, active bonus highlighted |
| Away (offline) report | list | scroll unrolling with the haul counting up |

## Effects / animation

- [ ] Level up: light column + "Seviye Atladı" ribbon over the hero
- [ ] Legendary / mythic drop: loot beam in rarity colour + short slow-mo
- [ ] Boss entrance: screen darkens, name ribbon, roar; boss kill: slow-mo + gold burst
- [ ] Hero recruit: card flip reveal in the tavern (rarity glow, SSR gets a special one)
- [ ] Chest opening: lid burst, items fly into the bag
- [ ] Window open/close: short scale + fade, panel tabs slide
- [ ] Hover feedback on every clickable thing (glow / lift)
- [ ] Ambient: weather per zone (snow, sand, ash), day/night tint already exists
