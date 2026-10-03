class_name Blacksmith
extends RefCounted
## Combine (9 -> 1 with pity), enhance (+1..+15), salvage and craft.


static func level() -> int:
	return int(GameState.blacksmith.get("level", 1))


static func xp_needed(lv: int) -> int:
	return int(100 * pow(lv, 1.5))


static func add_xp(n: int) -> void:
	var b := GameState.blacksmith
	b["xp"] = int(b.get("xp", 0)) + n
	while int(b["xp"]) >= xp_needed(int(b["level"])) and int(b["level"]) < 50:
		b["xp"] = int(b["xp"]) - xp_needed(int(b["level"]))
		b["level"] = int(b["level"]) + 1
		EventBus.notify.emit(DataDB.t("smith_level", {"lv": b["level"]}), UITheme.C_GOLD)


static func next_rarity(r: String) -> String:
	match r:
		"common":
			return "magic"
		"magic":
			return "rare"
		"rare":
			return "epic"
		"epic":
			return "legendary"
		"legendary", "set":
			return "mythic"
	return ""


static func combine_base_chance(r: String) -> float:
	var base: float = float(DataDB.bal("combine", {}).get(r, 0.0))
	return min(1.0, base + level() * 0.004)


## Chance shown and rolled: every failed combine moves the odds a step closer to 100%, which is reached
## on the pity count. What the panel shows is exactly what is rolled.
static func combine_chance(r: String) -> float:
	var base := combine_base_chance(r)
	var maxp := maxi(1, int(DataDB.bal("combine.pity", 10)))
	var pity := int(GameState.blacksmith.get("pity", 0))
	return min(1.0, base + (1.0 - base) * float(pity) / float(maxp))


static func combine_unlock_level(r: String) -> int:
	return int(DataDB.bal("combine.unlock_level", {}).get(r, 1 if r != "legendary" else 45))


## Validate a 9-item selection. Returns "" if ok, else an error key.
static func combine_problem(uids: Array) -> String:
	if uids.size() != 9:
		return "smith_need9"
	var r := ""
	for u in uids:
		var i := GameState.find_bag_index(u)
		if i < 0:
			return "smith_need9"
		var it: Dictionary = GameState.bag[i]
		if it.get("locked", false):
			return "smith_locked"
		var rr: String = it.get("rarity", "common")
		if rr == "set":
			rr = "legendary"
		if r == "":
			r = rr
		elif r != rr:
			return "smith_same_rarity"
	if next_rarity(r) == "":
		return "smith_max"
	if level() < combine_unlock_level(r):
		return "smith_level_low"
	if next_rarity(r) == "mythic" and not GameState.has_material("mythic_essence", 1):
		return "smith_need_mythic"
	return ""


static func combine(uids: Array, cls: String) -> Dictionary:
	var prob := combine_problem(uids)
	if prob != "":
		return {"ok": false, "error": prob}
	var items: Array = []
	var ilvl_sum := 0
	for u in uids:
		var it: Dictionary = GameState.bag[GameState.find_bag_index(u)]
		items.append(it)
		ilvl_sum += int(it.get("ilvl", 1))
	var r: String = items[0]["rarity"]
	if r == "set":
		r = "legendary"
	var nr := next_rarity(r)
	var pity := int(GameState.blacksmith.get("pity", 0))
	var guaranteed := pity >= int(DataDB.bal("combine.pity", 10))
	var success := guaranteed or GameState.rng.randf() < combine_chance(r)
	_log_roll("combine", combine_chance(r), success)
	for u in uids:
		GameState.bag.remove_at(GameState.find_bag_index(u))
	add_xp(10 * (ItemUtil.rarity_rank(r) + 1))
	GameState.totals["combines"] = int(GameState.totals.get("combines", 0)) + 1
	var result := {}
	if success:
		if nr == "mythic":
			GameState.spend_material("mythic_essence", 1)
		# never a step back: at least the best input's level, usually a bit above the average
		var best := 1
		for it in items:
			best = maxi(best, int(it.get("ilvl", 1)))
		var ilvl := maxi(best, int(round(float(ilvl_sum) / 9.0)) + 2)
		result = LootSystem.generate(GameState.rng, ilvl, nr, cls)
		GameState.bag.append(result)
		GameState.blacksmith["pity"] = 0
	else:
		# a failed combine keeps the best two thirds of the items and builds up pity
		items.sort_custom(func(a, b): return int(a.get("ilvl", 1)) > int(b.get("ilvl", 1)))
		for i in 6:
			GameState.bag.append(items[i])
		GameState.blacksmith["pity"] = pity + 1
	EventBus.inventory_changed.emit()
	return {"ok": true, "success": success, "item": result, "guaranteed": guaranteed}


