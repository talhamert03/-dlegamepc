class_name UnitView
extends Node2D
## Visual representation of a Combatant on the strip.
##
## Units with an animated chibi sheet (assets/hd/anim) play real frame animation: idle / run / attack / hurt / death,
## with the attack timed so its impact frame lands exactly when the simulation applies the hit. On top of the frames:
## melee lunge, ranged recoil, knock-back and squash on hits, hit flash, hit-stop, skill glow.
## Units without a sheet fall back to the single HD illustration with procedural motion.

const SHADER := preload("res://assets/shaders/unit.gdshader")
const HERO_H := 34.0                  # on-screen height of a hero, logical px
const ROW_IDLE := 0
const ROW_MOVE := 1
const ROW_ATTACK := 2
const ROW_HURT := 3
# frame in the attack row where the blow lands / the shot leaves
const IMPACT_FRAME := {"knight": 2, "berserker": 3, "assassin": 1, "archer": 3, "mage": 3, "necromancer": 3,
	"cleric": 3, "bard": 3}

static var hitstop := 0.0             # global freeze-frame on heavy hits (set by StripView)

var unit: Combatant
var kind := "hero"
var sheet_id := ""
var mat: ShaderMaterial
var body: Node2D                      # pivot at the feet: flip, squash & stretch, lunge
var spr: Sprite2D
var mode := ""                        # "sheet" | "hd" | ""
var _k := 1.0                         # texture px -> logical px
var _facing := 1.0
var _h := HERO_H                      # on-screen height
var _head_y := -42.0
var _bar_w := 16
var _show_bar := true
var _fly := 0.0
var _melee := true
var _impact_frame := 2
# animation state
var _cur := ""
var _t := 0.0                         # time in the current animation
var _clock := 0.0                     # free-running time (idle loops)
var _prev_anim_t := 0.0
var _prev_src := ""
var _done := false
var _death_t := 0.0
var _kick := 0.0                      # knock-back offset (decays)
var _squash := 0.0
var _last_flash := 0.0
var _phase := 0.0
var _base_x := 0.0
var _fallback_color := Color("#6CC24A")


func setup(u: Combatant) -> void:
	unit = u
	var vis: Dictionary = u.visual
	kind = vis.get("kind", "hero")
	sheet_id = str(vis.get("id", ""))
	_phase = randf() * 6.0
	_facing = 1.0 if u.is_hero_side() else -1.0
	_melee = bool(u.stats.get("melee", true))
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("time_offset", _phase)
	if kind == "hero":
		Costumes.apply(mat, sheet_id)
		EventBus.equipment_changed.connect(func(hid):
			if hid == sheet_id and is_instance_valid(self):
				Costumes.apply(mat, sheet_id))
	if kind == "enemy" and vis.get("elite", false):
		mat.set_shader_parameter("outline_color", Color(0.75, 0.4, 1.0, 0.9))
	elif kind == "enemy" and vis.get("boss", false):
		mat.set_shader_parameter("outline_color", Color(1.0, 0.35, 0.25, 0.8))
	var tint_hex: String = str(vis.get("def", {}).get("tint", ""))
	if tint_hex != "":
		mat.set_shader_parameter("tint", Color(tint_hex))
	_fallback_color = Color(str(vis.get("def", {}).get("color", "#6CC24A")))
	if kind == "enemy" and vis.get("boss", false):
		_show_bar = false
	if u.etype == "pet":
		_show_bar = false
	body = Node2D.new()
	add_child(body)
	_h = _target_height(vis)
	if not _setup_sheet():
		_setup_hd()
	_head_y = -_h - 5.0 - _fly
	_bar_w = int(clampf(_h * 0.5, 14.0, 26.0))
	if kind == "enemy" and vis.get("elite", false):
		_bar_w = 22
	z_index = 10 if kind != "enemy" else 9
	position = Vector2(round(u.x), BattleSim.GROUND_Y)
	_base_x = position.x


