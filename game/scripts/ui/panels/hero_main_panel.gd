extends PanelWindow
## Main hero window (taskbar-hero style): equipment around the hero's portrait on parchment, party switcher,
## the bag grid (or the party formation on its tab) and a bar of bronze buttons that open the side panels.

const EQUIP_L := ["weapon", "offhand", "helm", "chest", "gloves", "boots"]
const EQUIP_R := ["amulet", "cape", "ring1", "ring2", "belt", "charm"]
const SLOT_ICONS := {"weapon": "sword", "offhand": "shield", "helm": "crown", "chest": "shield", "gloves": "hammer", "boots": "boot",
	"belt": "bag", "cape": "flag", "amulet": "gem", "ring1": "gem", "ring2": "gem", "charm": "sparkle"}
const SLOT := 22.0
const COLS := 10

var tab := 0                      # 0 bag, 1 formation
var sel_slot := 0                 # formation: selected party slot
var _equip: Dictionary = {}
var _portrait: TextureRect
var _cls: Label
var _lvl: Label
var _xp: ProgressBar
var _stars: Label
var _party_row: Control
var _tabs: HBoxContainer
var _page: Control
var _bag_grid: GridContainer
var _bag_slots: Array = []
var _count: Label
var _ctx: PopupMenu
var _ctx_uid := ""
var _bottom: HBoxContainer
var _gold: Label


