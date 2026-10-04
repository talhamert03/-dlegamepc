extends Node
## Owns the single transparent overlay window that hosts the battle strip, every panel and the tooltip.
##
## The overlay covers the screen's usable area (never the taskbar). Everything outside the visible UI is
## excluded with a mouse-passthrough region, which on Windows is a window region: clicks *and* drawing
## outside it go to the desktop, so it also works on drivers where per-pixel transparency is broken.
## Rendering uses canvas_items stretch at an integer scale: pixel art stays sharp, text and vector UI are
## drawn at native resolution.

const STRIP_SIZE := Vector2i(472, 72)    # battle view 360 + control block 112
const MAX_PANEL_H := 334
const GAP := 2   # logical pixels between panels / strip
## taskbar mode: the part of the battle view shown on the taskbar and the room above it for the bubble
const MINI_CROP := Rect2(48, 18, 312, 54)
const MINI_BUBBLE_H := 36.0

signal mini_changed(on: bool)
const PANELS := {
	"hero": {"script": "res://scripts/ui/panels/hero_main_panel.gd", "size": Vector2i(252, 334), "title": "panel_hero"},
	"stats": {"script": "res://scripts/ui/panels/stats_panel.gd", "size": Vector2i(214, 334), "title": "panel_stats"},
	"skills": {"script": "res://scripts/ui/panels/hero_panel.gd", "size": Vector2i(196, 334), "title": "panel_skills"},
	"portrait": {"script": "res://scripts/ui/panels/portrait_panel.gd", "size": Vector2i(150, 250), "title": "panel_portrait"},
	"inventory": {"script": "res://scripts/ui/panels/inventory_panel.gd", "size": Vector2i(176, 250), "title": "panel_inventory"},
	"stash": {"script": "res://scripts/ui/panels/stash_panel.gd", "size": Vector2i(180, 240), "title": "panel_stash"},
	"blacksmith": {"script": "res://scripts/ui/panels/blacksmith_panel.gd", "size": Vector2i(200, 260), "title": "panel_blacksmith"},
	"world": {"script": "res://scripts/ui/panels/world_panel.gd", "size": Vector2i(240, 334), "title": "panel_world"},
	"growth": {"script": "res://scripts/ui/panels/growth_panel.gd", "size": Vector2i(248, 260), "title": "panel_growth"},
	"party": {"script": "res://scripts/ui/panels/party_panel.gd", "size": Vector2i(220, 200), "title": "panel_party"},
	"tavern": {"script": "res://scripts/ui/panels/tavern_panel.gd", "size": Vector2i(332, 300), "title": "panel_tavern"},
	"settings": {"script": "res://scripts/ui/panels/settings_panel.gd", "size": Vector2i(236, 250), "title": "panel_settings"},
	"away": {"script": "res://scripts/ui/panels/away_panel.gd", "size": Vector2i(220, 214), "title": "panel_away"},
	"dps": {"script": "res://scripts/ui/panels/dps_panel.gd", "size": Vector2i(210, 214), "title": "panel_dps"},
	"quests": {"script": "res://scripts/ui/panels/quests_panel.gd", "size": Vector2i(220, 236), "title": "panel_quests"},
	"codex": {"script": "res://scripts/ui/panels/codex_panel.gd", "size": Vector2i(232, 240), "title": "panel_codex"},
	"ending": {"script": "res://scripts/ui/panels/ending_panel.gd", "size": Vector2i(250, 150), "title": "panel_ending"},
	"pets": {"script": "res://scripts/ui/panels/pets_panel.gd", "size": Vector2i(210, 190), "title": "panel_pets"},
	"runes": {"script": "res://scripts/ui/panels/runes_panel.gd", "size": Vector2i(440, 300), "title": "panel_runes"},
	"chests": {"script": "res://scripts/ui/panels/chests_panel.gd", "size": Vector2i(236, 222), "title": "panel_chests"},
	"shop": {"script": "res://scripts/ui/panels/shop_panel.gd", "size": Vector2i(332, 300), "title": "panel_shop"},
}
const GROUPS := {"hero": ["hero"], "bag": ["hero"], "world": ["world"], "growth": ["growth"]}
## Default home of every panel: panels sit above the strip, bottom-aligned. Groups open side by side;
## a reopened panel comes back here.
const HOME := {
	"hero": "center", "ending": "center", "runes": "center",
	"away": "left", "stats": "left", "skills": "left", "stash": "left", "blacksmith": "left", "pets": "left", "dps": "left",
	"world": "right", "growth": "right", "tavern": "right", "quests": "right", "codex": "right", "settings": "right",
	"party": "right", "inventory": "right", "portrait": "left", "chests": "right", "shop": "center",
}