static func enhance_info(item: Dictionary) -> Dictionary:
	var e := int(item.get("enhance", 0))
	var tab: Array = DataDB.bal("enhance", [])
	if e >= tab.size():
		return {}
	var row: Dictionary = tab[e]
	var acc := GameState.account_mods()
	var disc := 1.0 - float(acc.get("smith_discount", 0.0)) / 100.0
	var cost := int(float(row["cost"]) * max(1, int(item.get("ilvl", 1))) * disc)
	var base: float = min(1.0, float(row["chance"]) + level() * 0.003)
	# pity: every failure on this item adds a share of the missing chance; guaranteed on the pity count
	var fails := int(item.get("enh_fail", 0))
	var maxp := maxi(1, int(DataDB.bal("enhance_pity", 6)))
	var chance: float = 1.0 if fails >= maxp else min(1.0, base + (1.0 - base) * float(fails) / float(maxp))
	return {"next": e + 1, "chance": chance, "base": base, "fails": fails, "pity": maxp, "cost": cost,
		"mat": row.get("mat", "iron_scrap" if e >= 5 else ""), "mat_n": 1 + e / 5, "fail_down": bool(row.get("fail_down", false))}


## Enhance an item dictionary in place (bag or equipped). Returns "success" | "fail" | error key.
static func enhance(item: Dictionary) -> String:
	var info := enhance_info(item)
	if info.is_empty():
		return "smith_max"
	if GameState.gold < int(info["cost"]):
		return "not_enough_gold"
	var m: String = info["mat"]
	if m != "" and not GameState.has_material(m, int(info["mat_n"])):
		return "not_enough_mats"
	GameState.spend_gold(int(info["cost"]))
	if m != "":
		GameState.spend_material(m, int(info["mat_n"]))
	add_xp(5 + int(item.get("enhance", 0)) * 2)
	GameState.totals["enhances"] = int(GameState.totals.get("enhances", 0)) + 1
	var ok := GameState.rng.randf() < float(info["chance"])
	_log_roll("enhance", float(info["chance"]), ok)
	if ok:
		item["enhance"] = int(info["next"])
		item.erase("enh_fail")
		GameState.invalidate_stats()
		EventBus.inventory_changed.emit()
		return "success"
	item["enh_fail"] = int(item.get("enh_fail", 0)) + 1
	if info["fail_down"] and int(item.get("enhance", 0)) > 0:
		item["enhance"] = int(item["enhance"]) - 1
	GameState.invalidate_stats()
	EventBus.inventory_changed.emit()
	return "fail"


## Last rolls, newest first ({k, c: chance, ok}): shown in the panel so odds can be checked.
static func _log_roll(kind: String, chance: float, ok: bool) -> void:
	var log: Array = GameState.blacksmith.get("log", [])
	log.push_front({"k": kind, "c": snappedf(chance, 0.001), "ok": ok})
	if log.size() > 20:
		log.resize(20)
	GameState.blacksmith["log"] = log


static func salvage_rarities(rarities: Array) -> int:
	var n := 0
	for it in GameState.bag.duplicate():
		if it.get("locked", false):
			continue
		if rarities.has(it.get("rarity", "common")):
			GameState.salvage_item(it["uid"])
			n += 1
	add_xp(n)
	return n


static func craft_cost(tier: int) -> Dictionary:
	return {"gold": int(200 * pow(2.2, tier)), "iron_scrap": 5 + tier * 5, "shiny_essence": max(0, tier - 1) * 2}


static func craft(cls: String, slot_cat: String, tier: int) -> Dictionary:
	var c := craft_cost(tier)
	if GameState.gold < int(c["gold"]) or not GameState.has_material("iron_scrap", int(c["iron_scrap"])) \
			or not GameState.has_material("shiny_essence", int(c["shiny_essence"])):
		return {}
	GameState.spend_gold(int(c["gold"]))
	GameState.spend_material("iron_scrap", int(c["iron_scrap"]))
	if int(c["shiny_essence"]) > 0:
		GameState.spend_material("shiny_essence", int(c["shiny_essence"]))
	var tl: Array = DataDB.bal("items.tier_levels", [1])
	var ilvl := int(tl[tier]) + GameState.rng.randi_range(0, 8)
	var r := "rare" if GameState.rng.randf() < 0.85 else "epic"
	var base := {}
	if slot_cat != "any":
		var tmp := LootSystem.pick_base(GameState.rng, cls, r)
		var tries := 0
		while ItemUtil.slot_group(tmp.get("slot", "")) != slot_cat and tries < 50:
			tmp = LootSystem.pick_base(GameState.rng, cls, r)
			tries += 1
		base = tmp
	var it := LootSystem.generate(GameState.rng, ilvl, r, cls, base)
	GameState.bag.append(it)
	add_xp(20 + tier * 10)
	EventBus.inventory_changed.emit()
	return it
