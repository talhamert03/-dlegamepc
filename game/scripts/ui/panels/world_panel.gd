extends PanelWindow
## World map, laid out like an atlas page: a difficulty plaque and the tower gate on top, hanging banner
## tabs for the four worlds, the painted map in a carved frame with medallion waypoints, and a zone card
## underneath (its monsters, readiness, the DPS it asks for, the stage pills and the Play button).

const TOP_H := 18.0
const TABS_Y := 21.0
const TABS_H := 15.0
const MAP_Y := 40.0
const DIFF_COL := [Color("#E8C27A"), Color("#C98BFF"), Color("#FF6A4A")]
const EL_COL := {"fire": Color("#FF7A3A"), "cold": Color("#7FD0FF"), "lightning": Color("#FFE45A"),
	"chaos": Color("#B57CFF"), "holy": Color("#FFF2B0")}

var act := 1
var _tabs: Control
var _diff_btn: Button
var _map: TextureRect
var _nodes_root: Control
var _overlay: Control
var _diff := 0
var _t := 0.0
var _card: Control
var _sel_zone := -1
var _sel_stage := 1


func build(c: Control) -> void:
	_diff = int(GameState.progress.get("difficulty", 0))
	act = int(DataDB.zone(int(GameState.progress.get("zone", 0))).get("act", 1))
	var w := c.size.x
	_build_top(c, w)
	_tabs = Control.new()
	_tabs.position = Vector2(0, TABS_Y)
	_tabs.size = Vector2(w, TABS_H)
	c.add_child(_tabs)
	# carved frame, painted map, waypoints, then a top layer with the world name and the edge shading
	var mw := w - 8.0
	var mh := mw * 150.0 / 240.0
	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2(0, MAP_Y)
	frame.size = Vector2(w, mh + 8.0)
	frame.draw.connect(func():
		var ci := frame.get_canvas_item()
		var r := Rect2(Vector2.ZERO, frame.size)
		UISkin.fill(ci, r, 3, UISkin.IRON_TOP, UISkin.IRON_BOT)
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.5), 2, Color(UISkin.BRONZE, 0.6), 0.8)
		for p in [Vector2(2.5, 2.5), Vector2(r.size.x - 2.5, 2.5), Vector2(2.5, r.size.y - 2.5), r.size - Vector2(2.5, 2.5)]:
			UISkin.rivet(ci, p, 1.4))
	c.add_child(frame)
	_map = TextureRect.new()
	_map.position = Vector2(4, MAP_Y + 4)
	_map.size = Vector2(mw, mh)
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	c.add_child(_map)
	_nodes_root = Control.new()
	_nodes_root.size = Vector2(240, 150)
	_nodes_root.scale = Vector2(mw / 240.0, mh / 150.0)
	_map.add_child(_nodes_root)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.position = _map.position
	_overlay.size = _map.size
	_overlay.draw.connect(_draw_overlay)
	c.add_child(_overlay)
	_card = Control.new()
	_card.position = Vector2(0, MAP_Y + mh + 12.0)
	_card.size = Vector2(w, c.size.y - _card.position.y)
	c.add_child(_card)
	EventBus.zone_changed.connect(func(_z): refresh())
	EventBus.zone_unlocked.connect(func(_z): refresh())
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _nodes_root:
		for ch in _nodes_root.get_children():
			if ch.has_meta("pulse"):
				ch.queue_redraw()