var ui_scale: float = 2.0
var panels: Dictionary = {}
var selected_hero: String = ""
var tooltip: Control = null
var hidden_all := false
var tray: Node = null
var title_mode := false          # true while the title screen is shown
var title_control: Control = null
var desktop: Control = null      # overlay root (logical coordinates)
var strip: Control = null        # battle strip root
var panels_layer: Control = null
var top_layer: Control = null
var _focus_poll := 0.0
var _any_focused := true
var _region_dirty := true
var _region_refresh := 0.0
var _last_region: PackedVector2Array = PackedVector2Array()
var mini_mode := false
var mini_bar: MiniBar = null
var _mini_top_t := 0.0
var _mini_rect := Rect2i()       # taskbar the bar sits on (screen pixels)
var _was_focused := false


func _ready() -> void:
	get_tree().root.close_requested.connect(_on_root_close)
	get_tree().auto_accept_quit = false
	EventBus.story_completed.connect(func(): open_panel("ending"))


## Called by Main with the overlay root and the strip control.
func setup_overlay(desk: Control, strip_root: Control) -> void:
	desktop = desk
	strip = strip_root
	panels_layer = Control.new()
	panels_layer.name = "Panels"
	panels_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panels_layer.z_index = 100       # windows always draw over the battle strip (its effects use z up to 50)
	desk.add_child(panels_layer)
	top_layer = Control.new()
	top_layer.name = "Top"
	top_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_layer.z_index = 120
	desk.add_child(top_layer)
	tooltip = load("res://scripts/ui/tooltip_window.gd").new()
	top_layer.add_child(tooltip)
	setup_main_window()


const LAYOUT_VERSION := 2      # bump when logical sizes change: saved strip / panel positions become invalid


func setup_main_window() -> void:
	var w := get_window()
	if int(Settings.get_v("layout_version", 1)) != LAYOUT_VERSION:
		Settings.set_v("layout_version", LAYOUT_VERSION)
		Settings.set_v("strip_pos", "taskbar")
		Settings.set_v("strip_lx", -1)
		Settings.set_v("strip_ly", -1)
		Settings.set_v("panel_lpos", {})
	ui_scale = compute_scale()
	var usable := _usable()
	# window = usable area rounded down to a multiple of the scale, bottom-aligned (keeps pixel art crisp)
	var logical := Vector2i(int(usable.size.x / ui_scale), int(usable.size.y / ui_scale))
	var phys := Vector2i((Vector2(logical) * ui_scale).floor())
	w.borderless = true
	w.transparent = true
	w.always_on_top = bool(Settings.get_v("always_on_top", true))
	w.unresizable = true
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	w.content_scale_size = logical
	w.size = phys
	var pos := Vector2i(usable.position.x + (usable.size.x - phys.x) / 2, usable.end.y - phys.y)
	w.position = pos
	# window managers may move/resize a window when it is first mapped: put it back once shown
	for delay in [0.15, 1.0]:
		get_tree().create_timer(delay).timeout.connect(func():
			if mini_mode:
				return
			w.size = phys
			w.position = pos
			layout_changed())
	if not w.size_changed.is_connected(layout_changed):
		w.size_changed.connect(layout_changed)
	if desktop:
		desktop.size = Vector2(logical)
		panels_layer.size = desktop.size
		top_layer.size = desktop.size
	place_strip()
	_setup_tray()
	layout_changed()


func _usable() -> Rect2i:
	return DisplayServer.screen_get_usable_rect(game_screen())


## The monitor the game lives on: the one picked in the settings, else the one the window is on.
func game_screen() -> int:
	var want := int(Settings.get_v("screen", -1))
	if want >= 0 and want < DisplayServer.get_screen_count():
		return want
	return DisplayServer.window_get_current_screen()


func set_screen(idx: int) -> void:
	Settings.set_v("screen", idx)
	Settings.set_v("strip_lx", -1)
	Settings.set_v("strip_ly", -1)
	Settings.set_v("panel_lpos", {})
	if mini_mode:
		exit_mini()
	setup_main_window()


