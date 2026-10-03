class_name Runes
extends RefCounted
## Rune tree: an account-wide web of upgrades bought with gold. Nodes sit on a grid around the central
## rune and open outwards: a node can be bought once one of its neighbours along a line has a rank.
## Four branches: war (right), defense (left), discovery (up), arcane (down).

## id: [x, y, stat, per rank, max rank, icon, links (ids it grows from)]
const NODES := {
	"core": [0, 0, "added_dmg", 2.0, 1, "knight_valor", []],
	# war
	"w1": [1, 0, "added_dmg", 2.0, 5, "berserker_rage", ["core"]],
	"w2": [2, 0, "attack_speed", 1.5, 5, "assassin_dual", ["w1"]],
	"w3": [3, 0, "crit_chance", 0.5, 5, "assassin_sneaky", ["w2"]],
	"w3a": [3, -1, "penetrate", 1.5, 5, "archer_pierce", ["w3"]],
	"w3b": [3, -2, "phys_dmg", 3.0, 5, "knight_mastery", ["w3a"]],
	"w4": [4, 0, "crit_dmg", 4.0, 5, "assassin_precision", ["w3"]],
	"w5": [5, 0, "elite_dmg", 4.0, 5, "knight_judgement", ["w4"]],
	"w5a": [5, 1, "aoe_dmg", 3.0, 5, "berserker_whirl", ["w5"]],
	"w5b": [5, 2, "execute_dmg", 4.0, 5, "assassin_execute", ["w5a"]],
	"w6": [6, 0, "boss_dmg", 4.0, 5, "berserker_quake", ["w5"]],
	"w7": [7, 0, "added_dmg", 3.0, 5, "berserker_ragnarok", ["w6"]],
	"w7a": [8, -1, "crit_dmg", 6.0, 5, "assassin_thousand", ["w7"]],
	"w7b": [8, 1, "attack_speed", 2.0, 5, "berserker_frenzy", ["w7"]],
	# defense
	"d1": [-1, 0, "hp_pct", 2.0, 5, "knight_iron_skin", ["core"]],
	"d2": [-2, 0, "def_pct", 3.0, 5, "knight_shield_wall", ["d1"]],
	"d2a": [-2, 1, "evasion", 1.0, 5, "assassin_cloak", ["d2"]],
	"d2b": [-2, 2, "crit_res", 2.0, 5, "knight_steadfast", ["d2a"]],
	"d3": [-3, 0, "all_res", 1.5, 5, "cleric_light_shield", ["d2"]],
	"d4": [-4, 0, "dr", 0.5, 5, "knight_fortress", ["d3"]],
	"d4a": [-4, -1, "revive_speed", 5.0, 5, "cleric_resurrection", ["d4"]],
	"d4b": [-4, -2, "thorns", 3.0, 5, "knight_thorns", ["d4a"]],
	"d5": [-5, 0, "hp_pct", 3.0, 5, "berserker_thick", ["d4"]],
	"d6": [-6, 0, "block", 1.0, 5, "knight_bash", ["d5"]],
	"d7": [-7, 0, "lifesteal", 0.3, 5, "berserker_thirst", ["d6"]],
	"d7a": [-8, -1, "dr", 0.6, 5, "knight_last_stand", ["d7"]],
	"d7b": [-8, 1, "hp_pct", 4.0, 5, "berserker_undying", ["d7"]],
	# discovery
	"e1": [0, -1, "xp_bonus", 3.0, 5, "mage_focus", ["core"]],
	"e2": [0, -2, "gold_find", 3.0, 5, "bard_golden", ["e1"]],
	"e2a": [-1, -2, "offline_eff", 3.0, 5, "bard_lullaby", ["e2"]],
	"e2b": [1, -2, "gold_find", 3.0, 5, "bard_luck", ["e2"]],
	"e3": [0, -3, "item_find", 3.0, 5, "archer_keen_eye", ["e2"]],
	"e4": [0, -4, "chest_find", 8.0, 5, "bard_legends", ["e3"]],
	"e4a": [-1, -4, "gold_find", 4.0, 5, "bard_fingers", ["e4"]],
	"e4b": [1, -4, "xp_bonus", 4.0, 5, "mage_wellspring", ["e4"]],
	"e5": [0, -5, "legendary_find", 1.0, 5, "bard_epic", ["e4"]],
	"e6": [0, -6, "chest_find", 12.0, 5, "cleric_miracle", ["e5"]],
	# arcane
	"a1": [0, 1, "skill_dmg", 3.0, 5, "mage_ember", ["core"]],
	"a2": [0, 2, "cdr", 1.0, 5, "mage_haste", ["a1"]],
	"a3": [0, 3, "ult_charge", 3.0, 5, "mage_cycle", ["a2"]],
	"a3a": [-1, 3, "heal_bonus", 4.0, 5, "cleric_heal", ["a3"]],
	"a3b": [1, 3, "summon_dmg", 5.0, 5, "necro_skeletons", ["a3"]],
	"a4": [0, 4, "elem_dmg", 3.0, 5, "mage_storm", ["a3"]],
	"a5": [0, 5, "ult_dmg", 5.0, 5, "mage_meteor", ["a4"]],
	"a5a": [-1, 5, "buff_duration", 4.0, 5, "bard_march", ["a5"]],
	"a5b": [1, 5, "pet_dmg", 6.0, 5, "archer_wolf", ["a5"]],
	"a6": [0, 6, "skill_dmg", 5.0, 5, "necro_doom", ["a5"]],
}
const BRANCH_COL := {"w": Color("#FF8A4A"), "d": Color("#6FB7FF"), "e": Color("#FFD35A"), "a": Color("#C58BFF"), "c": Color("#FFE9B0")}
## stat list groups (right-hand parchment)
const GROUPS := [
	["rune_g_discovery", ["xp_bonus", "gold_find", "item_find", "chest_find", "legendary_find", "offline_eff"]],
	["rune_g_war", ["added_dmg", "attack_speed", "crit_chance", "crit_dmg", "penetrate", "phys_dmg", "elite_dmg", "boss_dmg", "aoe_dmg", "execute_dmg"]],
	["rune_g_defense", ["hp_pct", "def_pct", "all_res", "dr", "evasion", "crit_res", "block", "lifesteal", "thorns", "revive_speed"]],
	["rune_g_arcane", ["skill_dmg", "cdr", "ult_charge", "elem_dmg", "ult_dmg", "heal_bonus", "summon_dmg", "buff_duration", "pet_dmg"]],
]


