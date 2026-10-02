class_name HeroState
extends RefCounted
## Persistent per-hero progression data.

const PRIMARY := ["str", "dex", "int", "vit", "luk"]

var id: String = ""
var level: int = 1
var xp: float = 0.0
var paragon: int = 0
var alloc: Dictionary = {"str": 0, "dex": 0, "int": 0, "vit": 0, "luk": 0}
var stat_points: int = 0
var skill_points: int = 0
var skill_levels: Dictionary = {}
var equipped_skills: Array = ["", "", ""]
var equipment: Dictionary = {}
var stars: int = 1
var shards: int = 0
var advancement: int = 0
var spec: String = ""
var resets: int = 0
var costume: String = ""


static func create(hero_id: String) -> HeroState:
	var h := HeroState.new()
	h.id = hero_id
	var d: Dictionary = DataDB.hero_def(hero_id)
	h.stars = {"R": 1, "SR": 2, "SSR": 3}.get(d.get("rarity", "R"), 1)
	# learn first active skill
	var first := ""
	for sid in DataDB.skills_by_class.get(h.cls(), []):
		var s: Dictionary = DataDB.skill_def(sid)
		if s.get("type") == "active" and int(s.get("tier", 0)) == 0:
			first = sid
			break
	if first != "":
		h.skill_levels[first] = 1
		h.equipped_skills[0] = first
	return h


func def() -> Dictionary:
	return DataDB.hero_def(id)


func cls() -> String:
	return str(def().get("class", "knight"))


func class_def() -> Dictionary:
	return DataDB.class_def(cls())


func display_name() -> String:
	return str(def().get("name", id))


func class_title() -> String:
	var adv: Array = class_def().get("adv", [])
	if advancement == 0 or adv.is_empty():
		return DataDB.tx(class_def().get("name", {}))
	if advancement == 1:
		return DataDB.tx(adv[1])
	var t2: Dictionary = adv[2]
	return DataDB.tx(t2.get(spec if spec != "" else "a", {}))


func skill_level(sid: String) -> int:
	return int(skill_levels.get(sid, 0))


func skill_available(sid: String) -> bool:
	var s: Dictionary = DataDB.skill_def(sid)
	if s.is_empty() or s.get("class") != cls():
		return false
	var tier := int(s.get("tier", 0))
	if tier > advancement:
		return false
	if tier == 2 and s.has("spec") and spec != "" and s["spec"] != spec:
		return false
	if tier == 2 and spec == "":
		return false
	return true


func class_skills() -> Array:
	return DataDB.skills_by_class.get(cls(), [])


func ult_id() -> String:
	for sid in class_skills():
		if DataDB.skill_def(sid).get("type") == "ult":
			return sid
	return ""


func can_level_skill(sid: String) -> bool:
	if skill_points <= 0 or not skill_available(sid):
		return false
	var s: Dictionary = DataDB.skill_def(sid)
	if s.get("type") == "ult" and level < 20:
		return false
	return skill_level(sid) < int(s.get("max", 1))


func level_skill(sid: String) -> bool:
	if not can_level_skill(sid):
		return false
	skill_levels[sid] = skill_level(sid) + 1
	skill_points -= 1
	var s: Dictionary = DataDB.skill_def(sid)
	if s.get("type") == "active" and skill_levels[sid] == 1 and not equipped_skills.has(sid):
		for i in equipped_skills.size():
			if equipped_skills[i] == "":
				equipped_skills[i] = sid
				break
	return true


## Spends skill points automatically: actives first (up to 3), ult at 20+, then passives.
func auto_skills() -> void:
	var guard := 0
	while skill_points > 0 and guard < 200:
		guard += 1
		var best := ""
		var best_score := -1.0
		for sid in class_skills():
			if not can_level_skill(sid):
				continue
			var sd: Dictionary = DataDB.skill_def(sid)
			var lv := skill_level(sid)
			var score := 10.0 - lv
			match sd.get("type", ""):
				"active":
					var active_count := 0
					for e in equipped_skills:
						if e != "":
							active_count += 1
					score += 6.0 if (equipped_skills.has(sid) or active_count < 3) else -20.0
				"ult":
					score += 8.0
				"passive":
					score += 3.0
			score += int(sd.get("tier", 0)) * 2.0
			if score > best_score:
				best_score = score
				best = sid
		if best == "" or best_score < 0:
			break
		level_skill(best)


func reset_skills() -> void:
	var total := 0
	for sid in skill_levels:
		total += int(skill_levels[sid])
	skill_levels.clear()
	skill_points += total
	equipped_skills = ["", "", ""]


func total_primary(stat: String) -> int:
	return int(DataDB.bal("start_stats", 5)) + int(alloc.get(stat, 0))


func reset_stats() -> void:
	var total := 0
	for k in alloc:
		total += int(alloc[k])
		alloc[k] = 0
	stat_points += total
	resets += 1


func auto_allocate() -> void:
	var tpl: Dictionary = class_def().get("auto_stats", {"str": 1.0})
	var keys: Array = tpl.keys()
	while stat_points > 0:
		# pick the stat furthest below its target share
		var total := 0
		for k in PRIMARY:
			total += int(alloc[k])
		var best: String = keys[0]
		var best_gap := -INF
		for k in keys:
			var want: float = float(tpl[k]) * float(total + 1)
			var gap: float = want - float(alloc.get(k, 0))
			if gap > best_gap:
				best_gap = gap
				best = k
		alloc[best] = int(alloc[best]) + 1
		stat_points -= 1


func to_dict() -> Dictionary:
	return {"id": id, "level": level, "xp": xp, "paragon": paragon, "alloc": alloc.duplicate(),
		"stat_points": stat_points, "skill_points": skill_points, "skill_levels": skill_levels.duplicate(),
		"equipped_skills": equipped_skills.duplicate(), "equipment": equipment.duplicate(true),
		"stars": stars, "shards": shards, "advancement": advancement, "spec": spec, "resets": resets,
		"costume": costume}


static func from_dict(d: Dictionary) -> HeroState:
	var h := HeroState.new()
	h.id = str(d.get("id", ""))
	h.level = int(d.get("level", 1))
	h.xp = float(d.get("xp", 0.0))
	h.paragon = int(d.get("paragon", 0))
	var a: Dictionary = d.get("alloc", {})
	for k in PRIMARY:
		h.alloc[k] = int(a.get(k, 0))
	h.stat_points = int(d.get("stat_points", 0))
	h.skill_points = int(d.get("skill_points", 0))
	h.skill_levels = {}
	var sl: Dictionary = d.get("skill_levels", {})
	for k in sl:
		h.skill_levels[k] = int(sl[k])
	h.equipped_skills = Array(d.get("equipped_skills", ["", "", ""]))
	while h.equipped_skills.size() < 3:
		h.equipped_skills.append("")
	h.equipment = d.get("equipment", {})
	h.stars = int(d.get("stars", 1))
	h.shards = int(d.get("shards", 0))
	h.advancement = int(d.get("advancement", 0))
	h.spec = str(d.get("spec", ""))
	h.resets = int(d.get("resets", 0))
	h.costume = str(d.get("costume", ""))
	return h
