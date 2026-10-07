class_name TitleScreen
extends Control
## First-launch title + cinematic intro story.
##
## Covers the whole overlay with a dark backdrop and plays in a large 16:9 frame: a night camp with the
## party's animated sprites around a campfire under the logo, then five illustrated story beats (slow
## camera moves, letterbox, typewriter narration, flashes and particles). Then the game shrinks to the strip.

signal finished

const SIZE := Vector2i(240, 135)          # kept for callers; the real size is the whole overlay
const BEATS := ["intro_1", "intro_2", "intro_3", "intro_4", "intro_5"]
const BEAT_LEN := 6.0
const SCENES := "res://assets/hd/scenes/%s.jpg"
## poster cast: [hero, x (0..1), height (x frame h), foot y (x frame h), back row]
const POSTER := [["nova", 0.39, 0.92, 1.0, true], ["bjorn", 0.665, 0.96, 1.03, true], ["lyra", 0.22, 1.0, 1.1, false],
	["pip", 0.79, 0.98, 1.1, false], ["kael", 0.5, 1.16, 1.2, false]]

var _frame := Rect2()
var _view: Control
var _t := 0.0
var _stage := "title"                      # title | intro | outro | done
var _beat := -1
var _bt := 0.0
var _fade := 1.0                           # black fade overlay
var _shake := 0.0
var _flash := 0.0
var _tex: Dictionary = {}
var _parts: Array = []
var _rng := RandomNumberGenerator.new()
var _buttons: HBoxContainer
var _text: Label
var _skip: Button
var _heroes: Array = []
var _hint: Label
var _logo: Control
var _bolt: PackedVector2Array = PackedVector2Array()
var _bolt_t := 1.5
var _bolt_life := 0.0


func _ready() -> void:
	theme = UITheme.theme
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	var area := WindowManager.area_size()
	position = Vector2.ZERO
	size = area
	# a cinema window, not the whole screen
	var fw := minf(area.x * 0.66, area.y * 0.7 * 16.0 / 9.0)
	var fh := fw * 9.0 / 16.0
	_frame = Rect2(((area - Vector2(fw, fh)) / 2.0).round(), Vector2(fw, fh).round())
	_view = Control.new()
	_view.position = _frame.position
	_view.size = _frame.size
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	add_child(_view)
	# key-art poster: the heroes' full illustrations, front to back
	for h in POSTER:
		var tex := SpriteLib.portrait(str(h[0]))
		_tex["poster_" + str(h[0])] = tex
		_tex["sil_" + str(h[0])] = _silhouette(tex)
	var bw := clampf(_frame.size.x * 0.17, 84.0, 120.0)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.size = Vector2(bw * 3 + 16, 24)
	_buttons.position = Vector2(_frame.position.x + (_frame.size.x - _buttons.size.x) / 2.0, _frame.end.y - _frame.size.y * 0.115)
	add_child(_buttons)
	for d in [["title_new", Color("#FFC14A"), _start_intro], ["title_settings", Color("#9FC8FF"), func(): WindowManager.toggle_panel("settings")],
			["tray_quit", Color("#FF6A5A"), func(): WindowManager.quit_game()]]:
		_buttons.add_child(Fancy.plaque_button(DataDB.t(d[0]), d[1], d[2], Vector2(bw, 24)))
	_buttons.modulate.a = 0.0
	_text = UITheme.label("", Color("#F7EBCF"), int(clampf(_frame.size.y * 0.05, 12.0, 19.0)), UITheme.font_read)
	_text.position = Vector2(_frame.position.x + _frame.size.x * 0.08, _frame.end.y - _frame.size.y * 0.13)
	_text.size = Vector2(_frame.size.x * 0.84, _frame.size.y * 0.11)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_text.add_theme_constant_override("outline_size", 5)
	_text.add_theme_constant_override("line_spacing", 1)
	_text.visible = false
	add_child(_text)
	_hint = UITheme.label(DataDB.t("click_continue"), Color("#E9DDC2"), 9)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint.add_theme_constant_override("outline_size", 3)
	# top-left of the letterbox, well inside the frame
	_hint.position = Vector2(_frame.position.x + 10, _frame.position.y + 10)
	_hint.size = Vector2(_frame.size.x * 0.5, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.visible = false
	add_child(_hint)
	_skip = UITheme.button(DataDB.t("skip") + "  ›", "brown", _finish, Vector2(54, 16))
	_skip.position = Vector2(_frame.end.x - 62, _frame.position.y + 8)
	_skip.visible = false
	add_child(_skip)
	for k in ["forest", "temple", "throne", "ruins", "meadow", "snow", "desert", "ash", "town"]:
		var p := SCENES % k
		_tex[k] = load(p) if ResourceLoader.exists(p) else null
	_tex["morvath"] = load("res://assets/hd/scenes/morvath.png") if ResourceLoader.exists("res://assets/hd/scenes/morvath.png") else null
	# textures must be loaded before the first draw call that uses them (first-use inside _draw renders blank)
	for b in ["goblin_king", "ice_witch", "pharaoh", "demon_hunter"]:
		_tex["boss_" + b] = SpriteLib.boss_art(b)
	for h in ["lyra", "kael", "pip", "bjorn"]:
		_tex["hero_" + h] = SpriteLib.portrait(h)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	g.add_point(0.55, Color(1, 1, 1, 0.0))
	g.add_point(0.85, Color(1, 1, 1, 0.45))
	var vt := GradientTexture2D.new()
	vt.gradient = g
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.0, 1.0)
	vt.width = 256
	vt.height = 144
	_tex["vignette"] = vt
	# logo sits above the cinematic view
	_logo = Control.new()
	_logo.size = size
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.draw.connect(_draw_logo)
	add_child(_logo)
	move_child(_logo, _view.get_index() + 1)
	AudioManager.play_music("title")


