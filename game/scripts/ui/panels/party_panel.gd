extends PanelWindow
## Party formation (5 slots, front -> back) + roster and star upgrades.

var sel_slot := 0
var _slots_row: HBoxContainer
var _roster: GridContainer
var _info: VBoxContainer


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	var top := W.hbox(4)
	v.add_child(top)
	var hint := UITheme.label(DataDB.t("party_hint"), UITheme.C_DIM)
	hint.custom_minimum_size = Vector2(c.size.x - 50, 0)
	hint.clip_text = true
	top.add_child(hint)
	top.add_child(UITheme.button(DataDB.t("btn_pets"), "green", func(): WindowManager.toggle_panel("pets"), Vector2(44, 12)))
	_slots_row = W.hbox(3)
	v.add_child(_slots_row)
	v.add_child(UITheme.hsep(int(c.size.x)))
	v.add_child(UITheme.label(DataDB.t("roster"), Color("#E8C98A")))
	var sc := W.scroll(Vector2(c.size.x, 62))
	v.add_child(sc)
	_roster = W.grid(9, 2)
	sc.add_child(_roster)
	_info = W.vbox(1)
	v.add_child(_info)
	EventBus.party_changed.connect(refresh)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	refresh()


func refresh() -> void:
	if _slots_row == null:
		return
	for ch in _slots_row.get_children():
		ch.queue_free()
	for ch in _roster.get_children():
		ch.queue_free()
	for ch in _info.get_children():
		ch.queue_free()
	var unlocked := GameState.unlocked_party_slots()
	# battlefield order: back (left) -> front (right)
	for vis_i in range(4, -1, -1):
		var slot := vis_i
		var col := W.vbox(0)
		var b := TextureButton.new()
		b.texture_normal = UITheme.tex("slot_normal")
		b.texture_hover = UITheme.tex("slot_hover")
		b.custom_minimum_size = Vector2(20, 20)
		b.focus_mode = Control.FOCUS_NONE
		var hid: String = GameState.party[slot]
		if hid != "":
			var ic := W.icon_rect(SpriteLib.hero_icon(hid))
			ic.size = Vector2(20, 20)
			b.add_child(ic)
		if slot >= unlocked:
			var lk := W.icon_rect(UITheme.icon("lock"))
			lk.position = Vector2(6, 6)
			b.add_child(lk)
			b.disabled = true
		if slot == sel_slot:
			var fr := W.icon_rect(UITheme.tex("slot_legendary"))
			fr.size = Vector2(20, 20)
			b.add_child(fr)
		b.pressed.connect(func():
			sel_slot = slot
			refresh())
		col.add_child(b)
		var lbl := UITheme.label(DataDB.t("slot_%d" % slot), UITheme.C_DIM)
		col.add_child(lbl)
		_slots_row.add_child(col)
	for hid in GameState.heroes:
		var h: HeroState = GameState.heroes[hid]
		var b2 := TextureButton.new()
		b2.texture_normal = UITheme.tex("slot_normal")
		b2.texture_hover = UITheme.tex("slot_hover")
		b2.custom_minimum_size = Vector2(20, 20)
		b2.focus_mode = Control.FOCUS_NONE
		b2.tooltip_text = "%s  Lv %d  %s" % [h.display_name(), h.level, h.class_title()]
		var ic2 := W.icon_rect(SpriteLib.hero_icon(hid))
		ic2.size = Vector2(20, 20)
		b2.add_child(ic2)
		if GameState.party.has(hid):
			var e := UITheme.label(str(GameState.party.find(hid) + 1), UITheme.C_GREEN)
			e.position = Vector2(14, 11)
			b2.add_child(e)
		var id2: String = hid
		b2.pressed.connect(func():
			if sel_slot < GameState.unlocked_party_slots():
				GameState.set_party_slot(sel_slot, id2)
				W.select_hero(id2)
			refresh())
		_roster.add_child(b2)
	# selected slot hero info + star up
	var shid: String = GameState.party[sel_slot]
	if shid != "":
		var h2: HeroState = GameState.heroes[shid]
		_info.add_child(UITheme.label("%s - %s Lv %d  %s" % [h2.display_name(), h2.class_title(), h2.level, "*".repeat(h2.stars)], UITheme.C_TEXT))
		var row := W.hbox(2)
		_info.add_child(row)
		if h2.stars < 6:
			var c := Tavern.star_cost(h2)
			var b3 := UITheme.button(DataDB.t("star_up", {"s": int(c["soul_shard"]), "g": F.fmt_num(int(c["gold"]))}), "gold", func():
				if Tavern.star_up(h2):
					BattleSim.refresh_hero_stats()
					EventBus.notify.emit(DataDB.t("starred", {"name": h2.display_name(), "n": h2.stars}), UITheme.C_GOLD)
					refresh())
			b3.disabled = not (GameState.gold >= int(c["gold"]) and GameState.has_material("soul_shard", int(c["soul_shard"])))
			row.add_child(b3)
		var rm := UITheme.button(DataDB.t("btn_remove"), "red", func():
			if GameState.party_count() > 1:
				GameState.set_party_slot(sel_slot, "")
				refresh())
		row.add_child(rm)
