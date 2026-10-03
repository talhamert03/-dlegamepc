extends PanelWindow
## Town store, "the Emerald Caravan": a merchant's shop front (lanterns, shelves of curios), hanging tab
## signs and arched display niches with a price plaque each. Every product is bought with real money:
## a purchase asks for confirmation, goes through SteamService and ends with a reward reveal.

const COLS := 3
const CARD := Vector2(102, 118)
const FRONT_H := 44.0
const TABS_H := 17.0
const BADGE_COL := {"popular": Color("#3FA9F5"), "best": Color("#FF7A2E"), "once": Color("#3FCF6A"), "free": Color("#3FCF6A"),
	"support": Color("#C77DFF"), "earnable": Color("#C9A46A"), "double": Color("#FF4F6A")}
const RARITY_COL := {"R": Color("#A9B1C2"), "SR": Color("#5E9BFF"), "SSR": Color("#FFC24A")}
## velvet of the display niches, per tab: [top, bottom, glow]
const VELVET := {
	"chests": [Color("#6A1A26"), Color("#1C0609"), Color("#FF9A6A")],
	"gold": [Color("#1D5236"), Color("#06160D"), Color("#FFE08A")],
	"heroes": [Color("#22356E"), Color("#070C20"), Color("#9FC4FF")],
	"packs": [Color("#4B2172"), Color("#12061F"), Color("#E3A8FF")],
}
const TAB_ICON := {"chests": "chest", "gold": "gold", "heroes": "people", "packs": "gem"}

var _tab := "chests"
var _header: Control
var _tabs: Control
var _grid: Control
var _scroll: ScrollContainer
var _host: Control
var _t := 0.0
var _cards: Array = []
var _motes: Array = []


func build(c: Control) -> void:
	_host = c
	c.clip_contents = true
	var back := Control.new()
	back.size = c.size
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.draw.connect(func(): _draw_floor(back))
	c.add_child(back)
	_header = Control.new()
	_header.size = Vector2(c.size.x, FRONT_H)
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.draw.connect(func(): _draw_header(_header))
	c.add_child(_header)
	_tabs = Control.new()
	_tabs.position = Vector2(0, FRONT_H + 1)
	_tabs.size = Vector2(c.size.x, TABS_H)
	c.add_child(_tabs)
	var top := FRONT_H + TABS_H + 4.0
	_scroll = W.scroll(Vector2(c.size.x, c.size.y - top - 11.0))
	_scroll.position = Vector2(0, top)
	c.add_child(_scroll)
	_grid = Control.new()
	_scroll.add_child(_grid)
	var foot := UITheme.label(DataDB.t("shop_test_mode") if SteamService.payment_mode() == "direct" else DataDB.t("shop_hint"),
		UITheme.C_ORANGE if SteamService.payment_mode() == "direct" else UITheme.C_DIM, 6, UITheme.font_body)
	foot.position = Vector2(0, c.size.y - 10)
	foot.size = Vector2(c.size.x, 9)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.clip_text = true
	c.add_child(foot)
	for i in 14:
		_motes.append(Vector3(randf() * c.size.x, randf() * FRONT_H, randf() * TAU))
	EventBus.chests_changed.connect(_refresh_state)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _header:
		_header.queue_redraw()
	for cd in _cards:
		if is_instance_valid(cd):
			cd.queue_redraw()


func refresh() -> void:
	if _grid == null:
		return
	_build_tabs()
	for ch in _grid.get_children():
		ch.queue_free()
	_cards.clear()
	var entries: Array = []   # [product, hero_id]
	for p in Shop.products(_tab):
		if str(p.get("kind", "")) == "hero_pick":
			for hid in Shop.unowned(str(p.get("rarity", ""))):
				entries.append([p, hid])
		else:
			entries.append([p, ""])
	var gap := (_grid.get_parent_control().size.x - 6.0 - COLS * CARD.x) / (COLS - 1)
	for i in entries.size():
		_card(entries[i][0], str(entries[i][1]), Vector2((i % COLS) * (CARD.x + gap), (i / COLS) * (CARD.y + 6.0)))
	_grid.custom_minimum_size = Vector2(_host.size.x - 6, ceil(entries.size() / float(COLS)) * (CARD.y + 6.0))


# ------------------------------------------------------------------ shop front
func _draw_floor(n: Control) -> void:
	var ci := n.get_canvas_item()
	var r := Rect2(Vector2(0, FRONT_H), n.size - Vector2(0, FRONT_H))
	UISkin.fill(ci, r, 0, Color("#2A1A12"), Color("#120A07"))
	# dark oak wall planks behind the niches
	var x := 0.0
	var i := 0
	while x < r.size.x:
		var pw := 22.0 + float((i * 7) % 9)
		n.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.35), 1.0)
		n.draw_line(Vector2(x + 1, r.position.y), Vector2(x + 1, r.end.y), Color(1, 0.8, 0.6, 0.04), 1.0)
		x += pw
		i += 1


