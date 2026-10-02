extends PanelWindow
## Stats panel: primary stat allocation + derived stats in 4 tabs (All/Combat/Defense/Other).

var tab := 0
var _list: VBoxContainer
var _tabs: HBoxContainer
var _prim: VBoxContainer
var _pts: Label


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("tab_all"), DataDB.t("tab_combat"), DataDB.t("tab_defense"), DataDB.t("tab_other")], tab, _on_tab)
	v.add_child(_tabs)
	_prim = W.vbox(0)
	v.add_child(_prim)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 82))
	v.add_child(sc)
	_list = W.vbox(0)
	_list.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_list)
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.equipment_changed.connect(func(_h): refresh())
	EventBus.party_changed.connect(refresh)
	refresh()


func _on_tab(i: int) -> void:
	tab = i
	W.set_tab_active(_tabs, i)
	refresh()


func refresh() -> void:
	if _list == null:
		return
	var hid := W.current_hero()
	for ch in _prim.get_children():
		ch.queue_free()
	for ch in _list.get_children():
		ch.queue_free()
	if hid == "":
		return
	var h: HeroState = GameState.heroes[hid]
	GameState.invalidate_stats()
	var s := GameState.hero_stats(hid)
	# primary stats with + buttons
	var top := W.hbox(2)
	_pts = UITheme.label(DataDB.t("stat_points_left", {"n": h.stat_points}), UITheme.C_GOLD if h.stat_points > 0 else UITheme.C_DIM)
	top.add_child(W.expand(_pts))
	var auto_b := UITheme.button(DataDB.t("btn_auto"), "blue", func():
		h.auto_allocate()
		_changed(hid), Vector2(26, 11))
	auto_b.disabled = h.stat_points <= 0
	top.add_child(auto_b)
	var reset_cost := F.stat_reset_cost(h.level, h.resets)
	var rb := UITheme.button(DataDB.t("btn_reset"), "red", func():
		if GameState.spend_gold(reset_cost):
			h.reset_stats()
			_changed(hid), Vector2(26, 11))
	rb.tooltip_text = DataDB.t("reset_cost", {"g": F.fmt_num(reset_cost)})
	top.add_child(rb)
	_prim.add_child(top)
	var g := W.grid(2, 1)
	_prim.add_child(g)
	var main: String = h.class_def().get("primary", "str")
	for p in HeroState.PRIMARY:
		var row := W.hbox(1)
		row.custom_minimum_size = Vector2(76, 10)
		var lab := UITheme.label(StatNames.label(p), UITheme.C_ORANGE if p == main else Color("#E8C98A"))
		lab.custom_minimum_size = Vector2(40, 0)
		lab.clip_text = true
		row.add_child(lab)
		var val := UITheme.label(str(int(s["primary"][p])), UITheme.C_TEXT)
		val.custom_minimum_size = Vector2(20, 0)
		row.add_child(val)
		var plus := UITheme.button("+", "green", Callable(), Vector2(10, 10))
		plus.disabled = h.stat_points <= 0
		var pp: String = p
		plus.pressed.connect(func():
			var n := 1
			if Input.is_key_pressed(KEY_SHIFT):
				n = min(10, h.stat_points)
			if h.stat_points >= n:
				h.alloc[pp] = int(h.alloc[pp]) + n
				h.stat_points -= n
				_changed(hid))
		row.add_child(plus)
		g.add_child(row)
	_prim.add_child(UITheme.hsep(int(content.size.x)))
	# derived
	var rows: Array = []
	var combat := [
		["level", str(h.level), ""], ["exp", "%s / %s" % [F.fmt_num(h.xp), F.fmt_num(F.xp_required(h.level))], ""],
		["power", F.fmt_num(s["power"]), ""], ["attack", F.fmt_num(s["attack"]), ""], ["spell", F.fmt_num(s["spell"]), ""],
		["added_dmg", _p(s, "added_dmg"), ""], ["elem_dmg", _p(s, "elem_dmg"), ""], ["crit_chance", "%.2f%%" % float(s["crit_chance"]), ""],
		["crit_dmg", "%d%%" % int(s["crit_dmg"]), ""], ["penetrate", _p(s, "penetrate"), ""],
		["attack_speed", "%.1f%% / 225%%" % float(s["attack_speed_total"]), ""], ["aps", "%.2f" % float(s["aps"]), ""],
		["cast_speed", _p(s, "cast_speed"), ""], ["skill_dmg", _p(s, "skill_dmg"), ""], ["phys_dmg", _p(s, "phys_dmg"), ""],
		["fire_dmg", _p(s, "fire_dmg"), ""], ["cold_dmg", _p(s, "cold_dmg"), ""], ["lightning_dmg", _p(s, "lightning_dmg"), ""],
		["chaos_dmg", _p(s, "chaos_dmg"), ""], ["holy_dmg", _p(s, "holy_dmg"), ""], ["elite_dmg", _p(s, "elite_dmg"), ""],
		["boss_dmg", _p(s, "boss_dmg"), ""]]
	var d: float = float(s["def"])
	var drp: float = min(75.0, d / (d + 50.0 + 6.0 * h.level) * 100.0)
	var defense := [
		["max_hp", F.fmt_num(s["max_hp"]), ""], ["def", "%s (%d%%)" % [F.fmt_num(d), int(round(drp))], ""], ["dr", _p(s, "dr"), ""],
		["crit_res", _p(s, "crit_res"), ""], ["evasion", _p(s, "evasion"), ""], ["block", _p(s, "block"), ""],
		["fire_res", _p(s, "fire_res"), ""], ["cold_res", _p(s, "cold_res"), ""], ["lightning_res", _p(s, "lightning_res"), ""],
		["chaos_res", _p(s, "chaos_res"), ""], ["hp_regen", F.fmt_num(s["hp_regen"]) + "/s", ""], ["lifesteal", _p(s, "lifesteal"), ""],
		["thorns", _p(s, "thorns"), ""]]
	var other := [
		["item_find", _p(s, "item_find"), ""], ["gold_find", _p(s, "gold_find"), ""], ["xp_bonus", _p(s, "xp_bonus"), ""],
		["cdr", _p(s, "cdr"), ""], ["heal_bonus", _p(s, "heal_bonus"), ""], ["buff_duration", _p(s, "buff_duration"), ""],
		["ult_charge", _p(s, "ult_charge"), ""], ["summon_dmg", _p(s, "summon_dmg"), ""], ["threat", F.fmt_num(s["threat"]), ""],
		["dps", F.fmt_num(StatCalc.dps_estimate(s)), ""], ["ehp", F.fmt_num(StatCalc.ehp_estimate(s, h.level)), ""]]
	match tab:
		0:
			rows = combat.slice(0, 12) + defense.slice(0, 3) + other.slice(0, 3)
		1:
			rows = combat
		2:
			rows = defense
		3:
			rows = other
	for r in rows:
		var key: String = r[0]
		var lbl := StatNames.label(key) if key not in ["exp", "dps", "ehp"] else DataDB.t("stat_" + key)
		_list.add_child(W.stat_row(lbl, str(r[1]), UITheme.C_TEXT, Color("#E8C98A"), int(content.size.x - 8)))


func _p(s: Dictionary, k: String) -> String:
	var v: float = float(s.get(k, 0.0))
	if abs(v - round(v)) < 0.05:
		return "%d%%" % int(round(v))
	return "%.1f%%" % v


func _changed(hid: String) -> void:
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.hero_stats_changed.emit(hid)
	refresh()
	WindowManager.refresh_all()
