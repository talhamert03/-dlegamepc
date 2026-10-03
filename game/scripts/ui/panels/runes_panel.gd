extends PanelWindow
## Leadership runes (the player's own tree, account-wide, bought with gold): a pannable board of carved rune
## stones joined by lines, the gold plaque in the corner and, on the right, the parchment list of every
## bonus learned (and whom it reaches) plus the details of the hovered rune. Rune stones (square, stat glyphs) are deliberately unlike the
## round class-skill medallions of the Status window.

const G := 28.0          # grid step between nodes
const NS := 20.0         # node frame size
const SIDE_W := 124.0

var _board: Control
var _side: Control
var _list: VBoxContainer
var _detail: Control
var _buy: Button
var _pan := Vector2.ZERO
var _drag := false
var _drag_moved := false
var _drag_start := Vector2.ZERO
var _pan_start := Vector2.ZERO
var _hover := ""
var _sel := "core"
var _detail_id := "core"
var _t := 0.0
var _flash := {}         # id -> remaining flash time
var _icons := {}


func build(c: Control) -> void:

	var bw := c.size.x - SIDE_W - 4.0
	_board = Control.new()
	_board.size = Vector2(bw, c.size.y)
	_board.clip_contents = true
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_on_board_input)
	_board.mouse_exited.connect(func():
		_hover = ""
		WindowManager.hide_tooltip())
	c.add_child(_board)
	# gold plaque over the board
	var plaque := Control.new()
	plaque.position = Vector2(6, 5)
	plaque.size = Vector2(70, 14)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.draw.connect(func():
		var ci := plaque.get_canvas_item()
		var r := Rect2(Vector2.ZERO, plaque.size)
		UISkin.fill(ci, r, 3, Color("#2B2420"), Color("#15110F"))
		UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.9), 1.0)
		var gi := UITheme.icon("gold")
		if gi:
			plaque.draw_texture_rect(gi, Rect2(3, 3, 8, 8), false)
		var s := F.fmt_num(GameState.gold)
		var f := UITheme.font_body
		var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		plaque.draw_string(f, Vector2(r.size.x - tw - 5, 10), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_TEXT))
	c.add_child(plaque)
	_side = Control.new()
	_side.position = Vector2(bw + 4.0, 0)
	_side.size = Vector2(SIDE_W, c.size.y)
	c.add_child(_side)
	_build_side()
	EventBus.gold_changed.connect(func(_g):
		plaque.queue_redraw()
		_update_detail())
	EventBus.runes_changed.connect(func():
		_refresh_list()
		_update_detail()
		_side.get_child(0).queue_redraw())
	_refresh_list()
	_update_detail()


