class_name Goals
extends RefCounted
## The one thing worth doing next, shown on the battle strip so a player is never left wondering: get the
## first companion, hire the next one, beat the zone boss, reach a level; later: a full party, the next
## difficulty, the tower's next reward floor, a hero's class advancement.

const EARLY_UNTIL_LEVEL := 25


static func current() -> String:
	if BattleSim.mode != "zone":
		return ""
	if GameState.max_hero_level() >= EARLY_UNTIL_LEVEL:
		return _later()
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


## Mid and late game: one milestone at a time, the nearest one first.
static func _later() -> String:
	var z := BattleSim.zone()
	var key := "%d_%s" % [BattleSim.difficulty, str(z.get("id", ""))]
	if not GameState.progress["cleared"].has(key):
		return DataDB.t("goal_boss", {"zone": DataDB.tx(z.get("name", {}))})
	if GameState.party_count() < GameState.unlocked_party_slots():
		return DataDB.t("goal_fill_party")
	# a hero ready for class advancement
	for h in GameState.party_heroes():
		if (h.advancement == 0 and h.level >= 30) or (h.advancement == 1 and h.level >= 70):
			return DataDB.t("goal_advance", {"name": h.display_name()})
	var maxz: Array = GameState.progress.get("max_zone", [0, -1, -1])
	for d in [1, 2]:
		if int(maxz[d]) < 0:
			return DataDB.t("goal_difficulty", {"diff": DataDB.tx(DataDB.difficulties[d]["name"])})
	if BattleSim.tower_unlocked():
		var best := int(GameState.progress.get("tower_best", 0))
		return DataDB.t("goal_tower", {"n": (best / 10 + 1) * 10})
	var lv := GameState.max_hero_level()
	return DataDB.t("goal_level", {"n": (lv / 5 + 1) * 5})