## Compact, taskbar-hero sized: about one integer step per 520 px of screen height
## (1920x1080/1200 -> 2x, 2560x1440 -> 3x, 4K -> 4x), reduced until the strip and a full panel still fit.
func compute_scale() -> float:
	var s := int(Settings.get_v("scale", 0))
	if s > 0:
		return float(s)
	var usable := _usable()
	# half steps: 768p -> 1.5x, 1080p -> 2x, 1440p -> 2.5x, 4K -> 4x
	var k := clampf(round(usable.size.y / 520.0 * 2.0) / 2.0, 1.5, 6.0)
	while k > 1.0:
		var fits_w: bool = STRIP_SIZE.x * k <= usable.size.x * 0.8
		var fits_h: bool = (STRIP_SIZE.y + MAX_PANEL_H + 6) * k <= usable.size.y
		if fits_w and fits_h:
			break
		k -= 0.5
	return k


func area_size() -> Vector2:
	return desktop.size if desktop else Vector2(STRIP_SIZE)


func place_strip() -> void:
	if strip == null:
		return
	var area := area_size()
	var mode: String = Settings.get_v("strip_pos", "taskbar")
	var sx: float = float(Settings.get_v("strip_lx", -1))
	var sy: float = float(Settings.get_v("strip_ly", -1))
	if mode == "free" and sx >= 0 and sy >= 0:
		strip.position = clamp_to_area(Vector2(sx, sy), strip.size)
	else:
		var y := area.y - strip.size.y if mode != "top" else 0.0
		strip.position = Vector2(round((area.x - strip.size.x) / 2.0), y)
	layout_changed()


func clamp_to_area(pos: Vector2, sz: Vector2) -> Vector2:
	var area := area_size()
	return Vector2(clampf(pos.x, 0, max(0.0, area.x - sz.x)), clampf(pos.y, 0, max(0.0, area.y - sz.y))).round()


func strip_rect() -> Rect2:
	return Rect2(strip.position, strip.size) if strip else Rect2(Vector2.ZERO, Vector2(STRIP_SIZE))


func set_scale(s: int) -> void:
	Settings.set_v("scale", s)
	var ids: Array = panels.keys()
	for id in ids:
		close_panel(id)
	setup_main_window()
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
		for id in ids:
			open_panel(id)


func toggle_panel(id: String) -> void:
	if is_open(id):
		close_panel(id)
	else:
		open_panel(id)


func open_panel(id: String, _index := -1, _count := 1) -> PanelWindow:
	if is_open(id):
		var p0: PanelWindow = panels[id]
		p0.move_to_front()
		return p0
	if not PANELS.has(id) or panels_layer == null:
		push_warning("unknown panel %s" % id)
		return null
	var info: Dictionary = PANELS[id]
	var scr: Script = load(info["script"])
	if scr == null:
		return null
	var p: PanelWindow = scr.new()
	p.setup(id, DataDB.t(info["title"]), info["size"])
	p.position = _default_pos(id, info["size"])
	panels_layer.add_child(p)
	panels[id] = p
	_pop_in(p)
	AudioManager.play("ui_open", 0.05, 0.6)
	EventBus.tutorial_step.emit("open_" + id)
	layout_changed()
	return p


func _pop_in(p: Control) -> void:
	p.pivot_offset = p.size / 2.0
	p.scale = Vector2(0.96, 0.96)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.10)


func close_panel(id: String) -> void:
	if not is_open(id):
		panels.erase(id)
		return
	var p: PanelWindow = panels[id]
	panels.erase(id)
	# quick fade and shrink, then gone (already out of the click region)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.pivot_offset = p.size / 2.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2(0.97, 0.97), 0.08)
	tw.tween_property(p, "modulate:a", 0.0, 0.08)
	tw.chain().tween_callback(p.queue_free)
	hide_tooltip()
	AudioManager.play("ui_close", 0.05, 0.5)
	layout_changed()


func close_top_panel() -> bool:
	if panels_layer == null:
		return false
	for i in range(panels_layer.get_child_count() - 1, -1, -1):
		var p := panels_layer.get_child(i)
		if p is PanelWindow and not p.is_queued_for_deletion() and panels.get((p as PanelWindow).panel_id) == p:
			close_panel((p as PanelWindow).panel_id)
			return true
	return false


func refresh_all() -> void:
	for id in panels:
		if is_instance_valid(panels[id]):
			panels[id].refresh()


