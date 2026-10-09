extends PanelWindow
## Main hero window (taskbar-hero style): equipment around the hero's portrait on parchment, party switcher,
## the bag grid (or the party formation on its tab) and a bar of bronze buttons that open the side panels.

const EQUIP_L := ["weapon", "offhand", "helm", "chest", "gloves", "boots"]
const EQUIP_R := ["amulet", "cape", "ring1", "ring2", "belt", "charm"]
const SLOT_ICONS := {"weapon": "sword", "offhand": "shield", "helm": "crown", "chest": "shield", "gloves": "hammer", "boots": "boot",
	"belt": "bag", "cape": "flag", "amulet": "gem", "ring1": "gem", "ring2": "gem", "charm": "sparkle"}
const SLOT := 24.0
const COLS := 9

var tab := 0                      # 0 bag, 1 formation
var sel_slot := 0                 # formation: selected party slot
var _equip: Dictionary = {}
var _portrait: TextureRect
var _cls: Label
var _lvl: Label
var _hdps: Label
var _xp: ProgressBar
var _stars: Control
var _party_row: Control
var _tabs: HBoxContainer
var _page: Control
var _bag_grid: GridContainer
var _bag_slots: Array = []
var _count: Control
var _ctx_uid := ""
var _bottom: HBoxContainer
var _last_uids: Dictionary = {}
var _shown_hero := ""
var _gold: Label
var _tools: HBoxContainer
var _changed_item: Dictionary = {}
var _host: Control


