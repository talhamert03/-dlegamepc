extends Node
## Deterministic-ish battle simulation for the strip. Runs at a fixed tick rate independent
## from rendering. The view (StripView) only reads state and listens to EventBus signals.

const TICK := 0.1
const VISIBLE_X := 350.0     # ranged heroes hit anything that has walked into view
const HERO_X := [196.0, 166.0, 136.0, 106.0, 76.0]   # slot 0 = front-most
const SPAWN_X := 420.0
const GROUND_Y := 64.0

var running := false
var speed := 1.0
var acc := 0.0
var time := 0.0
var phase := "idle"          # idle | travel | fight | boss | wipe | town | victory
var phase_t := 0.0
var heroes: Array = []       # Combatant (heroes + summons)
var enemies: Array = []
var pending: Array = []      # scheduled hits/effects
var zone_idx := 0
var mode := "zone"           # zone | tower
var tower_floor := 1
var stage := 1
var wave := 0
var difficulty := 0
var boss_t := 0.0
var boss_unit: Combatant = null
var boss_fail_count := 0
var rng := RandomNumberGenerator.new()
var scroll := 0.0            # background scroll position (px)
var session := {"kills": 0, "xp": 0.0, "gold": 0}
var _rate_acc := {"xp": 0.0, "gold": 0.0, "kills": 0}
var _rate_t := 0.0
var quiet := false           # suppress cosmetic events (offline/tests)
var dmg_log: Dictionary = {}  # hero id -> damage dealt since reset
var dmg_log_t := 0.0


func _ready() -> void:
	rng.randomize()
	EventBus.party_changed.connect(_on_party_changed)
	EventBus.equipment_changed.connect(func(_h): refresh_hero_stats())
	EventBus.hero_leveled.connect(func(_h, _l): refresh_hero_stats())
	EventBus.pet_changed.connect(func(_p):
		if not heroes.is_empty():
			refresh_hero_stats()
			_add_pet())


func _process(delta: float) -> void:
	if not running:
		return
	acc += delta * speed
	var guard := 0
	while acc >= TICK and guard < 200:
		acc -= TICK
		tick(TICK)
		guard += 1


# ------------------------------------------------------------------ setup
func start() -> void:
	zone_idx = int(GameState.progress.get("zone", 0))
	difficulty = int(GameState.progress.get("difficulty", 0))
	stage = clamp(int(GameState.progress.get("stage", 1)), 1, stages_per_zone())
	build_party()
	enemies.clear()
	pending.clear()
	running = true
	_set_phase("travel")
	EventBus.zone_changed.emit(zone_id())
	EventBus.stage_changed.emit(stage)


func stop() -> void:
	running = false


func stages_per_zone() -> int:
	return int(DataDB.bal("stage.stages_per_zone", 10))


func waves_per_stage() -> int:
	return int(DataDB.bal("stage.waves_per_stage", 5))


func zone() -> Dictionary:
	return DataDB.zone(zone_idx)


func zone_id() -> String:
	return str(zone().get("id", ""))


func is_boss_stage() -> bool:
	return stage >= stages_per_zone()


func build_party() -> void:
	var keep_hp: Dictionary = {}
	for u in heroes:
		if u.etype == "hero":
			keep_hp[u.id] = [u.hp_frac(), u.alive, u.revive_t, u.ult_charge]
	heroes.clear()
	for i in GameState.PARTY_SIZE:
		var hid: String = GameState.party[i]
		if hid == "" or not GameState.heroes.has(hid):
			continue
		var u := _make_hero_unit(hid, i)
		if keep_hp.has(hid):
			var k: Array = keep_hp[hid]
			u.hp = u.max_hp * float(k[0])
			u.alive = bool(k[1])
			u.revive_t = float(k[2])
			u.ult_charge = float(k[3])
		heroes.append(u)
		if not quiet:
			EventBus.unit_spawned.emit(u)
	_add_pet()


## The active pet fights from behind the party. It cannot be targeted or damaged.
func _add_pet() -> void:
	for u in heroes.filter(func(x): return x.etype == "pet"):
		heroes.erase(u)
		if not quiet:
			EventBus.unit_died.emit(u)
	var pid: String = str(GameState.pets.get("active", ""))
	if pid == "" or GameState.pet_level(pid) <= 0:
		return
	var pd := GameState.pet_def(pid)
	var p := Combatant.new()
	p.side = Combatant.Side.HERO
	p.id = pid
	p.name = DataDB.tx(pd.get("name", {}))
	p.etype = "pet"
	var power := 0.0
	var n := 0
	var lv := 1
	for u in heroes:
		if u.etype == "hero":
			power += float(u.stats.get("power", 10))
			lv = max(lv, u.level)
			n += 1
	power = power / max(1, n)
	var pmods: Dictionary = GameState.account_mods()
	var pet_mult: float = (0.25 + 0.03 * GameState.pet_level(pid)) * (1.0 + float(pmods.get("pet_dmg", 0.0)) / 100.0)
	p.level = lv
	p.stats = {"power": power * pet_mult, "def": 0.0, "crit_chance": 10.0, "crit_dmg": 150.0, "aps": 0.8,
		"range": 200.0, "melee": false, "threat": -99.0}
	p.max_hp = 1.0
	p.hp = 1.0
	p.element = str(pd.get("element", "physical"))
	p.projectile = str(pd.get("projectile", "bolt_arcane"))
	var back_x: float = INF
	for u in heroes:
		back_x = min(back_x, u.home_x)
	p.home_x = (back_x if back_x < INF else HERO_X[0]) - 16.0
	p.x = p.home_x
	p.visual = {"kind": "summon", "id": "pet_" + pid, "sheet": "pet_" + pid}
	heroes.append(p)
	if not quiet:
		EventBus.unit_spawned.emit(p)


func _make_hero_unit(hid: String, slot: int) -> Combatant:
	var h: HeroState = GameState.heroes[hid]
	var u := Combatant.new()
	u.side = Combatant.Side.HERO
	u.id = hid
	u.name = h.display_name()
	u.etype = "hero"
	u.level = h.level
	u.slot = slot
	u.home_x = HERO_X[slot]
	u.x = u.home_x
	u.stats = GameState.hero_stats(hid)
	u.max_hp = float(u.stats.get("max_hp", 100))
	u.hp = u.max_hp
	var cd: Dictionary = h.class_def()
	u.element = cd.get("element", "physical")
	u.projectile = cd.get("projectile", "")
	u.cheat_death_left = int(u.stats.get("cheat_death", 0))
	u.visual = {"kind": "hero", "id": hid}
	for sid in h.equipped_skills:
		if sid != "" and h.skill_level(sid) > 0 and h.skill_available(sid):
			u.skills.append({"id": sid, "lvl": h.skill_level(sid), "cd": 1.0 + rng.randf() * 2.0, "def": DataDB.skill_def(sid)})
	var ult := h.ult_id()
	if ult != "" and h.skill_level(ult) > 0:
		u.ult_id = ult
		u.ult_lvl = h.skill_level(ult)
	return u