func _default_pos(id: String, size_l: Vector2i) -> Vector2:
	var w := Vector2(size_l)
	if title_mode:
		return clamp_to_area((area_size() - w) / 2.0, w)
	if bool(Settings.get_v("remember_panels", false)):
		var saved: Dictionary = Settings.get_v("panel_lpos", {})
		if saved.has(id):
			var v: Array = saved[id]
			return clamp_to_area(Vector2(float(v[0]), float(v[1])), w)
	var s := strip_rect()
	# above the strip when there is room (normal taskbar position), otherwise below it
	var above: bool = s.position.y - w.y - GAP >= 0.0 or s.end.y + GAP + w.y > area_size().y
	var y := s.position.y - w.y - GAP if above else s.end.y + GAP
	var x := s.end.x - w.x
	var home: String = HOME.get(id, "right")
	# three columns centred on the strip: side panels | hero window | side panels
	var cx := s.position.x + s.size.x / 2.0
	var hw := float(PANELS["hero"]["size"].x)
	match home:
		"left":
			x = cx - hw / 2.0 - GAP - w.x
		"right":
			x = cx + hw / 2.0 + GAP
		_:
			x = cx - w.x / 2.0
	return _free_spot(id, Vector2(round(x), y), w)


## Nearest spot in the same row that doesn't cover another open panel (the portrait may be covered as
## a last resort). Falls back to the home spot; the new panel is on top either way.
func _free_spot(id: String, home_pos: Vector2, w: Vector2) -> Vector2:
	var area := area_size()
	var others: Array = []
	for pid in panels:
		if pid != id and is_open(pid) and panels[pid].visible:
			others.append([pid, Rect2(panels[pid].position, panels[pid].size)])
	var xs: Array = [home_pos.x]
	for o in others:
		var r: Rect2 = o[1]
		xs.append(r.end.x + GAP)
		xs.append(r.position.x - GAP - w.x)
	xs.sort_custom(func(a, b): return absf(a - home_pos.x) < absf(b - home_pos.x))
	for skip_portrait in [false, true]:
		for x in xs:
			if x < 0 or x + w.x > area.x:
				continue
			var cand := Rect2(Vector2(x, home_pos.y), w)
			var hit := false
			for o in others:
				if skip_portrait and o[0] == "portrait":
					continue
				if cand.grow(-0.5).intersects(o[1]):
					hit = true
					break
			if not hit:
				return clamp_to_area(cand.position, w)
	return clamp_to_area(home_pos, w)


func panel_moved(p: PanelWindow) -> void:
	var saved: Dictionary = Settings.get_v("panel_lpos", {}).duplicate()
	saved[p.panel_id] = [p.position.x, p.position.y]
	Settings.set_v("panel_lpos", saved, false)
	layout_changed()


## Magnetic edges: snaps to neighbouring panels / the strip when they line up, and stays on screen.
func snap_position(p: Control, pos: Vector2) -> Vector2:
	var snap := 6.0
	var rects: Array = [strip_rect()]
	for id in panels:
		var o: Control = panels[id]
		if is_instance_valid(o) and o != p and o.visible:
			rects.append(Rect2(o.position, o.size))
	var sz: Vector2 = p.size
	for o: Rect2 in rects:
		var r := Rect2(pos, sz)
		var v_overlap: bool = r.position.y < o.end.y + snap and r.end.y > o.position.y - snap
		var h_overlap: bool = r.position.x < o.end.x + snap and r.end.x > o.position.x - snap
		if v_overlap:
			if absf(r.position.x - o.end.x) < snap:
				pos.x = o.end.x + GAP
			elif absf(r.end.x - o.position.x) < snap:
				pos.x = o.position.x - sz.x - GAP
		if h_overlap:
			if absf(r.end.y - o.position.y) < snap:
				pos.y = o.position.y - sz.y - GAP
			elif absf(r.position.y - o.end.y) < snap:
				pos.y = o.end.y + GAP
			if absf(r.position.x - o.position.x) < snap:
				pos.x = o.position.x
			elif absf(r.end.x - o.end.x) < snap:
				pos.x = o.end.x - sz.x
		if v_overlap and absf(r.position.y - o.position.y) < snap:
			pos.y = o.position.y
	return clamp_to_area(pos, sz)


var _ctx_menu: Control = null


func show_context_menu(m: Control, at: Vector2) -> void:
	if _ctx_menu and is_instance_valid(_ctx_menu):
		_ctx_menu.queue_free()
	hide_tooltip()
	_ctx_menu = m
	top_layer.add_child(m)
	m.position = clamp_to_area(at + Vector2(2, 2), m.size)
	layout_changed()


