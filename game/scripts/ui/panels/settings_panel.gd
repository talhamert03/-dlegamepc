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
		refresh())
	v.add_child(_tabs)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 16))
	v.add_child(sc)
	_body = W.vbox(2)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	match tab:
		0:
			_choice("set_lang", "lang", ["tr", "en"], ["Türkçe", "English"])
			_choice("set_scale", "scale", [0, 2, 3, 4, 5], [DataDB.t("auto"), "2x", "3x", "4x", "5x"], func(v): WindowManager.set_scale(int(v)))
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
			_toggle("set_on_top", "always_on_top", func(v): WindowManager.set_always_on_top(v))
			_toggle("set_mini_mode", "mini_mode")
			_toggle("set_remember_panels", "remember_panels")
			_choice("set_fps_idle", "fps_idle", [5, 10, 15, 30], ["5", "10", "15", "30"])
			_choice("set_fps_focus", "fps_focus", [30, 60, 144], ["30", "60", "144"])
			_choice("set_dmg_numbers", "dmg_numbers", [0, 1, 2], [DataDB.t("off"), DataDB.t("crits"), DataDB.t("all")])
			_toggle("set_shake", "screen_shake")
			_choice("set_particles", "particles", [0.0, 0.5, 1.0], [DataDB.t("off"), DataDB.t("low"), DataDB.t("high")])
			_body.add_child(UITheme.button(DataDB.t("reset_layout"), "brown", func(): WindowManager.reset_layout()))
		1:
			_slider("set_master", "vol_master")
			_slider("set_music", "vol_music")
			_slider("set_sfx", "vol_sfx")
			_slider("set_duck", "unfocus_duck")
			_toggle("set_mute", "mute")
		2:
			_choice("set_barks", "barks", [0, 1, 2], [DataDB.t("off"), DataDB.t("few"), DataDB.t("normal")])
			_toggle("set_tutorial", "tutorial_done")
			_body.add_child(UITheme.label(DataDB.t("hotkeys_help"), UITheme.C_DIM))
			var save_b := UITheme.button(DataDB.t("btn_save_now"), "blue", func():
				GameState.save_game()
				EventBus.notify.emit(DataDB.t("saved"), UITheme.C_GREEN))
			_body.add_child(save_b)
			_body.add_child(UITheme.button(DataDB.t("tip_quit"), "red", func(): WindowManager.ask_quit()))


func _row(label: String, color: Color = UITheme.C_TEXT) -> HBoxContainer:
	var h := W.hbox(2)
	var l := UITheme.label(label, color)
	l.custom_minimum_size = Vector2(70, 0)
	l.clip_text = true
	h.add_child(l)
	_body.add_child(h)
	return h


func _choice(key_label: String, key: String, vals: Array, names: Array, cb: Callable = Callable()) -> void:
	_choice_label(DataDB.t(key_label), UITheme.C_TEXT, key, vals, names, cb)


func _choice_label(label: String, color: Color, key: String, vals: Array, names: Array, cb: Callable = Callable()) -> void:
	var h := _row(label, color)
	var cur: Variant = Settings.get_v(key)
	for i in vals.size():
		var v: Variant = vals[i]
		var active := str(cur) == str(v)
		var b := UITheme.button(str(names[i]), "orange" if active else "brown", func():
			Settings.set_v(key, v)
			if cb.is_valid():
				cb.call(v)
			refresh(), Vector2(0, 11))
		h.add_child(b)


func _toggle(key_label: String, key: String, cb: Callable = Callable()) -> void:
	var h := _row(DataDB.t(key_label))
	var on: bool = bool(Settings.get_v(key, false))
	var b := UITheme.button(DataDB.t("on") if on else DataDB.t("off"), "green" if on else "gray", func():
		Settings.set_v(key, not on)
		if cb.is_valid():
			cb.call(not on)
		refresh(), Vector2(26, 11))
	h.add_child(b)


func _slider(key_label: String, key: String) -> void:
	var h := _row(DataDB.t(key_label))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.get_v(key, 0.5))
	s.custom_minimum_size = Vector2(80, 10)
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v): Settings.set_v(key, v))
	h.add_child(s)
