extends PanelWindow
## Story ending after Morvath falls on Normal: restored crystal slides, then a credits roll.

const SLIDES := ["ending_1", "ending_2", "ending_3", "ending_4", "ending_5"]
const SLIDE_T := 4.2

var _stage := Control.new()
var _text: Label
var _slide := 0
var _t := 0.0
var _credits_y := 0.0
var _heroes: Array = []


func build(c: Control) -> void:
	_stage.size = c.size
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	_stage.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_next())
	c.add_child(_stage)
	var ids: Array = GameState.party.filter(func(h): return h != "")
	for i in ids.size():
		var s := AnimatedSprite2D.new()
		s.sprite_frames = SpriteLib.frames_for("hero", ids[i])
		s.centered = false
		s.offset = Vector2(-28, -54)
		s.position = Vector2(c.size.x * 0.5 + 40 - i * 20, c.size.y - 8)
		s.play("victory" if s.sprite_frames and s.sprite_frames.has_animation("victory") else "idle")
		s.visible = false
		_stage.add_child(s)
		_heroes.append(s)
	_text = UITheme.label("", UITheme.C_TEXT, 13, UITheme.font_read)
	_text.position = Vector2(8, 6)
	_text.size = Vector2(c.size.x - 16, 40)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_outline_color", Color("#140E10"))
	_text.add_theme_constant_override("outline_size", 2)
	_stage.add_child(_text)
	_slide = -1
	_next()
	AudioManager.play_music("title")


func _process(delta: float) -> void:
	if _text == null:
		return
	_t += delta
	if _slide < SLIDES.size():
		if _t > SLIDE_T:
			_next()
	else:
		_credits_y -= delta * 9.0
	_stage.queue_redraw()


func _next() -> void:
	_slide += 1
	_t = 0.0
	if _slide < SLIDES.size():
		_text.text = DataDB.t(SLIDES[_slide])
	else:
		_text.text = ""
		_credits_y = _stage.size.y
	for h in _heroes:
		h.visible = _slide == 3 or _slide >= SLIDES.size()


func _draw_stage() -> void:
	var sz := _stage.size
	var k: float = clampf(_t / 0.6, 0.0, 1.0)
	if _slide < SLIDES.size():
		k *= clampf((SLIDE_T - _t) / 0.5, 0.0, 1.0)
	_text.modulate.a = k
	_stage.draw_rect(Rect2(Vector2.ZERO, sz), Color("#100C16"))
	var cx := sz.x * 0.5
	var cy := sz.y * 0.55
	match _slide:
		0:
			# Morvath's shadow dissolves into motes
			for i in 40:
				var a := float(i) * 2.399
				var d := 4.0 + _t * 14.0 + float(i % 7) * 3.0
				_stage.draw_rect(Rect2(cx + cos(a) * d, cy + sin(a) * d * 0.6 - _t * 3.0, 1, 1), Color(0.6, 0.3, 0.9, (1.0 - _t / SLIDE_T) * k))
		1:
			# shards fly back together
			for i in 4:
				var a := float(i) * TAU / 4.0 + 0.5
				var d: float = maxf(0.0, 40.0 - _t * 14.0)
				_crystal(cx + cos(a) * d, cy + sin(a) * d * 0.6, 0.4, Color("#9FDFFF"), k)
		2:
			for r in range(40, 0, -3):
				_stage.draw_circle(Vector2(cx, cy), r, Color(0.5, 0.85, 1.0, 0.035 * k))
			_crystal(cx, cy, 1.2, Color("#9FDFFF"), k)
			for i in 12:
				var a2 := float(i) * TAU / 12.0 + _t
				_stage.draw_line(Vector2(cx, cy) + Vector2(cos(a2), sin(a2)) * 24.0, Vector2(cx, cy) + Vector2(cos(a2), sin(a2)) * (30.0 + 4.0 * sin(_t * 3.0 + i)), Color(1, 1, 1, 0.4 * k))
		3:
			# guild hall at dawn, party celebrates
			_stage.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(1.0, 0.6, 0.35, 0.18 * k))
			_stage.draw_rect(Rect2(0, sz.y - 10, sz.x, 10), Color("#2E3B2A"))
			_stage.draw_rect(Rect2(cx - 70, sz.y - 46, 40, 36), Color(0.45, 0.3, 0.2, k))
			_stage.draw_colored_polygon(PackedVector2Array([Vector2(cx - 74, sz.y - 46), Vector2(cx - 50, sz.y - 62), Vector2(cx - 26, sz.y - 46)]), Color(0.6, 0.25, 0.2, k))
			for i in 10:
				var fx := fmod(float(i) * 37.0 + _t * 20.0, sz.x)
				_stage.draw_rect(Rect2(fx, fmod(float(i) * 13.0 + _t * 30.0, sz.y - 20), 2, 2), [Color("#FFD84A"), Color("#FF8A3D"), Color("#9FDFFF")][i % 3])
		4:
			_crystal(cx, cy - 6, 0.6, Color("#9FDFFF"), k)
			var shadow := Color(0.1, 0.0, 0.15, 0.8 * k * clampf(_t - 1.5, 0.0, 1.0))
			_stage.draw_rect(Rect2(sz.x - 30, cy - 6, 3, 2), Color(1, 0.2, 0.3, shadow.a))
			_stage.draw_rect(Rect2(sz.x - 24, cy - 6, 3, 2), Color(1, 0.2, 0.3, shadow.a))
		_:
			_draw_credits(sz)


func _draw_credits(sz: Vector2) -> void:
	var f := UITheme.font_small
	var y := _credits_y
	var lines: Array = [["IDLE PARTY", Color("#FFB36A")], ["Desktop Legends", Color("#F2E6C9")], ["", Color.WHITE],
		[DataDB.t("credits_thanks"), Color("#9FDFFF")], ["", Color.WHITE]]
	var st := GameState.totals
	lines.append([DataDB.t("credits_kills", {"n": int(st.get("kills", 0))}), UITheme.C_TEXT])
	lines.append([DataDB.t("credits_bosses", {"n": int(st.get("bosses", 0))}), UITheme.C_TEXT])
	lines.append([DataDB.t("credits_heroes", {"n": GameState.heroes.size()}), UITheme.C_TEXT])
	lines.append(["", Color.WHITE])
	lines.append([DataDB.t("credits_next"), Color("#FF8A3D")])
	for l in lines:
		var w := f.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		_stage.draw_string(f, Vector2((sz.x - w) * 0.5, y), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, l[1])
		y += 11.0
	if y < 0:
		_credits_y = sz.y


func _crystal(x: float, y: float, s: float, c: Color, a: float) -> void:
	var pts := PackedVector2Array([Vector2(x, y - 18 * s), Vector2(x + 9 * s, y), Vector2(x, y + 18 * s), Vector2(x - 9 * s, y)])
	_stage.draw_colored_polygon(pts, Color(c, a))
	var pts2 := PackedVector2Array([Vector2(x, y - 18 * s), Vector2(x + 9 * s, y), Vector2(x, y)])
	_stage.draw_colored_polygon(pts2, Color(1, 1, 1, 0.5 * a))