func reset_layout() -> void:
	Settings.set_v("panel_lpos", {})
	Settings.set_v("strip_pos", "taskbar")
	place_strip()
	for id in panels.keys():
		if is_open(id):
			var p: PanelWindow = panels[id]
			p.position = _default_pos(id, p.logical_size)
	layout_changed()


# ------------------------------------------------------------------ click-through region
func layout_changed() -> void:
	_region_dirty = true


func _update_region() -> void:
	_region_dirty = false
	var rects: Array = []
	if mini_mode and mini_bar:
		rects.append(mini_bar.bar_rect)
		if mini_bar.bubble.visible:
			rects.append(Rect2(mini_bar.bubble.position.x, 0, mini_bar.bubble.size.x, mini_bar.bubble.size.y + 6))
	elif title_mode and title_control and is_instance_valid(title_control):
		rects.append(Rect2(title_control.position, title_control.size * title_control.scale))
	elif strip and strip.visible:
		rects.append(strip_rect())
	for id in panels:
		var p: Control = panels[id]
		if not mini_mode and is_instance_valid(p) and p.visible and not p.is_queued_for_deletion():
			rects.append(Rect2(p.position, p.size))
	if tooltip and tooltip.visible and not mini_mode:
		rects.append(Rect2(tooltip.position, tooltip.size))
	if top_layer and not mini_mode:
		for c in top_layer.get_children():
			if c != tooltip and c is Control and c.visible and c.has_meta("region"):
				rects.append(Rect2(c.position, c.size))
	# logical -> window pixels: the actual stretch (window size / content size); never trust a 0 scale
	var w := get_window()
	var cs := Vector2(w.content_scale_size)
	var sc := Vector2(w.size) / cs if cs.x > 0 and cs.y > 0 else Vector2(ui_scale, ui_scale)
	if sc.x <= 0.01 or sc.y <= 0.01 or is_nan(sc.x) or is_nan(sc.y):
		sc = Vector2(ui_scale, ui_scale)
	var full := Vector2(w.size)
	var irects: Array[Rect2i] = []
	for r: Rect2 in rects:
		var a := Vector2i((r.position * sc).floor().clamp(Vector2.ZERO, full))
		var b := Vector2i((r.end * sc).ceil().clamp(Vector2.ZERO, full))
		if b.x > a.x and b.y > a.y:
			irects.append(Rect2i(a, b - a))
	# an empty polygon means "whole window" to the OS: on drivers without per-pixel transparency that is a
	# black screen over the desktop. Keep at least a 1-pixel region.
	if irects.is_empty():
		# two separate pixels: still a complex region (see _notched)
		irects.append(Rect2i(0, 0, 1, 1))
		irects.append(Rect2i(2, 0, 1, 1))
	var poly := union_outline(_notched(irects))
	if poly == _last_region:
		return
	_last_region = poly
	get_window().mouse_passthrough_polygon = poly


## Never hand Windows a plain rectangular region. Chromium-based apps (the Steam client, browsers,
## Discord) treat a window whose region is a simple rectangle as an opaque window the size of its whole
## window rect; ours covers the screen, so they think they are hidden behind it and stop drawing (black
## pages). A region with any notch is a "complex" region, which they ignore. So one corner pixel of the
## region's bounding box is always cut out (it is a transparent frame corner anyway).
static func _notched(rects: Array[Rect2i]) -> Array[Rect2i]:
	var box := rects[0]
	for r in rects:
		box = box.merge(r)
	var tl := box.position
	var out: Array[Rect2i] = []
	for r in rects:
		if r.has_point(tl) and r.size.x > 1 and r.size.y > 1:
			# rect minus its top-left pixel = the rest of the first row + every row below
			out.append(Rect2i(r.position.x + 1, r.position.y, r.size.x - 1, 1))
			out.append(Rect2i(r.position.x, r.position.y + 1, r.size.x, r.size.y - 1))
		elif r.has_point(tl):
			continue
		else:
			out.append(r)
	return out if not out.is_empty() else rects