# ------------------------------------------------------------------ top: difficulty + tower
func _build_top(c: Control, w: float) -> void:
	var dw := floorf(w * 0.5 - 2.0)
	_diff_btn = Button.new()
	_diff_btn.flat = true
	_diff_btn.focus_mode = Control.FOCUS_NONE
	_diff_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_diff_btn.position = Vector2.ZERO
	_diff_btn.size = Vector2(dw, TOP_H)
	_diff_btn.tooltip_text = DataDB.t("world_diff_tip")
	_diff_btn.pressed.connect(_cycle_diff)
	_diff_btn.mouse_entered.connect(_diff_btn.queue_redraw)
	_diff_btn.mouse_exited.connect(_diff_btn.queue_redraw)
	_diff_btn.draw.connect(func():
		var ci := _diff_btn.get_canvas_item()
		var r := Rect2(Vector2.ZERO, _diff_btn.size)
		var col: Color = DIFF_COL[_diff]
		var hov := _diff_btn.is_hovered()
		UISkin.fill(ci, r, 3, Color("#3A2616").lightened(0.08 if hov else 0.0), Color("#1A0F08"))
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(col, 0.75 if hov else 0.5), 1.0)
		# small heraldic shield in the difficulty colour
		var s := Vector2(9, r.size.y / 2.0)
		var sh := PackedVector2Array([s + Vector2(-5, -6), s + Vector2(5, -6), s + Vector2(5, 0), s + Vector2(0, 6.5), s + Vector2(-5, 0)])
		UISkin.poly(ci, sh, col.lightened(0.2), col.darkened(0.45))
		var shc := sh.duplicate()
		shc.append(sh[0])
		_diff_btn.draw_polyline(shc, UISkin.OUTLINE, 1.0, true)
		for k in _diff + 1:
			UISkin.diamond(ci, s + Vector2((k - _diff / 2.0) * 3.2, -1.5), 1.3, Color("#FFF4D0"), Color("#9A7A4A"))
		var f := UITheme.font_title
		var name := DataDB.tx(DataDB.difficulties[_diff]["name"])
		var tw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var tp := Vector2(18 + (r.size.x - 30 - tw) / 2.0, r.size.y / 2.0 + 3.3)
		_diff_btn.draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color(0, 0, 0, 0.8))
		_diff_btn.draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col.lightened(0.25))
		_diff_btn.draw_string(UITheme.font_body, Vector2(r.size.x - 10, r.size.y / 2.0 + 3.5), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color("#E8C27A", 0.9 if hov else 0.55)))
	c.add_child(_diff_btn)
	var locked := not BattleSim.tower_unlocked()
	var tb := Button.new()
	tb.flat = true
	tb.focus_mode = Control.FOCUS_NONE
	tb.mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
	tb.position = Vector2(dw + 4.0, 0)
	tb.size = Vector2(w - dw - 4.0, TOP_H)
	tb.tooltip_text = DataDB.t("tower_locked") if locked else DataDB.t("tower_best", {"n": int(GameState.progress.get("tower_best", 0))})
	tb.pressed.connect(func():
		if BattleSim.mode == "tower":
			BattleSim.leave_tower()
		elif BattleSim.tower_unlocked():
			BattleSim.enter_tower()
		else:
			EventBus.notify.emit(DataDB.t("tower_locked"), UITheme.C_RED))
	tb.mouse_entered.connect(tb.queue_redraw)
	tb.mouse_exited.connect(tb.queue_redraw)
	tb.draw.connect(func():
		var ci := tb.get_canvas_item()
		var r := Rect2(Vector2.ZERO, tb.size)
		var hov := tb.is_hovered() and not locked
		var top := Color("#30406A") if not locked else Color("#2C2A30")
		UISkin.fill(ci, r, 3, top.lightened(0.1 if hov else 0.0), top.darkened(0.55))
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color("#9FB8F0", 0.55) if not locked else Color("#6A6470", 0.5), 1.0)
		# a little stone tower
		var b := Vector2(9, r.size.y - 3)
		var tc := Color("#AEB6CC") if not locked else Color("#77737C")
		UISkin.fill(ci, Rect2(b.x - 3.5, b.y - 9, 7, 9), 0, tc, tc.darkened(0.4))
		for k in 3:
			tb.draw_rect(Rect2(b.x - 4.5 + k * 3.5, b.y - 11.5, 2, 2.5), tc)
		tb.draw_rect(Rect2(b.x - 1, b.y - 4, 2, 4), Color(0.08, 0.06, 0.1))
		var f := UITheme.font_title
		var name := DataDB.t("tower_name")
		if locked:
			tb.draw_string(f, Vector2(17, 8), name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 8, Color(0.72, 0.7, 0.76))
			tb.draw_texture_rect(UITheme.icon("lock"), Rect2(17, 10, 6, 6), false, Color("#FF8A7A"))
			tb.draw_string(UITheme.font_body, Vector2(25, 15.5), DataDB.t("tower_req_short"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 7,
				Color("#FF8A7A"))
		else:
			var tw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			var tp := Vector2(17 + (r.size.x - 20 - tw) / 2.0, r.size.y / 2.0 + 3.3)
			tb.draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color(0, 0, 0, 0.8))
			tb.draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#E6EEFF")))
	c.add_child(tb)


