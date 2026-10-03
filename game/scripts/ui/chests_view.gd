class_name ChestsView
extends Control
## Treasure chests: a showcase of the best held chest on a lit pedestal, the shelf of the others, and an
## opening sequence (shake, lid thrown back, light, rewards dealt out as cards).

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	SHOW_H = clampf(size.y - 64.0, 80.0, 126.0)
	_build(self)


func _build(c: Control) -> void:
	_anim = -1.0
	var w := c.size.x
	_stage = Control.new()
	_stage.size = Vector2(w, SHOW_H)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
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
	_hint.position = Vector2(8, 40)
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
			UISkin.fill(ci, r, 3, Color("#2A2230"), Color("#141117"))
			UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.9), 1.0)
			UISkin.stroke(ci, r.grow(-1.0), 2, Color(Chests.color(k), 0.95 if sel_kind else (0.55 if b.is_hovered() else 0.25)), 1.0)
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
		if before < 0.55 and _anim >= 0.55:
			_reveal()
		if _anim >= 1.6:
			_anim = -1.0
			if _queue > 0:
				_queue -= 1
				_begin_open()
			else:
				refresh()
	if _stage:
		_stage.queue_redraw()
	if _shelf:
		for b in _shelf.get_children():
			(b as Control).queue_redraw()


func _draw_stage() -> void:
	var ci := _stage.get_canvas_item()
	var w := _stage.size.x
	var r := Rect2(0, 0, w, SHOW_H - 2)
	UISkin.fill(ci, r, 4, Color("#231C26"), Color("#0E0B10"))
	var kind := _open_kind if _open_kind != "" else (str(GameState.chests[_sel]["k"]) if _sel >= 0 and _sel < GameState.chests.size() else "")
	var col: Color = Chests.color(kind) if kind != "" else Color("#6A5A70")
	# back light and pedestal
	for k in 8:
		_stage.draw_circle(Vector2(w / 2.0, SHOW_H * 0.49), SHOW_H * 0.55 - k * SHOW_H * 0.06, Color(col, 0.028))
	var cw := clampf(SHOW_H * 0.5, 40.0, 64.0)
	var ped := Rect2(w / 2.0 - cw * 0.7, SHOW_H * 0.65, cw * 1.4, 8)
	UISkin.fill(ci, ped, 3, Color("#4A3E50"), Color("#1E1822"))
	UISkin.stroke(ci, ped, 3, Color(0, 0, 0, 0.9), 1.0)
	UISkin.line(ci, Vector2(ped.position.x + 4, ped.position.y + 1), Vector2(ped.end.x - 4, ped.position.y + 1), Color(col, 0.35), 1.0)
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.9), 1.0)
	UISkin.stroke(ci, r.grow(-1.5), 3, Color(UISkin.BRONZE, 0.4), 1.0)
	if kind == "":
		return
	var foot := Vector2(w / 2.0, SHOW_H * 0.65 + 1)
	var open := 0.0
	if _anim >= 0.0:
		if _anim < 0.45:
			var k2 := _anim / 0.45
			foot.x += sin(_anim * 60.0) * 2.2 * k2
			foot.y -= absf(sin(_anim * 30.0)) * 1.5 * k2
		else:
			open = clampf((_anim - 0.45) / 0.25, 0.0, 1.0)
	elif not _result.is_empty():
		open = 1.0
	ChestArt.draw(_stage, foot, cw, kind, open, _t)
	# burst flash when the lid flies open
	if _anim >= 0.45 and _anim < 0.9:
		var f := 1.0 - (_anim - 0.45) / 0.45
		_stage.draw_circle(foot - Vector2(0, 30), 90.0 * (1.0 - f) + 10.0, Color(col, 0.35 * f))


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
		holder.position = Vector2(x0 + i * (cw + gap), 2)
		_rewards.add_child(holder)
		holder.modulate.a = 0.0
		holder.scale = Vector2(0.6, 0.6)
		holder.pivot_offset = Vector2(cw / 2.0, cw / 2.0)
		var tw := holder.create_tween()
		tw.tween_interval(0.08 * i)
		tw.set_parallel(true)
		tw.tween_property(holder, "modulate:a", 1.0, 0.15)
		tw.tween_property(holder, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
