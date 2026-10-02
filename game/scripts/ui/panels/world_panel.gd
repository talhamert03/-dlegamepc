extends PanelWindow
## World map: difficulty selector, act tabs, zone nodes on a parchment map.

var act := 1
var _tabs: HBoxContainer
var _diff_btn: Button
var _map: TextureRect
var _nodes_root: Control
var _nodes: Dictionary = {}
var _marker: TextureRect
var _diff := 0


func build(c: Control) -> void:
	_diff = int(GameState.progress.get("difficulty", 0))
	act = int(DataDB.zone(int(GameState.progress.get("zone", 0))).get("act", 1))
	var w := c.size.x
	var top := W.hbox(3)
	top.position = Vector2(0, 0)
	c.add_child(top)
	_diff_btn = UITheme.button("", "gold", _cycle_diff, Vector2(w * 0.5 - 2, 14))
	top.add_child(_diff_btn)
	var tb := UITheme.button(DataDB.t("tower_name"), "blue", func():
		if BattleSim.mode == "tower":
			BattleSim.leave_tower()
		elif BattleSim.tower_unlocked():
			BattleSim.enter_tower()
		else:
			EventBus.notify.emit(DataDB.t("tower_locked"), UITheme.C_RED), Vector2(w * 0.5 - 1, 14))
	tb.tooltip_text = DataDB.t("tower_best", {"n": int(GameState.progress.get("tower_best", 0))})
	top.add_child(tb)
	_tabs = W.hbox(2)
	_tabs.position = Vector2(0, 18)
	c.add_child(_tabs)
	for i in range(1, 5):
		var a := i
		var b := UITheme.button(DataDB.t("act_n", {"n": i}), "brown", func(): _set_act(a), Vector2((w - 6) / 4.0, 13))
		_tabs.add_child(b)
	var mw := w
	var k := mw / 240.0
	var frame := UITheme.nine("parchment", 3)
	frame.position = Vector2(0, 35)
	frame.size = Vector2(mw, 150 * k + 4)
	c.add_child(frame)
	_map = TextureRect.new()
	_map.position = Vector2(2, 37)
	_map.size = Vector2(mw - 4, 150 * k)
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	c.add_child(_map)
	_nodes_root = Control.new()
	_nodes_root.size = Vector2(240, 150)
	_nodes_root.scale = Vector2((mw - 4) / 240.0, k)
	_map.add_child(_nodes_root)
	# zone card under the map (hovered node, else the current zone)
	_card = Control.new()
	_card.position = Vector2(0, 35 + 150 * k + 8)
	_card.size = Vector2(w, c.size.y - _card.position.y)
	c.add_child(_card)
	EventBus.zone_changed.connect(func(_z): refresh())
	EventBus.zone_unlocked.connect(func(_z): refresh())
	refresh()


var _card: Control


func _show_card(zi: int) -> void:
	for ch in _card.get_children():
		ch.queue_free()
	var z := DataDB.zone(zi)
	if z.is_empty():
		return
	var w := _card.size.x
	var bg := UITheme.nine("well", 2)
	bg.size = _card.size
	_card.add_child(bg)
	var nm := UITheme.label(DataDB.tx(z["name"]), UITheme.C_TITLE, 10, UITheme.font_title)
	nm.position = Vector2(6, 3)
	_card.add_child(nm)
	var lv := UITheme.label("Lv %d-%d" % [F.monster_level(z, 1, _diff), F.monster_level(z, 10, _diff)], UITheme.C_GOLD, 8, UITheme.font_body)
	lv.position = Vector2(w - 70, 4)
	lv.size = Vector2(64, 10)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_card.add_child(lv)
	var cleared: bool = GameState.progress["cleared"].has("%d_%s" % [_diff, z["id"]])
	var st := UITheme.label("✓ " + DataDB.t("cleared") if cleared else "", UITheme.C_GREEN, 7)
	st.position = Vector2(w - 70, 15)
	st.size = Vector2(64, 9)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_card.add_child(st)
	# monsters of the zone + the boss, as their idle sprites
	var row := W.hbox(2)
	row.position = Vector2(4, 22)
	_card.add_child(row)
	var ids: Array = z.get("enemies", []).duplicate()
	ids.append(z.get("boss", ""))
	for eid in ids:
		var boss: bool = eid == z.get("boss", "")
		var b := UITheme.slot_button(Vector2(30, 34) if boss else Vector2(26, 30))
		var tex := SpriteLib.chibi_frame("enemies", str(eid))
		if tex == null:
			tex = SpriteLib.hd_sprite("enemies", str(eid))
		var ic := W.icon_rect(tex, Vector2(26, 30) if boss else Vector2(22, 26))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(2, 2)
		ic.flip_h = true
		b.add_child(ic)
		b.tooltip_text = DataDB.tx(DataDB.enemy_def(str(eid)).get("name", {})) + (" (" + DataDB.t("boss") + ")" if boss else "")
		if boss:
			var sk := W.icon_rect(UITheme.icon("skull"), Vector2(8, 8))
			sk.position = Vector2(21, 1)
			sk.size = Vector2(8, 8)
			b.add_child(sk)
		row.add_child(b)
	var desc := UITheme.label(DataDB.t("boss") + ": " + DataDB.tx(DataDB.enemy_def(str(z.get("boss", ""))).get("name", {})), Color("#FF9A8A"), 8)
	desc.position = Vector2(6, 60)
	desc.size = Vector2(w - 12, 10)
	desc.clip_text = true
	_card.add_child(desc)


