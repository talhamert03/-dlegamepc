class_name Tavern
extends RefCounted
## Hero recruitment (no gacha: 3 visible offers that refresh every 4 hours) and star upgrades.

const REFRESH_SECS := 4 * 3600
const COST := {"R": {"gold": 500, "tavern_seal": 1}, "SR": {"gold": 6000, "tavern_seal": 3}, "SSR": {"gold": 60000, "tavern_seal": 8}}


static func candidates() -> Array:
	var out: Array = []
	for hid in DataDB.hero_order:
		var d: Dictionary = DataDB.hero_def(hid)
		if d.get("unlock", "") == "tavern" and not GameState.heroes.has(hid):
			out.append(hid)
	return out


static func ensure_offers(force := false) -> void:
	var now := TimeService.unix_now()
	var t := GameState.tavern
	var offers: Array = t.get("offers", [])
	offers = offers.filter(func(h): return not GameState.heroes.has(h))
	if not force and offers.size() >= 3 and now < int(t.get("refresh_at", 0)):
		t["offers"] = offers
		return
	var pool := candidates()
	var lv := GameState.max_hero_level()
	var out: Array = []
	var rng := GameState.rng
	var tries := 0
	while out.size() < 3 and pool.size() > 0 and tries < 100:
		tries += 1
		var roll := rng.randf()
		var want := "R"
		if lv >= 15 and roll < 0.32:
			want = "SR"
		if lv >= 30 and roll < 0.1:
			want = "SSR"
		var opts: Array = pool.filter(func(h): return DataDB.hero_def(h).get("rarity", "R") == want and not out.has(h))
		if opts.is_empty():
			opts = pool.filter(func(h): return not out.has(h))
		if opts.is_empty():
			break
		out.append(opts[rng.randi() % opts.size()])
	t["offers"] = out
	t["refresh_at"] = now + REFRESH_SECS


static func cost(hid: String) -> Dictionary:
	var r: String = DataDB.hero_def(hid).get("rarity", "R")
	if not GameState.flags.get("free_recruit_used", false) and r == "R":
		return {"gold": 0, "tavern_seal": 0}
	return COST.get(r, COST["R"])


static func can_afford(hid: String) -> bool:
	var c := cost(hid)
	return GameState.gold >= int(c["gold"]) and GameState.has_material("tavern_seal", int(c["tavern_seal"]))


static func recruit(hid: String) -> bool:
	if not can_afford(hid):
		return false
	var c := cost(hid)
	GameState.spend_gold(int(c["gold"]))
	if int(c["tavern_seal"]) > 0:
		GameState.spend_material("tavern_seal", int(c["tavern_seal"]))
	if int(c["gold"]) == 0:
		GameState.flags["free_recruit_used"] = true
	GameState.unlock_hero(hid)
	GameState.add_to_party(hid)
	GameState.tavern["offers"].erase(hid)
	return true


static func refresh_cost() -> int:
	return 200 + GameState.max_hero_level() * 50


static func star_cost(h: HeroState) -> Dictionary:
	return {"soul_shard": 10 * h.stars, "gold": 1000 * h.stars * h.stars}


static func star_up(h: HeroState) -> bool:
	if h.stars >= 6:
		return false
	var c := star_cost(h)
	if GameState.gold < int(c["gold"]) or not GameState.has_material("soul_shard", int(c["soul_shard"])):
		return false
	GameState.spend_gold(int(c["gold"]))
	GameState.spend_material("soul_shard", int(c["soul_shard"]))
	h.stars += 1
	GameState.invalidate_stats()
	return true
