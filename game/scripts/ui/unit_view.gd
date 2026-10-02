class_name UnitView
extends Node2D
## Visual representation of a Combatant on the strip.

const SHADER := preload("res://assets/shaders/unit.gdshader")

var unit: Combatant
var sprite: AnimatedSprite2D
var mat: ShaderMaterial
var kind := "hero"
var sheet_id := ""
var root_off := Vector2(28, 54)
var _cur_anim := ""
var _bar_w := 16
var _head_y := -42.0
var _scale := 1.0
var _fallback_color := Color("#6CC24A")
var _death_t := 0.0
var _show_bar := true


func setup(u: Combatant) -> void:
	unit = u
	var vis: Dictionary = u.visual
	kind = vis.get("kind", "hero")
	sheet_id = str(vis.get("id", ""))
	var frames: SpriteFrames = null
	if kind == "hero":
		frames = SpriteLib.frames_for("hero", sheet_id)
		var info := SpriteLib.sheet_info("hero", sheet_id)
		var r: Array = info.get("root", [28, 54])
		root_off = Vector2(float(r[0]), float(r[1]))
	elif kind == "summon":
		frames = SpriteLib.frames_for("enemy", "summon_" + sheet_id)
		var info2 := SpriteLib.sheet_info("enemy", "summon_" + sheet_id)
		var r2: Array = info2.get("root", [24, 46])
		root_off = Vector2(float(r2[0]), float(r2[1]))
		_head_y = -float(info2.get("height", 24)) - 4.0
	else:
		frames = SpriteLib.frames_for("enemy", sheet_id)
		var info3 := SpriteLib.sheet_info("enemy", sheet_id)
		var r3: Array = info3.get("root", [32, 60])
		root_off = Vector2(float(r3[0]), float(r3[1]))
		_head_y = -float(info3.get("height", 30)) - 5.0
		_fallback_color = Color(str(vis.get("def", {}).get("color", "#6CC24A")))
		if vis.get("boss", false):
			_bar_w = 0
			_show_bar = false
		elif vis.get("elite", false):
			_bar_w = 20
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.offset = -root_off
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("time_offset", randf() * 6.0)
	if kind == "enemy" and vis.get("elite", false):
		mat.set_shader_parameter("outline_color", Color(0.75, 0.4, 1.0, 0.9))
	elif kind == "enemy" and vis.get("boss", false):
		mat.set_shader_parameter("outline_color", Color(1.0, 0.35, 0.25, 0.8))
	var tint_hex: String = str(vis.get("def", {}).get("tint", ""))
	if tint_hex != "":
		mat.set_shader_parameter("tint", Color(tint_hex))
	sprite.material = mat
	if frames:
		sprite.sprite_frames = frames
		_play("idle")
	add_child(sprite)
	if kind == "hero":
		_head_y = -44.0
	z_index = 10 if kind != "enemy" else 9
	position = Vector2(round(u.x), BattleSim.GROUND_Y)


func _play(a: String, speed := 1.0) -> void:
	if sprite.sprite_frames == null:
		_cur_anim = a
		return
	if not sprite.sprite_frames.has_animation(a):
		a = "idle" if sprite.sprite_frames.has_animation("idle") else ""
		if a == "":
			return
	_cur_anim = a
	sprite.speed_scale = speed
	sprite.play(a)


func _process(delta: float) -> void:
	if unit == null:
		return
	var target_x: float = round(unit.x)
	position.x = lerp(position.x, target_x, min(1.0, delta * 14.0)) if abs(position.x - target_x) < 30 else target_x
	position.x = round(position.x)
	# animation selection
	var want: String = unit.anim
	if not unit.alive:
		want = "death"
	elif BattleSim.phase == "travel" and unit.is_hero_side():
		want = "run"
	elif BattleSim.phase == "victory" and unit.is_hero_side():
		want = "victory"
	elif (want == "attack" or want == "skill" or want == "hit") and not sprite.is_playing() and _cur_anim == want:
		unit.anim = "idle"
		want = "idle"
	if want != _cur_anim or (want in ["attack", "skill", "hit"] and unit.anim_t < 0.05 and sprite.frame > 1):
		var sp := 1.0
		if want == "attack":
			var aps: float = float(unit.stats.get("aps", 1.0))
			sp = clamp(aps, 1.0, 2.25)
		_play(want, sp)
	mat.set_shader_parameter("flash", clamp(unit.flash_t / 0.12, 0.0, 1.0) * 0.65)
	if not unit.alive:
		_death_t += delta
		if kind != "hero":
			mat.set_shader_parameter("dissolve", clamp((_death_t - 0.35) * 1.6, 0.0, 1.0))
		else:
			modulate.a = 0.5 + 0.3 * sin(_death_t * 6.0)
	else:
		_death_t = 0.0
		modulate.a = 1.0
		mat.set_shader_parameter("dissolve", 0.0)
	queue_redraw()


func _draw() -> void:
	if unit == null:
		return
	# soft shadow
	var sw := 9.0 if kind == "hero" else max(7.0, root_off.x * 0.3)
	draw_rect(Rect2(-sw, -1, sw * 2, 2), Color(0, 0, 0, 0.28))
	draw_rect(Rect2(-sw + 2, -2, sw * 2 - 4, 1), Color(0, 0, 0, 0.18))
	if sprite.sprite_frames == null:
		# placeholder blob
		draw_circle(Vector2(0, -7), 7.0, _fallback_color.darkened(0.5))
		draw_circle(Vector2(0, -7), 6.0, _fallback_color)
		draw_rect(Rect2(2, -10, 2, 2), Color.WHITE)
	if not unit.alive or not _show_bar:
		return
	var w := _bar_w
	var y := _head_y
	var frac := unit.hp_frac()
	var col := Color("#D63A3A") if not unit.is_hero_side() else Color("#5FD65A")
	if unit.is_hero_side() and frac < 0.35:
		col = Color("#E8B83A")
	draw_rect(Rect2(-w / 2.0 - 1, y - 1, w + 2, 4), Color("#140E10"))
	draw_rect(Rect2(-w / 2.0, y, w, 2), Color("#3A2A2A"))
	draw_rect(Rect2(-w / 2.0, y, round(w * frac), 2), col)
	if unit.shield > 0:
		var sf: float = clamp(unit.shield / max(1.0, unit.max_hp), 0.0, 1.0)
		draw_rect(Rect2(-w / 2.0, y, round(w * sf), 1), Color("#8FD8FF"))
	if unit.is_hero_side() and unit.ult_id != "":
		draw_rect(Rect2(-w / 2.0, y + 2, round(w * unit.ult_charge / 100.0), 1), Color("#F7C948") if unit.ult_charge < 100 else Color.WHITE)
	# status pips
	var px := -w / 2.0
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