## Outline of the union of axis-aligned rectangles as ONE polygon: every boundary loop (outer edges and
## holes, consistently oriented) is chained through zero-width bridges, which fills correctly under both
## even-odd and non-zero rules (Windows window regions / X11 shape regions).
static func union_outline(rects: Array[Rect2i]) -> PackedVector2Array:
	var out := PackedVector2Array()
	if rects.is_empty():
		return out
	var xs: Array = []
	var ys: Array = []
	for r in rects:
		for v in [r.position.x, r.end.x]:
			if not xs.has(v):
				xs.append(v)
		for v in [r.position.y, r.end.y]:
			if not ys.has(v):
				ys.append(v)
	xs.sort()
	ys.sort()
	var nx := xs.size() - 1
	var ny := ys.size() - 1
	var cov := PackedByteArray()
	cov.resize(nx * ny)
	for j in ny:
		var cy: float = (ys[j] + ys[j + 1]) * 0.5
		for i in nx:
			var cx: float = (xs[i] + xs[i + 1]) * 0.5
			for r in rects:
				if cx > r.position.x and cx < r.end.x and cy > r.position.y and cy < r.end.y:
					cov[j * nx + i] = 1
					break
	var covered := func(i: int, j: int) -> bool:
		return i >= 0 and j >= 0 and i < nx and j < ny and cov[j * nx + i] == 1
	# directed boundary edges, clockwise in y-down coordinates
	var edges: Dictionary = {}   # start Vector2i -> Array of end Vector2i
	var add_edge := func(a: Vector2i, b: Vector2i) -> void:
		if not edges.has(a):
			edges[a] = []
		edges[a].append(b)
	for j in ny:
		for i in nx:
			if not covered.call(i, j):
				continue
			var x0: int = xs[i]
			var x1: int = xs[i + 1]
			var y0: int = ys[j]
			var y1: int = ys[j + 1]
			if not covered.call(i, j - 1):
				add_edge.call(Vector2i(x0, y0), Vector2i(x1, y0))
			if not covered.call(i + 1, j):
				add_edge.call(Vector2i(x1, y0), Vector2i(x1, y1))
			if not covered.call(i, j + 1):
				add_edge.call(Vector2i(x1, y1), Vector2i(x0, y1))
			if not covered.call(i - 1, j):
				add_edge.call(Vector2i(x0, y1), Vector2i(x0, y0))
	var loops: Array = []
	while not edges.is_empty():
		var start: Vector2i = edges.keys()[0]
		var loop: Array = [start]
		var cur := start
		var guard := 0
		while guard < 100000:
			guard += 1
			var nexts: Array = edges.get(cur, [])
			if nexts.is_empty():
				break
			var nxt: Vector2i = nexts.pop_back()
			if nexts.is_empty():
				edges.erase(cur)
			if nxt == start:
				break
			loop.append(nxt)
			cur = nxt
		loops.append(_simplify(loop))
	var anchor: Vector2i = loops[0][0]
	for li in loops.size():
		var l: Array = loops[li]
		if li > 0:
			out.append(Vector2(anchor))
		for v in l:
			out.append(Vector2(v))
		out.append(Vector2(l[0]))
	out.append(Vector2(anchor))
	return out


static func _simplify(loop: Array) -> Array:
	var n := loop.size()
	if n < 4:
		return loop
	var res: Array = []
	for k in n:
		var a: Vector2i = loop[(k - 1 + n) % n]
		var b: Vector2i = loop[k]
		var c: Vector2i = loop[(k + 1) % n]
		var collinear := (a.x == b.x and b.x == c.x) or (a.y == b.y and b.y == c.y)
		if not collinear:
			res.append(b)
	return res if res.size() >= 3 else loop


# ------------------------------------------------------------------ tooltip
func show_item_tooltip(item: Dictionary, compare_hero := "") -> void:
	if tooltip:
		tooltip.show_item(item, compare_hero)


func show_text_tooltip(text: String) -> void:
	if tooltip:
		tooltip.show_text(text)


func hide_tooltip() -> void:
	if tooltip:
		tooltip.hide_tip()


var _tip_ctrl: Control = null
var _tip_t := 0.0
var _tip_text := ""
var _tip_shown := false


## Shows the hovered control's tooltip_text in our own tooltip (Godot's native tooltip is a popup window).
func _route_tooltips(delta: float) -> void:
	var c := get_viewport().gui_get_hovered_control() if desktop else null
	var text := ""
	if c != null and c.is_visible_in_tree():
		text = c.get_tooltip(c.get_local_mouse_position())
	if c != _tip_ctrl or text != _tip_text:
		_tip_ctrl = c
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
	# re-assert the window region now and then: some OS events (resize, DPI change, explorer restart) drop it
	_region_refresh += delta
	if _region_refresh > 2.0:
		_region_refresh = 0.0
		_last_region = PackedVector2Array()
		_region_dirty = true
	if _region_dirty and desktop:
		_update_region()
	_mini_watch(delta)
	_focus_poll += delta
	if _focus_poll < 0.3:
		return
	_focus_poll = 0.0
	var f := get_window().has_focus()
	if f != _any_focused:
		_any_focused = f
		_apply_fps()
		AudioManager.set_focused(f)


