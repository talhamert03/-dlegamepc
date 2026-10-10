extends PanelWindow
## Settings: display, sound, gameplay, loot filter, system.

var tab := 0
var _tabs: HBoxContainer
var _body: VBoxContainer


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("set_display"), DataDB.t("set_sound"), DataDB.t("set_game")], tab, func(i):
		tab = i
		W.set_tab_active(_tabs, i)
		refresh(), (c.size.x - 4.0) / 3.0)
	v.add_child(_tabs)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 16))
	v.add_child(sc)
	_body = W.vbox(1)
	_body.custom_minimum_size = Vector2(c.size.x - 8, 0)
	sc.add_child(_body)
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	match tab:
		0:
			_section("set_sec_view")
			_choice("set_lang", "lang", ["tr", "en"], ["Türkçe", "English"])
			# only offer scales that fit this screen (a 1080p screen tops out at 2x)
			var sv: Array = [0]
			var sn: Array = [DataDB.t("auto")]
			for k in [2, 3, 4, 5]:
				if float(k) <= WindowManager.max_fit_scale():
					sv.append(k)
					sn.append("%dx" % k)
			_choice("set_scale", "scale", sv, sn, func(v): WindowManager.set_scale(int(v)))
			_choice("set_strip_pos", "strip_pos", ["taskbar", "top", "free"], [DataDB.t("pos_taskbar"), DataDB.t("pos_top"), DataDB.t("pos_free")],
				func(_v): WindowManager.place_strip())
			var nscr := DisplayServer.get_screen_count()
			if nscr > 1:
				var vals: Array = [-1]
				var names: Array = [DataDB.t("auto")]
				for i in nscr:
					vals.append(i)
					names.append(str(i + 1))
				_choice("set_screen", "screen", vals, names, func(v): WindowManager.set_screen(int(v)))
			_section("set_sec_window")
			_toggle("set_on_top", "always_on_top", func(v): WindowManager.set_always_on_top(v))
			_toggle("set_mini_mode", "mini_mode")
			_toggle("set_remember_panels", "remember_panels")
			_section("set_sec_perf")
			_choice("set_fps_idle", "fps_idle", [5, 10, 15, 30], ["5", "10", "15", "30"])
			_choice("set_fps_focus", "fps_focus", [30, 60, 144], ["30", "60", "144"])
			_section("set_sec_fx")
			_choice("set_dmg_numbers", "dmg_numbers", [0, 1, 2], [DataDB.t("off"), DataDB.t("crits"), DataDB.t("all")])
			_toggle("set_shake", "screen_shake")
			_toggle("set_colorblind", "colorblind", func(_v): get_tree().call_group("item_slots", "queue_redraw"))
			_choice("set_particles", "particles", [0.0, 0.5, 1.0], [DataDB.t("off"), DataDB.t("low"), DataDB.t("high")])
			_gap()
			_wide_button(DataDB.t("reset_layout"), "brown", func(): WindowManager.reset_layout())
		1:
			_section("set_sec_audio")
			_slider("set_master", "vol_master")
			_slider("set_music", "vol_music")
			_slider("set_sfx", "vol_sfx")
			_slider("set_duck", "unfocus_duck")
			_toggle("set_mute", "mute")
		2:
			_section("set_sec_game")
			_choice("set_barks", "barks", [0, 1, 2], [DataDB.t("off"), DataDB.t("few"), DataDB.t("normal")])
			_toggle("set_tutorial", "tutorial_done")
			_gap()
			_wide_button(DataDB.t("btn_replay_intro"), "orange", func():
				var m := get_tree().current_scene
				if m and m.has_method("replay_intro"):
					m.replay_intro())
			_section("set_sec_keys")
			_body.add_child(_hotkey_grid(DataDB.t("hotkeys_help"), _w() - 4))
			_section("set_sec_system")
			_toggle("set_steam_cloud", "steam_cloud")
			var cs := UITheme.para(DataDB.t("cloud_on") if SteamService.cloud_enabled() else DataDB.t("cloud_off"), _w() - 8,
				UITheme.C_GREEN if SteamService.cloud_enabled() else UITheme.C_DIM)
			var cm := MarginContainer.new()
			cm.add_theme_constant_override("margin_left", 4)
			cm.add_child(cs)
			_body.add_child(cm)
			_wide_button(DataDB.t("btn_save_now"), "blue", func():
				GameState.save_game()
				EventBus.notify.emit(DataDB.t("saved"), UITheme.C_GREEN))
			_wide_button(DataDB.t("tip_quit"), "red", func(): WindowManager.ask_quit())


