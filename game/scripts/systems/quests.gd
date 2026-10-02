class_name Quests
extends RefCounted
## Daily quests derived from total counters + achievements checks.

const DAILY_POOL := [
	{"id": "kills", "stat": "kills", "base": 300, "per_lv": 6, "reward": {"gold": 50, "tavern_seal": 1}},
	{"id": "bosses", "stat": "bosses", "base": 2, "per_lv": 0, "reward": {"gold": 80, "soul_shard": 3}},
	{"id": "items", "stat": "items", "base": 40, "per_lv": 0, "reward": {"gold": 40, "iron_scrap": 10}},
	{"id": "combines", "stat": "combines", "base": 1, "per_lv": 0, "reward": {"gold": 60, "shiny_essence": 2}},
	{"id": "enhances", "stat": "enhances", "base": 3, "per_lv": 0, "reward": {"gold": 60, "iron_scrap": 15}},
	{"id": "gold", "stat": "gold", "base": 2000, "per_lv": 200, "reward": {"tavern_seal": 1, "guild_badge": 1}},
]


static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func ensure_daily() -> void:
	var q: Dictionary = GameState.flags.get("daily", {})
	if q.get("date", "") == today():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today())
	var pool := DAILY_POOL.duplicate()
	var picks: Array = []
	for i in 3:
		var idx := rng.randi() % pool.size()
		picks.append(pool[idx])
		pool.remove_at(idx)
	var lv := GameState.max_hero_level()
	var list: Array = []
	for p in picks:
		var target := int(p["base"] + p["per_lv"] * lv)
		list.append({"id": p["id"], "stat": p["stat"], "start": float(GameState.totals.get(p["stat"], 0)), "target": target,
			"reward": _scale_reward(p["reward"], lv), "claimed": false})
	GameState.flags["daily"] = {"date": today(), "list": list}


static func _scale_reward(r: Dictionary, lv: int) -> Dictionary:
	var out := {}
	for k in r:
		out[k] = int(r[k] * (1 + lv * 0.2)) if k == "gold" else int(r[k])
	if out.has("gold"):
		out["gold"] = int(out["gold"]) * max(1, lv)
	return out


static func progress(q: Dictionary) -> float:
	return float(GameState.totals.get(q["stat"], 0)) - float(q["start"])


static func claim(i: int) -> bool:
	var list: Array = GameState.flags.get("daily", {}).get("list", [])
	if i >= list.size():
		return false
	var q: Dictionary = list[i]
	if q["claimed"] or progress(q) < float(q["target"]):
		return false
	q["claimed"] = true
	for k in q["reward"]:
		if k == "gold":
			GameState.add_gold(int(q["reward"][k]))
		else:
			GameState.add_material(k, int(q["reward"][k]))
	return true


# ------------------------------------------------------------------ achievements
static func check_achievements() -> void:
	for a in DataDB.achievements:
		var id: String = a["id"]
		if GameState.achievements.has(id):
			continue
		if _met(a):
			GameState.achievements[id] = TimeService.unix_now()
			EventBus.achievement_unlocked.emit(id)
			EventBus.notify.emit(DataDB.t("achievement", {"name": DataDB.tx(a["name"])}), UITheme.C_GOLD)
			var rw: Dictionary = a.get("reward", {})
			for k in rw:
				if k == "gold":
					GameState.add_gold(int(rw[k]))
				else:
					GameState.add_material(k, int(rw[k]))


static func _met(a: Dictionary) -> bool:
	var c: Dictionary = a.get("cond", {})
	var t: Dictionary = GameState.totals
	match str(c.get("type", "")):
		"total":
			return float(t.get(c["stat"], 0)) >= float(c["n"])
		"heroes":
			return GameState.heroes.size() >= int(c["n"])
		"party":
			return GameState.party_count() >= int(c["n"])
		"level":
			return GameState.max_hero_level() >= int(c["n"])
		"boss":
			for k in GameState.progress.get("cleared", {}):
				if str(k).ends_with(str(c["zone"])) and str(k).begins_with(str(c.get("diff", 0))):
					return true
			return false
		"zone":
			return int(GameState.progress["max_zone"][int(c.get("diff", 0))]) >= int(c["n"])
		"enhance":
			for h in GameState.heroes.values():
				for s in h.equipment:
					if int(h.equipment[s].get("enhance", 0)) >= int(c["n"]):
						return true
			for it in GameState.bag:
				if int(it.get("enhance", 0)) >= int(c["n"]):
					return true
			return false
		"stars":
			for h in GameState.heroes.values():
				if h.stars >= int(c["n"]):
					return true
			return false
		"faction":
			var counts := {}
			for hid in GameState.heroes:
				var f: String = DataDB.hero_def(hid).get("faction", "")
				counts[f] = int(counts.get(f, 0)) + 1
			for f in counts:
				if int(counts[f]) >= int(c["n"]):
					return true
			return false
		"advance":
			for h in GameState.heroes.values():
				if h.advancement >= int(c["n"]):
					return true
			return false
		"guild":
			var tot := 0
			for k in GameState.guild:
				tot += int(GameState.guild[k])
			return tot >= int(c["n"])
	return false