func refresh_hero_stats() -> void:
	GameState.invalidate_stats()
	for u in heroes:
		if u.etype != "hero":
			continue
		var frac: float = u.hp_frac()
		u.stats = GameState.hero_stats(u.id)
		u.max_hp = float(u.stats.get("max_hp", 100))
		u.hp = u.max_hp * frac
		var h: HeroState = GameState.heroes.get(u.id)
		if h:
			u.level = h.level
			var old_cd: Dictionary = {}
			for s in u.skills:
				old_cd[s["id"]] = s["cd"]
			u.skills.clear()
			for sid in h.equipped_skills:
				if sid != "" and h.skill_level(sid) > 0 and h.skill_available(sid):
					u.skills.append({"id": sid, "lvl": h.skill_level(sid), "cd": float(old_cd.get(sid, 1.0)), "def": DataDB.skill_def(sid)})
			var ult := h.ult_id()
			u.ult_id = ult if ult != "" and h.skill_level(ult) > 0 else ""
			u.ult_lvl = h.skill_level(ult) if ult != "" else 0


func _on_party_changed() -> void:
	if running:
		build_party()


# ------------------------------------------------------------------ zone control
func go_to_zone(idx: int, diff: int = -1) -> void:
	if diff >= 0:
		difficulty = diff
		GameState.progress["difficulty"] = diff
	zone_idx = clamp(idx, 0, DataDB.zones.size() - 1)
	stage = 1
	GameState.progress["zone"] = zone_idx
	GameState.progress["stage"] = 1
	GameState.invalidate_stats()
	_clear_enemies()
	_revive_all()
	refresh_hero_stats()
	boss_fail_count = 0
	_set_phase("travel")
	EventBus.zone_changed.emit(zone_id())
	EventBus.stage_changed.emit(stage)


func enter_town() -> void:
	_clear_enemies()
	_revive_all()
	_set_phase("town")


func leave_town() -> void:
	_set_phase("travel")


func challenge_boss() -> void:
	stage = stages_per_zone()
	wave = 0
	_clear_enemies()
	_set_phase("travel")
	EventBus.stage_changed.emit(stage)


func _clear_enemies() -> void:
	for e in enemies:
		e.alive = false
	enemies.clear()
	pending.clear()
	boss_unit = null


func _revive_all() -> void:
	var had_dead := false
	for u in heroes:
		if u.etype == "hero":
			if not u.alive:
				had_dead = true
			u.alive = true
			u.hp = u.max_hp
			u.statuses.clear()
			u.buffs.clear()
			u.revive_t = 0
	if not quiet:
		for u in heroes:
			if u.etype != "hero":
				EventBus.unit_died.emit(u)     # pets / summons leave with their views
	heroes = heroes.filter(func(u): return u.etype == "hero")
	if had_dead and not quiet:
		for u in heroes:
			EventBus.unit_revived.emit(u)
	_add_pet()


func _set_phase(p: String) -> void:
	phase = p
	phase_t = 0.0
	if not quiet:
		EventBus.phase_changed.emit(p)


# ------------------------------------------------------------------ main tick
func tick(dt: float) -> void:
	time += dt
	dmg_log_t += dt
	phase_t += dt
	_rate_t += dt
	if _rate_t >= 10.0:
		GameState.record_rate_sample(_rate_acc["xp"], _rate_acc["gold"], _rate_acc["kills"])
		_rate_acc = {"xp": 0.0, "gold": 0.0, "kills": 0}
		_rate_t = 0.0
	match phase:
		"travel":
			scroll += 40.0 * dt
			_update_heroes_idle(dt)
			if phase_t >= float(DataDB.bal("combat.travel_time", 2.2)):
				_next_wave()
		"fight", "boss":
			_update_combat(dt)
		"wipe":
			if phase_t >= float(DataDB.bal("combat.wipe_delay", 5)):
				_after_wipe()
		"town", "idle":
			_update_heroes_idle(dt)
		"victory":
			_update_heroes_idle(dt)
			if phase_t >= 2.5:
				_after_boss_victory()


func _update_heroes_idle(dt: float) -> void:
	for u in heroes:
		if not u.alive:
			u.revive_t -= dt
			if u.revive_t <= 0:
				_revive(u)
			continue
		u.hp = min(u.max_hp, u.hp + u.max_hp * 0.05 * dt + u.st("hp_regen") * dt)
		_tick_timers(u, dt)


# ------------------------------------------------------------------ waves
func _next_wave() -> void:
	if mode == "tower":
		_spawn_tower_floor()
		return
	if is_boss_stage():
		_spawn_boss()
		return
	wave += 1
	var z := zone()
	var lv := F.monster_level(z, stage, difficulty)
	var n := rng.randi_range(int(DataDB.bal("stage.wave_min", 3)), int(DataDB.bal("stage.wave_max", 5)))
	if stage <= 2 and zone_idx == 0:
		n = 2 + (stage - 1)
	var roster: Array = z.get("enemies", [])
	var elite_idx := -1
	if roster.size() > 0 and rng.randf() < float(DataDB.bal("stage.elite_chance", 0.2)) and wave % 2 == 0:
		elite_idx = rng.randi() % n
	for i in n:
		var eid: String = roster[rng.randi() % roster.size()] if roster.size() > 0 else "slime_green"
		var et := "elite" if i == elite_idx else "normal"
		_spawn_enemy(eid, lv, et, SPAWN_X + i * 18.0 + rng.randf() * 6.0)
	_set_phase("fight")
	if not quiet:
		EventBus.wave_spawned.emit(wave)


func _spawn_enemy(eid: String, lv: int, etype: String, x: float) -> Combatant:
	var d: Dictionary = DataDB.enemy_def(eid)
	var u := Combatant.new()
	u.side = Combatant.Side.ENEMY
	u.id = eid
	u.name = DataDB.tx(d.get("name", {}))
	u.etype = etype
	u.level = lv
	var es := F.enemy_stats(d, lv, etype, difficulty)
	u.stats = {"power": es["atk"], "attack": es["atk"], "def": es["def"], "crit_chance": 5.0, "crit_dmg": 150.0,
		"aps": float(d.get("aps", 1.0)) * (1.0 + 0.1 * difficulty), "range": float(d.get("range", 24)),
		"melee": float(d.get("range", 24)) < 60.0, "target": d.get("target", "front")}
	for e in es["res"]:
		u.stats[e + "_res"] = es["res"][e]
	u.max_hp = float(es["hp"])
	u.hp = u.max_hp
	u.x = x
	u.home_x = x
	u.element = d.get("element", "physical")
	u.projectile = d.get("projectile", "")
	u.tags = d.get("tags", [])
	u.mech = d.get("mech", [])
	u.visual = {"kind": "enemy", "id": eid, "def": d.get("visual", {}), "elite": etype == "elite", "boss": etype == "boss" or etype == "actboss"}
	u.atk_cd = rng.randf_range(0.2, 1.0)
	enemies.append(u)
	if not quiet:
		EventBus.unit_spawned.emit(u)
	return u


func _spawn_boss() -> void:
	wave = 1
	var z := zone()
	var lv := F.monster_level(z, stages_per_zone(), difficulty) + 1
	var bid: String = z.get("boss", "giant_slime")
	var bd: Dictionary = DataDB.enemy_def(bid)
	var et: String = bd.get("type", "boss")
	boss_unit = _spawn_enemy(bid, lv, et, SPAWN_X)
	boss_unit.mech_t = 6.0
	var roster: Array = z.get("enemies", [])
	for i in 2:
		if roster.size() > 0:
			_spawn_enemy(roster[rng.randi() % roster.size()], lv - 1, "normal", SPAWN_X + 30 + i * 16)
	boss_t = float(DataDB.bal("stage.boss_time", 60))
	_set_phase("boss")
	if not quiet:
		EventBus.boss_spawned.emit(boss_unit)


