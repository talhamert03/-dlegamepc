extends Node
## Owns the main strip window placement and all floating native panel windows.

const STRIP_SIZE := Vector2i(480, 84)
const MAX_PANEL_H := 250
const GAP := 2   # logical pixels between panels / strip
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
var title_mode := false   # true while the title screen is shown


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
	# window managers may re-centre a window when it is first mapped: place it again once shown
	get_tree().create_timer(0.15).timeout.connect(func():
		if not title_mode:
			place_strip())
	_setup_tray()
	_ensure_tooltip()


## Largest integer scale where the strip fits ~80% of the screen width and a full-height panel fits
## above it (pixel art stays crisp). 1920x1080/1200 -> 3x, 2560x1440 -> 4x, 1366x768 -> 2x.
func compute_scale() -> int:
	var s := int(Settings.get_v("scale", 0))
	if s > 0:
		return s
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var best := 1
	for k in range(1, 7):
		var fits_w: bool = STRIP_SIZE.x * k <= int(usable.size.x * 0.8)
		var fits_h: bool = (STRIP_SIZE.y + MAX_PANEL_H + 6) * k <= usable.size.y
		if fits_w and fits_h:
			best = k
	return best


func place_strip() -> void:
	var w := get_window()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var mode: String = Settings.get_v("strip_pos", "taskbar")
	var sx: int = int(Settings.get_v("strip_x", -1))
	var sy: int = int(Settings.get_v("strip_y", -1))
	if mode == "free" and sx >= 0 and sy >= 0:
		w.position = clamp_to_screen(Vector2i(sx, sy), w.size)
		return
	# centered just above the taskbar (or at the top), never covering it
	var x := usable.position.x + (usable.size.x - w.size.x) / 2
	var y := usable.position.y + usable.size.y - w.size.y
	if mode == "top":
		y = usable.position.y
	w.position = Vector2i(x, y)


func clamp_to_screen(pos: Vector2i, sz: Vector2i) -> Vector2i:
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	return Vector2i(clampi(pos.x, usable.position.x, max(usable.position.x, usable.end.x - sz.x)),
		clampi(pos.y, usable.position.y, max(usable.position.y, usable.end.y - sz.y)))


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
		p.move_to_foreground()
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
	p.move_to_foreground()
	p.grab_focus()
	var want := p.position
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(p) and p.position != want and not p._dragging:
			p.position = want)
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


## Default home of every panel, in logical pixels relative to the strip's top-left corner (panels sit
## above the strip, bottom-aligned). Groups open side by side; reopening a panel brings it back here.
const HOME := {
	# hero group, centred over the strip
	"stats": "group", "hero": "group", "portrait": "group",
	# right side, above the control panel
	"inventory": "right", "world": "right", "growth": "center", "party": "right", "tavern": "right",
	"pets": "right", "quests": "right", "codex": "center", "settings": "right", "dps": "left",
	"away": "center", "ending": "center",
	# workshop panels open next to the bag
	"stash": "left_of:inventory", "blacksmith": "left_of:inventory",
}


func _default_pos(id: String, size_l: Vector2i, _index: int, _count: int) -> Vector2i:
	if bool(Settings.get_v("remember_panels", false)):
		var saved: Dictionary = Settings.get_v("panel_pos", {})
		if saved.has(id):
			var v: Array = saved[id]
			return clamp_to_screen(Vector2i(int(v[0]), int(v[1])), size_l * ui_scale)
	var sc := ui_scale
	var s := strip_rect()
	var w := size_l * sc
	var above: bool = Settings.get_v("strip_pos", "taskbar") != "top"
	var y := s.position.y - w.y - GAP * sc if above else s.end.y + GAP * sc
	var x := s.position.x + s.size.x - w.x
	var home: String = HOME.get(id, "right")
	if title_mode:
		# the title screen is in the middle of the screen: show panels centred over it
		var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		return clamp_to_screen(usable.position + (usable.size - w) / 2, w)
	match home:
		"group":
			var ids: Array = GROUPS["hero"]
			var total := 0
			for pid in ids:
				total += PANELS[pid]["size"].x * sc + GAP * sc
			total -= GAP * sc
			x = s.position.x + (s.size.x - total) / 2
			for pid in ids:
				if pid == id:
					break
				x += PANELS[pid]["size"].x * sc + GAP * sc
		"right":
			x = s.end.x - w.x
		"left":
			x = s.position.x
		"center":
			x = s.position.x + (s.size.x - w.x) / 2
		_:
			if home.begins_with("left_of:"):
				var other: String = home.substr(8)
				var ow: int = PANELS[other]["size"].x * sc
				x = s.end.x - ow - GAP * sc - w.x
	if home == "group":
		return clamp_to_screen(Vector2i(x, y), w)
	return _free_spot(id, Vector2i(x, y), w)