# ------------------------------------------------------------------ world tabs
func _build_tabs() -> void:
	for ch in _tabs.get_children():
		ch.queue_free()
	var gap := 3.0
	var bw := (_tabs.size.x - gap * 3.0) / 4.0
	var maxz: int = int(GameState.progress["max_zone"][_diff])
	for i in range(1, 5):
		var a := i
		var open := (a - 1) * 10 <= maxz
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.position = Vector2((i - 1) * (bw + gap), 0)
		b.size = Vector2(bw, TABS_H)
		b.tooltip_text = DataDB.tx(DataDB.acts[a - 1]["name"]) if a - 1 < DataDB.acts.size() else ""
		b.pressed.connect(func():
			AudioManager.play("ui_click", 0.05, 0.5)
			_set_act(a))
		b.mouse_entered.connect(b.queue_redraw)
		b.mouse_exited.connect(b.queue_redraw)
		var on := a == act
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var hov := b.is_hovered()
			var r := Rect2(Vector2(0, 0), b.size)
			if on:
				UISkin.stroke(ci, r.grow(1.0), 4, Color(1.0, 0.85, 0.4, 0.45), 2.0)
				UISkin.fill(ci, r, 3, UISkin.RIBBON_TOP.lightened(0.05), UISkin.RIBBON_BOT.darkened(0.2))
			else:
				UISkin.fill(ci, r, 3, Color("#4A3020").lightened(0.1 if hov else 0.0), Color("#24160C"))
			UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
			UISkin.stroke(ci, r.grow(-1.0), 2, Color("#F2CB7A", 0.85) if on else Color("#B08A5A", 0.35), 0.8)
			var f := UITheme.font_title
			var label := DataDB.t("act_n", {"n": a})
			var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var x := (r.size.x - tw - (8.0 if not open else 0.0)) / 2.0
			if not open:
				b.draw_texture_rect(UITheme.icon("lock"), Rect2(x, r.size.y / 2.0 - 3.5, 6, 6), false, Color(0.7, 0.66, 0.6))
				x += 8.0
			var tp := Vector2(x, r.size.y / 2.0 + 3.0)
			b.draw_string_outline(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, 0.85))
			var tc := Color("#FFE7B0") if on else (Color("#D8C4A0") if open else Color("#8A7E70"))
			b.draw_string(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, tc))
		_tabs.add_child(b)