# ------------------------------------------------------------------ combat
func front_hero_x() -> float:
	var m := -INF
	for u in heroes:
		if u.alive and u.etype != "pet":
			m = max(m, u.x)
	return m if m > -INF else 100.0


func _update_combat(dt: float) -> void:
	if phase == "boss":
		boss_t -= dt
		if boss_t <= 0.0 and boss_unit != null and boss_unit.alive:
			_boss_timeout()
			return
	# heroes & summons
	for u in heroes.duplicate():
		if not u.alive:
			if u.etype == "hero":
				u.revive_t -= dt
				if u.revive_t <= 0:
					_revive(u)
			continue
		if u.lifetime > 0:
			u.lifetime -= dt
			if u.lifetime <= 0:
				u.alive = false
				heroes.erase(u)
				if not quiet:
					EventBus.unit_died.emit(u)
				continue
		_tick_unit(u, dt)
		if u.alive:
			_hero_act(u, dt)
	# enemies
	var fx := front_hero_x()
	var alive_sorted: Array = enemies.filter(func(e): return e.alive)
	alive_sorted.sort_custom(func(a, b): return a.x < b.x)
	var rank := 0
	for e in alive_sorted:
		_tick_unit(e, dt)
		if not e.alive:
			continue
		var stop_x: float = fx + max(float(e.stats.get("range", 24)), 20.0) + (rank * 13.0 if bool(e.stats.get("melee", true)) else 0.0)
		if e.x > stop_x and not e.is_stunned():
			var spd := float(DataDB.bal("combat.enemy_walk_speed", 34)) * (0.7 if e.has_status("chill") else 1.0)
			if e.etype == "boss" or e.etype == "actboss":
				spd *= 0.8
			e.x = max(stop_x, e.x - spd * dt)
			if e.anim != "run" and e.busy_t <= 0:
				e.set_anim("run")
		elif e.anim == "run":
			e.set_anim("idle")
		rank += 1
		_enemy_act(e, dt, fx)
	# pending hits
	_process_pending(dt)
	# remove dead enemies after death anim
	for e in enemies.duplicate():
		if not e.alive:
			e.dead_t += dt
			if e.dead_t > 0.8:
				enemies.erase(e)
	# all heroes dead -> wipe
	var any_alive := false
	for u in heroes:
		if u.alive and u.etype == "hero":
			any_alive = true
			break
	if not any_alive:
		_wipe()
		return
	# wave cleared?
	var enemies_alive := false
	for e in enemies:
		if e.alive:
			enemies_alive = true
			break
	if not enemies_alive and pending.filter(func(p): return p["tgt_side"] == Combatant.Side.ENEMY).is_empty():
		_wave_cleared()


func _tick_timers(u: Combatant, dt: float) -> void:
	u.anim_t += dt
	u.flash_t = max(0.0, u.flash_t - dt)
	for b in u.buffs:
		b["t"] = float(b["t"]) - dt
	u.buffs = u.buffs.filter(func(b): return float(b["t"]) > 0.0)
	if u.shield > 0:
		u.shield_t -= dt
		if u.shield_t <= 0:
			u.shield = 0
	for s in u.statuses.keys():
		u.statuses[s]["t"] = float(u.statuses[s]["t"]) - dt
		if float(u.statuses[s]["t"]) <= 0.0:
			u.statuses.erase(s)


func _tick_unit(u: Combatant, dt: float) -> void:
	_tick_timers(u, dt)
	# damage over time
	u.dot_t += dt
	if u.dot_t >= 1.0:
		u.dot_t -= 1.0
		for s in ["burn", "poison", "bleed"]:
			if u.has_status(s):
				var info: Dictionary = u.statuses[s]
				var pct: float = {"burn": 0.2, "poison": 0.12, "bleed": 0.15}[s]
				var bonus: float = float(info.get("bonus", 0.0))
				var dmg: float = float(info.get("power", 0.0)) * pct * float(info.get("stacks", 1)) * (1.0 + bonus / 100.0)
				var el: String = {"burn": "fire", "poison": "chaos", "bleed": "physical"}[s]
				var res: float = clamp(u.st(el + "_res"), -50.0, 75.0) / 100.0 if el != "physical" else 0.0
				_apply_damage(null, u, dmg * (1.0 - res), false, el, "dot")
				if not u.alive:
					return
	if u.is_hero_side():
		u.hp = min(u.max_hp, u.hp + u.st("hp_regen") * dt)
	if u.busy_t > 0:
		u.busy_t -= dt
	var cdr: float = clamp(u.st("cdr"), 0.0, 60.0) / 100.0
	for s in u.skills:
		s["cd"] = float(s["cd"]) - dt / max(0.4, 1.0 - cdr)
	u.atk_cd -= dt * (0.7 if u.has_status("chill") else 1.0)
	if u.is_hero_side() and u.ult_id != "":
		u.ult_charge = min(100.0, u.ult_charge + float(DataDB.bal("combat.ult_passive", 0.6)) * dt * (1.0 + u.st("ult_charge") / 100.0))


func _hero_act(u: Combatant, _dt: float) -> void:
	if u.is_stunned() or u.busy_t > 0:
		return
	var has_enemy := false
	for e in enemies:
		if e.alive:
			has_enemy = true
			break
	if not has_enemy:
		return
	# ultimate
	if u.ult_id != "" and u.ult_charge >= 100.0:
		var sdef := DataDB.skill_def(u.ult_id)
		if not _select_targets(u, sdef).is_empty():
			u.ult_charge = 0.0
			_cast_skill(u, sdef, u.ult_lvl, true)
			return
	# skills
	for s in u.skills:
		if float(s["cd"]) <= 0.0:
			var tg := _select_targets(u, s["def"])
			if tg.is_empty():
				continue
			s["cd"] = float(s["def"].get("cd", 8.0))
			_cast_skill(u, s["def"], int(s["lvl"]), false)
			return
	# basic attack
	if u.atk_cd <= 0.0:
		var t := _basic_target(u)
		if t != null:
			_basic_attack(u, t)


func _basic_target(u: Combatant) -> Combatant:
	var best: Combatant = null
	var fx := front_hero_x()
	var melee: bool = bool(u.stats.get("melee", true))
	var rng_: float = float(u.stats.get("range", 26))
	for e in enemies:
		if not e.alive:
			continue
		var dist: float = (e.x - fx) if melee else (e.x - u.x)
		var ok: bool = dist <= rng_ + 8.0 or (not melee and u.is_hero_side() and e.x <= VISIBLE_X)
		if ok:
			if best == null or e.x < best.x:
				best = e
	return best


