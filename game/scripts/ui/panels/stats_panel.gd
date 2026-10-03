extends PanelWindow
## Status: one hero's personal growth. Header: the hero's framed portrait, name, class and level, and the
## party as clickable portraits (the open one lit). Two tabs:
##  * Attributes - spend stat points on the five attributes (glyph, what each gives, per-point tooltip),
##    key numbers, and every stat below.
##  * Skills - the class's skills on a red level rail, rows unlocking at levels 1 / 10 / 20 / 30 (class
##    advancement) / 50 / 70 (path choice), as round medallions; pick one for its details, learn and equip.

const PARCH_H := 98.0
## [unlock level, kind]: base = starting skills + ultimate, lv = skills with that req_lv, adv / spec = advancement tiers
const ROWS := [[1, "base"], [10, "lv"], [20, "lv"], [30, "adv"], [50, "lv"], [70, "spec"]]
const ROW_H := 30.0
const ROW_GAP := 3.0
const RAIL_X := 12.0
const BOX_X := 36.0
const HEAD_H := 34.0
const PRIM_ICON := {"str": "sword", "dex": "boot", "int": "book", "vit": "heart", "luk": "star"}
const PRIM_COL := {"str": Color("#B8402A"), "dex": Color("#2F8A3E"), "int": Color("#2F5FB8"), "vit": Color("#B8305A"), "luk": Color("#B88A1E")}

var tab := 0
var _head: Control
var _tabs: HBoxContainer
var _page_attr: Control
var _page_skill: Control
var _parch: Control
var _list: VBoxContainer
var _pts_plaque: Control
var _chips: Control
var _tiers: Control
var _detail: Control
var _learn: Button
var _equip: Button
var _full := false
var _sel := ""
var _hover := ""
var _cells: Array = []       # [Rect2 (in _tiers), sid, locked]
var _t := 0.0
var _tier_top := 0.0


func build(c: Control) -> void:
	var w := c.size.x
	_head = Control.new()
	_head.size = Vector2(w, HEAD_H)
	_head.mouse_filter = Control.MOUSE_FILTER_PASS
	_head.draw.connect(_draw_head)
	_head.gui_input.connect(_head_input)
	c.add_child(_head)
	_tabs = W.tabs([DataDB.t("status_tab_attr"), DataDB.t("status_tab_skills")], tab, _on_tab, int((w - 4) / 2.0))
	_tabs.position = Vector2(0, HEAD_H + 2)
	c.add_child(_tabs)
	var py := HEAD_H + 18.0
	_page_attr = Control.new()
	_page_attr.position = Vector2(0, py)
	_page_attr.size = Vector2(w, c.size.y - py)
	c.add_child(_page_attr)
	_page_skill = Control.new()
	_page_skill.position = Vector2(0, py)
	_page_skill.size = Vector2(w, c.size.y - py)
	c.add_child(_page_skill)
	_build_attr(_page_attr)
	_build_skill_page(_page_skill)
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.equipment_changed.connect(func(_h): refresh())
	EventBus.party_changed.connect(refresh)
	EventBus.hero_stats_changed.connect(func(_h): _head.queue_redraw())
	_on_tab(tab)


func _on_tab(i: int) -> void:
	tab = i
	W.set_tab_active(_tabs, i)
	_page_attr.visible = i == 0
	_page_skill.visible = i == 1
	refresh()


## Attributes page: parchment with the attribute rows (and every stat below them), key numbers at the bottom.
func _build_attr(c: Control) -> void:
	var w := c.size.x
	var ph := c.size.y - 21.0
	_parch = Control.new()
	_parch.size = Vector2(w, ph)
	_parch.mouse_filter = Control.MOUSE_FILTER_PASS
	_parch.draw.connect(_draw_parch)
	c.add_child(_parch)
	var sc := W.scroll(Vector2(w - 14, ph - 12))
	sc.position = Vector2(7, 6)
	c.add_child(sc)
	_list = W.vbox(0)
	_list.custom_minimum_size = Vector2(w - 24, 0)
	sc.add_child(_list)
	_chips = Control.new()
	_chips.position = Vector2(0, ph + 3)
	_chips.size = Vector2(w, 17)
	_chips.mouse_filter = Control.MOUSE_FILTER_PASS
	_chips.draw.connect(_draw_chips)
	c.add_child(_chips)
	_full = true


