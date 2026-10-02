class_name PanelWindow
extends Window
## Base class for all floating panels (native, borderless, transparent windows).
## Subclasses override `build(content: Control)` and optionally `refresh()`.

signal closed_by_user

var panel_id: String = ""
var logical_size := Vector2i(200, 250)
var title_text: String = ""
var root: Control
var content: Control
var _dragging := false
var _drag_offset := Vector2i.ZERO
var _title_label: Label


func _init() -> void:
	# Opaque on purpose: per-pixel transparent secondary windows are unreliable on Windows + OpenGL
	# (they can render invisible and click-through), so panels draw their own solid background.
	borderless = true
	transparent = false
	transparent_bg = false
	unresizable = true
	always_on_top = true
	wrap_controls = false
	content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	close_requested.connect(_on_close)


func setup(id: String, title: String, size_l: Vector2i) -> void:
	panel_id = id
	title_text = title
	logical_size = size_l


func _ready() -> void:
	var sc: int = WindowManager.ui_scale
	content_scale_size = logical_size
	size = logical_size * sc
	always_on_top = bool(Settings.get_v("always_on_top", true))
	theme = UITheme.theme
	root = Control.new()
	root.size = logical_size
	root.theme = UITheme.theme
	# any click that no button/slot consumes bubbles up here and drags the window
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_drag_input)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("#140E10")
	bg.size = Vector2(logical_size)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var frame := UITheme.nine("panel", 8)
	frame.size = Vector2(logical_size.x, logical_size.y - 5)
	frame.position = Vector2(0, 5)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	# title band: always a drag handle, shows the move cursor
	var drag := Control.new()
	drag.position = Vector2(0, 0)
	drag.size = Vector2(logical_size.x - 16, 18)
	drag.mouse_filter = Control.MOUSE_FILTER_PASS
	drag.mouse_default_cursor_shape = Control.CURSOR_MOVE
	root.add_child(drag)
	# title plaque
	var plaque := UITheme.nine("plaque", 6)
	_title_label = UITheme.title_label(title_text)
	var tw: float = max(60.0, UITheme.font_title.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20.0)
	plaque.size = Vector2(tw, 16)
	plaque.position = Vector2(round((logical_size.x - tw) / 2.0), 0)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plaque)
	_title_label.position = plaque.position + Vector2(0, -1)
	_title_label.size = Vector2(tw, 16)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_title_label)
	# close button
	var close := TextureButton.new()
	close.texture_normal = UITheme.tex("btn_red_normal")
	close.texture_hover = UITheme.tex("btn_red_hover")
	close.texture_pressed = UITheme.tex("btn_red_pressed")
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_SCALE
	close.size = Vector2(12, 11)
	close.position = Vector2(logical_size.x - 15, 3)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_on_close)
	root.add_child(close)
	var x := TextureRect.new()
	x.texture = UITheme.icon("close")
	x.position = close.position + Vector2(2.5, 2)
	x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	x.scale = Vector2(1, 1)
	root.add_child(x)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.position = Vector2(8, 19)
	content.size = Vector2(logical_size.x - 16, logical_size.y - 27)
	root.add_child(content)
	build(content)
	EventBus.language_changed.connect(_on_lang)


func set_panel_title(t: String) -> void:
	title_text = t
	if _title_label:
		_title_label.text = t


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
			_drag_offset = DisplayServer.mouse_get_position() - position
			grab_focus()
		else:
			_dragging = false
			WindowManager.panel_moved(self)
	elif ev is InputEventMouseMotion and _dragging:
		position = WindowManager.snap_position(self, DisplayServer.mouse_get_position() - _drag_offset)


func _notification(what: int) -> void:
	# a released button outside the window (fast drags) must still end the drag
	if what == NOTIFICATION_WM_MOUSE_EXIT and _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
		WindowManager.panel_moved(self)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_ESCAPE:
			_on_close()
		else:
			WindowManager.handle_hotkey(ev)
