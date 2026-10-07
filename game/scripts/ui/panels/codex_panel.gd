extends PanelWindow
## Achievements and bestiary.

var tab := 0
var _tabs: HBoxContainer
var _body: VBoxContainer


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("tab_achievements"), DataDB.t("tab_bestiary"), DataDB.t("tab_news")], tab, func(i):
		tab = i
		W.set_tab_active(_tabs, i)
		refresh(), (c.size.x - 4.0) / 3.0)
	v.add_child(_tabs)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 16))
	v.add_child(sc)
	_body = W.vbox(1)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	refresh()


## Achievement: a medallion (gold star when earned, dark lock otherwise), the name and its condition.
const REWARD_ICON := {"gold": "gold", "tavern_seal": "crown", "soul_shard": "gem", "iron_scrap": "hammer",
	"guild_badge": "flag", "shiny_essence": "sparkle", "star_dust": "star", "mythic_essence": "gem"}


## Bestiary tooltip: name, how many fell, its element and where it lives.
func _beast_tip(eid: String, d: Dictionary, kills: int) -> String:
	var lines: Array = [DataDB.tx(d.get("name", {})), DataDB.t("beast_kills", {"n": F.fmt_num(kills)})]
	var el := str(d.get("element", "physical"))
	if el != "physical" and el != "":
		lines.append(DataDB.t("beast_element", {"el": ZoneInfo.element_name(el)}))
	var where: Array = []
	for z in DataDB.zones:
		if z.get("boss", "") == eid or z.get("enemies", []).has(eid):
			where.append(DataDB.tx(z.get("name", {})))
	if where.size() > 0:
		lines.append(DataDB.t("beast_where", {"z": ", ".join(where.slice(0, 3))}))
	return "\n".join(lines)


func _achievement_row(a: Dictionary, w: float) -> Control:
	var got: bool = GameState.achievements.has(a["id"])
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 22)
	var name := DataDB.tx(a["name"])
	var desc := DataDB.tx(a.get("desc", {}))
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2(0, 1), c.size - Vector2(0, 2))
		UISkin.fill(ci, r, 2, Color(0.35, 0.25, 0.12, 0.25) if got else Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.1))
		UISkin.stroke(ci, r, 2, Color(UISkin.BRONZE, 0.35) if got else Color(0, 0, 0, 0.4), 0.7)
		var m := Vector2(11, c.size.y / 2.0)
		UISkin.circle(ci, m, 8.0, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, m, 7.4, UISkin.BRONZE_HI if got else Color("#5A5250"), UISkin.BRONZE_LO if got else Color("#2A2422"))
		UISkin.circle(ci, m, 5.4, Color("#7A3A12") if got else Color("#1E1A18"), Color("#3A1A08") if got else Color("#121010"))
		var ic := UITheme.icon("star" if got else "lock")
		if ic:
			c.draw_texture_rect(ic, Rect2(m - Vector2(3.5, 3.5), Vector2(7, 7)), false, Color("#FFE08A") if got else Color(0.6, 0.56, 0.52))
		var fb := UITheme.font_body
		# reward chip on the right: the first reward with its icon
		var rx := c.size.x - 4.0
		var rw: Dictionary = a.get("reward", {})
		if not rw.is_empty():
			var k0: String = str(rw.keys()[0])
			var amt := F.fmt_num(int(rw[k0])) + ("+" if rw.size() > 1 else "")
			var aw := fb.get_string_size(amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			var chip := Rect2(c.size.x - aw - 18, c.size.y / 2.0 - 5, aw + 14, 10)
			UISkin.fill(ci, chip, 3, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.25))
			var ric := UITheme.icon(REWARD_ICON.get(k0, "gem"))
			if ric:
				c.draw_texture_rect(ric, Rect2(chip.position + Vector2(2, 1.5), Vector2(7, 7)), false, Color(1, 1, 1, 1.0 if got else 0.5))
			c.draw_string(fb, Vector2(chip.position.x + 11, chip.end.y - 2.4), amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color("#FFD86A") if not got else Color("#9C8A6A"))
			rx = chip.position.x - 3
		c.draw_string(fb, Vector2(23, 10), name, HORIZONTAL_ALIGNMENT_LEFT, rx - 23, 8, UITheme.C_GOLD if got else UITheme.C_TEXT)
		c.draw_string(fb, Vector2(23, 19), desc, HORIZONTAL_ALIGNMENT_LEFT, rx - 23, 7, UITheme.C_DIM))
	return c