func build(c: Control) -> void:
	_host = c
	var w := c.size.x
	# ---------------------------------------------------------------- parchment: equipment + portrait
	var parch := Control.new()
	parch.position = Vector2(0, 0)
	parch.size = Vector2(w, 100)
	parch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parch.draw.connect(func():
		var ci := parch.get_canvas_item()
		UISkin.parchment(ci, Rect2(Vector2(1, 1), parch.size - Vector2(2, 2)))
		UISkin.ornate(ci, Rect2(Vector2(1, 1), parch.size - Vector2(2, 2))))
	c.add_child(parch)
	for i in 6:
		var col := i % 2
		var row := i / 2
		_add_equip(c, EQUIP_L[i], Vector2(5 + col * (SLOT + 2), 5 + row * (SLOT + 2)))
		_add_equip(c, EQUIP_R[i], Vector2(w - 5 - SLOT * 2 - 2 + col * (SLOT + 2), 5 + row * (SLOT + 2)))
	var px := 5 + SLOT * 2 + 6
	var pw := w - px * 2
	var frame := Control.new()
	frame.position = Vector2(px, 4)
	frame.size = Vector2(pw, 70)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(func():
		var ci := frame.get_canvas_item()
		var hid := W.current_hero()
		var fac: String = DataDB.hero_def(hid).get("faction", "empire") if hid != "" else "empire"
		var fc := Color(str(DataDB.factions.get(fac, {}).get("color", "#7A5A44")))
		var fr := Rect2(Vector2.ZERO, frame.size)
		UISkin.fill(ci, fr, 2, fc.darkened(0.35), fc.darkened(0.8))
		# a spotlight behind the hero, faint rays from the top and a floor shadow: a lit stage
		var sc := Vector2(fr.size.x * 0.5, fr.size.y * 0.42)
		for k in 9:
			RenderingServer.canvas_item_add_circle(ci, sc, fr.size.x * 0.48 * (1.0 - k * 0.1), Color(fc.lightened(0.45), 0.055))
		for k in 5:
			var x0 := fr.size.x * (0.18 + k * 0.16)
			var ray := PackedVector2Array([Vector2(x0 - 3.0, 0), Vector2(x0 + 3.0, 0), Vector2(sc.x + (x0 - sc.x) * 0.25 + 9.0, fr.size.y), Vector2(sc.x + (x0 - sc.x) * 0.25 - 9.0, fr.size.y)])
			RenderingServer.canvas_item_add_polygon(ci, ray, PackedColorArray([Color(1, 0.95, 0.8, 0.07), Color(1, 0.95, 0.8, 0.07), Color(1, 0.95, 0.8, 0.0), Color(1, 0.95, 0.8, 0.0)]))
		UISkin.fill(ci, Rect2(0, fr.size.y * 0.78, fr.size.x, fr.size.y * 0.22), 0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.35)))
	c.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portrait.size = frame.size
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_portrait)
	var rim := Control.new()
	rim.position = frame.position
	rim.size = frame.size
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.draw.connect(func():
		var ci := rim.get_canvas_item()
		var r := Rect2(Vector2.ZERO, rim.size)
		UISkin.stroke(ci, r, 2, Color(0, 0, 0, 0.9), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.8), 1.0)
		# soft vignette at the bottom so the level text reads, and side vignettes framing the hero
		UISkin.fill(ci, Rect2(1, r.size.y - 16, r.size.x - 2, 15), 1, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.65))
		var cl := Color(0, 0, 0, 0)
		var sh := Color(0, 0, 0, 0.45)
		RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([Vector2(1, 1), Vector2(14, 1), Vector2(14, r.size.y - 1), Vector2(1, r.size.y - 1)]), PackedColorArray([sh, cl, cl, sh]))
		RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([Vector2(r.size.x - 14, 1), Vector2(r.size.x - 1, 1), Vector2(r.size.x - 1, r.size.y - 1), Vector2(r.size.x - 14, r.size.y - 1)]), PackedColorArray([cl, sh, sh, cl]))
		# name plate: a dark glass band with gilded rules under the arrows
		var np := Rect2(12, 2.0, r.size.x - 24, 11.5)
		UISkin.fill(ci, np, 2, Color(0.04, 0.03, 0.02, 0.62), Color(0.04, 0.03, 0.02, 0.48))
		UISkin.line(ci, Vector2(np.position.x + 3, np.end.y + 0.3), Vector2(np.end.x - 3, np.end.y + 0.3), Color(UISkin.BRONZE_HI, 0.7), 0.7)
		UISkin.diamond(ci, Vector2(r.size.x / 2.0, np.end.y + 0.3), 1.6)
		# level plaque bottom left
		var lp := Rect2(2.5, r.size.y - 17.0, _lvl.size.x + 6.0 if _lvl else 34.0, 14.5)
		UISkin.fill(ci, lp, 2.5, Color(0.08, 0.05, 0.03, 0.85), Color(0.03, 0.02, 0.01, 0.85))
		UISkin.stroke(ci, lp, 2.5, Color(UISkin.BRONZE, 0.85), 0.7)
		# gilded corner brackets and a keystone gem: the portrait reads as a framed painting
		for i in 4:
			var cc: Vector2 = [Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)][i]
			var dx := 1.0 if i == 0 or i == 3 else -1.0
			var dy := 1.0 if i < 2 else -1.0
			var arm := PackedVector2Array([cc + Vector2(dx * 9.0, dy * 1.0), cc + Vector2(dx * 1.0, dy * 1.0), cc + Vector2(dx * 1.0, dy * 9.0)])
			rim.draw_polyline(arm, UISkin.OUTLINE, 3.0, true)
			rim.draw_polyline(arm, UISkin.BRONZE_HI, 1.4, true)
			UISkin.diamond(ci, cc + Vector2(dx * 3.2, dy * 3.2), 1.6, Color("#FFE08A"), Color("#B07420"))
		UISkin.diamond(ci, Vector2(r.size.x / 2.0, 0.5), 3.0)
		UISkin.diamond(ci, Vector2(r.size.x / 2.0, 0.5), 1.7, Color("#FF7A7A"), Color("#7A0C18")))
	c.add_child(rim)
	# class ribbon with hero switch arrows
	var cr := W.hbox(0)
	cr.position = Vector2(px + 2, 3)
	cr.size = Vector2(pw - 4, 12)
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(cr)
	cr.add_child(_arrow("‹", func(): _cycle_hero(-1)))
	_cls = UITheme.label("", Color("#FFF0D2"), 8, UITheme.font_body)
	_cls.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_cls.add_theme_constant_override("outline_size", 3)
	_cls.custom_minimum_size = Vector2(pw - 34, 11)
	_cls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cls.clip_text = true
	cr.add_child(_cls)
	cr.add_child(_arrow("›", func(): _cycle_hero(1)))
	_lvl = UITheme.label("", Color("#FFE7A6"), 10, UITheme.font_title)
	_lvl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_lvl.add_theme_constant_override("outline_size", 3)
	_lvl.position = Vector2(px + 5.5, 57)
	_lvl.resized.connect(rim.queue_redraw)
	c.add_child(_lvl)
	_hdps = UITheme.label("", Color("#FF9A6A"), 8, UITheme.font_body)
	_hdps.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hdps.add_theme_constant_override("outline_size", 3)
	_hdps.position = Vector2(px + 4, 46)
	_hdps.mouse_filter = Control.MOUSE_FILTER_STOP
	_hdps.tooltip_text = DataDB.t("hero_dps_tip")
	c.add_child(_hdps)
	_stars = _star_plate()
	_stars.position = Vector2(px + pw - 47, 59)
	c.add_child(_stars)
	_xp = UITheme.bar(int(pw), 3, Color("#F2B33D"))
	_xp.position = Vector2(px, 75)
	c.add_child(_xp)
	_party_row = Control.new()
	_party_row.position = Vector2(px - 2, 79)
	_party_row.size = Vector2(pw + 4, 20)
	c.add_child(_party_row)
	# ---------------------------------------------------------------- tabs
	_tabs = W.tabs([DataDB.t("panel_inventory"), DataDB.t("tab_formation"), DataDB.t("tab_chests")], tab, _on_tab, 50)
	_tabs.position = Vector2(0, 104)
	c.add_child(_tabs)
	_tools = W.hbox(2)
	_tools.position = Vector2(w - 78, 104)
	c.add_child(_tools)
	var sb := UITheme.button("", "brown", func(): GameState.sort_bag(), Vector2(14, 13))
	sb.icon = UITheme.icon("sort")
	sb.expand_icon = true
	sb.tooltip_text = DataDB.t("tip_sort")
	_tools.add_child(sb)
	var fb := UITheme.button("", "brown", _loot_filter_dialog, Vector2(14, 13))
	fb.icon = UITheme.icon("gear")
	fb.expand_icon = true
	fb.tooltip_text = DataDB.t("tip_loot_filter")
	_tools.add_child(fb)
	var sell := UITheme.button(DataDB.t("btn_sell"), "red", _sell_dialog, Vector2(0, 13))
	sell.tooltip_text = DataDB.t("tip_sell_junk")
	sell.add_theme_font_size_override("font_size", 7)
	_tools.add_child(sell)
	# ---------------------------------------------------------------- page (bag grid / formation)
	var well := Control.new()
	well.position = Vector2(0, 120)
	well.size = Vector2(w, 150)
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well.draw.connect(func():
		var ci := well.get_canvas_item()
		UISkin.well(ci, Rect2(Vector2.ZERO, well.size))
		UISkin.ornate(ci, Rect2(Vector2(1, 1), well.size - Vector2(2, 2))))
	c.add_child(well)
	_page = Control.new()
	_page.position = Vector2(2, 122)
	_page.size = Vector2(w - 4, 146)
	c.add_child(_page)
	# ---------------------------------------------------------------- bottom bar
	_bottom = W.hbox(5)
	_bottom.position = Vector2(2, 273)
	c.add_child(_bottom)
	for d in [["cross", "stats", "tip_open_stats"], ["rune", "runes", "tip_runes"], ["hammer", "blacksmith", "panel_blacksmith"],
			["chest", "stash", "panel_stash"], ["heart", "pets", "panel_pets"]]:
		var pid: String = d[1]
		var m := UITheme.medallion(d[0], func(): WindowManager.toggle_panel(pid), DataDB.t(d[2]), 11.0)
		m.set_meta("panel", pid)
		_bottom.add_child(m)
	var gbox := W.hbox(2)
	gbox.position = Vector2(w - 70, 280)
	c.add_child(gbox)
	gbox.add_child(W.icon_rect(UITheme.icon("gold"), Vector2(9, 9)))
	_gold = UITheme.label("", UITheme.C_GOLD, 9, UITheme.font_body)
	gbox.add_child(_gold)
	_count = Fancy.capacity(44, 10)
	_count.position = Vector2(w - 46, 289)
	_count.tooltip_text = DataDB.t("bag_capacity_tip")
	c.add_child(_count)
	# bag expansion lives right here, next to the slot count: a small "+" plate
	var ex := Button.new()
	ex.flat = true
	ex.focus_mode = Control.FOCUS_NONE
	ex.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ex.position = Vector2(w - 68, 289)
	ex.size = Vector2(20, 10)
	ex.tooltip_text = DataDB.t("bag_expand_tip", {"price": Shop.price_text(Shop.product("bag_expand"))})
	ex.pressed.connect(_ask_bag_expand)
	ex.draw.connect(func():
		var ci := ex.get_canvas_item()
		var r := Rect2(Vector2.ZERO, ex.size)
		UISkin.button(ci, r, "gold", "pressed" if ex.button_pressed else ("hover" if ex.is_hovered() else "normal"))
		var tw := UITheme.font_body.get_string_size("+10", HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		ex.draw_string(UITheme.font_body, Vector2((r.size.x - tw) / 2.0, 7.4 + (1.0 if ex.button_pressed else 0.0)), "+10", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#2A1606")))
	for sig in [ex.mouse_entered, ex.mouse_exited, ex.button_down, ex.button_up]:
		sig.connect(ex.queue_redraw)
	c.add_child(ex)
	EventBus.inventory_changed.connect(refresh)
	EventBus.equipment_changed.connect(func(_h): refresh())
	EventBus.party_changed.connect(refresh)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.gold_changed.connect(func(_g): _gold.text = F.fmt_num(GameState.gold))
	_build_page()
	refresh()


## Six stars under the portrait. Lit stars are earned; when the next one is affordable the next empty star
## pulses. Click: confirm card with the price and what a star gives (soul shards are the only sink).
func _star_plate() -> Control:
	var c := Control.new()
	c.size = Vector2(44, 10)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.mouse_entered.connect(func(): c.set_meta("hov", true); c.queue_redraw())
	c.mouse_exited.connect(func(): c.set_meta("hov", false); c.queue_redraw())
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_ask_star_up())
	c.draw.connect(func():
		var hid := W.current_hero()
		if not GameState.heroes.has(hid):
			return
		var h: HeroState = GameState.heroes[hid]
		var ready := _star_ready(hid)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
		if c.get_meta("hov", false):
			UISkin.fill(c.get_canvas_item(), Rect2(Vector2.ZERO, c.size), 3, Color(1, 0.85, 0.4, 0.22), Color(1, 0.7, 0.2, 0.12))
		for k in 6:
			var ctr := Vector2(4.0 + k * 7.2, 5.0)
			var on := k < h.stars
			var nxt := ready and k == h.stars
			if nxt:
				c.draw_circle(ctr, 4.6, Color(1, 0.85, 0.3, 0.25 + 0.35 * pulse))
			_draw_star(c, ctr, 3.9, Color(0, 0, 0, 0.85))
			var col := Color("#FFD84A") if on else (Color("#FFE89A", 0.55 + 0.45 * pulse) if nxt else Color("#4A4038"))
			_draw_star(c, ctr, 3.0, col)
			if on:
				_draw_star(c, ctr + Vector2(-0.4, -0.5), 1.3, Color(1, 1, 0.9, 0.7)))
	return c


func _draw_star(c: Control, ctr: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(ctr + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	c.draw_colored_polygon(pts, col)


func _star_ready(hid: String) -> bool:
	if not GameState.heroes.has(hid):
		return false
	var h: HeroState = GameState.heroes[hid]
	if h.stars >= 6:
		return false
	var cost := Tavern.star_cost(h)
	return GameState.gold >= int(cost["gold"]) and GameState.has_material("soul_shard", int(cost["soul_shard"]))


func _star_tip(h: HeroState) -> String:
	if h.stars >= 6:
		return DataDB.t("star_max", {"name": h.display_name()})
	var cost := Tavern.star_cost(h)
	return DataDB.t("star_tip", {"n": h.stars, "s": int(cost["soul_shard"]), "have": int(GameState.materials.get("soul_shard", 0)),
		"g": F.fmt_num(int(cost["gold"]))})


func _ask_star_up() -> void:
	var hid := W.current_hero()
	if not GameState.heroes.has(hid):
		return
	var h: HeroState = GameState.heroes[hid]
	if h.stars >= 6:
		EventBus.notify.emit(DataDB.t("star_max", {"name": h.display_name()}), UITheme.C_GOLD)
		return
	if not _star_ready(hid):
		AudioManager.play("smith_fail", 0.05, 0.4)
		var need := Tavern.star_cost(h)
		EventBus.notify.emit(DataDB.t("star_need", {"s": int(need["soul_shard"]), "have": int(GameState.materials.get("soul_shard", 0)),
			"g": F.fmt_num(int(need["gold"]))}), UITheme.C_RED)
		return
	var cost := Tavern.star_cost(h)
	W.confirm(_host, DataDB.t("star_up_ask", {"name": h.display_name(), "n": h.stars + 1,
		"s": int(cost["soul_shard"]), "g": F.fmt_num(int(cost["gold"]))}), func():
			if Tavern.star_up(h):
				BattleSim.refresh_hero_stats()
				AudioManager.play("levelup", 0.0, 0.6)
				EventBus.notify.emit(DataDB.t("starred", {"name": h.display_name(), "n": h.stars}), UITheme.C_GOLD)
				refresh(), DataDB.t("btn_star_up"))


func _arrow(t: String, cb: Callable) -> Button:
	var b := UITheme.button(t, "orange", cb, Vector2(13, 11))
	b.add_theme_font_size_override("font_size", 9)
	return b


func _add_equip(c: Control, key: String, pos: Vector2) -> void:
	var s := ItemSlot.new(SLOT)
	s.double_click_only = true
	s.source = "equip"
	s.key = key
	s.placeholder = UITheme.icon(SLOT_ICONS.get(key, "star"))
	s.position = pos
	s.left_clicked.connect(_on_equip_click)
	s.right_clicked.connect(_on_equip_click)
	s.dropped.connect(_on_drop_equip)
	c.add_child(s)
	_equip[key] = s


func _on_tab(i: int) -> void:
	tab = i
	W.set_tab_active(_tabs, i)
	_build_page()
	refresh()


func _build_page() -> void:
	for ch in _page.get_children():
		ch.queue_free()
	_bag_slots.clear()
	_bag_grid = null
	if _tools:
		_tools.visible = tab == 0
	if tab == 0:
		var sc := W.scroll(_page.size)
		_page.add_child(sc)
		_bag_grid = W.grid(COLS, 1)
		sc.add_child(_bag_grid)
	elif tab == 1:
		_build_formation()
	else:
		var cv := ChestsView.new()
		cv.size = _page.size
		_page.add_child(cv)


func _cycle_hero(dir: int) -> void:
	var ids: Array = []
	for hid in GameState.party:
		if hid != "":
			ids.append(hid)
	if ids.is_empty():
		return
	var i: int = max(0, ids.find(W.current_hero()))
	W.select_hero(str(ids[(i + dir + ids.size()) % ids.size()]))


func _process(_d: float) -> void:
	var hid := W.current_hero()
	if _stars and Engine.get_process_frames() % 4 == 0 and _star_ready(hid):
		_stars.queue_redraw()
	if _hdps and Engine.get_process_frames() % 30 == 0:
		var d := BattleSim.hero_dps(hid)
		_hdps.text = ("⚔ %s DPS" % F.fmt_num(d)) if d > 0.0 and GameState.party.has(hid) else ""
	if hid != "" and _xp and GameState.heroes.has(hid):
		var h: HeroState = GameState.heroes[hid]
		_xp.max_value = F.xp_required(h.level)
		_xp.value = h.xp

	for m in _bottom.get_children():
		var on: bool = WindowManager.is_open(str(m.get_meta("panel", "")))
		if m.get_meta("active", false) != on:
			m.set_meta("active", on)
			m.queue_redraw()


func refresh() -> void:
	if _portrait == null:
		return
	var hid := W.current_hero()
	var h: HeroState = GameState.heroes.get(hid)
	_gold.text = F.fmt_num(GameState.gold)
	Fancy.set_capacity(_count, GameState.bag.size(), GameState.bag_slots)
	var changed := false
	for k in _equip:
		var s: ItemSlot = _equip[k]
		var it: Dictionary = h.equipment.get(k, {}) if h else {}
		var uid: String = str(it.get("uid", ""))
		if _shown_hero == hid and _last_uids.get(k, "") != uid and uid != "":
			s.flash()
			changed = true
			_changed_item = it
		_last_uids[k] = uid
		s.set_item(it)
		s.compare_hero = hid
	if changed and visible:
		ItemSfx.equip(_changed_item)
	_shown_hero = hid
	if h:
		set_panel_title(DataDB.t("panel_hero"))
		_cls.text = "%s · %s" % [h.display_name(), h.class_title()]
		_lvl.text = F.lv(h.level, "dot") + ("  ✦P%d" % h.paragon if h.paragon > 0 else "")
		_stars.tooltip_text = _star_tip(h)
		_stars.queue_redraw()
		var tex := SpriteLib.portrait(hid)
		if tex:
			# head-and-shoulders crop of the full-body illustration
			var at := AtlasTexture.new()
			at.atlas = tex
			var tw := float(tex.get_width())
			var bust_h := minf(tex.get_height() * 0.42, tw / (_portrait.size.x / _portrait.size.y))
			var bust_w := bust_h * _portrait.size.x / _portrait.size.y
			at.region = Rect2((tw - bust_w) / 2.0, tex.get_height() * 0.015, bust_w, bust_h)
			_portrait.texture = at
	_build_party_row(hid)
	if tab == 0:
		_refresh_bag(hid)
	else:
		_build_formation()
	queue_redraw()
	for ch in get_children():
		if ch is Control:
			(ch as Control).queue_redraw()


func _build_party_row(sel: String) -> void:
	for ch in _party_row.get_children():
		ch.queue_free()
	var ids: Array = []
	for hid in GameState.party:
		if hid != "":
			ids.append(hid)
	var x := (_party_row.size.x - ids.size() * 20.0 - (ids.size() - 1) * 3.0) / 2.0
	for hid in ids:
		var b := UITheme.slot_button(Vector2(20, 18))
		b.position = Vector2(x, 0)
		b.tooltip_text = DataDB.hero_def(hid).get("name", hid)
		var ic := W.icon_rect(SpriteLib.hero_icon(hid), Vector2(18, 16))
		ic.position = Vector2(1, 1)
		ic.size = Vector2(18, 16)
		b.add_child(ic)
		if hid == sel:
			b.add_child(UITheme.selected_frame(Vector2(20, 18)))
		var h2: HeroState = GameState.heroes.get(hid)
		if h2 and (h2.stat_points > 0 or h2.skill_points > 0):
			var dot := UITheme.badge(7.0)
			dot.position = Vector2(14, -2)
			b.add_child(dot)
		var id2: String = hid
		b.pressed.connect(func(): W.select_hero(id2))
		_party_row.add_child(b)
		x += 23.0


# ------------------------------------------------------------------ bag
func _refresh_bag(hid: String) -> void:
	if _bag_grid == null:
		return
	var items: Array = GameState.bag_layout()
	var need: int = max(items.size(), COLS * 6)
	while _bag_slots.size() < need:
		var sl := ItemSlot.new(SLOT)
		sl.double_click_only = true
		sl.source = "bag"
		sl.left_clicked.connect(_on_bag_click)
		sl.right_clicked.connect(_on_bag_right)
		sl.dropped.connect(_on_drop_bag)
		_bag_grid.add_child(sl)
		_bag_slots.append(sl)
	for i in _bag_slots.size():
		var sl: ItemSlot = _bag_slots[i]
		sl.visible = i < need
		sl.compare_hero = hid
		var it: Variant = items[i] if i < items.size() else null
		sl.set_item(it if it != null else {})
		sl.key = it["uid"] if it != null else null
		sl.set_meta("cell", i)
		sl.dim = i >= GameState.bag_slots
		sl.selected = WindowManager.is_open("blacksmith") and WindowManager.panels["blacksmith"].is_selected(sl.key)


func _on_equip_click(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	if GameState.unequip(W.current_hero(), str(slot.key)):
		ItemSfx.drop()
	WindowManager.hide_tooltip()


func _on_bag_click(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	var uid: String = slot.item["uid"]
	if WindowManager.is_open("blacksmith"):
		WindowManager.panels["blacksmith"].pick_item(uid)
		refresh()
		return
	if Input.is_key_pressed(KEY_SHIFT):
		GameState.sell_item(uid)
		return
	if Input.is_key_pressed(KEY_CTRL):
		GameState.toggle_lock(uid)
		return
	if WindowManager.is_open("stash") and Input.is_key_pressed(KEY_ALT):
		GameState.move_to_stash(uid, WindowManager.panels["stash"].tab)
		return
	var err := GameState.equip_from_bag(W.current_hero(), uid)
	if err != "":
		EventBus.notify.emit(err, UITheme.C_RED)
	WindowManager.hide_tooltip()


func _on_bag_right(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	_ctx_uid = slot.item["uid"]
	var locked: bool = slot.item.get("locked", false)
	ContextMenu.open([
		[DataDB.t("ctx_equip"), func(): _on_ctx(0)],
		[DataDB.t("ctx_stash"), func(): _on_ctx(1)],
		[DataDB.t("ctx_sell") + "  (%s)" % F.fmt_num(ItemUtil.sell_price(slot.item)), func(): _on_ctx(2), Color("#F2C45A")],
		[DataDB.t("ctx_salvage"), func(): _on_ctx(3)],
		[DataDB.t("ctx_unlock") if locked else DataDB.t("ctx_lock"), func(): _on_ctx(4)],
	], WindowManager.desktop.get_local_mouse_position())


func _on_ctx(id: int) -> void:
	match id:
		0:
			var err := GameState.equip_from_bag(W.current_hero(), _ctx_uid)
			if err != "":
				EventBus.notify.emit(err, UITheme.C_RED)
		1:
			var t := 0
			if WindowManager.is_open("stash"):
				t = WindowManager.panels["stash"].tab
			if not GameState.move_to_stash(_ctx_uid, t):
				EventBus.notify.emit(DataDB.t("stash_full"), UITheme.C_RED)
		2:
			GameState.sell_item(_ctx_uid)
		3:
			GameState.salvage_item(_ctx_uid)
		4:
			GameState.toggle_lock(_ctx_uid)


func _on_drop_equip(slot: ItemSlot, data: Dictionary) -> void:
	if data.get("source", "") == "bag":
		var err := GameState.equip_from_bag(W.current_hero(), str(data["item"]["uid"]), str(slot.key))
		if err != "":
			EventBus.notify.emit(err, UITheme.C_RED)


func _on_drop_bag(slot: ItemSlot, data: Dictionary) -> void:
	var cell := int(slot.get_meta("cell", -1))
	match data.get("source", ""):
		"bag":
			GameState.move_in_bag(str(data["item"]["uid"]), cell)
		"equip":
			var uid := str(data["item"].get("uid", ""))
			if GameState.unequip(W.current_hero(), str(data["key"])) and slot.item.is_empty():
				GameState.move_in_bag(uid, cell)
		"stash":
			GameState.move_to_bag(int(data["key"][0]), str(data["item"]["uid"]))


## Sell by rarity: tick the rarities, see how many items and how much gold, then confirm.
func _sell_dialog() -> void:
	var picks := {"common": true, "magic": true, "rare": false, "epic": false, "legendary": false}
	var veil := Control.new()
	veil.size = _host.size
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 50
	veil.draw.connect(func(): veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.02, 0.01, 0.03, 0.72)))
	_host.add_child(veil)
	var card := Control.new()
	card.size = Vector2(196, 146)
	card.position = ((veil.size - card.size) / 2.0).round()
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		UISkin.popup(ci, Rect2(Vector2.ZERO, card.size), 0.6, 0.15))
	veil.add_child(card)
	var title := UITheme.label(DataDB.t("sell_title"), UITheme.C_TITLE, 10, UITheme.font_title)
	title.position = Vector2(10, 6)
	card.add_child(title)
	var summary := UITheme.label("", UITheme.C_GOLD, 8, UITheme.font_body)
	summary.position = Vector2(10, 104)
	summary.size = Vector2(176, 10)
	card.add_child(summary)
	var go: Button
	var recount := func():
		var n := 0
		var g := 0
		for it in GameState.bag:
			if not it.get("locked", false) and picks.get(str(it.get("rarity", "common")), false):
				n += 1
				g += ItemUtil.sell_price(it)
		summary.text = DataDB.t("sell_summary", {"n": n, "g": F.fmt_num(g)})
		if go:
			go.disabled = n == 0
	var y := 22.0
	for r in picks.keys():
		var rr: String = r
		var cnt := 0
		for it in GameState.bag:
			if str(it.get("rarity", "")) == rr and not it.get("locked", false):
				cnt += 1
		# rarity row: drawn checkbox, rarity gem, name, how many would go
		var b := Button.new()
		b.flat = true
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.button_pressed = picks[rr]
		b.size = Vector2(176, 14)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var rcol := ItemUtil.rarity_color(rr)
		var label := ItemUtil.rarity_name(rr)
		for sig in [b.mouse_entered, b.mouse_exited]:
			sig.connect(b.queue_redraw)
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var rect := Rect2(Vector2.ZERO, b.size)
			var on := b.button_pressed
			UISkin.fill(ci, rect, 3, Color("#3A2A20") if on else Color("#241A14"), Color("#1A120C"))
			UISkin.stroke(ci, rect, 3, UISkin.OUTLINE, 1.0)
			if b.is_hovered():
				UISkin.stroke(ci, rect.grow(-1.0), 2, Color(rcol, 0.45), 0.8)
			var box := Rect2(5, 3, 8, 8)
			UISkin.fill(ci, box, 1.5, Color("#120C08"), Color("#2A1E14"))
			UISkin.stroke(ci, box, 1.5, Color(UISkin.BRONZE, 0.9), 0.8)
			if on:
				b.draw_polyline(PackedVector2Array([Vector2(6.6, 7.2), Vector2(8.6, 9.2), Vector2(12, 4.6)]), Color("#8CFF7A"), 1.4, true)
			UISkin.diamond(ci, Vector2(21, 7), 3.0, rcol.lightened(0.25), rcol.darkened(0.35))
			var fb := UITheme.font_body
			b.draw_string(fb, Vector2(28, 10), label, HORIZONTAL_ALIGNMENT_LEFT, 110, 8, rcol if on else Color(rcol, 0.6))
			var ct := str(cnt)
			var cw := fb.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			b.draw_string(fb, Vector2(rect.size.x - cw - 6, 10), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#E8D8B8") if on else UITheme.C_DIM))
		b.toggled.connect(func(on: bool):
			picks[rr] = on
			AudioManager.play("ui_click", 0.05, 0.4)
			b.queue_redraw()
			recount.call())
		card.add_child(b)
		b.position = Vector2(10, y)
		y += 16.0
	go = Fancy.small_button(DataDB.t("btn_sell"), "red", func():
		var total := 0
		for it in GameState.bag.duplicate():
			if not it.get("locked", false) and picks.get(str(it.get("rarity", "common")), false):
				total += GameState.sell_item(it["uid"])
		veil.queue_free()
		if total > 0:
			EventBus.notify.emit(DataDB.t("sold_for", {"g": F.fmt_num(total)}), UITheme.C_GOLD)
			AudioManager.play("coin", 0.05, 0.8), Vector2(84, 15))
	card.add_child(go)
	go.position = Vector2(10, 124)
	var no := Fancy.small_button(DataDB.t("btn_cancel"), "brown", func(): veil.queue_free(), Vector2(84, 15))
	card.add_child(no)
	no.position = Vector2(102, 124)
	recount.call()


## What happens to new drops of each rarity: keep, sell at once or salvage into materials.
func _loot_filter_dialog() -> void:
	var veil := Control.new()
	veil.size = _host.size
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 50
	veil.draw.connect(func(): veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.02, 0.01, 0.03, 0.72)))
	_host.add_child(veil)
	var card := Control.new()
	card.size = Vector2(212, 146)
	card.position = ((veil.size - card.size) / 2.0).round()
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		UISkin.popup(ci, Rect2(Vector2.ZERO, card.size), 0.6, 0.15))
	veil.add_child(card)
	var title := UITheme.label(DataDB.t("loot_filter_title"), UITheme.C_TITLE, 10, UITheme.font_title)
	title.position = Vector2(10, 6)
	card.add_child(title)
	var hint := UITheme.label(DataDB.t("loot_filter_hint"), UITheme.C_DIM, 7, UITheme.font_body)
	hint.position = Vector2(10, 18)
	hint.size = Vector2(192, 10)
	hint.clip_text = true
	card.add_child(hint)
	var y := 32.0
	var acts := ["keep", "sell", "salvage"]
	for r in ["common", "magic", "rare", "epic"]:
		var rr: String = r
		var l := UITheme.label(ItemUtil.rarity_name(rr), ItemUtil.rarity_color(rr), 8, UITheme.font_body)
		l.position = Vector2(10, y + 1)
		card.add_child(l)
		var btns: Array = []
		for i in acts.size():
			var act: String = acts[i]
			var on: bool = Settings.loot_action(rr) == act
			var b := UITheme.button(DataDB.t(act), "gold" if on else "brown", Callable(), Vector2(44, 13))
			card.add_child(b)
			b.position = Vector2(64 + i * 46, y)
			b.size = Vector2(44, 13)
			btns.append(b)
		for i in btns.size():
			var act2: String = acts[i]
			btns[i].pressed.connect(func():
				Settings.set_v("loot_" + rr, act2)
				for j in btns.size():
					UITheme.set_button_color(btns[j], "gold" if j == i else "brown"))
		y += 17.0
	var oc := UITheme.button("", "brown", Callable(), Vector2(192, 13))
	oc.toggle_mode = true
	oc.button_pressed = bool(Settings.get_v("loot_offclass_sell", true))
	var oc_txt := func(on: bool) -> String:
		return ("☑  " if on else "☐  ") + DataDB.t("loot_offclass")
	oc.text = oc_txt.call(oc.button_pressed)
	oc.toggled.connect(func(on: bool):
		Settings.set_v("loot_offclass_sell", on)
		oc.text = oc_txt.call(on))
	card.add_child(oc)
	oc.size = Vector2(192, 13)
	oc.position = Vector2(10, y + 1)
	var ok := UITheme.button(DataDB.t("btn_close"), "brown", func(): veil.queue_free(), Vector2(80, 14))
	card.add_child(ok)
	ok.size = Vector2(80, 14)
	ok.position = Vector2(66, y + 19)


func _build_formation() -> void:
	if tab != 1:
		return
	for ch in _page.get_children():
		ch.queue_free()
	var fv := FormationView.new()
	fv.size = _page.size
	_page.add_child(fv)


func _ask_bag_expand() -> void:
	var p := Shop.product("bag_expand")
	var why := Shop.block_reason(p)
	if why != "":
		EventBus.notify.emit(why, UITheme.C_RED)
		return
	var txt := DataDB.t("bag_expand_confirm", {"n": int(p.get("slots", 10)), "price": Shop.price_text(p)})
	if SteamService.payment_mode() == "direct":
		txt += "\n" + DataDB.t("shop_test_note")
	W.confirm(_host, txt, func():
		Shop.buy("bag_expand", func(res: Dictionary):
			if res.is_empty():
				EventBus.notify.emit(DataDB.t("shop_failed"), UITheme.C_RED)
				return
			AudioManager.play("coin", 0.05, 0.9)
			Toast.show_reward(UITheme.icon("bag"), DataDB.t("bag_expanded", {"n": int(p.get("slots", 10))}), DataDB.t("bag_now", {"n": GameState.bag_slots}))
			refresh()), DataDB.t("shop_buy"))
