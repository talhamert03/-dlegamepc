class_name Goals
extends RefCounted
## The one thing worth doing next, shown on the battle strip during the first hours so a new player is
## never left wondering: get the first companion, hire the next one, beat the zone boss, reach a level.

const SHOW_UNTIL_LEVEL := 25


static func current() -> String:
	if GameState.max_hero_level() >= SHOW_UNTIL_LEVEL or BattleSim.mode != "zone":
		return ""
	if not GameState.heroes.has("lyra") and not GameState.flags.get("lyra_gift", false):
		return DataDB.t("goal_lyra")
	# the next starter companion the party can afford to save for
	if GameState.party_count() < 5:
		var best := ""
		for hid in Tavern.STARTERS:
			if not GameState.heroes.has(hid) and (best == "" or int(Tavern.STARTERS[hid]) < int(Tavern.STARTERS[best])):
				best = hid
		if best != "" and GameState.party_count() < 3:
			return DataDB.t("goal_hire", {"name": str(DataDB.hero_def(best).get("name", best)), "g": F.fmt_num(GameState.gold),
				"c": F.fmt_num(int(Tavern.STARTERS[best]))})
	var z := BattleSim.zone()
	var key := "%d_%s" % [BattleSim.difficulty, str(z.get("id", ""))]
	if not GameState.progress["cleared"].has(key):
		return DataDB.t("goal_boss", {"zone": DataDB.tx(z.get("name", {}))})
	var lv := GameState.max_hero_level()
	return DataDB.t("goal_level", {"n": (lv / 5 + 1) * 5})
