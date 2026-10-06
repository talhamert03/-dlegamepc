class_name RecruitReveal
extends Control
## New hero reveal, laid over a panel: a face-down card rises out of the dark with a glow in the hero's
## rarity colour, trembles, flips with a flash and a burst of sparks, and shows the hero's portrait in a
## gilded frame with their name on a ribbon. SSR heroes get a longer, golden build-up with turning rays.
## A click skips ahead to the flip, then closes.

const RCOL := {"R": Color("#B8C0D0"), "SR": Color("#6FA8FF"), "SSR": Color("#FFC94A")}
const CARD := Vector2(96, 140)

var hid := ""
var _rar := "R"
var _col := Color.WHITE
var _tex: Texture2D = null
var _t := 0.0
var _flip_at := 1.25          # seconds until the card turns (SSR waits longer)
var _flipped := false
var _parts: Array = []        # [pos, vel, life, max, size, colour]
var _rng := RandomNumberGenerator.new()
var _closing := false


static func show_over(host: Control, hero_id: String) -> RecruitReveal:
	var r := RecruitReveal.new()
	r.hid = hero_id
	r.size = host.size
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.z_index = 55
	host.add_child(r)
	return r


func _ready() -> void:
	_rng.randomize()
	_rar = Tavern.rarity(hid)
	_col = RCOL.get(_rar, Color.WHITE)
	_tex = SpriteLib.portrait(hid)
	if _rar == "SSR":
		_flip_at = 2.1
	elif _rar == "SR":
		_flip_at = 1.5
	WindowManager.hide_tooltip()
	AudioManager.play("ui_open", 0.0, 0.7)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if not _flipped and _t < _flip_at - 0.3:
			_t = _flip_at - 0.3          # skip the build-up, keep the flip itself
		elif _flipped and _t > _flip_at + 0.5:
			_close()
		accept_event()


func _close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	if not _flipped and _t >= _flip_at:
		_flipped = true
		_burst()
		AudioManager.play("recruit")
		if _rar == "SSR":
			AudioManager.play("loot_legendary", 0.0, 0.9)
	# build-up sparks drifting up behind the card
	if not _flipped and _t > 0.4 and _rng.randf() < (0.6 if _rar == "SSR" else 0.3):
		var c := _center()
		_parts.append([c + Vector2(_rng.randf_range(-60, 60), _rng.randf_range(20, 70)), Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-40, -20)),
			0.0, _rng.randf_range(0.8, 1.6), _rng.randf_range(0.8, 1.6), _col.lightened(0.3)])
	for p in _parts:
		p[2] += delta
		p[0] += p[1] * delta
		p[1] *= 0.97
		p[1].y += 18.0 * delta
	_parts = _parts.filter(func(p): return p[2] < p[3])
	if _t > 9.0 and not _closing:
		_close()
	queue_redraw()


func _center() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.44)


func _burst() -> void:
	var c := _center()
	var n := 70 if _rar == "SSR" else (48 if _rar == "SR" else 30)
	for i in n:
		var a := _rng.randf() * TAU
		var sp := _rng.randf_range(60, 220 if _rar == "SSR" else 160)
		var col: Color = [_col, _col.lightened(0.5), Color("#FFF6D8")][i % 3]
		_parts.append([c, Vector2.from_angle(a) * sp, 0.0, _rng.randf_range(0.6, 1.3), _rng.randf_range(1.0, 2.2), col])