func _build_side() -> void:
	var w := SIDE_W
	var list_h := _side.size.y - 96.0
	var parch := Control.new()
	parch.size = Vector2(w, list_h)
	parch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parch.draw.connect(func():
		var ci := parch.get_canvas_item()
		UISkin.parchment(ci, Rect2(Vector2(0, 6), parch.size - Vector2(0, 6)))
		var rib := Rect2(10, 0, w - 20, 13)
		UISkin.fill(ci, rib, 3, Color("#3A2A22"), Color("#1E1512"))
		UISkin.stroke(ci, rib, 3, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, rib.grow(-1.0), 2, Color(UISkin.BRONZE, 0.8), 1.0)
		var t := "· " + DataDB.t("rune_stat_list") + " ·"
		var f := UITheme.font_title
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		parch.draw_string(f, Vector2((w - tw) / 2.0, 10), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#F3D58F")))
	_side.add_child(parch)
	var sc := W.scroll(Vector2(w - 10, list_h - 22))
	sc.position = Vector2(6, 17)
	_side.add_child(sc)
	_list = W.vbox(0)
	_list.custom_minimum_size = Vector2(w - 18, 0)
	sc.add_child(_list)
	_detail = Control.new()
	_detail.position = Vector2(0, list_h + 3)
	_detail.size = Vector2(w, 93)
	_detail.draw.connect(_draw_detail)
	_side.add_child(_detail)
	_buy = UITheme.button(DataDB.t("rune_buy"), "gold", func():
		_sel = _detail_id
		_try_buy(_detail_id), Vector2(w - 12, 14))
	_detail.add_child(_buy)
	_buy.size = Vector2(w - 12, 14)
	_buy.position = Vector2(6, 75)


func _icon(id: String) -> Texture2D:
	var g := Runes.glyph(id)
	if not _icons.has(g):
		_icons[g] = UITheme.icon(g)
	return _icons[g]


func _refresh_list() -> void:
	for ch in _list.get_children():
		ch.queue_free()
	var any := false
	var groups: Array = [{"key": "", "name": {"tr": "Öz", "en": "Core"}, "color": "#8A5A2A"}] + Runes.branches()
	for g in groups:
		var rows: Array = []
		for id in GameState.runes:
			var nd := Runes.node(str(id))
			if nd.is_empty() or str(nd.get("br", "")) != str(g["key"]):
				continue
			rows.append([str(nd["stat"]), float(nd["per"]) * int(GameState.runes[id]), Runes.reach_text(str(id)), Runes.classes(str(id)).is_empty()])
		if rows.is_empty():
			continue
		any = true
		_list.add_child(UITheme.label(DataDB.tx(g["name"]), Color(str(g["color"])).darkened(0.55), 8, UITheme.font_title))
		for r in rows:
			var who: String = "" if r[3] else "  (" + str(r[2]) + ")"
			var l := UITheme.label("· " + _bonus_text(str(r[0]), float(r[1])) + who, UISkin.INK, 7, UITheme.font_body)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(SIDE_W - 20, 0)
			_list.add_child(l)
	if not any:
		var l2 := UITheme.label(DataDB.t("rune_none"), Color(UISkin.INK, 0.75), 7, UITheme.font_body)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.custom_minimum_size = Vector2(SIDE_W - 20, 0)
		_list.add_child(l2)


func _bonus_text(st: String, v: float) -> String:
	var num := ("%d" % int(round(v))) if absf(v - round(v)) < 0.05 else ("%.1f" % v)
	return ("+%s %s" if StatNames.is_flat(st) else "+%s%% %s") % [num, StatNames.label(st)]


func _process(delta: float) -> void:
	_t += delta
	for k in _flash.keys():
		_flash[k] = float(_flash[k]) - delta
		if float(_flash[k]) <= 0.0:
			_flash.erase(k)
	if _board:
		_board.queue_redraw()


# ------------------------------------------------------------------ board
func _center() -> Vector2:
	return _board.size / 2.0 + Vector2(0, 12) + _pan


func _node_pos(id: String) -> Vector2:
	var p := Runes.pos(id)
	return _center() + Vector2(p.x, p.y) * G


func _node_at(local: Vector2) -> String:
	for id in Runes.nodes():
		var half := (NS + (4.0 if id == "core" or Runes.is_cap(id) else 0.0)) / 2.0
		if Rect2(_node_pos(id) - Vector2(half, half), Vector2(half, half) * 2.0).has_point(local):
			return id
	return ""


func _draw_board() -> void:
	var ci := _board.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _board.size)
	UISkin.fill(ci, r, 3, Color("#24222A"), Color("#16151A"))
	# stone floor: slightly uneven tiles that move with the board
	var tile := 14.0
	var off := Vector2(fposmod(_pan.x, tile), fposmod(_pan.y, tile))
	var nx := int(r.size.x / tile) + 2
	var ny := int(r.size.y / tile) + 2
	for j in ny:
		for i in nx:
			var gx := i - int(floor(_pan.x / tile))
			var gy := j - int(floor(_pan.y / tile))
			var hsh := absi((gx * 73856093) ^ (gy * 19349663)) % 7
			if hsh < 3:
				_board.draw_rect(Rect2(off + Vector2(i - 1, j - 1) * tile, Vector2(tile - 1, tile - 1)), Color(1, 1, 1, 0.012 * (hsh + 1)))
	for j in ny:
		_board.draw_line(Vector2(0, off.y + (j - 1) * tile), Vector2(r.size.x, off.y + (j - 1) * tile), Color(0, 0, 0, 0.22), 1.0)
	for i in nx:
		_board.draw_line(Vector2(off.x + (i - 1) * tile, 0), Vector2(off.x + (i - 1) * tile, r.size.y), Color(0, 0, 0, 0.22), 1.0)
	# links
	for id in Runes.nodes():
		for l in Runes.links(id):
			var a := _node_pos(str(l))
			var b := _node_pos(id)
			var lit := Runes.rank(id) > 0 and Runes.rank(str(l)) > 0
			var open := Runes.rank(str(l)) > 0
			if lit:
				var bc := Runes.branch_color(id)
				_board.draw_line(a, b, Color(bc, 0.25), 4.0, true)
				_board.draw_line(a, b, Color("#E9D7A8"), 1.6, true)
			elif open:
				_board.draw_line(a, b, Color("#8A7556"), 1.4, true)
			else:
				_board.draw_line(a, b, Color("#3C3842"), 1.2, true)
	# capstone halos
	for id in Runes.nodes():
		if Runes.is_cap(id):
			var cc := _node_pos(id)
			var bc2 := Runes.branch_color(id)
			var pulse := 0.5 + 0.5 * sin(_t * 2.0)
			_board.draw_circle(cc, 19.0, Color(bc2, 0.06 + 0.05 * pulse))
			_board.draw_arc(cc, 17.0, 0, TAU, 32, Color(bc2, 0.35), 1.0, true)
	# nodes
	for id in Runes.nodes():
		_draw_node(ci, id)
	# branch names on a banner just past each capstone
	var fb := UITheme.font_title
	for b in Runes.branches():
		var key := str(b["key"])
		if not Runes.nodes().has(key + "_cap"):
			continue
		var pc := _node_pos(key + "_cap")
		var dir := (pc - _node_pos(key + "6")).normalized()
		var txt := DataDB.tx(b["name"])
		var tw := fb.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var anchor := pc + dir * 26.0
		var at := anchor + Vector2(-tw / 2.0, 3.0)
		if absf(dir.x) > 0.5:
			at = anchor + Vector2(0.0 if dir.x > 0 else -tw, 3.0) + Vector2(-8.0 * dir.x, 0)
		var col := Color(str(b["color"]))
		var plate := Rect2(at + Vector2(-4, -9), Vector2(tw + 8, 12))
		UISkin.fill(ci, plate, 3, Color(0.1, 0.08, 0.1, 0.85), Color(0.05, 0.04, 0.05, 0.85))
		UISkin.stroke(ci, plate, 3, Color(col, 0.7), 1.0)
		_board.draw_string(fb, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


func _draw_node(ci: RID, id: String) -> void:
	var c := _node_pos(id)
	var sz := NS + (4.0 if id == "core" or Runes.is_cap(id) else 0.0)
	var rr := Rect2(c - Vector2(sz, sz) / 2.0, Vector2(sz, sz))
	if not rr.grow(4).intersects(Rect2(Vector2.ZERO, _board.size)):
		return
	var rk := Runes.rank(id)
	var mx := Runes.max_rank(id)
	var open := Runes.is_open(id)
	var afford := Runes.can_buy(id)
	var bc := Runes.branch_color(id)
	# glow for affordable runes and the hovered / selected one
	if afford:
		var p := 0.5 + 0.5 * sin(_t * 4.0)
		UISkin.fill(ci, rr.grow(3.0), 4, Color(UITheme.C_GOLD, 0.18 * p), Color(UITheme.C_GOLD, 0.08 * p))
	if id == _hover or id == _sel:
		UISkin.stroke(ci, rr.grow(2.5), 4, Color(1, 1, 1, 0.55 if id == _hover else 0.3), 1.0)
	_stone(ci, rr, id, rk, open, afford)
	# rank pips along the bottom, check mark when maxed
	if rk >= mx:
		var o := rr.end - Vector2(6, 5)
		_board.draw_polyline(PackedVector2Array([o + Vector2(-2.5, 0), o + Vector2(-0.5, 2), o + Vector2(3, -2.5)]), Color(0, 0, 0, 0.9), 2.6, true)
		_board.draw_polyline(PackedVector2Array([o + Vector2(-2.5, 0), o + Vector2(-0.5, 2), o + Vector2(3, -2.5)]), Color("#7CFF9A"), 1.3, true)
	elif mx > 1:
		var pw := 2.0
		var gap := 1.0
		var total := mx * pw + (mx - 1) * gap
		var x0 := c.x - total / 2.0
		for k in mx:
			var pr := Rect2(x0 + k * (pw + gap), rr.end.y - 3.5, pw, 2.0)
			_board.draw_rect(pr.grow(0.5), Color(0, 0, 0, 0.9))
			_board.draw_rect(pr, bc if k < rk else Color("#3A3440"))
	# purchase flash
	if _flash.has(id):
		var f := float(_flash[id]) / 0.6
		UISkin.stroke(ci, rr.grow(2.0 + (1.0 - f) * 8.0), 4, Color(bc, f), 1.5)
		UISkin.fill(ci, rr, 2, Color(1, 1, 1, 0.35 * f), Color(1, 1, 1, 0.1 * f))


## A carved rune stone: bevelled grey slab, the stat glyph cut into it (dark when unlearned, glowing in the
## branch colour once learned) and a rim that tells its state.
func _stone(ci: RID, rr: Rect2, id: String, rk: int, open: bool, afford: bool) -> void:
	var bc := Runes.branch_color(id)
	var mx := Runes.max_rank(id)
	var pts := PackedVector2Array([rr.position + Vector2(3, 0), Vector2(rr.end.x - 3, rr.position.y), Vector2(rr.end.x, rr.position.y + 3),
		Vector2(rr.end.x, rr.end.y - 3), Vector2(rr.end.x - 3, rr.end.y), Vector2(rr.position.x + 3, rr.end.y),
		Vector2(rr.position.x, rr.end.y - 3), Vector2(rr.position.x, rr.position.y + 3)])
	var lit := rk > 0
	UISkin.poly(ci, pts, Color("#6A6672") if open else Color("#3A3840"), Color("#3A3640") if open else Color("#1E1D22"))
	# bevel
	_board.draw_line(rr.position + Vector2(3, 1), Vector2(rr.end.x - 3, rr.position.y + 1), Color(1, 1, 1, 0.22 if open else 0.08), 1.0)
	_board.draw_line(Vector2(rr.position.x + 3, rr.end.y - 1), Vector2(rr.end.x - 3, rr.end.y - 1), Color(0, 0, 0, 0.4), 1.0)
	if lit:
		_board.draw_circle(rr.get_center(), rr.size.x * 0.42, Color(bc, 0.22))
	var tex: Texture2D = _icon(id)
	if tex:
		var ir := rr.grow(-4.0)
		if lit:
			_board.draw_texture_rect(tex, ir.grow(0.8), false, Color(bc, 0.45))
			_board.draw_texture_rect(tex, ir, false, bc.lightened(0.35))
		else:
			# carved: a light lower edge under a dark cut
			_board.draw_texture_rect(tex, Rect2(ir.position + Vector2(0, 0.7), ir.size), false, Color(1, 1, 1, 0.12 if open else 0.05))
			_board.draw_texture_rect(tex, ir, false, Color(0.12, 0.11, 0.14, 0.9) if open else Color(0.1, 0.1, 0.12, 0.7))
	var border := Color("#2A2830")
	var bw := 1.0
	if rk >= mx:
		border = Color("#6FE08A")
		bw = 1.6
	elif lit:
		border = bc
		bw = 1.4
	elif afford:
		border = UITheme.C_GOLD
		bw = 1.4
	elif open:
		border = Color("#9A7A4E")
	var loop := pts.duplicate()
	loop.append(pts[0])
	_board.draw_polyline(loop, Color(0, 0, 0, 0.95), 2.6, true)
	_board.draw_polyline(loop, border, bw, true)


func _on_board_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_drag = true
			_drag_moved = false
			_drag_start = ev.position
			_pan_start = _pan
		else:
			if _drag and not _drag_moved:
				var id := _node_at(ev.position)
				if id != "":
					_sel = id
					_try_buy(id)
					_update_detail()
			_drag = false
		_board.accept_event()
	elif ev is InputEventMouseMotion:
		if _drag:
			var d: Vector2 = ev.position - _drag_start
			if d.length() > 3.0:
				_drag_moved = true
			if _drag_moved:
				_pan = (_pan_start + d).clamp(Vector2(-12 * G, -12 * G), Vector2(12 * G, 12 * G))
			_board.accept_event()
			return
		var h := _node_at(ev.position)
		if h != _hover:
			_hover = h
			if h != "":
				WindowManager.show_text_tooltip(_tip(h))
			else:
				WindowManager.hide_tooltip()
			_update_detail()


func _tip(id: String) -> String:
	var rk := Runes.rank(id)
	var mx := Runes.max_rank(id)
	var st := Runes.stat(id)
	var b := Runes.branch_of(id)
	var s := "%s  (%d/%d)\n%s%s" % [Runes.display_name(id), rk, mx, (DataDB.tx(b["name"]) + " · ") if not b.is_empty() else "",
		_bonus_text(st, Runes.per(id)) + (" / " + DataDB.t("rune_rank") if mx > 1 else "")]
	s += "\n" + DataDB.t("rune_reach", {"who": Runes.reach_text(id)})
	if Runes.is_cap(id):
		s += "\n" + DataDB.t("rune_capstone")
	if rk < mx:
		s += "\n" + (DataDB.t("rune_cost", {"g": F.fmt_num(Runes.cost(id))}) if Runes.is_open(id) else DataDB.t("rune_locked"))
	return s


func _try_buy(id: String) -> void:
	if id == "":
		return
	if Runes.buy(id):
		_flash[id] = 0.6
		AudioManager.play("smith_success", 0.06, 0.55)
		if _hover == id:
			WindowManager.show_text_tooltip(_tip(id))
	elif Runes.rank(id) < Runes.max_rank(id) and Runes.is_open(id):
		AudioManager.play("smith_fail", 0.05, 0.35)


# ------------------------------------------------------------------ detail card
func _update_detail() -> void:
	if _detail == null:
		return
	var id := _hover if _hover != "" else _sel
	var rk := Runes.rank(id)
	var mx := Runes.max_rank(id)
	_buy.visible = rk < mx
	_buy.disabled = not Runes.can_buy(id)
	_buy.text = DataDB.t("rune_buy") + "  " + F.fmt_num(Runes.cost(id)) if Runes.is_open(id) else DataDB.t("rune_locked")
	_detail_id = id
	_detail.queue_redraw()


func _draw_detail() -> void:
	var ci := _detail.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _detail.size)
	UISkin.fill(ci, r, 3, Color("#2A2228"), Color("#141016"))
	UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.6), 1.0)
	var id := _hover if _hover != "" else _sel
	if not Runes.nodes().has(id):
		return
	var rk := Runes.rank(id)
	var mx := Runes.max_rank(id)
	var st := Runes.stat(id)
	var bc := Runes.branch_color(id)
	var ir := Rect2(6, 6, 22, 22)
	UISkin.fill(ci, ir, 3, Color("#6A6672"), Color("#3A3640"))
	var tex: Texture2D = _icon(id)
	if tex:
		_detail.draw_texture_rect(tex, ir.grow(-4.0), false, bc.lightened(0.35) if rk > 0 else Color(0.15, 0.14, 0.17))
	UISkin.stroke(ci, ir, 3, bc, 1.2)
	var f := UITheme.font_title
	_detail.draw_string(f, Vector2(32, 15), Runes.display_name(id), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 9, bc.lightened(0.2))
	_detail.draw_string(UITheme.font_body, Vector2(32, 26), "%d / %d  ·  " % [rk, mx] + Runes.reach_text(id), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 7, UITheme.C_DIM)
	var fb := UITheme.font_body
	var now := _bonus_text(st, Runes.per(id) * rk) if rk > 0 else "—"
	_detail.draw_string(fb, Vector2(7, 42), DataDB.t("rune_now") + ": " + now, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_TEXT)
	if rk < mx:
		_detail.draw_string(fb, Vector2(7, 53), DataDB.t("rune_next") + ": " + _bonus_text(st, Runes.per(id) * (rk + 1)), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_GREEN)
		if not Runes.is_open(id):
			_detail.draw_string(fb, Vector2(7, 66), DataDB.t("rune_need_link"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_RED)
	else:
		_detail.draw_string(fb, Vector2(7, 53), DataDB.t("rune_maxed"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, Color("#7CFF9A"))
