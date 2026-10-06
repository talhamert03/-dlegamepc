class_name FormationView
extends Control
## Party formation: a small battle stage with the five positions (back on the left, front on the right, as
## on the battlefield), each hero standing on a lit platform with name plate and level, and the roster as
## portrait cards below. Drag a card onto a platform to place the hero, drag between platforms to swap,
## drag a hero off the stage (onto the roster) to bench them. Clicking works too: pick a platform, then a card.

const STAGE_H := 84.0

var sel_slot := 0
var _t := 0.0
var _stage: Control
var _roster: Control
var _info: Control
var _tex := {}
# in-panel drag: the hero follows the mouse, the platform under it lights up
var _cand := {}            # {hid, from_slot, start}
var _dragging := false
var _just_dragged := false
var _ghost: Control
var _hover_slot := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_stage = Control.new()
	_stage.size = Vector2(size.x, STAGE_H)
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	_stage.draw.connect(_draw_stage)
	add_child(_stage)
	_roster = Control.new()
	_roster.position = Vector2(0, STAGE_H + 16)
	_roster.size = Vector2(size.x, size.y - STAGE_H - 16)
	add_child(_roster)
	_info = Control.new()
	_info.position = Vector2(0, STAGE_H + 2)
	_info.size = Vector2(size.x, 13)
	_info.draw.connect(_draw_info)
	add_child(_info)
	_ghost = Control.new()
	_ghost.size = size
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.z_index = 20
	_ghost.draw.connect(_draw_ghost)
	add_child(_ghost)
	EventBus.party_changed.connect(rebuild)
	EventBus.hero_unlocked.connect(func(_h): rebuild())
	rebuild()


func _process(delta: float) -> void:
	_t += delta
	_stage.queue_redraw()
	if not _cand.is_empty():
		var m := get_local_mouse_position()
		if not _dragging and m.distance_to(_cand["start"]) > 4.0:
			_dragging = true
			WindowManager.hide_tooltip()
			AudioManager.play("ui_click", 0.05, 0.4)
		if _dragging:
			_hover_slot = _slot_at(m)
			_ghost.queue_redraw()


func _input(ev: InputEvent) -> void:
	if _cand.is_empty():
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		if _dragging:
			_finish_drag(get_local_mouse_position())
			_just_dragged = true
			get_viewport().set_input_as_handled()
		_cand = {}
		_dragging = false
		_hover_slot = -1
		_ghost.queue_redraw()


func _begin(hid: String, from_slot: int) -> void:
	if hid == "":
		return
	_cand = {"hid": hid, "from_slot": from_slot, "start": get_local_mouse_position()}
	_just_dragged = false


func _slot_at(local: Vector2) -> int:
	for slot in 5:
		if _slot_rect(slot).grow(2.0).has_point(local):
			return slot
	return -1


func _finish_drag(local: Vector2) -> void:
	var hid: String = _cand["hid"]
	var from: int = int(_cand["from_slot"])
	var to := _slot_at(local)
	if to >= 0:
		if to < GameState.unlocked_party_slots():
			_place(hid, to)
	elif from >= 0 and local.y > STAGE_H:
		_bench({"from_slot": from})


