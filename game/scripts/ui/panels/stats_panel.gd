extends PanelWindow
## Status: personal growth of one hero. A parchment sheet to spend stat points on the five attributes (each
## with its own glyph and what it gives), a strip of key numbers, and the class abilities hanging off a red
## level rail (base / first advancement / specialisation) as round medallions. The magnifier shows every stat.

const PARCH_H := 98.0
const TIER_LV := [1, 30, 70]
const ROW_H := 34.0
const ROW_GAP := 4.0
const PRIM_ICON := {"str": "sword", "dex": "boot", "int": "book", "vit": "heart", "luk": "star"}
const PRIM_COL := {"str": Color("#B8402A"), "dex": Color("#2F8A3E"), "int": Color("#2F5FB8"), "vit": Color("#B8305A"), "luk": Color("#B88A1E")}
const RAIL_X := 12.0
const BOX_X := 36.0

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
	# parchment with the stat list
	_parch = Control.new()
	_parch.size = Vector2(w, PARCH_H)
	_parch.mouse_filter = Control.MOUSE_FILTER_PASS
	_parch.draw.connect(_draw_parch)
	c.add_child(_parch)
	var sc := W.scroll(Vector2(w - 16, PARCH_H - 24))
	sc.position = Vector2(8, 17)
	c.add_child(sc)
	_list = W.vbox(0)
	_list.custom_minimum_size = Vector2(w - 26, 0)
	sc.add_child(_list)
	# hero switch arrows on the parchment's tab
	for dir in [-1, 1]:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(10, 12)
		b.position = Vector2(w / 2.0 - 62 if dir < 0 else w / 2.0 + 52, 1)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var d: int = dir
		b.draw.connect(func():
			var cx := 5.0
			var pts := PackedVector2Array([Vector2(cx + 2.5 * d, 2), Vector2(cx - 2.5 * d, 6), Vector2(cx + 2.5 * d, 10)])
			b.draw_colored_polygon(pts, Color("#F3D58F") if b.is_hovered() else Color("#C9A66B")))
		b.mouse_entered.connect(b.queue_redraw)
		b.mouse_exited.connect(b.queue_redraw)
		b.pressed.connect(func(): _cycle_hero(d))
		c.add_child(b)
	# magnifier: summary <-> every stat
	var mag := Button.new()
	mag.flat = true
	mag.focus_mode = Control.FOCUS_NONE
	mag.size = Vector2(13, 13)
	mag.position = Vector2(4, 0)
	mag.tooltip_text = DataDB.t("status_more")
	mag.draw.connect(func():
		var ci := mag.get_canvas_item()
		var r := Rect2(Vector2.ZERO, mag.size)
		UISkin.fill(ci, r, 2, Color("#5A2A20"), Color("#2C120E"))
		UISkin.stroke(ci, r, 2, Color(0, 0, 0, 0.9), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.8 if mag.is_hovered() or _full else 0.45), 1.0)
		mag.draw_arc(Vector2(5.5, 5.5), 2.8, 0, TAU, 14, Color("#F3D58F"), 1.2, true)
		mag.draw_line(Vector2(7.6, 7.6), Vector2(10.5, 10.5), Color("#F3D58F"), 1.6, true))
	mag.mouse_entered.connect(mag.queue_redraw)
	mag.mouse_exited.connect(mag.queue_redraw)
	mag.pressed.connect(func():
		_full = not _full
		AudioManager.play("ui_click", 0.05, 0.5)
		refresh())
	c.add_child(mag)
	# key numbers
	_chips = Control.new()
	_chips.position = Vector2(0, PARCH_H + 2)
	_chips.size = Vector2(w, 17)
	_chips.mouse_filter = Control.MOUSE_FILTER_PASS
	_chips.draw.connect(_draw_chips)
	c.add_child(_chips)
	# class abilities header with skill points
	_pts_plaque = Control.new()
	_pts_plaque.position = Vector2(0, PARCH_H + 22)
	_pts_plaque.size = Vector2(w, 13)
	_pts_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pts_plaque.draw.connect(_draw_plaque)
	c.add_child(_pts_plaque)
	# tier rail + boxes
	_tier_top = PARCH_H + 38.0
	_tiers = Control.new()
	_tiers.position = Vector2(0, _tier_top)
	_tiers.size = Vector2(w, 3 * ROW_H + 2 * ROW_GAP + 4)
	_tiers.mouse_filter = Control.MOUSE_FILTER_STOP
	_tiers.draw.connect(_draw_tiers)
	_tiers.gui_input.connect(_on_tiers_input)
	_tiers.mouse_exited.connect(func():
		_hover = ""
		WindowManager.hide_tooltip())
	c.add_child(_tiers)
	# selected skill
	var dy := _tier_top + _tiers.size.y + 3.0
	_detail = Control.new()
	_detail.position = Vector2(0, dy)
	_detail.size = Vector2(w, c.size.y - dy)
	_detail.mouse_filter = Control.MOUSE_FILTER_PASS
	_detail.draw.connect(_draw_detail)
	c.add_child(_detail)
	_learn = UITheme.button(DataDB.t("btn_levelup"), "blue", _on_learn, Vector2(44, 12))
	_detail.add_child(_learn)
	_learn.size = Vector2(44, 12)
	_learn.position = Vector2(w - 94, 4)
	_equip = UITheme.button(DataDB.t("btn_equip"), "orange", _on_equip, Vector2(44, 12))
	_detail.add_child(_equip)
	_equip.size = Vector2(44, 12)
	_equip.position = Vector2(w - 47, 4)
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.equipment_changed.connect(func(_h): refresh())
	EventBus.party_changed.connect(refresh)
	refresh()


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
	var h := _hero()
	for ch in _list.get_children():
		ch.queue_free()
	if h == null:
		return
	if _sel == "" or DataDB.skill_def(_sel).get("class", "") != h.cls():
		_sel = h.equipped_skills[0] if h.equipped_skills[0] != "" else h.class_skills()[0]
	GameState.invalidate_stats()
	var s := GameState.hero_stats(h.id)
	_build_stats(h, s)
	_layout_cells(h)
	_update_detail()
	_parch.queue_redraw()
	_pts_plaque.queue_redraw()
	_chips.queue_redraw()


