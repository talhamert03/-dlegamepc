class_name StatCalc
extends RefCounted
## Computes final combat stats for heroes from class, level, primaries, gear, passives,
## signatures, set bonuses, party auras and account-wide bonuses.

const ELEMENTS := ["fire", "cold", "lightning", "chaos"]


static func param(sdef: Dictionary, v: Variant, lvl: int) -> float:
	if v is String:
		var p: Array = sdef.get("params", {}).get(v, [0, 0])
		return float(p[0]) + float(p[1]) * float(max(0, lvl - 1))
	return float(v)


static func _add(d: Dictionary, k: String, v: float) -> void:
	d[k] = float(d.get(k, 0.0)) + v


## Raw additive modifiers owned by the hero (gear, passives, signature...). Includes party_* keys.
static func hero_mods(h: HeroState) -> Dictionary:
	var mods: Dictionary = {}
	for slot in h.equipment:
		var it: Dictionary = h.equipment[slot]
		if it.is_empty():
			continue
		var st := ItemUtil.item_stats(it)
		for k in st:
			_add(mods, k, float(st[k]))
	# set bonuses
	var set_counts: Dictionary = {}
	for slot in h.equipment:
		var sid: String = h.equipment[slot].get("set", "")
		if sid != "":
			set_counts[sid] = int(set_counts.get(sid, 0)) + 1
	for sid in set_counts:
		var sd: Dictionary = DataDB.items.get("sets", {}).get(sid, {})
		for need in sd.get("bonus", {}):
			if int(set_counts[sid]) >= int(need):
				var bon: Dictionary = sd["bonus"][need]
				for k in bon:
					_add(mods, k, float(bon[k]))
	# passives
	for sid in h.skill_levels:
		var lvl := int(h.skill_levels[sid])
		if lvl <= 0 or not h.skill_available(sid):
			continue
		var sdef: Dictionary = DataDB.skill_def(sid)
		if sdef.get("type") != "passive":
			continue
		var stats: Dictionary = sdef.get("stats", {})
		for k in stats:
			_add(mods, k, param(sdef, stats[k], lvl))
	# signature
	var sig: Dictionary = h.def().get("signature", {})
	if sig.has("stat"):
		var mult := 1.0 + 0.2 * float(h.stars - 1)
		_add(mods, str(sig["stat"]), float(sig.get("value", 0)) * mult)
	# advancement
	if h.advancement >= 1:
		_add(mods, "added_dmg", 10.0)
		_add(mods, "hp_pct", 10.0)
	if h.advancement >= 2:
		_add(mods, "added_dmg", 15.0)
		_add(mods, "hp_pct", 15.0)
	return mods


## Sum of party_* modifiers across the party (prefix stripped).
static func party_mods(heroes: Array) -> Dictionary:
	var out: Dictionary = {}
	for h in heroes:
		if h == null:
			continue
		var m := hero_mods(h)
		for k in m:
			if str(k).begins_with("party_"):
				_add(out, str(k).substr(6), float(m[k]))
	return out


