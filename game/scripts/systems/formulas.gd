class_name F
extends RefCounted
## Balance formulas. All coefficients come from data/balance.json (DataDB.balance).


static func b(path: String, default: Variant = 0.0) -> Variant:
	return DataDB.bal(path, default)


# ------------------------------------------------------------------ XP / gold
static func xp_per_kill(level: int, etype: String = "normal") -> float:
	var base: float = b("xp.kill_base", 8.0) + b("xp.kill_coef", 1.5) * pow(level, b("xp.kill_exp", 1.5))
	var tm: float = float(b("xp.type_mult", {}).get(etype, 1.0))
	return round(base) * tm


static func kills_to_level(level: int) -> int:
	return int(b("xp.kills_base", 40) + b("xp.kills_per_level", 9) * level)


static func xp_required(level: int) -> float:
	if level >= int(b("xp.max_level", 100)):
		# paragon requirement grows 2% per paragon level
		return round(8 + 1.5 * pow(100, 1.5)) * kills_to_level(100)
	return round(8 + 1.5 * pow(level, 1.5)) * kills_to_level(level)


static func xp_level_factor(hero_level: int, monster_level: int) -> float:
	var diff := monster_level - hero_level
	if diff <= -int(b("xp.penalty_low_start", 5)):
		var steps := (-diff) - int(b("xp.penalty_low_start", 5)) + 1
		return max(b("xp.penalty_low_min", 0.1), 1.0 - steps * b("xp.penalty_low_step", 0.1))
	if diff >= int(b("xp.bonus_high_start", 3)):
		var steps2 := diff - int(b("xp.bonus_high_start", 3)) + 1
		return 1.0 + min(b("xp.bonus_high_max", 0.25), steps2 * b("xp.bonus_high_step", 0.05))
	return 1.0


static func gold_per_kill(level: int, etype: String = "normal") -> float:
	var g: float = b("gold.base", 3) + b("gold.coef", 0.8) * pow(level, b("gold.exp", 1.3))
	var mult := {"normal": 1.0, "elite": 4.0, "miniboss": 8.0, "boss": 20.0, "actboss": 50.0}
	return round(g * float(mult.get(etype, 1.0)))


# ------------------------------------------------------------------ reference hero (drives enemy scaling)
static func ref_attack(level: int) -> float:
	var r: Dictionary = b("ref", {})
	var base: float = r.get("atk_base", 14.0) + r.get("atk_lv", 3.2) * level + r.get("weapon_base", 10.0) * pow(r.get("weapon_growth", 1.055), level)
	return base * (1.0 + r.get("stat_pct_lv", 0.006) * level + r.get("affix_pct_lv", 0.006) * level)


static func ref_dps(level: int) -> float:
	return ref_attack(level) * float(b("ref.dps_mult", 1.6))


static func ref_hp(level: int) -> float:
	var r: Dictionary = b("ref", {})
	var hp: float = (r.get("hp_base", 190.0) + r.get("hp_lv", 48.0) * level) * (1.0 + r.get("hp_pct_lv", 0.004) * level)
	return hp + r.get("item_hp", 120.0) * pow(r.get("item_hp_growth", 1.045), level)


static func early_factor(level: int) -> float:
	return clamp(float(b("ref.early_factor_base", 0.25)) + float(b("ref.early_factor_lv", 0.025)) * level, 0.0, 1.0)


# ------------------------------------------------------------------ enemies
## Player resistance penalty for the current difficulty (Diablo style).
static func difficulty_res_penalty(difficulty: int) -> float:
	return float(b("enemy.difficulty_res", [0, -30, -60])[clamp(difficulty, 0, 2)])


static func monster_level(zone: Dictionary, stage: int, difficulty: int) -> int:
	var lv: Array = zone.get("level", [1, 1])
	var stages: int = int(b("stage.stages_per_zone", 10))
	var t: float = float(stage - 1) / float(max(1, stages - 1))
	var base_lv: float = lerp(float(lv[0]), float(lv[1]), t)
	var dl: Array = b("enemy.difficulty_level", [[0, 1.0], [50, 0.5], [75, 0.5]])
	var d: Array = dl[clamp(difficulty, 0, dl.size() - 1)]
	return int(round(float(d[0]) + base_lv * float(d[1]))) if difficulty > 0 else int(round(base_lv))


static func enemy_stats(def: Dictionary, level: int, etype: String, difficulty: int) -> Dictionary:
	var diff_mult: float = float(b("enemy.difficulty_mult", [1.0, 1.25, 1.5])[clamp(difficulty, 0, 2)])
	var type_hp: float = float(b("enemy.type_hp", {}).get(etype, 1.0))
	var type_atk: float = float(b("enemy.type_atk", {}).get(etype, 1.0))
	var hp: float = ref_dps(level) * float(b("ref.enemy_hp_k", 7.0)) * early_factor(level) * float(def.get("hp", 1.0)) * type_hp * diff_mult
	var atk: float = ref_hp(level) * float(b("ref.enemy_atk_k", 0.035)) * float(def.get("atk", 1.0)) * type_atk * diff_mult
	atk *= lerp(0.6, 1.0, early_factor(level))
	var dfn: float = float(b("enemy.def_base", 10)) + float(b("enemy.def_per_level", 4.5)) * level
	var res: Dictionary = {}
	for e in ["fire", "cold", "lightning", "chaos", "holy", "physical"]:
		res[e] = float(def.get("res", {}).get(e, 0.0))
	return {"hp": max(1.0, round(hp)), "atk": max(1.0, round(atk)), "def": round(dfn), "res": res}


# ------------------------------------------------------------------ items
static func tier_for_level(ilvl: int) -> int:
	var tl: Array = b("items.tier_levels", [1, 12, 25, 40, 55, 70, 85])
	var t := 0
	for i in tl.size():
		if ilvl >= int(tl[i]):
			t = i
	return t


static func flat_scale(ilvl: int) -> float:
	return pow(float(b("items.flat_growth", 1.05)), ilvl)


static func armor_scale(ilvl: int) -> float:
	return pow(float(b("items.armor_growth", 1.035)), ilvl)


# ------------------------------------------------------------------ misc
static func stat_reset_cost(level: int, resets_done: int) -> int:
	if resets_done < int(b("stat_reset_cost.free", 2)):
		return 0
	return int(float(b("stat_reset_cost.coef", 100)) * pow(level, float(b("stat_reset_cost.exp", 1.5))))


static func fmt_num(v: float) -> String:
	var a: float = abs(v)
	var sgn := "-" if v < 0 else ""
	if a >= 1e9:
		return sgn + "%.2fB" % (a / 1e9)
	if a >= 1e6:
		return sgn + "%.2fM" % (a / 1e6)
	if a >= 1e4:
		return sgn + "%.1fK" % (a / 1e3)
	if a >= 100 or is_equal_approx(a, round(a)):
		return sgn + str(int(round(a)))
	return sgn + "%.1f" % a


static func fmt_int_grouped(v: int) -> String:
	var s := str(abs(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out
