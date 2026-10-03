class_name Runes
extends RefCounted
## Rune trees: every hero grows their own web of personal upgrades, bought with gold. Nodes sit on a grid
## around the central rune and open outwards: a node can be bought once one of its neighbours along a line
## has a rank. Four branches: war (right), defense (left), discovery (up), arcane (down). The ranks feed only
## that hero's stats (discovery runes count towards the party's average find).

## id: [x, y, stat, per rank, max rank, glyph, links (ids it grows from)]
const NODES := {
	"core": [0, 0, "added_dmg", 2.0, 1, "rune", []],
	# war
	"w1": [1, 0, "added_dmg", 2.0, 5, "sword", ["core"]],
	"w2": [2, 0, "attack_speed", 1.5, 5, "bolt", ["w1"]],
	"w3": [3, 0, "crit_chance", 0.5, 5, "target", ["w2"]],
	"w3a": [3, -1, "penetrate", 1.5, 5, "arrow", ["w3"]],
	"w3b": [3, -2, "phys_dmg", 3.0, 5, "hammer", ["w3a"]],
	"w4": [4, 0, "crit_dmg", 4.0, 5, "claw", ["w3"]],
	"w5": [5, 0, "elite_dmg", 4.0, 5, "flag", ["w4"]],
	"w5a": [5, 1, "aoe_dmg", 3.0, 5, "star", ["w5"]],
	"w5b": [5, 2, "execute_dmg", 4.0, 5, "skull", ["w5a"]],
	"w6": [6, 0, "boss_dmg", 4.0, 5, "crown", ["w5"]],
	"w7": [7, 0, "added_dmg", 3.0, 5, "sword", ["w6"]],
	"w7a": [8, -1, "crit_dmg", 6.0, 5, "claw", ["w7"]],
	"w7b": [8, 1, "attack_speed", 2.0, 5, "bolt", ["w7"]],
	# defense
	"d1": [-1, 0, "hp_pct", 2.0, 5, "heart", ["core"]],
	"d2": [-2, 0, "def_pct", 3.0, 5, "shield", ["d1"]],
	"d2a": [-2, 1, "evasion", 1.0, 5, "boot", ["d2"]],
	"d2b": [-2, 2, "crit_res", 2.0, 5, "eye", ["d2a"]],
	"d3": [-3, 0, "all_res", 1.5, 5, "gem", ["d2"]],
	"d4": [-4, 0, "dr", 0.5, 5, "tower", ["d3"]],
	"d4a": [-4, -1, "revive_speed", 5.0, 5, "cross", ["d4"]],
	"d4b": [-4, -2, "thorns", 3.0, 5, "spikes", ["d4a"]],
	"d5": [-5, 0, "hp_pct", 3.0, 5, "heart", ["d4"]],
	"d6": [-6, 0, "block", 1.0, 5, "lock", ["d5"]],
	"d7": [-7, 0, "lifesteal", 0.3, 5, "drop", ["d6"]],
	"d7a": [-8, -1, "dr", 0.6, 5, "tower", ["d7"]],
	"d7b": [-8, 1, "hp_pct", 4.0, 5, "heart", ["d7"]],
	# discovery
	"e1": [0, -1, "xp_bonus", 3.0, 5, "book", ["core"]],
	"e2": [0, -2, "gold_find", 3.0, 5, "gold", ["e1"]],
	"e2a": [-1, -2, "xp_bonus", 3.0, 5, "book", ["e2"]],
	"e2b": [1, -2, "gold_find", 3.0, 5, "gold", ["e2"]],
	"e3": [0, -3, "item_find", 3.0, 5, "bag", ["e2"]],
	"e4": [0, -4, "chest_find", 8.0, 5, "chest", ["e3"]],
	"e4a": [-1, -4, "gold_find", 4.0, 5, "gold", ["e4"]],
	"e4b": [1, -4, "xp_bonus", 4.0, 5, "book", ["e4"]],
	"e5": [0, -5, "legendary_find", 1.0, 5, "crown", ["e4"]],
	"e6": [0, -6, "chest_find", 12.0, 5, "chest", ["e5"]],
	# arcane
	"a1": [0, 1, "skill_dmg", 3.0, 5, "flame", ["core"]],
	"a2": [0, 2, "cdr", 1.0, 5, "clock", ["a1"]],
	"a3": [0, 3, "ult_charge", 3.0, 5, "potion", ["a2"]],
	"a3a": [-1, 3, "heal_bonus", 4.0, 5, "plus", ["a3"]],
	"a3b": [1, 3, "summon_dmg", 5.0, 5, "people", ["a3"]],
	"a4": [0, 4, "elem_dmg", 3.0, 5, "rune", ["a3"]],
	"a5": [0, 5, "ult_dmg", 5.0, 5, "sparkle", ["a4"]],
	"a5a": [-1, 5, "buff_duration", 4.0, 5, "note", ["a5"]],
	"a5b": [1, 5, "pet_dmg", 6.0, 5, "heart", ["a5"]],
	"a6": [0, 6, "skill_dmg", 5.0, 5, "flame", ["a5"]],
}
const BRANCH_COL := {"w": Color("#FF8A4A"), "d": Color("#6FB7FF"), "e": Color("#FFD35A"), "a": Color("#C58BFF"), "c": Color("#FFE9B0")}
## stat list groups (right-hand parchment)
const GROUPS := [
	["rune_g_discovery", ["xp_bonus", "gold_find", "item_find", "chest_find", "legendary_find"]],
	["rune_g_war", ["added_dmg", "attack_speed", "crit_chance", "crit_dmg", "penetrate", "phys_dmg", "elite_dmg", "boss_dmg", "aoe_dmg", "execute_dmg"]],
	["rune_g_defense", ["hp_pct", "def_pct", "all_res", "dr", "evasion", "crit_res", "block", "lifesteal", "thorns", "revive_speed"]],
	["rune_g_arcane", ["skill_dmg", "cdr", "ult_charge", "elem_dmg", "ult_dmg", "heal_bonus", "summon_dmg", "buff_duration", "pet_dmg"]],
]


