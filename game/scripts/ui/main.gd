extends Control
## Root of the main (strip) window: battle strip + control panel + quick buttons.

var strip: StripView
var cpanel: ControlPanel
var _round: Dictionary = {}
var _notify_box: VBoxContainer
var _auto_btn: TextureButton


func _ready() -> void:
	theme = UITheme.theme
	size = Vector2(WindowManager.STRIP_SIZE)
	WindowManager.setup_main_window()
	strip = StripView.new()
	add_child(strip)
	cpanel = ControlPanel.new()
	cpanel.position = Vector2(400, 0)
	add_child(cpanel)
	_build_round_buttons()
	_notify_box = VBoxContainer.new()
	_notify_box.position = Vector2(230, 14)
	_notify_box.size = Vector2(168, 60)
	_notify_box.alignment = BoxContainer.ALIGNMENT_END
	_notify_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notify_box.z_index = 50
	add_child(_notify_box)
	EventBus.notify.connect(_on_notify)
	call_deferred("_boot")


func _boot() -> void:
	var cmd := OS.get_cmdline_user_args()
	if cmd.has("--fresh"):
		GameState.new_game()
	elif not GameState.load_game():
		GameState.new_game()
		Settings.set_v("tutorial_done", false)
	var away := OfflineSim.apply()
	BattleSim.start()
	if away.get("seconds", 0) >= 120:
		var p := WindowManager.open_panel("away")
		if p and p.has_method("set_report"):
			p.set_report(away)
	Tutorial.start_if_needed(self)
	if cmd.has("--screenshot"):
		_screenshot_mode(cmd)


func _build_round_buttons() -> void:
	var defs := [["red", "town", Vector2(2, 14), "tip_town"], ["green", "dps", Vector2(2, 30), "tip_dps"], ["blue", "auto", Vector2(2, 46), "tip_auto"]]
	for d in defs:
		var b := TextureButton.new()
		b.texture_normal = UITheme.tex("round_%s_normal" % d[0])
		b.texture_hover = UITheme.tex("round_%s_hover" % d[0])
		b.texture_pressed = UITheme.tex("round_%s_pressed" % d[0])
		b.position = d[2]
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = DataDB.t(d[3])
		b.z_index = 45
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(b)
		_round[d[1]] = b
	_round["town"].pressed.connect(_on_town)
	_round["dps"].pressed.connect(func(): WindowManager.toggle_panel("dps"))
	_round["auto"].pressed.connect(_on_auto)
	_auto_btn = _round["auto"]
	_update_auto()


func _process(_d: float) -> void:
	if _auto_btn and GameState.progress.get("auto", true):
		_auto_btn.pivot_offset = Vector2(7, 7)
	_round["town"].modulate = Color(1.3, 1.3, 1.0) if BattleSim.phase == "town" else Color.WHITE


func _on_town() -> void:
	if BattleSim.phase == "town":
		BattleSim.leave_town()
	else:
		BattleSim.enter_town()
		WindowManager.toggle_panel("tavern")


func _on_auto() -> void:
	GameState.progress["auto"] = not GameState.progress.get("auto", true)
	_update_auto()
	EventBus.notify.emit(DataDB.t("auto_on") if GameState.progress["auto"] else DataDB.t("auto_off"), UITheme.C_BLUE)


func _update_auto() -> void:
	_auto_btn.modulate = Color.WHITE if GameState.progress.get("auto", true) else Color(0.55, 0.55, 0.6)


func _on_notify(text: String, color: Color) -> void:
	var l := UITheme.label(text, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_color_override("font_outline_color", Color("#140E10"))
	l.add_theme_constant_override("outline_size", 2)
	_notify_box.add_child(l)
	while _notify_box.get_child_count() > 3:
		_notify_box.get_child(0).queue_free()
		_notify_box.remove_child(_notify_box.get_child(0))
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		WindowManager.handle_hotkey(ev)
	# drag the strip with the middle or right mouse button on empty battle area
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT:
		if ev.pressed:
			_drag = true
			_drag_off = DisplayServer.mouse_get_position() - get_window().position
		else:
			_drag = false
			Settings.set_v("strip_pos", "free")
			Settings.set_v("strip_x", get_window().position.x)
			Settings.set_v("strip_y", get_window().position.y)
	if ev is InputEventMouseMotion and _drag:
		get_window().position = DisplayServer.mouse_get_position() - _drag_off


var _drag := false
var _drag_off := Vector2i.ZERO


# ------------------------------------------------------------------ automated screenshots (CI / docs)
func _screenshot_mode(cmd: PackedStringArray) -> void:
	var secs := 6.0
	for a in cmd:
		if a.begins_with("--secs="):
			secs = float(a.substr(7))
	var panels: Array = []
	for a in cmd:
		if a.begins_with("--open="):
			panels = a.substr(7).split(",")
	for a in cmd:
		if a.begins_with("--hour="):
			TimeService.override_hour = float(a.substr(7))
	for a in cmd:
		if a.begins_with("--zone="):
			BattleSim.go_to_zone(int(a.substr(7)))
	for a in cmd:
		if a.begins_with("--level="):
			for h in GameState.heroes.values():
				h.level = int(a.substr(8))
			GameState.invalidate_stats()
			BattleSim.refresh_hero_stats()
	for a in cmd:
		if a == "--allheroes":
			for hid in DataDB.hero_order.slice(0, 12):
				GameState.unlock_hero(hid, false)
			GameState.party = ["kael", "lyra", "pip", "nova", "bjorn"]
			for hid in GameState.party:
				GameState.unlock_hero(hid, false)
			EventBus.party_changed.emit()
	for a in cmd:
		if a == "--loot":
			for i in 40:
				var r: String = ["rare", "epic", "legendary", "set", "magic"][i % 5]
				var it := LootSystem.generate(GameState.rng, 20, r, ["knight", "archer", "cleric", "mage", "berserker"][i % 5])
				GameState.bag.append(it)
			EventBus.inventory_changed.emit()
	await get_tree().create_timer(0.5).timeout
	for p in panels:
		if p != "":
			WindowManager.open_panel(p)
	await get_tree().create_timer(secs).timeout
	var out := "user://screenshots/"
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png(out + "strip.png")
	for id in WindowManager.panels:
		var w: Window = WindowManager.panels[id]
		if is_instance_valid(w):
			w.get_texture().get_image().save_png(out + "panel_%s.png" % id)
	print("SCREENSHOTS_DONE ", ProjectSettings.globalize_path(out))
	get_tree().quit()
