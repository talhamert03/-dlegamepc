class_name Combatant
extends RefCounted
## Runtime state of one unit on the battle strip (hero, summon or enemy).

enum Side { HERO, ENEMY }

static var _next_uid := 1

var uid: int = 0
var side: int = Side.HERO
var id: String = ""          # hero id / enemy id
var name: String = ""
var etype: String = "normal" # normal | elite | boss | actboss | summon | hero
var level: int = 1
var stats: Dictionary = {}
var hp: float = 1.0
var max_hp: float = 1.0
var shield: float = 0.0
var shield_t: float = 0.0
var x: float = 0.0
var home_x: float = 0.0
var slot: int = 0
var alive: bool = true
var dead_t: float = 0.0        # time since death (enemies removed after anim)
var revive_t: float = 0.0
var atk_cd: float = 0.0
var busy_t: float = 0.0
var skills: Array = []         # [{id, lvl, cd, def}]
var ult_id: String = ""
var ult_lvl: int = 0
var ult_charge: float = 0.0
var buffs: Array = []          # [{stat, v, t}]
var statuses: Dictionary = {}  # name -> {t, stacks, power}
var dot_t: float = 0.0
var cheat_death_left: int = 0
var lifetime: float = -1.0     # summons
var owner_uid: int = 0
var visual: Dictionary = {}    # sprite info for the view
var element: String = "physical"
var projectile: String = ""
var tags: Array = []
var mech: Array = []
var mech_t: float = 0.0
var telegraph: Dictionary = {}
var anim: String = "idle"
var anim_t: float = 0.0
var act_impact: float = 0.25   # seconds from the start of the current attack/skill to its hit (drives the view)
var act_len: float = 0.5
var flash_t: float = 0.0
var last_target: int = 0


func _init() -> void:
	uid = _next_uid
	_next_uid += 1


func st(k: String, default: float = 0.0) -> float:
	var v: float = float(stats.get(k, default))
	for b in buffs:
		if b["stat"] == k:
			v += float(b["v"])
	return v


func has_status(s: String) -> bool:
	return statuses.has(s) and float(statuses[s]["t"]) > 0.0


func is_stunned() -> bool:
	return has_status("stun") or has_status("freeze")


func is_hero_side() -> bool:
	return side == Side.HERO


func hp_frac() -> float:
	return clamp(hp / max(1.0, max_hp), 0.0, 1.0)


func set_anim(a: String) -> void:
	anim = a
	anim_t = 0.0
