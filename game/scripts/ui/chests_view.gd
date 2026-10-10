class_name ChestsView
extends Control
## Treasure chests: a showcase of the best held chest on a lit pedestal, the shelf of the others, and an
## opening sequence (shake, lid thrown back, light, rewards dealt out as cards).

const SLATE := preload("res://assets/ui_hd/frame/slate.png")

var SHOW_H := 126.0

var _t := 0.0
var _stage: Control
var _shelf: Control
var _rewards: Control
var _name: Label
var _open_btn: Button
var _all_btn: Button
var _hint: Label
var _sel := -1
var _anim := 0.0          # opening timeline (s); < 0 = idle
var _open_kind := ""
var _result: Dictionary = {}
var _queue := 0           # chests left in an "open all" run
var _shake_t := 0.45      # build-up length: rarer chests tremble longer
var _parts: Array = []    # sparks and coins: [pos, vel, age, life, size, colour]
var _rng := RandomNumberGenerator.new()
var _best_x := -1.0       # reward column that gets a light beam (legendary and better)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	SHOW_H = clampf(size.y - 64.0, 80.0, 126.0)
	_build(self)


func _build(c: Control) -> void:
	_anim = -1.0
	var w := c.size.x
	_stage = Control.new()
	_stage.size = Vector2(w, SHOW_H)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.draw.connect(_draw_stage)
	# a click during the build-up throws the lid open at once
	_stage.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and _anim >= 0.0 and _anim < _shake_t:
			_anim = _shake_t)
	c.add_child(_stage)
	_name = UITheme.label("", UITheme.C_TITLE, 11, UITheme.font_title)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_name.add_theme_constant_override("outline_size", 3)
	_name.position = Vector2(0, 2)
	_name.size = Vector2(w, 14)
	c.add_child(_name)
	_rewards = Control.new()
	_rewards.position = Vector2(0, SHOW_H - 31)
	_rewards.size = Vector2(w, 30)
	_rewards.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(_rewards)
	_open_btn = UITheme.button(DataDB.t("chest_open"), "gold", _on_open, Vector2(70, 15))
	c.add_child(_open_btn)
	_open_btn.size = Vector2(70, 15)
	_open_btn.position = Vector2(w / 2.0 - 74, SHOW_H + 2)
	_all_btn = UITheme.button(DataDB.t("chest_open_all"), "brown", _on_open_all, Vector2(70, 15))
	c.add_child(_all_btn)
	_all_btn.size = Vector2(70, 15)
	_all_btn.position = Vector2(w / 2.0 + 4, SHOW_H + 2)
	_shelf = Control.new()
	_shelf.position = Vector2(0, SHOW_H + 21)
	_shelf.size = Vector2(w, c.size.y - SHOW_H - 21)
	_shelf.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(_shelf)
	_hint = UITheme.label(DataDB.t("chest_empty"), UITheme.C_DIM, 8)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(8, 16)
	_hint.size = Vector2(w - 16, 40)
	c.add_child(_hint)
	EventBus.chests_changed.connect(func():
		if _anim < 0.0:
			refresh())
	refresh()


func refresh() -> void:
	if _shelf == null:
		return
	if _sel < 0 or _sel >= GameState.chests.size():
		_sel = Chests.best_index()
	var has := _sel >= 0
	_hint.visible = not has and _result.is_empty()
	_open_btn.disabled = not has or _anim >= 0.0
	_all_btn.disabled = GameState.chests.size() < 2 or _anim >= 0.0
	if _anim < 0.0 and _result.is_empty():
		_name.text = Chests.display_name(str(GameState.chests[_sel]["k"])) if has else ""
		_name.add_theme_color_override("font_color", Chests.color(str(GameState.chests[_sel]["k"])) if has else UITheme.C_TITLE)
	_build_shelf()


