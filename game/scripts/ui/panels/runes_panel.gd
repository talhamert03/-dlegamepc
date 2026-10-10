extends PanelWindow
## Leadership runes (the player's own tree, account-wide, bought with gold): a pannable board of carved rune
## stones joined by lines, the gold plaque in the corner and, on the right, the parchment list of every
## bonus learned (and whom it reaches) plus the details of the hovered rune. Rune stones (square, stat glyphs) are deliberately unlike the
## round class-skill medallions of the Status window.

const G := 28.0          # grid step between nodes
const NS := 20.0         # node frame size
const SIDE_W := 124.0
const SLATE := preload("res://assets/ui_hd/frame/slate.png")
const SLATE_TILE := 96.0

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
		UISkin.groove(ci, r, 3)
		UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-0.8), 2.5, Color(UISkin.BRONZE_HI, 0.75), 0.7)
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
	# the gold coin right in front of the price (Button.icon would sit at the far left edge)
	_buy.draw.connect(func():
		if not _buy.get_meta("coin", false):
			return
		var tw := UITheme.font_body.get_string_size(_buy.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var x := (_buy.size.x - tw) / 2.0 - 11.0
		_buy.draw_texture_rect(UITheme.icon("gold"), Rect2(x, (_buy.size.y - 8.0) / 2.0, 8, 8), false, Color(1, 1, 1, 0.45) if _buy.disabled else Color.WHITE))


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
	if StatNames.is_flat(st):
		return "+%s %s" % [num, StatNames.label(st)]
	return "%s %s" % [F.pct(v, true), StatNames.label(st)]


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
	# veined slate floor (painted HD tile) that moves with the board
	var o := Vector2(fposmod(_pan.x, SLATE_TILE), fposmod(_pan.y, SLATE_TILE)) - Vector2(SLATE_TILE, SLATE_TILE)
	var y := o.y
	while y < r.size.y:
		var x := o.x
		while x < r.size.x:
			_board.draw_texture_rect(SLATE, Rect2(x, y, SLATE_TILE, SLATE_TILE), false)
			x += SLATE_TILE
		y += SLATE_TILE
	# the summoning circle engraved around the core: warm glow, three rings, ticks and rune dashes
	var core := _node_pos("core")
	for k in 10:
		_board.draw_circle(core, G * 3.2 * (1.0 - k * 0.09), Color(1.0, 0.78, 0.4, 0.022))
	var rot := _t * 0.03
	for ring in [[1.55, 0.16], [3.45, 0.12], [5.5, 0.09]]:
		var rad: float = G * float(ring[0])
		var al: float = ring[1]
		_board.draw_arc(core, rad, 0, TAU, 96, Color(0, 0, 0, al * 2.5), 2.2, true)
		_board.draw_arc(core, rad, 0, TAU, 96, Color("#D8B46A", al), 0.8, true)
		_board.draw_arc(core, rad + 3.0, 0, TAU, 96, Color("#D8B46A", al * 0.6), 0.5, true)
		var n := int(rad * 0.55)
		for i in n:
			var ang := rot * (1.0 if int(rad) % 2 == 0 else -1.0) + TAU * i / n
			var dir := Vector2.from_angle(ang)
			if i % 6 == 0:
				# a rune dash: a short arc between the two rings
				_board.draw_arc(core, rad + 1.5, ang - 0.04, ang + 0.04, 4, Color("#F2D48A", al * 1.6), 1.6, true)
			else:
				_board.draw_line(core + dir * rad, core + dir * (rad + 3.0), Color("#D8B46A", al * 0.8), 0.5, true)
	# links: lit = an energy channel with a pulse flowing outwards, open = an engraved groove, locked = a faint scratch
	for id in Runes.nodes():
		for l in Runes.links(id):
			var a := _node_pos(str(l))
			var b := _node_pos(id)
			if not Rect2(a, Vector2.ZERO).expand(b).grow(8).intersects(r):
				continue
			var lit := Runes.rank(id) > 0 and Runes.rank(str(l)) > 0
			var open := Runes.rank(str(l)) > 0
			if lit:
				var bc := Runes.branch_color(id)
				_board.draw_line(a, b, Color(bc, 0.16), 6.0, true)
				_board.draw_line(a, b, Color(bc.lightened(0.2), 0.75), 2.2, true)
				_board.draw_line(a, b, Color("#FFF3D0", 0.9), 0.8, true)
				var ph := fposmod(_t * 0.55 + float(hash(id) % 97) / 97.0, 1.0)
				_board.draw_circle(a.lerp(b, ph), 1.6, Color(1, 0.97, 0.85, 0.85 * sin(ph * PI)))
			elif open:
				_board.draw_line(a, b, Color(0, 0, 0, 0.65), 2.6, true)
				_board.draw_line(a + Vector2(0, 0.5), b + Vector2(0, 0.5), Color("#B08A5A", 0.55), 0.8, true)
			else:
				_board.draw_line(a, b, Color(0, 0, 0, 0.45), 1.8, true)
				_board.draw_line(a, b, Color("#4A4656", 0.6), 0.6, true)
	# capstone halos
	for id in Runes.nodes():
		if Runes.is_cap(id):
			var cc := _node_pos(id)
			var bc2 := Runes.branch_color(id)
			var pulse := 0.5 + 0.5 * sin(_t * 2.0)
			_board.draw_circle(cc, 19.0, Color(bc2, 0.06 + 0.05 * pulse))
			_board.draw_arc(cc, 17.0, 0, TAU, 48, Color(0, 0, 0, 0.5), 2.0, true)
			_board.draw_arc(cc, 17.0, 0, TAU, 48, Color(bc2, 0.45), 0.9, true)
			for q in 8:
				var dp := cc + Vector2.from_angle(_t * 0.25 + TAU * q / 8.0) * 17.0
				UISkin.diamond(_board.get_canvas_item(), dp, 1.5, Color(bc2.lightened(0.4), 0.9), Color(bc2.darkened(0.3), 0.9))
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
	_vignette()


## Dark falloff at the board edges so it reads as a lit table under the window frame.
func _vignette() -> void:
	var r := Rect2(Vector2.ZERO, _board.size)
	var e := 22.0
	var sh := Color(0, 0, 0, 0.55)
	var cl := Color(0, 0, 0, 0)
	_board.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), Vector2(r.size.x, e), Vector2(0, e)]), PackedColorArray([sh, sh, cl, cl]))
	_board.draw_polygon(PackedVector2Array([Vector2(0, r.size.y - e), Vector2(r.size.x, r.size.y - e), r.size, Vector2(0, r.size.y)]), PackedColorArray([cl, cl, sh, sh]))
	_board.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(e, 0), Vector2(e, r.size.y), Vector2(0, r.size.y)]), PackedColorArray([sh, cl, cl, sh]))
	_board.draw_polygon(PackedVector2Array([Vector2(r.size.x - e, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y), Vector2(r.size.x - e, r.size.y)]), PackedColorArray([cl, sh, sh, cl]))


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
	if rk > 0:
		# learned runes breathe a soft light in their branch colour
		var br := 0.5 + 0.5 * sin(_t * 1.6 + float(hash(id) % 31))
		_board.draw_circle(c, sz * 0.95, Color(bc, 0.06 + 0.04 * br))
	if id == "core":
		_board.draw_arc(c, sz * 0.78, 0, TAU, 40, Color(0, 0, 0, 0.6), 2.4, true)
		_board.draw_arc(c, sz * 0.78, 0, TAU, 40, Color("#F2D48A", 0.8), 1.0, true)
	if id == _hover or id == _sel:
		UISkin.stroke(ci, rr.grow(2.5), 4, Color(1, 1, 1, 0.55 if id == _hover else 0.3), 1.0)
	_stone(ci, rr, id, rk, open, afford)
	# rank pips along the bottom, check mark when maxed
	if rk >= mx:
		var o := rr.end - Vector2(6, 5)
		_board.draw_polyline(PackedVector2Array([o + Vector2(-2.5, 0), o + Vector2(-0.5, 2), o + Vector2(3, -2.5)]), Color(0, 0, 0, 0.9), 2.6, true)
		_board.draw_polyline(PackedVector2Array([o + Vector2(-2.5, 0), o + Vector2(-0.5, 2), o + Vector2(3, -2.5)]), Color("#7CFF9A"), 1.3, true)
	elif mx > 1:
		# rank gauge sunk into the bottom rim, never wider than the stone: segments up to 5 ranks, a bar above
		var gw := rr.size.x - 7.0
		var g := Rect2(c.x - gw / 2.0, rr.end.y - 1.6, gw, 2.4)
		_board.draw_rect(g.grow(0.7), Color(0, 0, 0, 0.92))
		if mx <= 5:
			var sw := (gw - (mx - 1) * 1.0) / mx
			for k in mx:
				_board.draw_rect(Rect2(g.position.x + k * (sw + 1.0), g.position.y, sw, g.size.y), bc.lightened(0.15) if k < rk else Color("#3A3440"))
		else:
			_board.draw_rect(g, Color("#3A3440"))
			if rk > 0:
				_board.draw_rect(Rect2(g.position, Vector2(gw * rk / mx, g.size.y)), bc.lightened(0.15))
				_board.draw_rect(Rect2(g.position, Vector2(gw * rk / mx, 0.8)), Color(1, 1, 1, 0.45))
	# purchase flash
	if _flash.has(id):
		var f := float(_flash[id]) / 0.6
		UISkin.stroke(ci, rr.grow(2.0 + (1.0 - f) * 8.0), 4, Color(bc, f), 1.5)
		UISkin.fill(ci, rr, 2, Color(1, 1, 1, 0.35 * f), Color(1, 1, 1, 0.1 * f))