## On-screen size: heroes share one height; monsters keep their relative size from the old sheet heights.
func _target_height(vis: Dictionary) -> float:
	if kind == "hero":
		return HERO_H
	var old_h := 30.0
	var sid := sheet_id if kind == "enemy" else str(vis.get("sheet", "summon_" + sheet_id))
	var info := SpriteLib.sheet_info("enemy", sid)
	old_h = float(info.get("height", 30))
	if kind == "summon":
		return 22.0 if sheet_id.begins_with("pet_") else clampf(old_h * 0.9 + 4.0, 20.0, 34.0)
	if vis.get("boss", false):
		return clampf(old_h * 0.8 + 16.0, 44.0, 66.0)
	var h := clampf(old_h * 0.95 + 6.0, 20.0, 44.0)
	if vis.get("elite", false):
		h *= 1.12
	return h


func _art_ref() -> Array:
	## [category, id, mirrored] for this unit's art (bosses that reuse hero art, summons that reuse monsters, pets)
	const ALIAS := {"bjorn_duel": ["heroes", "bjorn"], "mirror_party": ["heroes", "kael"],
		"skeleton": ["enemies", "skeleton"], "wolf": ["enemies", "wolf"], "golem": ["enemies", "crystal_golem"]}
	if kind == "hero":
		return ["heroes", sheet_id]
	if kind == "summon" and sheet_id.begins_with("pet_"):
		return ["pets", sheet_id.substr(4)]
	if ALIAS.has(sheet_id) and (kind == "summon" or (SpriteLib.anim_meta("enemies", sheet_id).is_empty()
			and SpriteLib.hd_meta("enemies", sheet_id).is_empty())):
		return ALIAS[sheet_id]
	return ["enemies", sheet_id]


func _setup_sheet() -> bool:
	var ref := _art_ref()
	var m := SpriteLib.anim_meta(ref[0], ref[1])
	var tex := SpriteLib.anim_sheet(ref[0], ref[1])
	if tex == null:
		return false
	mode = "sheet"
	spr = Sprite2D.new()
	spr.texture = tex
	spr.hframes = 6
	spr.vframes = 4
	spr.centered = false
	spr.offset = -Vector2(float(m["ax"]), float(m["ay"]))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	spr.material = mat
	_k = _h / float(m.get("h", 128.0))
	mat.set_shader_parameter("texel_scale", 1.0 / _k)
	body.add_child(spr)
	if m.get("fly", false):
		_fly = 8.0
		_h *= 0.8
		_k *= 0.8
	if ref[0] == "heroes":
		_impact_frame = int(IMPACT_FRAME.get(str(DataDB.hero_def(ref[1]).get("class", "knight")), 2))
	else:
		_impact_frame = 2 if _melee else 3
	_play("idle")
	return true


func _setup_hd() -> void:
	var ref := _art_ref()
	var tex := SpriteLib.hd_sprite(ref[0], ref[1])
	if tex == null:
		return
	mode = "hd"
	var m := SpriteLib.hd_meta(ref[0], ref[1])
	var h := float(m.get("h", tex.get_height()))
	_k = _h / h
	spr = Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.offset = Vector2(-float(m.get("foot_x", tex.get_width() / 2.0)), -h)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	spr.material = mat
	mat.set_shader_parameter("texel_scale", 1.0 / _k)
	body.add_child(spr)
	# HD illustrations face right for heroes, left for monsters
	# (pets are painted facing right, like heroes)
	_hd_flip = (ref[0] == "heroes" or ref[0] == "pets") != unit.is_hero_side()


var _hd_flip := false


func _play(a: String) -> void:
	_cur = a
	_t = 0.0
	_done = false
	_dash = 0.0
	if (a == "attack" or a == "skill") and _melee and unit.act_impact <= 0.9:
		# melee units close the gap to their target, strike, and hop back (the sim allows a little reach)
		var tx := _target_x()
		if not is_nan(tx):
			_dash = clampf((tx - unit.x) * _facing - _h * 0.55 - 6.0, 0.0, 150.0)
		AudioManager.play("swing%d" % (randi() % 2), 0.1, 0.32 if unit.is_hero_side() else 0.22)


var _dash := 0.0
var _dash_off := 0.0


func _target_x() -> float:
	var pool: Array = BattleSim.enemies if unit.is_hero_side() else BattleSim.heroes
	for c in pool:
		if c.uid == unit.last_target and c.alive:
			return c.x
	return NAN