# ------------------------------------------------------------------ map
## Soft dark edges over the painting and the world's name on a ribbon at the top.
func _draw_overlay() -> void:
	var ci := _overlay.get_canvas_item()
	var s := _overlay.size
	var e := 10.0
	var dark := Color(0.05, 0.03, 0.02, 0.55)
	var clear := Color(0.05, 0.03, 0.02, 0.0)
	_overlay.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x, 0), Vector2(s.x, e), Vector2(0, e)]), PackedColorArray([dark, dark, clear, clear]))
	_overlay.draw_polygon(PackedVector2Array([Vector2(0, s.y - e), Vector2(s.x, s.y - e), s, Vector2(0, s.y)]), PackedColorArray([clear, clear, dark, dark]))
	_overlay.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(e, 0), Vector2(e, s.y), Vector2(0, s.y)]), PackedColorArray([dark, clear, clear, dark]))
	_overlay.draw_polygon(PackedVector2Array([Vector2(s.x - e, 0), Vector2(s.x, 0), s, Vector2(s.x - e, s.y)]), PackedColorArray([clear, dark, dark, clear]))
	UISkin.stroke(ci, Rect2(Vector2.ZERO, s), 0, Color(0, 0, 0, 0.8), 1.0)
	var name := DataDB.tx(DataDB.acts[act - 1]["name"]) if act - 1 < DataDB.acts.size() else ""
	if name == "":
		return
	var f := UITheme.font_title
	var fs := 8
	var label := DataDB.t("act_n", {"n": act}) + "  ·  " + name
	var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var rb := Rect2((s.x - tw) / 2.0 - 10.0, 4, tw + 20.0, 12)
	UISkin.ribbon(ci, rb)
	var tp := Vector2((s.x - tw) / 2.0, rb.get_center().y + 3.0)
	_overlay.draw_string_outline(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0.15, 0.0, 0.02, 0.95))
	_overlay.draw_string(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFE7A8"))


## Waypoint medallion: gold when cleared, crimson when open, dark stone with a lock when not reached.
func _waypoint(at: Vector2, num: int, state: String, current: bool, zi: int, tip: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(14, 14)
	b.position = at - Vector2(7, 7)
	b.disabled = state == "locked"
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if state != "locked" else Control.CURSOR_ARROW
	b.tooltip_text = tip
	if current:
		b.set_meta("pulse", true)
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var c := Vector2(7, 7)
		var hov := b.is_hovered() and state != "locked"
		if current:
			var p := 0.5 + 0.5 * sin(_t * 3.0)
			b.draw_circle(c, 7.5 + p * 1.5, Color(1.0, 0.85, 0.4, 0.18 + 0.15 * p))
		b.draw_circle(c + Vector2(0, 0.8), 6.2, Color(0, 0, 0, 0.5))
		b.draw_circle(c, 6.0, UISkin.OUTLINE)
		var top: Color
		var bot: Color
		match state:
			"cleared":
				top = Color("#FFE08A")
				bot = Color("#B07420")
			"open":
				top = Color("#E0574A")
				bot = Color("#7A1A16")
			_:
				top = Color("#6A6670")
				bot = Color("#2E2C34")
		if hov:
			top = top.lightened(0.2)
		UISkin.circle(ci, c, 5.2, top, bot)
		UISkin.ring(ci, c, 4.3, Color(1, 1, 1, 0.22), 0.6)
		if state == "locked":
			b.draw_texture_rect(UITheme.icon("lock"), Rect2(c - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), false, Color(0.85, 0.82, 0.78))
		else:
			var f := UITheme.font_body
			var txt := str(num)
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
			b.draw_string(f, Vector2(c.x - tw / 2.0, c.y + 2.2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
				Color("#3A1C06") if state == "cleared" else Color("#FFF0DA")))
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.6)
		_show_card(zi)
		refresh_nodes_highlight())
	return b