func _basic_attack(u: Combatant, t: Combatant) -> void:
	var aps: float = max(0.2, float(u.stats.get("aps", 1.0)))
	for b in u.buffs:
		if b["stat"] == "attack_speed":
			aps *= 1.0 + float(b["v"]) / 100.0
	var interval: float = 1.0 / aps
	u.atk_cd = interval
	var impact: float = min(0.25, interval * 0.5)
	u.busy_t = min(0.5, interval * 0.8)
	u.set_anim("attack")
	u.act_impact = impact
	u.act_len = max(u.busy_t, impact + 0.15)
	if not quiet:
		EventBus.attack_started.emit(u, "attack")
	var mult := 1.0
	if u.etype == "hero" and bool(u.stats.get("melee", true)) and u.slot >= 2:
		mult *= 1.0 - float(DataDB.bal("combat.melee_offslot_penalty", 0.3))
	if u.projectile != "" or not bool(u.stats.get("melee", true)):
		var travel: float = abs(t.x - u.x) / float(DataDB.bal("combat.projectile_speed", 260))
		_schedule({"t": impact + travel, "src": u, "tgt": t, "mult": mult, "element": u.element, "skill": false, "fire_t": impact,
			"projectile": u.projectile if u.projectile != "" else "arrow_enemy", "travel": travel})
	else:
		_schedule({"t": impact, "src": u, "tgt": t, "mult": mult, "element": u.element, "skill": false})
	u.last_target = t.uid


func _enemy_act(e: Combatant, dt: float, fx: float) -> void:
	if e.is_stunned():
		return
	# boss mechanics
	if (e.etype == "boss" or e.etype == "actboss") and e.mech.size() > 0:
		if not e.telegraph.is_empty():
			e.telegraph["t"] = float(e.telegraph["t"]) - dt
			if float(e.telegraph["t"]) <= 0.0:
				_boss_mech(e, str(e.telegraph["mech"]))
				e.telegraph = {}
				e.busy_t = 0.6
			return
		e.mech_t -= dt
		if e.mech_t <= 0.0 and e.busy_t <= 0:
			var m: String = e.mech[rng.randi() % e.mech.size()]
			if m == "enrage":
				m = e.mech[0]
			e.telegraph = {"mech": m, "t": 1.5}
			e.mech_t = rng.randf_range(9.0, 13.0)
			e.set_anim("skill")
			e.act_impact = 1.5
			e.act_len = 1.8
			if not quiet:
				EventBus.vfx_requested.emit("telegraph", Vector2(e.x, GROUND_Y), {"t": 1.5, "mech": m, "uid": e.uid})
			return
		if e.mech.has("enrage") and e.hp_frac() < 0.5 and not e.stats.get("enraged", false):
			e.stats["enraged"] = true
			e.stats["aps"] = float(e.stats["aps"]) * 1.5
			if not quiet:
				EventBus.notify.emit(DataDB.t("boss_enraged", {"name": e.name}), Color("#FF5A3A"))
	if e.busy_t > 0 or e.atk_cd > 0:
		return
	var range_: float = float(e.stats.get("range", 24))
	var melee: bool = bool(e.stats.get("melee", true))
	var dist: float = e.x - fx
	if dist > range_ + (40.0 if melee else 6.0):
		return
	var t := _enemy_target(e)
	if t == null:
		return
	var aps: float = max(0.2, float(e.stats.get("aps", 1.0)))
	e.atk_cd = 1.0 / aps
	e.busy_t = min(0.5, e.atk_cd * 0.7)
	e.set_anim("attack")
	e.act_impact = 0.3
	e.act_len = max(e.busy_t, 0.45)
	e.last_target = t.uid
	if not quiet:
		EventBus.attack_started.emit(e, "attack")
	var mult := 1.0
	if e.has_status("weaken"):
		mult *= 0.8
	if melee:
		_schedule({"t": 0.3, "src": e, "tgt": t, "mult": mult, "element": e.element, "skill": false})
	else:
		var travel: float = abs(e.x - t.x) / 220.0
		_schedule({"t": 0.3 + travel, "src": e, "tgt": t, "mult": mult, "element": e.element, "skill": false, "fire_t": 0.3,
			"projectile": e.projectile if e.projectile != "" else "bolt_enemy", "travel": travel})


func _enemy_target(e: Combatant) -> Combatant:
	var alive: Array = heroes.filter(func(u): return u.alive and u.etype != "pet")
	if alive.is_empty():
		return null
	var mode: String = e.stats.get("target", "front")
	match mode:
		"lowest":
			alive.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
			return alive[0]
		"random":
			return alive[rng.randi() % alive.size()]
		"back":
			alive.sort_custom(func(a, b): return a.x < b.x)
			return alive[0]
	var best: Combatant = null
	var best_score := -INF
	for u in alive:
		var score: float = u.x + u.st("threat") * 18.0 + rng.randf() * 4.0
		if score > best_score:
			best_score = score
			best = u
	return best


# ------------------------------------------------------------------ skills
func _select_targets(u: Combatant, sdef: Dictionary) -> Array:
	var mode: String = sdef.get("target", "enemy_front")
	var maxn: int = int(sdef.get("max_targets", 1))
	var foes: Array = (enemies if u.is_hero_side() else heroes).filter(func(e): return e.alive and e.etype != "pet")
	var allies: Array = (heroes if u.is_hero_side() else enemies).filter(func(e): return e.alive and e.etype != "pet")
	var reach: float = float(u.stats.get("range", 26)) + 30.0
	var fx := front_hero_x()
	var ranged_hero: bool = u.is_hero_side() and not bool(u.stats.get("melee", true))
	var in_range: Array = foes.filter(func(e): return (e.x - (fx if bool(u.stats.get("melee", true)) else u.x)) <= reach + 40.0 or (ranged_hero and e.x <= VISIBLE_X))
	match mode:
		"enemy_front":
			in_range.sort_custom(func(a, b): return a.x < b.x)
			return in_range.slice(0, maxn)
		"enemy_back":
			foes.sort_custom(func(a, b): return a.x > b.x)
			return foes.slice(0, 1)
		"enemy_lowest":
			foes.sort_custom(func(a, b): return a.hp < b.hp)
			return foes.slice(0, 1)
		"enemy_random":
			var pool := foes.duplicate()
			pool.shuffle()
			return pool.slice(0, maxn)
		"enemy_all":
			return foes
		"enemy_aoe":
			if in_range.is_empty():
				return []
			in_range.sort_custom(func(a, b): return a.x < b.x)
			var c: Combatant = in_range[0]
			var r: float = float(sdef.get("radius", 30))
			return foes.filter(func(e): return abs(e.x - c.x) <= r)
		"ally_lowest":
			if in_range.is_empty() and foes.size() == 0:
				return []
			allies.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
			if allies.size() > 0 and allies[0].hp_frac() > 0.92:
				return []
			return allies.slice(0, 1)
		"ally_all":
			return allies
		"ally_front":
			allies.sort_custom(func(a, b): return a.x > b.x)
			return allies.slice(0, 1)
		"self":
			return [u]
	return []


