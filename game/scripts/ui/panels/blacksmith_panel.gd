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


func _build_combine() -> void:
	var hint := UITheme.label(DataDB.t("smith_combine_hint"), UITheme.C_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(content.size.x, 0)
	_body.add_child(hint)
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(content.size.x, 64)
	_body.add_child(center)
	var g := W.grid(3, 2)
	center.add_child(g)
	for i in 9:
		var s := ItemSlot.new()
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
	var r := ""
	if picks.size() > 0:
		r = GameState.bag[GameState.find_bag_index(picks[0])].get("rarity", "common")
	var pity := int(GameState.blacksmith.get("pity", 0))
	var maxp := int(DataDB.bal("combine.pity", 10))
	var chance := Blacksmith.combine_chance(r if r != "" else _auto_rarity)
	_body.add_child(W.stat_row("%d/9" % picks.size(), DataDB.t("smith_success", {"p": int(round(chance * 100))}), UITheme.C_GREEN, UITheme.C_TEXT, int(content.size.x)))
	_body.add_child(UITheme.label(DataDB.t("smith_pity", {"n": pity, "m": maxp}), UITheme.C_DIM))
	_body.add_child(_roll_log("combine"))
	var row := W.hbox(2)
	_body.add_child(row)
	var rar_btn := UITheme.button(ItemUtil.rarity_name(_auto_rarity), "brown", Callable(), Vector2(40, 12))
	rar_btn.add_theme_color_override("font_color", ItemUtil.rarity_color(_auto_rarity))
	rar_btn.pressed.connect(func():
		var order := ["common", "magic", "rare", "epic", "legendary"]
		_auto_rarity = order[(order.find(_auto_rarity) + 1) % order.size()]
		refresh())
	row.add_child(rar_btn)
	row.add_child(UITheme.button(DataDB.t("smith_autofill"), "orange", _autofill))
	row.add_child(UITheme.button(DataDB.t("btn_clear"), "brown", func():
		picks.clear()
		refresh()))
	var cb := UITheme.button(DataDB.t("smith_combine"), "gold", _do_combine, Vector2(content.size.x, 13))
	var prob := Blacksmith.combine_problem(picks)
	cb.disabled = prob != ""
	if prob != "" and picks.size() == 9:
		cb.tooltip_text = DataDB.t(prob)
	_body.add_child(cb)


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


func _process(delta: float) -> void:
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
			c.draw_circle(Vector2(46, r.size.y + 6), 46.0 - k * 7.0, Color(1.0, 0.45, 0.15, 0.035))
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


func _build_salvage() -> void:
	var hint := UITheme.label(DataDB.t("smith_salvage_hint"), UITheme.C_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(content.size.x, 0)
	_body.add_child(hint)
	for r in ["common", "magic", "rare", "epic"]:
		var n: int = GameState.bag.filter(func(it): return it.get("rarity", "") == r and not it.get("locked", false)).size()
		var row := W.hbox(2)
		var l := UITheme.label("%s (%d)" % [ItemUtil.rarity_name(r), n], ItemUtil.rarity_color(r))
		l.custom_minimum_size = Vector2(80, 0)
		row.add_child(l)
		var rr: String = r
		var b := UITheme.button(DataDB.t("ctx_salvage"), "brown", func():
			var k := Blacksmith.salvage_rarities([rr])
			EventBus.notify.emit(DataDB.t("salvaged_n", {"n": k}), UITheme.C_TEXT)
			refresh())
		b.disabled = n == 0
		row.add_child(b)
		_body.add_child(row)
	_body.add_child(UITheme.hsep(int(content.size.x)))
	_body.add_child(UITheme.label(DataDB.t("materials"), UITheme.C_GOLD))
	var g := W.grid(2, 1)
	_body.add_child(g)
	for m in DataDB.items.get("materials", {}):
		var n2 := int(GameState.materials.get(m, 0))
		var l2 := UITheme.label("%s: %d" % [ItemUtil.material_name(m), n2], Color(str(DataDB.items["materials"][m].get("color", "#FFFFFF"))) if n2 > 0 else UITheme.C_DIM)
		l2.custom_minimum_size = Vector2(76, 0)
		l2.clip_text = true
		g.add_child(l2)


func _build_craft() -> void:
	var hint := UITheme.label(DataDB.t("smith_craft_hint"), UITheme.C_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(content.size.x, 0)
	_body.add_child(hint)
	var slots := ["any", "weapon", "helm", "chest", "gloves", "boots", "ring", "amulet"]
	var g := W.grid(4, 1)
	_body.add_child(g)
	for s in slots:
		var nm := DataDB.t("tab_all") if s == "any" else DataDB.tx(DataDB.items["slot_names"].get(s if s != "ring" else "ring1", {}))
		var ss: String = s
		var b := UITheme.button(nm, "orange" if s == craft_slot else "brown", func():
			craft_slot = ss
			refresh(), Vector2(37, 12))
		g.add_child(b)
	var tl: Array = DataDB.bal("items.tier_levels", [1])
	var max_tier := 0
	for i in tl.size():
		if GameState.max_hero_level() + 5 >= int(tl[i]):
			max_tier = i
	craft_tier = min(craft_tier, max_tier)
	var th := W.hbox(2)
	_body.add_child(th)
	th.add_child(UITheme.button("<", "brown", func():
		craft_tier = max(0, craft_tier - 1)
		refresh(), Vector2(12, 12)))
	th.add_child(UITheme.label("T%d (Lv %d)" % [craft_tier + 1, int(tl[craft_tier])], UITheme.C_TEXT))
	th.add_child(UITheme.button(">", "brown", func():
		craft_tier = min(max_tier, craft_tier + 1)
		refresh(), Vector2(12, 12)))
	var c := Blacksmith.craft_cost(craft_tier)
	_body.add_child(W.stat_row(DataDB.t("gold"), F.fmt_num(int(c["gold"])), UITheme.C_GOLD if GameState.gold >= int(c["gold"]) else UITheme.C_RED, UITheme.C_TEXT, int(content.size.x)))
	for m in ["iron_scrap", "shiny_essence"]:
		if int(c[m]) > 0:
			var have := int(GameState.materials.get(m, 0))
			_body.add_child(W.stat_row(ItemUtil.material_name(m), "%d / %d" % [int(c[m]), have], UITheme.C_TEXT if have >= int(c[m]) else UITheme.C_RED, UITheme.C_TEXT, int(content.size.x)))
	var b2 := UITheme.button(DataDB.t("smith_craft"), "gold", func():
		var cls: String = GameState.heroes[W.current_hero()].cls() if W.current_hero() != "" else ""
		var it := Blacksmith.craft(cls, craft_slot, craft_tier)
		if it.is_empty():
			EventBus.notify.emit(DataDB.t("not_enough_mats"), UITheme.C_RED)
		else:
			EventBus.notify.emit(DataDB.t("smith_crafted", {"name": ItemUtil.display_name(it)}), ItemUtil.rarity_color(it["rarity"]))
		refresh(), Vector2(content.size.x, 13))
	_body.add_child(b2)


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