## Nearest spot in the same row that doesn't cover another open panel (the portrait may be covered as
## a last resort). Falls back to the home spot; the new panel is raised to the front either way.
func _free_spot(id: String, home_pos: Vector2i, w: Vector2i) -> Vector2i:
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var g := GAP * ui_scale
	var others: Array = []
	for pid in panels:
		if pid != id and is_open(pid) and panels[pid].visible:
			others.append([pid, Rect2i(panels[pid].position, panels[pid].size)])
	var xs: Array = [home_pos.x]
	for o in others:
		var r: Rect2i = o[1]
		xs.append(r.end.x + g)
		xs.append(r.position.x - g - w.x)
	xs.sort_custom(func(a, b): return absi(a - home_pos.x) < absi(b - home_pos.x))
	for skip_portrait in [false, true]:
		for x in xs:
			if x < usable.position.x or x + w.x > usable.end.x:
				continue
			var cand := Rect2i(Vector2i(x, home_pos.y), w)
			var hit := false
			for o in others:
				if skip_portrait and o[0] == "portrait":
					continue
				if cand.intersects(o[1]):
					hit = true
					break
			if not hit:
				return clamp_to_screen(cand.position, w)
	return clamp_to_screen(home_pos, w)


func panel_moved(p: PanelWindow) -> void:
	var saved: Dictionary = Settings.get_v("panel_pos", {}).duplicate()
	saved[p.panel_id] = [p.position.x, p.position.y]
	Settings.set_v("panel_pos", saved, false)


## Magnetic edges: snaps to neighbouring panels / the strip when they line up, and stays on screen.
func snap_position(p: Window, pos: Vector2i) -> Vector2i:
	var snap := 6 * ui_scale
	var g := GAP * ui_scale
	var rects: Array = [strip_rect()]
	for id in panels:
		var o: Window = panels[id]
		if is_instance_valid(o) and o != p and o.visible:
			rects.append(Rect2i(o.position, o.size))
	var sz: Vector2i = p.size
	for o: Rect2i in rects:
		var r := Rect2i(pos, sz)
		var v_overlap: bool = r.position.y < o.end.y + snap and r.end.y > o.position.y - snap
		var h_overlap: bool = r.position.x < o.end.x + snap and r.end.x > o.position.x - snap
		if v_overlap:
			if absi(r.position.x - o.end.x) < snap:
				pos.x = o.end.x + g
			elif absi(r.end.x - o.position.x) < snap:
				pos.x = o.position.x - sz.x - g
		if h_overlap:
			if absi(r.end.y - o.position.y) < snap:
				pos.y = o.position.y - sz.y - g
			elif absi(r.position.y - o.end.y) < snap:
				pos.y = o.end.y + g
			if absi(r.position.x - o.position.x) < snap:
				pos.x = o.position.x
			elif absi(r.end.x - o.end.x) < snap:
				pos.x = o.end.x - sz.x
		if v_overlap and absi(r.position.y - o.position.y) < snap:
			pos.y = o.position.y
	return clamp_to_screen(pos, sz)


func reset_layout() -> void:
	Settings.set_v("panel_pos", {})
	Settings.set_v("strip_pos", "taskbar")
	place_strip()
	for id in panels.keys():
		if is_open(id):
			var p: PanelWindow = panels[id]
			p.position = _default_pos(id, p.logical_size, -1, 1)


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


# ------------------------------------------------------------------ tooltip router
var _tip_ctrl: Control = null
var _tip_t := 0.0
var _tip_text := ""
var _tip_shown := false


## Finds the control under the mouse in any of our windows and shows its tooltip_text after a short delay.
func _route_tooltips(delta: float) -> void:
	var hovered: Control = null
	var vps: Array = [get_window()]
	for id in panels:
		if is_instance_valid(panels[id]):
			vps.append(panels[id])
	for vp: Viewport in vps:
		var c := vp.gui_get_hovered_control()
		if c != null and c.is_visible_in_tree():
			hovered = c
			break
	var text := ""
	if hovered != null:
		text = hovered.get_tooltip(hovered.get_local_mouse_position())
	if hovered != _tip_ctrl or text != _tip_text:
		_tip_ctrl = hovered
		_tip_text = text
		_tip_t = 0.0
		if _tip_shown:
			_tip_shown = false
			hide_tooltip()
		return
	if text == "" or _tip_shown:
		return
	_tip_t += delta
	if _tip_t >= 0.3:
		_tip_shown = true
		show_text_tooltip(text)


# ------------------------------------------------------------------ focus / fps / hotkeys
func _process(delta: float) -> void:
	_route_tooltips(delta)
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