## Skills page: points plaque, the level rail with its six rows, the selected skill's card.
func _build_skill_page(c: Control) -> void:
	var w := c.size.x
	_pts_plaque = Control.new()
	_pts_plaque.size = Vector2(w, 13)
	_pts_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pts_plaque.draw.connect(_draw_plaque)
	c.add_child(_pts_plaque)
	# free skill respec: try builds without fear
	var rs := UITheme.button(DataDB.t("btn_reset_free"), "red", func():
		var hh := _hero()
		if hh == null:
			return
		W.confirm(_host_ctl(), DataDB.t("skills_reset_confirm"), func():
			hh.reset_skills()
			GameState.invalidate_stats()
			BattleSim.refresh_hero_stats()
			_changed(hh), DataDB.t("btn_reset_free"), true), Vector2(40, 10))
	rs.position = Vector2(w * 0.42, 1.5)
	rs.size = Vector2(40, 10)
	rs.add_theme_font_size_override("font_size", 7)
	c.add_child(rs)
	# two skill bars (farming / boss), one click to swap
	for i in 2:
		var idx := i
		var sb := UITheme.button(["A", "B"][i], "brown", func():
			var hh := _hero()
			if hh:
				hh.use_skill_set(idx)
				BattleSim.refresh_hero_stats()
				_changed(hh)
				_paint_sets(), Vector2(12, 10))
		sb.position = Vector2(w * 0.42 + 43 + i * 13, 1.5)
		sb.size = Vector2(12, 10)
		sb.add_theme_font_size_override("font_size", 7)
		sb.tooltip_text = DataDB.t("skill_set_tip")
		sb.set_meta("set", i)
		c.add_child(sb)
		_set_btns.append(sb)
	_paint_sets()
	_tier_top = 16.0
	_tiers = Control.new()
	_tiers.position = Vector2(0, _tier_top)
	_tiers.size = Vector2(w, ROWS.size() * ROW_H + (ROWS.size() - 1) * ROW_GAP + 4)
	_tiers.mouse_filter = Control.MOUSE_FILTER_STOP
	_tiers.draw.connect(_draw_tiers)
	_tiers.gui_input.connect(_on_tiers_input)
	_tiers.mouse_exited.connect(func():
		_hover = ""
		WindowManager.hide_tooltip())
	c.add_child(_tiers)
	var dy := _tier_top + _tiers.size.y + 2.0
	_detail = Control.new()
	_detail.position = Vector2(0, dy)
	_detail.size = Vector2(w, c.size.y - dy)
	_detail.mouse_filter = Control.MOUSE_FILTER_PASS
	_detail.draw.connect(_draw_detail)
	c.add_child(_detail)
	_learn = UITheme.button(DataDB.t("btn_levelup"), "blue", _on_learn, Vector2(44, 12))
	_detail.add_child(_learn)
	_learn.size = Vector2(44, 12)
	_learn.position = Vector2(w - 94, 3)
	_equip = UITheme.button(DataDB.t("btn_equip"), "orange", _on_equip, Vector2(44, 12))
	_detail.add_child(_equip)
	_equip.size = Vector2(44, 12)
	_equip.position = Vector2(w - 47, 3)


# ------------------------------------------------------------------ header
func _party_ids() -> Array:
	var ids: Array = []
	for hid in GameState.party:
		if hid != "" and GameState.heroes.has(hid):
			ids.append(hid)
	var cur := W.current_hero()
	if cur != "" and not ids.has(cur):
		ids.append(cur)
	return ids


func _avatar_rect(i: int, n: int) -> Rect2:
	var sz := 20.0
	var x0 := _head.size.x - n * (sz + 2.0)
	return Rect2(x0 + i * (sz + 2.0), 7, sz, sz)


