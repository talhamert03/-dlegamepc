extends PanelWindow
## Story ending after Morvath falls on Normal: restored crystal slides, then a credits roll.

const SLIDES := ["ending_1", "ending_2", "ending_3", "ending_4", "ending_5"]
const SLIDE_T := 4.2

var _stage := Control.new()
var _text: Label
var _slide := 0
var _t := 0.0
var _credits_y := 0.0
var _heroes: Array = []      # portrait textures of the party
var _tex: Dictionary = {}


func build(c: Control) -> void:
	_stage.size = c.size
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	_stage.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_next())
	c.add_child(_stage)
	# painted scenes + the party's full illustrations (loaded here: first use inside _draw renders blank)
	for k in ["throne", "void", "temple", "town", "meadow"]:
		var p := "res://assets/hd/scenes/%s.jpg" % k
		_tex[k] = load(p) if ResourceLoader.exists(p) else null
	_tex["morvath"] = load("res://assets/hd/scenes/morvath.png") if ResourceLoader.exists("res://assets/hd/scenes/morvath.png") else null
	for h in GameState.party.filter(func(h): return h != ""):
		var tex := SpriteLib.portrait(str(h))
		if tex:
			_heroes.append(tex)
	_text = UITheme.label("", Color("#F7EBCF"), 11, UITheme.font_read)
	_text.position = Vector2(14, c.size.y - 36)
	_text.size = Vector2(c.size.x - 28, 32)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_outline_color", Color("#140E10"))
	_text.add_theme_constant_override("outline_size", 4)
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


## Cover-fit a painted scene with a slow push-in.
func _scene(key: String, tint: Color, zoom := 1.0) -> void:
	var tex: Texture2D = _tex.get(key)
	if tex == null:
		return
	var sz := _stage.size
	var ts := tex.get_size()
	var sc := maxf(sz.x / ts.x, sz.y / ts.y) * (zoom + _t * 0.012)
	var d := ts * sc
	_stage.draw_texture_rect(tex, Rect2((sz - d) / 2.0, d), false, tint)


