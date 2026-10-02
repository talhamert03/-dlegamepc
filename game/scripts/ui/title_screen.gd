class_name TitleScreen
extends Control
## First-launch title screen + 5-panel intro story, then the window shrinks into the strip.

signal finished

const SIZE := Vector2i(240, 135)

var _t := 0.0
var _stage := "title"     # title | intro | done
var _slide := 0
var _slide_t := 0.0
var _logo_y := -40.0
var _fire_t := 0.0
var _heroes: Array = []
var _buttons: VBoxContainer
var _text: Label
var _skip: Button
var _rng := RandomNumberGenerator.new()
var _sky: Texture2D
var _mid: Texture2D
var _ground: Texture2D

const SLIDES := ["intro_1", "intro_2", "intro_3", "intro_4", "intro_5"]


func _ready() -> void:
	size = Vector2(SIZE)
	theme = UITheme.theme
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sky = load("res://assets/backgrounds/dark_forest/sky.png")
	_mid = load("res://assets/backgrounds/dark_forest/mid.png")
	_ground = load("res://assets/backgrounds/forest/ground.png")
	var xs := [36.0, 66.0, 214.0]
	var ids := ["lyra", "kael", "pip"]
	for i in 3:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = SpriteLib.frames_for("hero", ids[i])
		s.centered = false
		s.offset = Vector2(-28, -54)
		s.position = Vector2(xs[i], 122)
		s.flip_h = i == 2
		s.play("idle")
		add_child(s)
		_heroes.append(s)
	_buttons = W.vbox(2)
	_buttons.position = Vector2(94, 62)
	add_child(_buttons)
	_buttons.add_child(UITheme.button(DataDB.t("title_new"), "orange", _start_intro, Vector2(72, 13)))
	_buttons.add_child(UITheme.button(DataDB.t("title_settings"), "brown", func(): WindowManager.toggle_panel("settings"), Vector2(72, 13)))
	_buttons.add_child(UITheme.button(DataDB.t("tray_quit"), "red", func(): get_tree().quit(), Vector2(72, 13)))
	_buttons.modulate.a = 0.0
	_text = UITheme.label("", UITheme.C_TEXT, 13, UITheme.font_title)
	_text.position = Vector2(10, 92)
	_text.size = Vector2(220, 40)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_outline_color", Color("#140E10"))
	_text.add_theme_constant_override("outline_size", 2)
	_text.visible = false
	add_child(_text)
	_skip = UITheme.button(DataDB.t("skip"), "gray", _finish, Vector2(30, 11))
	_skip.position = Vector2(206, 2)
	_skip.visible = false
	add_child(_skip)
	AudioManager.play_music("title")


func _process(delta: float) -> void:
	_t += delta
	_fire_t += delta
	_logo_y = lerp(_logo_y, 14.0, min(1.0, delta * 4.0))
	if _t > 0.8:
		_buttons.modulate.a = min(1.0, _buttons.modulate.a + delta * 2.0)
	if _stage == "intro":
		_slide_t += delta
		if _slide_t > 3.6:
			_next_slide()
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if _stage == "intro" and ev is InputEventMouseButton and ev.pressed:
		_next_slide()


func _draw() -> void:
	if _stage == "title":
		_draw_scene()
		_draw_logo()
	else:
		_draw_slide()


func _draw_scene() -> void:
	if _sky:
		draw_texture_rect_region(_sky, Rect2(0, 0, 240, 84), Rect2(0, 0, 240, 84))
		draw_texture_rect_region(_sky, Rect2(0, 84, 240, 51), Rect2(0, 60, 240, 24))
	if _mid:
		draw_texture_rect_region(_mid, Rect2(0, 50, 240, 84), Rect2(_t * 3.0, 0, 240, 84))
	draw_rect(Rect2(0, 118, 240, 17), Color("#2E3B2A"))
	draw_rect(Rect2(0, 118, 240, 2), Color("#3F5236"))
	# campfire with flickering light
	var fx := 186.0
	var fy := 121.0
	var flick := 0.8 + 0.2 * sin(_fire_t * 13.0) * sin(_fire_t * 7.3)
	draw_circle(Vector2(fx, fy - 2), 26.0 * flick, Color(1.0, 0.55, 0.2, 0.08))
	draw_circle(Vector2(fx, fy - 2), 14.0 * flick, Color(1.0, 0.6, 0.25, 0.10))
	draw_rect(Rect2(fx - 6, fy - 1, 12, 2), Color("#5A3E2E"))
	draw_rect(Rect2(fx - 4, fy - 2, 8, 1), Color("#7A5A3A"))
	for i in 5:
		var h: float = 4.0 + 3.0 * abs(sin(_fire_t * (5.0 + i) + i))
		var c := Color("#FF7A33") if i % 2 == 0 else Color("#FFD84A")
		draw_rect(Rect2(fx - 4 + i * 2, fy - 2 - h, 2, h), c)
	for i in 4:
		var sp := fmod(_fire_t * 18.0 + i * 13.0, 30.0)
		draw_rect(Rect2(fx - 2 + sin(_fire_t * 3 + i) * 4, fy - 8 - sp, 1, 1), Color(1, 0.8, 0.4, 1.0 - sp / 30.0))