## One change in the patch notes: a dark card, a gold diamond, the text wrapped in the reading font.
func _note_card(text: String, w: float) -> Control:
	var card := MarginContainer.new()
	card.custom_minimum_size = Vector2(w, 0)
	for side in ["left", "right", "top", "bottom"]:
		card.add_theme_constant_override("margin_" + side, 3)
	card.add_theme_constant_override("margin_left", 12)
	var l := UITheme.para(text, w - 16, Color("#EADFC8"), 8)
	l.add_theme_font_override("font", UITheme.font_read)
	card.add_child(l)
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		var r := Rect2(Vector2.ZERO, card.size)
		UISkin.fill(ci, r, 3, Color("#2A1F18"), Color("#18110C"))
		UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.8), 1.0)
		UISkin.diamond(ci, Vector2(6, 8), 2.4, Color("#FFE08A"), Color("#B07420")))
	return card


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	var w := _body.custom_minimum_size.x
	if tab == 0:
		var done := GameState.achievements.size()
		var tot := DataDB.achievements.size()
		_body.add_child(Fancy.bar(w, 10, float(done) / maxf(1.0, tot), Color("#E8B84A"), "%d / %d" % [done, tot]))
		_body.add_child(W.spacer(0, 2))
		# unlocked first, then the rest in their natural order
		var list: Array = []
		for a0 in DataDB.achievements:
			if GameState.achievements.has(a0["id"]):
				list.append(a0)
		for a0 in DataDB.achievements:
			if not GameState.achievements.has(a0["id"]):
				list.append(a0)
		for a in list:
			_body.add_child(_achievement_row(a, w))
	elif tab == 2:
		# patch notes: a version plaque, then one card per change in the reading font, newest first
		for n in DataDB.patch_notes.get("notes", []):
			_body.add_child(Fancy.section("v%s · %s" % [str(n.get("version", "")), DataDB.tx(n.get("title", {}))], w))
			for it in n.get("items", []):
				_body.add_child(_note_card(DataDB.tx(it), w))
			_body.add_child(W.spacer(0, 4))
	else:
		var seen: Dictionary = GameState.codex.get("enemies", {})
		var tot2 := DataDB.enemies.size() + DataDB.bosses.size()
		_body.add_child(Fancy.bar(w, 10, float(seen.size()) / maxf(1.0, tot2), Color("#C0392B"), "%d / %d" % [seen.size(), tot2]))
		_body.add_child(W.spacer(0, 2))
		var cols := 7
		var cell := floorf((w - (cols - 1) * 2.0) / cols)
		var g := W.grid(cols, 2)
		_body.add_child(g)
		for eid in DataDB.enemies.keys() + DataDB.bosses.keys():
			var known := seen.has(eid)
			var boss := DataDB.bosses.has(eid)
			var d2 := DataDB.enemy_def(eid)
			var sheet := str(d2.get("visual", {}).get("sheet", eid))   # variants (treasure goblin) reuse a sheet
			var tex := SpriteLib.chibi_frame("enemies", sheet)
			if tex == null:
				tex = SpriteLib.hd_sprite("enemies", sheet)
			var card := Control.new()
			card.custom_minimum_size = Vector2(cell, cell + 2)
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.tooltip_text = _beast_tip(str(eid), d2, int(seen[eid])) if known else "???"
			card.draw.connect(func():
				var ci := card.get_canvas_item()
				var r := Rect2(Vector2.ZERO, card.size)
				UISkin.slot(ci, r, Color.WHITE, false, false)
				if tex:
					var tr := r.grow(-2.5)
					var asp := float(tex.get_width()) / float(tex.get_height())
					var dw := minf(tr.size.x, tr.size.y * asp)
					var dh := dw / asp
					var dr := Rect2(tr.position + Vector2((tr.size.x - dw) / 2.0, tr.size.y - dh), Vector2(dw, dh))
					card.draw_texture_rect(tex, Rect2(dr.position + Vector2(dw, 0), Vector2(-dw, dh)), false,
						Color.WHITE if known else Color(0.05, 0.04, 0.06, 0.85))
				if boss:
					UISkin.stroke(ci, r.grow(-0.5), 2, Color("#E0574A", 0.9), 1.0)
				if not known:
					var f := UITheme.font_title
					card.draw_string(f, Vector2(r.size.x / 2.0 - 3, r.size.y / 2.0 + 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.7, 0.55, 0.6)))
			g.add_child(card)
