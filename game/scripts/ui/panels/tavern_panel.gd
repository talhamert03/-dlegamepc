extends PanelWindow
## Tavern: three hero offers shown as illustrated recruitment cards (refresh every 4h), recruit with gold + seals.

const RARITY_COL := {"R": Color("#A9B1C2"), "SR": Color("#5E9BFF"), "SSR": Color("#FFC24A")}

var _body: Control
var _t := 0.0
var _cards: Array = []


func build(c: Control) -> void:
	_body = Control.new()
	_body.size = c.size
	c.add_child(_body)
	EventBus.gold_changed.connect(func(_g): refresh())
	EventBus.hero_unlocked.connect(func(_h): refresh())
	refresh()


func _process(delta: float) -> void:
	_t += delta
	for cd in _cards:
		if is_instance_valid(cd):
			cd.queue_redraw()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	_cards.clear()
	var w := _body.size.x
	var locked := GameState.max_hero_level() < 8 and GameState.heroes.size() < 4
	# top bar: seals, refresh timer, refresh button
	var bar := UITheme.nine("well", 2)
	bar.size = Vector2(w, 18)
	_body.add_child(bar)
	var seal := W.icon_rect(UITheme.icon("crown"), Vector2(10, 10))
	seal.position = Vector2(5, 4)
	_body.add_child(seal)
	var sl := UITheme.label(str(int(GameState.materials.get("tavern_seal", 0))), UITheme.C_GOLD, 9, UITheme.font_body)
	sl.position = Vector2(18, 3)
	sl.tooltip_text = DataDB.t("seals", {"n": int(GameState.materials.get("tavern_seal", 0))})
	sl.mouse_filter = Control.MOUSE_FILTER_STOP
	_body.add_child(sl)
	if not locked:
		Tavern.ensure_offers()
		var left: int = max(0, int(GameState.tavern.get("refresh_at", 0)) - TimeService.unix_now())
		var tl := UITheme.label("⟳ %d:%02d" % [left / 3600, (left % 3600) / 60], UITheme.C_DIM, 8)
		tl.position = Vector2(48, 3)
		_body.add_child(tl)
		var rc := Tavern.refresh_cost()
		var rb := UITheme.button(DataDB.t("btn_refresh") + "  " + F.fmt_num(rc), "brown", func():
			if GameState.spend_gold(rc):
				Tavern.ensure_offers(true)
				AudioManager.play("ui_travel")
				refresh(), Vector2(0, 14))
		rb.position = Vector2(w - 92, 2)
		_body.add_child(rb)
		rb.size = Vector2(90, 14)
	# three cards
	var cw := (w - 8.0) / 3.0
	var ch := _body.size.y - 24.0
	var offers: Array = [] if locked else GameState.tavern.get("offers", [])
	for i in 3:
		var pos := Vector2(i * (cw + 4.0), 23.0)
		if i < offers.size():
			_card(str(offers[i]), pos, Vector2(cw, ch))
		else:
			_card_back(pos, Vector2(cw, ch), locked)
	if locked:
		var msg := UITheme.label(DataDB.t("tavern_locked"), UITheme.C_TEXT, 9, UITheme.font_body)
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		msg.add_theme_constant_override("outline_size", 3)
		msg.position = Vector2(10, ch * 0.62 + 23)
		msg.size = Vector2(w - 20, 30)
		_body.add_child(msg)


func _card_back(pos: Vector2, sz: Vector2, locked: bool) -> void:
	var c := Control.new()
	c.position = pos
	c.size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.fill(ci, r, 4, Color("#2A2430"), Color("#141218"))
		UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.9), 1.0)
		UISkin.stroke(ci, r.grow(-2.0), 3, Color(UISkin.BRONZE, 0.55), 1.0)
		var cc := r.get_center() - Vector2(0, 14)
		UISkin.diamond(ci, cc, 14.0, Color("#4A3C52"), Color("#231C29"))
		UISkin.ring(ci, cc, 20.0, Color(UISkin.BRONZE, 0.35), 1.0)
		var f := UITheme.font_title
		c.draw_string(f, cc + Vector2(-5, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.7, 0.55)))
	_body.add_child(c)
	if locked:
		var lk := W.icon_rect(UITheme.icon("lock"), Vector2(12, 12))
		lk.position = pos + Vector2(sz.x / 2.0 - 6, sz.y - 22)
		lk.size = Vector2(12, 12)
		_body.add_child(lk)


