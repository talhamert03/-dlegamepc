class_name Chests
extends RefCounted
## Treasure chests: five rarities drop from kills on the battlefield, wait in GameState.chests and are
## opened from the chest window. Rewards scale with the chest's rarity and the level it dropped at.

const KINDS := ["wood", "iron", "gold", "crystal", "royal"]
const MAX_HELD := 30
## gold = that many normal kills' worth; items = [min, max] count, first one at least `min_r`
const DEF := {
	"wood": {"gold": 25, "items": [1, 1], "min_r": "common", "mats": {"iron_scrap": [1, 3]}},
	"iron": {"gold": 50, "items": [1, 2], "min_r": "magic", "mats": {"iron_scrap": [2, 5]}},
	"gold": {"gold": 110, "items": [2, 3], "min_r": "rare", "mats": {"iron_scrap": [3, 6], "tavern_seal": [1, 1]}},
	"crystal": {"gold": 220, "items": [3, 3], "min_r": "epic", "mats": {"soul_shard": [2, 4], "tavern_seal": [1, 2]}},
	"royal": {"gold": 480, "items": [3, 4], "min_r": "legendary", "mats": {"soul_shard": [4, 8], "tavern_seal": [2, 3], "guild_badge": [1, 2]}},
}
## chance per kill and the rarity table by enemy type
const DROP := {"normal": 0.0045, "elite": 0.06, "miniboss": 0.25, "boss": 0.6, "actboss": 1.0}
const WEIGHTS := {
	"normal": [70.0, 24.0, 5.0, 0.9, 0.1],
	"elite": [0.0, 62.0, 30.0, 7.0, 1.0],
	"miniboss": [0.0, 40.0, 45.0, 13.0, 2.0],
	"boss": [0.0, 0.0, 68.0, 27.0, 5.0],
	"actboss": [0.0, 0.0, 0.0, 75.0, 25.0],
}
const COLORS := {"wood": Color("#C8A27A"), "iron": Color("#9FC2E6"), "gold": Color("#FFC94A"),
	"crystal": Color("#C58BFF"), "royal": Color("#FF8A3D")}


static func rank(kind: String) -> int:
	return KINDS.find(kind)


static func color(kind: String) -> Color:
	return COLORS.get(kind, Color.WHITE)


static func display_name(kind: String) -> String:
	return DataDB.t("chest_" + kind)


## Rolls a chest for a kill. Returns "" when none drops.
static func roll(rng: RandomNumberGenerator, etype: String, luck := 0.0) -> String:
	var chance: float = float(DROP.get(etype, 0.0)) * (1.0 + luck / 300.0 + Runes.party_average("chest_find") / 100.0)
	if rng.randf() >= chance:
		return ""
	var w: Array = WEIGHTS.get(etype, WEIGHTS["normal"])
	var total := 0.0
	for v in w:
		total += float(v)
	var x := rng.randf() * total
	for i in w.size():
		x -= float(w[i])
		if x <= 0.0:
			return KINDS[i]
	return KINDS[0]


static func add(kind: String, level: int) -> void:
	var held: Array = GameState.chests
	if held.size() >= MAX_HELD:
		# full: the weakest chest makes room for a better one
		var worst := 0
		for i in held.size():
			if rank(str(held[i]["k"])) < rank(str(held[worst]["k"])):
				worst = i
		if rank(str(held[worst]["k"])) >= rank(kind):
			return
		held.remove_at(worst)
	held.append({"k": kind, "lv": level, "t": TimeService.unix_now()})
	GameState.totals["chests_found"] = int(GameState.totals.get("chests_found", 0)) + 1
	EventBus.chests_changed.emit()


static func count() -> int:
	return GameState.chests.size()


## Index of the best chest held (opened first), or -1.
static func best_index() -> int:
	var best := -1
	for i in GameState.chests.size():
		if best < 0 or rank(str(GameState.chests[i]["k"])) > rank(str(GameState.chests[best]["k"])):
			best = i
	return best


## Opens a held chest: grants and returns {kind, gold, items: [[item, result]], mats}.
static func open(index: int) -> Dictionary:
	if index < 0 or index >= GameState.chests.size():
		return {}
	var c: Dictionary = GameState.chests[index]
	GameState.chests.remove_at(index)
	var kind := str(c["k"])
	var lv := int(c.get("lv", 1))
	var rng: RandomNumberGenerator = GameState.rng
	var d: Dictionary = DEF[kind]
	var out := {"kind": kind, "gold": 0, "items": [], "mats": {}}
	var g := int(F.gold_per_kill(lv, "normal") * float(d["gold"]) * rng.randf_range(0.85, 1.2))
	GameState.add_gold(g)
	out["gold"] = g
	var classes: Array = GameState.party_classes()
	var n := rng.randi_range(int(d["items"][0]), int(d["items"][1]))
	for i in n:
		var r := LootSystem.roll_rarity(rng, 0.0, 0, str(d["min_r"]) if i == 0 else "common")
		if i > 0 and ItemUtil.rarity_rank(r) < ItemUtil.rarity_rank("magic") and rank(kind) >= 2:
			r = "magic"
		var cls := ""
		if classes.size() > 0 and rng.randf() < 0.75:
			cls = classes[rng.randi() % classes.size()]
		var it := LootSystem.generate(rng, lv, r, cls)
		out["items"].append([it, GameState.receive_item(it)])
	for m in d["mats"]:
		var k := rng.randi_range(int(d["mats"][m][0]), int(d["mats"][m][1]))
		GameState.add_material(m, k)
		out["mats"][m] = k
	GameState.totals["chests_opened"] = int(GameState.totals.get("chests_opened", 0)) + 1
	EventBus.chests_changed.emit()
	return out