# ------------------------------------------------------------------ zone card
func _show_card(zi: int) -> void:
	for ch in _card.get_children():
		ch.queue_free()
	var z := DataDB.zone(zi)
	if z.is_empty():
		return
	var w := _card.size.x
	var h := _card.size.y
	var cleared: bool = GameState.progress["cleared"].has("%d_%s" % [_diff, z["id"]])
	var bg := Control.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.size = _card.size
	bg.draw.connect(func():
		var ci := bg.get_canvas_item()
		var r := Rect2(Vector2.ZERO, bg.size)
		UISkin.fill(ci, r, 3, UISkin.BODY_TOP.lightened(0.04), UISkin.BODY_BOT)
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.5), 2, Color(UISkin.BRONZE, 0.45), 0.8)
		UISkin.line(ci, Vector2(6, 16.5), Vector2(r.size.x - 6, 16.5), Color(UISkin.BRONZE, 0.4), 0.8)
		UISkin.diamond(ci, Vector2(r.size.x / 2.0, 16.5), 2.0))
	_card.add_child(bg)
	# header: name, "cleared" seal, level range
	var lvtxt := "%s %d–%d" % [DataDB.t("lv_short").capitalize(), F.monster_level(z, 1, _diff), F.monster_level(z, 10, _diff)]
	var lvw := UITheme.font_body.get_string_size(lvtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var nm := UITheme.label(DataDB.tx(z["name"]), UITheme.C_TITLE, 10, UITheme.font_title)
	nm.position = Vector2(6, 2)
	nm.size = Vector2(w - lvw - 26, 13)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card.add_child(nm)
	var tag := Control.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.position = Vector2(w - lvw - 5, 3)
	tag.size = Vector2(lvw, 11)
	tag.draw.connect(func():
		var ci := tag.get_canvas_item()
		var r := Rect2(Vector2.ZERO, tag.size)
		UISkin.fill(ci, r, 3, Color("#4A3418"), Color("#24180A"))
		UISkin.stroke(ci, r, 3, Color(UISkin.BRONZE, 0.8), 0.8)
		tag.draw_string(UITheme.font_body, Vector2(5, 8.4), lvtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_GOLD))
	_card.add_child(tag)
	if cleared:
		var ck := Control.new()
		ck.mouse_filter = Control.MOUSE_FILTER_STOP
		ck.tooltip_text = DataDB.t("cleared")
		ck.position = Vector2(w - lvw - 20, 2)
		ck.size = Vector2(13, 13)
		ck.draw.connect(func():
			var ci := ck.get_canvas_item()
			UISkin.circle(ci, Vector2(6.5, 6.5), 5.5, Color("#6FE08A"), Color("#24673B"))
			UISkin.ring(ci, Vector2(6.5, 6.5), 5.5, UISkin.OUTLINE, 1.0)
			ck.draw_polyline(PackedVector2Array([Vector2(3.8, 6.8), Vector2(5.8, 8.8), Vector2(9.4, 4.4)]), Color("#0E2A14"), 1.4, true))
		_card.add_child(ck)
	# monsters of the zone and the boss
	var row := W.hbox(2)
	row.position = Vector2(6, 20)
	_card.add_child(row)
	var ids: Array = z.get("enemies", []).duplicate()
	ids.append(z.get("boss", ""))
	for eid in ids:
		var boss: bool = eid == z.get("boss", "")
		var b := UITheme.slot_button(Vector2(28, 30) if boss else Vector2(24, 26))
		var tex := SpriteLib.chibi_frame("enemies", str(eid))
		if tex == null:
			tex = SpriteLib.hd_sprite("enemies", str(eid))
		var ic := W.icon_rect(tex, Vector2(24, 26) if boss else Vector2(20, 22))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(2, 2)
		ic.flip_h = true
		b.add_child(ic)
		b.tooltip_text = DataDB.tx(DataDB.enemy_def(str(eid)).get("name", {})) + (" (" + DataDB.t("boss") + ")" if boss else "")
		if boss:
			b.draw.connect(func(): UISkin.stroke(b.get_canvas_item(), Rect2(Vector2.ZERO, b.size).grow(-0.5), 3, Color("#E0574A"), 1.2))
			var sk := W.icon_rect(UITheme.icon("skull"), Vector2(8, 8))
			sk.position = Vector2(19, 1)
			sk.size = Vector2(8, 8)
			b.add_child(sk)
		row.add_child(b)
	# readiness: a verdict seal and the elements of the zone with the party's weakest resistance
	var els := ZoneInfo.elements(z)
	var ready := ZoneInfo.readiness(z, _diff)
	var rcol: Color = {"ok": UITheme.C_GREEN, "hard": Color("#FFC94A"), "very_hard": Color("#FF6A5A")}[ready]
	var rx := 6.0 + ids.size() * 26.0 + 6.0
	var rbox := Control.new()
	rbox.mouse_filter = Control.MOUSE_FILTER_STOP
	rbox.position = Vector2(rx, 20)
	rbox.size = Vector2(w - rx - 6, 30)
	var tip := DataDB.t("ready_tip_" + ready)
	if els.size() > 0:
		var names: Array = []
		for el in els:
			names.append(ZoneInfo.element_name(el))
		tip += "\n" + DataDB.t("zone_elements", {"list": ", ".join(names), "want": int(ZoneInfo.TARGET_RES)})
	if ready != "ok":
		tip += "\n" + ZoneInfo.hint(z, _diff)
	rbox.tooltip_text = tip
	rbox.draw.connect(func():
		var ci := rbox.get_canvas_item()
		var r := Rect2(Vector2.ZERO, rbox.size)
		UISkin.well(ci, r)
		var f := UITheme.font_body
		var verdict := DataDB.t("ready_" + ready)
		var vw := f.get_string_size(verdict, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		rbox.draw_string(f, Vector2((r.size.x - vw) / 2.0, 11), verdict, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 8, rcol)
		if els.is_empty():
			var none := DataDB.t("zone_physical")
			var nw := f.get_string_size(none, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			rbox.draw_string(f, Vector2((r.size.x - nw) / 2.0, 23), none, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 7, UITheme.C_DIM)
			return
		# one chip per element: coloured gem + the party's weakest resistance against it
		var chips: Array = []
		var tot := 0.0
		for el in els:
			var t := "%d%%" % int(ZoneInfo.party_res(el, _diff))
			var cw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 9.0
			chips.append([el, t, cw])
			tot += cw + 3.0
		var x := maxf(2.0, (r.size.x - tot + 3.0) / 2.0)
		for chp in chips:
			var col: Color = EL_COL.get(chp[0], Color.WHITE)
			UISkin.diamond(ci, Vector2(x + 3, 20.5), 2.6, col.lightened(0.3), col.darkened(0.35))
			var low := ZoneInfo.party_res(str(chp[0]), _diff) < ZoneInfo.TARGET_RES
			rbox.draw_string(f, Vector2(x + 7, 23.5), str(chp[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#FF9A8A") if low else UITheme.C_TEXT)
			x += float(chp[2]) + 3.0)
	_card.add_child(rbox)
	# boss line
	var bl := UITheme.label("☠ " + DataDB.t("boss") + ": " + DataDB.tx(DataDB.enemy_def(str(z.get("boss", ""))).get("name", {})), Color("#FF9A8A"), 8)
	bl.position = Vector2(6, 52)
	bl.size = Vector2(w - 12, 10)
	bl.clip_text = true
	bl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card.add_child(bl)
	_stage_picker(zi, w, h)


## DPS gauge, stage pills (1-9, 10 = boss) up to the furthest stage reached, and the Play button.
func _stage_picker(zi: int, w: float, h: float) -> void:
	var unlocked: bool = zi <= int(GameState.progress["max_zone"][_diff])
	var rec: Dictionary = BattleSim.zone_record(_diff, zi)
	var playing: bool = BattleSim.mode == "zone" and zi == BattleSim.zone_idx and _diff == BattleSim.difficulty
	if zi != _sel_zone:
		_sel_zone = zi
		_sel_stage = BattleSim.stage if playing else int(rec["last"])
	var gauge := Control.new()
	gauge.name = "DpsNeed"
	gauge.mouse_filter = Control.MOUSE_FILTER_STOP
	gauge.tooltip_text = DataDB.t("dps_gauge_tip")
	gauge.position = Vector2(6, 64)
	gauge.size = Vector2(w - 12, 11)
	gauge.draw.connect(func():
		var need := ZoneInfo.dps_needed(z_of(zi), _sel_stage, _diff)
		var have := BattleSim.party_dps()
		var col := UITheme.C_GREEN if have >= need else (Color("#FFC94A") if have >= need * 0.6 else Color("#FF7A6A"))
		var f := UITheme.font_body
		var lt := DataDB.t("dps_need_l", {"n": F.fmt_num(need)})
		var rt := DataDB.t("dps_have_r", {"n": F.fmt_num(have) if have > 0.0 else "—"})
		var lw := f.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var rw := f.get_string_size(rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		gauge.draw_string(f, Vector2(0, 8), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM)
		gauge.draw_string(f, Vector2(gauge.size.x - rw, 8), rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col)
		var bar := Rect2(lw + 6, 3, gauge.size.x - lw - rw - 12, 5)
		if bar.size.x > 10:
			var ci := gauge.get_canvas_item()
			UISkin.fill(ci, bar, 2, Color("#0C0806"), Color("#1A120C"))
			var k := clampf(have / maxf(1.0, need), 0.0, 1.0)
			if k > 0.0:
				UISkin.fill(ci, Rect2(bar.position, Vector2(maxf(3.0, bar.size.x * k), bar.size.y)), 2, col.lightened(0.25), col.darkened(0.3))
			UISkin.stroke(ci, bar, 2, Color(0, 0, 0, 0.9), 0.8))
	_card.add_child(gauge)
	var n := BattleSim.stages_per_zone()
	var pw := (w - 12.0 - (n - 1) * 2.0) / n
	var py := 78.0
	for i in n:
		var st := i + 1
		var open: bool = unlocked and st <= int(rec["max"])
		var boss: bool = st == n
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.position = Vector2(6 + i * (pw + 2.0), py)
		b.size = Vector2(pw, 15)
		b.disabled = not open
		b.tooltip_text = (DataDB.t("boss") if boss else DataDB.t("world_stage_n", {"n": st})) + ("" if open else "  🔒") \
			+ "\n" + DataDB.t("dps_need_short", {"n": F.fmt_num(ZoneInfo.dps_needed(z_of(zi), st, _diff))})
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var r := Rect2(Vector2.ZERO, b.size)
			var sel := st == _sel_stage
			var here := playing and st == BattleSim.stage
			var top := Color("#7A2E22") if boss else Color("#4A3A2C")
			if sel:
				top = Color("#D8A04A")
			if not open:
				top = Color("#24222A")
			UISkin.fill(ci, r, 3, top.lightened(0.15 if b.is_hovered() and open else 0.0), top.darkened(0.45))
			UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
			if sel:
				UISkin.stroke(ci, r.grow(-1.0), 2, Color("#FFE7A6", 0.8), 0.8)
			if here:
				UISkin.stroke(ci, r.grow(0.8), 3, Color("#7CFF9A"), 1.0)
			var f := UITheme.font_body
			if boss:
				b.draw_texture_rect(UITheme.icon("skull"), Rect2(r.get_center() - Vector2(4, 4), Vector2(8, 8)), false,
					Color("#1A1208") if sel else (Color("#FFD8C8") if open else Color("#5A5560")))
				return
			var txt := str(st)
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			b.draw_string(f, Vector2((r.size.x - tw) / 2.0, 11), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color("#1A1208") if sel else (UITheme.C_TEXT if open else Color("#5A5560"))))
		b.mouse_entered.connect(b.queue_redraw)
		b.mouse_exited.connect(b.queue_redraw)
		b.pressed.connect(func():
			_sel_stage = st
			AudioManager.play("ui_click", 0.05, 0.5)
			gauge.queue_redraw()
			for ch in b.get_parent().get_children():
				if ch is Button:
					ch.queue_redraw())
		_card.add_child(b)
	var by := minf(h - 22.0, py + 20.0)
	var info := UITheme.label(DataDB.t("world_playing") if playing else (DataDB.t("world_resume", {"n": int(rec["last"])}) if unlocked else DataDB.t("world_locked_zone")),
		UITheme.C_GREEN if playing else UITheme.C_DIM, 8, UITheme.font_body)
	info.position = Vector2(6, by + 4)
	info.size = Vector2(w - 104, 10)
	info.clip_text = true
	info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card.add_child(info)
	var play := UITheme.button(DataDB.t("world_play"), "gold", func():
		BattleSim.mode = "zone"
		BattleSim.go_to_zone(zi, _diff, _sel_stage)
		AudioManager.play("ui_travel")
		refresh(), Vector2(88, 18))
	_card.add_child(play)
	play.size = Vector2(88, 18)
	play.position = Vector2(w - 94, by)
	play.disabled = not unlocked


func _cycle_diff() -> void:
	var maxz: Array = GameState.progress.get("max_zone", [0, -1, -1])
	for k in 3:
		_diff = (_diff + 1) % 3
		if int(maxz[_diff]) >= 0:
			break
	AudioManager.play("ui_click", 0.05, 0.5)
	refresh()


func _set_act(a: int) -> void:
	act = a
	refresh()


func refresh() -> void:
	if _map == null:
		return
	_diff_btn.queue_redraw()
	_build_tabs()
	_map.texture = UITheme.tex("map_act%d" % act)
	_overlay.queue_redraw()
	for ch in _nodes_root.get_children():
		ch.queue_free()
	var nodes_data: Dictionary = DataDB._load("res://data/map_nodes.json")
	var pts: Array = nodes_data.get(str(act), [])
	var maxz: int = int(GameState.progress["max_zone"][_diff])
	var cur: int = int(GameState.progress.get("zone", 0))
	var cur_diff: int = int(GameState.progress.get("difficulty", 0))
	for i in pts.size():
		var zi := (act - 1) * 10 + i
		var z := DataDB.zone(zi)
		if z.is_empty():
			continue
		var p: Array = pts[i]
		var cleared: bool = GameState.progress["cleared"].has("%d_%s" % [_diff, z["id"]])
		var state := "cleared" if cleared else ("open" if zi <= maxz else "locked")
		var lvtxt := "%s %d–%d" % [DataDB.t("lv_short").capitalize(), F.monster_level(z, 1, _diff), F.monster_level(z, 10, _diff)]
		var tip := "%s\n%s\n%s: %s" % [DataDB.tx(z["name"]), lvtxt, DataDB.t("boss"), DataDB.tx(DataDB.enemy_def(z["boss"]).get("name", {}))]
		var here := zi == cur and _diff == cur_diff
		_nodes_root.add_child(_waypoint(Vector2(float(p[0]), float(p[1])), i + 1, state, here, zi, tip))
		if here:
			# party leader standing on the current zone
			var lead: String = GameState.party[0] if GameState.party[0] != "" else "kael"
			var chibi := SpriteLib.chibi_frame("heroes", lead)
			var m := W.icon_rect(chibi if chibi else SpriteLib.hero_icon(lead), Vector2(20, 18))
			m.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			m.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			m.size = Vector2(20, 18)
			m.position = Vector2(float(p[0]), float(p[1])) + Vector2(-11, -24)
			_nodes_root.add_child(m)
	_show_card(_sel_zone if _sel_zone >= 0 and int(DataDB.zone(_sel_zone).get("act", 0)) == act else cur)
	refresh_nodes_highlight()


## Gold ring around the zone picked on the map.
func refresh_nodes_highlight() -> void:
	for ch in _nodes_root.get_children():
		if ch.has_meta("sel_ring"):
			ch.queue_free()
	var nodes_data: Dictionary = DataDB._load("res://data/map_nodes.json")
	var pts: Array = nodes_data.get(str(act), [])
	var i := _sel_zone - (act - 1) * 10
	if i < 0 or i >= pts.size():
		return
	var ring := Control.new()
	ring.set_meta("sel_ring", true)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(float(pts[i][0]) - 10, float(pts[i][1]) - 10)
	ring.size = Vector2(20, 20)
	ring.draw.connect(func():
		ring.draw_arc(Vector2(10, 10), 8.6, 0, TAU, 28, Color(0, 0, 0, 0.8), 2.6, true)
		ring.draw_arc(Vector2(10, 10), 8.6, 0, TAU, 28, Color("#FFD35A"), 1.3, true))
	_nodes_root.add_child(ring)
	_nodes_root.move_child(ring, 0)


func _travel(zi: int) -> void:
	BattleSim.mode = "zone"
	BattleSim.go_to_zone(zi, _diff)
	AudioManager.play("ui_travel")
	refresh()


func z_of(zi: int) -> Dictionary:
	return DataDB.zone(zi)