func _draw_header(n: Control) -> void:
	var ci := n.get_canvas_item()
	var w := n.size.x
	var h := FRONT_H
	UISkin.fill(ci, Rect2(0, 0, w, h), 0, Color("#4A2C18"), Color("#1F120A"))
	for k in 9:
		var px := k * w / 8.0
		n.draw_line(Vector2(px, 0), Vector2(px, h), Color(0, 0, 0, 0.3), 1.0)
	# two shelves with curios
	for side in [0, 1]:
		var x0: float = 34.0 if side == 0 else w - 112.0
		for row in 2:
			var sy := 17.0 + row * 17.0
			UISkin.fill(ci, Rect2(x0, sy, 78, 3), 1, Color("#8A5A32"), Color("#4A2C16"))
			n.draw_line(Vector2(x0, sy + 3.5), Vector2(x0 + 78, sy + 3.5), Color(0, 0, 0, 0.45), 1.0)
			for j in 5:
				var cx := x0 + 7.0 + j * 15.5
				var kind: int = (j + row * 2 + side * 3) % 4
				_curio(n, Vector2(cx, sy), kind, j + row * 5 + side * 11)
	# lanterns
	for lx in [16.0, w - 16.0]:
		n.draw_line(Vector2(lx, 0), Vector2(lx, 9), Color("#1A100A"), 1.2)
		var fl := 0.8 + 0.2 * sin(_t * 9.0 + lx) * sin(_t * 5.3 + lx * 0.3)
		for k in 6:
			n.draw_circle(Vector2(lx, 17), 20.0 - k * 3.0, Color(1.0, 0.7, 0.3, 0.035 * fl))
		UISkin.fill(ci, Rect2(lx - 4, 10, 8, 12), 2, Color("#FFE08A"), Color("#FF9A3A"))
		UISkin.stroke(ci, Rect2(lx - 4, 10, 8, 12), 2, Color("#2A1A0E"), 1.2)
		n.draw_line(Vector2(lx, 10), Vector2(lx, 22), Color("#2A1A0E"), 0.8)
		UISkin.fill(ci, Rect2(lx - 5, 8, 10, 3), 1, Color("#6A4A2A"), Color("#2A1A0E"))
		UISkin.fill(ci, Rect2(lx - 5, 21, 10, 2.5), 1, Color("#6A4A2A"), Color("#2A1A0E"))
	# merchant sign in the middle
	var sw := 132.0
	var sr := Rect2((w - sw) / 2.0, 6, sw, 30)
	for cx in [sr.position.x + 10.0, sr.end.x - 10.0]:
		n.draw_line(Vector2(cx, 0), Vector2(cx, sr.position.y + 2), Color("#C9A46A"), 1.0)
	UISkin.fill(ci, sr.grow(2), 5, Color("#1A0E06"), Color("#1A0E06"))
	UISkin.fill(ci, sr, 4, Color("#7A1E24"), Color("#3A0A10"))
	UISkin.ornate(ci, sr.grow(-2))
	UISkin.diamond(ci, Vector2(sr.position.x + 9, sr.get_center().y), 2.6)
	UISkin.diamond(ci, Vector2(sr.end.x - 9, sr.get_center().y), 2.6)
	var f := UITheme.font_title
	var title := DataDB.t("shop_sign")
	var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	n.draw_string_outline(f, Vector2(w / 2.0 - tw / 2.0, sr.position.y + 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.9))
	n.draw_string(f, Vector2(w / 2.0 - tw / 2.0, sr.position.y + 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFD978"))
	var sub := DataDB.t("shop_motto")
	var fb := UITheme.font_body
	var sw2 := fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	n.draw_string(fb, Vector2(w / 2.0 - sw2 / 2.0, sr.position.y + 25), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#F3D7B0"))
	# drifting golden motes
	for m in _motes:
		var mv: Vector3 = m
		var px := fmod(mv.x + _t * 4.0, w)
		var py := fmod(mv.y - _t * 3.0 + h * 4.0, h)
		var a := 0.35 + 0.35 * sin(_t * 3.0 + mv.z)
		n.draw_circle(Vector2(px, py), 0.8, Color(1.0, 0.85, 0.45, a))
	n.draw_line(Vector2(0, h - 0.5), Vector2(w, h - 0.5), Color("#C9A46A", 0.7), 1.0)


## Little shelf goods: potions, scrolls, gems, tiny chests.
func _curio(n: Control, base: Vector2, kind: int, seed: int) -> void:
	var cols := [Color("#E8484A"), Color("#4AA8FF"), Color("#5EE07A"), Color("#C77DFF"), Color("#FFC94A")]
	var col: Color = cols[seed % cols.size()]
	match kind:
		0:
			n.draw_circle(base + Vector2(0, -4), 3.6, Color(0, 0, 0, 0.6))
			n.draw_circle(base + Vector2(0, -4), 3.0, col)
			n.draw_circle(base + Vector2(-1, -5), 1.0, Color(1, 1, 1, 0.7))
			n.draw_rect(Rect2(base + Vector2(-1, -9.5), Vector2(2, 3)), Color("#D8D0C0"))
			n.draw_circle(base + Vector2(0, -4), 5.0, Color(col, 0.12 + 0.06 * sin(_t * 2.0 + seed)))
		1:
			n.draw_rect(Rect2(base + Vector2(-4, -5), Vector2(8, 5)), Color("#E9D8B0"))
			n.draw_rect(Rect2(base + Vector2(-5, -5.5), Vector2(1.6, 6)), Color("#B8925A"))
			n.draw_rect(Rect2(base + Vector2(3.4, -5.5), Vector2(1.6, 6)), Color("#B8925A"))
			n.draw_rect(Rect2(base + Vector2(-0.6, -5), Vector2(1.2, 5)), Color("#A01E24"))
		2:
			var pts := PackedVector2Array([base + Vector2(0, -8), base + Vector2(3, -4), base + Vector2(0, 0), base + Vector2(-3, -4)])
			n.draw_colored_polygon(pts, col)
			n.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0, 0, 0, 0.6), 0.8)
			n.draw_circle(base + Vector2(0, -4), 6.0, Color(col, 0.1 + 0.08 * sin(_t * 3.0 + seed)))
		3:
			ChestArt.draw(n, base, 10.0, ["wood", "iron", "gold", "crystal", "royal"][seed % 5], 0.0, _t, false)


# ------------------------------------------------------------------ tabs
func _build_tabs() -> void:
	for ch in _tabs.get_children():
		ch.queue_free()
	var tabs := Shop.tabs()
	var gap := 4.0
	var bw := (_tabs.size.x - gap * (tabs.size() - 1)) / tabs.size()
	for i in tabs.size():
		var key := str(tabs[i])
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.position = Vector2(i * (bw + gap), 0)
		b.size = Vector2(bw, TABS_H)
		b.pressed.connect(func():
			_tab = key
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh())
		var label := DataDB.t("shop_tab_" + key)
		var on := _tab == key
		var vel: Array = VELVET.get(key, VELVET["chests"])
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var hov := b.is_hovered()
			var r := Rect2(Vector2(1, 0 if on else 1), b.size - Vector2(2, 1))
			if on:
				UISkin.stroke(ci, r.grow(1.0), 4, Color(1.0, 0.85, 0.4, 0.5), 2.0)
			UISkin.fill(ci, r, 3, (vel[0] as Color).lightened(0.15 if on or hov else 0.0) if on else Color("#5A3820").lightened(0.1 if hov else 0.0),
				(vel[1] as Color) if on else Color("#2A180C"))
			UISkin.stroke(ci, r, 3, Color("#140A04"), 1.0)
			UISkin.stroke(ci, r.grow(-1.0), 2, Color("#E8C27A", 0.85) if on else Color("#B08A5A", 0.4), 0.8)
			var f := UITheme.font_title
			var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var x0 := (r.size.x - tw - 12.0) / 2.0 + r.position.x
			if key == "gold":
				_coin(b, Vector2(x0 + 4.5, r.get_center().y), 4.0)
			else:
				b.draw_texture_rect(UITheme.icon(TAB_ICON[key]), Rect2(x0, r.get_center().y - 4.5, 9, 9), false,
					Color.WHITE if on else Color(0.85, 0.8, 0.75))
			var tp := Vector2(x0 + 12.0, r.get_center().y + 3.0)
			b.draw_string_outline(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, 0.85))
			b.draw_string(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFE7B0") if on else Color("#D8C4A0")))
		_tabs.add_child(b)


func _refresh_state() -> void:
	for cd in _cards:
		if not is_instance_valid(cd):
			continue
		for ch in cd.get_children():
			if ch is Button and ch.has_meta("pid"):
				var p := Shop.product(str(ch.get_meta("pid")))
				ch.disabled = Shop.block_reason(p, str(ch.get_meta("hid"))) != ""
				ch.queue_redraw()


# ------------------------------------------------------------------ cards
func _title(p: Dictionary, hid: String) -> String:
	if hid != "":
		return str(DataDB.hero_def(hid).get("name", hid))
	return DataDB.t("shop_" + str(p["id"]))


func _subtitle(p: Dictionary, hid: String) -> String:
	match str(p.get("kind", "")):
		"chest":
			return "%d× %s" % [int(p.get("count", 1)), Chests.display_name(str(p["chest"]))]
		"gold":
			return "+" + F.fmt_num(Shop.gold_amount(p) * (2 if Shop.first_double(p) else 1)) + " " + DataDB.t("gold")
		"daily":
			return DataDB.t("shop_daily_desc", {"chest": Chests.display_name(Shop.daily_chest())})
		"supporter":
			return DataDB.t("shop_supporter_desc")
		"hero_random":
			return DataDB.t("shop_random_odds", {"ssr": int(p["weights"].get("SSR", 0)), "sr": int(p["weights"].get("SR", 0))})
		"hero_pick":
			var d := DataDB.hero_def(hid)
			return "%s · %s" % [str(d.get("rarity", "")), DataDB.tx(DataDB.class_def(str(d["class"])).get("name", {}))]
		"bundle":
			return DataDB.t("shop_starter_desc", {"g": F.fmt_num(int(p.get("gold", Shop.gold_amount(p))))})
		"offline":
			return DataDB.t("shop_offline_desc", {"e": int(round(float(p.get("eff", 0)) * 100.0)), "h": int(p.get("hours", 0))})
		"bag":
			var left := int(p.get("max_buys", 1)) - Shop.times_bought(str(p["id"]))
			return DataDB.t("shop_bag_desc", {"n": int(p.get("slots", 20)), "left": left})
		"mats":
			return "+%d %s" % [int(p["mats"].get("tavern_seal", 0)), DataDB.t("seal_name")]
	return ""


## Arched niche outline (flat bottom, elliptical top).
func _arch(r: Rect2, rise: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(r.position.x, r.end.y))
	pts.append(Vector2(r.position.x, r.position.y + rise))
	var cx := r.get_center().x
	var rx := r.size.x / 2.0
	for k in range(1, 16):
		var a := PI + PI * k / 16.0
		pts.append(Vector2(cx + cos(a) * rx, r.position.y + rise + sin(a) * rise))
	pts.append(Vector2(r.end.x, r.position.y + rise))
	pts.append(Vector2(r.end.x, r.end.y))
	return pts


func _card(p: Dictionary, hid: String, pos: Vector2) -> void:
	var kind := str(p.get("kind", ""))
	var vel: Array = VELVET.get(_tab, VELVET["chests"])
	var glow: Color = RARITY_COL.get(Tavern.rarity(hid), vel[2]) if hid != "" else vel[2]
	var tex := SpriteLib.portrait(hid) if hid != "" else null
	var title := _title(p, hid)
	var sub := _subtitle(p, hid)
	var c := Control.new()
	c.position = pos
	c.size = CARD
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip_key := "shop_%s_tip" % str(p["id"])
	c.tooltip_text = title + "\n" + (DataDB.t(tip_key) if DataDB.strings.has(tip_key) else sub)
	var seed := randf() * 10.0
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var outer := Rect2(Vector2(1, 1), c.size - Vector2(2, 2))
		var inner := outer.grow(-4.0)
		# bronze frame, then the velvet niche
		var po := _arch(outer, 18.0)
		UISkin.poly(ci, po, Color("#E2B866"), Color("#6A4320"))
		var pin := _arch(inner, 15.0)
		var top_c: Color = vel[0]
		var bot_c: Color = vel[1]
		if hid != "":
			top_c = top_c.lerp(glow.darkened(0.45), 0.35)
		UISkin.poly(ci, pin, top_c, bot_c)
		# velvet folds
		for k in 5:
			var fx := inner.position.x + 8.0 + k * (inner.size.x - 16.0) / 4.0
			c.draw_line(Vector2(fx, inner.position.y + 14), Vector2(fx, inner.end.y), Color(0, 0, 0, 0.12), 3.0)
		# spotlight from the top of the arch
		var ctr := Vector2(c.size.x / 2.0, 44)
		var sp := PackedVector2Array([Vector2(ctr.x - 8, inner.position.y + 2), Vector2(ctr.x + 8, inner.position.y + 2),
			Vector2(ctr.x + 40, 70), Vector2(ctr.x - 40, 70)])
		c.draw_colored_polygon(sp, Color(glow, 0.07 + 0.02 * sin(_t * 2.0 + seed)))
		for k in 5:
			c.draw_circle(ctr, 34.0 - k * 6.0, Color(glow, 0.035))
		# stone pedestal
		if kind != "hero_pick":
			c.draw_set_transform(Vector2(ctr.x, 70), 0.0, Vector2(1.0, 0.28))
			c.draw_circle(Vector2(0, 6), 30.0, Color(0, 0, 0, 0.45))
			c.draw_circle(Vector2.ZERO, 30.0, Color("#5A5560"))
			c.draw_circle(Vector2(0, -2), 27.0, Color("#8A8590"))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_art(c, kind, p, tex, ctr)
		# twinkles
		for k in 3:
			var ph := fmod(_t * 0.7 + seed + k * 0.33, 1.0)
			var tp := Vector2(inner.position.x + fmod(seed * 37.0 + k * 29.0, inner.size.x), inner.position.y + 18 + fmod(seed * 13.0 + k * 21.0, 46.0))
			var a := sin(ph * PI)
			c.draw_line(tp - Vector2(2.5 * a, 0), tp + Vector2(2.5 * a, 0), Color(1, 1, 0.9, a * 0.8), 0.8)
			c.draw_line(tp - Vector2(0, 2.5 * a), tp + Vector2(0, 2.5 * a), Color(1, 1, 0.9, a * 0.8), 0.8)
		c.draw_polyline(_close(po), Color("#2A1606"), 1.2, true)
		c.draw_polyline(_close(pin), Color("#FFE3A0", 0.55), 0.8, true)
		# ribbon banner with the name
		_ribbon(c, Rect2(4, 76, c.size.x - 8, 13), title, glow)
		var fb := UITheme.font_body
		var sw := minf(fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, c.size.x - 8)
		c.draw_string_outline(fb, Vector2((c.size.x - sw) / 2.0, 97), sub, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 8, 7, 2, Color(0, 0, 0, 0.8))
		c.draw_string(fb, Vector2((c.size.x - sw) / 2.0, 97), sub, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 8, 7, Color("#EADFC8"))
		if hid != "":
			var rar := Tavern.rarity(hid)
			var tag := Rect2(8, 16, 21 if rar == "SSR" else 16, 9)
			UISkin.fill(ci, tag, 2, glow.lightened(0.15), glow.darkened(0.35))
			UISkin.stroke(ci, tag, 2, Color(0, 0, 0, 0.9), 1.0)
			c.draw_string(fb, tag.position + Vector2(2.5, 7.5), rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208"))
		var badge := str(p.get("badge", ""))
		if Shop.first_double(p):
			badge = "double"
		if badge != "":
			_sash(c, DataDB.t("shop_badge_" + badge), BADGE_COL.get(badge, Color.WHITE)))
	_grid.add_child(c)
	_cards.append(c)
	_price_plaque(c, p, hid)


func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _ribbon(c: Control, r: Rect2, text: String, glow: Color) -> void:
	var ci := c.get_canvas_item()
	var tail := 6.0
	for side in [-1, 1]:
		var x0: float = r.position.x if side < 0 else r.end.x
		var pts := PackedVector2Array([Vector2(x0, r.position.y + 3), Vector2(x0 - side * tail, r.position.y + 3),
			Vector2(x0 - side * (tail - 3), r.get_center().y + 1.5), Vector2(x0 - side * tail, r.end.y + 3), Vector2(x0, r.end.y + 3)])
		c.draw_colored_polygon(pts, Color("#5A0E14"))
	var body := Rect2(r.position + Vector2(2, 0), r.size - Vector2(4, 0))
	UISkin.fill(ci, body, 1, Color("#B0262E"), Color("#5E0D14"))
	c.draw_line(body.position + Vector2(1, 1.5), Vector2(body.end.x - 1, body.position.y + 1.5), Color(1, 0.8, 0.6, 0.35), 0.8)
	UISkin.stroke(ci, body, 1, Color("#240406"), 1.0)
	var f := UITheme.font_title
	var fs := 9
	while fs > 6 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > body.size.x - 6:
		fs -= 1
	var tw := minf(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, body.size.x - 6)
	var tp := Vector2(body.get_center().x - tw / 2.0, body.get_center().y + fs * 0.36)
	c.draw_string_outline(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, body.size.x - 6, fs, 3, Color(0.15, 0.0, 0.02, 0.95))
	c.draw_string(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, body.size.x - 6, fs, Color("#FFE7A8"))


## Corner sash across the top right of a niche ("Popular", "Best value", "One time").
func _sash(c: Control, text: String, col: Color) -> void:
	var fb := UITheme.font_body
	var tw := fb.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var len := maxf(tw + 22.0, 60.0)
	c.draw_set_transform(Vector2(c.size.x - 15, 15), PI / 4.0, Vector2.ONE)
	var r := Rect2(-len / 2.0, -5, len, 10)
	c.draw_rect(r.grow(0.8), Color(0, 0, 0, 0.75))
	UISkin.fill(c.get_canvas_item(), r, 0, col.lightened(0.25), col.darkened(0.25))
	c.draw_line(Vector2(r.position.x, r.position.y + 1.2), Vector2(r.end.x, r.position.y + 1.2), Color(1, 1, 1, 0.35), 0.6)
	c.draw_string(fb, Vector2(-tw / 2.0, 2.4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#FFFFFF"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Gold price plaque with a wax seal; shows the reason instead when the product can't be bought.
func _price_plaque(c: Control, p: Dictionary, hid: String) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size = Vector2(CARD.x - 14, 15)
	b.position = Vector2(7, CARD.y - 18)
	b.set_meta("pid", str(p["id"]))
	b.set_meta("hid", hid)
	b.disabled = Shop.block_reason(p, hid) != ""
	b.pressed.connect(func(): _ask(p, hid))
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var r := Rect2(Vector2.ZERO, b.size)
		var why := Shop.block_reason(p, hid)
		var off := why != ""
		var hov := b.is_hovered() and not off
		var down := b.button_pressed
		if hov:
			UISkin.stroke(ci, r.grow(1.5), 5, Color(1.0, 0.9, 0.5, 0.5), 2.0)
		var top := Color("#FFE58A") if hov else Color("#F2C55A")
		var bot := Color("#A8661E")
		if off:
			top = Color("#6A6470")
			bot = Color("#2E2A32")
		UISkin.fill(ci, r.grow(-0.5).grow_individual(0, -1 if down else 0, 0, 0), 4, top, bot)
		UISkin.stroke(ci, r, 4, Color("#2A1606"), 1.0)
		b.draw_line(Vector2(5, 2), Vector2(r.size.x - 5, 2), Color(1, 1, 0.9, 0.45 if not off else 0.15), 0.8)
		# wax seal
		var sc := Vector2(9, r.size.y / 2.0)
		b.draw_circle(sc, 6.2, Color("#3A0508"))
		b.draw_circle(sc, 5.4, Color("#B3141E") if not off else Color("#55505A"))
		b.draw_circle(sc + Vector2(-1, -1), 2.2, Color(1, 0.6, 0.5, 0.35))
		UISkin.diamond(ci, sc, 2.2, Color("#FFD27A"), Color("#B07020"))
		var txt := why if off else Shop.price_text(p)
		var f := UITheme.font_title
		var fs := 9 if not off else 7
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := Vector2(9 + (r.size.x - 9 - tw) / 2.0, r.size.y / 2.0 + fs * 0.36)
		b.draw_string(f, tp + Vector2(0, 0.8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.3))
		b.draw_string(f, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#3A1C06") if not off else Color("#D8D0DC")))
	c.add_child(b)


func _draw_art(c: Control, kind: String, p: Dictionary, tex: Texture2D, ctr: Vector2) -> void:
	match kind:
		"chest":
			var n := mini(int(p.get("count", 1)), 3)
			for i in n:
				var off := (i - (n - 1) / 2.0) * 18.0
				ChestArt.draw(c, ctr + Vector2(off, 22 - absf(off) * 0.15), 34.0 if n == 1 else 26.0, str(p["chest"]), 0.0, _t + i, i == 0)
		"bundle":
			for k in 2:
				_mystery_card(c, ctr + Vector2(-20 + k * 40, -6), 0.42, k * 1.7)
			ChestArt.draw(c, ctr + Vector2(-6, 30), 30.0, "crystal", 0.0, _t, true)
			for i in 4:
				_coin(c, ctr + Vector2(16 + (i % 2) * 9.0, 28 - (i / 2) * 6.0), 5.5)
		"offline":
			_hourglass(c, ctr + Vector2(0, 6), 1.0)
		"daily":
			ChestArt.draw(c, ctr + Vector2(0, 26), 36.0, Shop.daily_chest(), 0.0, _t, Shop.daily_ready())
			if Shop.daily_ready():
				var f := UITheme.font_title
				var bob := sin(_t * 3.0) * 2.0
				c.draw_string_outline(f, ctr + Vector2(-4, -20 + bob), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.9))
				c.draw_string(f, ctr + Vector2(-4, -20 + bob), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#FFE27A"))
		"supporter":
			_crest(c, ctr + Vector2(0, 4))
		"gold":
			var piles := {"gold_s": [3], "gold_m": [4, 3, 2], "gold_l": [5, 4, 3, 2, 1]}.get(str(p["id"]), [3, 2]) as Array
			var base := ctr + Vector2(0, 24)
			for row in piles.size():
				var n := int(piles[row])
				for i in n:
					var at := base + Vector2((i - (n - 1) / 2.0) * 11.0, -row * 7.0)
					_coin(c, at, 6.5)
			var tw := 0.5 + 0.5 * sin(_t * 4.0)
			c.draw_texture_rect(UITheme.icon("sparkle"), Rect2(base + Vector2(10, -piles.size() * 7.0 - 12), Vector2(9, 9)), false, Color(1, 1, 1, tw))
		"hero_random":
			_mystery_card(c, ctr, 1.0, 0.0)
		"hero_pick":
			if tex:
				var art_h := 76.0
				var aw := tex.get_width() * art_h / float(tex.get_height())
				c.draw_texture_rect(tex, Rect2(Vector2(ctr.x - aw / 2.0, 2), Vector2(aw, art_h)), false)
		"bag":
			c.draw_texture_rect(UITheme.icon("bag"), Rect2(ctr - Vector2(18, 16), Vector2(36, 36)), false, Color("#C98B52"))
			_plus(c, ctr + Vector2(18, -14))
		"mats":
			c.draw_texture_rect(UITheme.icon("crown"), Rect2(ctr - Vector2(18, 16), Vector2(36, 36)), false, Color("#FFC94A"))
			_plus(c, ctr + Vector2(18, -14))


## A shiny gold coin seen slightly from above.
func _coin(c: Control, at: Vector2, r: float) -> void:
	c.draw_set_transform(at, 0.0, Vector2(1.0, 0.62))
	c.draw_circle(Vector2(0, 2.2), r, Color("#6B3E0C"))
	c.draw_circle(Vector2.ZERO, r, Color("#3A2208"))
	c.draw_circle(Vector2.ZERO, r - 0.8, Color("#E8A92E"))
	c.draw_circle(Vector2(-0.4, -0.4), r - 2.0, Color("#FFD866"))
	c.draw_arc(Vector2.ZERO, r - 2.6, PI * 1.05, PI * 1.6, 8, Color(1, 1, 0.9, 0.9), 1.0, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _plus(c: Control, at: Vector2) -> void:
	c.draw_circle(at, 6.0, Color(0, 0, 0, 0.8))
	c.draw_circle(at, 5.0, Color("#5EE07A"))
	c.draw_rect(Rect2(at - Vector2(3, 0.8), Vector2(6, 1.6)), Color("#0E2A12"))
	c.draw_rect(Rect2(at - Vector2(0.8, 3), Vector2(1.6, 6)), Color("#0E2A12"))


# ------------------------------------------------------------------ buying
func _ask(p: Dictionary, hid: String) -> void:
	var title := _title(p, hid)
	if not Shop.is_real_money(p):
		_buy(p, hid)
		return
	var txt := DataDB.t("shop_confirm", {"name": title, "price": Shop.price_text(p)})
	if SteamService.payment_mode() == "direct":
		txt += "\n" + DataDB.t("shop_test_note")
	W.confirm(_host, txt, func(): _buy(p, hid), DataDB.t("shop_buy"))


func _buy(p: Dictionary, hid: String) -> void:
	Shop.buy(str(p["id"]), func(res: Dictionary):
		if res.is_empty():
			EventBus.notify.emit(DataDB.t("shop_failed"), UITheme.C_RED)
			AudioManager.play("ui_click", 0.05, 0.4)
			return
		AudioManager.play("coin", 0.05, 0.9)
		_reveal(res)
		refresh(), hid)


## Reward reveal over the store: what was bought, with its art.
func _reveal(res: Dictionary) -> void:
	var veil := Control.new()
	veil.size = _host.size
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 50
	_host.add_child(veil)
	var born := _t
	var hid := str(res.get("hero", ""))
	var tex := SpriteLib.portrait(hid) if hid != "" else null
	var rcol: Color = RARITY_COL.get(Tavern.rarity(hid), Color("#FFD36A")) if hid != "" else Color("#FFD36A")
	var line := ""
	match str(res.get("kind", "")):
		"chest":
			line = "%d× %s" % [int(res["count"]), Chests.display_name(str(res["chest"]))]
		"gold":
			line = "+" + F.fmt_num(int(res.get("gold", 0))) + " " + DataDB.t("gold")
		"bundle":
			var names: Array = []
			for h in res.get("heroes", []):
				names.append(str(DataDB.hero_def(str(h)).get("name", h)))
			line = DataDB.t("shop_new_hero", {"name": " & ".join(names)}) if names.size() > 0 else DataDB.t("shop_thanks")
			AudioManager.play("recruit")
		"hero_random", "hero_pick":
			line = DataDB.t("shop_new_hero", {"name": str(DataDB.hero_def(hid).get("name", hid))})
			AudioManager.play("recruit")
		_:
			line = DataDB.t("shop_thanks")
	veil.draw.connect(func():
		var e := clampf((_t - born) / 0.45, 0.0, 1.0)
		veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.02, 0.01, 0.03, 0.78 * e))
		var ctr := veil.size / 2.0 - Vector2(0, 12)
		for k in 12:
			var a := (_t - born) * 0.6 + k * TAU / 12.0
			veil.draw_colored_polygon(PackedVector2Array([ctr, ctr + Vector2.from_angle(a - 0.09) * 150.0 * e,
				ctr + Vector2.from_angle(a + 0.09) * 150.0 * e]), Color(rcol, 0.1 * e))
		var s := 0.6 + 0.4 * (1.0 - pow(1.0 - e, 3.0))
		if tex:
			var h := 120.0 * s
			var w := tex.get_width() * h / float(tex.get_height())
			veil.draw_texture_rect(tex, Rect2(ctr - Vector2(w / 2.0, h * 0.55), Vector2(w, h)), false, Color(1, 1, 1, e))
		elif str(res.get("kind", "")) == "chest":
			ChestArt.draw(veil, ctr + Vector2(0, 30), 70.0 * s, str(res["chest"]), 0.0, _t, true)
		else:
			if res.has("gold"):
				for row in 4:
					for i in 5 - row:
						_coin(veil, ctr + Vector2((i - (4 - row) / 2.0) * 16.0 * s, 24 - row * 10.0 * s), 9.5 * s)
			else:
				var ic := UITheme.icon("bag" if str(res.get("kind")) == "bag" else "crown")
				veil.draw_texture_rect(ic, Rect2(ctr - Vector2(28, 28) * s, Vector2(56, 56) * s), false, Color(Color("#FFC94A"), e))
		var f := UITheme.font_title
		var w2 := f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var y := ctr.y + 74
		veil.draw_string_outline(f, Vector2(ctr.x - w2 / 2.0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, e))
		veil.draw_string(f, Vector2(ctr.x - w2 / 2.0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(rcol.lightened(0.3), e)))
	var tick := Timer.new()
	tick.wait_time = 1.0 / 30.0
	tick.autostart = true
	tick.timeout.connect(veil.queue_redraw)
	veil.add_child(tick)
	var ok := UITheme.button(DataDB.t("btn_ok"), "gold", func(): veil.queue_free(), Vector2(70, 14))
	veil.add_child(ok)
	ok.size = Vector2(70, 14)
	ok.position = Vector2((veil.size.x - 70) / 2.0, veil.size.y - 26)


## Face-down mystery hero card with a shifting rainbow glow.
func _mystery_card(c: Control, ctr: Vector2, k: float, phase: float) -> void:
	var ci := c.get_canvas_item()
	var r := Rect2(ctr - Vector2(20, 30) * k, Vector2(40, 58) * k)
	var glow := Color.from_hsv(fmod(_t * 0.15 + phase, 1.0), 0.55, 1.0)
	for i in 4:
		UISkin.stroke(ci, r.grow((2.0 + i * 2.0) * k), 5, Color(glow, 0.14 - i * 0.03), 2.0)
	UISkin.fill(ci, r, 4, Color("#4A2C6E"), Color("#1A1030"))
	UISkin.stroke(ci, r, 4, Color("#FFD36A"), 1.2)
	if k > 0.6:
		UISkin.ornate(ci, r.grow(-3.0))
	var f := UITheme.font_title
	var s := int(30 * k)
	var w := f.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var bob := sin(_t * 2.0 + phase) * 1.5
	c.draw_string_outline(f, Vector2(ctr.x - w / 2.0, ctr.y + 10 * k + bob), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, s, 4, Color(0, 0, 0, 0.9))
	c.draw_string(f, Vector2(ctr.x - w / 2.0, ctr.y + 10 * k + bob), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color("#FFE7A0"))


## Guild crest: a shield with a crown, for the supporter pack.
func _crest(c: Control, ctr: Vector2) -> void:
	var ci := c.get_canvas_item()
	for k in 5:
		c.draw_circle(ctr, 30.0 - k * 5.0, Color(0.8, 0.5, 1.0, 0.05 + 0.02 * sin(_t * 2.0)))
	var pts := PackedVector2Array([ctr + Vector2(-18, -16), ctr + Vector2(18, -16), ctr + Vector2(18, 2), ctr + Vector2(0, 22), ctr + Vector2(-18, 2)])
	UISkin.poly(ci, pts, Color("#7A3FB0"), Color("#2A0E44"))
	c.draw_polyline(_close(pts), Color("#FFD36A"), 1.6, true)
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(ctr + (q - ctr) * 0.78)
	c.draw_polyline(_close(inner), Color("#FFD36A", 0.5), 0.8, true)
	c.draw_texture_rect(UITheme.icon("crown"), Rect2(ctr - Vector2(9, 12), Vector2(18, 18)), false, Color("#FFC94A"))


## Brass hourglass with sand running.
func _hourglass(c: Control, ctr: Vector2, k: float) -> void:
	var ci := c.get_canvas_item()
	var hw := 13.0 * k
	var hh := 22.0 * k
	var flow := fmod(_t * 0.15, 1.0)
	var top_glass := PackedVector2Array([ctr + Vector2(-hw, -hh), ctr + Vector2(hw, -hh), ctr + Vector2(1.5, -1), ctr + Vector2(-1.5, -1)])
	var bot_glass := PackedVector2Array([ctr + Vector2(-1.5, 1), ctr + Vector2(1.5, 1), ctr + Vector2(hw, hh), ctr + Vector2(-hw, hh)])
	for k2 in 4:
		c.draw_circle(ctr, 26.0 - k2 * 5.0, Color(0.6, 0.85, 1.0, 0.05))
	c.draw_colored_polygon(top_glass, Color(0.75, 0.9, 1.0, 0.22))
	c.draw_colored_polygon(bot_glass, Color(0.75, 0.9, 1.0, 0.22))
	var st := 1.0 - flow
	var sy := -1.0 - (hh - 2.0) * st * 0.8
	var sw := hw * (absf(sy) / hh)
	c.draw_colored_polygon(PackedVector2Array([ctr + Vector2(-sw, sy), ctr + Vector2(sw, sy), ctr + Vector2(1.2, -1.5), ctr + Vector2(-1.2, -1.5)]), Color("#F2C55A"))
	var by := hh - (hh - 3.0) * flow * 0.8
	var bw := hw * (by / hh)
	c.draw_colored_polygon(PackedVector2Array([ctr + Vector2(-hw + 1, hh - 0.5), ctr + Vector2(hw - 1, hh - 0.5), ctr + Vector2(bw * 0.4, by), ctr + Vector2(-bw * 0.4, by)]), Color("#E8B040"))
	c.draw_line(ctr + Vector2(0, -1), ctr + Vector2(0, hh - 1), Color("#F2C55A", 0.8), 0.8)
	c.draw_polyline(_close(top_glass), Color(1, 1, 1, 0.6), 0.8, true)
	c.draw_polyline(_close(bot_glass), Color(1, 1, 1, 0.6), 0.8, true)
	for yy in [-hh - 3.0, hh]:
		UISkin.fill(ci, Rect2(ctr.x - hw - 4, ctr.y + yy, hw * 2 + 8, 3.5), 1, Color("#F2C55A"), Color("#8A5A1E"))
	for xx in [-hw - 2.5, hw + 1.0]:
		c.draw_rect(Rect2(ctr.x + xx, ctr.y - hh - 1, 1.6, hh * 2 + 1), Color("#B0782A"))