## One tile per held chest kind with a count, best first; click picks it for the showcase.
func _build_shelf() -> void:
	for ch in _shelf.get_children():
		ch.queue_free()
	var counts := {}
	var first := {}
	for i in GameState.chests.size():
		var k := str(GameState.chests[i]["k"])
		counts[k] = int(counts.get(k, 0)) + 1
		if not first.has(k):
			first[k] = i
	var kinds: Array = []
	for k in Chests.KINDS:
		if counts.has(k):
			kinds.push_front(k)
	var tw := 40.0
	var x0 := (_shelf.size.x - kinds.size() * (tw + 3.0) + 3.0) / 2.0
	for j in kinds.size():
		var k: String = kinds[j]
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(x0 + j * (tw + 3.0), 2)
		b.size = Vector2(tw, 36)
		b.tooltip_text = Chests.display_name(k)
		var cnt := int(counts[k])
		var sel_kind := _sel >= 0 and str(GameState.chests[_sel]["k"]) == k
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var r := Rect2(Vector2.ZERO, b.size)
			UISkin.well(ci, r)
			if sel_kind or b.is_hovered():
				UISkin.stroke(ci, r.grow(0.6), 3, Color(Chests.color(k), 0.95 if sel_kind else 0.5), 1.2)
				UISkin.fill(ci, r.grow(-1.0), 2, Color(Chests.color(k), 0.14 if sel_kind else 0.07), Color(Chests.color(k), 0.0))
			ChestArt.draw(b, Vector2(r.size.x / 2.0, r.size.y - 6), 24.0, k, 0.0, _t, false)
			if cnt > 1:
				var f := UITheme.font_body
				var s := "x%d" % cnt
				b.draw_string_outline(f, Vector2(r.size.x - 15, 10), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, 0.95))
				b.draw_string(f, Vector2(r.size.x - 15, 10), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_TEXT))
		b.mouse_entered.connect(b.queue_redraw)
		b.mouse_exited.connect(b.queue_redraw)
		b.pressed.connect(func():
			if _anim >= 0.0:
				return
			_result = {}
			_clear_rewards()
			_sel = int(first[k])
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh())
		_shelf.add_child(b)


func _process(delta: float) -> void:
	_t += delta
	if _anim >= 0.0:
		var before := _anim
		_anim += delta
		if before < _shake_t and _anim >= _shake_t:
			_burst()
		if before < _shake_t + 0.1 and _anim >= _shake_t + 0.1:
			_reveal()
		if _anim >= _shake_t + 1.45:
			_anim = -1.0
			if _queue > 0:
				_queue -= 1
				_begin_open()
			else:
				refresh()
	for p in _parts:
		p[2] += delta
		p[0] += p[1] * delta
		p[1].y += 140.0 * delta
	_parts = _parts.filter(func(p): return p[2] < p[3])
	if _stage:
		_stage.queue_redraw()
	if _shelf:
		for b in _shelf.get_children():
			(b as Control).queue_redraw()