func _w() -> float:
	return _body.custom_minimum_size.x


func _section(key: String) -> void:
	_body.add_child(Fancy.section(DataDB.t(key), _w()))


func _gap() -> void:
	_body.add_child(W.spacer(0, 3))


func _wide_button(text: String, color: String, cb: Callable) -> void:
	var b := UITheme.button(text, color, cb, Vector2(_w() - 8, 14))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 4)
	m.add_child(b)
	_body.add_child(m)


func _choice(key_label: String, key: String, vals: Array, names: Array, cb: Callable = Callable()) -> void:
	_choice_label(DataDB.t(key_label), UITheme.C_TEXT, key, vals, names, cb)


func _choice_label(label: String, _color: Color, key: String, vals: Array, names: Array, cb: Callable = Callable()) -> void:
	var cur: Variant = Settings.get_v(key)
	var idx := 0
	for i in vals.size():
		if str(cur) == str(vals[i]):
			idx = i
	var seg := Fancy.segmented(names, idx, func(i: int):
		Settings.set_v(key, vals[i])
		if cb.is_valid():
			cb.call(vals[i])
		refresh())
	_body.add_child(Fancy.row(label, _w(), seg))


func _toggle(key_label: String, key: String, cb: Callable = Callable()) -> void:
	var on: bool = bool(Settings.get_v(key, false))
	var t := Fancy.toggle(on, func(v: bool):
		Settings.set_v(key, v)
		if cb.is_valid():
			cb.call(v)
		refresh())
	_body.add_child(Fancy.row(DataDB.t(key_label), _w(), t))


func _slider(key_label: String, key: String) -> void:
	var s := Fancy.slider(float(Settings.get_v(key, 0.5)), func(v: float): Settings.set_v(key, v), 92.0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(112, 11)
	holder.add_child(s)
	s.position = Vector2.ZERO
	s.size = s.custom_minimum_size
	_body.add_child(Fancy.row(DataDB.t(key_label), _w(), holder))


## Shortcuts as a two-column list of key caps + what they open (the help string is "keys label · keys label").
func _hotkey_grid(help: String, w: float) -> Control:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 2)
	var colw := (w - 6.0) / 2.0
	for part in help.split(" · "):
		var toks := part.split(" ")
		var keys: Array = []
		var i := 0
		while i < toks.size() and (toks[i].length() <= 3 or "+" in toks[i] or toks[i] == "/"):
			if toks[i] != "/":
				keys.append(toks[i])
			i += 1
		var label := " ".join(toks.slice(i))
		if label != "":
			label = UITheme.upper(label.left(1)) + label.substr(1)
		g.add_child(_hotkey_row(keys, label, colw))
	return g


func _hotkey_row(keys: Array, label: String, w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 12)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var fb := UITheme.font_body
		var x := 0.0
		for k in keys:
			var kt := str(k)
			var kw := maxf(10.0, fb.get_string_size(kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 6.0)
			var kr := Rect2(x, 1, kw, 10)
			# a key cap: dark base, lighter top face, bronze edge
			UISkin.fill(ci, kr, 2, Color("#1A120C"), Color("#0A0604"))
			UISkin.fill(ci, Rect2(kr.position + Vector2(1, 0.6), kr.size - Vector2(2, 2.6)), 1.5, Color("#5A4632"), Color("#3A2A1C"))
			UISkin.stroke(ci, kr, 2, Color(UISkin.BRONZE, 0.7), 0.6)
			var tw := fb.get_string_size(kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			c.draw_string(fb, Vector2(kr.position.x + (kw - tw) / 2.0, 8.0), kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#FFE7B0"))
			x += kw + 2.0
		var fs := 8 if fb.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= w - x - 4.0 else 7
		c.draw_string(fb, Vector2(x + 3.0, 9.0), label, HORIZONTAL_ALIGNMENT_LEFT, w - x - 4.0, fs, UITheme.C_TEXT))
	return c
