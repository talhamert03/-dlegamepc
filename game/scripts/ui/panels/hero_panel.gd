extends PanelWindow
## Hero panel: skill details, skill grid (tiers), equip/level buttons, hero selector.

var sel_skill := ""
var _top: Control
var _grid_box: VBoxContainer
var _bottom: HBoxContainer
var _pts: Label


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_top = Control.new()
	_top.custom_minimum_size = Vector2(c.size.x, 72)
	v.add_child(_top)
	_pts = UITheme.label("", UITheme.C_GOLD)
	_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pts.custom_minimum_size = Vector2(c.size.x, 9)
	v.add_child(_pts)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 114))
	v.add_child(sc)
	_grid_box = W.vbox(2)
	sc.add_child(_grid_box)
	var bottom_box := W.vbox(1)
	v.add_child(bottom_box)
	_bottom = W.hbox(2)
	bottom_box.add_child(_bottom)
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	EventBus.party_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if _grid_box == null:
		return
	var hid := W.current_hero()
	for ch in _top.get_children():
		ch.queue_free()
	for ch in _grid_box.get_children():
		ch.queue_free()
	for ch in _bottom.get_children():
		ch.queue_free()
	if hid == "":
		return
	var h: HeroState = GameState.heroes[hid]
	if sel_skill == "" or DataDB.skill_def(sel_skill).get("class", "") != h.cls():
		sel_skill = h.equipped_skills[0] if h.equipped_skills[0] != "" else h.class_skills()[0]
	_pts.text = DataDB.t("skill_points_left", {"n": h.skill_points})
	_pts.add_theme_color_override("font_color", UITheme.C_GOLD if h.skill_points > 0 else UITheme.C_DIM)
	_build_detail(h)
	# skill grid by tier
	var tiers := [[0, "", DataDB.t("tier_base")], [1, "", h.class_def()["adv"][1][DataDB.lang] if h.class_def().has("adv") else ""],
		[2, "a", DataDB.tx(h.class_def()["adv"][2]["a"])], [2, "b", DataDB.tx(h.class_def()["adv"][2]["b"])]]
	var ult := h.ult_id()
	for t in tiers:
		var ids: Array = []
		for sid in h.class_skills():
			var sd: Dictionary = DataDB.skill_def(sid)
			if sd.get("type") == "ult":
				continue
			if int(sd.get("tier", 0)) == int(t[0]) and (t[1] == "" or sd.get("spec", "") == t[1]):
				ids.append(sid)
		if t[0] == 0 and ult != "":
			ids.append(ult)
		if ids.is_empty():
			continue
		var locked: bool = int(t[0]) > h.advancement or (int(t[0]) == 2 and h.spec != "" and h.spec != t[1])
		var title := UITheme.label(str(t[2]) + ("  (" + DataDB.t("adv_req", {"lv": [1, 30, 70][int(t[0])]}) + ")" if locked else ""), UITheme.C_DIM if locked else Color("#E8C98A"))
		_grid_box.add_child(title)
		var g := W.grid(6, 2)
		_grid_box.add_child(g)
		for sid in ids:
			g.add_child(_skill_button(h, sid, locked))
	# bottom: hero selector + class advancement
	_bottom.add_child(W.hero_selector(hid, W.select_hero))
	if (h.level >= 30 and h.advancement == 0) or (h.level >= 70 and h.advancement == 1):
		var ab := UITheme.button(DataDB.t("btn_advance"), "gold", func(): _advance(h))
		_bottom.add_child(ab)


func _skill_button(h: HeroState, sid: String, locked: bool) -> Control:
	var sd := DataDB.skill_def(sid)
	var lv := h.skill_level(sid)
	var b := TextureButton.new()
	b.custom_minimum_size = Vector2(22, 26)
	b.focus_mode = Control.FOCUS_NONE
	var icon := W.icon_rect(SpriteLib.skill_icon(sid))
	icon.position = Vector2(1, 0)
	icon.size = Vector2(20, 20)
	icon.modulate = Color(1, 1, 1) if lv > 0 else Color(0.45, 0.45, 0.5)
	b.add_child(icon)
	if sid == sel_skill:
		var fr := ColorRect.new()
		fr.color = Color(1, 0.85, 0.3, 0.0)
		b.add_child(fr)
		var outline := ReferenceRect.new()
		outline.border_color = Color("#FFE45C")
		outline.editor_only = false
		outline.position = Vector2(0, -1)
		outline.size = Vector2(22, 22)
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(outline)
	if h.equipped_skills.has(sid):
		var e := UITheme.label("E", UITheme.C_GREEN)
		e.position = Vector2(2, -1)
		b.add_child(e)
	var l := UITheme.label("%d/%d" % [lv, int(sd.get("max", 1))], UITheme.C_TEXT if not locked else UITheme.C_DIM)
	l.position = Vector2(2, 18)
	b.add_child(l)
	var tip := DataDB.tx(sd.get("name", {}))
	b.tooltip_text = tip
	b.pressed.connect(func():
		sel_skill = sid
		refresh())
	return b


func _fmt_param(sd: Dictionary, name: String, lvl: int) -> String:
	var p: Array = sd.get("params", {}).get(name, [0, 0, "n"])
	var v := StatCalc.param(sd, name, max(1, lvl))
	match str(p[2]):
		"%":
			return F.pct(v * 100.0)
		"p":
			return F.pct(v)
		"s":
			return "%.1fs" % v
	return F.fmt_num(round(v * 10) / 10.0)


