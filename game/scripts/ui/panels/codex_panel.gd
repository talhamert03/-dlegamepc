extends PanelWindow
## Achievements and bestiary.

var tab := 0
var _tabs: HBoxContainer
var _body: VBoxContainer


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("tab_achievements"), DataDB.t("tab_bestiary")], tab, func(i):
		tab = i
		W.set_tab_active(_tabs, i)
		refresh())
	v.add_child(_tabs)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 16))
	v.add_child(sc)
	_body = W.vbox(1)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	if tab == 0:
		var done := GameState.achievements.size()
		_body.add_child(UITheme.label("%d / %d" % [done, DataDB.achievements.size()], UITheme.C_GOLD))
		for a in DataDB.achievements:
			var got: bool = GameState.achievements.has(a["id"])
			var row := W.hbox(2)
			var ic := W.icon_rect(UITheme.icon("star" if got else "lock"))
			ic.custom_minimum_size = Vector2(8, 8)
			row.add_child(ic)
			var l := UITheme.label(DataDB.tx(a["name"]), UITheme.C_GOLD if got else UITheme.C_TEXT)
			l.custom_minimum_size = Vector2(80, 0)
			l.clip_text = true
			row.add_child(l)
			var d := UITheme.label(DataDB.tx(a.get("desc", {})), UITheme.C_DIM)
			d.clip_text = true
			d.custom_minimum_size = Vector2(110, 0)
			row.add_child(d)
			_body.add_child(row)
	else:
		var seen: Dictionary = GameState.codex.get("enemies", {})
		_body.add_child(UITheme.label("%d / %d" % [seen.size(), DataDB.enemies.size() + DataDB.bosses.size()], UITheme.C_GOLD))
		var g := W.grid(10, 1)
		_body.add_child(g)
		for eid in DataDB.enemies.keys() + DataDB.bosses.keys():
			var t := TextureRect.new()
			t.custom_minimum_size = Vector2(20, 20)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var sf := SpriteLib.frames_for("enemy", eid)
			if sf and sf.has_animation("idle"):
				t.texture = sf.get_frame_texture("idle", 0)
			var d2 := DataDB.enemy_def(eid)
			if seen.has(eid):
				t.tooltip_text = "%s  x%d" % [DataDB.tx(d2.get("name", {})), int(seen[eid])]
			else:
				t.modulate = Color(0, 0, 0, 0.7)
				t.tooltip_text = "???"
			g.add_child(t)