func _draw_head() -> void:
	var h := _hero()
	var ci := _head.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _head.size)
	UISkin.fill(ci, r, 4, Color("#2A2228"), Color("#151116"))
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 3, Color(UISkin.BRONZE, 0.45), 1.0)
	if h == null:
		return
	# the open hero's portrait in a gold frame
	var pr := Rect2(3, 3, 28, 28)
	var cls_col := Color(str(DataDB.factions.get(h.def().get("faction", ""), {}).get("color", "#5A4A3A")))
	UISkin.fill(ci, pr, 3, cls_col.darkened(0.2), cls_col.darkened(0.7))
	var tex := SpriteLib.hero_icon(h.id)
	if tex:
		_head.draw_texture_rect(tex, pr.grow(-1.0), false)
	UISkin.stroke(ci, pr, 3, Color(0, 0, 0, 0.95), 1.6)
	UISkin.stroke(ci, pr.grow(-0.5), 3, UITheme.C_GOLD, 1.0)
	var lvr := Rect2(pr.position.x + 1, pr.end.y - 8, 17, 8)
	UISkin.fill(ci, lvr, 2, Color(0.1, 0.06, 0.04, 0.9), Color(0.05, 0.03, 0.02, 0.9))
	_head.draw_string(UITheme.font_body, lvr.position + Vector2(2, 6.5), str(h.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_GOLD)
	var ids := _party_ids()
	var name_w := _avatar_rect(0, ids.size()).position.x - 38.0
	_head.draw_string(UITheme.font_title, Vector2(36, 15), h.display_name(), HORIZONTAL_ALIGNMENT_LEFT, name_w, 10, UITheme.C_TITLE)
	_head.draw_string(UITheme.font_body, Vector2(36, 26), h.class_title(), HORIZONTAL_ALIGNMENT_LEFT, name_w, 7, UITheme.C_DIM)
	# party switcher
	for i in ids.size():
		var ar := _avatar_rect(i, ids.size())
		var on: bool = ids[i] == h.id
		UISkin.fill(ci, ar, 3, Color("#3A3036"), Color("#1A1519"))
		var t2 := SpriteLib.hero_icon(str(ids[i]))
		if t2:
			_head.draw_texture_rect(t2, ar.grow(-1.0), false, Color.WHITE if on else Color(0.55, 0.55, 0.6))
		UISkin.stroke(ci, ar, 3, Color(0, 0, 0, 0.95), 1.4)
		UISkin.stroke(ci, ar.grow(-0.5), 3, UITheme.C_GOLD if on else Color(UISkin.BRONZE, 0.35), 1.0 if not on else 1.3)
		var h2: HeroState = GameState.heroes.get(str(ids[i]))
		if h2 and (h2.stat_points > 0 or h2.skill_points > 0):
			_head.draw_circle(ar.position + Vector2(ar.size.x - 2, 2), 2.6, Color(0, 0, 0, 0.9))
			_head.draw_circle(ar.position + Vector2(ar.size.x - 2, 2), 1.8, Color("#FF5A4A"))


func _head_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var ids := _party_ids()
		for i in ids.size():
			if _avatar_rect(i, ids.size()).has_point(ev.position):
				W.select_hero(str(ids[i]))
				AudioManager.play("ui_click", 0.05, 0.5)
				refresh()
				return
	elif ev is InputEventMouseMotion:
		var ids2 := _party_ids()
		var tip := ""
		for i in ids2.size():
			if _avatar_rect(i, ids2.size()).has_point(ev.position):
				var hh: HeroState = GameState.heroes[str(ids2[i])]
				tip = "%s · %s · Lv %d" % [hh.display_name(), hh.class_title(), hh.level]
		_head.tooltip_text = tip


func _process(delta: float) -> void:
	_t += delta
	if _tiers:
		_tiers.queue_redraw()


func _hero() -> HeroState:
	var hid := W.current_hero()
	return GameState.heroes.get(hid) if hid != "" else null


func _cycle_hero(d: int) -> void:
	var ids: Array = []
	for hid in GameState.party:
		if hid != "" and GameState.heroes.has(hid):
			ids.append(hid)
	for hid in GameState.heroes:
		if not ids.has(hid):
			ids.append(hid)
	if ids.is_empty():
		return
	var i := ids.find(W.current_hero())
	W.select_hero(ids[(i + d + ids.size()) % ids.size()])
	AudioManager.play("ui_click", 0.05, 0.5)
	refresh()


func refresh() -> void:
	if _list == null:
		return
	_paint_sets()
	var h := _hero()
	for ch in _list.get_children():
		ch.queue_free()
	if h == null:
		return
	if _sel == "" or DataDB.skill_def(_sel).get("class", "") != h.cls():
		_sel = h.equipped_skills[0] if h.equipped_skills[0] != "" else h.class_skills()[0]
	GameState.invalidate_stats()
	for hid in _party_ids():
		SpriteLib.hero_icon(str(hid))
	for sid in h.class_skills():
		SpriteLib.skill_icon(sid)
	var s := GameState.hero_stats(h.id)
	_build_stats(h, s)
	_layout_cells(h)
	_update_detail()
	_parch.queue_redraw()
	_pts_plaque.queue_redraw()
	_chips.queue_redraw()
	_head.queue_redraw()


# ------------------------------------------------------------------ parchment
func _draw_parch() -> void:
	var ci := _parch.get_canvas_item()
	var r := Rect2(Vector2(2, 2), _parch.size - Vector2(4, 4))
	UISkin.parchment(ci, r)
	UISkin.ornate(ci, r)


func _row(label: String, value: String, vcol: Color = UISkin.INK, plus_cb: Callable = Callable(), key := "") -> void:
	var r := W.hbox(2)
	if key != "":
		r.tooltip_text = label + "\n" + StatNames.describe(key) if StatNames.describe(key) != "" else ""
		r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.custom_minimum_size = Vector2(_list.custom_minimum_size.x, 10)
	var l := UITheme.label(label, Color("#4A2E16"), 8, UITheme.font_body)
	l.clip_text = true
	r.add_child(W.expand(l))
	var v := UITheme.label(value, vcol, 8, UITheme.font_body)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(v)
	if plus_cb.is_valid():
		var b := UITheme.button("+", "green", plus_cb, Vector2(10, 9))
		r.add_child(b)
	_list.add_child(r)


func _section(title: String) -> void:
	var l := UITheme.label(title, Color("#8A3A1A"), 8, UITheme.font_title)
	_list.add_child(l)


const PRIM_HINT := {"str": "prim_hint_str", "dex": "prim_hint_dex", "int": "prim_hint_int", "vit": "prim_hint_vit", "luk": "prim_hint_luk"}


func _build_stats(h: HeroState, s: Dictionary) -> void:
	# points + auto
	var top := W.hbox(2)
	top.custom_minimum_size = Vector2(_list.custom_minimum_size.x, 11)
	var pl := UITheme.label(DataDB.t("stat_points_left", {"n": h.stat_points}), Color("#8A3A1A") if h.stat_points > 0 else Color("#6A4A2A"), 8, UITheme.font_title)
	top.add_child(W.expand(pl))
	_list.add_child(top)
	var main: String = h.class_def().get("primary", "str")
	for p in HeroState.PRIMARY:
		_prim_row(h, s, p, p == main)
	if not _full:
		return
	_section(DataDB.t("status_summary"))
	_row(StatNames.label("level"), str(h.level))
	_row(DataDB.t("stat_exp"), "%s / %s" % [F.fmt_num(h.xp), F.fmt_num(F.xp_required(h.level))])
	_row(StatNames.label("aps"), "%.2f" % float(s["aps"]), UISkin.INK, Callable(), "aps")
	_row(StatNames.label("crit_chance"), "%.1f%%" % float(s["crit_chance"]), UISkin.INK, Callable(), "crit_chance")
	_row(StatNames.label("crit_dmg"), "%d%%" % int(s["crit_dmg"]), UISkin.INK, Callable(), "crit_dmg")
	_section(DataDB.t("tab_combat"))
	for k in ["spell", "added_dmg", "elem_dmg", "penetrate", "attack_speed", "cast_speed", "skill_dmg", "phys_dmg", "fire_dmg",
			"cold_dmg", "lightning_dmg", "chaos_dmg", "holy_dmg", "elite_dmg", "boss_dmg"]:
		_row(StatNames.label(k), F.fmt_num(s[k]) if StatNames.is_flat(k) else _p(s, k), UISkin.INK, Callable(), k)
	_section(DataDB.t("tab_defense"))
	for k in ["dr", "crit_res", "evasion", "block", "fire_res", "cold_res", "lightning_res", "chaos_res", "lifesteal", "thorns"]:
		_row(StatNames.label(k), _p(s, k), UISkin.INK, Callable(), k)
	_row(StatNames.label("hp_regen"), F.fmt_num(s["hp_regen"]) + "/s", UISkin.INK, Callable(), "hp_regen")
	_section(DataDB.t("tab_other"))
	for k in ["item_find", "gold_find", "xp_bonus", "cdr", "heal_bonus", "buff_duration", "ult_charge", "summon_dmg"]:
		_row(StatNames.label(k), _p(s, k), UISkin.INK, Callable(), k)
	_row(DataDB.t("stat_ehp"), F.fmt_num(StatCalc.ehp_estimate(s, h.level)))
	var rb := UITheme.button(DataDB.t("btn_reset") + "  " + F.fmt_num(F.stat_reset_cost(h.level, h.resets)), "red", func():
		if GameState.spend_gold(F.stat_reset_cost(h.level, h.resets)):
			h.reset_stats()
			_changed(h), Vector2(0, 11))
	_list.add_child(rb)


## Attribute row: glyph, name, what it gives, value and a + while points are left.
func _prim_row(h: HeroState, s: Dictionary, p: String, main: bool) -> void:
	var r := W.hbox(2)
	r.custom_minimum_size = Vector2(_list.custom_minimum_size.x, 12)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.tooltip_text = _prim_tip(h, p, main)
	var col: Color = PRIM_COL[p]
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(11, 11)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := UITheme.icon(PRIM_ICON[p])
	ic.draw.connect(func():
		ic.draw_circle(Vector2(5.5, 5.5), 5.5, col.darkened(0.25))
		ic.draw_arc(Vector2(5.5, 5.5), 5.3, 0, TAU, 16, Color(0.2, 0.12, 0.05, 0.9), 1.0, true)
		if tex:
			ic.draw_texture_rect(tex, Rect2(2, 2, 7, 7), false, Color(1, 0.96, 0.88)))
	r.add_child(ic)
	var l := UITheme.label(StatNames.label(p) + (" ★" if main else ""), Color("#4A2E16"), 8, UITheme.font_body)
	l.custom_minimum_size = Vector2(62, 0)
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_child(l)
	var hint := UITheme.label(DataDB.t(PRIM_HINT[p]), Color(0.36, 0.24, 0.12, 0.8), 7, UITheme.font_body)
	hint.clip_text = true
	hint.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_child(W.expand(hint))
	var v := UITheme.label(str(int(s["primary"][p])), UISkin.INK, 8, UITheme.font_title)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.custom_minimum_size = Vector2(20, 0)
	r.add_child(v)
	if h.stat_points > 0:
		var pp: String = p
		r.add_child(UITheme.button("+", "green", func():
			var n := 1
			if Input.is_key_pressed(KEY_SHIFT):
				n = min(10, h.stat_points)
			if h.stat_points >= n:
				h.alloc[pp] = int(h.alloc[pp]) + n
				h.stat_points -= n
				AudioManager.play("ui_click", 0.05, 0.5)
				_changed(h), Vector2(11, 10)))
	_list.add_child(r)


func _prim_tip(h: HeroState, p: String, main: bool) -> String:
	var row: Dictionary = DataDB.bal("primary", {}).get(p, {})
	var lines: Array = [StatNames.label(p) + " — " + DataDB.t("prim_per_point")]
	var eff: Dictionary = row.get("always", {}).duplicate()
	if main:
		for k in row.get("main", {}):
			eff[k] = float(eff.get(k, 0.0)) + float(row["main"][k])
	for k in eff:
		var v := float(eff[k])
		lines.append(("+%s %s" if StatNames.is_flat(k) else "+%s%% %s") % [("%.2f" % v).rstrip("0").rstrip("."), StatNames.label(k)])
	if not main and row.has("main"):
		lines.append(DataDB.t("prim_main_only"))
	return "\n".join(lines)


func _draw_chips() -> void:
	var h := _hero()
	if h == null:
		return
	var s := GameState.hero_stats(h.id)
	var d: float = float(s["def"])
	var items := [["dps", DataDB.t("stat_dps"), F.fmt_num(StatCalc.dps_estimate(s)), Color("#FF8A5A")],
		["sword", StatNames.label("attack"), F.fmt_num(s["attack"] if not bool(h.class_def().get("uses_spell", false)) else s["spell"]), Color("#F2C45A")],
		["heart", StatNames.label("max_hp"), F.fmt_num(s["max_hp"]), Color("#FF6A8A")],
		["shield", StatNames.label("def"), F.fmt_num(d), Color("#86B3FF")]]
	var cw := (_chips.size.x - 6.0) / 4.0
	var ci := _chips.get_canvas_item()
	var f := UITheme.font_body
	for i in items.size():
		var it: Array = items[i]
		var r := Rect2(i * (cw + 2.0), 0, cw, _chips.size.y)
		UISkin.fill(ci, r, 3, Color("#2A2228"), Color("#151116"))
		UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(it[3], 0.35), 1.0)
		var tex := UITheme.icon(str(it[0]))
		if tex:
			_chips.draw_texture_rect(tex, Rect2(r.position + Vector2(3, 4.5), Vector2(8, 8)), false, it[3])
		var val: String = it[2]
		var tw := f.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		_chips.draw_string(f, Vector2(r.end.x - tw - 4, 12), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.C_TEXT)