func _process(delta: float) -> void:
	_t += delta
	_bt += delta
	_shake = maxf(0.0, _shake - delta)
	_flash = maxf(0.0, _flash - delta * 2.2)
	match _stage:
		"title":
			_fade = maxf(0.0, _fade - delta * 0.8)
			if _t > 1.6:
				_buttons.modulate.a = minf(1.0, _buttons.modulate.a + delta * 1.6)
			_bolt_t -= delta
			if _bolt_t <= 0.0:
				_bolt_t = _rng.randf_range(3.0, 6.5)
				_bolt = _make_bolt()
				_bolt_life = 0.35
			_bolt_life = maxf(0.0, _bolt_life - delta)
			for s: Sprite2D in _heroes:
				s.frame = posmod(int((_t + float(s.get_meta("phase"))) * 7.0), 6)
		"intro":
			_fade = maxf(0.0, _fade - delta * 1.5) if _bt < BEAT_LEN - 0.6 else minf(1.0, _fade + delta * 1.8)
			_text.visible_ratio = clampf((_bt - 0.5) / 2.2, 0.0, 1.0)
			_hint.visible = _text.visible_ratio >= 1.0
			_hint.modulate.a = 0.75 + 0.25 * sin(_t * 4.0)
			_beat_events()
			if _bt >= BEAT_LEN:
				_next_beat()
		"outro":
			_fade = minf(1.0, _fade + delta * 1.4)
			if _fade >= 1.0:
				_stage = "done"
				finished.emit()
				queue_free()
	_update_parts(delta)
	_view.position = _frame.position + (Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake * 10.0).round()
	_view.queue_redraw()
	_logo.queue_redraw()
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if _stage == "intro" and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _text.visible_ratio < 1.0:
			_bt = maxf(_bt, 2.7)
		else:
			_bt = maxf(_bt, BEAT_LEN - 0.6)


func _unhandled_input(ev: InputEvent) -> void:
	if _stage == "intro" and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_finish()


# ------------------------------------------------------------------ flow
func _start_intro() -> void:
	_stage = "intro"
	_buttons.visible = false
	for h in _heroes:
		h.visible = false
	_skip.visible = true
	_text.visible = true
	_beat = -1
	_next_beat()


func _next_beat() -> void:
	_beat += 1
	_bt = 0.0
	_fade = 1.0
	_parts.clear()
	_fired.clear()
	if _beat >= BEATS.size():
		_stage = "outro"
		_text.visible = false
		_skip.visible = false
		_hint.visible = false
		return
	_text.text = DataDB.t(BEATS[_beat])
	_text.visible_ratio = 0.0


var _fired: Dictionary = {}


func _once(key: String) -> bool:
	if _fired.has(key):
		return false
	_fired[key] = true
	return true


func _beat_events() -> void:
	match _beat:
		1:
			if _bt > 2.0 and _once("shatter"):
				_shake = 0.6
				_flash = 1.0
				AudioManager.play("boss_warning", 0.0, 1.0)
				var c := Vector2(_frame.size.x * 0.3, _frame.size.y * 0.42)
				for i in 46:
					var a := _rng.randf() * TAU
					_parts.append({"k": "shard", "p": c, "v": Vector2(cos(a), sin(a) - 0.3) * _rng.randf_range(120, 420), "t": 0.0,
						"life": _rng.randf_range(1.2, 2.6), "r": _rng.randf() * TAU, "s": _rng.randf_range(4, 10)})
		4:
			if _bt > 1.4 and _once("guild"):
				_flash = 0.6
				AudioManager.play("levelup", 0.0, 0.9)
				var c2 := Vector2(_frame.size.x * 0.5, _frame.size.y * 0.33)
				for i in 60:
					var a2 := _rng.randf() * TAU
					_parts.append({"k": "spark", "p": c2, "v": Vector2(cos(a2), sin(a2)) * _rng.randf_range(60, 260), "t": 0.0,
						"life": _rng.randf_range(0.8, 1.8), "c": [Color("#FFD978"), Color("#FFF2C2"), Color("#FF9A5A")][i % 3]})


func _finish() -> void:
	if _stage == "done" or _stage == "outro":
		return
	_stage = "outro"
	_text.visible = false
	_skip.visible = false
	_hint.visible = false