func _draw_stage() -> void:
	var ci := _stage.get_canvas_item()
	var w := _stage.size.x
	var r := Rect2(0, 0, w, SHOW_H - 2)
	var kind := _open_kind if _open_kind != "" else (str(GameState.chests[_sel]["k"]) if _sel >= 0 and _sel < GameState.chests.size() else "")
	var col: Color = Chests.color(kind) if kind != "" else Color("#6A5A70")
	# a treasure vault: slate wall, a velvet drape behind the pedestal, a shaft of light from above in the
	# chest's colour and a stone plinth with a gilded edge
	RenderingServer.canvas_item_set_default_texture_filter(ci, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	UISkin.fill(ci, r, 4, Color("#16141A"), Color("#0B0A0D"))
	UISkin._tile(ci, SLATE, r.grow(-1.0), 96.0)
	UISkin.fill(ci, r.grow(-1.0), 3, Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.45))
	var cx := w / 2.0
	var drape := Rect2(cx - SHOW_H * 0.62, 0, SHOW_H * 1.24, SHOW_H * 0.74)
	UISkin.fill(ci, drape, 0, Color("#5A1420"), Color("#2A0810"))
	for k in 7:
		var fx := drape.position.x + drape.size.x * (k + 0.5) / 7.0
		UISkin.line(ci, Vector2(fx, 0), Vector2(fx, drape.end.y), Color(0, 0, 0, 0.28), 2.4)
		UISkin.line(ci, Vector2(fx + 3.0, 0), Vector2(fx + 3.0, drape.end.y), Color(1, 0.6, 0.6, 0.06), 1.4)
	# the drape's edges and hem fall into shadow so it does not read as a flat rectangle
	var cl := Color(0.04, 0.03, 0.05, 0.0)
	var dk := Color(0.04, 0.03, 0.05, 0.85)
	var ew := drape.size.x * 0.16
	RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([drape.position, drape.position + Vector2(ew, 0), Vector2(drape.position.x + ew, drape.end.y), Vector2(drape.position.x, drape.end.y)]), PackedColorArray([dk, cl, cl, dk]))
	RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([Vector2(drape.end.x - ew, 0), Vector2(drape.end.x, 0), drape.end, Vector2(drape.end.x - ew, drape.end.y)]), PackedColorArray([cl, dk, dk, cl]))
	RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([Vector2(drape.position.x, drape.end.y - 10), Vector2(drape.end.x, drape.end.y - 10), drape.end, Vector2(drape.position.x, drape.end.y)]), PackedColorArray([cl, cl, dk, dk]))
	UISkin.line(ci, Vector2(drape.position.x, 1.5), Vector2(drape.end.x, 1.5), Color(UISkin.BRONZE_HI, 0.7), 1.4)
	var shaft := PackedVector2Array([Vector2(cx - 8, 0), Vector2(cx + 8, 0), Vector2(cx + SHOW_H * 0.4, SHOW_H * 0.74), Vector2(cx - SHOW_H * 0.4, SHOW_H * 0.74)])
	var sc := Color(col.lightened(0.4), 0.16)
	RenderingServer.canvas_item_add_polygon(ci, shaft, PackedColorArray([sc, sc, Color(sc, 0.0), Color(sc, 0.0)]))
	for k in 8:
		_stage.draw_circle(Vector2(cx, SHOW_H * 0.49), SHOW_H * 0.55 - k * SHOW_H * 0.06, Color(col, 0.03))
	var cw := clampf(SHOW_H * 0.52, 40.0, 66.0)
	var ped := Rect2(cx - cw * 0.75, SHOW_H * 0.7, cw * 1.5, 9)
	UISkin.fill(ci, Rect2(ped.position + Vector2(0, 2), ped.size), 3, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
	UISkin.fill(ci, ped, 3, Color("#5A5462"), Color("#25222A"))
	UISkin.stroke(ci, ped, 3, Color(0, 0, 0, 0.9), 1.0)
	UISkin.line(ci, Vector2(ped.position.x + 3, ped.position.y + 1), Vector2(ped.end.x - 3, ped.position.y + 1), Color(UISkin.BRONZE_HI, 0.65), 0.9)
	UISkin.line(ci, Vector2(ped.position.x + 6, ped.position.y + 2.6), Vector2(ped.end.x - 6, ped.position.y + 2.6), Color(col, 0.4), 0.8)
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.9), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 3, Color(UISkin.BRONZE, 0.55), 0.8)
	if kind == "":
		# empty pedestal: a faint dashed chest outline waiting for loot
		var bw := cw * 0.9
		var body := Rect2(w / 2.0 - bw / 2.0, SHOW_H * 0.7 - bw * 0.42, bw, bw * 0.42)
		var gc := Color(0.75, 0.65, 0.85, 0.22)
		_stage.draw_dashed_line(body.position, Vector2(body.end.x, body.position.y), gc, 1.0, 3.0)
		_stage.draw_dashed_line(Vector2(body.position.x, body.position.y), Vector2(body.position.x, body.end.y), gc, 1.0, 3.0)
		_stage.draw_dashed_line(Vector2(body.end.x, body.position.y), body.end, gc, 1.0, 3.0)
		var lid := PackedVector2Array()
		for k in 13:
			var a := PI + PI * k / 12.0
			lid.append(Vector2(w / 2.0 + cos(a) * bw / 2.0, body.position.y + sin(a) * bw * 0.22))
		for k in range(0, 12, 2):
			_stage.draw_line(lid[k], lid[k + 1], gc, 1.0, true)
		return
	var foot := Vector2(w / 2.0, SHOW_H * 0.7 + 1)
	var open := 0.0
	var build := 0.0
	if _anim >= 0.0:
		if _anim < _shake_t:
			build = _anim / _shake_t
			foot.x += sin(_anim * 60.0) * 2.4 * build
			foot.y -= absf(sin(_anim * 30.0)) * 1.8 * build
		else:
			open = clampf((_anim - _shake_t) / 0.25, 0.0, 1.0)
	elif not _result.is_empty():
		open = 1.0
	# light rays climbing out of the open chest, turning slowly, fading after the burst
	var ray_a := 0.0
	if _anim >= _shake_t:
		ray_a = clampf((_anim - _shake_t) / 0.2, 0.0, 1.0) * clampf(1.0 - (_anim - _shake_t - 0.6) / 0.8, 0.25, 1.0)
	elif _anim < 0.0 and not _result.is_empty():
		ray_a = 0.25
	if ray_a > 0.0:
		var src := foot - Vector2(0, cw * 0.42)
		var nr := 7 + Chests.rank(kind) * 2
		for k in nr:
			var a := -PI / 2.0 + (k - (nr - 1) / 2.0) * 0.22 + sin(_t * 0.8 + k) * 0.04
			var ln := SHOW_H * (0.55 + 0.12 * sin(_t * 2.0 + k * 1.7))
			_stage.draw_colored_polygon(PackedVector2Array([src + Vector2(-3, 0), src + Vector2(3, 0),
				src + Vector2.from_angle(a + 0.05) * ln, src + Vector2.from_angle(a - 0.05) * ln]), Color(col.lightened(0.3), 0.10 * ray_a))
	ChestArt.draw(_stage, foot, cw, kind, open, _t)
	# during the build-up light leaks through the lid seam
	if build > 0.0:
		var sy := foot.y - cw * 0.5
		_stage.draw_rect(Rect2(foot.x - cw * 0.46, sy - 1.0, cw * 0.92, 2.0), Color(col.lightened(0.5), 0.7 * build))
		for k in 5:
			var bx := foot.x - cw * 0.4 + k * cw * 0.2 + sin(_t * 9.0 + k) * 2.0
			var bl := 8.0 + 14.0 * build * (0.6 + 0.4 * sin(_t * 13.0 + k * 2.0))
			_stage.draw_colored_polygon(PackedVector2Array([Vector2(bx - 1.2, sy), Vector2(bx + 1.2, sy), Vector2(bx + 3.5, sy - bl), Vector2(bx - 3.5, sy - bl)]),
				Color(col.lightened(0.4), 0.35 * build))
	# burst flash when the lid flies open
	if _anim >= _shake_t and _anim < _shake_t + 0.45:
		var f := 1.0 - (_anim - _shake_t) / 0.45
		_stage.draw_circle(foot - Vector2(0, 30), 90.0 * (1.0 - f) + 10.0, Color(col, 0.35 * f))
	# beam behind the best reward
	if _best_x >= 0.0 and not _result.is_empty():
		var bt := clampf((_anim - _shake_t - 0.3) / 0.4, 0.0, 1.0) if _anim >= 0.0 else 1.0
		var by := SHOW_H - 31.0
		var bcol := Color("#FF9A3A")
		_stage.draw_colored_polygon(PackedVector2Array([Vector2(_best_x - 6, by + 26), Vector2(_best_x + 6, by + 26),
			Vector2(_best_x + 2.5, by - 60), Vector2(_best_x - 2.5, by - 60)]), Color(bcol, 0.22 * bt * (0.8 + 0.2 * sin(_t * 6.0))))
	# sparks and coins
	for p in _parts:
		var k3: float = 1.0 - float(p[2]) / float(p[3])
		_stage.draw_circle(p[0], float(p[4]) * (0.5 + 0.5 * k3), Color(p[5], k3))