## A carved rune stone: an octagonal slab with a drop shadow, an inner bevel, the stat glyph cut into it
## (dark when unlearned, glowing in the branch colour once learned, with an inner light) and a rim that
## tells its state: gold = affordable, branch colour = learned, green = maxed. Drawn on `cv`.
func _stone(ci: RID, rr: Rect2, id: String, rk: int, open: bool, afford: bool, cv: CanvasItem = null) -> void:
	if cv == null:
		cv = _board
	var bc := Runes.branch_color(id)
	var mx := Runes.max_rank(id)
	var lit := rk > 0
	var pts := _octagon(rr, 3.2)
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(0.3, 1.4))
	cv.draw_colored_polygon(shadow, Color(0, 0, 0, 0.55))
	var top := Color("#7A7684") if open else Color("#3C3A44")
	var bot := Color("#403C48") if open else Color("#1E1D23")
	if lit:
		top = Color("#5E5A6A").lerp(bc, 0.22)
		bot = Color("#24212A").lerp(bc, 0.10)
	UISkin.poly(ci, pts, top, bot)
	# inner bevel: lit upper-left facets, shaded lower-right ones
	var inner := _octagon(rr.grow(-2.2), 2.4)
	var il := inner.duplicate()
	il.append(inner[0])
	cv.draw_polyline(il, Color(0, 0, 0, 0.35), 0.8, true)
	cv.draw_polyline(PackedVector2Array([pts[6], pts[7], pts[0], pts[1]]), Color(1, 1, 1, 0.26 if open or lit else 0.08), 0.8, true)
	cv.draw_polyline(PackedVector2Array([pts[2], pts[3], pts[4], pts[5]]), Color(0, 0, 0, 0.45), 0.8, true)
	if lit:
		for k in 5:
			cv.draw_circle(rr.get_center(), rr.size.x * (0.46 - k * 0.07), Color(bc, 0.10))
	var tex: Texture2D = _icon(id)
	if tex:
		var ir := rr.grow(-4.0)
		if lit:
			cv.draw_texture_rect(tex, ir.grow(1.0), false, Color(bc, 0.45))
			cv.draw_texture_rect(tex, ir, false, bc.lightened(0.45))
		else:
			# carved: a light lower edge under a dark cut
			cv.draw_texture_rect(tex, Rect2(ir.position + Vector2(0, 0.7), ir.size), false, Color(1, 1, 1, 0.14 if open else 0.05))
			cv.draw_texture_rect(tex, ir, false, Color(0.10, 0.09, 0.12, 0.92) if open else Color(0.09, 0.09, 0.11, 0.7))
	var border := Color("#2A2830")
	var bw := 1.0
	if rk >= mx:
		border = Color("#7CEB96")
		bw = 1.5
	elif lit:
		border = bc.lightened(0.15)
		bw = 1.4
	elif afford:
		border = UITheme.C_GOLD
		bw = 1.4
	elif open:
		border = Color("#A8875A")
	var loop := pts.duplicate()
	loop.append(pts[0])
	cv.draw_polyline(loop, Color(0, 0, 0, 0.95), 2.6, true)
	cv.draw_polyline(loop, border, bw, true)