func _process(delta: float) -> void:
	if unit == null:
		return
	var target_x: float = round(unit.x)
	_base_x = lerp(_base_x, target_x, min(1.0, delta * 14.0)) if abs(_base_x - target_x) < 30 else target_x
	position.x = round(_base_x + _dash_off * _facing)
	var frozen := hitstop > 0.0 and _cur in ["attack", "hit", "skill"]
	var dt := 0.0 if frozen else delta
	_clock += delta
	_t += dt
	# ----- choose the animation
	var src: String = unit.anim
	var restarted: bool = unit.anim_t < _prev_anim_t - 0.001 or src != _prev_src
	_prev_anim_t = unit.anim_t
	_prev_src = src
	var want := src
	if not unit.alive:
		want = "death"
	elif BattleSim.phase == "travel" and unit.is_hero_side():
		want = "run"
	elif BattleSim.phase == "victory" and unit.is_hero_side():
		want = "victory"
	var busy: bool = _cur in ["attack", "skill", "hit"] and not _done
	if want in ["attack", "skill", "hit"]:
		if restarted and not (want == "hit" and busy and _cur != "hit"):
			_play(want)
			busy = true
		elif not (_cur == want and not _done):
			want = "idle"
	if want not in ["attack", "skill", "hit"] and want != _cur and (not busy or want == "death"):
		_play(want)
	# ----- hit reaction
	if unit.flash_t > _last_flash + 0.01:
		_kick = 2.5
		_squash = 1.0
	_last_flash = unit.flash_t
	_kick = move_toward(_kick, 0.0, delta * 18.0)
	_squash = move_toward(_squash, 0.0, delta * 7.0)
	_dash_off = _dash_curve()
	z_index = (14 if _dash_off > 2.0 else 10) if kind != "enemy" else (13 if _dash_off > 2.0 else 9)
	if mode == "sheet":
		_animate_sheet()
	elif mode == "hd":
		_animate_hd()
	mat.set_shader_parameter("flash", clamp(unit.flash_t / 0.12, 0.0, 1.0) * 0.7)
	if not unit.alive:
		_death_t += delta
		if kind != "hero":
			mat.set_shader_parameter("dissolve", clamp((_death_t - 0.55) * 1.8, 0.0, 1.0))
		else:
			modulate.a = 0.75
	else:
		_death_t = 0.0
		modulate.a = 1.0
		mat.set_shader_parameter("dissolve", 0.0)
	queue_redraw()


## Offset along the facing direction while dashing in for a melee blow.
func _dash_curve() -> float:
	if _dash <= 0.0 or not (_cur == "attack" or _cur == "skill"):
		return 0.0
	var imp: float = clampf(unit.act_impact, 0.08, 0.9)
	var total: float = max(unit.act_len, imp + 0.16)
	if _t < imp:
		var e := clampf(_t / (imp * 0.85), 0.0, 1.0)
		return _dash * (e * e * (3.0 - 2.0 * e))
	var r := clampf((_t - imp) / max(0.05, total - imp), 0.0, 1.0)
	if r < 0.35:
		return _dash
	var b := (r - 0.35) / 0.65
	return _dash * (1.0 - b * b * (3.0 - 2.0 * b))


func _frames(row: int, a: int, b: int, dur: float, loop: bool) -> int:
	## frame index (a..b inclusive) for time _t over dur seconds
	var n := b - a + 1
	var f := int(floor(_t / max(0.01, dur) * n))
	if loop:
		f = posmod(f, n)
	elif f >= n:
		f = n - 1
		_done = true
	return row * 6 + a + f


