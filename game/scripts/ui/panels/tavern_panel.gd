extends PanelWindow
## Tavern: the whole hero roster as illustrated cards (filter by rarity). Heroes are bought here and only
## here; prices climb with rarity and with every recruit. A card asks for confirmation before buying.

const RARITY_COL := {"R": Color("#A9B1C2"), "SR": Color("#5E9BFF"), "SSR": Color("#FFC24A")}
const COLS := 4
const CARD := Vector2(74, 108)

var _filter := ""
var _top: Control
var _grid: Control
var _scroll: ScrollContainer
var _t := 0.0
var _cards: Array = []
var _host: Control


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
	EventBus.gold_changed.connect(func(_g): _refresh_buttons())
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
	var ids: Array = []
	for hid in Tavern.roster():
		if _filter == "" or Tavern.rarity(hid) == _filter:
			ids.append(hid)
	# not yet recruited first, cheapest first
	ids.sort_custom(func(a, b):
		var oa := GameState.heroes.has(a)
		var ob := GameState.heroes.has(b)
		if oa != ob:
			return ob
		return int(Tavern.cost(a)["gold"]) < int(Tavern.cost(b)["gold"]))
	var gap := (_grid.get_parent_control().size.x - 6.0 - COLS * CARD.x) / (COLS - 1)
	for i in ids.size():
		var pos := Vector2((i % COLS) * (CARD.x + gap), (i / COLS) * (CARD.y + 4.0))
		_card(str(ids[i]), pos)
	_grid.custom_minimum_size = Vector2(_host.size.x - 6, ceil(ids.size() / float(COLS)) * (CARD.y + 4.0))


func _build_top() -> void:
	for ch in _top.get_children():
		ch.queue_free()
	var tabs := [["", DataDB.t("tavern_all")], ["R", "R"], ["SR", "SR"], ["SSR", "SSR"]]
	var x := 0.0
	for tb in tabs:
		var key: String = tb[0]
		var b := UITheme.button(str(tb[1]), "gold" if _filter == key else "brown", func():
			_filter = key
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh(), Vector2(34 if key != "" else 40, 13))
		_top.add_child(b)
		b.position = Vector2(x, 0)
		b.size = Vector2(34 if key != "" else 40, 13)
		x += b.size.x + 2
	var seal := W.icon_rect(UITheme.icon("crown"), Vector2(9, 9))
	seal.position = Vector2(_top.size.x - 30, 2)
	_top.add_child(seal)
	var sl := UITheme.label(str(int(GameState.materials.get("tavern_seal", 0))), UITheme.C_GOLD, 8, UITheme.font_body)
	sl.position = Vector2(_top.size.x - 19, 1)
	sl.tooltip_text = DataDB.t("seals", {"n": int(GameState.materials.get("tavern_seal", 0))})
	sl.mouse_filter = Control.MOUSE_FILTER_STOP
	_top.add_child(sl)
	var hint := UITheme.label(DataDB.t("tavern_hint"), UITheme.C_DIM, 7, UITheme.font_body)
	hint.position = Vector2(0, 16)
	hint.size = Vector2(_top.size.x, 10)
	hint.clip_text = true
	_top.add_child(hint)


