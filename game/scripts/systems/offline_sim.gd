class_name OfflineSim
extends RefCounted
## Statistical simulation of progress made while the game was closed.


static func apply() -> Dictionary:
	var report := {"seconds": 0, "xp": 0.0, "gold": 0, "kills": 0, "items": [], "levels": {}, "sold": 0}
	var last: int = GameState.last_save_unix
	var now := TimeService.unix_now()
	if last <= 0 or now <= last:
		return report
	var acc: Dictionary = GameState.account_mods()
	var boost := Shop.offline_bonus()
	var max_h: float = float(DataDB.bal("offline.max_hours", 12)) + float(acc.get("offline_hours", 0.0)) + float(boost["hours"])
	var secs: float = min(float(now - last), max_h * 3600.0)
	if secs < 60:
		return report
	var eff: float = min(0.45 + float(boost["eff"]), float(DataDB.bal("offline.efficiency", 0.2)) + float(acc.get("offline_eff", 0.0)) / 100.0 + float(boost["eff"]))
	for h in GameState.party_heroes():
		for slot in h.equipment:
			var it: Dictionary = h.equipment[slot]
			if it.get("leg", "") == "leg_hourglass":
				eff = min(0.9, eff + 0.15)
	var minutes := secs / 60.0
	var rates: Dictionary = GameState.rates
	# fall back to a conservative estimate if no rates were recorded yet
	var z: Dictionary = DataDB.zone(int(GameState.progress.get("zone", 0)))
	var lv := F.monster_level(z, max(1, int(GameState.progress.get("stage", 1))), int(GameState.progress.get("difficulty", 0)))
	var kpm: float = float(rates.get("kills", 0.0))
	if kpm <= 0.1:
		kpm = 12.0
	var xpm: float = float(rates.get("xp", 0.0))
	if xpm <= 0.1:
		xpm = kpm * F.xp_per_kill(lv)
	var gpm: float = float(rates.get("gold", 0.0))
	if gpm <= 0.1:
		gpm = kpm * F.gold_per_kill(lv)
	var kills := int(kpm * minutes * eff)
	var xp := xpm * minutes * eff
	var gold := int(gpm * minutes * eff)
	var before: Dictionary = {}
	for hid in GameState.heroes:
		before[hid] = GameState.heroes[hid].level
	for hid in GameState.heroes.keys():
		var h: HeroState = GameState.heroes[hid]
		var share := 1.0 if GameState.party.has(hid) else float(DataDB.bal("xp.reserve_share", 0.25))
		GameState.add_hero_xp(h, xp * share)
	for hid in GameState.heroes:
		var gained: int = GameState.heroes[hid].level - int(before.get(hid, GameState.heroes[hid].level))
		if gained > 0:
			report["levels"][hid] = gained
	GameState.add_gold(gold)
	# loot
	var iff := 0.0
	var ph := GameState.party_heroes()
	for h in ph:
		iff += float(GameState.hero_stats(h.id).get("item_find", 0.0))
	iff /= max(1, ph.size())
	var drop_p: float = float(DataDB.bal("loot.drop_chance", {}).get("normal", 0.08)) * (1.0 + iff / 400.0)
	var expected := int(kills * drop_p * float(DataDB.bal("offline.item_factor", 0.35)))
	var max_items := int(DataDB.bal("offline.max_items", 200))
	var gen: int = min(expected, max_items)
	var found: Array = []
	var sold_gold := 0
	for i in gen:
		var r := LootSystem.roll_rarity(GameState.rng, iff, int(GameState.progress.get("difficulty", 0)))
		var cls := ""
		var classes := GameState.party_classes()
		if classes.size() > 0 and GameState.rng.randf() < 0.6:
			cls = classes[GameState.rng.randi() % classes.size()]
		var it := LootSystem.generate(GameState.rng, lv, r, cls)
		var res := GameState.receive_item(it)
		if res == "sold":
			sold_gold += ItemUtil.sell_price(it)
		found.append(it)
	# remaining expected drops are converted into gold
	if expected > gen:
		var extra := int((expected - gen) * (5.0 + lv * 1.5))
		GameState.add_gold(extra)
		sold_gold += extra
	found.sort_custom(func(a, b): return ItemUtil.rarity_rank(a["rarity"]) > ItemUtil.rarity_rank(b["rarity"]))
	report["seconds"] = int(secs)
	report["xp"] = xp
	report["gold"] = gold + sold_gold
	report["kills"] = kills
	report["items"] = found.slice(0, 5)
	report["item_count"] = found.size()
	report["sold"] = sold_gold
	report["eff"] = eff
	GameState.totals["kills"] = int(GameState.totals.get("kills", 0)) + kills
	GameState.totals["offline"] = float(GameState.totals.get("offline", 0.0)) + secs
	GameState.invalidate_stats()
	return report