func _animate_sheet() -> void:
	var ox := 0.0
	var oy := -_fly
	var sx := 1.0
	var sy := 1.0
	var glow := 0.0
	match _cur:
		"run":
			spr.frame = _frames(ROW_MOVE, 0, 5, 0.5, true) if kind == "hero" or unit.is_hero_side() else _frames(ROW_MOVE, 0, 5, 0.6, true)
			_t = fmod(_t, 6.0)
		"attack", "skill":
			var imp: float = clampf(unit.act_impact, 0.08, 1.6)
			var total: float = max(unit.act_len, imp + 0.16)
			var post: float = total - imp
			if _t < imp:
				# wind-up: frames 0 .. impact-1 ; a long boss charge holds the wind-up and pulses
				var pre_n := maxi(1, _impact_frame)
				var f := mini(pre_n - 1, int(_t / imp * pre_n))
				if imp > 0.9:
					f = mini(pre_n - 1, int(_t * 6.0) % 2) if pre_n > 1 else 0
					glow = 0.35 + 0.25 * sin(_clock * 18.0)
				spr.frame = ROW_ATTACK * 6 + f
				if _melee:
					ox = -1.5 * (_t / imp)
			else:
				var e: float = (_t - imp) / max(0.05, post)
				var rest := 6 - _impact_frame
				var f2 := _impact_frame + mini(rest - 1, int(e * rest))
				spr.frame = ROW_ATTACK * 6 + f2
				if e >= 1.0:
					_done = true
					spr.frame = ROW_ATTACK * 6 + 5
				if _melee:
					# dash into the blow, then settle back
					var d: float = clampf(e * 3.0, 0.0, 1.0)
					ox = lerpf(4.5, 0.0, clampf((e - 0.35) / 0.65, 0.0, 1.0)) * d
					sx = 1.0 + 0.06 * (1.0 - clampf(e * 2.5, 0.0, 1.0))
					sy = 1.0 - 0.04 * (1.0 - clampf(e * 2.5, 0.0, 1.0))
				else:
					ox = -1.5 * (1.0 - clampf(e * 2.0, 0.0, 1.0))
			if _cur == "skill" and imp <= 0.9:
				glow = 0.22 * (1.0 - clampf(abs(_t - imp) / 0.3, 0.0, 1.0))
		"hit":
			spr.frame = _frames(ROW_HURT, 0, 1, 0.24, false)
		"death":
			spr.frame = _frames(ROW_HURT, 2, 5, 0.55, false)
		"victory":
			spr.frame = _frames(ROW_IDLE, 0, 5, 0.6, true)
			oy -= absf(sin(_clock * 7.0 + _phase)) * 3.0
		_:
			# idle: 6-frame breathing loop, each unit on its own phase
			var n := int(floor((_clock + _phase) * 7.0))
			spr.frame = ROW_IDLE * 6 + posmod(n, 6)
			if _fly > 0.0:
				oy += sin(_clock * 3.0 + _phase) * 1.5
	if _fly > 0.0 and _cur != "death":
		oy += sin(_clock * 3.0 + _phase) * 0.8
	if _cur == "death":
		oy = -_fly * (1.0 - clampf(_death_t / 0.4, 0.0, 1.0))
	# hit squash and knock-back
	sx *= 1.0 + 0.08 * _squash
	sy *= 1.0 - 0.08 * _squash
	ox -= _kick
	body.position = Vector2(round(ox * _facing), round(oy))
	body.scale = Vector2(_k * sx * _facing, _k * sy)
	mat.set_shader_parameter("glow", Color(1.0, 0.85, 0.45, glow) if unit.is_hero_side() else Color(1.0, 0.3, 0.2, glow))


## Procedural animation for units that only have the single HD illustration (pivot = feet).
func _animate_hd() -> void:
	var ox := 0.0
	var oy := 0.0
	var rot := 0.0
	var sx := 1.0
	var sy := 1.0
	var t := _clock + _phase
	match _cur:
		"run":
			oy = -absf(sin(t * 9.0)) * 1.6
			rot = 0.04 + 0.02 * sin(t * 9.0)
		"attack", "skill":
			var imp: float = clampf(unit.act_impact, 0.08, 1.6)
			var total: float = max(unit.act_len, imp + 0.16)
			if _t < imp:
				var e := _t / imp
				ox = -2.0 * e
				rot = -0.08 * e
				sx = 1.0 - 0.04 * e
				sy = 1.0 + 0.03 * e
			else:
				var e2: float = clampf((_t - imp) / max(0.05, total - imp), 0.0, 1.0)
				ox = lerpf(5.0, 0.0, e2) if _melee else lerpf(-1.5, 0.0, e2)
				rot = lerpf(0.12, 0.0, e2)
				sx = 1.0 + 0.06 * (1.0 - e2)
				sy = 1.0 - 0.05 * (1.0 - e2)
				if e2 >= 1.0:
					_done = true
		"hit":
			var p := clampf(_t / 0.25, 0.0, 1.0)
			rot = -0.1 * (1.0 - p)
			if p >= 1.0:
				_done = true
		"death":
			var d: float = clampf(_death_t / 0.45, 0.0, 1.0)
			rot = -1.45 * d * d
			oy = 2.0 * d
		"victory":
			oy = -absf(sin(t * 6.0)) * 3.0
		_:
			sy = 1.0 + 0.015 * sin(t * 2.6)
			sx = 1.0 - 0.008 * sin(t * 2.6)
	sx *= 1.0 + 0.08 * _squash
	sy *= 1.0 - 0.08 * _squash
	ox -= _kick
	var flip := -1.0 if _hd_flip else 1.0
	body.position = Vector2(round(ox * _facing), round(oy))
	body.rotation = rot * _facing
	body.scale = Vector2(_k * sx * flip, _k * sy)