# ------------------------------------------------------------------ particles
func _update_parts(delta: float) -> void:
	var f := _frame.size
	if _stage == "title":
		# embers rising from the burning logo
		while _parts.size() < 46:
			_parts.append({"k": "ember", "t": 0.0, "life": _rng.randf_range(1.2, 3.2),
				"p": Vector2(f.x * _rng.randf_range(0.28, 0.72), f.y * _rng.randf_range(0.7, 0.82)),
				"v": Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-60, -25)), "ph": _rng.randf() * 6.0})
	elif _stage == "intro" and (_beat == 0 or _beat == 2):
		while _parts.size() < 36:
			_parts.append({"k": "mote", "t": 0.0, "life": _rng.randf_range(2.5, 5.0), "p": Vector2(_rng.randf() * f.x, f.y * _rng.randf_range(0.2, 1.0)),
				"v": Vector2(_rng.randf_range(-5, 5), _rng.randf_range(-16, -6)), "ph": _rng.randf() * 6.0})
	for p in _parts:
		p["t"] = float(p["t"]) + delta
		var v: Vector2 = p["v"]
		if p["k"] == "shard":
			v.y += 260.0 * delta
			p["v"] = v
			p["r"] = float(p["r"]) + delta * 6.0
		elif p["k"] == "spark":
			p["v"] = v * (1.0 - delta * 1.6) + Vector2(0, 40.0 * delta)
		p["p"] = (p["p"] as Vector2) + v * delta
	_parts = _parts.filter(func(p): return float(p["t"]) < float(p["life"]))


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	# dim the desktop behind the cinematic
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.02, 0.62))
	var ci := get_canvas_item()
	# soft drop shadow and an ornate gilded frame around the cinema window
	for i in 6:
		UISkin.stroke(ci, _frame.grow(6.0 + i * 3.0), 8, Color(0, 0, 0, 0.12), 3.0)
	UISkin.fill(ci, _frame.grow(7.0), 6, Color("#3A2614"), Color("#1A0F08"))
	UISkin.ornate(ci, _frame.grow(6.0))
	UISkin.stroke(ci, _frame.grow(2.0), 3, Color(0, 0, 0, 1), 2.0)
	UISkin.stroke(ci, _frame.grow(1.0), 3, Color("#E8C27A", 0.9), 1.0)
	for c in [_frame.position, Vector2(_frame.end.x, _frame.position.y), Vector2(_frame.position.x, _frame.end.y), _frame.end]:
		UISkin.diamond(ci, c, 5.0)


## Pan / zoom over a scene image so it covers the frame. pan: 0..1 across the spare width.
func _scene(key: String, pan: float, zoom := 1.0, tint := Color.WHITE, alpha := 1.0, rect := Rect2()) -> void:
	var tex: Texture2D = _tex.get(key)
	if tex == null:
		return
	if rect.size == Vector2.ZERO:
		rect = Rect2(Vector2.ZERO, _frame.size)
	var ts := Vector2(tex.get_width(), tex.get_height())
	var sc := maxf(rect.size.x / ts.x, rect.size.y / ts.y) * zoom
	var src := rect.size / sc
	var spare := ts - src
	var org := Vector2(spare.x * clampf(pan, 0.0, 1.0), spare.y * 0.5)
	_view.draw_texture_rect_region(tex, rect, Rect2(org, src), Color(tint, alpha))


func _figure(tex: Texture2D, foot: Vector2, h: float, alpha := 1.0, flip := false, tint := Color.WHITE) -> void:
	if tex == null:
		return
	var k := h / float(tex.get_height())
	var w := tex.get_width() * k
	var r := Rect2(foot - Vector2(w / 2.0, h), Vector2(w, h))
	if flip:
		# a negative width mirrors the texture in place (same left edge)
		r = Rect2(r.position, Vector2(-w, h))
	_view.draw_texture_rect(tex, r, false, Color(tint, alpha))


func _vignette(col: Color, strength: float) -> void:
	var vt: Texture2D = _tex.get("vignette")
	if vt:
		_view.draw_texture_rect(vt, Rect2(Vector2.ZERO, _frame.size), false, Color(col.r, col.g, col.b, strength))