func _cycle_diff() -> void:
	var maxz: Array = GameState.progress.get("max_zone", [0, -1, -1])
	for k in 3:
		_diff = (_diff + 1) % 3
		if int(maxz[_diff]) >= 0:
			break
	refresh()


func _set_act(a: int) -> void:
	act = a
	refresh()


func refresh() -> void:
	if _map == null:
		return
	_diff_btn.text = DataDB.tx(DataDB.difficulties[_diff]["name"])
	for i in _tabs.get_child_count():
		UITheme.set_button_color(_tabs.get_child(i), "orange" if i + 1 == act else "brown")
	_map.texture = UITheme.tex("map_act%d" % act)
	for ch in _nodes_root.get_children():
		ch.queue_free()
	var nodes_data: Dictionary = DataDB._load("res://data/map_nodes.json")
	var pts: Array = nodes_data.get(str(act), [])
	var maxz: int = int(GameState.progress["max_zone"][_diff])
	var cur: int = int(GameState.progress.get("zone", 0))
	var cur_diff: int = int(GameState.progress.get("difficulty", 0))
	for i in pts.size():
		var zi := (act - 1) * 10 + i
		var z := DataDB.zone(zi)
		if z.is_empty():
			continue
		var p: Array = pts[i]
		var cleared: bool = GameState.progress["cleared"].has("%d_%s" % [_diff, z["id"]])
		var unlocked := zi <= maxz
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		var col := "orange" if cleared else ("red" if unlocked else "gray")
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, UITheme.btn_box(col, st))
		b.custom_minimum_size = Vector2(12, 12)
		b.size = Vector2(12, 12)
		var zi3 := zi
		b.mouse_entered.connect(func(): _show_card(zi3))
		b.mouse_exited.connect(func(): _show_card(int(GameState.progress.get("zone", 0))))
		b.position = Vector2(float(p[0]) - 6, float(p[1]) - 6)
		b.disabled = not unlocked
		var lv: Array = z.get("level", [1, 1])
		var lvtxt := "Lv %d-%d" % [F.monster_level(z, 1, _diff), F.monster_level(z, 10, _diff)]
		b.tooltip_text = "%s\n%s\n%s: %s" % [DataDB.tx(z["name"]), lvtxt, DataDB.t("boss"), DataDB.tx(DataDB.enemy_def(z["boss"]).get("name", {}))]
		var zi2 := zi
		b.pressed.connect(func(): _travel(zi2))
		_nodes_root.add_child(b)
		var num := UITheme.label(str(i + 1), UITheme.C_TEXT)
		num.position = b.position + Vector2(3 if i < 9 else 1, 0)
		_nodes_root.add_child(num)
		if zi == cur and _diff == cur_diff:
			# party leader standing on the current zone
			var lead: String = GameState.party[0] if GameState.party[0] != "" else "kael"
			var chibi := SpriteLib.chibi_frame("heroes", lead)
			var m := W.icon_rect(chibi if chibi else SpriteLib.hero_icon(lead), Vector2(20, 18))
			m.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			m.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			m.size = Vector2(20, 18)
			m.position = b.position + Vector2(-5, -17)
			_nodes_root.add_child(m)
	var nm := UITheme.label(DataDB.tx(DataDB.acts[act - 1]["name"]) if act - 1 < DataDB.acts.size() else "", Color("#3A2A22"), 8, UITheme.font_title)
	nm.position = Vector2(8, 4)
	_nodes_root.add_child(nm)
	_show_card(cur)


func _travel(zi: int) -> void:
	BattleSim.mode = "zone"
	BattleSim.go_to_zone(zi, _diff)
	AudioManager.play("ui_travel")
	refresh()
