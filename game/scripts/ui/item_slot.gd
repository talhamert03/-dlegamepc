class_name ItemSlot
extends Control
## 20x20 inventory / equipment slot with icon, rarity frame, tooltip, click and drag & drop.

signal left_clicked(slot: ItemSlot)
signal right_clicked(slot: ItemSlot)
signal dropped(slot: ItemSlot, data: Dictionary)

var item: Dictionary = {}
var source := ""        # "bag" | "equip" | "stash" | "combine"
var key: Variant = null # slot name / index
var compare_hero := ""
var placeholder: Texture2D = null
var selected := false
var dim := false
var double_click_only := false   # bag / equipment: one click selects (and sounds), a double click acts
var _hover := false
var _flash := 0.0

## Item drag (custom, so the picture follows the cursor above every panel): the slot that was pressed,
## where, and the floating icon while dragging.
static var _press_slot: ItemSlot = null
static var _press_at := Vector2.ZERO
static var _grab := Vector2.ZERO
static var _ghost: Control = null
static var _drag_target: ItemSlot = null
const DRAG_START := 4.0


## Golden pulse when this slot's item just changed (equip / upgrade feedback).
func flash() -> void:
	_flash = 1.0
	set_process(true)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 1.4)
	queue_redraw()
	if _flash <= 0.0:
		set_process(false)


func _init(sz := 22.0) -> void:
	set_process(false)
	add_to_group("item_slots")
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	# HD frames are minified (mipmaps), pixel item icons are magnified (stay crisp)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		_hover = true
		queue_redraw()
		if not item.is_empty() and _ghost == null:
			WindowManager.show_item_tooltip(item, compare_hero))
	mouse_exited.connect(func():
		_hover = false
		queue_redraw()
		WindowManager.hide_tooltip())


func set_item(it: Dictionary) -> void:
	item = it
	queue_redraw()


func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	var rar: String = item.get("rarity", "common")
	UISkin.slot(ci, r, UISkin.rarity_fill(rar), not item.is_empty(), _hover)
	var isz := roundf(size.x * 0.8)
	var o := ((size - Vector2(isz, isz)) / 2.0).round()
	if item.is_empty():
		if placeholder:
			draw_texture_rect(placeholder, Rect2(o + Vector2(3, 3), Vector2(10, 10)), false, Color(1, 1, 1, 0.16))
		return
	var ic := SpriteLib.item_icon(item)
	if ic:
		# soft drop shadow, then the crisp pixel icon at 1:1 logical size
		draw_texture_rect(ic, Rect2(o + Vector2(0.5, 1), Vector2(isz, isz)), false, Color(0, 0, 0, 0.35))
		draw_texture_rect(ic, Rect2(o, Vector2(isz, isz)), false, Color(1, 1, 1, 0.4) if dim else Color.WHITE)
	var enh := int(item.get("enhance", 0))
	if enh > 0:
		draw_string_outline(UITheme.font_body, Vector2(2, 8), "+%d" % enh, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.8))
		draw_string(UITheme.font_body, Vector2(2, 8), "+%d" % enh, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#B6FFC8"))
	if item.get("locked", false):
		draw_texture_rect(UITheme.icon("lock"), Rect2(size.x - 7, size.y - 7, 6, 6), false, Color(1, 1, 1, 0.9))
	if selected:
		UISkin.stroke(ci, r.grow(-0.5), 2, Color("#FFE45C"), 1.6)
	if _drag_target == self:
		draw_rect(r, Color(1.0, 0.92, 0.6, 0.18))
		UISkin.stroke(ci, r.grow(0.5), 2, Color("#FFE9A0"), 1.4)
	if _press_slot == self and _ghost != null:
		draw_rect(r.grow(-1), Color(0.05, 0.03, 0.06, 0.55))
	if _flash > 0.0:
		var e := _flash
		draw_rect(r, Color(1.0, 0.9, 0.55, 0.45 * e * e))
		UISkin.stroke(ci, r.grow(1.0 + (1.0 - e) * 3.0), 3, Color(1.0, 0.85, 0.35, e), 1.5)
	if compare_hero != "" and source != "equip" and GameState.heroes.has(compare_hero):
		var h: HeroState = GameState.heroes[compare_hero]
		if ItemUtil.can_equip(h, item):
			var cur: Dictionary = h.equipment.get(ItemUtil.equip_slots(item)[0], {})
			if ItemUtil.power_score(item, h.cls()) > ItemUtil.power_score(cur, h.cls()) * 1.02:
				_up_arrow(Vector2(size.x - 4.5, 4.0))
		else:
			# not usable by this hero: red corner mark
			var p := Vector2(size.x - 5, size.y - 5)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(5, 5)), Color(0, 0, 0, 0.7))
			draw_line(p, p + Vector2(3, 3), Color("#FF5A4A"), 1.2, true)
			draw_line(p + Vector2(3, 0), p + Vector2(0, 3), Color("#FF5A4A"), 1.2, true)


