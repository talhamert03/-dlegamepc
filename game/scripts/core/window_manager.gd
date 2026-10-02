extends Node
## Owns the main strip window placement and all floating native panel windows.

const STRIP_SIZE := Vector2i(480, 84)
const PANELS := {
	"stats": {"script": "res://scripts/ui/panels/stats_panel.gd", "size": Vector2i(170, 250), "title": "panel_stats"},
	"hero": {"script": "res://scripts/ui/panels/hero_panel.gd", "size": Vector2i(176, 250), "title": "panel_hero"},
	"portrait": {"script": "res://scripts/ui/panels/portrait_panel.gd", "size": Vector2i(150, 250), "title": "panel_portrait"},
	"inventory": {"script": "res://scripts/ui/panels/inventory_panel.gd", "size": Vector2i(176, 250), "title": "panel_inventory"},
	"stash": {"script": "res://scripts/ui/panels/stash_panel.gd", "size": Vector2i(160, 250), "title": "panel_stash"},
	"blacksmith": {"script": "res://scripts/ui/panels/blacksmith_panel.gd", "size": Vector2i(170, 250), "title": "panel_blacksmith"},
	"world": {"script": "res://scripts/ui/panels/world_panel.gd", "size": Vector2i(260, 200), "title": "panel_world"},
	"growth": {"script": "res://scripts/ui/panels/growth_panel.gd", "size": Vector2i(260, 220), "title": "panel_growth"},
	"party": {"script": "res://scripts/ui/panels/party_panel.gd", "size": Vector2i(220, 200), "title": "panel_party"},
	"tavern": {"script": "res://scripts/ui/panels/tavern_panel.gd", "size": Vector2i(220, 200), "title": "panel_tavern"},
	"settings": {"script": "res://scripts/ui/panels/settings_panel.gd", "size": Vector2i(200, 230), "title": "panel_settings"},
	"away": {"script": "res://scripts/ui/panels/away_panel.gd", "size": Vector2i(200, 170), "title": "panel_away"},
	"dps": {"script": "res://scripts/ui/panels/dps_panel.gd", "size": Vector2i(170, 150), "title": "panel_dps"},
	"quests": {"script": "res://scripts/ui/panels/quests_panel.gd", "size": Vector2i(200, 200), "title": "panel_quests"},
	"codex": {"script": "res://scripts/ui/panels/codex_panel.gd", "size": Vector2i(220, 220), "title": "panel_codex"},
	"ending": {"script": "res://scripts/ui/panels/ending_panel.gd", "size": Vector2i(240, 135), "title": "panel_ending"},
	"pets": {"script": "res://scripts/ui/panels/pets_panel.gd", "size": Vector2i(200, 200), "title": "panel_pets"},
}
const GROUPS := {"hero": ["stats", "hero", "portrait"], "bag": ["inventory"], "world": ["world"], "growth": ["growth"]}

var ui_scale: int = 2
var panels: Dictionary = {}
var selected_hero: String = ""
var tooltip: Window = null
var hidden_all := false
var tray: Node = null
var _focus_poll := 0.0
var _any_focused := true


func _ready() -> void:
	get_tree().root.close_requested.connect(_on_root_close)
	get_tree().auto_accept_quit = false
	EventBus.story_completed.connect(func(): open_panel("ending"))


func setup_main_window() -> void:
	var w := get_window()
	ui_scale = compute_scale()
	w.content_scale_size = STRIP_SIZE
	w.size = STRIP_SIZE * ui_scale
	w.always_on_top = bool(Settings.get_v("always_on_top", true))
	w.borderless = true
	w.transparent = true
	place_strip()
	_setup_tray()
	_ensure_tooltip()


func compute_scale() -> int:
	var s := int(Settings.get_v("scale", 0))
	if s > 0:
		return s
	var scr := DisplayServer.window_get_current_screen()
	var h: int = DisplayServer.screen_get_size(scr).y
	if h >= 2000:
		return 3
	if h >= 900:
		return 2
	return 1


func place_strip() -> void:
	var w := get_window()
	var scr := DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(scr)
	var mode: String = Settings.get_v("strip_pos", "taskbar")
	var sx: int = int(Settings.get_v("strip_x", -1))
	var sy: int = int(Settings.get_v("strip_y", -1))
	if mode == "free" and sx >= 0 and sy >= 0:
		w.position = Vector2i(sx, sy)
		return
	var x := usable.position.x + usable.size.x - w.size.x - 24
	var y := usable.position.y + usable.size.y - w.size.y
	if mode == "top":
		y = usable.position.y
	w.position = Vector2i(x, y)