func _draw_logo() -> void:
	var f := UITheme.font_big
	var t1 := "IDLE PARTY"
	var w := f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var x := (240 - w) / 2.0
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 2)]:
		draw_string(f, Vector2(x, _logo_y + 16) + o, t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#140E10"))
	draw_string(f, Vector2(x, _logo_y + 16), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#FF8A3D"))
	draw_string(f, Vector2(x, _logo_y + 15), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#FFB36A"))
	var t2 := "Desktop Legends"
	var w2 := UITheme.font_title.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(UITheme.font_title, Vector2((240 - w2) / 2.0 + 1, _logo_y + 31), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#140E10"))
	draw_string(UITheme.font_title, Vector2((240 - w2) / 2.0, _logo_y + 30), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#F2E6C9"))


func _draw_slide() -> void:
	var k: float = clamp(_slide_t / 0.6, 0.0, 1.0) * clamp((3.6 - _slide_t) / 0.5, 0.0, 1.0)
	draw_rect(Rect2(0, 0, 240, 135), Color("#100C16"))
	var cx := 120.0
	var cy := 50.0
	match _slide:
		0:
			# glowing world crystal
			for r in range(30, 0, -3):
				draw_circle(Vector2(cx, cy), r, Color(0.5, 0.85, 1.0, 0.03 * k))
			_crystal(cx, cy, 1.0, Color("#9FDFFF"), k)
		1:
			_crystal(cx, cy, 1.0, Color("#9FDFFF"), k)
			var sh := Color(0.1, 0.0, 0.15, 0.85 * k)
			draw_circle(Vector2(cx - 40 + _slide_t * 8, cy - 10), 22, sh)
			draw_rect(Rect2(cx - 50 + _slide_t * 8, cy - 4, 4, 2), Color(1, 0.2, 0.3, k))
			draw_rect(Rect2(cx - 42 + _slide_t * 8, cy - 4, 4, 2), Color(1, 0.2, 0.3, k))
		2:
			for i in 4:
				var a := i * TAU / 4.0 + 0.5
				var d := 10.0 + _slide_t * 18.0
				_crystal(cx + cos(a) * d, cy + sin(a) * d * 0.6, 0.4, Color("#9FDFFF"), k)
		3:
			if _mid:
				draw_texture_rect_region(UITheme.tex("../backgrounds/town/mid"), Rect2(0, 10, 240, 84), Rect2(40, 0, 240, 84), Color(1, 1, 1, k))
			draw_rect(Rect2(cx - 16, cy - 2, 32, 12), Color(0.35, 0.25, 0.18, k))
			draw_string(UITheme.font_small, Vector2(cx - 14, cy + 6), DataDB.t("for_sale"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.7, k))
		4:
			draw_rect(Rect2(cx - 22, cy - 4, 44, 12), Color(0.45, 0.3, 0.2, k))
			draw_string(UITheme.font_small, Vector2(cx - 20, cy + 4), DataDB.t("guild_sign"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.85, 0.4, k))
	_text.modulate.a = k


func _crystal(x: float, y: float, s: float, c: Color, a: float) -> void:
	var pts := PackedVector2Array([Vector2(x, y - 18 * s), Vector2(x + 9 * s, y), Vector2(x, y + 18 * s), Vector2(x - 9 * s, y)])
	draw_colored_polygon(pts, Color(c, a))
	var pts2 := PackedVector2Array([Vector2(x, y - 18 * s), Vector2(x + 9 * s, y), Vector2(x, y)])
	draw_colored_polygon(pts2, Color(1, 1, 1, 0.5 * a))


func _start_intro() -> void:
	_stage = "intro"
	_buttons.visible = false
	for h in _heroes:
		h.visible = false
	_slide = -1
	_skip.visible = true
	_text.visible = true
	_next_slide()


func _next_slide() -> void:
	_slide += 1
	_slide_t = 0.0
	if _slide >= SLIDES.size():
		_finish()
		return
	_text.text = DataDB.t(SLIDES[_slide])


func _finish() -> void:
	if _stage == "done":
		return
	_stage = "done"
	finished.emit()
	queue_free()
