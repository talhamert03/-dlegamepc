extends Control
## Root of the overlay window. Hosts the battle strip (strip view + control panel + quick buttons);
## WindowManager adds the panel and tooltip layers on top.

var strip_root: Control
var strip: StripView
var cpanel: ControlPanel
var _round: Dictionary = {}
var _notify_box: VBoxContainer
var _auto_btn: TextureButton


func _ready() -> void:
	theme = UITheme.theme
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_root = Control.new()
	strip_root.name = "Strip"
	strip_root.size = Vector2(WindowManager.STRIP_SIZE)
	strip_root.clip_contents = true
	strip_root.mouse_filter = Control.MOUSE_FILTER_PASS
	strip_root.gui_input.connect(_on_strip_input)
	add_child(strip_root)
	WindowManager.setup_overlay(self, strip_root)
	strip = StripView.new()
	strip_root.add_child(strip)
	cpanel = ControlPanel.new()
	cpanel.position = Vector2(400, 0)
	strip_root.add_child(cpanel)
	_build_round_buttons()
	_notify_box = VBoxContainer.new()
	_notify_box.position = Vector2(230, 14)
	_notify_box.size = Vector2(168, 60)
	_notify_box.alignment = BoxContainer.ALIGNMENT_END
	_notify_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notify_box.z_index = 50
	strip_root.add_child(_notify_box)
	EventBus.notify.connect(_on_notify)
	get_viewport().size_changed.connect(func():
		size = get_viewport().get_visible_rect().size)
	call_deferred("_boot")


func _boot() -> void:
	var cmd := OS.get_cmdline_user_args()
	if cmd.has("--title") or (not cmd.has("--fresh") and not GameState.has_save()):
		await _run_title()
		GameState.new_game()
		Settings.set_v("tutorial_done", false)
	elif cmd.has("--fresh"):
		GameState.new_game()
	elif not GameState.load_game():
		GameState.new_game()
	Quests.ensure_daily()
	var away := OfflineSim.apply()
	BattleSim.start()
	if away.get("seconds", 0) >= 120:
		var p := WindowManager.open_panel("away")
		if p and p.has_method("set_report"):
			p.set_report(away)
	Tutorial.start_if_needed(strip_root)
	if cmd.has("--screenshot"):
		_screenshot_mode(cmd)


func _run_title() -> void:
	WindowManager.title_mode = true
	strip_root.visible = false
	var t := TitleScreen.new()
	t.position = ((size - Vector2(TitleScreen.SIZE)) / 2.0).round()
	add_child(t)
	move_child(t, strip_root.get_index() + 1)
	WindowManager.title_control = t
	WindowManager.layout_changed()
	if OS.get_cmdline_user_args().has("--screenshot"):
		await get_tree().create_timer(2.0).timeout
		get_viewport().get_texture().get_image().save_png("user://screenshots/title.png")
		t._start_intro()
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png("user://screenshots/intro.png")
		t._finish()
	else:
		await t.finished
	WindowManager.title_mode = false
	WindowManager.title_control = null
	WindowManager.close_panel("settings")
	strip_root.visible = true
	strip_root.modulate.a = 0.0
	WindowManager.place_strip()
	var tw := create_tween()
	tw.tween_property(strip_root, "modulate:a", 1.0, 0.5)
	WindowManager.layout_changed()


func _build_round_buttons() -> void:
	var defs := [["red", "town", Vector2(2, 14), "tip_town"], ["green", "dps", Vector2(2, 30), "tip_dps"], ["blue", "auto", Vector2(2, 46), "tip_auto"]]
	for d in defs:
		var b := UITheme.round_button(d[0], d[1])
		b.position = d[2]
		b.tooltip_text = DataDB.t(d[3])
		b.z_index = 45
		strip_root.add_child(b)
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
	l.add_theme_color_override("font_outline_color", Color("#0B0D14"))
	l.add_theme_constant_override("outline_size", 3)
	_notify_box.add_child(l)
	while _notify_box.get_child_count() > 3:
		_notify_box.get_child(0).queue_free()
		_notify_box.remove_child(_notify_box.get_child(0))
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func _input(ev: InputEvent) -> void:
	# clicking anywhere on a panel raises it
	if ev is InputEventMouseButton and ev.pressed and WindowManager.panels_layer:
		var m := get_local_mouse_position()
		var layer := WindowManager.panels_layer
		for i in range(layer.get_child_count() - 1, -1, -1):
			var p := layer.get_child(i) as Control
			if p and p.visible and Rect2(p.position, p.size).has_point(m):
				if i != layer.get_child_count() - 1:
					p.move_to_front()
				break


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		WindowManager.handle_hotkey(ev)


## Drag the strip with the left or right mouse button on any empty part of the battlefield.
func _on_strip_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev.button_index == MOUSE_BUTTON_LEFT or ev.button_index == MOUSE_BUTTON_RIGHT):
		if ev.pressed:
			_drag = true
			_drag_moved = false
			_drag_start = get_local_mouse_position()
			_drag_off = _drag_start - strip_root.position
		elif _drag:
			_drag = false
			if _drag_moved:
				Settings.set_v("strip_pos", "free")
				Settings.set_v("strip_lx", strip_root.position.x)
				Settings.set_v("strip_ly", strip_root.position.y)
	elif ev is InputEventMouseMotion and _drag:
		var m := get_local_mouse_position()
		if not _drag_moved and (m - _drag_start).length() < 3.0:
			return
		_drag_moved = true
		strip_root.position = WindowManager.clamp_to_area(m - _drag_off, strip_root.size)
		WindowManager.layout_changed()


var _drag := false
var _drag_moved := false
var _drag_off := Vector2.ZERO
var _drag_start := Vector2.ZERO


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
		if a.begins_with("--pets="):
			for pid in a.substr(7).split(","):
				GameState.grant_pet(pid)
				GameState.grant_pet(pid)
	for a in cmd:
		if a.begins_with("--costume="):
			GameState.flags["costumes"] = Costumes.defs().keys()
			for h in GameState.heroes.values():
				h.costume = a.substr(10)
			BattleSim.build_party()
			EventBus.party_changed.emit()
	for a in cmd:
		if a == "--ending":
			EventBus.story_completed.emit()
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
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + "screen.png")
	var sc: int = WindowManager.ui_scale
	var sr := WindowManager.strip_rect()
	img.get_region(Rect2i(Vector2i(sr.position) * sc, Vector2i(sr.size) * sc)).save_png(out + "strip.png")
	for id in WindowManager.panels:
		var w: Control = WindowManager.panels[id]
		if is_instance_valid(w):
			img.get_region(Rect2i(Vector2i(w.position) * sc, Vector2i(w.size) * sc)).save_png(out + "panel_%s.png" % id)
	print("SCREENSHOTS_DONE ", ProjectSettings.globalize_path(out))
	get_tree().quit()