func _p(s: Dictionary, k: String) -> String:
	var v: float = float(s.get(k, 0.0))
	if abs(v - round(v)) < 0.05:
		return "%d%%" % int(round(v))
	return "%.1f%%" % v


func _draw_plaque() -> void:
	var ci := _pts_plaque.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _pts_plaque.size)
	var h := _hero()
	UISkin.fill(ci, r, 3, Color("#3A1416"), Color("#1E0A0C"))
	UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.55), 1.0)
	var f := UITheme.font_title
	var title := DataDB.t("status_abilities")
	UISkin.diamond(ci, Vector2(8, r.size.y / 2.0), 2.6)
	_pts_plaque.draw_string(f, Vector2(14, 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#F3D58F"))
	var n := h.skill_points if h else 0
	var s := DataDB.t("skill_points_left", {"n": n})
	var fb := UITheme.font_body
	var tw := fb.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	_pts_plaque.draw_string(fb, Vector2(r.size.x - tw - 6, 9.5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_GOLD if n > 0 else UITheme.C_DIM)


# ------------------------------------------------------------------ tiers
## Skills of one rail row. spec: "a" / "b" for the path row.
func _row_ids(h: HeroState, row: int, spec := "") -> Array:
	var lv: int = ROWS[row][0]
	var kind: String = ROWS[row][1]
	var ids: Array = []
	for sid in h.class_skills():
		var sd: Dictionary = DataDB.skill_def(sid)
		if sd.get("type") == "ult":
			continue
		var req := int(sd.get("req_lv", 1))
		var tier := int(sd.get("tier", 0))
		match kind:
			"base":
				if tier == 0 and req <= 1:
					ids.append(sid)
			"lv":
				if req == lv:
					ids.append(sid)
			"adv":
				if tier == 1 and req <= 1:
					ids.append(sid)
			"spec":
				if tier == 2 and sd.get("spec", "") == spec:
					ids.append(sid)
	if kind == "base" and h.ult_id() != "":
		ids.append(h.ult_id())
	return ids


## Whether a row's skills can be learned yet.
func _row_open(h: HeroState, row: int) -> bool:
	match str(ROWS[row][1]):
		"base":
			return true
		"lv":
			return h.level >= int(ROWS[row][0])
		"adv":
			return h.advancement >= 1
		"spec":
			return h.advancement >= 2
	return false


func _row_rect(i: int) -> Rect2:
	return Rect2(BOX_X, 2 + i * (ROW_H + ROW_GAP), _tiers.size.x - BOX_X - 1, ROW_H)


func _layout_cells(h: HeroState) -> void:
	_cells.clear()
	for i in ROWS.size():
		var rr := _row_rect(i)
		var groups: Array = []
		if str(ROWS[i][1]) != "spec":
			groups.append([_row_ids(h, i), rr.grow(-3.0), not _row_open(h, i)])
		else:
			var half := (rr.size.x - 8.0) / 2.0
			for k in 2:
				var sp: String = ["a", "b"][k]
				var lock := h.advancement < 2 or (h.spec != "" and h.spec != sp)
				groups.append([_row_ids(h, i, sp), Rect2(rr.position.x + 4 + k * half, rr.position.y + 3, half, rr.size.y - 6), lock])
		for g in groups:
			var ids: Array = g[0]
			var area: Rect2 = g[1]
			if ids.is_empty():
				continue
			var cw := minf(23.0, area.size.x / ids.size())
			var x0 := area.position.x + (area.size.x - cw * ids.size()) / 2.0
			for j in ids.size():
				_cells.append([Rect2(x0 + j * cw, area.position.y, cw, area.size.y), ids[j], g[2]])


## Row of the class advancement / path choice call-outs, or -1.
func _callout_row(h: HeroState) -> int:
	for i in ROWS.size():
		var kind: String = ROWS[i][1]
		if kind == "adv" and h.advancement == 0 and h.level >= int(ROWS[i][0]):
			return i
		if kind == "spec" and h.advancement == 1 and h.level >= int(ROWS[i][0]):
			return i
	return -1


func _draw_tiers() -> void:
	var h := _hero()
	if h == null:
		return
	var ci := _tiers.get_canvas_item()
	# red level rail with a medallion cap
	var top := 6.0
	var bot := _row_rect(ROWS.size() - 1).get_center().y + 8.0
	var rail := Rect2(RAIL_X - 3, top, 6, bot - top)
	UISkin.fill(ci, rail.grow(1.5), 3, Color("#2A1416"), Color("#140A0B"))
	var fill_to := _rail_fill(h, top, bot)
	if fill_to > top:
		UISkin.fill(ci, Rect2(rail.position, Vector2(rail.size.x, fill_to - top)), 3, Color("#FF6A5A"), Color("#B8282A"))
		_tiers.draw_line(Vector2(RAIL_X - 1, top + 2), Vector2(RAIL_X - 1, fill_to - 2), Color(1, 1, 1, 0.25), 1.0)
	UISkin.stroke(ci, rail.grow(1.5), 3, Color(0, 0, 0, 0.95), 1.0)
	UISkin.medallion(ci, Vector2(RAIL_X, top - 1), 5.5, "normal", true)
	var ic := UITheme.icon("cross")
	if ic:
		_tiers.draw_texture_rect(ic, Rect2(RAIL_X - 3.5, top - 4.5, 7, 7), false)
	var fb := UITheme.font_body
	for i in ROWS.size():
		var rr := _row_rect(i)
		var cy := rr.get_center().y
		var lv: int = ROWS[i][0]
		var open := _row_open(h, i)
		_tiers.draw_line(Vector2(RAIL_X - 5, cy), Vector2(RAIL_X + 5, cy), Color("#F1E2BE"), 1.2)
		var ls := str(lv)
		_tiers.draw_string_outline(fb, Vector2(RAIL_X + 7, cy - 3), ls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.9))
		_tiers.draw_string(fb, Vector2(RAIL_X + 7, cy - 3), ls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_TEXT if h.level >= lv else UITheme.C_DIM)
		var ac := Color("#C9C2B4") if open else Color("#5A5560")
		for k in 2:
			var ax := RAIL_X + 12 + k * 6
			_tiers.draw_polyline(PackedVector2Array([Vector2(ax + 3.5, cy - 3.5), Vector2(ax, cy), Vector2(ax + 3.5, cy + 3.5)]), ac, 1.4, true)
		_tiers.draw_line(Vector2(RAIL_X + 13, cy), Vector2(BOX_X - 1, cy), ac, 1.4)
		UISkin.fill(ci, rr, 3, Color("#3A363E") if open else Color("#26232A"), Color("#24212A") if open else Color("#17151B"))
		UISkin.stroke(ci, rr, 3, Color(0, 0, 0, 0.95), 1.2)
		UISkin.stroke(ci, rr.grow(-1.5), 2, Color(1, 1, 1, 0.07), 1.0)
		if str(ROWS[i][1]) == "spec":
			var mx := rr.position.x + rr.size.x / 2.0
			_tiers.draw_line(Vector2(mx, rr.position.y + 4), Vector2(mx, rr.end.y - 4), Color(0, 0, 0, 0.6), 1.0)
		if not open:
			var li := UITheme.icon("lock")
			if li:
				_tiers.draw_texture_rect(li, Rect2(rr.end.x - 10, rr.position.y + 2, 7, 7), false, Color(1, 1, 1, 0.6))
	for cell in _cells:
		_draw_skill(cell[0], str(cell[1]), bool(cell[2]), h)
	var co := _callout_row(h)
	if co >= 0:
		var rr2 := _row_rect(co)
		var p := 0.5 + 0.5 * sin(_t * 4.0)
		UISkin.stroke(ci, rr2.grow(1.0), 3, Color(UITheme.C_GOLD, 0.4 + 0.5 * p), 1.4)
		var s := DataDB.t("status_advance") if str(ROWS[co][1]) == "adv" else DataDB.t("status_pick_spec")
		var tw := fb.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var br := Rect2(rr2.get_center().x - tw / 2.0 - 6, rr2.get_center().y - 5.5, tw + 12, 11)
		UISkin.button(ci, br, "gold", "hover" if p > 0.5 else "normal")
		_tiers.draw_string(fb, Vector2(br.position.x + 6, br.position.y + 8.5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#2A1A08"))


## Rail fill: piecewise linear between the row centres by hero level.
func _rail_fill(h: HeroState, top: float, bot: float) -> float:
	var ys: Array = [top]
	var lvs: Array = [0]
	for i in ROWS.size():
		ys.append(_row_rect(i).get_center().y)
		lvs.append(int(ROWS[i][0]))
	ys.append(bot)
	lvs.append(100)
	for k in range(lvs.size() - 2, -1, -1):
		if h.level >= int(lvs[k]):
			var f := clampf(float(h.level - int(lvs[k])) / float(maxi(1, int(lvs[k + 1]) - int(lvs[k]))), 0.0, 1.0)
			return lerpf(float(ys[k]), float(ys[k + 1]), f)
	return top


func _draw_skill(r: Rect2, sid: String, locked: bool, h: HeroState) -> void:
	var sd := DataDB.skill_def(sid)
	var lv := h.skill_level(sid)
	var mx := int(sd.get("max", 1))
	var c := Vector2(r.get_center().x, r.position.y + 9)
	var rad := 8.5
	var typ := str(sd.get("type", "active"))
	var rim: Color = {"active": Color("#F2C45A"), "passive": Color("#7FB3FF"), "ult": Color("#FF6A5A")}.get(typ, Color.WHITE)
	if sid == _sel:
		_tiers.draw_circle(c, rad + 3.5, Color(1, 0.9, 0.5, 0.25))
	var learnable := not locked and h.can_level_skill(sid)
	if learnable:
		_tiers.draw_circle(c, rad + 2.5, Color(UITheme.C_GOLD, 0.15 + 0.15 * sin(_t * 4.0)))
	_tiers.draw_circle(c, rad + 1.2, Color(0, 0, 0, 0.95))
	_tiers.draw_circle(c, rad, Color("#1A1418"))
	var tex := SpriteLib.skill_icon(sid)
	if tex:
		var s := rad * 2.2
		var mod := Color.WHITE if lv > 0 else (Color(0.55, 0.53, 0.55) if not locked else Color(0.28, 0.28, 0.32))
		_tiers.draw_texture_rect(tex, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), false, mod)
	if h.equipped_skills.has(sid):
		var o := c + Vector2(rad - 2, -rad + 2)
		_tiers.draw_polyline(PackedVector2Array([o + Vector2(-3, 0), o + Vector2(-0.5, 2.5), o + Vector2(4, -3)]), Color(0, 0, 0, 0.95), 3.2, true)
		_tiers.draw_polyline(PackedVector2Array([o + Vector2(-3, 0), o + Vector2(-0.5, 2.5), o + Vector2(4, -3)]), Color("#7CFF9A"), 1.6, true)
	var txt := "%d/%d" % [lv, mx]
	var f := UITheme.font_body
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	_tiers.draw_string_outline(f, Vector2(c.x - tw / 2.0, r.position.y + 25), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.9))
	_tiers.draw_string(f, Vector2(c.x - tw / 2.0, r.position.y + 25), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
		UITheme.C_TEXT if lv > 0 else (UITheme.C_DIM if not locked else Color("#5A5560")))


func _cell_at(p: Vector2) -> Array:
	for cell in _cells:
		var r: Rect2 = cell[0]
		if r.has_point(p):
			return cell
	return []


func _on_tiers_input(ev: InputEvent) -> void:
	var h := _hero()
	if h == null:
		return
	if ev is InputEventMouseMotion:
		var cell := _cell_at(ev.position)
		var id := str(cell[1]) if not cell.is_empty() else ""
		if id != _hover:
			_hover = id
			if id != "":
				WindowManager.show_text_tooltip(_skill_tip(h, id))
			else:
				WindowManager.hide_tooltip()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		# advancement call-outs
		var co := _callout_row(h)
		if co >= 0 and _row_rect(co).has_point(ev.position):
			if str(ROWS[co][1]) == "adv":
				_advance(h)
			else:
				_set_spec(h, "a" if ev.position.x < _row_rect(co).get_center().x else "b")
			_tiers.accept_event()
			return
		var cell2 := _cell_at(ev.position)
		if not cell2.is_empty():
			_sel = str(cell2[1])
			AudioManager.play("ui_click", 0.05, 0.45)
			if ev.double_click:
				_on_learn()
			_update_detail()
		_tiers.accept_event()


func _skill_tip(h: HeroState, sid: String) -> String:
	var sd := DataDB.skill_def(sid)
	var lv := h.skill_level(sid)
	var s := "%s  %d/%d\n%s\n%s" % [DataDB.tx(sd.get("name", {})), lv, int(sd.get("max", 1)),
		DataDB.t("skill_" + str(sd.get("type", "active"))), _describe(sd, maxi(1, lv))]
	if lv > 0 and lv < int(sd.get("max", 1)):
		s += "\n" + DataDB.t("next_level") + ": " + _describe(sd, lv + 1)
	return s


func _fmt_param(sd: Dictionary, name: String, lvl: int) -> String:
	var p: Array = sd.get("params", {}).get(name, [0, 0, "n"])
	var v := StatCalc.param(sd, name, max(1, lvl))
	match str(p[2]):
		"%":
			return "%d%%" % int(round(v * 100))
		"p":
			return ("%.1f%%" % v) if abs(v - round(v)) > 0.05 else "%d%%" % int(round(v))
		"s":
			return "%.1fs" % v
	return F.fmt_num(round(v * 10) / 10.0)


func _describe(sd: Dictionary, lvl: int) -> String:
	var txt := DataDB.tx(sd.get("desc", {}))
	for k in sd.get("params", {}):
		txt = txt.replace("{%s}" % k, _fmt_param(sd, k, lvl))
	return txt


# ------------------------------------------------------------------ detail
func _update_detail() -> void:
	var h := _hero()
	if h == null or _detail == null:
		return
	var sd := DataDB.skill_def(_sel)
	var lv := h.skill_level(_sel)
	_learn.disabled = not h.can_level_skill(_sel)
	_equip.visible = sd.get("type") == "active"
	_equip.disabled = lv <= 0
	_equip.text = DataDB.t("btn_unequip") if h.equipped_skills.has(_sel) else DataDB.t("btn_equip")
	_detail.queue_redraw()


func _draw_detail() -> void:
	var h := _hero()
	if h == null:
		return
	var ci := _detail.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _detail.size)
	UISkin.fill(ci, r, 3, Color("#2A2228"), Color("#141016"))
	UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.0)
	UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.5), 1.0)
	var sd := DataDB.skill_def(_sel)
	if sd.is_empty():
		return
	var lv := h.skill_level(_sel)
	var tex := SpriteLib.skill_icon(_sel)
	if tex:
		_detail.draw_texture_rect(tex, Rect2(4, 4, 16, 16), false)
	var f := UITheme.font_title
	_detail.draw_string(f, Vector2(24, 11), DataDB.tx(sd.get("name", {})), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 122, 8, UITheme.C_GOLD)
	var meta := "%s  ·  %d/%d" % [DataDB.t("skill_" + str(sd.get("type", "active"))), lv, int(sd.get("max", 1))]
	if sd.has("cd"):
		meta += "  ·  " + DataDB.t("cooldown", {"s": "%.0f" % float(sd["cd"])})
	_detail.draw_string(UITheme.font_body, Vector2(24, 20), meta, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 7, UITheme.C_DIM)
	var req := int(sd.get("req_lv", 1))
	var line := _describe(sd, maxi(1, lv))
	if h.level < req:
		line = DataDB.t("status_need_lv", {"lv": req}) + "  " + line
	_detail.draw_multiline_string(UITheme.font_body, Vector2(5, 30), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 7, 2, UITheme.C_TEXT)


