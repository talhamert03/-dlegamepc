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
	_tabs = W.tabs([DataDB.t("smith_combine"), DataDB.t("smith_enhance"), DataDB.t("smith_salvage"), DataDB.t("smith_craft")], tab, _on_tab)
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


func _build_enhance() -> void:
	var it := _item_for_target()
	var hint := UITheme.label(DataDB.t("smith_enhance_hint"), UITheme.C_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(content.size.x, 0)
	_body.add_child(hint)
	# equipped items of current hero as quick picks
	var hid := W.current_hero()
	var h: HeroState = GameState.heroes.get(hid)
	if h:
		var g := W.grid(6, 1)
		_body.add_child(g)
		for slot in ["weapon", "offhand", "helm", "chest", "gloves", "boots", "belt", "cape", "amulet", "ring1", "ring2", "charm"]:
			var s := ItemSlot.new()
			s.source = "equip"
			s.set_item(h.equipment.get(slot, {}))
			s.selected = enh_target.get("src", "") == "equip" and enh_target.get("slot", "") == slot and enh_target.get("hid", "") == hid
			var sl: String = slot
			s.left_clicked.connect(func(_x):
				enh_target = {"src": "equip", "hid": hid, "slot": sl}
				refresh())
			g.add_child(s)
	if it.is_empty():
		return
	var name_l := UITheme.label(ItemUtil.display_name(it), ItemUtil.rarity_color(it.get("rarity", "common")))
	_body.add_child(name_l)
	var info := Blacksmith.enhance_info(it)
	if info.is_empty():
		_body.add_child(UITheme.label(DataDB.t("smith_max"), UITheme.C_GOLD))
		return
	_body.add_child(W.stat_row(DataDB.t("smith_next"), "+%d" % int(info["next"]), UITheme.C_GREEN, UITheme.C_TEXT, int(content.size.x)))
	_body.add_child(W.stat_row(DataDB.t("smith_chance"), "%d%%" % int(round(float(info["chance"]) * 100)), UITheme.C_TEXT, UITheme.C_TEXT, int(content.size.x)))
	_body.add_child(W.stat_row(DataDB.t("cost"), F.fmt_num(int(info["cost"])) + " " + DataDB.t("gold"), UITheme.C_GOLD, UITheme.C_TEXT, int(content.size.x)))
	if info["mat"] != "":
		_body.add_child(W.stat_row(ItemUtil.material_name(info["mat"]), "%d / %d" % [int(info["mat_n"]), int(GameState.materials.get(info["mat"], 0))],
			UITheme.C_TEXT, UITheme.C_TEXT, int(content.size.x)))
	if info["fail_down"]:
		_body.add_child(UITheme.label(DataDB.t("smith_fail_down"), UITheme.C_RED))
	var b := UITheme.button(DataDB.t("smith_enhance"), "gold", func():
		var r := Blacksmith.enhance(_item_for_target())
		if r == "success":
			EventBus.notify.emit(DataDB.t("smith_enh_ok"), UITheme.C_GREEN)
			AudioManager.play("smith_success")
			BattleSim.refresh_hero_stats()
		elif r == "fail":
			EventBus.notify.emit(DataDB.t("smith_enh_fail"), UITheme.C_RED)
			AudioManager.play("smith_fail")
		else:
			EventBus.notify.emit(DataDB.t(r), UITheme.C_RED)
		refresh(), Vector2(content.size.x, 13))
	_body.add_child(b)


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