func _apply_fps() -> void:
	var idle := int(Settings.get_v("fps_idle", 15))
	if mini_mode:
		idle = maxi(idle, 30)     # the taskbar battle stays smooth
	Engine.max_fps = int(Settings.get_v("fps_focus", 60)) if _any_focused else idle


# ------------------------------------------------------------------ taskbar mode
## Minimising the game (taskbar button, Win+D, ...) doesn't stop it: the window comes straight back as a
## slim battle bar on the taskbar, left of the notification area, and the party keeps fighting. Clicking the
## bar, the taskbar button or the tray icon brings the full game back.
func _mini_watch(delta: float) -> void:
	if desktop == null or title_mode or hidden_all:
		return
	var w := get_window()
	if w.mode == Window.MODE_MINIMIZED:
		if mini_mode:
			exit_mini()
		elif bool(Settings.get_v("mini_mode", true)):
			enter_mini()
		return
	if not mini_mode:
		return
	# the taskbar keeps raising itself: stay above it
	_mini_top_t += delta
	if _mini_top_t > 1.5:
		_mini_top_t = 0.0
		w.always_on_top = false
		w.always_on_top = true
	# activated from the taskbar button (the click landed on the taskbar, not on the bar): restore
	var f := w.has_focus()
	if f and not _was_focused:
		var m := DisplayServer.mouse_get_position()
		var own := Rect2i(w.position, w.size)
		if _mini_rect.has_point(m) and not own.has_point(m):
			exit_mini()
			return
	_was_focused = f


func _taskbar_rect() -> Rect2i:
	var scr := game_screen()
	var full := Rect2i(DisplayServer.screen_get_position(scr), DisplayServer.screen_get_size(scr))
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var dpi := maxf(1.0, DisplayServer.screen_get_dpi(scr) / 96.0)
	if usable.end.y < full.end.y - 8:
		return Rect2i(full.position.x, usable.end.y, full.size.x, full.end.y - usable.end.y)
	if usable.position.y > full.position.y + 8:
		return Rect2i(full.position.x, full.position.y, full.size.x, usable.position.y - full.position.y)
	# side or auto-hidden taskbar: a taskbar-high strip along the bottom of the screen
	var hh := int(48 * dpi)
	return Rect2i(usable.position.x, usable.end.y - hh, usable.size.x, hh)


func enter_mini() -> void:
	var w := get_window()
	mini_mode = true
	_ensure_mini_bar()
	hide_tooltip()
	if _ctx_menu and is_instance_valid(_ctx_menu):
		_ctx_menu.queue_free()
	w.mode = Window.MODE_WINDOWED
	panels_layer.visible = false
	top_layer.visible = false
	var tb := _taskbar_rect()
	_mini_rect = tb
	var dpi := maxf(1.0, DisplayServer.screen_get_dpi(game_screen()) / 96.0)
	var bar_px := maxf(24.0, tb.size.y - 4.0 * dpi)
	var k := bar_px / MINI_CROP.size.y
	var logical := Vector2i(int(MINI_CROP.size.x), int(MINI_CROP.size.y + MINI_BUBBLE_H))
	var phys := Vector2i(roundi(logical.x * k), roundi(logical.y * k))
	w.content_scale_size = logical
	w.size = phys
	var off := int(Settings.get_v("mini_off", -1))
	if off < 0:
		off = int(300 * dpi)     # clears the Windows 11 / 10 tray + clock
	var x := clampi(tb.end.x - off - phys.x, tb.position.x, tb.end.x - phys.x)
	w.position = Vector2i(x, tb.end.y - phys.y - int(2 * dpi))
	w.always_on_top = true
	desktop.size = Vector2(logical)
	strip.position = Vector2(-MINI_CROP.position.x, MINI_BUBBLE_H - MINI_CROP.position.y)
	mini_bar.visible = true
	mini_bar.size = Vector2(logical)
	mini_bar.layout(Rect2(0, MINI_BUBBLE_H, MINI_CROP.size.x, MINI_CROP.size.y), MINI_BUBBLE_H)
	_was_focused = w.has_focus()
	_apply_fps()
	mini_changed.emit(true)
	layout_changed()


## The in-game minimise button: taskbar mode when enabled, a normal minimise otherwise.
func minimize() -> void:
	if mini_mode:
		return
	if bool(Settings.get_v("mini_mode", true)):
		enter_mini()
	else:
		get_window().mode = Window.MODE_MINIMIZED