static func rank(id: String) -> int:
	return int(GameState.runes.get(id, 0))


static func max_rank(id: String) -> int:
	return int(NODES[id][4])


static func pos(id: String) -> Vector2i:
	return Vector2i(int(NODES[id][0]), int(NODES[id][1]))


static func stat(id: String) -> String:
	return str(NODES[id][2])


static func per(id: String) -> float:
	return float(NODES[id][3])


static func links(id: String) -> Array:
	return NODES[id][6]


static func branch_color(id: String) -> Color:
	return BRANCH_COL.get(id.substr(0, 1), BRANCH_COL["c"])


static func ring(id: String) -> int:
	var p := pos(id)
	return absi(p.x) + absi(p.y)


## Gold price of the next rank.
static func cost(id: String) -> int:
	var r := rank(id)
	return int(round(250.0 * pow(2.3, maxi(0, ring(id) - 1)) * pow(1.6, r) / 10.0) * 10.0)


## Open = linked from a node that already has a rank (the core is always open).
static func is_open(id: String) -> bool:
	if links(id).is_empty():
		return true
	for l in links(id):
		if rank(str(l)) > 0:
			return true
	return false


static func can_buy(id: String) -> bool:
	return is_open(id) and rank(id) < max_rank(id) and GameState.gold >= cost(id)


static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	GameState.spend_gold(cost(id))
	GameState.runes[id] = rank(id) + 1
	GameState.invalidate_stats()
	EventBus.runes_changed.emit()
	return true


## Summed bonuses of every learned rank, by stat.
static func totals() -> Dictionary:
	var out := {}
	for id in GameState.runes:
		if NODES.has(id):
			var s := stat(id)
			out[s] = float(out.get(s, 0.0)) + per(id) * rank(id)
	return out


static func total(stat_key: String) -> float:
	return float(totals().get(stat_key, 0.0))


static func any_affordable() -> bool:
	for id in NODES:
		if can_buy(id):
			return true
	return false