func _up_arrow(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0.5), c + Vector2(1.2, 0.5), c + Vector2(1.2, 3),
		c + Vector2(-1.2, 3), c + Vector2(-1.2, 0.5), c + Vector2(-3, 0.5)])
	var outline := PackedVector2Array()
	for q in pts:
		outline.append(c + (q - c) * 1.35)
	draw_colored_polygon(outline, Color(0, 0, 0, 0.75))
	draw_colored_polygon(pts, Color("#6FF08A"))


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		if _press_slot == self:
			if _ghost != null:
				_finish_drag()
			_press_slot = null
		return
	if ev is InputEventMouseMotion and _press_slot == self and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		if _ghost == null and ev.global_position.distance_to(_press_at) > DRAG_START:
			_start_drag()
		if _ghost != null:
			_move_drag(ev.global_position)
		accept_event()
		return
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if not ev.double_click:
				ItemSfx.pick(item)
				if not item.is_empty():
					_press_slot = self
					_press_at = ev.global_position
					_grab = ev.position
			var modified: bool = ev.shift_pressed or ev.ctrl_pressed or ev.alt_pressed or WindowManager.is_open("blacksmith")
			if double_click_only and not ev.double_click and not modified:
				accept_event()
				return
			left_clicked.emit(self)
			accept_event()
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			ItemSfx.pick(item)
			right_clicked.emit(self)
			accept_event()


# ------------------------------------------------------------------ drag & drop
func _start_drag() -> void:
	WindowManager.hide_tooltip()
	var layer: Control = WindowManager.top_layer if WindowManager.top_layer else get_tree().root
	var g := Control.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size = size * 1.15
	g.z_index = 40
	var it := item
	var gsz := size
	g.draw.connect(func():
		var ic := SpriteLib.item_icon(it)
		var isz := roundf(gsz.x * 0.8) * 1.15
		var o := (g.size - Vector2(isz, isz)) / 2.0
		g.draw_texture_rect(ic, Rect2(o + Vector2(1.5, 2.5), Vector2(isz, isz)), false, Color(0, 0, 0, 0.45))
		g.draw_texture_rect(ic, Rect2(o, Vector2(isz, isz)), false, Color(1, 1, 1, 0.95)))
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	g.rotation = -0.08
	layer.add_child(g)
	_ghost = g
	_move_drag(_press_at)
	queue_redraw()


## Ghost keeps the point that was grabbed under the cursor; the slot under it lights up.
func _move_drag(gpos: Vector2) -> void:
	if _ghost == null:
		return
	var parent := _ghost.get_parent() as Control
	var local: Vector2 = parent.get_global_transform_with_canvas().affine_inverse() * gpos if parent else gpos
	_ghost.pivot_offset = _grab * 1.15
	_ghost.position = local - _grab * 1.15
	var t := _slot_at(gpos)
	if t != _drag_target:
		var old := _drag_target
		_drag_target = t
		if old and is_instance_valid(old):
			old.queue_redraw()
		if t:
			t.queue_redraw()


func _slot_at(gpos: Vector2) -> ItemSlot:
	for n in get_tree().get_nodes_in_group("item_slots"):
		var sl := n as ItemSlot
		if sl == self or not sl.is_visible_in_tree():
			continue
		var gr := Rect2(sl.get_global_transform_with_canvas().origin, sl.size * sl.get_global_transform_with_canvas().get_scale())
		if gr.has_point(gpos):
			return sl
	return null


func _finish_drag() -> void:
	var t := _drag_target
	_drag_target = null
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	queue_redraw()
	if t and is_instance_valid(t):
		t.queue_redraw()
		t._receive({"item": item, "source": source, "key": key})


func _receive(data: Dictionary) -> void:
	if source != "equip":
		ItemSfx.drop()
	dropped.emit(self, data)


func _exit_tree() -> void:
	if _press_slot == self:
		_press_slot = null
		if _ghost and is_instance_valid(_ghost):
			_ghost.queue_free()
		_ghost = null
		_drag_target = null