func _card(hid: String, pos: Vector2, sz: Vector2) -> void:
	var d := DataDB.hero_def(hid)
	var rar: String = d.get("rarity", "R")
	var rcol: Color = RARITY_COL.get(rar, Color.WHITE)
	var fac := Color(str(DataDB.factions.get(d.get("faction", ""), {}).get("color", "#7A5A44")))
	var tex := SpriteLib.portrait(hid)
	var c := Control.new()
	c.position = pos
	c.size = sz
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.fill(ci, r, 4, fac.darkened(0.35), Color("#121016"))
		# light behind the hero
		for k in 6:
			c.draw_circle(Vector2(r.size.x / 2.0, r.size.y * 0.36), r.size.x * (0.62 - k * 0.08), Color(rcol, 0.035))
		if tex:
			var art_h := r.size.y * 0.66
			var aw := tex.get_width() * art_h / float(tex.get_height())
			c.draw_texture_rect(tex, Rect2(Vector2((r.size.x - aw) / 2.0, 6), Vector2(aw, art_h)), false)
		# dark band for the text
		UISkin.fill(ci, Rect2(0, r.size.y * 0.52, r.size.x, r.size.y * 0.48), 0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.85))
		# rarity frame; SSR shimmers
		var pulse := 0.65 + 0.35 * sin(_t * 3.0) if rar == "SSR" else 0.85
		UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 3, Color(rcol, pulse), 1.4)
		if rar != "R":
			UISkin.stroke(ci, r.grow(-3.0), 2, Color(rcol, 0.22 * pulse), 2.0)
		# rarity tag
		var tag := Rect2(4, 4, 22 if rar == "SSR" else 17, 10)
		UISkin.fill(ci, tag, 2, rcol.lightened(0.15), rcol.darkened(0.35))
		UISkin.stroke(ci, tag, 2, Color(0, 0, 0, 0.9), 1.0)
		c.draw_string(UITheme.font_body, tag.position + Vector2(3, 8), rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208")))
	_body.add_child(c)
	_cards.append(c)
	var y := sz.y * 0.6
	var nm := UITheme.label(str(d.get("name", hid)), rcol.lightened(0.25), 10, UITheme.font_title)
	nm.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	nm.add_theme_constant_override("outline_size", 3)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.position = pos + Vector2(2, y)
	nm.size = Vector2(sz.x - 4, 12)
	_body.add_child(nm)
	var cls := UITheme.label(DataDB.tx(DataDB.class_def(d["class"]).get("name", {})) + "  ·  " +
		DataDB.tx(DataDB.factions.get(d.get("faction", ""), {}).get("name", {})), Color("#CFC6B4"), 7)
	cls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cls.clip_text = true
	cls.position = pos + Vector2(2, y + 12)
	cls.size = Vector2(sz.x - 4, 9)
	_body.add_child(cls)
	var sig: Dictionary = d.get("signature", {})
	var sg := UITheme.label("✦ " + DataDB.tx(sig.get("name", {})), UITheme.C_GREEN, 7)
	sg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sg.clip_text = true
	sg.position = pos + Vector2(2, y + 21)
	sg.size = Vector2(sz.x - 4, 9)
	sg.tooltip_text = "%s: +%s" % [StatNames.label(str(sig.get("stat", ""))), StatNames.fmt(str(sig.get("stat", "")), float(sig.get("value", 0)))]
	sg.mouse_filter = Control.MOUSE_FILTER_STOP
	_body.add_child(sg)
	var cost := Tavern.cost(hid)
	var txt := DataDB.t("free") if int(cost["gold"]) == 0 else "%s  +%d" % [F.fmt_num(int(cost["gold"])), int(cost["tavern_seal"])]
	var b := UITheme.button(txt, "gold" if rar != "R" else "orange", func():
		if Tavern.recruit(hid):
			AudioManager.play("recruit")
			refresh()
		else:
			EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED), Vector2(sz.x - 10, 15))
	b.position = pos + Vector2(5, sz.y - 19)
	b.size = Vector2(sz.x - 10, 15)
	b.disabled = not Tavern.can_afford(hid)
	_body.add_child(b)
	b.size = Vector2(sz.x - 10, 15)