func _draw() -> void:
	var ci := get_canvas_item()
	var fade := clampf(_t / 0.35, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.03, 0.9 * fade))
	var c := _center()
	# turning rays and halo, stronger after the flip and for rarer heroes
	var rays := 0.0
	if _flipped:
		rays = clampf((_t - _flip_at) / 0.4, 0.0, 1.0)
	elif _rar == "SSR":
		rays = clampf((_t - 0.6) / 1.2, 0.0, 0.55)
	if rays > 0.0:
		var nr := 16 if _rar == "SSR" else 12
		for k in nr:
			var a := _t * (0.5 if _rar == "SSR" else 0.3) + k * TAU / nr
			var ln := 170.0 + 20.0 * sin(_t * 2.0 + k)
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.07) * ln, c + Vector2.from_angle(a + 0.07) * ln]),
				Color(_col, 0.10 * rays))
		for k in 6:
			draw_circle(c, 70.0 - k * 10.0, Color(_col, 0.035 * rays))
	# sparks
	for p in _parts:
		var k2: float = 1.0 - float(p[2]) / float(p[3])
		draw_circle(p[0], float(p[4]) * (0.4 + 0.6 * k2), Color(p[5], k2))
	# the card: rises in, trembles, flips (x scale through zero)
	var rise := 1.0 - pow(1.0 - clampf(_t / 0.55, 0.0, 1.0), 3.0)
	var scale := 0.55 + 0.45 * rise
	var pos := c + Vector2(0, 40.0 * (1.0 - rise))
	if not _flipped and _t > 0.6:
		var shake := clampf((_t - 0.6) / (_flip_at - 0.6), 0.0, 1.0)
		pos += Vector2(sin(_t * 60.0), cos(_t * 47.0)) * shake * (2.2 if _rar == "SSR" else 1.2)
	var sx := 1.0
	var front := _flipped
	var ft := _t - _flip_at
	if ft > -0.18 and ft < 0.18:
		sx = absf(ft) / 0.18          # thin edge at the moment of the turn
		front = ft >= 0.0
	draw_set_transform(pos, 0.0, Vector2(scale * maxf(sx, 0.04), scale))
	var r := Rect2(-CARD / 2.0, CARD)
	# glow behind the card
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	for k in 4:
		UISkin.fill(ci, r.grow(3.0 + k * 3.0), 8, Color(_col, (0.10 + 0.08 * pulse) * (1.0 - k * 0.22) * rise), Color(_col, 0.05 * rise))
	if front:
		_draw_front(ci, r)
	else:
		_draw_back(ci, r)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# flash at the flip
	if ft > 0.0 and ft < 0.35:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.97, 0.88, 0.55 * (1.0 - ft / 0.35)))
	# caption
	if _flipped and ft > 0.25:
		var a2 := clampf((ft - 0.25) / 0.4, 0.0, 1.0)
		var f := UITheme.font_title
		var nm := DataDB.t("recruit_joined", {"name": str(DataDB.hero_def(hid).get("name", hid))})
		var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var y := c.y + CARD.y * 0.5 + 22
		draw_string_outline(f, Vector2(c.x - w / 2.0, y), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0, 0, 0, a2))
		draw_string(f, Vector2(c.x - w / 2.0, y), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(_col.lightened(0.35), a2))
		if ft > 0.8:
			var hint := DataDB.t("click_continue")
			var fb := UITheme.font_body
			var hw := fb.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			draw_string(fb, Vector2(c.x - hw / 2.0, size.y - 8), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.45 + 0.2 * sin(_t * 4.0)))