func _cast_skill(u: Combatant, sdef: Dictionary, lvl: int, is_ult: bool) -> void:
	var targets := _select_targets(u, sdef)
	if targets.is_empty():
		return
	u.busy_t = 0.6
	u.set_anim("skill")
	u.act_impact = 0.3
	u.act_len = 0.6
	if targets[0].side != u.side:
		u.last_target = targets[0].uid
	if not quiet:
		EventBus.skill_cast.emit(u, str(sdef.get("id", "")))
		EventBus.attack_started.emit(u, "skill")
		var c: Combatant = targets[0]
		EventBus.vfx_requested.emit(str(sdef.get("vfx", "hit")), Vector2(c.x, GROUND_Y), {"src": u.uid, "tgt": c.uid, "ult": is_ult,
			"targets": targets.map(func(t): return t.uid)})
	var buff_mult: float = 1.0 + u.st("buff_duration") / 100.0
	for eff in sdef.get("effects", []):
		var et: String = eff.get("type", "")
		match et:
			"damage":
				var mult := StatCalc.param(sdef, eff.get("mult", 1.0), lvl)
				var hits := int(StatCalc.param(sdef, eff.get("hits", 1), lvl))
				var el: String = eff.get("element", u.element if u.element != "" else "physical")
				if is_ult:
					mult *= 1.0 + u.st("ult_dmg") / 100.0
				for t in targets:
					for k in hits:
						_schedule({"t": 0.3 + k * 0.1, "src": u, "tgt": t, "mult": mult, "element": el, "skill": true,
							"aoe": targets.size() > 1, "party_heal": float(eff.get("party_heal", 0.0))})
			"heal":
				var hm := StatCalc.param(sdef, eff.get("mult", 1.0), lvl)
				for t in targets:
					_heal(u, t, float(u.stats.get("power", 10)) * hm * (1.0 + u.st("heal_bonus") / 100.0))
			"heal_pct":
				var hp_ := StatCalc.param(sdef, eff.get("value", 0.2), lvl)
				for t in targets:
					_heal(u, t, t.max_hp * hp_ * (1.0 + u.st("heal_bonus") / 200.0))
			"shield":
				var amt: float
				if eff.has("mult"):
					amt = float(u.stats.get("power", 10)) * StatCalc.param(sdef, eff["mult"], lvl)
				else:
					amt = 0.0
				for t in targets:
					var a2: float = amt if amt > 0 else t.max_hp * StatCalc.param(sdef, eff.get("pct", 0.1), lvl)
					if a2 > t.shield:
						t.shield = a2
					t.shield_t = float(DataDB.bal("combat.shield_duration", 6)) * buff_mult
			"buff":
				var v := StatCalc.param(sdef, eff.get("value", 0), lvl)
				var dur := StatCalc.param(sdef, eff.get("dur", 5), lvl) * buff_mult
				for t in targets:
					t.buffs.append({"stat": str(eff.get("stat", "")), "v": v, "t": dur})
			"status":
				var chance: float = float(eff.get("chance", 1.0))
				var dur2 := StatCalc.param(sdef, eff.get("dur", 2), lvl)
				var stacks := int(StatCalc.param(sdef, eff.get("stacks", 1), lvl))
				for t in targets:
					if rng.randf() <= chance * (1.0 + u.st("status_chance") / 100.0):
						_apply_status(u, t, str(eff.get("status", "stun")), dur2, stacks)
			"summon":
				var cnt := int(StatCalc.param(sdef, eff.get("count", 1), lvl))
				var pct := StatCalc.param(sdef, eff.get("pct", 0.3), lvl)
				var dur3 := StatCalc.param(sdef, eff.get("dur", 15), lvl)
				_summon(u, str(eff.get("kind", "skeleton")), cnt, pct, dur3)


func _apply_status(src: Combatant, t: Combatant, s: String, dur: float, stacks: int) -> void:
	if t.etype == "boss" or t.etype == "actboss":
		if s == "stun" or s == "freeze":
			dur *= 0.5
	var info: Dictionary = t.statuses.get(s, {"t": 0.0, "stacks": 0})
	var max_stacks: int = {"burn": 3, "poison": 20, "bleed": 5, "chill": 5}.get(s, 1)
	info["stacks"] = min(max_stacks, int(info.get("stacks", 0)) + stacks)
	info["t"] = max(float(info.get("t", 0.0)), dur)
	if src != null:
		info["power"] = float(src.stats.get("power", 10))
		info["bonus"] = src.st(s + "_dmg") + src.st("chaos_dmg" if s == "poison" else ("fire_dmg" if s == "burn" else "phys_dmg")) * 0.5
	t.statuses[s] = info
	if s == "chill" and int(info["stacks"]) >= 5:
		t.statuses.erase("chill")
		t.statuses["freeze"] = {"t": 1.0, "stacks": 1}


func _summon(owner: Combatant, kind: String, count: int, pct: float, dur: float) -> void:
	var existing: Array = heroes.filter(func(x): return x.etype == "summon" and x.owner_uid == owner.uid and x.alive)
	var limit: int = 3 + int(owner.st("max_summons"))
	if kind == "golem" or kind == "wolf":
		limit = 1 + int(owner.st("max_summons")) / 2
	for e in existing:
		if e.id == kind:
			e.lifetime = dur
	var have: int = existing.filter(func(x): return x.id == kind).size()
	for i in range(have, min(limit, have + count)):
		var s := Combatant.new()
		s.side = Combatant.Side.HERO
		s.id = kind
		s.etype = "summon"
		s.owner_uid = owner.uid
		s.level = owner.level
		var dmg_mult: float = 1.0 + owner.st("summon_dmg") / 100.0
		var hp_mult: float = 1.0 + owner.st("summon_hp") / 100.0
		s.stats = {"power": float(owner.stats.get("power", 10)) * pct * dmg_mult, "def": float(owner.stats.get("def", 5)),
			"crit_chance": 5.0, "crit_dmg": 150.0, "aps": 1.0 if kind != "golem" else 0.7, "range": 22.0, "melee": true,
			"threat": 3.0 if kind == "golem" else 1.0}
		s.max_hp = owner.max_hp * (0.35 if kind != "golem" else 1.2) * hp_mult
		s.hp = s.max_hp
		s.home_x = front_hero_x() + 12.0 + i * 9.0
		s.x = s.home_x
		s.lifetime = dur
		s.visual = {"kind": "summon", "id": kind}
		heroes.append(s)
		if not quiet:
			EventBus.unit_spawned.emit(s)


func _boss_mech(e: Combatant, m: String) -> void:
	var alive: Array = heroes.filter(func(u): return u.alive and u.etype != "pet")
	if alive.is_empty():
		return
	var atk: float = float(e.stats.get("power", 10))
	match m:
		"slam", "gold_rain", "apocalypse", "dark_combo":
			for u in alive:
				_hit_now(e, u, 1.6 if m != "apocalypse" else 2.2, e.element)
		"blizzard", "freeze":
			for u in alive:
				_hit_now(e, u, 1.1, "cold")
				_apply_status(e, u, "chill", 4.0, 3)
		"storm", "element_shift":
			var pool := alive.duplicate()
			pool.shuffle()
			for u in pool.slice(0, 3):
				_hit_now(e, u, 1.7, "lightning" if m == "storm" else ["fire", "cold", "lightning"][rng.randi() % 3])
		"meteor", "bombard":
			var pool2 := alive.duplicate()
			pool2.sort_custom(func(a, b): return a.x < b.x)
			_hit_now(e, pool2[0], 2.6, "fire")
		"poison_cloud", "curse":
			for u in alive:
				if m == "poison_cloud":
					_apply_status(e, u, "poison", 6.0, 3)
				else:
					_apply_status(e, u, "weaken", 6.0, 1)
		"charge", "void_prison", "roots":
			var tgt := _enemy_target(e)
			if tgt:
				_hit_now(e, tgt, 2.4, e.element)
				_apply_status(e, tgt, "stun", 1.5, 1)
		"drain":
			var tgt2 := _enemy_target(e)
			if tgt2:
				_hit_now(e, tgt2, 2.0, "chaos")
				e.hp = min(e.max_hp, e.hp + e.max_hp * 0.06)
		"ice_wall", "clones", "split":
			e.shield = e.max_hp * 0.12
			e.shield_t = 6.0
		"summon_goblins", "summon_spiders", "summon_undead", "summon_bats":
			var roster: Array = zone().get("enemies", [])
			for i in 2:
				if roster.size() > 0:
					_spawn_enemy(roster[rng.randi() % roster.size()], e.level - 1, "normal", SPAWN_X + i * 16)
		"slow":
			for u in alive:
				_apply_status(e, u, "chill", 5.0, 2)
		_:
			for u in alive:
				_hit_now(e, u, 1.4, e.element)
	if not quiet:
		EventBus.vfx_requested.emit("boss_" + m, Vector2(e.x, GROUND_Y), {"uid": e.uid})


