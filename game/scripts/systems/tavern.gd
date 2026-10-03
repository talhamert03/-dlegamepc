class_name Tavern
extends RefCounted
## Hero recruitment: every hero of the roster is on show and is bought with gold (and tavern seals for the
## rarer ones). A few cheap companions get a new party going; everyone else is a real goal: plain heroes
## start at 70k, SR and SSR need a party level and seals, and every hero recruited past a full party makes
## the next one dearer. Nobody joins for free except the two story heroes.

## the first companions, at a fixed price (the cheapest buys in the tavern)
const STARTERS := {"lyra": 1000, "pip": 5000, "leon": 10000, "nova": 20000}
const BASE := {"R": {"gold": 70000, "tavern_seal": 0, "lv": 1}, "SR": {"gold": 220000, "tavern_seal": 2, "lv": 15},
	"SSR": {"gold": 1200000, "tavern_seal": 8, "lv": 30}}
## every hero owned beyond a full party (5) raises the price of the others by this much
const GROWTH := 0.12
const FULL_PARTY := 5


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
	if STARTERS.has(hid):
		return {"gold": int(STARTERS[hid]), "tavern_seal": 0}
	var b: Dictionary = BASE.get(rarity(hid), BASE["R"])
	var extra := maxi(0, GameState.heroes.size() - FULL_PARTY)
	var mult := 1.0 + GROWTH * extra
	var step := 5000.0 if rarity(hid) == "R" else 10000.0
	return {"gold": int(round(float(b["gold"]) * mult / step) * step), "tavern_seal": int(b["tavern_seal"])}


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