func strip_rect() -> Rect2i:
	var w := get_window()
	return Rect2i(w.position, w.size)


func set_scale(s: int) -> void:
	Settings.set_v("scale", s)
	ui_scale = compute_scale()
	var w := get_window()
	w.size = STRIP_SIZE * ui_scale
	place_strip()
	var ids: Array = panels.keys()
	for id in ids:
		close_panel(id)
	for id in ids:
		open_panel(id)


# ------------------------------------------------------------------ panels
func is_open(id: String) -> bool:
	return panels.has(id) and is_instance_valid(panels[id])


func toggle_group(g: String) -> void:
	var ids: Array = GROUPS.get(g, [g])
	var any_open := false
	for id in ids:
		if is_open(id):
			any_open = true
	if any_open:
		for id in ids:
			close_panel(id)
	else:
		var i := 0
		for id in ids:
			open_panel(id, i, ids.size())
			i += 1


func toggle_panel(id: String) -> void:
	if is_open(id):
		close_panel(id)
	else:
		open_panel(id)


func open_panel(id: String, index := -1, count := 1) -> PanelWindow:
	if is_open(id):
		var p: PanelWindow = panels[id]
		p.grab_focus()
		return p
	if not PANELS.has(id):
		push_warning("unknown panel %s" % id)
		return null
	var info: Dictionary = PANELS[id]
	var scr: Script = load(info["script"])
	if scr == null:
		return null
	var p: PanelWindow = scr.new()
	p.setup(id, DataDB.t(info["title"]), info["size"])
	p.position = _default_pos(id, info["size"], index, count)
	get_tree().root.add_child(p)
	panels[id] = p
	p.show()
	AudioManager.play("ui_open", 0.05, 0.6)
	EventBus.tutorial_step.emit("open_" + id)
	return p


func close_panel(id: String) -> void:
	if not is_open(id):
		panels.erase(id)
		return
	var p: PanelWindow = panels[id]
	panels.erase(id)
	p.queue_free()
	hide_tooltip()
	AudioManager.play("ui_close", 0.05, 0.5)


func refresh_all() -> void:
	for id in panels:
		if is_instance_valid(panels[id]):
			panels[id].refresh()


func _default_pos(id: String, size_l: Vector2i, index: int, count: int) -> Vector2i:
	var saved: Dictionary = Settings.get_v("panel_pos", {})
	if saved.has(id):
		var v: Array = saved[id]
		return Vector2i(int(v[0]), int(v[1]))
	var s := strip_rect()
	var w := size_l * ui_scale
	var y := s.position.y - w.y - 4
	if Settings.get_v("strip_pos", "taskbar") == "top":
		y = s.position.y + s.size.y + 4
	var x: int
	if index >= 0 and count > 1:
		var total := 0
		for gid in GROUPS.values():
			if gid.has(id):
				for pid in gid:
					total += PANELS[pid]["size"].x * ui_scale + 4
				break
		x = s.position.x + s.size.x - total
		var off := 0
		for gid in GROUPS.values():
			if gid.has(id):
				for pid in gid:
					if pid == id:
						break
					off += PANELS[pid]["size"].x * ui_scale + 4
				break
		x += off
	else:
		# stack to the left of already open panels
		x = s.position.x + s.size.x - w.x
		for pid in panels:
			if is_instance_valid(panels[pid]):
				var pr: Window = panels[pid]
				x = min(x, pr.position.x - w.x - 4)
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	x = clamp(x, usable.position.x, usable.end.x - w.x)
	y = clamp(y, usable.position.y, usable.end.y - w.y)
	return Vector2i(x, y)


func panel_moved(p: PanelWindow) -> void:
	var saved: Dictionary = Settings.get_v("panel_pos", {}).duplicate()
	saved[p.panel_id] = [p.position.x, p.position.y]
	Settings.set_v("panel_pos", saved)


func snap_position(p: Window, pos: Vector2i) -> Vector2i:
	var snap := 10
	var rects: Array = [strip_rect()]
	for id in panels:
		var o: Window = panels[id]
		if is_instance_valid(o) and o != p:
			rects.append(Rect2i(o.position, o.size))
	var r := Rect2i(pos, p.size)
	for o: Rect2i in rects:
		if abs(r.position.x - o.end.x) < snap:
			pos.x = o.end.x + 2
		elif abs(r.end.x - o.position.x) < snap:
			pos.x = o.position.x - r.size.x - 2
		if abs(r.end.y - o.position.y) < snap:
			pos.y = o.position.y - r.size.y - 2
		elif abs(r.position.y - o.end.y) < snap:
			pos.y = o.end.y + 2
		if abs(r.position.y - o.position.y) < snap:
			pos.y = o.position.y
	return pos