func _hit_now(src: Combatant, tgt: Combatant, mult: float, element: String) -> void:
	var r := calc_damage(src, tgt, mult, element, true, false)
	if r["miss"]:
		if not quiet:
			EventBus.damage_dealt.emit(src, tgt, 0.0, false, element, "miss")
		return
	_apply_damage(src, tgt, float(r["amount"]), bool(r["crit"]), element, "block" if r["blocked"] else "skill")


func _heal(src: Combatant, t: Combatant, amount: float) -> void:
	if not t.alive:
		return
	var before := t.hp
	t.hp = min(t.max_hp, t.hp + amount)
	var real := t.hp - before
	if real > 0.5 and not quiet:
		EventBus.healed.emit(t, real)


# ------------------------------------------------------------------ hits & damage
func _schedule(p: Dictionary) -> void:
	p["tgt_side"] = (p["tgt"] as Combatant).side
	pending.append(p)
	if p.has("projectile") and not quiet:
		var delay: float = float(p.get("fire_t", 0.0))
		pending.append({"t": delay, "fx_only": true, "src": p["src"], "tgt": p["tgt"], "projectile": p["projectile"],
			"travel": p.get("travel", 0.3), "tgt_side": -1})


func _process_pending(dt: float) -> void:
	var due: Array = []
	for p in pending:
		p["t"] = float(p["t"]) - dt
		if float(p["t"]) <= 0.0:
			due.append(p)
	for p in due:
		pending.erase(p)
		if p.get("fx_only", false):
			var s: Combatant = p["src"]
			var tg: Combatant = p["tgt"]
			if s.alive:
				EventBus.projectile_fired.emit(s, tg, str(p["projectile"]), float(p["travel"]))
			continue
		var src: Combatant = p["src"]
		var tgt: Combatant = p["tgt"]
		if not tgt.alive:
			continue
		var r := calc_damage(src, tgt, float(p["mult"]), str(p["element"]), bool(p.get("skill", false)), false, bool(p.get("aoe", false)))
		if r["miss"]:
			if not quiet:
				EventBus.damage_dealt.emit(src, tgt, 0.0, false, str(p["element"]), "miss")
			continue
		var kind := "block" if r["blocked"] else ("skill" if p.get("skill", false) else "hit")
		_apply_damage(src, tgt, float(r["amount"]), bool(r["crit"]), str(p["element"]), kind)
		if float(p.get("party_heal", 0.0)) > 0.0 and src.alive:
			for u in heroes:
				if u.alive:
					_heal(src, u, float(r["amount"]) * float(p["party_heal"]) / max(1, heroes.size()))
		# on-hit procs (hero side)
		if src.is_hero_side() and tgt.alive:
			if rng.randf() * 100.0 < src.st("bleed_chance"):
				_apply_status(src, tgt, "bleed", 4.0, 1)
			if rng.randf() * 100.0 < src.st("stun_chance"):
				_apply_status(src, tgt, "stun", 0.8, 1)
			if rng.randf() * 100.0 < src.st("weaken_chance"):
				_apply_status(src, tgt, "weaken", 4.0, 1)
			if str(p["element"]) == "cold" and rng.randf() < 0.3:
				_apply_status(src, tgt, "chill", 2.0, 1)
			if str(p["element"]) == "fire" and rng.randf() < 0.15:
				_apply_status(src, tgt, "burn", 3.0, 1)


func calc_damage(src: Combatant, tgt: Combatant, mult: float, element: String, is_skill: bool, is_dot := false, is_aoe := false) -> Dictionary:
	var out := {"amount": 0.0, "crit": false, "miss": false, "blocked": false}
	if tgt.st("invuln") > 0.0:
		out["miss"] = true
		return out
	if not is_dot and tgt.is_hero_side() and rng.randf() * 100.0 < min(50.0, tgt.st("evasion")):
		out["miss"] = true
		return out
	var power: float = float(src.stats.get("power", 10)) if src != null else 10.0
	var raw := power * mult
	var inc := 0.0
	if src != null and src.is_hero_side():
		inc += src.st("added_dmg")
		if element == "physical":
			inc += src.st("phys_dmg")
		else:
			inc += src.st(element + "_dmg") + (src.st("elem_dmg") if element != "holy" else 0.0)
		if is_skill:
			inc += src.st("skill_dmg")
		if is_aoe:
			inc += src.st("aoe_dmg")
		if tgt.etype == "elite":
			inc += src.st("elite_dmg")
		if tgt.etype == "boss" or tgt.etype == "actboss":
			inc += src.st("boss_dmg") + src.st("elite_dmg") * 0.5
		if tgt.tags.has("undead"):
			inc += src.st("undead_dmg")
		if TimeService.is_night():
			inc += src.st("night_dmg")
		if tgt.hp_frac() < 0.3:
			inc += src.st("execute_dmg")
		if src.st("rage_dmg") > 0:
			inc += src.st("rage_dmg") * (1.0 - src.hp_frac()) * 10.0
	raw *= max(0.1, 1.0 + inc / 100.0)
	if src != null and src.has_status("weaken"):
		raw *= 0.8
	if tgt.has_status("vulnerable"):
		raw *= 1.2
	if tgt.has_status("shock"):
		raw *= 1.15
	if src != null and not is_dot and rng.randf() * 100.0 < src.st("crit_chance", 5.0):
		out["crit"] = true
		raw *= max(1.0, src.st("crit_dmg", 150.0) / 100.0 * (1.0 - tgt.st("crit_res") / 100.0))
	if element == "physical":
		var eff_def: float = float(tgt.stats.get("def", 0)) * (1.0 - (src.st("penetrate") if src != null else 0.0) / 100.0)
		var lv: float = float(src.level if src != null else 1)
		var dr: float = min(0.75, eff_def / (eff_def + float(DataDB.bal("combat.def_k_base", 50)) + float(DataDB.bal("combat.def_k_per_level", 6)) * lv))
		raw *= 1.0 - dr
	else:
		var res: float = clamp(tgt.st(element + "_res"), -50.0, 75.0) if element != "holy" else 0.0
		if element == "holy" and tgt.tags.has("undead"):
			raw *= 1.5
		raw *= 1.0 - res / 100.0
	raw *= 1.0 - clamp(tgt.st("dr"), 0.0, 75.0) / 100.0
	if not is_dot and rng.randf() * 100.0 < min(50.0, tgt.st("block")):
		raw *= 1.0 - float(DataDB.bal("combat.block_reduction", 0.6))
		out["blocked"] = true
	var v: float = float(DataDB.bal("combat.dmg_variance", 0.05))
	raw *= rng.randf_range(1.0 - v, 1.0 + v)
	out["amount"] = max(1.0, round(raw))
	return out