# ------------------------------------------------------------------ parchment
func _draw_parch() -> void:
	var ci := _parch.get_canvas_item()
	var w := _parch.size.x
	UISkin.parchment(ci, Rect2(2, 7, w - 4, PARCH_H - 9))
	UISkin.ornate(ci, Rect2(2, 7, w - 4, PARCH_H - 9))
	# name tab
	var h := _hero()
	var txt := "%s · %s" % [h.display_name(), h.class_title()] if h else ""
	var tab := Rect2(w / 2.0 - 50, 0, 100, 13)
	UISkin.fill(ci, tab, 6, Color("#F1E2BE"), Color("#D2B884"))
	UISkin.stroke(ci, tab, 6, UISkin.PARCH_EDGE, 1.0)
	var f := UITheme.font_title
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_parch.draw_string(f, Vector2(w / 2.0 - minf(tw, 92.0) / 2.0, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, 92, 8, UISkin.INK)


func _row(label: String, value: String, vcol: Color = UISkin.INK, plus_cb: Callable = Callable()) -> void:
	var r := W.hbox(2)
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
	if h.stat_points > 0:
		top.add_child(UITheme.button(DataDB.t("btn_auto"), "blue", func():
			h.auto_allocate()
			_changed(h), Vector2(30, 10)))
	_list.add_child(top)
	var main: String = h.class_def().get("primary", "str")
	for p in HeroState.PRIMARY:
		_prim_row(h, s, p, p == main)
	if not _full:
		return
	_section(DataDB.t("status_summary"))
	_row(StatNames.label("level"), str(h.level))
	_row(DataDB.t("stat_exp"), "%s / %s" % [F.fmt_num(h.xp), F.fmt_num(F.xp_required(h.level))])
	_row(StatNames.label("aps"), "%.2f" % float(s["aps"]))
	_row(StatNames.label("crit_chance"), "%.1f%%" % float(s["crit_chance"]))
	_row(StatNames.label("crit_dmg"), "%d%%" % int(s["crit_dmg"]))
	_section(DataDB.t("tab_combat"))
	for k in ["spell", "added_dmg", "elem_dmg", "penetrate", "attack_speed", "cast_speed", "skill_dmg", "phys_dmg", "fire_dmg",
			"cold_dmg", "lightning_dmg", "chaos_dmg", "holy_dmg", "elite_dmg", "boss_dmg"]:
		_row(StatNames.label(k), F.fmt_num(s[k]) if StatNames.is_flat(k) else _p(s, k))
	_section(DataDB.t("tab_defense"))
	for k in ["dr", "crit_res", "evasion", "block", "fire_res", "cold_res", "lightning_res", "chaos_res", "lifesteal", "thorns"]:
		_row(StatNames.label(k), _p(s, k))
	_row(StatNames.label("hp_regen"), F.fmt_num(s["hp_regen"]) + "/s")
	_section(DataDB.t("tab_other"))
	for k in ["item_find", "gold_find", "xp_bonus", "cdr", "heal_bonus", "buff_duration", "ult_charge", "summon_dmg"]:
		_row(StatNames.label(k), _p(s, k))
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
func _tier_ids(h: HeroState, tier: int, spec := "") -> Array:
	var ids: Array = []
	for sid in h.class_skills():
		var sd: Dictionary = DataDB.skill_def(sid)
		if sd.get("type") == "ult":
			continue
		if int(sd.get("tier", 0)) == tier and (spec == "" or sd.get("spec", "") == spec):
			ids.append(sid)
	if tier == 0 and h.ult_id() != "":
		ids.append(h.ult_id())
	return ids


func _row_rect(i: int) -> Rect2:
	return Rect2(BOX_X, 2 + i * (ROW_H + ROW_GAP), _tiers.size.x - BOX_X - 1, ROW_H)


func _layout_cells(h: HeroState) -> void:
	_cells.clear()
	for i in 3:
		var rr := _row_rect(i)
		var groups: Array = []
		if i < 2:
			groups.append([_tier_ids(h, i), rr.grow(-4.0), i > h.advancement])
		else:
			var half := (rr.size.x - 8.0) / 2.0
			for k in 2:
				var sp: String = ["a", "b"][k]
				var lock := h.advancement < 2 or (h.spec != "" and h.spec != sp)
				groups.append([_tier_ids(h, 2, sp), Rect2(rr.position.x + 4 + k * (half + 0.0), rr.position.y + 4, half, rr.size.y - 8), lock])
		for g in groups:
			var ids: Array = g[0]
			var area: Rect2 = g[1]
			if ids.is_empty():
				continue
			var cw := minf(24.0, area.size.x / ids.size())
			var x0 := area.position.x + (area.size.x - cw * ids.size()) / 2.0
			for j in ids.size():
				_cells.append([Rect2(x0 + j * cw, area.position.y, cw, area.size.y), ids[j], g[2]])


func _draw_tiers() -> void:
	var h := _hero()
	if h == null:
		return
	var ci := _tiers.get_canvas_item()
	# red level rail with a medallion cap
	var top := 6.0
	var bot := _row_rect(2).get_center().y + 10.0
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
	for i in 3:
		var rr := _row_rect(i)
		var cy := rr.get_center().y
		var lv: int = TIER_LV[i]
		var reached := h.level >= lv
		# tick + level number
		_tiers.draw_line(Vector2(RAIL_X - 5, cy), Vector2(RAIL_X + 5, cy), Color("#F1E2BE"), 1.2)
		var ls := str(lv)
		_tiers.draw_string_outline(fb, Vector2(RAIL_X + 7, cy - 3), ls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.9))
		_tiers.draw_string(fb, Vector2(RAIL_X + 7, cy - 3), ls, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_TEXT if reached else UITheme.C_DIM)
		# double chevron pointing at the box
		var ac := Color("#C9C2B4") if i <= h.advancement else Color("#5A5560")
		for k in 2:
			var ax := RAIL_X + 12 + k * 6
			_tiers.draw_polyline(PackedVector2Array([Vector2(ax + 4, cy - 4), Vector2(ax, cy), Vector2(ax + 4, cy + 4)]), ac, 1.6, true)
		_tiers.draw_line(Vector2(RAIL_X + 13, cy), Vector2(BOX_X - 1, cy), ac, 1.6)
		# stone box
		var open := i <= h.advancement
		UISkin.fill(ci, rr, 3, Color("#3A363E") if open else Color("#26232A"), Color("#24212A") if open else Color("#17151B"))
		UISkin.stroke(ci, rr, 3, Color(0, 0, 0, 0.95), 1.2)
		UISkin.stroke(ci, rr.grow(-1.5), 2, Color(1, 1, 1, 0.07), 1.0)
		if i == 2:
			var mx := rr.position.x + rr.size.x / 2.0
			_tiers.draw_line(Vector2(mx, rr.position.y + 5), Vector2(mx, rr.end.y - 5), Color(0, 0, 0, 0.6), 1.0)
			_tiers.draw_line(Vector2(mx + 1, rr.position.y + 5), Vector2(mx + 1, rr.end.y - 5), Color(1, 1, 1, 0.06), 1.0)
	for cell in _cells:
		_draw_skill(cell[0], str(cell[1]), bool(cell[2]), h)
	# advancement call-outs on reachable locked tiers
	for i in [1, 2]:
		if h.advancement == i - 1 and h.level >= TIER_LV[i]:
			var rr2 := _row_rect(i)
			var p := 0.5 + 0.5 * sin(_t * 4.0)
			UISkin.stroke(ci, rr2.grow(1.0), 3, Color(UITheme.C_GOLD, 0.4 + 0.5 * p), 1.4)
			var s := DataDB.t("status_advance") if i == 1 else DataDB.t("status_pick_spec")
			var tw := fb.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var br := Rect2(rr2.get_center().x - tw / 2.0 - 6, rr2.position.y - 5, tw + 12, 11)
			UISkin.button(ci, br, "gold", "hover" if p > 0.5 else "normal")
			_tiers.draw_string(fb, Vector2(br.position.x + 6, br.position.y + 8.5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#2A1A08"))
		elif h.advancement < i:
			var rr3 := _row_rect(i)
			var li := UITheme.icon("lock")
			if li:
				_tiers.draw_texture_rect(li, Rect2(rr3.end.x - 12, rr3.position.y + 3, 8, 8), false, Color(1, 1, 1, 0.7))


## Rail fill: linear between the tier rows by level (row centres at levels 1 / 30 / 70).
func _rail_fill(h: HeroState, top: float, bot: float) -> float:
	var ys: Array = [top]
	for i in 3:
		ys.append(_row_rect(i).get_center().y)
	var lvs: Array = [0, 1, 30, 70]
	for k in range(3, 0, -1):
		if h.level >= int(lvs[k]):
			if k == 3:
				return minf(bot, float(ys[3]) + (bot - float(ys[3])) * clampf((h.level - 70) / 30.0, 0.0, 1.0))
			var f := clampf(float(h.level - int(lvs[k])) / float(int(lvs[k + 1]) - int(lvs[k])), 0.0, 1.0)
			return lerpf(float(ys[k]), float(ys[k + 1]), f)
	return top


func _draw_skill(r: Rect2, sid: String, locked: bool, h: HeroState) -> void:
	var sd := DataDB.skill_def(sid)
	var lv := h.skill_level(sid)
	var mx := int(sd.get("max", 1))
	var c := Vector2(r.get_center().x, r.position.y + 10)
	var rad := 9.5
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
		var s := rad * 1.55
		var mod := Color.WHITE if lv > 0 else (Color(0.62, 0.6, 0.6) if not locked else Color(0.28, 0.28, 0.32))
		_tiers.draw_texture_rect(tex, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), false, mod)
		# round off the square icon
		_tiers.draw_arc(c, rad + 0.6, 0, TAU, 28, Color("#1A1418"), 3.4, true)
	_tiers.draw_arc(c, rad, 0, TAU, 28, Color(0, 0, 0, 0.9), 1.8, true)
	_tiers.draw_arc(c, rad - 0.3, 0, TAU, 28, rim if lv > 0 else Color(rim, 0.35), 1.2, true)
	if h.equipped_skills.has(sid):
		var o := c + Vector2(rad - 2, -rad + 2)
		_tiers.draw_polyline(PackedVector2Array([o + Vector2(-3, 0), o + Vector2(-0.5, 2.5), o + Vector2(4, -3)]), Color(0, 0, 0, 0.95), 3.2, true)
		_tiers.draw_polyline(PackedVector2Array([o + Vector2(-3, 0), o + Vector2(-0.5, 2.5), o + Vector2(4, -3)]), Color("#7CFF9A"), 1.6, true)
	var txt := "%d/%d" % [lv, mx]
	var f := UITheme.font_body
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	_tiers.draw_string_outline(f, Vector2(c.x - tw / 2.0, r.position.y + 28), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.9))
	_tiers.draw_string(f, Vector2(c.x - tw / 2.0, r.position.y + 28), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
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
		for i in [1, 2]:
			if h.advancement == i - 1 and h.level >= TIER_LV[i] and _row_rect(i).has_point(ev.position):
				if i == 1:
					_advance(h)
				else:
					var sp := "a" if ev.position.x < _row_rect(2).get_center().x else "b"
					_set_spec(h, sp)
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
	_detail.draw_multiline_string(UITheme.font_body, Vector2(5, 30), _describe(sd, maxi(1, lv)), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 7, 2, UITheme.C_TEXT)


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