func build(c: Control) -> void:
	var w := c.size.x
	# ---------------------------------------------------------------- parchment: equipment + portrait
	var parch := UITheme.nine("parchment", 4)
	parch.position = Vector2(0, 0)
	parch.size = Vector2(w, 100)
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
		UISkin.fill(ci, Rect2(Vector2.ZERO, frame.size), 2, fc.darkened(0.25), fc.darkened(0.75)))
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
		# soft vignette at the bottom so the level text reads
		UISkin.fill(ci, Rect2(1, r.size.y - 16, r.size.x - 2, 15), 1, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.65)))
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
	_lvl.position = Vector2(px + 4, 56)
	c.add_child(_lvl)
	_stars = UITheme.label("", Color("#FFD84A"), 7)
	_stars.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_stars.add_theme_constant_override("outline_size", 2)
	_stars.position = Vector2(px + pw - 40, 58)
	_stars.size = Vector2(37, 9)
	_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	c.add_child(_stars)
	_xp = UITheme.bar(int(pw), 3, Color("#F2B33D"))
	_xp.position = Vector2(px, 75)
	c.add_child(_xp)
	_party_row = Control.new()
	_party_row.position = Vector2(px - 2, 79)
	_party_row.size = Vector2(pw + 4, 20)
	c.add_child(_party_row)
	# ---------------------------------------------------------------- tabs
	_tabs = W.tabs([DataDB.t("panel_inventory"), DataDB.t("tab_formation")], tab, _on_tab, 58)
	_tabs.position = Vector2(0, 104)
	c.add_child(_tabs)
	var tools := W.hbox(2)
	tools.position = Vector2(w - 70, 104)
	c.add_child(tools)
	var sb := UITheme.button("", "brown", func(): GameState.sort_bag(), Vector2(14, 13))
	sb.icon = UITheme.icon("sort")
	sb.expand_icon = true
	sb.tooltip_text = DataDB.t("tip_sort")
	tools.add_child(sb)
	var sell := UITheme.button(DataDB.t("btn_sell_junk"), "red", _sell_junk, Vector2(0, 13))
	sell.tooltip_text = DataDB.t("tip_sell_junk")
	sell.add_theme_font_size_override("font_size", 7)
	tools.add_child(sell)
	# ---------------------------------------------------------------- page (bag grid / formation)
	var well := UITheme.nine("well", 2)
	well.position = Vector2(0, 120)
	well.size = Vector2(w, 150)
	c.add_child(well)
	_page = Control.new()
	_page.position = Vector2(2, 122)
	_page.size = Vector2(w - 4, 146)
	c.add_child(_page)
	# ---------------------------------------------------------------- bottom bar
	_bottom = W.hbox(5)
	_bottom.position = Vector2(2, 273)
	c.add_child(_bottom)
	for d in [["chart", "stats", "tip_open_stats"], ["book", "skills", "tip_open_skills"], ["hammer", "blacksmith", "panel_blacksmith"],
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
	_count = UITheme.label("", UITheme.C_DIM, 7)
	_count.position = Vector2(w - 70, 290)
	_count.size = Vector2(68, 9)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	c.add_child(_count)
	_ctx = PopupMenu.new()
	_ctx.add_theme_font_override("font", UITheme.font_small)
	_ctx.add_theme_font_size_override("font_size", 8)
	_ctx.id_pressed.connect(_on_ctx)
	add_child(_ctx)
	EventBus.inventory_changed.connect(refresh)
	EventBus.equipment_changed.connect(func(_h): refresh())
	EventBus.party_changed.connect(refresh)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.gold_changed.connect(func(_g): _gold.text = F.fmt_num(GameState.gold))
	_build_page()
	refresh()


func _arrow(t: String, cb: Callable) -> Button:
	var b := UITheme.button(t, "orange", cb, Vector2(13, 11))
	b.add_theme_font_size_override("font_size", 9)
	return b


func _add_equip(c: Control, key: String, pos: Vector2) -> void:
	var s := ItemSlot.new(SLOT)
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
	if tab == 0:
		var sc := W.scroll(_page.size)
		_page.add_child(sc)
		_bag_grid = W.grid(COLS, 1)
		sc.add_child(_bag_grid)
	else:
		_build_formation()


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
	_count.text = "%d / %d" % [GameState.bag.size(), GameState.bag_slots]
	for k in _equip:
		var s: ItemSlot = _equip[k]
		s.set_item(h.equipment.get(k, {}) if h else {})
		s.compare_hero = hid
	if h:
		set_panel_title(DataDB.t("panel_hero"))
		_cls.text = "%s · %s" % [h.display_name(), h.class_title()]
		_lvl.text = "Lv.%d" % h.level
		_stars.text = "★".repeat(h.stars)
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
			var dot := ColorRect.new()
			dot.color = Color("#FF5A4A")
			dot.size = Vector2(3, 3)
			dot.position = Vector2(16, 1)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(dot)
		var id2: String = hid
		b.pressed.connect(func(): W.select_hero(id2))
		_party_row.add_child(b)
		x += 23.0


# ------------------------------------------------------------------ bag
func _refresh_bag(hid: String) -> void:
	if _bag_grid == null:
		return
	var items: Array = GameState.bag
	var need: int = max(GameState.bag_slots, COLS * 6)
	while _bag_slots.size() < need:
		var sl := ItemSlot.new(SLOT)
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
		sl.set_item(items[i] if i < items.size() else {})
		sl.key = items[i]["uid"] if i < items.size() else null
		sl.dim = i >= GameState.bag_slots
		sl.selected = WindowManager.is_open("blacksmith") and WindowManager.panels["blacksmith"].is_selected(sl.key)


func _on_equip_click(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	GameState.unequip(W.current_hero(), str(slot.key))
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
	else:
		AudioManager.play("equip", 0.05, 0.7)
	WindowManager.hide_tooltip()


func _on_bag_right(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	_ctx_uid = slot.item["uid"]
	_ctx.clear()
	_ctx.add_item(DataDB.t("ctx_equip"), 0)
	_ctx.add_item(DataDB.t("ctx_stash"), 1)
	_ctx.add_item(DataDB.t("ctx_sell") + " (%s)" % F.fmt_num(ItemUtil.sell_price(slot.item)), 2)
	_ctx.add_item(DataDB.t("ctx_salvage"), 3)
	_ctx.add_item(DataDB.t("ctx_unlock") if slot.item.get("locked", false) else DataDB.t("ctx_lock"), 4)
	_ctx.position = DisplayServer.mouse_get_position()
	_ctx.popup()
	WindowManager.hide_tooltip()


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


func _on_drop_bag(_slot: ItemSlot, data: Dictionary) -> void:
	match data.get("source", ""):
		"equip":
			GameState.unequip(W.current_hero(), str(data["key"]))
		"stash":
			GameState.move_to_bag(int(data["key"][0]), str(data["item"]["uid"]))


func _sell_junk() -> void:
	var total := 0
	for it in GameState.bag.duplicate():
		if it.get("locked", false):
			continue
		if ItemUtil.rarity_rank(it.get("rarity", "common")) <= ItemUtil.rarity_rank("magic"):
			total += GameState.sell_item(it["uid"])
	if total > 0:
		EventBus.notify.emit(DataDB.t("sold_for", {"g": F.fmt_num(total)}), UITheme.C_GOLD)
		AudioManager.play("coin", 0.05, 0.8)


# ------------------------------------------------------------------ formation
func _build_formation() -> void:
	if tab != 1:
		return
	for ch in _page.get_children():
		ch.queue_free()
	var unlocked := GameState.unlocked_party_slots()
	var w := _page.size.x
	# five battle slots, back (left) -> front (right), each shows the hero's chibi
	var cw := (w - 8.0) / 5.0
	for vis_i in 5:
		var slot := 4 - vis_i
		var b := UITheme.slot_button(Vector2(cw - 2, 46))
		b.position = Vector2(4 + vis_i * cw, 3)
		var hid: String = GameState.party[slot]
		if hid != "":
			var tex := SpriteLib.chibi_frame("heroes", hid)
			var ic := W.icon_rect(tex if tex else SpriteLib.hero_icon(hid), Vector2(cw - 4, 42))
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.position = Vector2(1, 2)
			ic.size = Vector2(cw - 4, 42)
			b.add_child(ic)
			b.tooltip_text = GameState.heroes[hid].display_name()
		if slot >= unlocked:
			var lk := W.icon_rect(UITheme.icon("lock"), Vector2(10, 10))
			lk.position = Vector2((cw - 12) / 2.0, 18)
			lk.size = Vector2(10, 10)
			b.add_child(lk)
			b.disabled = true
		if slot == sel_slot:
			b.add_child(UITheme.selected_frame(Vector2(cw - 2, 46)))
		var lbl := UITheme.label(DataDB.t("front") if slot == 0 else (DataDB.t("back") if slot == 4 else str(slot + 1)), UITheme.C_DIM, 7)
		lbl.position = Vector2(4 + vis_i * cw, 49)
		lbl.size = Vector2(cw - 2, 8)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_page.add_child(lbl)
		var s2 := slot
		b.pressed.connect(func():
			sel_slot = s2
			_build_formation())
		_page.add_child(b)
	# roster
	var sc := W.scroll(Vector2(w - 4, 62))
	sc.position = Vector2(2, 59)
	_page.add_child(sc)
	var g := W.grid(10, 1)
	sc.add_child(g)
	for hid in GameState.heroes:
		var h: HeroState = GameState.heroes[hid]
		var rb := UITheme.slot_button(Vector2(SLOT, SLOT))
		rb.tooltip_text = "%s  Lv %d  %s" % [h.display_name(), h.level, h.class_title()]
		var ic2 := W.icon_rect(SpriteLib.hero_icon(hid), Vector2(SLOT - 2, SLOT - 2))
		ic2.position = Vector2(1, 1)
		ic2.size = Vector2(SLOT - 2, SLOT - 2)
		rb.add_child(ic2)
		if GameState.party.has(hid):
			var e := UITheme.label(str(GameState.party.find(hid) + 1), UITheme.C_GREEN, 7)
			e.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			e.add_theme_constant_override("outline_size", 2)
			e.position = Vector2(SLOT - 7, SLOT - 10)
			rb.add_child(e)
		var id2: String = hid
		rb.pressed.connect(func():
			if sel_slot < GameState.unlocked_party_slots():
				GameState.set_party_slot(sel_slot, id2)
				W.select_hero(id2)
			_build_formation())
		g.add_child(rb)
	# selected slot: star up / remove
	var row := W.hbox(3)
	row.position = Vector2(2, 124)
	_page.add_child(row)
	var shid: String = GameState.party[sel_slot]
	if shid != "":
		var h2: HeroState = GameState.heroes[shid]
		if h2.stars < 6:
			var cost := Tavern.star_cost(h2)
			var b3 := UITheme.button(DataDB.t("star_up", {"s": int(cost["soul_shard"]), "g": F.fmt_num(int(cost["gold"]))}), "gold", func():
				if Tavern.star_up(h2):
					BattleSim.refresh_hero_stats()
					EventBus.notify.emit(DataDB.t("starred", {"name": h2.display_name(), "n": h2.stars}), UITheme.C_GOLD)
					_build_formation(), Vector2(0, 14))
			b3.disabled = not (GameState.gold >= int(cost["gold"]) and GameState.has_material("soul_shard", int(cost["soul_shard"])))
			row.add_child(b3)
		var rm := UITheme.button(DataDB.t("btn_remove"), "red", func():
			if GameState.party_count() > 1:
				GameState.set_party_slot(sel_slot, "")
				_build_formation(), Vector2(0, 14))
		row.add_child(rm)