func _apply_damage(src: Combatant, tgt: Combatant, amount: float, crit: bool, element: String, kind: String) -> void:
	if not tgt.alive or tgt.etype == "pet":
		return
	var dmg := amount
	if tgt.shield > 0:
		var absorbed: float = min(tgt.shield, dmg)
		tgt.shield -= absorbed
		dmg -= absorbed
	tgt.hp -= dmg
	tgt.flash_t = 0.09
	if tgt.anim != "attack" and tgt.anim != "skill" and tgt.busy_t <= 0:
		tgt.set_anim("hit")
	if src != null and src.alive:
		var ls: float = src.st("lifesteal")
		if ls > 0:
			src.hp = min(src.max_hp, src.hp + amount * ls / 100.0)
		if src.is_hero_side() and src.ult_id != "":
			src.ult_charge = min(100.0, src.ult_charge + float(DataDB.bal("combat.ult_per_dealt", 0.012)) * 100.0 * (1.0 + src.st("ult_charge") / 100.0) * (0.3 if kind == "dot" else 1.0))
		if tgt.is_hero_side() and tgt.st("thorns") > 0 and bool(src.stats.get("melee", true)) and kind != "dot":
			var refl: float = amount * tgt.st("thorns") / 100.0
			src.hp -= refl
			if src.hp <= 0 and src.alive:
				_die(src, tgt)
	if tgt.is_hero_side() and tgt.ult_id != "":
		tgt.ult_charge = min(100.0, tgt.ult_charge + float(DataDB.bal("combat.ult_per_taken", 0.04)) * amount / max(1.0, tgt.max_hp) * 100.0)
	if src != null and src.is_hero_side():
		var key: String = src.id if src.etype == "hero" else "summon"
		dmg_log[key] = float(dmg_log.get(key, 0.0)) + amount
	if not quiet:
		EventBus.damage_dealt.emit(src, tgt, amount, crit, element, kind)
	if tgt.hp <= 0.0:
		if tgt.cheat_death_left > 0:
			tgt.cheat_death_left -= 1
			tgt.hp = tgt.max_hp * 0.3
			tgt.buffs.append({"stat": "invuln", "v": 1.0, "t": 2.0})
			return
		_die(tgt, src)


func _die(u: Combatant, killer: Combatant) -> void:
	if not u.alive:
		return
	u.alive = false
	u.hp = 0.0
	u.set_anim("death")
	u.statuses.clear()
	if u.is_hero_side():
		if u.etype == "hero":
			var rs: float = u.st("revive_speed")
			u.revive_t = float(DataDB.bal("combat.revive_time", 15)) * max(0.2, 1.0 - rs / 100.0)
			GameState.totals["deaths"] = int(GameState.totals.get("deaths", 0)) + 1
		if not quiet:
			EventBus.unit_died.emit(u)
		return
	_on_enemy_killed(u)
	if not quiet:
		EventBus.unit_died.emit(u)


func _on_enemy_killed(e: Combatant) -> void:
	session["kills"] = int(session["kills"]) + 1
	_rate_acc["kills"] = int(_rate_acc["kills"]) + 1
	GameState.totals["kills"] = int(GameState.totals.get("kills", 0)) + 1
	GameState.codex["enemies"][e.id] = int(GameState.codex["enemies"].get(e.id, 0)) + 1
	var xp := F.xp_per_kill(e.level, e.etype)
	GameState.grant_kill_xp(e.level, e.etype)
	session["xp"] = float(session["xp"]) + xp
	_rate_acc["xp"] = float(_rate_acc["xp"]) + xp
	var gf := 0.0
	var iff := 0.0
	var lf := 0.0
	var ph := GameState.party_heroes()
	for h in ph:
		var s := GameState.hero_stats(h.id)
		gf += float(s.get("gold_find", 0.0))
		iff += float(s.get("item_find", 0.0))
		lf += float(s.get("legendary_find", 0.0))
	var n: float = max(1, ph.size())
	var g := int(F.gold_per_kill(e.level, e.etype) * (1.0 + gf / n / 100.0))
	GameState.add_gold(g)
	session["gold"] = int(session["gold"]) + g
	_rate_acc["gold"] = float(_rate_acc["gold"]) + g
	var drops := LootSystem.roll_drops(GameState.rng, e.level, e.etype, iff / n, difficulty, GameState.party_classes(), lf / n)
	for it in drops["items"]:
		var res := GameState.receive_item(it)
		if not quiet:
			EventBus.item_dropped.emit(it, Vector2(e.x, GROUND_Y))
		if res == "equipped" and not quiet:
			var gain := GameState.last_equip_gain
			EventBus.notify.emit(DataDB.t("auto_equipped", {"name": ItemUtil.display_name(it)}) + ("  ▲%d%%" % gain if gain > 0 else ""),
				ItemUtil.rarity_color(it["rarity"]))
	for m in drops["materials"]:
		GameState.add_material(m, int(drops["materials"][m]))
	var ck := Chests.roll(GameState.rng, e.etype, iff / n)
	if ck != "":
		Chests.add(ck, e.level)
		if not quiet:
			EventBus.chest_dropped.emit(ck, Vector2(e.x, GROUND_Y))
	if mode == "tower":
		var left := 0
		for o in enemies:
			if o.alive:
				left += 1
		if left == 0:
			_tower_cleared()
		return
	if e == boss_unit:
		_boss_killed()


func _revive(u: Combatant) -> void:
	u.alive = true
	u.hp = u.max_hp * 0.5
	u.set_anim("idle")
	u.revive_t = 0.0
	if not quiet:
		EventBus.unit_revived.emit(u)


# ------------------------------------------------------------------ flow
func _wave_cleared() -> void:
	if phase == "boss":
		return
	for u in heroes:
		if u.alive:
			u.set_anim("idle")
	if wave >= waves_per_stage():
		_stage_cleared()
	else:
		_set_phase("travel")


func _stage_cleared() -> void:
	wave = 0
	var auto: bool = bool(GameState.progress.get("auto", true))
	if stage < stages_per_zone() - 1:
		stage += 1
	elif stage == stages_per_zone() - 1:
		# boss gate: auto mode tries the boss, retrying after failures every 2 clears
		if auto and (boss_fail_count == 0 or rng.randf() < 0.5):
			stage = stages_per_zone()
	GameState.progress["stage"] = stage
	GameState.progress["max_stage"] = max(int(GameState.progress.get("max_stage", 1)), stage)
	EventBus.stage_changed.emit(stage)
	_set_phase("travel")


