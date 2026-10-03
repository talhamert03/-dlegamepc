class_name MiniBar
extends Control
## Taskbar mode overlay: a slim gilded frame over the cropped battle view sitting on the Windows taskbar,
## plus the chest bubble that pops up above it. Click returns to the full game, drag slides it along the
## taskbar.

signal restore_requested
signal bubble_clicked

var bar_rect := Rect2()
var bubble: Control
var _bubble_kind := ""
var _bubble_title := ""
var _bubble_t := 0.0
var _press := false
var _dragging := false
var _press_x := 0
var _win_x0 := 0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hit := Control.new()
	hit.name = "Hit"
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = DataDB.t("mini_tip")
	hit.gui_input.connect(_on_bar_input)
	hit.draw.connect(_draw_frame.bind(hit))
	add_child(hit)
	bubble = Control.new()
	bubble.visible = false
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bubble.draw.connect(_draw_bubble)
	bubble.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			hide_bubble()
			bubble_clicked.emit())
	add_child(bubble)


func layout(bar: Rect2, bubble_h: float) -> void:
	bar_rect = bar
	var hit: Control = get_node("Hit")
	hit.position = bar.position
	hit.size = bar.size
	bubble.size = Vector2(minf(bar.size.x, 168.0), bubble_h - 3.0)
	bubble.position = Vector2(bar.end.x - bubble.size.x, 0)


func show_bubble(kind: String, title: String) -> void:
	_bubble_kind = kind
	_bubble_title = title
	_bubble_t = 0.0
	bubble.visible = true
	bubble.modulate.a = 0.0
	WindowManager.layout_changed()


func hide_bubble() -> void:
	if bubble.visible:
		bubble.visible = false
		WindowManager.layout_changed()


func _process(delta: float) -> void:
	_t += delta
	if bubble.visible:
		_bubble_t += delta
		bubble.modulate.a = clampf(_bubble_t / 0.25, 0.0, 1.0) * clampf((9.0 - _bubble_t) / 0.6, 0.0, 1.0)
		bubble.position.y = (1.0 - minf(1.0, _bubble_t / 0.25)) * 6.0
		if _bubble_t >= 9.0:
			hide_bubble()
		bubble.queue_redraw()
	get_node("Hit").queue_redraw()


func _draw_frame(hit: Control) -> void:
	var ci := hit.get_canvas_item()
	var r := Rect2(Vector2.ZERO, hit.size)
	# soft vignette at both ends so the cut-out battlefield sits in the frame
	for k in 6:
		var a := 0.12 * (1.0 - k / 6.0)
		hit.draw_rect(Rect2(k, 0, 1, r.size.y), Color(0, 0, 0, a))
		hit.draw_rect(Rect2(r.size.x - 1 - k, 0, 1, r.size.y), Color(0, 0, 0, a))
	UISkin.stroke(ci, r, 3, Color(0, 0, 0, 0.95), 1.4)
	UISkin.stroke(ci, r.grow(-1.0), 2, Color(UISkin.BRONZE, 0.85), 1.0)
	UISkin.stroke(ci, r.grow(-2.0), 2, Color(UISkin.BRONZE_HI, 0.18), 1.0)
	for c in [Vector2(3, 3), Vector2(r.size.x - 3, 3), Vector2(3, r.size.y - 3), Vector2(r.size.x - 3, r.size.y - 3)]:
		UISkin.diamond(ci, c, 2.2)
	# stage plate
	var f := UITheme.font_body
	var txt := "%s  ·  %d" % [DataDB.tx(BattleSim.zone().get("name", {})), int(BattleSim.stage)]
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	var plate := Rect2(5, 3, tw + 8, 9)
	UISkin.fill(ci, plate, 2, Color(0.06, 0.04, 0.05, 0.75), Color(0.06, 0.04, 0.05, 0.6))
	hit.draw_string(f, Vector2(9, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_TITLE)
	# chests waiting
	var n := Chests.count()
	if n > 0:
		var bi := Chests.best_index()
		var kind := str(GameState.chests[bi]["k"])
		ChestArt.draw(hit, Vector2(r.size.x - 12, 14), 12.0, kind, 0.0, _t, false)
		if n > 1:
			hit.draw_string_outline(f, Vector2(r.size.x - 9, 7), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 2, Color(0, 0, 0, 0.95))
			hit.draw_string(f, Vector2(r.size.x - 9, 7), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, UITheme.C_GOLD)


func _draw_bubble() -> void:
	var ci := bubble.get_canvas_item()
	var r := Rect2(Vector2.ZERO, bubble.size - Vector2(0, 4))
	var col := Chests.color(_bubble_kind) if _bubble_kind != "" else UITheme.C_GOLD
	UISkin.fill(ci, r, 4, Color("#2C2430"), Color("#141016"))
	UISkin.stroke(ci, r, 4, Color(0, 0, 0, 0.95), 1.2)
	UISkin.stroke(ci, r.grow(-1.0), 3, Color(col, 0.85), 1.0)
	# little tail pointing at the bar
	var tx := r.size.x - 22.0
	bubble.draw_colored_polygon(PackedVector2Array([Vector2(tx - 4, r.end.y - 1), Vector2(tx + 4, r.end.y - 1), Vector2(tx, r.end.y + 4)]), Color("#141016"))
	bubble.draw_polyline(PackedVector2Array([Vector2(tx - 4, r.end.y), Vector2(tx, r.end.y + 4), Vector2(tx + 4, r.end.y)]), Color(col, 0.85), 1.0, true)
	if _bubble_kind != "":
		ChestArt.draw(bubble, Vector2(16, r.size.y - 5), 20.0, _bubble_kind, 0.0, _t, true)
	var f := UITheme.font_title
	bubble.draw_string_outline(f, Vector2(32, 13), _bubble_title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 9, 3, Color(0, 0, 0, 0.9))
	bubble.draw_string(f, Vector2(32, 13), _bubble_title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 9, col.lightened(0.2))
	bubble.draw_string(UITheme.font_body, Vector2(32, 23), DataDB.t("chest_bubble"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 7, UITheme.C_DIM)


func _on_bar_input(ev: InputEvent) -> void:
	var w := get_window()
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_press = true
			_dragging = false
			_press_x = DisplayServer.mouse_get_position().x
			_win_x0 = w.position.x
		elif _press:
			_press = false
			if _dragging:
				WindowManager.mini_drag_done()
			else:
				restore_requested.emit()
	elif ev is InputEventMouseMotion and _press:
		var dx := DisplayServer.mouse_get_position().x - _press_x
		if absi(dx) > 4:
			_dragging = true
		if _dragging:
			WindowManager.mini_drag_to(_win_x0 + dx)
