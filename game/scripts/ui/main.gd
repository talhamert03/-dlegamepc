extends Control
## Root of the overlay window. Hosts the battle strip (strip view + control panel + quick buttons);
## WindowManager adds the panel and tooltip layers on top.

var strip_root: Control
var strip: StripView
var cpanel: ControlPanel
var _round: Dictionary = {}
var _notify_box: VBoxContainer
var _auto_btn: TextureButton
var _chest_btn: Button
var _chest_pulse := 0.0
var _t := 0.0


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
	cpanel.position = Vector2(StripView.W, 0)
	strip_root.add_child(cpanel)
	_build_round_buttons()
	_build_chest_button()
	strip.chest_landed.connect(func(_k):
		_chest_pulse = 1.0)
	_notify_box = VBoxContainer.new()
	_notify_box.position = Vector2(190, 12)
	_notify_box.size = Vector2(166, 48)
	_notify_box.alignment = BoxContainer.ALIGNMENT_END
	_notify_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notify_box.z_index = 50
	strip_root.add_child(_notify_box)
	EventBus.notify.connect(_on_notify)
	WindowManager.mini_changed.connect(_on_mini)
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
	if not cmd.has("--screenshot") or cmd.has("--tutorial"):
		Tutorial.start_if_needed(strip_root)
	if cmd.has("--screenshot"):
		_screenshot_mode(cmd)


## Taskbar mode shows only the battlefield: hide the control block, buttons, HUD and notifications.
func _on_mini(on: bool) -> void:
	cpanel.visible = not on
	for k in _round:
		_round[k].visible = not on
	_notify_box.visible = not on
	strip.hud.visible = not on


func _run_title() -> void:
	WindowManager.title_mode = true
	strip_root.visible = false
	var t := TitleScreen.new()
	add_child(t)
	move_child(t, strip_root.get_index() + 1)
	WindowManager.title_control = t
	WindowManager.layout_changed()
	if OS.get_cmdline_user_args().has("--screenshot"):
		await get_tree().create_timer(2.5).timeout
		get_viewport().get_texture().get_image().save_png("user://screenshots/title.png")
		t._start_intro()
		for i in TitleScreen.BEATS.size():
			await get_tree().create_timer(3.2).timeout
			get_viewport().get_texture().get_image().save_png("user://screenshots/intro_%d.png" % i)
			t._bt = TitleScreen.BEAT_LEN
		t._finish()
		await t.finished
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
	var defs := [["red", "town", Vector2(2, 12), "tip_town"], ["green", "dps", Vector2(2, 27), "tip_dps"], ["blue", "auto", Vector2(2, 42), "tip_auto"]]
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


## Pile of found chests under the round buttons: shows the best one held and the count.
func _build_chest_button() -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = Vector2(0, 57)
	b.size = Vector2(19, 15)
	b.z_index = 45
	b.tooltip_text = DataDB.t("tip_chests")
	b.pressed.connect(func():
		var hp := WindowManager.open_panel("hero")
		if hp:
			hp._on_tab(2))
	b.draw.connect(func():
		var bi := Chests.best_index()
		if bi < 0:
			return
		var kind := str(GameState.chests[bi]["k"])
		var s := 1.0 + _chest_pulse * 0.35 + (0.08 if b.is_hovered() else 0.0)
		ChestArt.draw(b, Vector2(9, 13), 13.0 * s, kind, 0.0, _t, false)
		var n := Chests.count()
		if n > 1:
			var f := UITheme.font_body
			b.draw_string_outline(f, Vector2(12, 7), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0, 0, 0, 0.95))
			b.draw_string(f, Vector2(12, 7), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_GOLD))
	strip_root.add_child(b)
	_chest_btn = b