func _on_learn() -> void:
	var h := _hero()
	if h and h.level_skill(_sel):
		AudioManager.play("levelup", 0.05, 0.4)
		_changed(h)


func _on_equip() -> void:
	var h := _hero()
	if h == null:
		return
	var i := h.equipped_skills.find(_sel)
	if i >= 0:
		h.equipped_skills[i] = ""
	else:
		var free := h.equipped_skills.find("")
		if free < 0:
			free = h.equipped_skills.size() - 1
		h.equipped_skills[free] = _sel
	AudioManager.play("equip", 0.05, 0.4)
	_changed(h)


func _advance(h: HeroState) -> void:
	if h.advancement == 0 and h.level >= 30:
		h.advancement = 1
		h.stat_points += 10
		h.skill_points += 3
		AudioManager.play("levelup", 0.0, 0.8)
		EventBus.notify.emit(DataDB.t("advanced", {"name": h.display_name(), "cls": h.class_title()}), UITheme.C_GOLD)
		_changed(h)


func _set_spec(h: HeroState, sp: String) -> void:
	if h.advancement != 1 or h.level < 70:
		return
	h.advancement = 2
	h.spec = sp
	h.stat_points += 10
	h.skill_points += 3
	AudioManager.play("levelup", 0.0, 0.8)
	EventBus.notify.emit(DataDB.t("advanced", {"name": h.display_name(), "cls": h.class_title()}), UITheme.C_GOLD)
	_changed(h)


func _changed(h: HeroState) -> void:
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.hero_stats_changed.emit(h.id)
	WindowManager.refresh_all()


var _set_btns: Array = []


func _paint_sets() -> void:
	var h := _hero()
	for b in _set_btns:
		if is_instance_valid(b):
			UITheme.set_button_color(b, "gold" if h and int(b.get_meta("set")) == h.active_set else "brown")


func _host_ctl() -> Control:
	return content