func _burst() -> void:
	var w := _stage.size.x
	var cw := clampf(SHOW_H * 0.52, 40.0, 66.0)
	var src := Vector2(w / 2.0, SHOW_H * 0.7 - cw * 0.45)
	var col := Chests.color(_open_kind)
	var n := 18 + Chests.rank(_open_kind) * 10
	for i in n:
		var a := -PI / 2.0 + _rng.randf_range(-1.1, 1.1)
		var gold := i % 3 == 0
		_parts.append([src + Vector2(_rng.randf_range(-cw * 0.3, cw * 0.3), 0), Vector2.from_angle(a) * _rng.randf_range(60, 150), 0.0,
			_rng.randf_range(0.6, 1.2), _rng.randf_range(1.2, 2.4) if gold else _rng.randf_range(0.8, 1.6),
			Color("#FFD36A") if gold else col.lightened(0.4)])


func _on_open() -> void:
	if _sel < 0 or _anim >= 0.0:
		return
	_queue = 0
	_begin_open()


func _on_open_all() -> void:
	if GameState.chests.is_empty() or _anim >= 0.0:
		return
	_queue = GameState.chests.size() - 1
	_sel = Chests.best_index()
	_begin_open()


func _begin_open() -> void:
	if _sel < 0 or _sel >= GameState.chests.size():
		_sel = Chests.best_index()
	if _sel < 0:
		_queue = 0
		return
	_open_kind = str(GameState.chests[_sel]["k"])
	# rarer chests keep you waiting a little longer; "open all" keeps a brisk pace
	_shake_t = 0.3 if _queue > 0 else 0.45 + 0.15 * Chests.rank(_open_kind)
	_best_x = -1.0
	_result = {}
	_clear_rewards()
	_name.text = Chests.display_name(_open_kind)
	_name.add_theme_color_override("font_color", Chests.color(_open_kind))
	_anim = 0.0
	_open_btn.disabled = true
	_all_btn.disabled = true
	AudioManager.play("chest_shake", 0.05, 0.7)