func _draw_stage() -> void:
	var sz := _stage.size
	var ci := _stage.get_canvas_item()
	var k: float = clampf(_t / 0.6, 0.0, 1.0)
	if _slide < SLIDES.size():
		k *= clampf((SLIDE_T - _t) / 0.5, 0.0, 1.0)
	_text.modulate.a = k
	_stage.draw_rect(Rect2(Vector2.ZERO, sz), Color("#0A080E"))
	var cx := sz.x * 0.5
	var cy := sz.y * 0.42
	match _slide:
		0:
			# the throne room; Morvath's shadow thins into violet motes
			_scene("throne", Color(0.45, 0.38, 0.55, k))
			var mv: Texture2D = _tex.get("morvath")
			if mv:
				var h := sz.y * 0.85
				var w := h * mv.get_size().x / mv.get_size().y
				var fade := clampf(1.0 - _t / (SLIDE_T * 0.8), 0.0, 1.0)
				_stage.draw_texture_rect(mv, Rect2(cx - w / 2.0, sz.y * 0.08 - _t * 2.0, w, h), false, Color(0.5, 0.3, 0.7, fade * k))
			for i in 60:
				var a := float(i) * 2.399
				var d := 6.0 + _t * 18.0 + float(i % 7) * 4.0
				var mp := Vector2(cx + cos(a) * d, cy + sin(a) * d * 0.6 - _t * 6.0)
				_stage.draw_circle(mp, 2.2, Color(0.6, 0.3, 0.9, 0.15 * k))
				_stage.draw_circle(mp, 0.8, Color(0.85, 0.6, 1.0, (1.0 - _t / SLIDE_T) * k))
		1:
			# the four shards fly home through the void
			_scene("void", Color(0.55, 0.6, 0.8, k))
			for i in 4:
				var a := float(i) * TAU / 4.0 + 0.5 + _t * 0.4
				var d: float = maxf(0.0, 70.0 - _t * 22.0)
				var sp := Vector2(cx + cos(a) * d, cy + sin(a) * d * 0.6)
				_stage.draw_line(sp, sp + Vector2(cos(a), sin(a) * 0.6) * 18.0, Color(0.6, 0.9, 1.0, 0.25 * k), 2.0)
				_crystal(sp.x, sp.y, 0.45, k)
		2:
			# the crystal whole again above the temple
			_scene("temple", Color(0.9, 0.95, 1.0, k))
			for r in range(60, 0, -4):
				_stage.draw_circle(Vector2(cx, cy), r, Color(0.5, 0.85, 1.0, 0.03 * k))
			for i in 12:
				var a2 := float(i) * TAU / 12.0 + _t * 0.3
				var dir := Vector2(cos(a2), sin(a2))
				_stage.draw_line(Vector2(cx, cy) + dir * 28.0, Vector2(cx, cy) + dir * (44.0 + 6.0 * sin(_t * 3.0 + i)), Color(1, 1, 1, 0.35 * k), 1.0)
			_crystal(cx, cy, 1.3 + 0.03 * sin(_t * 2.0), k)
		3:
			# dawn over Stonebridge, the party in front of the guild hall, confetti
			_scene("town", Color(1.0, 0.85, 0.75, k))
			_stage.draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.6, 0.3, 0.12 * k))
			var n := _heroes.size()
			for i in n:
				var tex: Texture2D = _heroes[i]
				var hh := sz.y * (0.78 if i == n / 2 else 0.7)
				var hw := hh * tex.get_size().x / tex.get_size().y
				var fx := sz.x * (0.5 + (float(i) - (n - 1) / 2.0) * 0.17)
				var bob := sin(_t * 4.0 + i * 1.3) * 2.0 * clampf(_t - 0.5, 0.0, 1.0)
				_stage.draw_texture_rect(tex, Rect2(fx - hw / 2.0, sz.y - hh + 6.0 + bob, hw, hh), false, Color(1, 1, 1, k))
			for i in 40:
				var px := fmod(float(i) * 37.0 + _t * (16.0 + i % 5 * 4.0), sz.x)
				var py := fmod(float(i) * 23.0 + _t * (28.0 + i % 3 * 6.0), sz.y)
				_stage.draw_set_transform(Vector2(px, py), _t * 3.0 + i, Vector2.ONE)
				_stage.draw_rect(Rect2(-1.5, -0.8, 3, 1.6), Color([Color("#FFD84A"), Color("#FF8A3D"), Color("#9FDFFF"), Color("#FF6A8A")][i % 4], k))
				_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		4:
			# peace over the meadow... and two red eyes far away
			_scene("meadow", Color(0.85, 0.85, 0.9, k))
			_crystal(cx, cy - 10, 0.6, k)
			var ea := k * clampf(_t - 1.5, 0.0, 1.0)
			_stage.draw_rect(Rect2(Vector2.ZERO, Vector2(sz.x, sz.y)), Color(0.05, 0.0, 0.08, 0.35 * ea))
			for ex in [sz.x - 40.0, sz.x - 30.0]:
				_stage.draw_circle(Vector2(ex, cy - 20), 4.0, Color(1, 0.1, 0.2, 0.2 * ea))
				_stage.draw_circle(Vector2(ex, cy - 20), 1.4, Color(1, 0.3, 0.3, ea))
		_:
			_scene("town", Color(0.25, 0.22, 0.25, 1.0))
			_draw_credits(sz)
	# subtitle plate behind the narration
	if _slide < SLIDES.size():
		var sp := Rect2(8, sz.y - 38, sz.x - 16, 34)
		UISkin.fill(ci, sp, 4, Color(0.06, 0.04, 0.03, 0.72 * k), Color(0.02, 0.01, 0.01, 0.85 * k))
		_stage.draw_line(Vector2(sp.position.x + 10, sp.position.y), Vector2(sp.end.x - 10, sp.position.y), Color(0.91, 0.76, 0.48, 0.6 * k), 1.0)
		for i in SLIDES.size():
			_stage.draw_circle(Vector2(cx + (i - 2) * 9.0, sz.y - 3.0), 1.8 if i == _slide else 1.3, Color("#F2CB7A") if i == _slide else Color(1, 1, 1, 0.25))
	# soft vignette
	for i in 6:
		UISkin.stroke(ci, Rect2(Vector2.ZERO, sz).grow(-i * 2.0), 2, Color(0, 0, 0, 0.12), 2.0)


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


## Faceted crystal with a lit and a shaded side.
func _crystal(x: float, y: float, s: float, a: float) -> void:
	var ci := _stage.get_canvas_item()
	var top := Vector2(x, y - 18 * s)
	var bot := Vector2(x, y + 18 * s)
	var l := Vector2(x - 9 * s, y - 2 * s)
	var r := Vector2(x + 9 * s, y - 2 * s)
	var m := Vector2(x, y - 2 * s)
	_stage.draw_circle(Vector2(x, y), 22.0 * s, Color(0.5, 0.85, 1.0, 0.12 * a))
	UISkin.poly(ci, PackedVector2Array([top, l, m]), Color(0.85, 0.97, 1.0, a), Color(0.35, 0.7, 0.95, a))
	UISkin.poly(ci, PackedVector2Array([top, m, r]), Color(0.65, 0.9, 1.0, a), Color(0.2, 0.55, 0.9, a))
	UISkin.poly(ci, PackedVector2Array([l, bot, m]), Color(0.4, 0.75, 0.98, a), Color(0.15, 0.4, 0.8, a))
	UISkin.poly(ci, PackedVector2Array([m, bot, r]), Color(0.3, 0.62, 0.95, a), Color(0.1, 0.3, 0.7, a))
	_stage.draw_polyline(PackedVector2Array([top, r, bot, l, top]), Color(0.05, 0.1, 0.2, 0.8 * a), 1.0, true)
