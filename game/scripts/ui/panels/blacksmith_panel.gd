extends PanelWindow
## Blacksmith: Combine (3x3 + pity) / Enhance / Salvage / Craft.

var tab := 0
var picks: Array = []          # combine selection (uids)
var enh_target := {}           # {"src": "bag"/"equip", "uid"/"hid","slot"}
var craft_tier := 0
var craft_slot := "any"
var _tabs: HBoxContainer
var _body: VBoxContainer
var _lvl: Label
var _xp: ProgressBar
var _auto_rarity := "common"


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("smith_combine"), DataDB.t("smith_enhance"), DataDB.t("smith_salvage"), DataDB.t("smith_craft")], tab, _on_tab, (c.size.x - 6.0) / 4.0)
	v.add_child(_tabs)
	var lh := W.hbox(2)
	v.add_child(lh)
	_lvl = UITheme.label("", UITheme.C_GOLD)
	lh.add_child(_lvl)
	_xp = UITheme.bar(70, 3, Color("#F2B33D"))
	_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lh.add_child(_xp)
	_body = W.vbox(2)
	v.add_child(_body)
	EventBus.inventory_changed.connect(refresh)
	EventBus.materials_changed.connect(refresh)
	refresh()


func _on_tab(i: int) -> void:
	tab = i
	W.set_tab_active(_tabs, i)
	refresh()


func is_selected(uid: Variant) -> bool:
	if uid == null:
		return false
	if tab == 0:
		return picks.has(uid)
	return enh_target.get("uid", "") == uid


func pick_item(uid: String) -> void:
	if tab == 0:
		if picks.has(uid):
			picks.erase(uid)
		elif picks.size() < 9:
			picks.append(uid)
	elif tab == 1:
		enh_target = {"src": "bag", "uid": uid}
	refresh()


func _item_for_target() -> Dictionary:
	if enh_target.get("src", "") == "bag":
		var i := GameState.find_bag_index(str(enh_target["uid"]))
		return GameState.bag[i] if i >= 0 else {}
	if enh_target.get("src", "") == "equip":
		var h: HeroState = GameState.heroes.get(str(enh_target["hid"]))
		return h.equipment.get(str(enh_target["slot"]), {}) if h else {}
	return {}


func refresh() -> void:
	if _body == null:
		return
	_lvl.text = DataDB.t("smith_lv", {"lv": Blacksmith.level()})
	_xp.max_value = Blacksmith.xp_needed(Blacksmith.level())
	_xp.value = int(GameState.blacksmith.get("xp", 0))
	for ch in _body.get_children():
		ch.queue_free()
	picks = picks.filter(func(u): return GameState.find_bag_index(u) >= 0)
	match tab:
		0:
			_build_combine()
		1:
			_build_enhance()
		2:
			_build_salvage()
		3:
			_build_craft()
	for pid in ["inventory", "hero"]:
		if WindowManager.is_open(pid):
			WindowManager.panels[pid].refresh()


const RARITY_CYCLE := ["common", "magic", "rare", "epic", "legendary"]
const CRAFT_SLOTS := [["any", "star"], ["weapon", "sword"], ["helm", "crown"], ["chest", "shield"], ["gloves", "hammer"],
	["boots", "boot"], ["ring", "gem"], ["amulet", "sparkle"]]


## Hero row shared by the tabs: whose class decides what a combine or a craft produces.
func _hero_row(note_key: String) -> void:
	var hid := W.current_hero()
	var hr := W.hbox(4)
	var hl := UITheme.label(DataDB.t(note_key), UITheme.C_DIM, 8, UITheme.font_body)
	hl.custom_minimum_size = Vector2(0, 20)
	hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hr.add_child(hl)
	hr.add_child(W.hero_selector(hid, func(nh: String):
		W.select_hero(nh)
		enh_target = {}
		refresh()))
	_body.add_child(hr)