func _process(_d: float) -> void:
	_t += _d
	_chest_pulse = maxf(0.0, _chest_pulse - _d * 2.0)
	if _chest_btn:
		_chest_btn.visible = Chests.count() > 0 and not WindowManager.mini_mode
		_chest_btn.queue_redraw()
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
	for a in cmd:
		if a == "--runes":
			GameState.add_gold(5000000)
			var order: Array = ["core"]
			for br in Runes.branches():
				for k in ["1", "1", "2", "2", "3", "_s1"]:
					order.append(str(br["key"]) + k)
			for id in order:
				Runes.buy(id)
			GameState.gold = 2715147
	for a in cmd:
		if a == "--chests":
			for k in ["wood", "wood", "iron", "gold", "crystal", "royal", "iron"]:
				Chests.add(k, 20)
			get_tree().create_timer(secs - 1.2).timeout.connect(func():
				EventBus.chest_dropped.emit("gold", Vector2(250, BattleSim.GROUND_Y)))
	await get_tree().create_timer(0.5).timeout
	if cmd.has("--town"):
		BattleSim.enter_town()
	if cmd.has("--awaytest"):
		var items: Array = []
		for i in 5:
			items.append(LootSystem.generate(GameState.rng, 10, ["rare", "epic", "magic", "rare", "common"][i], "mage"))
		var ap := WindowManager.open_panel("away")
		ap.set_report({"seconds": 1500, "eff": 0.4, "kills": 250, "xp": 3200.0, "gold": 1800, "item_count": 6,
			"levels": {"lyra": 1, "nova": 1, "pip": 1, "kael": 1}, "items": items})
	for p in panels:
		if p != "":
			WindowManager.open_panel(p)
	await get_tree().create_timer(secs).timeout
	var out := "user://screenshots/"
	DirAccess.make_dir_recursive_absolute(out)
	for a in cmd:
		if a.begins_with("--burst="):
			# strip frames at ~30 fps for checking animation timing
			var sc0: float = WindowManager.ui_scale
			var sr0 := WindowManager.strip_rect()
			for i in int(a.substr(8)):
				await get_tree().process_frame
				await get_tree().create_timer(0.033).timeout
				var im := get_viewport().get_texture().get_image()
				im.get_region(Rect2i(Vector2i(sr0.position * sc0), Vector2i(sr0.size * sc0))).save_png(out + "burst_%03d.png" % i)
	for a in cmd:
		if a == "--mini":
			WindowManager.enter_mini()
			await get_tree().create_timer(0.6).timeout
			EventBus.chest_dropped.emit("crystal", Vector2(250, BattleSim.GROUND_Y))
			await get_tree().create_timer(1.0).timeout
			get_viewport().get_texture().get_image().save_png(out + "mini.png")
			print("SCREENSHOTS_DONE ", ProjectSettings.globalize_path(out))
			get_tree().quit()
			return
		if a.begins_with("--herotab=") and WindowManager.is_open("hero"):
			WindowManager.panels["hero"]._on_tab(int(a.substr(10)))
			await get_tree().create_timer(0.5).timeout
		if a.begins_with("--statustab=") and WindowManager.is_open("stats"):
			WindowManager.panels["stats"]._on_tab(int(a.substr(12)))
			await get_tree().create_timer(0.4).timeout
		if a == "--dragtest" and WindowManager.is_open("hero"):
			var fv: FormationView = null
			for n in WindowManager.panels["hero"].find_children("*", "FormationView", true, false):
				fv = n
			if fv:
				var sc0: float = WindowManager.ui_scale
				var p0: Vector2 = fv.get_global_transform() * fv._slot_rect(0).get_center()
				var p1: Vector2 = fv.get_global_transform() * fv._slot_rect(2).get_center()
				Input.warp_mouse(p0 * sc0)
				var ev := InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = true
				ev.position = p0 * sc0
				ev.global_position = p0 * sc0
				Input.parse_input_event(ev)
				for k in 10:
					await get_tree().process_frame
					var mv := InputEventMouseMotion.new()
					var q: Vector2 = p0.lerp(p1 + Vector2(0, -8), (k + 1) / 10.0) * sc0
					mv.position = q
					mv.global_position = q
					mv.button_mask = MOUSE_BUTTON_MASK_LEFT
					Input.warp_mouse(q)
					Input.parse_input_event(mv)
				await get_tree().create_timer(0.3).timeout
		if a.begins_with("--shoptab=") and WindowManager.is_open("shop"):
			WindowManager.panels["shop"]._tab = a.substr(10)
			WindowManager.panels["shop"].refresh()
			await get_tree().create_timer(0.4).timeout
		if a == "--bagdrag" and WindowManager.is_open("hero"):
			var slots: Array = []
			for n in WindowManager.panels["hero"].find_children("*", "ItemSlot", true, false):
				if n.source == "bag" and n.is_visible_in_tree():
					slots.append(n)
			if slots.size() > 8:
				var sc2: float = WindowManager.ui_scale
				var q0: Vector2 = slots[0].get_global_transform_with_canvas() * (slots[0].size * 0.3)
				var tgt: Control = slots[mini(45, slots.size() - 1)] if cmd.has("--bagdrop") else slots[8]
				var q1: Vector2 = tgt.get_global_transform_with_canvas() * (tgt.size * 0.5)
				var pe := InputEventMouseButton.new()
				pe.button_index = MOUSE_BUTTON_LEFT
				pe.pressed = true
				pe.position = q0 * sc2
				pe.global_position = q0 * sc2
				Input.warp_mouse(q0 * sc2)
				Input.parse_input_event(pe)
				for k in 10:
					await get_tree().process_frame
					var mv2 := InputEventMouseMotion.new()
					var q: Vector2 = q0.lerp(q1, (k + 1) / 10.0) * sc2
					mv2.position = q
					mv2.global_position = q
					mv2.button_mask = MOUSE_BUTTON_MASK_LEFT
					Input.warp_mouse(q)
					Input.parse_input_event(mv2)
				if cmd.has("--bagdrop"):
					await get_tree().process_frame
					var re := InputEventMouseButton.new()
					re.button_index = MOUSE_BUTTON_LEFT
					re.pressed = false
					re.position = q1 * sc2
					re.global_position = q1 * sc2
					Input.parse_input_event(re)
				await get_tree().create_timer(0.3).timeout
		if a == "--selldlg" and WindowManager.is_open("hero"):
			WindowManager.panels["hero"]._sell_dialog()
			await get_tree().create_timer(0.3).timeout
		if a == "--chestopen" and WindowManager.is_open("chests"):
			WindowManager.panels["chests"]._on_open()
			await get_tree().create_timer(1.0).timeout
	for a in cmd:
		if a.begins_with("--fxtest="):
			var sc1: float = WindowManager.ui_scale
			var sr1 := WindowManager.strip_rect()
			var kinds := a.substr(9).split(",")
			if kinds[0] == "all":
				kinds = PackedStringArray(SkillFx.KINDS.keys())
			for kname in kinds:
				var ally := kname in ["aegis", "sanctuary", "anthem"]
				var pts: Array = [Vector2(196, 64), Vector2(166, 64), Vector2(136, 64)] if ally else [Vector2(250, 64), Vector2(285, 64), Vector2(320, 64)]
				var fx := SkillFx.new()
				fx.setup(kname, Vector2(166, 64), pts)
				strip.fx_root.add_child(fx)
				for k in 3:
					var wait_s: float = fx.life * (0.22 if k == 0 else 0.25)
					await get_tree().create_timer(wait_s).timeout
					await RenderingServer.frame_post_draw
					var im := get_viewport().get_texture().get_image()
					im.get_region(Rect2i(Vector2i(sr1.position * sc1), Vector2i(Vector2(360, 72) * sc1))).save_png(out + "fx_%s_%d.png" % [kname, k])
				await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + "screen.png")
	var sc: float = WindowManager.ui_scale
	var sr := WindowManager.strip_rect()
	img.get_region(Rect2i(Vector2i(sr.position * sc), Vector2i(sr.size * sc))).save_png(out + "strip.png")
	for id in WindowManager.panels:
		var w: Control = WindowManager.panels[id]
		if is_instance_valid(w):
			img.get_region(Rect2i(Vector2i(w.position * sc), Vector2i(w.size * sc))).save_png(out + "panel_%s.png" % id)
	print("SCREENSHOTS_DONE ", ProjectSettings.globalize_path(out))
	get_tree().quit()