func _draw_view() -> void:
	var f := _frame.size
	var ci := _view.get_canvas_item()
	match _stage:
		"title", "done":
			_draw_poster()
		_:
			if _beat >= 0 and _beat < BEATS.size():
				_draw_beat(_beat)
	# particles
	for p in _parts:
		var k: float = float(p["t"]) / float(p["life"])
		var a := sin(k * PI)
		var pos: Vector2 = p["p"]
		match p["k"]:
			"fly":
				var tw := 0.5 + 0.5 * sin(_t * 3.0 + float(p["ph"]))
				_view.draw_circle(pos, 3.0, Color(1.0, 0.9, 0.4, 0.12 * a * tw))
				_view.draw_circle(pos, 1.1, Color(1.0, 0.95, 0.6, 0.85 * a * tw))
			"ember":
				var ep := pos + Vector2(sin(_t * 4.0 + float(p["ph"])) * 3.0, 0)
				_view.draw_circle(ep, 2.6, Color(1.0, 0.5, 0.1, 0.15 * a))
				_view.draw_circle(ep, 1.0, Color(1.0, 0.75, 0.3, a))
			"mote":
				_view.draw_circle(pos + Vector2(sin(_t + float(p["ph"])) * 6.0, 0), 1.3, Color(1.0, 0.92, 0.65, 0.7 * a))
			"shard":
				var s: float = p["s"]
				var r: float = p["r"]
				var pts := PackedVector2Array([pos + Vector2(cos(r), sin(r)) * s, pos + Vector2(cos(r + 2.3), sin(r + 2.3)) * s * 0.5,
					pos + Vector2(cos(r + 3.6), sin(r + 3.6)) * s * 0.7])
				_view.draw_colored_polygon(pts, Color(0.62, 0.9, 1.0, 1.0 - k))
				_view.draw_circle(pos, s * 1.4, Color(0.6, 0.9, 1.0, 0.12 * (1.0 - k)))
			"spark":
				_view.draw_circle(pos, 1.6, Color(p["c"], 1.0 - k))
	# letterbox + flash + fade
	if _stage == "intro" or _stage == "outro":
		var bar := f.y * 0.115
		_view.draw_rect(Rect2(0, 0, f.x, bar), Color(0, 0, 0, 0.92))
		_view.draw_rect(Rect2(0, f.y - bar * 1.25, f.x, bar * 1.25), Color(0, 0, 0, 0.92))
		# subtitle plate: a soft gilded band behind the narration
		var sp := Rect2(f.x * 0.06, f.y - bar * 1.25 + 2.0, f.x * 0.88, bar * 1.25 - 12.0)
		UISkin.fill(ci, sp, 4, Color(0.08, 0.05, 0.03, 0.55), Color(0.02, 0.01, 0.01, 0.7))
		_view.draw_line(Vector2(sp.position.x + 10, sp.position.y), Vector2(sp.end.x - 10, sp.position.y), Color("#E8C27A", 0.5), 1.0)
		UISkin.diamond(ci, Vector2(f.x / 2.0, sp.position.y), 2.5)
		# beat dots
		for i in BEATS.size():
			var c := Vector2(f.x / 2.0 + (i - 2) * 12.0, f.y - 7.0)
			_view.draw_circle(c, 2.4 if i == _beat else 1.8, Color("#F2CB7A") if i == _beat else Color(1, 1, 1, 0.25))
	if _flash > 0.0:
		_view.draw_rect(Rect2(Vector2.ZERO, f), Color(1, 0.97, 0.9, _flash))
	if _fade > 0.0:
		_view.draw_rect(Rect2(Vector2.ZERO, f), Color(0, 0, 0, _fade))


func _draw_camp() -> void:
	var f := _frame.size
	var ci := _view.get_canvas_item()
	# night forest: the day panorama pushed to moonlight
	_scene("forest", 0.5 + 0.5 * sin(_t * 0.05), 1.06, Color(0.32, 0.38, 0.62))
	UISkin.fill(ci, Rect2(0, 0, f.x, f.y * 0.55), 0, Color(0.02, 0.03, 0.10, 0.65), Color(0.02, 0.03, 0.1, 0.0))
	# moon
	var mc := Vector2(f.x * 0.82, f.y * 0.16)
	for i in 5:
		_view.draw_circle(mc, 14.0 + i * 9.0, Color(0.75, 0.82, 1.0, 0.035))
	_view.draw_circle(mc, 12.0, Color("#E8EEFF"))
	_view.draw_circle(mc + Vector2(3, -2), 10.5, Color(0.86, 0.9, 1.0, 0.5))
	# campfire light pool
	var fc := Vector2(f.x * 0.5, f.y * 0.85)
	var flick := 0.85 + 0.15 * sin(_t * 11.0) * sin(_t * 6.7)
	for i in 7:
		var r := (f.y * 0.55) * (1.0 - i / 7.0) * flick
		_view.draw_set_transform(fc, 0.0, Vector2(1.0, 0.45))
		_view.draw_circle(Vector2.ZERO, r, Color(1.0, 0.55, 0.2, 0.045))
		_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_campfire(fc, f.y * 0.09)
	_vignette(Color(0, 0, 0), 1.0)


