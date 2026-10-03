extends PanelWindow
## Town store: tabs of product cards (chests, gold, heroes, packs). Gold-priced cards buy at once;
## real-money cards ask for confirmation, go through SteamService and end with a reward reveal.

const COLS := 3
const CARD := Vector2(102, 116)
const BADGE_COL := {"popular": Color("#4FB8FF"), "best": Color("#FF8A3D"), "once": Color("#5EE07A")}
const RARITY_COL := {"R": Color("#A9B1C2"), "SR": Color("#5E9BFF"), "SSR": Color("#FFC24A")}

var _tab := "chests"
var _top: Control
var _grid: Control
var _scroll: ScrollContainer
var _host: Control
var _t := 0.0
var _cards: Array = []
var _gold_lbl: Label


func build(c: Control) -> void:
	_host = c
	_top = Control.new()
	_top.size = Vector2(c.size.x, 30)
	c.add_child(_top)
	_scroll = W.scroll(Vector2(c.size.x, c.size.y - 32))
	_scroll.position = Vector2(0, 32)
	c.add_child(_scroll)
	_grid = Control.new()
	_scroll.add_child(_grid)
	EventBus.gold_changed.connect(func(_g): _refresh_state())
	EventBus.chests_changed.connect(_refresh_state)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	refresh()


func _process(delta: float) -> void:
	_t += delta
	for cd in _cards:
		if is_instance_valid(cd):
			cd.queue_redraw()


func refresh() -> void:
	if _grid == null:
		return
	_build_top()
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
		_card(entries[i][0], str(entries[i][1]), Vector2((i % COLS) * (CARD.x + gap), (i / COLS) * (CARD.y + 5.0)))
	_grid.custom_minimum_size = Vector2(_host.size.x - 6, ceil(entries.size() / float(COLS)) * (CARD.y + 5.0))


func _build_top() -> void:
	for ch in _top.get_children():
		ch.queue_free()
	var x := 0.0
	for tb in Shop.tabs():
		var key: String = tb
		var bw := 56.0
		var b := UITheme.button(DataDB.t("shop_tab_" + key), "gold" if _tab == key else "brown", func():
			_tab = key
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh(), Vector2(bw, 13))
		_top.add_child(b)
		b.position = Vector2(x, 0)
		b.size = Vector2(bw, 13)
		x += bw + 2
	var coin := W.icon_rect(UITheme.icon("gold"), Vector2(9, 9))
	coin.position = Vector2(_top.size.x - 62, 2)
	_top.add_child(coin)
	_gold_lbl = UITheme.label(F.fmt_num(GameState.gold), UITheme.C_GOLD, 8, UITheme.font_body)
	_gold_lbl.position = Vector2(_top.size.x - 51, 1)
	_top.add_child(_gold_lbl)
	var hint := UITheme.label(DataDB.t("shop_test_mode") if SteamService.payment_mode() == "direct" else DataDB.t("shop_hint"),
		UITheme.C_ORANGE if SteamService.payment_mode() == "direct" else UITheme.C_DIM, 7, UITheme.font_body)
	hint.position = Vector2(0, 16)
	hint.size = Vector2(_top.size.x, 10)
	hint.clip_text = true
	_top.add_child(hint)


