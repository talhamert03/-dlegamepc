class_name PanelWindow
extends Control
## Base class for all floating panels. Panels live inside the single transparent overlay window
## (see WindowManager) instead of being separate OS windows: secondary OS windows render black or
## invisible on some Windows/OpenGL drivers.
## Subclasses override `build(content: Control)` and optionally `refresh()`.

signal closed_by_user

const HEADER_H := 18.0

var panel_id: String = ""
var logical_size := Vector2i(200, 250)
var title_text: String = ""
var root: Control
var content: Control
var _dragging := false
var _drag_offset := Vector2.ZERO
var _title_label: Label


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
	var frame := UITheme.frame(Vector2(logical_size), true)
	add_child(frame)
	# title
	_title_label = UITheme.title_label(title_text, UITheme.C_TITLE)
	_title_label.position = Vector2(0, 1)
	_title_label.size = Vector2(logical_size.x, HEADER_H - 2)
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
	close.position = Vector2(logical_size.x - 15, 4)
	add_child(close)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.position = Vector2(8, HEADER_H + 3)
	content.size = Vector2(logical_size.x - 16, logical_size.y - HEADER_H - 10)
	add_child(content)
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
			_drag_offset = get_parent().get_local_mouse_position() - position
			move_to_front()
		elif _dragging:
			_dragging = false
			WindowManager.panel_moved(self)
	elif ev is InputEventMouseMotion and _dragging:
		position = WindowManager.snap_position(self, get_parent().get_local_mouse_position() - _drag_offset)
		WindowManager.layout_changed()