func _reveal() -> void:
	_result = Chests.open(_sel)
	_sel = -1
	AudioManager.play("chest_open", 0.04, 0.9)
	if Chests.rank(_open_kind) >= 3:
		AudioManager.play("loot_legendary", 0.0, 0.6)
	elif Chests.rank(_open_kind) >= 2:
		AudioManager.play("loot_rare", 0.05, 0.6)
	_show_rewards()


func _clear_rewards() -> void:
	for ch in _rewards.get_children():
		ch.queue_free()


## Reward cards dealt left to right over the pedestal: gold, items, materials.
func _show_rewards() -> void:
	_clear_rewards()
	if _result.is_empty():
		return
	var cards: Array = []
	cards.append(["gold", int(_result["gold"])])
	for pair in _result["items"]:
		cards.append(["item", pair])
	for m in _result["mats"]:
		cards.append(["mat", [m, int(_result["mats"][m])]])
	var cw := 24.0
	var gap := 3.0
	var total := cards.size() * cw + (cards.size() - 1) * gap
	var x0 := (_rewards.size.x - total) / 2.0
	var mouth := Vector2(_rewards.size.x / 2.0 - cw / 2.0, SHOW_H * 0.7 - clampf(SHOW_H * 0.52, 40.0, 66.0) * 0.45 - _rewards.position.y - cw / 2.0)
	var best_rank := ItemUtil.rarity_rank("legendary") - 1
	for i in cards.size():
		var cd: Array = cards[i]
		var holder: Control
		match cd[0]:
			"item":
				var it: Dictionary = cd[1][0]
				var s := ItemSlot.new(cw)
				s.set_item(it)
				holder = s
			"gold":
				holder = _icon_card(UITheme.icon("gold"), F.fmt_num(int(cd[1])), UITheme.C_GOLD, DataDB.t("gold"))
			_:
				var mid: String = cd[1][0]
				holder = _icon_card(UITheme.icon(_mat_icon(mid)), "x%d" % int(cd[1][1]), UITheme.C_TEXT, ItemUtil.material_name(mid))
		var dest := Vector2(x0 + i * (cw + gap), 2)
		if cd[0] == "item":
			var rr := ItemUtil.rarity_rank(str(cd[1][0].get("rarity", "common")))
			if rr > best_rank:
				best_rank = rr
				_best_x = dest.x + cw / 2.0
		# each reward leaps out of the chest mouth and lands in its place
		holder.position = mouth
		_rewards.add_child(holder)
		holder.modulate.a = 0.0
		holder.scale = Vector2(0.4, 0.4)
		holder.pivot_offset = Vector2(cw / 2.0, cw / 2.0)
		var tw := holder.create_tween()
		tw.tween_interval(0.09 * i)
		tw.set_parallel(true)
		tw.tween_property(holder, "modulate:a", 1.0, 0.12)
		tw.tween_property(holder, "position:x", dest.x, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(holder, "position:y", dest.y, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(holder, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _icon_card(tex: Texture2D, txt: String, col: Color, tip: String) -> Control:
	var c := Control.new()
	c.size = Vector2(24, 24)
	c.tooltip_text = tip
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.draw.connect(func():
		UISkin.slot(c.get_canvas_item(), Rect2(Vector2.ZERO, c.size), Color("#8C919C"), true, false)
		if tex:
			c.draw_texture_rect(tex, Rect2(5, 3, 14, 14), false)
		var f := UITheme.font_body
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		c.draw_string_outline(f, Vector2((24 - tw) / 2.0, 22), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0, 0, 0, 0.95))
		c.draw_string(f, Vector2((24 - tw) / 2.0, 22), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col))
	return c


func _mat_icon(mid: String) -> String:
	match mid:
		"tavern_seal":
			return "crown"
		"soul_shard":
			return "gem"
		"guild_badge":
			return "star"
	return "hammer"