func _refresh_state() -> void:
	if _gold_lbl:
		_gold_lbl.text = F.fmt_num(GameState.gold)
	for cd in _cards:
		if not is_instance_valid(cd):
			continue
		for ch in cd.get_children():
			if ch is Button and ch.has_meta("pid"):
				var p := Shop.product(str(ch.get_meta("pid")))
				ch.disabled = Shop.block_reason(p, str(ch.get_meta("hid"))) != ""
				ch.text = _price_label(p, str(ch.get_meta("hid")))


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
			return "+" + F.fmt_num(Shop.gold_amount(p)) + " " + DataDB.t("gold")
		"hero_random":
			return DataDB.t("shop_random_odds", {"ssr": int(p["weights"].get("SSR", 0)), "sr": int(p["weights"].get("SR", 0))})
		"hero_pick":
			var d := DataDB.hero_def(hid)
			return "%s · %s" % [str(d.get("rarity", "")), DataDB.tx(DataDB.class_def(str(d["class"])).get("name", {}))]
		"bundle":
			return DataDB.t("shop_starter_desc", {"g": F.fmt_num(Shop.gold_amount(p))})
		"bag":
			var left := int(p.get("max_buys", 1)) - Shop.times_bought(str(p["id"]))
			return DataDB.t("shop_bag_desc", {"n": int(p.get("slots", 20)), "left": left})
		"mats":
			return "+%d %s" % [int(p["mats"].get("tavern_seal", 0)), DataDB.t("seal_name")]
	return ""


func _price_label(p: Dictionary, hid: String) -> String:
	var why := Shop.block_reason(p, hid)
	if why != "" and why != DataDB.t("not_enough_gold"):
		return why
	return Shop.price_text(p)


