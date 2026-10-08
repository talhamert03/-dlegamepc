class_name PanelWindow
extends Control
## Base class for all floating panels. Panels live inside the single transparent overlay window
## (see WindowManager) instead of being separate OS windows: secondary OS windows render black or
## invisible on some Windows/OpenGL drivers.
## Subclasses override `build(content: Control)` and optionally `refresh()`.

signal closed_by_user

const HEADER_H := 22.0     # frame (4) + title band (18)

var panel_id: String = ""
var logical_size := Vector2i(200, 250)
var title_text: String = ""
var root: Control
var content: Control
var _dragging := false
var _drag_offset := Vector2.ZERO
var _title_label: Label
var _deco: Control
var _sweep := 1.0       # 0..1: light running along the frame after the window opens or is raised

## The window's emblem, shown on two small seals flanking the title ribbon.
const PANEL_ICON := {"hero": "shield", "stats": "cross", "inventory": "bag", "stash": "chest", "blacksmith": "hammer",
	"world": "map", "growth": "star", "tavern": "mug", "settings": "gear", "away": "clock", "dps": "chart",
	"quests": "quest", "codex": "book", "ending": "crown", "pets": "heart", "runes": "rune", "chests": "chest", "shop": "gem"}


func setup(id: String, title: String, size_l: Vector2i) -> void:
	panel_id = id
	title_text = title
	logical_size = size_l


func _ready() -> void:
	size = Vector2(logical_size)
	theme = UITheme.theme
	mouse_filter = Control.MOUSE_FILTER_STOP
	# any click that no button/slot consumes bubbles up here: raise + drag the panel
	gui_input.connect(_on_drag_input)
	root = self
	_frame = UITheme.frame(Vector2(logical_size), true)
	add_child(_frame)
	_deco = Control.new()
	_deco.size = size
	_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deco.draw.connect(_draw_deco)
	add_child(_deco)
	_start_sweep.call_deferred()
	# title on a red ribbon
	_title_label = UITheme.title_label(UITheme.upper(title_text), Color("#FFF0D2"))
	_title_label.add_theme_font_size_override("font_size", 10)
	_title_label.add_theme_color_override("font_outline_color", Color("#3A0A0C"))
	_title_label.add_theme_constant_override("outline_size", 3)
	_title_label.position = Vector2(0, 4)
	_title_label.size = Vector2(logical_size.x, 18)
	_fit_ribbon()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_title_label)
	var drag := Control.new()
	drag.size = Vector2(logical_size.x - 18, HEADER_H)
	drag.mouse_filter = Control.MOUSE_FILTER_PASS
	drag.mouse_default_cursor_shape = Control.CURSOR_MOVE
	add_child(drag)
	# close button
	var close := UITheme.close_button(_on_close)
	close.position = Vector2(logical_size.x - 18, 7)
	add_child(close)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.position = Vector2(8, HEADER_H + 4)
	content.size = Vector2(logical_size.x - 16, logical_size.y - HEADER_H - 11)
	add_child(content)
	build(content)
	EventBus.language_changed.connect(_on_lang)


func set_panel_title(t: String) -> void:
	title_text = t
	if _title_label:
		_title_label.text = UITheme.upper(t)
		_fit_ribbon()


var _frame: Control


func _fit_ribbon() -> void:
	if _frame == null or _title_label == null:
		return
	var w := UITheme.font_title.get_string_size(_title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	_frame.ribbon_w = clampf(w + 30.0, 64.0, logical_size.x - 60.0)
	_frame.queue_redraw()


func build(_c: Control) -> void:
	pass


func refresh() -> void:
	pass


func rebuild() -> void:
	for ch in content.get_children():
		ch.queue_free()
	build(content)


func _on_lang() -> void:
	rebuild()


func _on_close() -> void:
	closed_by_user.emit()
	WindowManager.close_panel(panel_id)


func _on_drag_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dragging = true
			_drag_offset = get_parent().get_local_mouse_position() - position
			if get_index() < get_parent().get_child_count() - 1 and _sweep >= 1.0:
				_start_sweep()
			move_to_front()
		elif _dragging:
			_dragging = false
			WindowManager.panel_moved(self)
	elif ev is InputEventMouseMotion and _dragging:
		position = WindowManager.snap_position(self, get_parent().get_local_mouse_position() - _drag_offset)
		WindowManager.layout_changed()


var _sweep_tw: Tween


## Light runs once around the frame (a tween, so subclasses' own _process stays untouched).
func _start_sweep() -> void:
	if _deco == null:
		return
	# one sweep at a time: a second start (open, then focus) would fight over _sweep
	if _sweep_tw and _sweep_tw.is_valid():
		_sweep_tw.kill()
	var tw := create_tween()
	_sweep_tw = tw
	tw.tween_method(func(v: float):
		_sweep = v
		_deco.queue_redraw(), 0.0, 1.0, 0.9)


## Seals with the window's emblem beside the title ribbon, and the light sweep along the frame's gilded rule.
func _draw_deco() -> void:
	var ci := _deco.get_canvas_item()
	var w := float(logical_size.x)
	var ic_name: String = PANEL_ICON.get(panel_id, "")
	var rw: float = _frame.ribbon_w if _frame else 0.0
	if ic_name != "" and rw > 0.0 and w > 150.0:
		var ic := UITheme.icon(ic_name)
		for sd in [-1.0, 1.0]:
			var c := Vector2(w / 2.0 + sd * (rw / 2.0 + 24.0), 14.0)
			UISkin.circle(ci, c + Vector2(0, 0.8), 6.6, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45))
			UISkin.circle(ci, c, 6.2, UISkin.OUTLINE, UISkin.OUTLINE)
			UISkin.circle(ci, c, 5.6, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
			UISkin.circle(ci, c, 4.3, Color("#6A3A16"), Color("#2E1608"))
			UISkin.ring(ci, c, 5.0, Color(1, 0.95, 0.75, 0.3), 0.6)
			if ic:
				_deco.draw_texture_rect(ic, Rect2(c - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), false, Color("#FFE7B0"))
	if _sweep < 1.0:
		# a short bright stroke running clockwise along the inner gilded rule
		# along the frame's gold rule (wood 5 px + half of the 1.2 px rule)
		var r := Rect2(Vector2.ZERO, size).grow(-5.6)
		var per := 2.0 * (r.size.x + r.size.y)
		var head := _sweep * per
		var fade := 1.0 - _sweep
		for k in 16:
			var d := head - k * 2.5
			if d < 0.0:
				break
			var p := _perimeter_point(r, d)
			var a := (1.0 - k / 16.0) * fade
			_deco.draw_circle(p, 3.6 - k * 0.15, Color(1.0, 0.8, 0.45, 0.16 * a))
			_deco.draw_circle(p, 1.8 - k * 0.08, Color(1.0, 0.95, 0.75, 0.85 * a))


func _perimeter_point(r: Rect2, d: float) -> Vector2:
	if d <= r.size.x:
		return r.position + Vector2(d, 0)
	d -= r.size.x
	if d <= r.size.y:
		return Vector2(r.end.x, r.position.y + d)
	d -= r.size.y
	if d <= r.size.x:
		return Vector2(r.end.x - d, r.end.y)
	d -= r.size.x
	return Vector2(r.position.x, r.end.y - minf(d, r.size.y))