static func compute(h: HeroState, pmods: Dictionary = {}, account: Dictionary = {}, difficulty: int = 0) -> Dictionary:
	var mods := hero_mods(h)
	for k in pmods:
		_add(mods, k, float(pmods[k]))
	for k in account:
		_add(mods, k, float(account[k]))
	var cd: Dictionary = h.class_def()
	var base: Dictionary = cd.get("base", {})
	var L := h.level
	var main: String = cd.get("primary", "str")
	var prim: Dictionary = {}
	for p in HeroState.PRIMARY:
		prim[p] = float(h.total_primary(p)) + float(mods.get(p, 0.0)) + float(mods.get("all_stats", 0.0))
	var ptab: Dictionary = DataDB.bal("primary", {})
	for p in prim:
		var row: Dictionary = ptab.get(p, {})
		for k in row.get("always", {}):
			_add(mods, k, float(row["always"][k]) * prim[p])
		if p == main or (main == "int" and p == "int"):
			for k in row.get("main", {}):
				_add(mods, k, float(row["main"][k]) * prim[p])
	var star := 1.0 + 0.08 * float(h.stars - 1)
	var s: Dictionary = mods.duplicate()
	s["level"] = L
	s["primary"] = prim
	var weapon_atk: float = float(mods.get("weapon_atk", 0.0))
	s["attack"] = (float(base.get("atk", 10)) + float(base.get("atk_lv", 2)) * L + weapon_atk + float(mods.get("attack_flat", 0.0))) \
		* (1.0 + float(mods.get("attack_pct", 0.0)) / 100.0) * star
	s["spell"] = (float(base.get("spell", 5)) + float(base.get("spell_lv", 1)) * L + weapon_atk + float(mods.get("spell_flat", 0.0))) \
		* (1.0 + float(mods.get("spell_pct", 0.0)) / 100.0) * star
	s["uses_spell"] = bool(cd.get("uses_spell", false))
	s["power"] = s["spell"] if s["uses_spell"] else s["attack"]
	s["max_hp"] = (float(base.get("hp", 100)) + float(base.get("hp_lv", 20)) * L + float(mods.get("hp_flat", 0.0))) \
		* (1.0 + float(mods.get("hp_pct", 0.0)) / 100.0) * star
	s["def"] = (float(base.get("def", 5)) + float(base.get("def_lv", 1)) * L + float(mods.get("def_flat", 0.0))) \
		* (1.0 + float(mods.get("def_pct", 0.0)) / 100.0) * star
	var caps: Dictionary = DataDB.bal("caps", {})
	s["crit_chance"] = min(float(caps.get("crit_chance", 75)), float(DataDB.bal("combat.base_crit", 5)) + float(mods.get("crit_chance", 0.0)))
	s["crit_dmg"] = min(float(caps.get("crit_dmg", 500)), float(DataDB.bal("combat.base_crit_dmg", 150)) + float(mods.get("crit_dmg", 0.0)))
	var spd: float = float(mods.get("attack_speed", 0.0))
	if s["uses_spell"]:
		spd += float(mods.get("cast_speed", 0.0)) * 0.5
	s["attack_speed_total"] = min(float(caps.get("attack_speed", 225)), 100.0 + spd)
	var w: Dictionary = h.equipment.get("weapon", {})
	var weapon_aps: float = float(w.get("base", {}).get("aps", cd.get("aps", 1.0))) if not w.is_empty() else float(cd.get("aps", 1.0))
	s["aps"] = weapon_aps * s["attack_speed_total"] / 100.0
	s["penetrate"] = min(float(caps.get("penetrate", 60)), float(mods.get("penetrate", 0.0)))
	s["cdr"] = min(float(caps.get("cdr", 40)), float(mods.get("cdr", 0.0)))
	s["dr"] = min(float(caps.get("dr", 75)), float(mods.get("dr", 0.0)))
	s["evasion"] = min(float(caps.get("evasion", 50)), float(mods.get("evasion", 0.0)))
	s["block"] = min(float(caps.get("block", 50)), float(mods.get("block", 0.0)))
	s["lifesteal"] = min(float(caps.get("lifesteal", 10)), float(mods.get("lifesteal", 0.0)))
	s["crit_res"] = min(float(caps.get("crit_res", 50)), float(mods.get("crit_res", 0.0)))
	s["item_find"] = min(float(caps.get("item_find", 400)), float(mods.get("item_find", 0.0)))
	s["gold_find"] = min(float(caps.get("gold_find", 400)), float(mods.get("gold_find", 0.0)))
	var pen: float = F.difficulty_res_penalty(difficulty)
	for e in ELEMENTS:
		s[e + "_res"] = min(float(caps.get("res", 75)), float(mods.get(e + "_res", 0.0)) + float(mods.get("all_res", 0.0)) + pen)
	s["hp_regen"] = s["max_hp"] * float(mods.get("hp_regen_pct", 0.0)) / 100.0 + float(mods.get("hp_regen", 0.0))
	s["threat"] = float(cd.get("threat", 0)) + float(mods.get("threat", 0.0))
	s["range"] = float(cd.get("range", 26))
	s["melee"] = bool(cd.get("melee", true))
	return s


## Short DPS estimate used by UI comparisons.
static func dps_estimate(s: Dictionary) -> float:
	var crit: float = float(s.get("crit_chance", 5)) / 100.0
	var cm: float = float(s.get("crit_dmg", 150)) / 100.0
	var inc: float = 1.0 + float(s.get("added_dmg", 0.0)) / 100.0
	return float(s.get("power", 0)) * float(s.get("aps", 1)) * (1.0 + crit * (cm - 1.0)) * inc


static func ehp_estimate(s: Dictionary, level: int) -> float:
	var d: float = float(s.get("def", 0))
	var dr: float = min(0.75, d / (d + 50.0 + 6.0 * level))
	dr = 1.0 - (1.0 - dr) * (1.0 - float(s.get("dr", 0.0)) / 100.0)
	return float(s.get("max_hp", 1)) / max(0.05, 1.0 - dr)