func _card(p: Dictionary, hid: String, pos: Vector2) -> void:
	var real := Shop.is_real_money(p)
	var kind := str(p.get("kind", ""))
	var accent: Color = RARITY_COL.get(Tavern.rarity(hid), Color.WHITE) if hid != "" else (Color("#E9B54A") if real else Color("#9C7A55"))
	var tex := SpriteLib.portrait(hid) if hid != "" else null
	var c := Control.new()
	c.position = pos
	c.size = CARD
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.tooltip_text = _title(p, hid) + "\n" + _subtitle(p, hid)
	var title := _title(p, hid)
	var sub := _subtitle(p, hid)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.fill(ci, r, 4, Color("#2C2232").lerp(accent, 0.12), Color("#0F0C12"))
		# light rays behind the art
		var ctr := Vector2(r.size.x / 2.0, 42)
		for k in 6:
			c.draw_circle(ctr, 40.0 - k * 6.0, Color(accent, 0.035))
		if real:
			for k in 8:
				var a := _t * 0.4 + k * TAU / 8.0
				c.draw_colored_polygon(PackedVector2Array([ctr, ctr + Vector2.from_angle(a - 0.12) * 60.0, ctr + Vector2.from_angle(a + 0.12) * 60.0]), Color(accent, 0.05))
		_draw_art(c, kind, p, tex, ctr)
		UISkin.fill(ci, Rect2(0, r.size.y - 50, r.size.x, 50), 0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.85))
		UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 3, Color(accent, 0.75 + 0.25 * sin(_t * 2.5) if real else 0.6), 1.2)
		var f := UITheme.font_title
		var fs := 9
		while fs > 6 and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 6:
			fs -= 1
		var tw := minf(f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, r.size.x - 6)
		c.draw_string_outline(f, Vector2((r.size.x - tw) / 2.0, r.size.y - 31), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, fs, 3, Color(0, 0, 0, 0.95))
		c.draw_string(f, Vector2((r.size.x - tw) / 2.0, r.size.y - 31), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, fs, Color("#FFE7B0"))
		var fb := UITheme.font_body
		var sw := minf(fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, r.size.x - 6)
		c.draw_string(fb, Vector2((r.size.x - sw) / 2.0, r.size.y - 21), sub, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 7, Color("#CFC6B4"))
		var badge := str(p.get("badge", ""))
		if badge != "":
			var bt := DataDB.t("shop_badge_" + badge)
			var bw := fb.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 8
			var br := Rect2(r.size.x - bw - 3, 3, bw, 10)
			var bc: Color = BADGE_COL.get(badge, Color.WHITE)
			UISkin.fill(ci, br, 2, bc.lightened(0.2), bc.darkened(0.3))
			UISkin.stroke(ci, br, 2, Color(0, 0, 0, 0.9), 1.0)
			c.draw_string(fb, br.position + Vector2(4, 7.5), bt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208"))
		if hid != "":
			var rar := Tavern.rarity(hid)
			var tag := Rect2(3, 3, 21 if rar == "SSR" else 16, 9)
			UISkin.fill(ci, tag, 2, accent.lightened(0.15), accent.darkened(0.35))
			UISkin.stroke(ci, tag, 2, Color(0, 0, 0, 0.9), 1.0)
			c.draw_string(fb, tag.position + Vector2(2.5, 7.5), rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208")))
	_grid.add_child(c)
	_cards.append(c)
	var b := UITheme.button(_price_label(p, hid), "gold" if real else "orange", func(): _ask(p, hid), Vector2(CARD.x - 10, 14))
	c.add_child(b)
	b.size = Vector2(CARD.x - 10, 14)
	b.position = Vector2(5, CARD.y - 17)
	b.set_meta("pid", str(p["id"]))
	b.set_meta("hid", hid)
	b.disabled = Shop.block_reason(p, hid) != ""
	if not real:
		var coin := W.icon_rect(UITheme.icon("gold"), Vector2(8, 8))
		coin.position = Vector2(8, 3)
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(coin)


func _draw_art(c: Control, kind: String, p: Dictionary, tex: Texture2D, ctr: Vector2) -> void:
	match kind:
		"chest":
			var n := mini(int(p.get("count", 1)), 3)
			for i in n:
				var off := (i - (n - 1) / 2.0) * 18.0
				ChestArt.draw(c, ctr + Vector2(off, 22 - absf(off) * 0.15), 34.0 if n == 1 else 26.0, str(p["chest"]), 0.0, _t + i, i == 0)
		"gold", "bundle":
			if kind == "bundle":
				ChestArt.draw(c, ctr + Vector2(-16, 22), 32.0, "gold", 0.0, _t, true)
			var piles := {"gold_s": [3], "gold_m": [4, 3, 2], "gold_l": [5, 4, 3, 2, 1]}.get(str(p["id"]), [3, 2]) as Array
			var base := ctr + Vector2(16 if kind == "bundle" else 0, 24)
			for row in piles.size():
				var n := int(piles[row])
				for i in n:
					var at := base + Vector2((i - (n - 1) / 2.0) * 11.0, -row * 7.0)
					_coin(c, at, 6.5)
			var tw := 0.5 + 0.5 * sin(_t * 4.0)
			c.draw_texture_rect(UITheme.icon("sparkle"), Rect2(base + Vector2(10, -piles.size() * 7.0 - 12), Vector2(9, 9)), false, Color(1, 1, 1, tw))
		"hero_random":
			# a glowing card back with a question mark
			var r := Rect2(ctr - Vector2(20, 30), Vector2(40, 58))
			var ci := c.get_canvas_item()
			var hue := fmod(_t * 0.15, 1.0)
			var glow := Color.from_hsv(hue, 0.55, 1.0)
			for k in 4:
				UISkin.stroke(ci, r.grow(2.0 + k * 2.0), 5, Color(glow, 0.12 - k * 0.025), 2.0)
			UISkin.fill(ci, r, 4, Color("#4A2C6E"), Color("#1A1030"))
			UISkin.stroke(ci, r, 4, Color("#FFD36A"), 1.4)
			UISkin.ornate(ci, r.grow(-3.0))
			var f := UITheme.font_title
			var q := "?"
			var s := 30
			var w := f.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
			c.draw_string_outline(f, Vector2(ctr.x - w / 2.0, ctr.y + 10), q, HORIZONTAL_ALIGNMENT_LEFT, -1, s, 4, Color(0, 0, 0, 0.9))
			c.draw_string(f, Vector2(ctr.x - w / 2.0, ctr.y + 10), q, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color("#FFE7A0"))
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
		"gold", "bundle":
			line = "+" + F.fmt_num(int(res.get("gold", 0))) + " " + DataDB.t("gold")
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