## Combine: nine items of one rarity laid in a rune circle become one of the next rarity.
func _build_combine() -> void:
	var w := content.size.x
	_hero_row("smith_for_hero")
	var r := ""
	if picks.size() > 0:
		r = GameState.bag[GameState.find_bag_index(picks[0])].get("rarity", "common")
	var cur_r := r if r != "" else _auto_rarity
	var nr := Blacksmith.next_rarity(cur_r)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(w, 92)
	stage.clip_contents = true
	var gx := 18.0
	var gy := 7.0
	stage.draw.connect(func():
		var ci := stage.get_canvas_item()
		var rr := Rect2(Vector2.ZERO, stage.size)
		UISkin.well(ci, rr)
		var col := ItemUtil.rarity_color(cur_r)
		var c := Vector2(gx + 39, gy + 39)
		# rune circle under the grid, turning slowly, brighter as it fills
		var fill := picks.size() / 9.0
		for k in 4:
			stage.draw_circle(c, 44.0 - k * 8.0, Color(col, 0.03 + 0.04 * fill))
		stage.draw_arc(c, 44, 0, TAU, 48, Color(col, 0.35 + 0.4 * fill), 1.2, true)
		stage.draw_arc(c, 40, 0, TAU, 48, Color(col, 0.2 + 0.3 * fill), 0.8, true)
		for k in 12:
			var a := _ct * 0.3 + k * TAU / 12.0
			var p := c + Vector2.from_angle(a) * 42.0
			stage.draw_rect(Rect2(p - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color(col.lightened(0.3), 0.4 + 0.5 * fill))
		# arrow and the result to come
		var ax := gx + 92.0
		stage.draw_colored_polygon(PackedVector2Array([Vector2(ax, c.y - 3), Vector2(ax + 16, c.y - 3), Vector2(ax + 16, c.y - 8), Vector2(ax + 26, c.y),
			Vector2(ax + 16, c.y + 8), Vector2(ax + 16, c.y + 3), Vector2(ax, c.y + 3)]), Color("#E8C27A", 0.5 + 0.5 * fill))
		var res := Rect2(ax + 34, c.y - 17, 34, 34)
		var ncol := ItemUtil.rarity_color(nr) if nr != "" else UITheme.C_DIM
		for k in 4:
			UISkin.fill(ci, res.grow(2.0 + k * 2.0), 4, Color(ncol, 0.06 + 0.04 * sin(_ct * 3.0)), Color(ncol, 0.03))
		UISkin.slot(ci, res, UISkin.rarity_fill(nr if nr != "" else "common"), true, false)
		var f := UITheme.font_title
		stage.draw_string(f, res.get_center() + Vector2(-4, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.85))
		var nm := ItemUtil.rarity_name(nr) if nr != "" else "—"
		var fb := UITheme.font_body
		var tw := fb.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		stage.draw_string(fb, Vector2(res.get_center().x - tw / 2.0, res.end.y + 11), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ncol)
		var cnt := "%d / 9" % picks.size()
		var cw2 := fb.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		stage.draw_string(fb, Vector2(res.get_center().x - cw2 / 2.0, res.position.y - 5), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_GOLD if picks.size() == 9 else UITheme.C_DIM))
	_body.add_child(stage)
	_stage = stage
	var g := W.grid(3, 3)
	g.position = Vector2(gx, gy)
	stage.add_child(g)
	for i in 9:
		var s := ItemSlot.new(24.0)
		s.source = "combine"
		if i < picks.size():
			var bi := GameState.find_bag_index(picks[i])
			s.set_item(GameState.bag[bi])
			s.key = picks[i]
		s.left_clicked.connect(func(sl):
			if sl.key != null:
				picks.erase(sl.key)
				refresh())
		g.add_child(s)
	# rarity gems, auto-fill and clear
	var tools := Control.new()
	tools.custom_minimum_size = Vector2(w, 16)
	_body.add_child(tools)
	for i in RARITY_CYCLE.size():
		var rid: String = RARITY_CYCLE[i]
		var gb := Button.new()
		gb.flat = true
		gb.focus_mode = Control.FOCUS_NONE
		gb.size = Vector2(15, 15)
		gb.position = Vector2(i * 17.0, 0)
		gb.tooltip_text = ItemUtil.rarity_name(rid) + " · " + DataDB.t("smith_bag_count", {"n": GameState.bag.filter(func(it): return it.get("rarity", "") == rid and not it.get("locked", false)).size()})
		gb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gb.pressed.connect(func():
			_auto_rarity = rid
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh())
		gb.draw.connect(func():
			var ci := gb.get_canvas_item()
			var on := rid == _auto_rarity
			var col := ItemUtil.rarity_color(rid)
			var c := Vector2(7.5, 7.5)
			if on:
				UISkin.ring(ci, c, 7.2, Color("#FFE45C"), 1.4)
			UISkin.diamond(ci, c, 5.2 if on else 4.4, col.lightened(0.25), col.darkened(0.4)))
		tools.add_child(gb)
	var af := Fancy.small_button(DataDB.t("smith_autofill"), "gold", _autofill, Vector2(62, 14))
	tools.add_child(af)
	af.position = Vector2(w - 62 - 50, 1)
	var cl := Fancy.small_button(DataDB.t("btn_clear"), "brown", func():
		picks.clear()
		refresh(), Vector2(46, 14))
	tools.add_child(cl)
	cl.position = Vector2(w - 46, 1)
	var pity := int(GameState.blacksmith.get("pity", 0))
	var maxp := int(DataDB.bal("combine.pity", 10))
	var chance := Blacksmith.combine_chance(cur_r)
	_body.add_child(_odds_strip(chance, pity, maxp, "combine", w))
	var prob := Blacksmith.combine_problem(picks)
	_body.add_child(_round_action("merge", DataDB.t("smith_combine"), prob == "", DataDB.t(prob) if prob != "" else "", _do_combine, w))


## Chance ring + pity pips + recent roll dots in one line (combine).
func _odds_strip(chance: float, fails: int, pity: int, kind: String, w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 26)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.tooltip_text = DataDB.t("smith_pity", {"n": fails, "m": pity})
	var log: Array = []
	for e in GameState.blacksmith.get("log", []):
		if str(e.get("k", "")) == kind and log.size() < 8:
			log.append(e)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var fb := UITheme.font_body
		var rc := Vector2(12, 13)
		var col := UITheme.C_GREEN if chance >= 0.7 else (Color("#FFC94A") if chance >= 0.4 else Color("#FF7A6A"))
		c.draw_circle(rc, 12.0, UISkin.OUTLINE)
		c.draw_circle(rc, 11.0, Color("#1A120C"))
		c.draw_arc(rc, 9.0, -PI / 2.0, -PI / 2.0 + TAU, 32, Color(0.25, 0.18, 0.12), 3.0, true)
		c.draw_arc(rc, 9.0, -PI / 2.0, -PI / 2.0 + TAU * chance, 32, col, 3.0, true)
		var pt := "%%%d" % int(round(chance * 100.0)) if DataDB.lang == "tr" else "%d%%" % int(round(chance * 100.0))
		var pw := fb.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		c.draw_string(fb, rc + Vector2(-pw / 2.0, 2.2), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, col)
		c.draw_string(fb, Vector2(30, 10), DataDB.t("smith_success", {"p": int(round(chance * 100.0))}), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
		c.draw_string(fb, Vector2(30, 22), DataDB.t("smith_pity_short"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM)
		var px := 30.0 + fb.get_string_size(DataDB.t("smith_pity_short"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 6.0
		for i in pity:
			var on := i < fails
			UISkin.diamond(ci, Vector2(px + i * 7.0, 19.5), 2.4, Color("#FFE08A") if on else Color("#4A3A30"), Color("#B07420") if on else Color("#241A14"))
		var lx := w - 4.0
		for e in log:
			lx -= 7.0
			c.draw_circle(Vector2(lx, 19.5), 2.4, Color("#6FE08A") if e.get("ok", false) else Color("#FF6A5A")))
	return c


## Big round action button (merge / hammer / plus) with its label, or the reason it cannot be pressed.
func _round_action(glyph: String, label: String, ok: bool, reason: String, cb: Callable, w: float) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(w, 46)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(30, 30)
	b.position = Vector2((w - 30) / 2.0, 2)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ok else Control.CURSOR_ARROW
	b.tooltip_text = label if ok else reason
	b.disabled = not ok
	for sig in [b.mouse_entered, b.mouse_exited, b.button_down, b.button_up]:
		sig.connect(b.queue_redraw)
	b.pressed.connect(cb)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var c := Vector2(15, 15 + (1.0 if b.button_pressed else 0.0))
		var hov := b.is_hovered() and ok
		if ok:
			var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0)
			b.draw_circle(c, 15.0, Color(1.0, 0.85, 0.4, 0.12 + 0.12 * p))
		UISkin.circle(ci, c + Vector2(0, 1.2), 13.4, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
		UISkin.circle(ci, c, 13.2, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, c, 12.4, (UISkin.BRONZE_HI if hov else UISkin.BRONZE) if ok else Color("#5A5650"), UISkin.BRONZE_LO if ok else Color("#2A2622"))
		var inner_top := {"plus": Color("#2E8A3E"), "merge": Color("#6A3AB0"), "hammer": Color("#B0602A"), "salvage": Color("#A03030")}.get(glyph, Color("#2E8A3E"))
		UISkin.circle(ci, c, 9.4, inner_top if ok else Color("#2A2826"), inner_top.darkened(0.5) if ok else Color("#161412"))
		UISkin.ring(ci, c, 9.4, Color(0, 0, 0, 0.6), 1.0)
		var pc := Color("#F4ECFF") if ok else Color("#6A6660")
		match glyph:
			"plus":
				b.draw_rect(Rect2(c.x - 5.5, c.y - 1.4, 11, 2.8), pc)
				b.draw_rect(Rect2(c.x - 1.4, c.y - 5.5, 2.8, 11), pc)
			"merge":
				for k in 3:
					var a := -PI / 2.0 + k * TAU / 3.0 + Time.get_ticks_msec() / 900.0
					var p0 := c + Vector2.from_angle(a) * 6.0
					b.draw_line(p0, c + Vector2.from_angle(a) * 2.0, pc, 1.4, true)
					b.draw_circle(p0, 1.5, pc)
				b.draw_circle(c, 2.2, pc)
			"hammer":
				var ic := UITheme.icon("hammer")
				if ic:
					b.draw_texture_rect(ic, Rect2(c - Vector2(6, 6), Vector2(12, 12)), false, pc)
		b.draw_circle(c + Vector2(-3, -4), 2.2, Color(1, 1, 1, 0.2)))
	if ok:
		var tm := Timer.new()
		tm.wait_time = 0.05
		tm.autostart = true
		tm.timeout.connect(b.queue_redraw)
		b.add_child(tm)
	row.add_child(b)
	var lab := UITheme.label(label if ok else reason, Color("#FFE7B0") if ok else Color("#FF8A7A"), 8, UITheme.font_title if ok else UITheme.font_body)
	lab.position = Vector2(0, 34)
	lab.size = Vector2(w, 11)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.clip_text = true
	row.add_child(lab)
	return row


func _autofill() -> void:
	picks.clear()
	var cand: Array = GameState.bag.filter(func(it): return it.get("rarity", "") == _auto_rarity and not it.get("locked", false))
	cand.sort_custom(func(a, b): return int(a.get("ilvl", 0)) < int(b.get("ilvl", 0)))
	for it in cand.slice(0, 9):
		picks.append(it["uid"])
	refresh()


func _do_combine() -> void:
	var res := Blacksmith.combine(picks, GameState.heroes[W.current_hero()].cls() if W.current_hero() != "" else "")
	picks.clear()
	if not res.get("ok", false):
		EventBus.notify.emit(DataDB.t(str(res.get("error", ""))), UITheme.C_RED)
	elif res["success"]:
		var it: Dictionary = res["item"]
		EventBus.notify.emit(DataDB.t("smith_combine_ok", {"name": ItemUtil.display_name(it)}), ItemUtil.rarity_color(it["rarity"]))
		AudioManager.play("smith_success")
	else:
		EventBus.notify.emit(DataDB.t("smith_combine_fail"), UITheme.C_RED)
		AudioManager.play("smith_fail")
	refresh()


const EQUIP_ORDER := ["weapon", "offhand", "helm", "chest", "gloves", "boots", "belt", "cape", "amulet", "ring1", "ring2", "charm"]
const MAT_ICON := {"iron_scrap": "hammer", "soul_shard": "gem", "shiny_essence": "sparkle", "guild_badge": "flag", "tavern_seal": "crown"}
var _stage: Control
var _fx := ""          # "ok" | "fail" after a roll, drawn over the anvil
var _fx_t := 9.0
var _fx_lv := 0
var _ct := 0.0         # clock for the combine rune circle


func _process(delta: float) -> void:
	_ct += delta
	if (tab == 0 or tab == 1) and is_instance_valid(_stage):
		_stage.queue_redraw()
	if _fx_t < 1.6:
		_fx_t += delta
		if is_instance_valid(_stage):
			_stage.queue_redraw()


## Enhance, laid out top to bottom like a forge: pick a hero, pick one of their twelve items (or any bag
## item), see it on the anvil with the next level and what it gains, read the odds and the price, press +.
func _build_enhance() -> void:
	var w := content.size.x
	var hid := W.current_hero()
	var h: HeroState = GameState.heroes.get(hid)
	# hero row
	var hr := W.hbox(4)
	var hl := UITheme.label(DataDB.t("smith_pick_hero"), UITheme.C_DIM, 8, UITheme.font_body)
	hl.custom_minimum_size = Vector2(0, 20)
	hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hr.add_child(hl)
	hr.add_child(W.hero_selector(hid, func(nh: String):
		W.select_hero(nh)
		enh_target = {}
		refresh()))
	_body.add_child(hr)
	# the hero's equipment, two rows of six; the current target is gilded
	if h and enh_target.is_empty():
		for sl in EQUIP_ORDER:
			if not h.equipment.get(sl, {}).is_empty():
				enh_target = {"src": "equip", "hid": hid, "slot": sl}
				break
	var gw := 6 * 24.0 + 5 * 3.0
	var gbox := Control.new()
	gbox.custom_minimum_size = Vector2(w, 52)
	gbox.draw.connect(func():
		var r := Rect2((w - gw) / 2.0 - 4, 0, gw + 8, 52)
		UISkin.well(gbox.get_canvas_item(), r))
	_body.add_child(gbox)
	if h:
		for i in EQUIP_ORDER.size():
			var sl: String = EQUIP_ORDER[i]
			var s := ItemSlot.new(24.0)
			s.source = "equip"
			s.key = sl
			s.set_item(h.equipment.get(sl, {}))
			s.placeholder = UITheme.icon({"weapon": "sword", "offhand": "shield", "helm": "crown", "chest": "shield", "gloves": "hammer",
				"boots": "boot", "belt": "bag", "cape": "flag", "amulet": "gem", "ring1": "gem", "ring2": "gem", "charm": "sparkle"}.get(sl, "star"))
			s.selected = enh_target.get("src", "") == "equip" and enh_target.get("slot", "") == sl and enh_target.get("hid", "") == hid
			s.position = Vector2((w - gw) / 2.0 + (i % 6) * 27.0, 2 + (i / 6) * 25.0)
			s.left_clicked.connect(func(_x):
				if not h.equipment.get(sl, {}).is_empty():
					enh_target = {"src": "equip", "hid": hid, "slot": sl}
					AudioManager.play("ui_click", 0.05, 0.5)
					refresh())
			gbox.add_child(s)
	var it := _item_for_target()
	_stage = _anvil_stage(it, w)
	_body.add_child(_stage)
	if it.is_empty():
		return
	var info := Blacksmith.enhance_info(it)
	if info.is_empty():
		var mx := UITheme.label(DataDB.t("smith_max"), UITheme.C_GOLD, 9, UITheme.font_title)
		mx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mx.custom_minimum_size = Vector2(w, 16)
		_body.add_child(mx)
		return
	_body.add_child(_odds_block(it, info, w))
	_body.add_child(_plus_button(info, w))


## Forge stage: warm glow, an anvil with the item on it, and "+5 → +6" with the stat it raises.
func _anvil_stage(it: Dictionary, w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 70)
	c.clip_contents = true
	var nxt := it.duplicate(true)
	if not it.is_empty():
		nxt["enhance"] = int(it.get("enhance", 0)) + 1
	var lines: Array = []
	if not it.is_empty() and not Blacksmith.enhance_info(it).is_empty():
		var a := ItemUtil.item_stats(it)
		var b := ItemUtil.item_stats(nxt)
		for k in ["weapon_atk", "def_flat", "hp_flat"]:
			if a.has(k) and absf(float(b.get(k, 0)) - float(a[k])) > 0.001:
				var nm := DataDB.t("weapon_damage") if k == "weapon_atk" else (StatNames.label("def") if k == "def_flat" else StatNames.label("max_hp"))
				lines.append([nm, F.fmt_num(float(a[k])), F.fmt_num(float(b[k]))])
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.well(ci, r)
		# forge glow from below
		for k in 6:
			c.draw_circle(Vector2(46, r.size.y + 6), 46.0 - k * 7.0, Color(1.0, 0.45, 0.15, 0.035 + 0.008 * sin(_ct * 2.3 + k)))
		# embers drifting up from the forge, each on its own slow loop
		for k in 8:
			var life := fposmod(_ct * 0.35 + k * 0.125, 1.0)
			var ex := 20.0 + fposmod(k * 37.0, 56.0) + sin(_ct * 1.7 + k * 2.1) * 4.0 * life
			var ey := r.size.y - 4.0 - life * (r.size.y - 8.0)
			var ea := (1.0 - life) * minf(1.0, life * 6.0)
			c.draw_circle(Vector2(ex, ey), 1.6 * (1.0 - life * 0.5), Color(1.0, 0.55, 0.15, 0.35 * ea))
			c.draw_circle(Vector2(ex, ey), 0.8, Color(1.0, 0.88, 0.55, 0.95 * ea))
		# anvil
		var ax := 46.0
		var ay := r.size.y - 12.0
		var horn := PackedVector2Array([Vector2(ax - 28, ay - 14), Vector2(ax + 22, ay - 14), Vector2(ax + 30, ay - 11), Vector2(ax + 22, ay - 8),
			Vector2(ax + 12, ay - 8), Vector2(ax + 8, ay - 2), Vector2(ax + 14, ay + 6), Vector2(ax - 14, ay + 6), Vector2(ax - 8, ay - 2),
			Vector2(ax - 12, ay - 8), Vector2(ax - 24, ay - 8)])
		UISkin.poly(ci, horn, Color("#5A5A66"), Color("#24242C"))
		var hc := horn.duplicate()
		hc.append(horn[0])
		c.draw_polyline(hc, UISkin.OUTLINE, 1.0, true)
		c.draw_line(Vector2(ax - 26, ay - 13.4), Vector2(ax + 21, ay - 13.4), Color(1, 1, 1, 0.25), 0.8)
		if it.is_empty():
			var t0 := DataDB.t("smith_pick_item")
			var fb0 := UITheme.font_body
			var tw0 := fb0.get_string_size(t0, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			c.draw_string(fb0, Vector2(84 + (r.size.x - 84 - tw0) / 2.0, r.size.y / 2.0 + 3), t0, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_DIM)
			return
		var f := UITheme.font_title
		var fb := UITheme.font_body
		var x0 := 86.0
		c.draw_string(fb, Vector2(x0, 12), ItemUtil.display_name(it), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x0 - 4, 8, ItemUtil.rarity_color(it.get("rarity", "common")))
		var e := int(it.get("enhance", 0))
		if Blacksmith.enhance_info(it).is_empty():
			c.draw_string(f, Vector2(x0, 32), "+%d" % e, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.C_GOLD)
		else:
			var t1 := "+%d" % e
			var t2 := "+%d" % (e + 1)
			var w1 := f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			c.draw_string_outline(f, Vector2(x0, 32), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color(0, 0, 0, 0.8))
			c.draw_string(f, Vector2(x0, 32), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#D8C4A0"))
			var axx := x0 + w1 + 6.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(axx, 24), Vector2(axx + 10, 24), Vector2(axx + 10, 21), Vector2(axx + 16, 26.5),
				Vector2(axx + 10, 32), Vector2(axx + 10, 29), Vector2(axx, 29)]), Color("#E8C27A"))
			c.draw_string_outline(f, Vector2(axx + 21, 32), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color(0, 0, 0, 0.8))
			c.draw_string(f, Vector2(axx + 21, 32), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8CF09A"))
			var y := 45.0
			for ln in lines:
				c.draw_string(fb, Vector2(x0, y), "%s: %s" % [ln[0], ln[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM)
				var lw := fb.get_string_size("%s: %s" % [ln[0], ln[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
				c.draw_string(fb, Vector2(x0 + lw + 4, y), "→ " + str(ln[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#8CF09A"))
				y += 10.0
		# result flash after a roll
		if _fx_t < 1.6 and _fx != "":
			var k := _fx_t / 1.6
			var a := 1.0 - k
			if _fx == "ok":
				for i in 12:
					var ang := TAU * i / 12.0 + 0.3
					var d := 8.0 + 34.0 * k
					c.draw_circle(Vector2(ax, ay - 30) + Vector2(cos(ang), sin(ang) * 0.7) * d, 1.6 * a + 0.3, Color(1.0, 0.85, 0.4, a))
				c.draw_rect(r, Color(1.0, 0.85, 0.4, 0.18 * a))
				var tt := "+%d!" % _fx_lv
				c.draw_string_outline(f, Vector2(ax - 12, ay - 40 - 10 * k), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(0, 0, 0, a))
				c.draw_string(f, Vector2(ax - 12, ay - 40 - 10 * k), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 1.0, 0.6, a))
			else:
				c.draw_rect(r, Color(1.0, 0.2, 0.15, 0.2 * a))
				for i in 4:
					var sx := ax - 10 + i * 7.0
					c.draw_line(Vector2(sx, ay - 40), Vector2(sx + 4, ay - 30), Color(1, 0.4, 0.3, a), 1.0)
					c.draw_line(Vector2(sx + 4, ay - 30), Vector2(sx - 1, ay - 22), Color(1, 0.4, 0.3, a), 1.0)
				var ft := DataDB.t("smith_failed_short")
				c.draw_string_outline(fb, Vector2(ax - 22, ay - 42), ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color(0, 0, 0, a))
				c.draw_string(fb, Vector2(ax - 22, ay - 42), ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.5, 0.45, a)))
	if not it.is_empty():
		var big := ItemSlot.new(30.0)
		big.source = "smith"
		big.set_item(it)
		big.position = Vector2(31, 70 - 12 - 14 - 30)
		c.add_child(big)
	return c


## Chance ring, price, material, pity pips, the last rolls and the drop warning.
func _odds_block(it: Dictionary, info: Dictionary, w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 50)
	var chance := float(info["chance"])
	var cost := int(info["cost"])
	var mat := str(info["mat"])
	var mat_n := int(info["mat_n"])
	var have_mat := int(GameState.materials.get(mat, 0)) if mat != "" else 0
	var fails := int(info["fails"])
	var pity := int(info["pity"])
	var log: Array = []
	for e in GameState.blacksmith.get("log", []):
		if str(e.get("k", "")) == "enhance" and log.size() < 8:
			log.append(e)
	c.tooltip_text = DataDB.t("smith_enh_pity", {"n": fails, "m": pity})
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var fb := UITheme.font_body
		var f := UITheme.font_title
		# chance ring
		var rc := Vector2(22, 24)
		var col := UITheme.C_GREEN if chance >= 0.7 else (Color("#FFC94A") if chance >= 0.4 else Color("#FF7A6A"))
		c.draw_circle(rc, 20.0, UISkin.OUTLINE)
		c.draw_circle(rc, 18.5, Color("#1A120C"))
		c.draw_arc(rc, 15.5, -PI / 2.0, -PI / 2.0 + TAU, 40, Color(0.25, 0.18, 0.12), 4.0, true)
		c.draw_arc(rc, 15.5, -PI / 2.0, -PI / 2.0 + TAU * chance, 40, col, 4.0, true)
		UISkin.ring(ci, rc, 19.5, Color(UISkin.BRONZE, 0.7), 1.0)
		var pt := "%d%%" % int(round(chance * 100.0)) if DataDB.lang != "tr" else "%%%d" % int(round(chance * 100.0))
		var pw := fb.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		c.draw_string(fb, rc + Vector2(-pw / 2.0, 3.5), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
		var cl := DataDB.t("smith_chance")
		var clw := fb.get_string_size(cl, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		c.draw_string(fb, Vector2(rc.x - clw / 2.0, 49), cl, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, UITheme.C_DIM)
		# price and material
		var x := 50.0
		var gi := UITheme.icon("gold")
		if gi:
			c.draw_texture_rect(gi, Rect2(x, 3, 9, 9), false)
		c.draw_string(fb, Vector2(x + 12, 11), F.fmt_num(cost) + " " + DataDB.t("gold"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			UITheme.C_GOLD if GameState.gold >= cost else UITheme.C_RED)
		if mat != "":
			var mi := UITheme.icon(MAT_ICON.get(mat, "gem"))
			if mi:
				c.draw_texture_rect(mi, Rect2(x, 15, 9, 9), false)
			c.draw_string(fb, Vector2(x + 12, 23), "%s  %d / %d" % [ItemUtil.material_name(mat), have_mat, mat_n], HORIZONTAL_ALIGNMENT_LEFT, w - x - 14, 8,
				UITheme.C_TEXT if have_mat >= mat_n else UITheme.C_RED)
		# pity pips
		var py := 34.0 if mat != "" else 22.0
		c.draw_string(fb, Vector2(x, py + 4), DataDB.t("smith_pity_short"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM)
		var px := x + fb.get_string_size(DataDB.t("smith_pity_short"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 6.0
		for i in pity:
			var on := i < fails
			UISkin.diamond(ci, Vector2(px + i * 7.0, py + 1.5), 2.6, Color("#FFE08A") if on else Color("#4A3A30"), Color("#B07420") if on else Color("#241A14"))
		# last rolls as small coloured dots
		var lx := w - 4.0
		for e in log:
			var ok: bool = e.get("ok", false)
			lx -= 7.0
			c.draw_circle(Vector2(lx, py + 1.5), 2.4, Color("#6FE08A") if ok else Color("#FF6A5A"))
		if info["fail_down"]:
			c.draw_string(fb, Vector2(x, 49), DataDB.t("smith_fail_down"), HORIZONTAL_ALIGNMENT_LEFT, w - x - 4, 7, UITheme.C_RED))
	return c


## The big round + : enhance once. Grey when the price or the material is missing.
func _plus_button(info: Dictionary, w: float) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(w, 46)
	var ok := GameState.gold >= int(info["cost"]) and (str(info["mat"]) == "" or GameState.has_material(str(info["mat"]), int(info["mat_n"])))
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(30, 30)
	b.position = Vector2((w - 30) / 2.0, 2)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = DataDB.t("smith_enhance") + " (+%d)" % int(info["next"])
	b.disabled = not ok
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.button_down.connect(b.queue_redraw)
	b.button_up.connect(b.queue_redraw)
	b.pressed.connect(_do_enhance)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var c := Vector2(15, 15 + (1.0 if b.button_pressed else 0.0))
		var hov := b.is_hovered() and ok
		if ok:
			var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0)
			b.draw_circle(c, 15.0, Color(1.0, 0.85, 0.4, 0.12 + 0.12 * p))
		UISkin.circle(ci, c + Vector2(0, 1.2), 13.4, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
		UISkin.circle(ci, c, 13.2, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, c, 12.4, (UISkin.BRONZE_HI if hov else UISkin.BRONZE) if ok else Color("#5A5650"), UISkin.BRONZE_LO if ok else Color("#2A2622"))
		UISkin.circle(ci, c, 9.4, Color("#2E8A3E") if ok else Color("#2A2826"), Color("#14481E") if ok else Color("#161412"))
		UISkin.ring(ci, c, 9.4, Color(0, 0, 0, 0.6), 1.0)
		var pc := Color("#E8FFE0") if ok else Color("#6A6660")
		b.draw_rect(Rect2(c.x - 5.5, c.y - 1.4, 11, 2.8), pc)
		b.draw_rect(Rect2(c.x - 1.4, c.y - 5.5, 2.8, 11), pc)
		b.draw_circle(c + Vector2(-3, -4), 2.2, Color(1, 1, 1, 0.2)))
	if ok:
		var tm := Timer.new()
		tm.wait_time = 0.05
		tm.autostart = true
		tm.timeout.connect(b.queue_redraw)
		b.add_child(tm)
	row.add_child(b)
	var gold_ok := GameState.gold >= int(info["cost"])
	var txt := DataDB.t("smith_enhance") + "  +%d" % int(info["next"]) if ok else (DataDB.t("not_enough_gold") if not gold_ok else DataDB.t("not_enough_mats"))
	var lab := UITheme.label(txt, Color("#FFE7B0") if ok else Color("#FF8A7A"), 8, UITheme.font_title if ok else UITheme.font_body)
	lab.position = Vector2(0, 34)
	lab.size = Vector2(w, 11)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(lab)
	return row


func _do_enhance() -> void:
	var it := _item_for_target()
	var r := Blacksmith.enhance(it)
	if r == "success":
		_fx = "ok"
		_fx_lv = int(it.get("enhance", 0))
		_fx_t = 0.0
		AudioManager.play("smith_success")
		BattleSim.refresh_hero_stats()
	elif r == "fail":
		_fx = "fail"
		_fx_t = 0.0
		AudioManager.play("smith_fail")
	else:
		EventBus.notify.emit(DataDB.t(r), UITheme.C_RED)
	refresh()


const MAT_ICON2 := {"iron_scrap": "hammer", "shiny_essence": "sparkle", "epic_essence": "gem", "legendary_essence": "flame",
	"star_dust": "star", "mythic_essence": "gem", "soul_shard": "gem", "tavern_seal": "crown", "guild_badge": "flag"}


## Salvage: one row per rarity (what is in the bag and what it melts into), then the material pouch.
func _build_salvage() -> void:
	var w := content.size.x
	_body.add_child(UITheme.para(DataDB.t("smith_salvage_hint"), w, UITheme.C_DIM))
	for r in ["common", "magic", "rare", "epic"]:
		var n: int = GameState.bag.filter(func(it): return it.get("rarity", "") == r and not it.get("locked", false)).size()
		var yields: Dictionary = DataDB.items.get("salvage", {}).get(r, {})
		var row := Control.new()
		row.custom_minimum_size = Vector2(w, 22)
		var col := ItemUtil.rarity_color(r)
		var rr: String = r
		row.draw.connect(func():
			var ci := row.get_canvas_item()
			var rect := Rect2(Vector2(0, 1), row.size - Vector2(0, 2))
			UISkin.fill(ci, rect, 2, Color(col, 0.12), Color(0, 0, 0, 0.25))
			UISkin.stroke(ci, rect, 2, Color(col, 0.45), 0.8)
			UISkin.diamond(ci, Vector2(8, 11), 4.0, col.lightened(0.25), col.darkened(0.4))
			var fb := UITheme.font_body
			row.draw_string(fb, Vector2(16, 14), "%s  ×%d" % [ItemUtil.rarity_name(rr), n], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col if n > 0 else UITheme.C_DIM)
			var x := 92.0
			row.draw_string(fb, Vector2(x, 14), "→", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_DIM)
			x += 10.0
			for m in yields:
				var ic := UITheme.icon(MAT_ICON2.get(m, "gem"))
				if ic:
					row.draw_texture_rect(ic, Rect2(x, 6, 9, 9), false, Color(str(DataDB.items["materials"][m].get("color", "#FFFFFF"))))
				var t := "×%d" % (int(yields[m]) * maxi(n, 1))
				row.draw_string(fb, Vector2(x + 11, 14), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_TEXT if n > 0 else UITheme.C_DIM)
				x += 34.0)
		var b := Fancy.small_button(DataDB.t("ctx_salvage"), "red", func():
			var k := Blacksmith.salvage_rarities([rr])
			EventBus.notify.emit(DataDB.t("salvaged_n", {"n": k}), UITheme.C_TEXT)
			AudioManager.play("smith_fail", 0.05, 0.5)
			refresh(), Vector2(50, 14))
		b.disabled = n == 0
		row.add_child(b)
		b.position = Vector2(w - 53, 4)
		_body.add_child(row)
	_body.add_child(Fancy.section(DataDB.t("materials"), w))
	var g := W.grid(2, 2)
	_body.add_child(g)
	for m in DataDB.items.get("materials", {}):
		var n2 := int(GameState.materials.get(m, 0))
		var mc := Color(str(DataDB.items["materials"][m].get("color", "#FFFFFF")))
		var chip := Control.new()
		chip.custom_minimum_size = Vector2((w - 2) / 2.0, 15)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.tooltip_text = ItemUtil.material_name(m)
		var mm: String = m
		chip.draw.connect(func():
			var ci := chip.get_canvas_item()
			var r2 := Rect2(Vector2.ZERO, chip.size)
			UISkin.well(ci, r2)
			var ic := UITheme.icon(MAT_ICON2.get(mm, "gem"))
			if ic:
				chip.draw_texture_rect(ic, Rect2(3, 3, 10, 10), false, mc if n2 > 0 else Color(mc, 0.35))
			var fb := UITheme.font_body
			var nm := ItemUtil.material_name(mm)
			chip.draw_string(fb, Vector2(15, 11), nm, HORIZONTAL_ALIGNMENT_LEFT, r2.size.x - 36, 7, UITheme.C_TEXT if n2 > 0 else UITheme.C_DIM)
			var t := F.fmt_num(n2)
			var tw := fb.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			chip.draw_string(fb, Vector2(r2.size.x - tw - 3, 11), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, mc if n2 > 0 else UITheme.C_DIM))
		g.add_child(chip)


## Craft: pick a slot and a tier, see the price and the odds, strike the anvil.
func _build_craft() -> void:
	var w := content.size.x
	_hero_row("smith_for_hero")
	var sb := Control.new()
	sb.custom_minimum_size = Vector2(w, 24)
	_body.add_child(sb)
	var bw := 24.0
	var gap := (w - bw * CRAFT_SLOTS.size()) / (CRAFT_SLOTS.size() - 1)
	for i in CRAFT_SLOTS.size():
		var sid: String = CRAFT_SLOTS[i][0]
		var icn: String = CRAFT_SLOTS[i][1]
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(bw, bw)
		b.position = Vector2(i * (bw + gap), 0)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = DataDB.t("tab_all") if sid == "any" else DataDB.tx(DataDB.items["slot_names"].get(sid if sid != "ring" else "ring1", {}))
		b.pressed.connect(func():
			craft_slot = sid
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh())
		b.mouse_entered.connect(b.queue_redraw)
		b.mouse_exited.connect(b.queue_redraw)
		b.draw.connect(func():
			var ci := b.get_canvas_item()
			var on := craft_slot == sid
			UISkin.slot(ci, Rect2(Vector2.ZERO, b.size), Color.WHITE, false, b.is_hovered())
			var ic := UITheme.icon(icn)
			if ic:
				b.draw_texture_rect(ic, Rect2(6, 6, 12, 12), false, Color("#FFE08A") if on else Color(0.85, 0.8, 0.7, 0.7))
			if on:
				UISkin.stroke(ci, Rect2(Vector2.ZERO, b.size).grow(-0.5), 2, Color("#FFE45C"), 1.6))
		sb.add_child(b)
	var tl: Array = DataDB.bal("items.tier_levels", [1])
	var max_tier := 0
	for i in tl.size():
		if GameState.max_hero_level() + 5 >= int(tl[i]):
			max_tier = i
	craft_tier = min(craft_tier, max_tier)
	var tier_row := Control.new()
	tier_row.custom_minimum_size = Vector2(w, 18)
	_body.add_child(tier_row)
	var lb := Fancy.small_button("‹", "brown", func():
		craft_tier = max(0, craft_tier - 1)
		refresh(), Vector2(18, 16))
	lb.disabled = craft_tier <= 0
	tier_row.add_child(lb)
	lb.position = Vector2(w / 2.0 - 60, 1)
	var rb := Fancy.small_button("›", "brown", func():
		craft_tier = min(max_tier, craft_tier + 1)
		refresh(), Vector2(18, 16))
	rb.disabled = craft_tier >= max_tier
	tier_row.add_child(rb)
	rb.position = Vector2(w / 2.0 + 42, 1)
	var tt := DataDB.t("smith_tier", {"t": craft_tier + 1, "lv": int(tl[craft_tier])})
	tier_row.draw.connect(func():
		var ci := tier_row.get_canvas_item()
		var pr := Rect2(w / 2.0 - 40, 1, 80, 16)
		UISkin.fill(ci, pr, 3, Color("#3A2616"), Color("#1A0F08"))
		UISkin.stroke(ci, pr, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, pr.grow(-1.0), 2, Color(UISkin.BRONZE, 0.6), 0.7)
		var f := UITheme.font_title
		var tw := f.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		tier_row.draw_string(f, Vector2(w / 2.0 - tw / 2.0, 12.5), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFE7B0")))
	var c := Blacksmith.craft_cost(craft_tier)
	var info := Control.new()
	info.custom_minimum_size = Vector2(w, 46)
	info.draw.connect(func():
		var ci := info.get_canvas_item()
		UISkin.well(ci, Rect2(Vector2.ZERO, info.size))
		var fb := UITheme.font_body
		# odds of the result
		var x := 6.0
		info.draw_string(fb, Vector2(x, 12), DataDB.t("smith_craft_odds"), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM)
		UISkin.diamond(ci, Vector2(x + 4, 22), 3.2, ItemUtil.rarity_color("rare").lightened(0.2), ItemUtil.rarity_color("rare").darkened(0.4))
		info.draw_string(fb, Vector2(x + 10, 25), ItemUtil.rarity_name("rare") + " %85", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ItemUtil.rarity_color("rare"))
		UISkin.diamond(ci, Vector2(x + 4, 34), 3.2, ItemUtil.rarity_color("epic").lightened(0.2), ItemUtil.rarity_color("epic").darkened(0.4))
		info.draw_string(fb, Vector2(x + 10, 37), ItemUtil.rarity_name("epic") + " %15", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ItemUtil.rarity_color("epic"))
		# price
		x = w * 0.5
		var lines := [["gold", F.fmt_num(int(c["gold"])), GameState.gold >= int(c["gold"]), UITheme.C_GOLD]]
		for m in ["iron_scrap", "shiny_essence"]:
			if int(c[m]) > 0:
				var have := int(GameState.materials.get(m, 0))
				lines.append([MAT_ICON2.get(m, "gem"), "%d / %d" % [have, int(c[m])], have >= int(c[m]), Color(str(DataDB.items["materials"][m].get("color", "#FFFFFF")))])
		var y := 6.0
		for ln in lines:
			var ic := UITheme.icon(str(ln[0]))
			if ic:
				info.draw_texture_rect(ic, Rect2(x, y, 9, 9), false, ln[3])
			info.draw_string(fb, Vector2(x + 12, y + 8), str(ln[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_TEXT if ln[2] else UITheme.C_RED)
			y += 12.0)
	_body.add_child(info)
	var ok := GameState.gold >= int(c["gold"]) and GameState.has_material("iron_scrap", int(c["iron_scrap"])) and GameState.has_material("shiny_essence", int(c["shiny_essence"]))
	var reason := DataDB.t("not_enough_gold") if GameState.gold < int(c["gold"]) else DataDB.t("not_enough_mats")
	_body.add_child(_round_action("hammer", DataDB.t("smith_craft"), ok, reason, func():
		var cls: String = GameState.heroes[W.current_hero()].cls() if W.current_hero() != "" else ""
		var it := Blacksmith.craft(cls, craft_slot, craft_tier)
		if it.is_empty():
			EventBus.notify.emit(DataDB.t("not_enough_mats"), UITheme.C_RED)
		else:
			EventBus.notify.emit(DataDB.t("smith_crafted", {"name": ItemUtil.display_name(it)}), ItemUtil.rarity_color(it["rarity"]))
			AudioManager.play("smith_success")
		refresh(), w))


## Last rolls of a kind with the chance they had: "✓ 75%  ✗ 40%  ✓ 52%".
func _roll_log(kind: String) -> Label:
	var parts: Array = []
	for e in GameState.blacksmith.get("log", []):
		if str(e.get("k", "")) == kind and parts.size() < 6:
			parts.append(("✓ " if e.get("ok", false) else "✗ ") + F.pct(round(float(e.get("c", 0)) * 100.0)))
	var l := UITheme.label(DataDB.t("smith_log") + " " + ("  ".join(parts) if parts.size() > 0 else "—"), UITheme.C_DIM, 7, UITheme.font_body)
	l.clip_text = true
	l.custom_minimum_size = Vector2(content.size.x - 4, 9)
	return l
