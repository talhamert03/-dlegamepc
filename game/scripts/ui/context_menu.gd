class_name ContextMenu
extends Control
## Slim right-click menu drawn inside the overlay (a native popup window would not share the UI scale/style).
## items: [[text, callable, colour (optional, may be null), icon name (optional)], ...]; closes on pick, on a click elsewhere or when the mouse leaves.

const ROW_H := 13.0
const PAD := 3.0

var _items: Array = []
var _hover := -1
var _away := 0.0
var _icons := false   # any row carries an action icon: text shifts right to a shared column


static func open(items: Array, at: Vector2) -> ContextMenu:
	var m := ContextMenu.new()
	m._items = items
	WindowManager.show_context_menu(m, at)
	return m


func _ready() -> void:
	set_meta("region", true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var w := 0.0
	for it in _items:
		w = maxf(w, UITheme.font_body.get_string_size(str(it[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
		if it.size() > 3 and it[3] != null:
			_icons = true
	size = Vector2(w + (34.0 if _icons else 22.0), _items.size() * ROW_H + PAD * 2.0)
	z_index = 100
	# drop in from the cursor
	pivot_offset = Vector2.ZERO
	scale = Vector2(0.92, 0.85)
	modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)


func _process(delta: float) -> void:
	var m := get_local_mouse_position()
	var inside := Rect2(Vector2.ZERO, size).grow(6.0).has_point(m)
	_away = 0.0 if inside else _away + delta
	if _away > 0.7:
		close()
		return
	var h := int(floor((m.y - PAD) / ROW_H)) if Rect2(Vector2.ZERO, size).has_point(m) else -1
	if h != _hover:
		_hover = h
		queue_redraw()


func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and not Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		close()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _hover >= 0 and _hover < _items.size():
			var cb: Callable = _items[_hover][1]
			AudioManager.play("ui_click", 0.05, 0.6)
			close()
			if cb.is_valid():
				cb.call()
		accept_event()


func close() -> void:
	if is_queued_for_deletion():
		return
	queue_free()
	WindowManager.layout_changed()


func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	UISkin.popup(ci, r, 0.45, 0.3)
	for i in _items.size():
		var y := PAD + i * ROW_H
		if i == _hover:
			UISkin.button(ci, Rect2(3, y, size.x - 6, ROW_H), "orange", "normal")
			if not _icons:
				UISkin.diamond(ci, Vector2(7, y + ROW_H * 0.5), 2.2)
		elif i > 0:
			draw_line(Vector2(6, y), Vector2(size.x - 6, y), Color(1, 1, 1, 0.05), 1.0)
		var col: Color = _items[i][2] if _items[i].size() > 2 and _items[i][2] != null else Color("#E9DEC8")
		if i == _hover:
			col = Color.WHITE
		var tx := 12.0
		if _icons:
			tx = 22.0
			if _items[i].size() > 3 and _items[i][3] != null:
				var ic := UITheme.icon(str(_items[i][3]))
				if ic:
					# a small dark well behind the icon so it reads on the hover plate too
					draw_circle(Vector2(12.5, y + ROW_H * 0.5), 5.2, Color(0, 0, 0, 0.35))
					draw_texture_rect(ic, Rect2(8, y + ROW_H * 0.5 - 4.5, 9, 9), false, Color(1, 1, 1, 1.0 if i == _hover else 0.85))
		draw_string(UITheme.font_body, Vector2(tx, y + ROW_H * 0.5 + 3.2), str(_items[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