func reset_layout() -> void:
	Settings.set_v("panel_pos", {})
	var ids: Array = panels.keys()
	for id in ids:
		close_panel(id)


# ------------------------------------------------------------------ tooltip window
func _ensure_tooltip() -> void:
	if tooltip != null:
		return
	tooltip = load("res://scripts/ui/tooltip_window.gd").new()
	get_tree().root.add_child.call_deferred(tooltip)


func show_item_tooltip(item: Dictionary, compare_hero := "") -> void:
	if tooltip:
		tooltip.show_item(item, compare_hero)


func show_text_tooltip(text: String) -> void:
	if tooltip:
		tooltip.show_text(text)


func hide_tooltip() -> void:
	if tooltip:
		tooltip.hide_tip()


# ------------------------------------------------------------------ focus / fps / hotkeys
func _process(delta: float) -> void:
	_focus_poll += delta
	if _focus_poll < 0.3:
		return
	_focus_poll = 0.0
	var f := get_window().has_focus()
	for id in panels:
		if is_instance_valid(panels[id]) and panels[id].has_focus():
			f = true
	if f != _any_focused:
		_any_focused = f
		Engine.max_fps = int(Settings.get_v("fps_focus", 60)) if f else int(Settings.get_v("fps_idle", 15))
		AudioManager.set_focused(f)


func handle_hotkey(ev: InputEventKey) -> void:
	if ev.ctrl_pressed and ev.shift_pressed and ev.keycode == KEY_H:
		toggle_hide_all()
		return
	if ev.ctrl_pressed or ev.alt_pressed:
		return
	match ev.keycode:
		KEY_H, KEY_C:
			toggle_group("hero")
		KEY_I, KEY_B:
			toggle_group("bag")
		KEY_M:
			toggle_group("world")
		KEY_G:
			toggle_group("growth")
		KEY_P:
			toggle_panel("party")
		KEY_T:
			toggle_panel("tavern")
		KEY_J:
			toggle_panel("quests")
		KEY_D:
			toggle_panel("dps")
		KEY_E:
			toggle_panel("pets")


func toggle_hide_all() -> void:
	hidden_all = not hidden_all
	var w := get_window()
	if hidden_all:
		w.mode = Window.MODE_MINIMIZED
	else:
		w.mode = Window.MODE_WINDOWED
		place_strip()
	for id in panels:
		if is_instance_valid(panels[id]):
			panels[id].visible = not hidden_all
	hide_tooltip()


func set_always_on_top(v: bool) -> void:
	Settings.set_v("always_on_top", v)
	get_window().always_on_top = v
	for id in panels:
		if is_instance_valid(panels[id]):
			panels[id].always_on_top = v


func _setup_tray() -> void:
	if tray != null or not ClassDB.class_exists("StatusIndicator"):
		return
	var os_name := OS.get_name()
	if os_name != "Windows" and os_name != "macOS":
		return
	tray = ClassDB.instantiate("StatusIndicator")
	var menu := PopupMenu.new()
	menu.add_item(DataDB.t("tray_show"), 0)
	menu.add_item(DataDB.t("tray_mute"), 1)
	menu.add_separator()
	menu.add_item(DataDB.t("tray_quit"), 2)
	menu.id_pressed.connect(_on_tray_menu)
	tray.add_child(menu)
	tray.set("icon", UITheme.tex("icon"))
	tray.set("tooltip", "Idle Party")
	add_child(tray)
	tray.set("menu", tray.get_path_to(menu))
	if tray.has_signal("pressed"):
		tray.connect("pressed", func(_b, _p): if hidden_all: toggle_hide_all())


func _on_tray_menu(id: int) -> void:
	match id:
		0:
			if hidden_all:
				toggle_hide_all()
			else:
				get_window().grab_focus()
		1:
			Settings.set_v("mute", not Settings.get_v("mute", false))
		2:
			quit_game()


func _on_root_close() -> void:
	quit_game()


func quit_game() -> void:
	GameState.save_game()
	Settings.save_settings()
	get_tree().quit()