func _draw_ghost() -> void:
	if not _dragging or _cand.is_empty():
		return
	var tex := _chibi(str(_cand["hid"]))
	if tex == null:
		return
	var m := get_local_mouse_position()
	var h := 50.0
	var w := tex.get_width() * h / float(tex.get_height())
	# shadow on the ground under the cursor, then the lifted hero, slightly tilted
	_ghost.draw_set_transform(m + Vector2(0, 4), 0.0, Vector2(1.0, 0.3))
	_ghost.draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	_ghost.draw_set_transform(m, sin(_t * 9.0) * 0.06, Vector2.ONE)
	_ghost.draw_texture_rect(tex, Rect2(-w / 2.0, -h - 4.0, w, h), false, Color(1, 1, 1, 0.92))
	_ghost.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if m.y > STAGE_H and int(_cand["from_slot"]) >= 0:
		_ghost.draw_string(UITheme.font_body, m + Vector2(10, -2), DataDB.t("formation_bench"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_ORANGE)


func _slot_rect(slot: int) -> Rect2:
	var cw := (size.x - 8.0) / 5.0
	var vis := 4 - slot
	return Rect2(4 + vis * cw, 4, cw - 3, STAGE_H - 8)


func _chibi(hid: String) -> Texture2D:
	if not _tex.has(hid):
		var t := SpriteLib.chibi_frame("heroes", hid)
		_tex[hid] = t if t else SpriteLib.hero_icon(hid)
	return _tex[hid]


func rebuild() -> void:
	if _stage == null:
		return
	for ch in _stage.get_children():
		ch.queue_free()
	for ch in _roster.get_children():
		ch.queue_free()
	var unlocked := GameState.unlocked_party_slots()
	# drop targets / buttons over each platform
	for slot in 5:
		var r := _slot_rect(slot)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = r.position
		b.size = r.size
		b.disabled = slot >= unlocked
		var hid: String = GameState.party[slot]
		if hid != "":
			var h: HeroState = GameState.heroes[hid]
			b.tooltip_text = "%s · %s · %s" % [h.display_name(), h.class_title(), F.lv(h.level)]
			_chibi(hid)
		var s := slot
		b.button_down.connect(func(): _begin(str(GameState.party[s]), s))
		b.pressed.connect(func():
			if _just_dragged:
				_just_dragged = false
				return
			sel_slot = s
			AudioManager.play("ui_click", 0.05, 0.5))
		_stage.add_child(b)
	# roster cards
	var ids: Array = GameState.heroes.keys()
	ids.sort_custom(func(a, b):
		var pa := GameState.party.has(a)
		var pb := GameState.party.has(b)
		if pa != pb:
			return pa
		return GameState.heroes[a].level > GameState.heroes[b].level)
	var cw := 30.0
	var per_row := int((_roster.size.x + 2) / (cw + 2))
	var sc := W.scroll(_roster.size)
	_roster.add_child(sc)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(_roster.size.x - 6, ceil(ids.size() / float(per_row)) * (cw + 10))
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	sc.add_child(holder)
	for i in ids.size():
		var hid2: String = ids[i]
		var card := _card(hid2, cw)
		card.position = Vector2((i % per_row) * (cw + 2), (i / per_row) * (cw + 10))
		holder.add_child(card)


func _card(hid: String, cw: float) -> Control:
	var h: HeroState = GameState.heroes[hid]
	var rar := str(h.def().get("rarity", "R"))
	var rcol: Color = {"R": Color("#A9B1C2"), "SR": Color("#5E9BFF"), "SSR": Color("#FFC24A")}.get(rar, Color.WHITE)
	var tex := SpriteLib.hero_icon(hid)
	var in_party := GameState.party.find(hid)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(cw, cw + 8)
	b.tooltip_text = "%s · %s · %s" % [h.display_name(), h.class_title(), F.lv(h.level)]
	b.mouse_default_cursor_shape = Control.CURSOR_DRAG
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var r := Rect2(0, 0, cw, cw)
		UISkin.fill(ci, r, 3, Color("#3A3036"), Color("#1A1519"))
		if tex:
			b.draw_texture_rect(tex, r.grow(-1.5), false, Color.WHITE if in_party < 0 else Color(0.6, 0.6, 0.65))
		UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.4)
		UISkin.stroke(ci, r.grow(-0.5), 3, Color(rcol, 0.9 if b.is_hovered() else 0.6), 1.0)
		if in_party >= 0:
			var badge := Rect2(cw - 10, 1, 9, 9)
			UISkin.fill(ci, badge, 2, Color("#4FB85A"), Color("#23602B"))
			UISkin.stroke(ci, badge, 2, Color(0, 0, 0, 0.9), 1.0)
			b.draw_string(UITheme.font_body, badge.position + Vector2(2.4, 7.5), str(in_party + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
		var f := UITheme.font_body
		var lv := F.lv(h.level, "tight")
		var tw := f.get_string_size(lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		b.draw_string(f, Vector2((cw - tw) / 2.0, cw + 7), lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.button_down.connect(func(): _begin(hid, GameState.party.find(hid)))
	b.pressed.connect(func():
		if _just_dragged:
			_just_dragged = false
			return
		if sel_slot < GameState.unlocked_party_slots():
			_place(hid, sel_slot))
	return b


func _place(hid: String, slot: int) -> void:
	GameState.set_party_slot(slot, hid)
	sel_slot = slot
	W.select_hero(hid)
	AudioManager.play("equip", 0.05, 0.5)


func _bench(d: Dictionary) -> void:
	if GameState.party_count() <= 1:
		EventBus.notify.emit(DataDB.t("formation_last"), UITheme.C_RED)
		return
	GameState.set_party_slot(int(d["from_slot"]), "")
	AudioManager.play("unequip", 0.05, 0.5)


func _draw_stage() -> void:
	var ci := _stage.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _stage.size)
	# dusk sky and a ground band
	UISkin.fill(ci, r, 4, Color("#3A2E4A"), Color("#1A1420"))
	UISkin.fill(ci, Rect2(0, r.size.y * 0.66, r.size.x, r.size.y * 0.34), 0, Color("#3A2A22"), Color("#1E1410"))
	_stage.draw_line(Vector2(2, r.size.y * 0.66), Vector2(r.size.x - 2, r.size.y * 0.66), Color(1, 0.85, 0.6, 0.15), 1.0)
	for k in 6:
		var x := fposmod(k * 61.0 + _t * 3.0, r.size.x)
		_stage.draw_circle(Vector2(x, 10 + (k % 3) * 6), 0.8, Color(1, 1, 1, 0.35))
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 3, Color(UISkin.BRONZE, 0.5), 1.0)
	var unlocked := GameState.unlocked_party_slots()
	var f := UITheme.font_body
	for slot in 5:
		var sr := _slot_rect(slot)
		var foot := Vector2(sr.get_center().x, sr.end.y - 16)
		var hid: String = GameState.party[slot]
		var sel := slot == sel_slot or (_dragging and slot == _hover_slot)
		# platform
		_stage.draw_set_transform(foot + Vector2(0, 2), 0.0, Vector2(1.0, 0.32))
		var pc := Color("#C8913F") if sel else Color("#5A4A60")
		_stage.draw_circle(Vector2.ZERO, sr.size.x * 0.42, Color(pc, 0.35 if slot < unlocked else 0.12))
		_stage.draw_arc(Vector2.ZERO, sr.size.x * 0.42, 0, TAU, 24, Color(pc, 0.9 if sel else 0.5), 2.0, true)
		_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if sel:
			for k in 4:
				var yy := fposmod(_t * 20.0 + k * 9.0, 34.0)
				_stage.draw_circle(foot + Vector2(sin(k * 2.0 + _t * 3.0) * 8.0, -yy), 0.9, Color(1, 0.85, 0.5, 0.6 * (1.0 - yy / 34.0)))
		if slot >= unlocked:
			var li := UITheme.icon("lock")
			if li:
				_stage.draw_texture_rect(li, Rect2(foot - Vector2(5, 22), Vector2(10, 10)), false, Color(1, 1, 1, 0.5))
		elif hid == "":
			_stage.draw_arc(foot + Vector2(0, -16), 7.0, 0, TAU, 20, Color(1, 1, 1, 0.25), 1.0, true)
			_stage.draw_line(foot + Vector2(-3, -16), foot + Vector2(3, -16), Color(1, 1, 1, 0.35), 1.2)
			_stage.draw_line(foot + Vector2(0, -19), foot + Vector2(0, -13), Color(1, 1, 1, 0.35), 1.2)
		else:
			var tex := _chibi(hid)
			if tex:
				var h := 46.0
				var w := tex.get_width() * h / float(tex.get_height())
				var bob := sin(_t * 2.5 + slot) * 0.6
				var lifted: bool = _dragging and int(_cand.get("from_slot", -1)) == slot
				_stage.draw_texture_rect(tex, Rect2(foot.x - w / 2.0, foot.y - h + 4 + bob, w, h), false, Color(1, 1, 1, 0.25 if lifted else 1.0))
			var h2: HeroState = GameState.heroes[hid]
			var nm := h2.display_name()
			var plate := Rect2(sr.position.x + 1, sr.end.y - 12, sr.size.x - 2, 11)
			UISkin.fill(ci, plate, 2, Color(0.08, 0.06, 0.08, 0.9), Color(0.04, 0.03, 0.04, 0.9))
			UISkin.stroke(ci, plate, 2, Color(UISkin.BRONZE, 0.6 if sel else 0.3), 1.0)
			var txt := "%s %d" % [nm, h2.level]
			_stage.draw_string(f, plate.position + Vector2(2, 8.5), txt, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x - 4, 7, UITheme.C_TEXT)
		var lab := DataDB.t("front") if slot == 0 else (DataDB.t("back") if slot == 4 else "")
		if lab != "":
			_stage.draw_string(f, Vector2(sr.position.x + 2, sr.position.y + 8), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.9, 0.7, 0.55))


func _draw_info() -> void:
	var s := DataDB.t("formation_hint")
	_info.draw_string(UITheme.font_body, Vector2(3, 9), s, HORIZONTAL_ALIGNMENT_LEFT, _info.size.x - 6, 7, UITheme.C_DIM)