func _draw() -> void:
	if unit == null:
		return
	# soft contact shadow
	var sw := clampf(_h * 0.32, 6.0, 20.0)
	var sa := 1.0 if unit.alive else clampf(1.0 - (_death_t - 0.6) * 2.0, 0.0, 1.0)
	if _fly > 0.0:
		sw *= 0.7
	draw_set_transform(Vector2(0, -0.5), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, sw, Color(0, 0, 0, 0.20 * sa))
	draw_circle(Vector2.ZERO, sw * 0.62, Color(0, 0, 0, 0.16 * sa))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mode == "":
		draw_circle(Vector2(0, -7), 7.0, _fallback_color.darkened(0.5))
		draw_circle(Vector2(0, -7), 6.0, _fallback_color)
	if not unit.alive or not _show_bar:
		return
	var w := float(_bar_w)
	var y := _head_y
	var frac := unit.hp_frac()
	var col := Color("#E2453C") if not unit.is_hero_side() else Color("#5BD65A")
	if unit.is_hero_side() and frac < 0.35:
		col = Color("#F0B33A")
	var x0 := -w / 2.0
	draw_rect(Rect2(x0 - 1, y - 1, w + 2, 4), Color(0.04, 0.03, 0.05, 0.85))
	draw_rect(Rect2(x0, y, w, 2), Color(0.22, 0.13, 0.14))
	draw_rect(Rect2(x0, y, round(w * frac), 2), col)
	draw_rect(Rect2(x0, y, round(w * frac), 0.5), col.lightened(0.45))
	if unit.shield > 0:
		var sf: float = clamp(unit.shield / max(1.0, unit.max_hp), 0.0, 1.0)
		draw_rect(Rect2(x0, y - 1, round(w * sf), 1), Color("#8FD8FF"))
	if unit.is_hero_side() and unit.ult_id != "":
		var uc := Color("#F7C948") if unit.ult_charge < 100 else Color(1, 1, 1, 0.6 + 0.4 * sin(_clock * 10.0))
		draw_rect(Rect2(x0, y + 2, round(w * unit.ult_charge / 100.0), 1), uc)
	# status pips
	var px := x0
	for s in ["stun", "freeze", "burn", "poison", "bleed", "chill", "shock", "vulnerable", "weaken"]:
		if unit.has_status(s):
			var c: Color = {"stun": Color("#FFE45C"), "freeze": Color("#BFE8FF"), "burn": Color("#FF7A33"), "poison": Color("#9BE05A"),
				"bleed": Color("#C9213A"), "chill": Color("#7FD8FF"), "shock": Color("#FFF27A"), "vulnerable": Color("#FF5A9A"),
				"weaken": Color("#9A8AB8")}[s]
			draw_rect(Rect2(px, y - 4, 2, 2), c)
			px += 3
	for b in unit.buffs:
		draw_rect(Rect2(px, y - 4, 2, 2), Color("#7FE07A"))
		px += 3
		if px > w / 2.0:
			break


## Where the blow of this unit's attack lands (logical, strip space): in front of the weapon.
func strike_point() -> Vector2:
	return position + Vector2(_facing * _h * 0.45, -_h * 0.45)


func center() -> Vector2:
	return position + Vector2(0, -_h * 0.5 - _fly)