static func _store(h: HeroState) -> Dictionary:
	return h.runes if h else {}


static func rank(h: HeroState, id: String) -> int:
	return int(_store(h).get(id, 0))


static func max_rank(id: String) -> int:
	return int(NODES[id][4])


static func pos(id: String) -> Vector2i:
	return Vector2i(int(NODES[id][0]), int(NODES[id][1]))


static func stat(id: String) -> String:
	return str(NODES[id][2])


static func per(id: String) -> float:
	return float(NODES[id][3])


static func glyph(id: String) -> String:
	return str(NODES[id][5])


static func links(id: String) -> Array:
	return NODES[id][6]


static func branch_color(id: String) -> Color:
	return BRANCH_COL.get(id.substr(0, 1), BRANCH_COL["c"])


static func ring(id: String) -> int:
	var p := pos(id)
	return absi(p.x) + absi(p.y)


## Gold price of the next rank.
static func cost(h: HeroState, id: String) -> int:
	var r := rank(h, id)
	return int(round(150.0 * pow(2.2, maxi(0, ring(id) - 1)) * pow(1.6, r) / 10.0) * 10.0)


## Open = linked from a node that already has a rank (the core is always open).
static func is_open(h: HeroState, id: String) -> bool:
	if links(id).is_empty():
		return true
	for l in links(id):
		if rank(h, str(l)) > 0:
			return true
	return false


static func can_buy(h: HeroState, id: String) -> bool:
	return h != null and is_open(h, id) and rank(h, id) < max_rank(id) and GameState.gold >= cost(h, id)


static func buy(h: HeroState, id: String) -> bool:
	if not can_buy(h, id):
		return false
	GameState.spend_gold(cost(h, id))
	h.runes[id] = rank(h, id) + 1
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.runes_changed.emit()
	return true


## Summed bonuses of every learned rank of one hero, by stat.
static func totals(h: HeroState) -> Dictionary:
	var out := {}
	for id in _store(h):
		if NODES.has(id):
			var s := stat(id)
			out[s] = float(out.get(s, 0.0)) + per(id) * rank(h, id)
	return out


static func points_spent(h: HeroState) -> int:
	var n := 0
	for id in _store(h):
		n += int(_store(h)[id])
	return n


## Party average of a stat from runes (chest find).
static func party_average(stat_key: String) -> float:
	var ph := GameState.party_heroes()
	if ph.is_empty():
		return 0.0
	var t := 0.0
	for h in ph:
		t += float(totals(h).get(stat_key, 0.0))
	return t / ph.size()


static func any_affordable() -> bool:
	for h in GameState.party_heroes():
		for id in NODES:
			if can_buy(h, id):
				return true
	return false
