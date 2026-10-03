class_name ZoneInfo
extends RefCounted
## What a zone throws at the party and whether the party is ready: the elements its monsters and boss use,
## the resistance worth having there, a readiness verdict and a plain hint for players who are stuck.

const ELEMENT_ICON := {"fire": "🔥", "cold": "❄", "lightning": "⚡", "chaos": "☠", "holy": "✦"}
const TARGET_RES := 25.0   # effective resistance that makes elemental hits comfortable


## Non-physical elements used in a zone, the boss's first.
static func elements(z: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = [z.get("boss", "")]
	ids.append_array(z.get("enemies", []))
	for eid in ids:
		var el := str(DataDB.enemy_def(str(eid)).get("element", "physical"))
		if el != "physical" and el != "" and not out.has(el):
			out.append(el)
	return out


const ELEMENT_NAME := {"fire": ["Ateş", "Fire"], "cold": ["Soğuk", "Cold"], "lightning": ["Yıldırım", "Lightning"],
	"chaos": ["Kaos", "Chaos"], "holy": ["Kutsal", "Holy"]}


static func element_name(el: String) -> String:
	var n: Array = ELEMENT_NAME.get(el, [el, el])
	return n[0] if DataDB.lang == "tr" else n[1]


## Effective resistance of the weakest party hero against `el`, as it would be on difficulty `diff`.
static func party_res(el: String, diff: int) -> float:
	var worst := INF
	var cur_pen := F.difficulty_res_penalty(BattleSim.difficulty)
	for h in GameState.party_heroes():
		var s := GameState.hero_stats(h.id)
		var v := float(s.get(el + "_res", 0.0)) - cur_pen + F.difficulty_res_penalty(diff)
		worst = minf(worst, v)
	return 0.0 if worst == INF else worst


static func party_level() -> float:
	var ph := GameState.party_heroes()
	if ph.is_empty():
		return 1.0
	var t := 0.0
	for h in ph:
		t += h.level
	return t / ph.size()


## "ok" | "hard" | "very_hard" for a zone on a difficulty, from levels and missing resistances.
static func readiness(z: Dictionary, diff: int) -> String:
	var gap := float(F.monster_level(z, 10, diff)) - party_level()
	var short := 0
	for el in elements(z):
		if party_res(el, diff) < TARGET_RES - 15.0:
			short += 1
	if gap > 6.0 or (gap > 2.0 and short > 0):
		return "very_hard"
	if gap > 1.0 or short > 0:
		return "hard"
	return "ok"


## One line of advice for a zone the party keeps failing.
static func hint(z: Dictionary, diff: int) -> String:
	for el in elements(z):
		var r := party_res(el, diff)
		if r < TARGET_RES:
			return DataDB.t("hint_res", {"el": ELEMENT_ICON.get(el, "") + " " + element_name(el), "now": int(r), "want": int(TARGET_RES)})
	var gap := float(F.monster_level(z, 10, diff)) - party_level()
	if gap > 1.0:
		return DataDB.t("hint_level", {"n": int(ceil(gap))})
	return DataDB.t("hint_gear")


## Damage per second a party needs to clear a stage comfortably: a wave in ~10 s, the boss inside its timer
## with room to spare. Same scale as the live party DPS shown in the HUD.
static func dps_needed(z: Dictionary, stage: int, diff: int) -> float:
	var stages := int(DataDB.bal("stage.stages_per_zone", 10))
	if stage >= stages:
		var bid := str(z.get("boss", ""))
		var bd := DataDB.enemy_def(bid)
		var lv := F.monster_level(z, stages, diff) + 1
		var hp := float(F.enemy_stats(bd, lv, str(bd.get("type", "boss")), diff).get("hp", 1.0))
		return hp / (float(DataDB.bal("stage.boss_time", 90)) * 0.7)
	var roster: Array = z.get("enemies", [])
	if roster.is_empty():
		return 0.0
	var lv2 := F.monster_level(z, stage, diff)
	var tot := 0.0
	for eid in roster:
		tot += float(F.enemy_stats(DataDB.enemy_def(str(eid)), lv2, "normal", diff).get("hp", 1.0))
	var per := tot / roster.size()
	var n := mini(4, GameState.party_count() + 1)
	return per * n / 10.0