func _campfire(c: Vector2, s: float) -> void:
	var ci := _view.get_canvas_item()
	# stones and crossed logs
	for i in 7:
		var ang := PI + i * PI / 6.0
		_view.draw_circle(c + Vector2(cos(ang) * s * 0.95, s * 0.12 + sin(ang) * s * 0.1), s * 0.16, Color("#4A4642"))
	for d in [-1.0, 1.0]:
		var p0 := c + Vector2(-s * 0.8 * d, s * 0.1)
		var p1 := c + Vector2(s * 0.6 * d, -s * 0.18)
		_view.draw_line(p0, p1, Color("#2A190E"), s * 0.26, true)
		_view.draw_line(p0, p1, Color("#6B4429"), s * 0.18, true)
	# flame tongues: back (red) to front (yellow-white)
	var layers := [[Color("#C9301A"), 1.25, 7], [Color("#FF6A1F"), 1.0, 6], [Color("#FFB23A"), 0.72, 5], [Color("#FFF2B0"), 0.42, 3]]
	for li in layers.size():
		var L: Array = layers[li]
		var col: Color = L[0]
		var hk: float = L[1]
		var n: int = L[2]
		for j in n:
			var fx: float = (float(j) / maxf(1.0, n - 1.0) - 0.5) * s * 0.9 * hk
			var ph := j * 1.9 + li * 0.7
			var h := s * 1.3 * hk * (0.7 + 0.3 * sin(_t * (7.0 + j) + ph)) * (1.0 - absf(fx) / (s * 0.75))
			var w := s * 0.22 * hk
			var sway := sin(_t * 5.0 + ph) * s * 0.12
			var base := c + Vector2(fx, 0)
			var pts := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.6, -h * 0.5), base + Vector2(sway, -h),
				base + Vector2(w * 0.6, -h * 0.55), base + Vector2(w, 0)])
			UISkin.poly(ci, pts, Color(col, 0.0), Color(col, 0.95))
	_view.draw_circle(c + Vector2(0, -s * 0.2), s * 0.35, Color(1.0, 0.95, 0.7, 0.35))