func _card(hid: String, pos: Vector2) -> void:
	var d := DataDB.hero_def(hid)
	var rar: String = d.get("rarity", "R")
	var rcol: Color = RARITY_COL.get(rar, Color.WHITE)
	var fac := Color(str(DataDB.factions.get(d.get("faction", ""), {}).get("color", "#7A5A44")))
	var tex := SpriteLib.portrait(hid)
	var owned := GameState.heroes.has(hid)
	var c := Control.new()
	c.position = pos
	c.size = CARD
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	var sig: Dictionary = d.get("signature", {})
	c.tooltip_text = "%s · %s\n%s\n✦ %s: +%s %s" % [str(d.get("name", hid)), DataDB.tx(DataDB.class_def(d["class"]).get("name", {})),
		DataDB.tx(DataDB.class_def(d["class"]).get("role", {})), DataDB.tx(sig.get("name", {})),
		StatNames.fmt(str(sig.get("stat", "")), float(sig.get("value", 0))), StatNames.label(str(sig.get("stat", "")))]
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.fill(ci, r, 4, fac.darkened(0.3), Color("#100E14"))
		for k in 5:
			c.draw_circle(Vector2(r.size.x / 2.0, r.size.y * 0.33), r.size.x * (0.6 - k * 0.09), Color(rcol, 0.04))
		if tex:
			var art_h := r.size.y * 0.78
			var aw := tex.get_width() * art_h / float(tex.get_height())
			c.draw_texture_rect(tex, Rect2(Vector2((r.size.x - aw) / 2.0, 3), Vector2(aw, art_h)), false,
				Color.WHITE if not owned else Color(0.55, 0.55, 0.6))
		UISkin.fill(ci, Rect2(0, r.size.y * 0.5, r.size.x, r.size.y * 0.5), 0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.9))
		var pulse := 0.65 + 0.35 * sin(_t * 3.0) if rar == "SSR" else 0.85
		UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 3, Color(rcol, pulse), 1.3)
		var tag := Rect2(3, 3, 21 if rar == "SSR" else 16, 9)
		UISkin.fill(ci, tag, 2, rcol.lightened(0.15), rcol.darkened(0.35))
		UISkin.stroke(ci, tag, 2, Color(0, 0, 0, 0.9), 1.0)
		c.draw_string(UITheme.font_body, tag.position + Vector2(2.5, 7.5), rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208"))
		var f := UITheme.font_title
		var nm := str(d.get("name", hid))
		var tw := minf(f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x, r.size.x - 4)
		c.draw_string_outline(f, Vector2((r.size.x - tw) / 2.0, r.size.y - 30), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 9, 3, Color(0, 0, 0, 0.95))
		c.draw_string(f, Vector2((r.size.x - tw) / 2.0, r.size.y - 30), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 9, rcol.lightened(0.3))
		var cl := DataDB.tx(DataDB.class_def(d["class"]).get("name", {}))
		var fb := UITheme.font_body
		var cw := minf(fb.get_string_size(cl, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, r.size.x - 4)
		c.draw_string(fb, Vector2((r.size.x - cw) / 2.0, r.size.y - 21), cl, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 7, Color("#CFC6B4")))
	_grid.add_child(c)
	_cards.append(c)
	if owned:
		var badge := UITheme.label("✓ " + DataDB.t("tavern_owned"), UITheme.C_GREEN, 8, UITheme.font_body)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.position = Vector2(0, CARD.y - 15)
		badge.size = Vector2(CARD.x, 12)
		c.add_child(badge)
		return
	if not Tavern.level_ok(hid):
		var lk := UITheme.label("🔒 " + DataDB.t("tavern_need_lv", {"lv": Tavern.level_req(hid)}), UITheme.C_RED, 7, UITheme.font_body)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lk.position = Vector2(0, CARD.y - 15)
		lk.size = Vector2(CARD.x, 12)
		c.add_child(lk)
		return
	var cost := Tavern.cost(hid)
	var txt := F.fmt_num(int(cost["gold"])) + ("  +%d♛" % int(cost["tavern_seal"]) if int(cost["tavern_seal"]) > 0 else "")
	var b := UITheme.button(txt, "gold" if rar != "R" else "orange", func(): _ask(hid), Vector2(CARD.x - 8, 13))
	c.add_child(b)
	b.size = Vector2(CARD.x - 8, 13)
	b.position = Vector2(4, CARD.y - 16)
	b.disabled = not Tavern.can_afford(hid)
	b.set_meta("hid", hid)


func _refresh_buttons() -> void:
	for cd in _cards:
		if not is_instance_valid(cd):
			continue
		for ch in cd.get_children():
			if ch is Button and ch.has_meta("hid"):
				ch.disabled = not Tavern.can_afford(str(ch.get_meta("hid")))


func _ask(hid: String) -> void:
	var cost := Tavern.cost(hid)
	var ctxt := F.fmt_num(int(cost["gold"])) + " " + DataDB.t("gold") + ("  +%d %s" % [int(cost["tavern_seal"]), DataDB.t("seal_name")] if int(cost["tavern_seal"]) > 0 else "")
	W.confirm(_host, DataDB.t("tavern_confirm", {"name": str(DataDB.hero_def(hid).get("name", hid)), "cost": ctxt}), func():
		if Tavern.recruit(hid):
			AudioManager.play("recruit")
			refresh()
		else:
			EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED), DataDB.t("btn_recruit"))