func exit_mini(open_id := "") -> void:
	if not mini_mode:
		return
	mini_mode = false
	var w := get_window()
	w.mode = Window.MODE_WINDOWED
	if mini_bar:
		mini_bar.visible = false
		mini_bar.hide_bubble()
	panels_layer.visible = true
	top_layer.visible = true
	mini_changed.emit(false)
	setup_main_window()
	_apply_fps()
	if open_id != "":
		open_panel(open_id)
	w.grab_focus()


func mini_drag_to(x: int) -> void:
	var w := get_window()
	w.position.x = clampi(x, _mini_rect.position.x, _mini_rect.end.x - w.size.x)


func mini_drag_done() -> void:
	var w := get_window()
	Settings.set_v("mini_off", _mini_rect.end.x - (w.position.x + w.size.x))


func _ensure_mini_bar() -> void:
	if mini_bar and is_instance_valid(mini_bar):
		return
	mini_bar = MiniBar.new()
	mini_bar.z_index = 130
	desktop.add_child(mini_bar)
	mini_bar.restore_requested.connect(func(): exit_mini())
	mini_bar.bubble_clicked.connect(func(): exit_mini("chests"))
	EventBus.chest_dropped.connect(func(kind: String, _p: Vector2):
		if mini_mode and Chests.rank(kind) >= int(Settings.get_v("mini_bubble_min", 0)):
			mini_bar.show_bubble(kind, DataDB.t("chest_found", {"name": Chests.display_name(kind)}))
			AudioManager.play("chest_drop", 0.0, 0.5))


func handle_hotkey(ev: InputEventKey) -> void:
	if ev.ctrl_pressed and ev.shift_pressed and ev.keycode == KEY_H:
		toggle_hide_all()
		return
	if ev.ctrl_pressed or ev.alt_pressed:
		return
	match ev.keycode:
		KEY_ESCAPE:
			close_top_panel()
		KEY_H, KEY_I, KEY_B:
			toggle_panel("hero")
		KEY_C:
			toggle_panel("stats")
		KEY_K:
			toggle_panel("stats")
		KEY_R:
			toggle_panel("runes")
		KEY_M:
			toggle_group("world")
		KEY_G:
			toggle_group("growth")
		KEY_P:
			open_panel("hero")
			if panels.has("hero") and is_instance_valid(panels["hero"]):
				panels["hero"]._on_tab(1)
		KEY_T:
			toggle_panel("tavern")
		KEY_J:
			toggle_panel("quests")
		KEY_D:
			toggle_panel("dps")
		KEY_E:
			toggle_panel("pets")


func toggle_hide_all() -> void:
	if mini_mode:
		exit_mini()
	hidden_all = not hidden_all
	var w := get_window()
	if hidden_all:
		w.mode = Window.MODE_MINIMIZED
	else:
		w.mode = Window.MODE_WINDOWED
		setup_main_window()
	hide_tooltip()


func set_always_on_top(v: bool) -> void:
	Settings.set_v("always_on_top", v)
	get_window().always_on_top = v


func _setup_tray() -> void:
	if tray != null or not ClassDB.class_exists("StatusIndicator"):
		return
	var os_name := OS.get_name()
	if os_name != "Windows" and os_name != "macOS":
		return
	tray = ClassDB.instantiate("StatusIndicator")
	var menu := PopupMenu.new()
	menu.prefer_native_menu = true
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
		tray.connect("pressed", func(_b, _p):
			if hidden_all:
				toggle_hide_all()
			elif mini_mode:
				exit_mini())


func _on_tray_menu(id: int) -> void:
	match id:
		0:
			if hidden_all:
				toggle_hide_all()
			elif mini_mode:
				exit_mini()
			else:
				get_window().grab_focus()
		1:
			Settings.set_v("mute", not Settings.get_v("mute", false))
		2:
			quit_game()


func _on_root_close() -> void:
	quit_game()


## Quit with a confirmation over the battle strip (progress is saved either way).
func ask_quit() -> void:
	if strip == null or mini_mode:
		quit_game()
		return
	if strip.has_node("QuitAsk"):
		return
	var v := W.confirm(strip, DataDB.t("quit_confirm"), quit_game, DataDB.t("tip_quit"), true)
	v.name = "QuitAsk"
	v.z_index = 200


func quit_game() -> void:
	GameState.save_game(0, true)
	Settings.save_settings()
	get_tree().quit()