func _draw_logo() -> void:
	if _stage != "title":
		return
	var cx := _frame.position.x + _frame.size.x / 2.0
	var sz := int(clampf(_frame.size.y * 0.17, 30.0, 80.0))
	var f := UITheme.font_big
	var t1 := "IDLE PARTY"
	var w := f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var pos := Vector2(cx - w / 2.0, _frame.position.y + _frame.size.y * 0.76)
	var a := clampf((_t - 0.3) * 0.9, 0.0, 1.0)
	var ci := _logo.get_canvas_item()
	# flames licking up behind the letters
	for i in 18:
		var fx := pos.x - sz * 0.25 + (w + sz * 0.5) * i / 17.0
		var ph := i * 1.7
		var h := sz * (0.55 + 0.35 * sin(_t * (5.0 + i % 4) + ph)) * (1.0 - absf(float(i) / 17.0 - 0.5) * 0.9)
		var fw := sz * 0.22
		var sway := sin(_t * 4.0 + ph) * sz * 0.08
		var base := Vector2(fx, pos.y - sz * 0.45)
		for layer in 2:
			var k := 1.0 - layer * 0.45
			var pts := PackedVector2Array([base + Vector2(-fw * k, 0), base + Vector2(sway, -h * k), base + Vector2(fw * k, 0)])
			var col: Color = [Color("#E03A12"), Color("#FFB23A")][layer]
			UISkin.poly(ci, pts, Color(col, 0.0), Color(col, 0.75 * a))
	# thick dark rim, red, orange, then the golden face with a light top edge
	_logo.draw_string_outline(f, pos + Vector2(0, sz * 0.06), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.32), Color(0, 0, 0, 0.75 * a))
	_logo.draw_string_outline(f, pos, t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.24), Color("#2A0804", a))
	_logo.draw_string_outline(f, pos, t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.15), Color("#B01E10", a))
	_logo.draw_string_outline(f, pos, t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.07), Color("#FF7A1A", a))
	_logo.draw_string(f, pos, t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("#FFB93A", a))
	_logo.draw_string(f, pos + Vector2(0, -sz * 0.05), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(1.0, 0.95, 0.6, 0.55 * a))
	var shine := fmod(_t * 0.35, 1.6) - 0.3
	if shine > 0.0 and shine < 1.0:
		_logo.draw_string(f, pos + Vector2(0, -sz * 0.08), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(1, 1, 0.9, 0.25 * a * sin(shine * PI)))
	# subtitle ribbon
	var t2 := "DESKTOP LEGENDS"
	var s2 := int(sz * 0.3)
	var w2 := UITheme.font_title.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x
	var p2 := Vector2(cx - w2 / 2.0, pos.y + s2 * 1.45)
	var rb := Rect2(cx - w2 / 2.0 - 16, p2.y - s2 * 0.95, w2 + 32, s2 * 1.3)
	UISkin.fill(ci, rb, 3, Color(0.35, 0.06, 0.05, 0.9 * a), Color(0.15, 0.02, 0.02, 0.9 * a))
	UISkin.stroke(ci, rb, 3, Color(0.9, 0.7, 0.4, 0.8 * a), 1.0)
	_logo.draw_string_outline(UITheme.font_title, p2, t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, 4, Color(0, 0, 0, 0.85 * a))
	_logo.draw_string(UITheme.font_title, p2, t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#F8E6BE", a))
	UISkin.diamond(ci, Vector2(rb.position.x - 4, rb.get_center().y), 3.0)
	UISkin.diamond(ci, Vector2(rb.end.x + 4, rb.get_center().y), 3.0)


# ------------------------------------------------------------------ key art poster
## White silhouette of an illustration (alpha kept): drawn tinted behind a hero as a rim light.
func _silhouette(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	for i in range(0, data.size(), 4):
		data[i] = 255
		data[i + 1] = 255
		data[i + 2] = 255
	img = Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(img)


func _make_bolt() -> PackedVector2Array:
	var f := _frame.size
	var pts := PackedVector2Array()
	var p := Vector2(f.x * _rng.randf_range(0.1, 0.9), -4.0)
	pts.append(p)
	while p.y < f.y * 0.55:
		p += Vector2(_rng.randf_range(-22, 22), _rng.randf_range(14, 30))
		pts.append(p)
	return pts


func _draw_poster() -> void:
	var f := _frame.size
	var ci := _view.get_canvas_item()
	var flash := _bolt_life / 0.35
	# stormy sky over a dark forest, pushed to green-teal like an old painting
	_scene("forest", 0.5 + 0.5 * sin(_t * 0.04), 1.08, Color(0.22, 0.34, 0.30).lerp(Color(0.6, 0.8, 0.8), flash * 0.5))
	UISkin.fill(ci, Rect2(0, 0, f.x, f.y * 0.6), 0, Color(0.02, 0.06, 0.05, 0.75), Color(0.02, 0.06, 0.05, 0.0))
	# drifting cloud bands
	for i in 5:
		var cx := fmod(_t * (6.0 + i * 2.0) + i * 140.0, f.x + 240.0) - 120.0
		_view.draw_set_transform(Vector2(cx, f.y * (0.12 + i * 0.07)), 0.0, Vector2(1.0, 0.22))
		_view.draw_circle(Vector2.ZERO, 120.0 + i * 20.0, Color(0.55, 0.7, 0.65, 0.05))
		_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# lightning
	if _bolt_life > 0.0 and _bolt.size() > 1:
		_view.draw_rect(Rect2(Vector2.ZERO, f), Color(0.7, 0.9, 1.0, 0.18 * flash))
		_view.draw_polyline(_bolt, Color(0.6, 0.85, 1.0, 0.35 * flash), 5.0, true)
		_view.draw_polyline(_bolt, Color(1, 1, 1, 0.9 * flash), 1.6, true)
	# god rays slanting in from the upper left, slowly breathing
	for i in 6:
		var x0 := f.x * (0.08 + i * 0.13)
		var wob := 0.5 + 0.5 * sin(_t * (0.35 + i * 0.07) + i * 1.7)
		var wtop := f.x * (0.018 + 0.01 * (i % 3))
		var ray := PackedVector2Array([Vector2(x0 - wtop, -4), Vector2(x0 + wtop, -4),
			Vector2(x0 + f.x * 0.20 + wtop * 3.0, f.y * 0.82), Vector2(x0 + f.x * 0.20 - wtop * 3.0, f.y * 0.82)])
		var rc := Color(0.85, 1.0, 0.9, 0.06 * wob + 0.03 * flash)
		_view.draw_polygon(ray, PackedColorArray([rc, rc, Color(rc, 0.0), Color(rc, 0.0)]))
	# heroes: back row darker, each with a warm / cool rim light; a slow breathing parallax
	for h in POSTER:
		var id := str(h[0])
		var tex: Texture2D = _tex.get("poster_" + id)
		if tex == null:
			continue
		var back: bool = h[4]
		var hh: float = f.y * float(h[2])
		var bob := sin(_t * 0.9 + float(h[1]) * 9.0) * f.y * 0.006
		var foot := Vector2(f.x * float(h[1]) + sin(_t * 0.3) * f.x * (0.004 if back else 0.008), f.y * float(h[3]) + bob)
		var sil: Texture2D = _tex.get("sil_" + id)
		var rim := Color(0.55, 0.95, 0.85, 0.5) if back else Color(1.0, 0.75, 0.4, 0.6)
		if sil:
			for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(-1.5, -1.5), Vector2(1.5, -1.5)]:
				_figure(sil, foot + o, hh, rim.a * (0.6 + 0.4 * flash), false, Color(rim.r, rim.g, rim.b))
		_figure(tex, foot, hh, 1.0, false, Color(0.62, 0.7, 0.72) if back else Color(1, 1, 1))
	# ground fog and a dark floor so the logo reads
	UISkin.fill(ci, Rect2(0, f.y * 0.55, f.x, f.y * 0.45), 0, Color(0.02, 0.03, 0.03, 0.0), Color(0.02, 0.02, 0.02, 0.92))
	for i in 4:
		var fx := fmod(_t * 10.0 * (i + 1) + i * 200.0, f.x + 300.0) - 150.0
		_view.draw_set_transform(Vector2(fx, f.y * (0.78 + i * 0.04)), 0.0, Vector2(1.0, 0.18))
		_view.draw_circle(Vector2.ZERO, 160.0, Color(0.7, 0.85, 0.8, 0.045))
		_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_vignette(Color(0, 0, 0), 1.0)
	# embers drifting up through the whole poster (stateless: position is a function of time)
	for i in 34:
		var sp := 0.6 + fmod(i * 0.37, 0.9)
		var ex := fmod(i * 97.3 + _t * 7.0 * sp + sin(_t * 0.8 + i) * 14.0, f.x + 20.0) - 10.0
		var ey := f.y - fmod(i * 53.1 + _t * 18.0 * sp, f.y * 1.1)
		var fl := 0.5 + 0.5 * sin(_t * (3.0 + i % 4) + i)
		var er := maxf(0.8, f.y * 0.0055) * (0.7 + 0.5 * fmod(i * 0.61, 1.0))
		_view.draw_circle(Vector2(ex, ey), er * 2.6, Color(1.0, 0.55, 0.2, 0.16 * fl))
		_view.draw_circle(Vector2(ex, ey), er, Color(1.0, 0.82, 0.45, 0.9 * fl))


func _draw_beat(b: int) -> void:
	var f := _frame.size
	var e := _bt / BEAT_LEN
	match b:
		0:
			# the World Crystal over the sun temple
			_scene("temple", 0.2 + e * 0.5, 1.0 + e * 0.08, Color(1.0, 0.95, 0.85))
			_crystal(Vector2(f.x * 0.5, f.y * 0.4), f.y * 0.17, 1.0)
			_vignette(Color(0.1, 0.05, 0.0), 0.8)
		1:
			# Morvath shatters it
			_scene("throne", 0.7 - e * 0.4, 1.04 + e * 0.05, Color(0.85, 0.55, 0.55))
			var ci := _view.get_canvas_item()
			UISkin.fill(ci, Rect2(Vector2.ZERO, f), 0, Color(0.25, 0.0, 0.05, 0.25), Color(0.05, 0.0, 0.0, 0.55))
			# Morvath strides in and stays whole inside the frame, above the subtitle band
			var mt: Texture2D = _tex.get("morvath")
			var mh := f.y * 0.7
			var mw := (mt.get_width() * mh / float(mt.get_height())) if mt else 0.0
			var mx := lerpf(f.x + mw * 0.6, f.x - mw * 0.5 - f.x * 0.04, clampf(_bt / 1.6, 0.0, 1.0))
			_figure(mt, Vector2(mx, f.y * 0.86), mh, 1.0, true, Color(1.0, 0.8, 0.8))
			if _bt < 2.0:
				_crystal(Vector2(f.x * 0.3, f.y * 0.42), f.y * 0.14, 1.0, _bt * 0.5)
			_vignette(Color(0.3, 0.0, 0.0), 1.0)
		2:
			# the shards fall on four realms; their monsters rise
			var keys := ["meadow", "snow", "desert", "ash"]
			var bosses := ["goblin_king", "ice_witch", "pharaoh", "demon_hunter"]
			var sw := f.x / 4.0
			for i in 4:
				var appear := clampf((_bt - i * 0.35) / 0.7, 0.0, 1.0)
				var r := Rect2(i * sw, f.y * (1.0 - appear) * -0.15, sw, f.y)
				_scene(keys[i], 0.3 + 0.1 * i + e * 0.2, 1.0, Color(0.85, 0.8, 0.85), appear, Rect2(r.position, Vector2(sw + 1, f.y)))
				var rise := clampf((_bt - 1.4 - i * 0.3) / 0.9, 0.0, 1.0)
				var tex: Texture2D = _tex.get("boss_" + bosses[i])
				# each boss fits its own column, feet above the subtitle band
				var bh := f.y * 0.46
				if tex:
					bh = minf(bh, sw * 0.9 * tex.get_height() / float(tex.get_width()))
				_figure(tex, Vector2(i * sw + sw * 0.5, f.y * (0.84 + (1.0 - rise) * 0.4)), bh, rise, true, Color(0.9, 0.75, 0.75))
				# falling shard streak
				var st := clampf((_bt - 0.4 - i * 0.35) / 0.8, 0.0, 1.0)
				if st > 0.0 and st < 1.0:
					var p := Vector2(i * sw + sw * 0.5, lerpf(-10.0, f.y * 0.55, st))
					_view.draw_line(p - Vector2(0, 40), p, Color(0.6, 0.9, 1.0, 0.6), 3.0, true)
					_view.draw_circle(p, 4.0, Color(0.8, 0.95, 1.0))
				if i > 0:
					_view.draw_line(Vector2(i * sw, 0), Vector2(i * sw, f.y), Color(0, 0, 0, 0.85), 3.0)
			_vignette(Color(0, 0, 0), 0.9)
		3, 4:
			# Stonebridge: the empty guild hall, then the Wandering Guild
			var warm := 1.0 if b == 4 else 0.85
			_scene("town", 0.15 + e * 0.35 + (0.35 if b == 4 else 0.0), 1.03, Color(warm, warm * 0.95, warm * 0.85))
			var founded := b == 4 and _bt > 1.4
			_sign(Vector2(f.x * 0.5, f.y * 0.2), f.y * 0.2, DataDB.t("guild_sign") if founded else DataDB.t("for_sale"), founded)
			if b == 4:
				var cast := [["lyra", -0.3], ["kael", -0.16], ["pip", 0.16], ["bjorn", 0.3]]
				for i in cast.size():
					var a := clampf((_bt - 1.6 - i * 0.25) / 0.6, 0.0, 1.0)
					var tex2: Texture2D = _tex.get("hero_" + str(cast[i][0]))
					_figure(tex2, Vector2(f.x * (0.5 + float(cast[i][1])), f.y * (0.86 + (1.0 - a) * 0.08)), f.y * 0.56, a, float(cast[i][1]) > 0.0)
			_vignette(Color(0, 0, 0), 0.7)


func _crystal(c: Vector2, s: float, a: float, crack := 0.0) -> void:
	var ci := _view.get_canvas_item()
	var pulse := 0.85 + 0.15 * sin(_t * 2.4)
	for i in 8:
		_view.draw_circle(c, s * (2.4 - i * 0.25) * pulse, Color(0.55, 0.85, 1.0, 0.04 * a))
	# slow light rays
	for i in 10:
		var ang := _t * 0.15 + i * TAU / 10.0
		var d := Vector2(cos(ang), sin(ang))
		var n := Vector2(-d.y, d.x)
		var pts := PackedVector2Array([c, c + d * s * 3.2 + n * s * 0.18, c + d * s * 3.2 - n * s * 0.18])
		_view.draw_colored_polygon(pts, Color(0.75, 0.92, 1.0, 0.06 * a))
	var top := c + Vector2(0, -s * 1.25)
	var bot := c + Vector2(0, s * 1.05)
	var l := c + Vector2(-s * 0.55, -s * 0.1)
	var r := c + Vector2(s * 0.55, -s * 0.1)
	var ml := c + Vector2(-s * 0.2, s * 0.05)
	UISkin.poly(ci, PackedVector2Array([top, l, ml]), Color(0.85, 0.97, 1.0, a), Color(0.35, 0.7, 0.95, a))
	UISkin.poly(ci, PackedVector2Array([top, ml, r]), Color(0.65, 0.9, 1.0, a), Color(0.2, 0.55, 0.9, a))
	UISkin.poly(ci, PackedVector2Array([l, bot, ml]), Color(0.4, 0.75, 0.98, a), Color(0.15, 0.4, 0.8, a))
	UISkin.poly(ci, PackedVector2Array([ml, bot, r]), Color(0.3, 0.62, 0.95, a), Color(0.1, 0.3, 0.7, a))
	var outline := PackedVector2Array([top, r, bot, l, top])
	_view.draw_polyline(outline, Color(1, 1, 1, 0.8 * a), 1.5, true)
	if crack > 0.0:
		var rr := RandomNumberGenerator.new()
		rr.seed = 7
		for i in int(3 + crack * 9):
			var p0 := c + Vector2(rr.randf_range(-0.3, 0.3), rr.randf_range(-0.6, 0.6)) * s
			var p1 := p0 + Vector2(rr.randf_range(-0.5, 0.5), rr.randf_range(-0.5, 0.5)) * s * crack
			_view.draw_line(p0, p1, Color(0.1, 0.0, 0.1, 0.9), 2.0, true)


func _sign(c: Vector2, s: float, txt: String, glow: bool) -> void:
	var ci := _view.get_canvas_item()
	var swing := sin(_t * 1.6) * 0.03
	var w := s * 2.4
	var h := s * 0.62
	_view.draw_set_transform(c, swing, Vector2.ONE)
	_view.draw_line(Vector2(-w * 0.35, -h * 1.1), Vector2(-w * 0.3, -h * 0.5), Color("#2A2A2E"), 2.0, true)
	_view.draw_line(Vector2(w * 0.35, -h * 1.1), Vector2(w * 0.3, -h * 0.5), Color("#2A2A2E"), 2.0, true)
	var r := Rect2(-w / 2.0, -h / 2.0, w, h)
	if glow:
		for i in 6:
			UISkin.fill(ci, r.grow(4.0 + i * 4.0), 8, Color(1.0, 0.8, 0.35, 0.05), Color(1.0, 0.8, 0.35, 0.05))
	UISkin.fill(ci, r, 4, Color("#8A5A32"), Color("#4E3019"))
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.9), 1.5)
	UISkin.stroke(ci, r.grow(-3.0), 3, Color("#C8913F" if glow else "#6E4A2A"), 1.2)
	for i in 3:
		_view.draw_line(Vector2(-w / 2.0 + 6, -h / 2.0 + h * (0.3 + i * 0.22)), Vector2(w / 2.0 - 6, -h / 2.0 + h * (0.3 + i * 0.22)),
			Color(0, 0, 0, 0.18), 1.0)
	var fs := int(h * 0.42)
	var tw := UITheme.font_title.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp := Vector2(-tw / 2.0, fs * 0.36)
	_view.draw_string_outline(UITheme.font_title, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8))
	_view.draw_string(UITheme.font_title, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFE7A6") if glow else Color("#F2E2C4"))
	for k in [-1.0, 1.0]:
		UISkin.rivet(ci, Vector2(k * (w / 2.0 - 5), -h / 2.0 + 5), 2.0)
		UISkin.rivet(ci, Vector2(k * (w / 2.0 - 5), h / 2.0 - 5), 2.0)
	_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