func _octagon(rr: Rect2, k: float) -> PackedVector2Array:
	return PackedVector2Array([rr.position + Vector2(k, 0), Vector2(rr.end.x - k, rr.position.y), Vector2(rr.end.x, rr.position.y + k),
		Vector2(rr.end.x, rr.end.y - k), Vector2(rr.end.x - k, rr.end.y), Vector2(rr.position.x + k, rr.end.y),
		Vector2(rr.position.x, rr.end.y - k), Vector2(rr.position.x, rr.position.y + k)])


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
	_buy.set_meta("coin", Runes.is_open(id))
	_buy.queue_redraw()
	_detail_id = id
	_detail.queue_redraw()


func _draw_detail() -> void:
	var ci := _detail.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _detail.size)
	var id := _hover if _hover != "" else _sel
	var has := Runes.nodes().has(id)
	var bc := Runes.branch_color(id) if has else UISkin.BRONZE
	# dark card, a header wash in the branch colour, gilded frame
	UISkin.fill(ci, r, 3, Color("#221B22"), Color("#100C10"))
	UISkin.fill(ci, Rect2(1, 1, r.size.x - 2, 32), 2.5, Color(bc, 0.30), Color(bc, 0.04))
	UISkin.line(ci, Vector2(6, 33.5), Vector2(r.size.x - 6, 33.5), Color(UISkin.BRONZE, 0.55), 0.7)
	UISkin.diamond(ci, Vector2(r.size.x / 2.0, 33.5), 1.8)
	UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.7), 0.8)
	if not has:
		return
	var rk := Runes.rank(id)
	var mx := Runes.max_rank(id)
	var st := Runes.stat(id)
	_stone(ci, Rect2(6, 6, 23, 23), id, rk, Runes.is_open(id), Runes.can_buy(id), _detail)
	var f := UITheme.font_title
	var rn := Runes.display_name(id)
	var rfs := 9
	while rfs > 6 and f.get_string_size(rn, HORIZONTAL_ALIGNMENT_LEFT, -1, rfs).x > r.size.x - 38:
		rfs -= 1
	_detail.draw_string_outline(f, Vector2(34, 15), rn, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 38, rfs, 2, Color(0, 0, 0, 0.7))
	_detail.draw_string(f, Vector2(34, 15), rn, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 38, rfs, bc.lightened(0.35))
	# rank pips (a single-rank rune has none: one empty box read as a glitch)
	var pw := minf(6.0, (r.size.x - 40.0 - (mx - 1) * 1.5) / maxf(1.0, mx))
	for k in (mx if mx > 1 else 0):
		var pr := Rect2(34 + k * (pw + 1.5), 19.5, pw, 2.5)
		_detail.draw_rect(pr.grow(0.5), Color(0, 0, 0, 0.9))
		_detail.draw_rect(pr, bc.lightened(0.2) if k < rk else Color("#3A3440"))
	_detail.draw_string(UITheme.font_body, Vector2(34, 30), Runes.reach_text(id), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 38, 7, UITheme.C_DIM)
	var fb := UITheme.font_body
	var now := _bonus_text(st, Runes.per(id) * rk) if rk > 0 else "—"
	_detail.draw_string(fb, Vector2(7, 45), DataDB.t("rune_now") + ": " + now, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_TEXT)
	if rk < mx:
		_detail.draw_string(fb, Vector2(7, 56), DataDB.t("rune_next") + ": " + _bonus_text(st, Runes.per(id) * (rk + 1)), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_GREEN)
		if not Runes.is_open(id):
			_detail.draw_string(fb, Vector2(7, 67), DataDB.t("rune_need_link"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, UITheme.C_RED)
	else:
		_detail.draw_string(fb, Vector2(7, 56), DataDB.t("rune_maxed"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 7, Color("#7CFF9A"))