func _boss_killed() -> void:
	var zid := zone_id()
	var key := "%d_%s" % [difficulty, zid]
	var first: bool = not GameState.progress["cleared"].has(key)
	GameState.progress["cleared"][key] = true
	GameState.totals["bosses"] = int(GameState.totals.get("bosses", 0)) + 1
	boss_fail_count = 0
	var maxz: Array = GameState.progress["max_zone"]
	if zone_idx + 1 < DataDB.zones.size():
		if zone_idx + 1 > int(maxz[difficulty]):
			maxz[difficulty] = zone_idx + 1
			EventBus.zone_unlocked.emit(DataDB.zone(zone_idx + 1)["id"])
	elif difficulty < 2 and int(maxz[difficulty + 1]) < 0:
		maxz[difficulty + 1] = 0
		EventBus.notify.emit(DataDB.t("difficulty_unlocked", {"name": DataDB.tx(DataDB.difficulties[difficulty + 1]["name"])}), Color("#FF8A1F"))
	if first:
		_first_clear_rewards()
	var btype: String = str(DataDB.enemy_def(str(zone().get("boss", ""))).get("type", "boss"))
	var drop: Dictionary = DataDB.pets.get("drop", {})
	var chance: float = float(drop.get("actboss" if btype == "actboss" else "boss", 0.04))
	if first:
		chance = max(chance, float(drop.get("first_clear", 0.25)))
	_roll_pet(int(zone().get("act", 1)), chance)
	EventBus.boss_defeated.emit(zid)
	if first and difficulty == 0 and zone_idx == DataDB.zones.size() - 1:
		GameState.flags["story_done"] = true
		if not quiet:
			EventBus.story_completed.emit()
	boss_unit = null
	_set_phase("victory")
	for u in heroes:
		if u.alive:
			u.set_anim("victory")


func _first_clear_rewards() -> void:
	# Act bosses grant skill points; story legendaries for the first act boss
	var z := zone()
	if z.get("boss", "") == "goblin_king" and difficulty == 0:
		var it := LootSystem.generate(GameState.rng, 12, "legendary", "", {"cat": "armor", "btype": "helm", "slot": "helm", "weight": "medium"})
		it["leg"] = "leg_goblin_crown"
		GameState.receive_item(it)
	var bd := DataDB.enemy_def(str(z.get("boss", "")))
	if bd.get("type", "") == "actboss":
		for h in GameState.heroes.values():
			h.skill_points += 2
		GameState.add_material("guild_badge", 3)


func _after_boss_victory() -> void:
	var auto: bool = bool(GameState.progress.get("auto", true))
	var maxz: int = int(GameState.progress["max_zone"][difficulty])
	if auto and zone_idx + 1 <= maxz and zone_idx + 1 < DataDB.zones.size():
		go_to_zone(zone_idx + 1)
	elif auto and zone_idx + 1 >= DataDB.zones.size() and difficulty < 2 and int(GameState.progress["max_zone"][difficulty + 1]) >= 0:
		go_to_zone(0, difficulty + 1)
	else:
		stage = stages_per_zone() - 1
		GameState.progress["stage"] = stage
		EventBus.stage_changed.emit(stage)
		_set_phase("travel")


func _boss_timeout() -> void:
	if mode == "tower":
		_tower_failed()
		return
	boss_fail_count += 1
	EventBus.boss_failed.emit(zone_id())
	EventBus.notify.emit(DataDB.t("boss_failed"), Color("#FF6A5A"))
	_clear_enemies()
	stage = stages_per_zone() - 1
	GameState.progress["stage"] = stage
	EventBus.stage_changed.emit(stage)
	_set_phase("travel")


func _wipe() -> void:
	_set_phase("wipe")
	_clear_enemies()
	if not quiet:
		EventBus.party_wiped.emit()


func _after_wipe() -> void:
	_revive_all()
	if mode == "tower":
		_tower_failed()
		return
	if is_boss_stage():
		boss_fail_count += 1
	stage = max(1, stage - 2)
	wave = 0
	GameState.progress["stage"] = stage
	EventBus.stage_changed.emit(stage)
	_set_phase("travel")


# ------------------------------------------------------------------ endless tower
func tower_unlocked() -> bool:
	return GameState.max_hero_level() >= 50 or int(GameState.progress["max_zone"][1]) >= 0


func enter_tower() -> void:
	mode = "tower"
	tower_floor = int(GameState.progress.get("tower_best", 0)) + 1
	_clear_enemies()
	_revive_all()
	refresh_hero_stats()
	_set_phase("travel")
	EventBus.zone_changed.emit("tower")
	EventBus.stage_changed.emit(tower_floor)


func leave_tower() -> void:
	mode = "zone"
	go_to_zone(zone_idx, difficulty)


func tower_level(fl: int) -> int:
	return 50 + int(fl * 0.8)


func _spawn_tower_floor() -> void:
	var lv := tower_level(tower_floor)
	var zi := (tower_floor * 7) % DataDB.zones.size()
	var z := DataDB.zone(zi)
	var roster: Array = z.get("enemies", ["slime_green"])
	if tower_floor % 10 == 0:
		boss_unit = _spawn_enemy(str(z.get("boss", "giant_slime")), lv, "boss", SPAWN_X)
		boss_unit.mech_t = 6.0
	else:
		boss_unit = null
		for i in 3:
			var u := _spawn_enemy(roster[rng.randi() % roster.size()], lv, "elite", SPAWN_X + i * 18.0)
			if boss_unit == null:
				boss_unit = u
	boss_t = 60.0
	_set_phase("boss")


func _tower_cleared() -> void:
	var best := int(GameState.progress.get("tower_best", 0))
	if tower_floor > best:
		GameState.progress["tower_best"] = tower_floor
		GameState.add_material("star_dust", 1 + tower_floor / 10)
		if tower_floor % 10 == 0:
			GameState.add_material("guild_badge", 1)
			_roll_pet(0, float(DataDB.pets.get("drop", {}).get("tower10", 0.15)) * (3.0 if tower_floor % 50 == 0 else 1.0))
			GameState.add_material("mythic_essence", 1 if tower_floor % 50 == 0 else 0)
		SteamService.submit_score("tower", tower_floor)
	tower_floor += 1
	boss_unit = null
	EventBus.stage_changed.emit(tower_floor)
	if not quiet:
		EventBus.notify.emit(DataDB.t("tower_floor", {"n": tower_floor}), Color("#9FDFFF"))
	_set_phase("travel")


## Rolls a pet drop from the pool of the given act (0 = tower-only pets + all acts).
func _roll_pet(act_n: int, chance: float) -> void:
	if rng.randf() >= chance:
		return
	var pool: Array = []
	var all_pets: Dictionary = DataDB.pets.get("pets", {})
	for pid in all_pets:
		var pa := int(all_pets[pid].get("act", 1))
		if pa == act_n or (act_n == 0) or (pa > 0 and pa < act_n and rng.randf() < 0.3):
			var w: float = {"R": 6.0, "SR": 3.0, "SSR": 1.0}.get(str(all_pets[pid].get("rarity", "R")), 3.0)
			pool.append([pid, w])
	if pool.is_empty():
		return
	var total := 0.0
	for e in pool:
		total += float(e[1])
	var r := rng.randf() * total
	for e in pool:
		r -= float(e[1])
		if r <= 0.0:
			GameState.grant_pet(str(e[0]))
			if not quiet:
				AudioManager.play("loot_legendary", 0.0, 0.8)
			return


func _tower_failed() -> void:
	if not quiet:
		EventBus.notify.emit(DataDB.t("tower_failed", {"n": tower_floor}), Color("#FF6A5A"))
	mode = "zone"
	go_to_zone(zone_idx, difficulty)


## Runs the simulation for `seconds` of game time (used by tests / bot balance runs).
func simulate(seconds: float) -> void:
	var steps := int(seconds / TICK)
	for i in steps:
		tick(TICK)