func describe(sd: Dictionary, lvl: int) -> String:
	var txt := DataDB.tx(sd.get("desc", {}))
	for k in sd.get("params", {}):
		txt = txt.replace("{%s}" % k, _fmt_param(sd, k, lvl))
	return txt


func _build_detail(h: HeroState) -> void:
	var sd := DataDB.skill_def(sel_skill)
	if sd.is_empty():
		return
	var lv := h.skill_level(sel_skill)
	var frame := UITheme.nine("tooltip", 3)
	frame.size = Vector2(content.size.x, 70)
	_top.add_child(frame)
	var ic := W.icon_rect(SpriteLib.skill_icon(sel_skill))
	ic.position = Vector2(4, 4)
	ic.size = Vector2(20, 20)
	_top.add_child(ic)
	var lvl := UITheme.label("Lv.%d/%d" % [lv, int(sd.get("max", 1))], UITheme.C_TEXT)
	lvl.position = Vector2(3, 25)
	_top.add_child(lvl)
	var nm := UITheme.label(DataDB.tx(sd.get("name", {})), UITheme.C_GOLD)
	nm.position = Vector2(28, 2)
	nm.size = Vector2(content.size.x - 30, 9)
	nm.clip_text = true
	_top.add_child(nm)
	var typ := UITheme.label(DataDB.t("skill_" + str(sd.get("type", "active"))), UITheme.C_DIM)
	typ.position = Vector2(28, 10)
	_top.add_child(typ)
	var desc := UITheme.label(describe(sd, max(1, lv)), UITheme.C_TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(28, 19)
	desc.size = Vector2(content.size.x - 32, 26)
	desc.clip_text = true
	_top.add_child(desc)
	if lv > 0 and lv < int(sd.get("max", 1)):
		var nxt := UITheme.label(DataDB.t("next_level") + ": " + describe(sd, lv + 1), UITheme.C_GREEN)
		nxt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nxt.position = Vector2(3, 46)
		nxt.size = Vector2(content.size.x - 6, 9)
		nxt.clip_text = true
		_top.add_child(nxt)
	if sd.has("cd"):
		var cd := UITheme.label(DataDB.t("cooldown", {"s": "%.1f" % float(sd["cd"])}), UITheme.C_BLUE)
		cd.position = Vector2(content.size.x - 60, 10)
		cd.size = Vector2(56, 9)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_top.add_child(cd)
	var bh := W.hbox(2)
	bh.position = Vector2(3, 56)
	_top.add_child(bh)
	if sd.get("type") == "active":
		var eq := h.equipped_skills.has(sel_skill)
		var eb := UITheme.button(DataDB.t("btn_unequip") if eq else DataDB.t("btn_equip"), "orange", func(): _toggle_equip(h), Vector2(34, 11))
		eb.disabled = lv <= 0
		bh.add_child(eb)
	var lb := UITheme.button(DataDB.t("btn_levelup"), "blue", func():
		if h.level_skill(sel_skill):
			_changed(h), Vector2(40, 11))
	lb.disabled = not h.can_level_skill(sel_skill)
	bh.add_child(lb)
	var rb := UITheme.button(DataDB.t("btn_reset"), "red", func():
		var cost := 50 * h.level
		if GameState.spend_gold(cost):
			h.reset_skills()
			_changed(h), Vector2(30, 11))
	rb.tooltip_text = DataDB.t("reset_cost", {"g": F.fmt_num(50 * h.level)})
	bh.add_child(rb)


func _toggle_equip(h: HeroState) -> void:
	var i := h.equipped_skills.find(sel_skill)
	if i >= 0:
		h.equipped_skills[i] = ""
	else:
		var free := h.equipped_skills.find("")
		if free < 0:
			free = 2
		h.equipped_skills[free] = sel_skill
	_changed(h)


func _advance(h: HeroState) -> void:
	if h.advancement == 0 and h.level >= 30:
		h.advancement = 1
		h.stat_points += 10
		h.skill_points += 3
		EventBus.notify.emit(DataDB.t("advanced", {"name": h.display_name(), "cls": h.class_title()}), UITheme.C_GOLD)
		_changed(h)
	elif h.advancement == 1 and h.level >= 70:
		var dlg := ConfirmationDialog.new()
		var cd: Dictionary = h.class_def()["adv"][2]
		dlg.dialog_text = DataDB.t("choose_spec")
		dlg.ok_button_text = DataDB.tx(cd["a"])
		dlg.cancel_button_text = DataDB.tx(cd["b"])
		dlg.confirmed.connect(func(): _set_spec(h, "a"))
		dlg.canceled.connect(func(): _set_spec(h, "b"))
		add_child(dlg)
		dlg.popup_centered()


func _set_spec(h: HeroState, sp: String) -> void:
	h.advancement = 2
	h.spec = sp
	h.stat_points += 10
	h.skill_points += 3
	EventBus.notify.emit(DataDB.t("advanced", {"name": h.display_name(), "cls": h.class_title()}), UITheme.C_GOLD)
	_changed(h)


func _changed(h: HeroState) -> void:
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.hero_stats_changed.emit(h.id)
	WindowManager.refresh_all()
