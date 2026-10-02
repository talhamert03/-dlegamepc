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
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	var top := W.hbox(2)
	v.add_child(top)
	_diff_btn = UITheme.button("", "gold", _cycle_diff, Vector2(60, 12))
	top.add_child(_diff_btn)
	top.add_child(W.spacer(8, 0))
	_tabs = W.hbox(1)
	top.add_child(_tabs)
	for i in range(1, 5):
		var a := i
		var b := UITheme.button(DataDB.t("act_n", {"n": i}), "brown", func(): _set_act(a), Vector2(38, 12))
		_tabs.add_child(b)
	_map = TextureRect.new()
	_map.custom_minimum_size = Vector2(240, 150)
	_map.stretch_mode = TextureRect.STRETCH_KEEP
	v.add_child(_map)
	_nodes_root = Control.new()
	_nodes_root.size = Vector2(240, 150)
	_map.add_child(_nodes_root)
	EventBus.zone_changed.connect(func(_z): refresh())
	EventBus.zone_unlocked.connect(func(_z): refresh())
	refresh()


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
			var m := TextureRect.new()
			m.texture = SpriteLib.hero_icon(GameState.party[0] if GameState.party[0] != "" else "kael")
			m.position = b.position + Vector2(-4, -18)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_nodes_root.add_child(m)
	var nm := UITheme.label(DataDB.tx(DataDB.acts[act - 1]["name"]) if act - 1 < DataDB.acts.size() else "", Color("#3A2A22"))
	nm.position = Vector2(8, 6)
	_nodes_root.add_child(nm)


func _travel(zi: int) -> void:
	BattleSim.go_to_zone(zi, _diff)
	AudioManager.play("ui_travel")
	refresh()
