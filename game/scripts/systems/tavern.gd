class_name Tavern
extends RefCounted
## Hero recruitment: every hero of the roster is on show and is bought with gold (and tavern seals for the
## rarer ones). Prices climb with rarity and with every hero already recruited, rarer heroes also need a
## party level. Nobody joins for free: the party grows only through the tavern.

const BASE := {"R": {"gold": 450, "tavern_seal": 0, "lv": 1}, "SR": {"gold": 25000, "tavern_seal": 2, "lv": 15},
	"SSR": {"gold": 250000, "tavern_seal": 8, "lv": 30}}


static func roster() -> Array:
	var out: Array = []
	for hid in DataDB.hero_order:
		if hid != "kael":
			out.append(hid)
	return out


static func rarity(hid: String) -> String:
	return str(DataDB.hero_def(hid).get("rarity", "R"))


static func level_req(hid: String) -> int:
	return int(BASE.get(rarity(hid), BASE["R"])["lv"])


static func cost(hid: String) -> Dictionary:
	var b: Dictionary = BASE.get(rarity(hid), BASE["R"])
	var owned := maxi(0, GameState.heroes.size() - 1)
	var mult := 1.0 + (0.8 if rarity(hid) == "R" else 0.25) * owned
	return {"gold": int(round(float(b["gold"]) * mult / 50.0) * 50.0), "tavern_seal": int(b["tavern_seal"])}


static func level_ok(hid: String) -> bool:
	return GameState.max_hero_level() >= level_req(hid)


static func can_afford(hid: String) -> bool:
	var c := cost(hid)
	return level_ok(hid) and GameState.gold >= int(c["gold"]) and GameState.has_material("tavern_seal", int(c["tavern_seal"]))


static func recruit(hid: String) -> bool:
	if GameState.heroes.has(hid) or not can_afford(hid):
		return false
	var c := cost(hid)
	GameState.spend_gold(int(c["gold"]))
	if int(c["tavern_seal"]) > 0:
		GameState.spend_material("tavern_seal", int(c["tavern_seal"]))
	GameState.unlock_hero(hid)
	GameState.add_to_party(hid)
	return true


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