## Card back: dark velvet, gilded double border, a guild crest in the middle and rarity-coloured gems.
func _draw_back(ci: RID, r: Rect2) -> void:
	UISkin.fill(ci, r, 6, Color("#3A1E3A"), Color("#140A16"))
	UISkin.stroke(ci, r, 6, UISkin.OUTLINE, 1.6)
	UISkin.stroke(ci, r.grow(-3.0), 5, Color(UISkin.BRONZE_HI, 0.9), 1.2)
	UISkin.stroke(ci, r.grow(-6.0), 4, Color(UISkin.BRONZE, 0.5), 0.8)
	# diamond lattice
	var x := r.position.x + 10.0
	while x < r.end.x - 10.0:
		draw_line(Vector2(x, r.position.y + 10), Vector2(x + 18, r.end.y - 10), Color(UISkin.BRONZE_HI, 0.06), 0.8)
		draw_line(Vector2(x + 18, r.position.y + 10), Vector2(x, r.end.y - 10), Color(UISkin.BRONZE_HI, 0.06), 0.8)
		x += 12.0
	# crest
	var c := r.get_center()
	var sh := PackedVector2Array([c + Vector2(-20, -22), c + Vector2(20, -22), c + Vector2(20, 4), c + Vector2(0, 26), c + Vector2(-20, 4)])
	UISkin.poly(ci, sh, Color("#6A2A5A"), Color("#2A0E26"))
	var shc := sh.duplicate()
	shc.append(sh[0])
	draw_polyline(shc, UISkin.BRONZE_HI, 1.6, true)
	var cr := UITheme.icon("crown")
	if cr:
		draw_texture_rect(cr, Rect2(c - Vector2(10, 14), Vector2(20, 20)), false, Color("#FFD36A"))
	var q := "?"
	var f := UITheme.font_title
	draw_string(f, c + Vector2(-4, 22), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(_col, 0.9))
	for p in [r.position + Vector2(10, 10), Vector2(r.end.x - 10, r.position.y + 10), r.end - Vector2(10, 10), Vector2(r.position.x + 10, r.end.y - 10)]:
		UISkin.circle(ci, p, 3.2, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, p, 2.6, _col.lightened(0.3), _col.darkened(0.4))


## Card front: the hero's portrait in an arched gilded frame, rarity tag, name ribbon and class.
func _draw_front(ci: RID, r: Rect2) -> void:
	var dark := _col.darkened(0.7)
	UISkin.fill(ci, r, 6, _col.darkened(0.35), dark)
	if _tex:
		var inner := r.grow(-5.0)
		var h := inner.size.y - 18.0
		var w := _tex.get_width() * h / float(_tex.get_height())
		var src := Rect2(Vector2.ZERO, Vector2(_tex.get_width(), _tex.get_height()))
		if w > inner.size.x:
			# crop the sides so the portrait fills the frame
			var keep := inner.size.x / w
			src = Rect2(Vector2(_tex.get_width() * (1.0 - keep) / 2.0, 0), Vector2(_tex.get_width() * keep, _tex.get_height()))
			w = inner.size.x
		draw_texture_rect_region(_tex, Rect2(Vector2(r.get_center().x - w / 2.0, inner.position.y), Vector2(w, h)), src)
		UISkin.fill(ci, Rect2(inner.position + Vector2(0, h - 22), Vector2(inner.size.x, 22)), 0, Color(dark, 0.0), Color(dark, 0.95))
	UISkin.stroke(ci, r, 6, UISkin.OUTLINE, 1.6)
	UISkin.stroke(ci, r.grow(-2.5), 5, _col.lightened(0.25), 1.6)
	UISkin.stroke(ci, r.grow(-5.0), 4, Color(UISkin.BRONZE_HI, 0.7), 0.8)
	# rarity tag
	var tag := Rect2(r.position + Vector2(6, 6), Vector2(24 if _rar == "SSR" else 18, 11))
	UISkin.fill(ci, tag, 2, _col.lightened(0.2), _col.darkened(0.3))
	UISkin.stroke(ci, tag, 2, UISkin.OUTLINE, 1.0)
	draw_string(UITheme.font_body, tag.position + Vector2(3, 8.6), _rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#1A1208"))
	# name ribbon and class
	var d := DataDB.hero_def(hid)
	var nm := str(d.get("name", hid))
	var rb := Rect2(Vector2(r.position.x + 4, r.end.y - 26), Vector2(r.size.x - 8, 13))
	UISkin.ribbon(ci, rb)
	var f := UITheme.font_title
	var fs := 9
	while fs > 6 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rb.size.x - 10:
		fs -= 1
	var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(rb.get_center().x - tw / 2.0, rb.get_center().y + fs * 0.36), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFE7A8"))
	var cls := DataDB.tx(DataDB.class_def(str(d.get("class", ""))).get("name", {}))
	var fb := UITheme.font_body
	var cw := fb.get_string_size(cls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(fb, Vector2(r.get_center().x - cw / 2.0, r.end.y - 4), cls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#EADFC8"))
