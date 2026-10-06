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
var _sheen: TextureRect      # epic+ icon drawn with the reflection shader
var _over: Control           # badges, selection and marks drawn above the icon
const SHEEN_SHADER := preload("res://assets/shaders/item_sheen.gdshader")
## sheen per rarity: [colour, strength, rim glow (alpha 0 = none), rainbow]
const SHEEN := {
	"epic": [Color("#F0D8FF"), 0.7, Color(0.75, 0.45, 1.0, 0.0), false],
	"set": [Color("#D8FFD0"), 0.75, Color(0.4, 1.0, 0.45, 0.35), false],
	"legendary": [Color("#FFE9B0"), 0.9, Color(1.0, 0.62, 0.2, 0.55), false],
	"mythic": [Color.WHITE, 0.8, Color(1.0, 0.3, 0.3, 0.6), true],
}
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


func _ensure_layers() -> void:
	if _over != null:
		return
	_sheen = TextureRect.new()
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sheen.stretch_mode = TextureRect.STRETCH_SCALE
	_sheen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sheen.visible = false
	add_child(_sheen)
	_over = Control.new()
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)


## Epic and better: the icon goes on its own layer with the reflection shader.
func _sync_sheen(ic: Texture2D, o: Vector2, isz: float) -> bool:
	var rar: String = item.get("rarity", "common")
	if item.get("mythic", false):
		rar = "mythic"
	if ic == null or not SHEEN.has(rar):
		_sheen.visible = false
		return false
	var cfg: Array = SHEEN[rar]
	if _sheen.material == null or _sheen.get_meta("rar", "") != rar:
		var m := ShaderMaterial.new()
		m.shader = SHEEN_SHADER
		m.set_shader_parameter("sheen_color", cfg[0])
		m.set_shader_parameter("strength", cfg[1])
		m.set_shader_parameter("glow_color", cfg[2])
		m.set_shader_parameter("rainbow", cfg[3])
		m.set_shader_parameter("offset", randf())
		_sheen.material = m
		_sheen.set_meta("rar", rar)
	_sheen.texture = ic
	_sheen.position = o
	_sheen.size = Vector2(isz, isz)
	_sheen.modulate = Color(1, 1, 1, 0.4) if dim else Color.WHITE
	_sheen.visible = true
	return true


func _draw() -> void:
	_ensure_layers()
	_over.size = size
	_over.queue_redraw()
	var ci := get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	var rar: String = item.get("rarity", "common")
	UISkin.slot(ci, r, UISkin.rarity_fill(rar), not item.is_empty(), _hover)
	var isz := roundf(size.x * 0.8)
	var o := ((size - Vector2(isz, isz)) / 2.0).round()
	if item.is_empty():
		_sheen.visible = false
		if placeholder:
			draw_texture_rect(placeholder, Rect2(o + Vector2(3, 3), Vector2(10, 10)), false, Color(1, 1, 1, 0.16))
		return
	var ic := SpriteLib.item_icon(item)
	if ic:
		# soft drop shadow, then the icon (on the shader layer for epic and better)
		draw_texture_rect(ic, Rect2(o + Vector2(0.5, 1), Vector2(isz, isz)), false, Color(0, 0, 0, 0.35))
		if not _sync_sheen(ic, o, isz):
			draw_texture_rect(ic, Rect2(o, Vector2(isz, isz)), false, Color(1, 1, 1, 0.4) if dim else Color.WHITE)


## Colour-blind aid: a shape per rarity on the right edge (corners hold enhance, upgrade, class and lock marks)
## (magic dot, rare triangle, epic diamond, set square, legendary star, mythic four-point star).
func _rarity_mark(rar: String) -> void:
	var c := Vector2(size.x - 4.0, roundf(size.y / 2.0))
	var pts := PackedVector2Array()
	match rar:
		"magic":
			for k in 10:
				pts.append(c + Vector2.from_angle(k * TAU / 10.0) * 1.8)
		"rare":
			pts = PackedVector2Array([c + Vector2(0, -2.4), c + Vector2(2.3, 1.8), c + Vector2(-2.3, 1.8)])
		"epic":
			pts = PackedVector2Array([c + Vector2(0, -2.6), c + Vector2(2.2, 0), c + Vector2(0, 2.6), c + Vector2(-2.2, 0)])
		"set":
			pts = PackedVector2Array([c + Vector2(-2, -2), c + Vector2(2, -2), c + Vector2(2, 2), c + Vector2(-2, 2)])
		"legendary", "mythic":
			var n := 5 if rar == "legendary" else 4
			for k in n * 2:
				var a := -PI / 2.0 + k * PI / n
				pts.append(c + Vector2.from_angle(a) * (2.8 if k % 2 == 0 else 1.1))
		_:
			return
	var outline := PackedVector2Array()
	for p in pts:
		outline.append(c + (p - c) * 1.55)
	_over.draw_colored_polygon(outline, Color(0, 0, 0, 0.85))
	_over.draw_colored_polygon(pts, Color.WHITE)


## Everything drawn above the icon: enhance level, lock, selection, drag target, flash, upgrade arrow.
func _draw_over() -> void:
	if item.is_empty() and not selected and _drag_target != self:
		return
	var ci := _over.get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	var enh := int(item.get("enhance", 0))
	if enh > 0:
		_over.draw_string_outline(UITheme.font_body, Vector2(2, 8), "+%d" % enh, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.8))
		_over.draw_string(UITheme.font_body, Vector2(2, 8), "+%d" % enh, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#B6FFC8"))
	if bool(Settings.get_v("colorblind", false)) and not item.is_empty():
		_rarity_mark(str(item.get("rarity", "common")))
	if item.get("locked", false):
		_over.draw_texture_rect(UITheme.icon("lock"), Rect2(size.x - 7, size.y - 7, 6, 6), false, Color(1, 1, 1, 0.9))
	if selected:
		UISkin.stroke(ci, r.grow(-0.5), 2, Color("#FFE45C"), 1.6)
	if _drag_target == self:
		_over.draw_rect(r, Color(1.0, 0.92, 0.6, 0.18))
		UISkin.stroke(ci, r.grow(0.5), 2, Color("#FFE9A0"), 1.4)
	if _press_slot == self and _ghost != null:
		_over.draw_rect(r.grow(-1), Color(0.05, 0.03, 0.06, 0.55))
	if _flash > 0.0:
		var e := _flash
		_over.draw_rect(r, Color(1.0, 0.9, 0.55, 0.45 * e * e))
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
			_over.draw_rect(Rect2(p - Vector2(1, 1), Vector2(5, 5)), Color(0, 0, 0, 0.7))
			_over.draw_line(p, p + Vector2(3, 3), Color("#FF5A4A"), 1.2, true)
			_over.draw_line(p + Vector2(3, 0), p + Vector2(0, 3), Color("#FF5A4A"), 1.2, true)


func _up_arrow(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0.5), c + Vector2(1.2, 0.5), c + Vector2(1.2, 3),
		c + Vector2(-1.2, 3), c + Vector2(-1.2, 0.5), c + Vector2(-3, 0.5)])
	var outline := PackedVector2Array()
	for q in pts:
		outline.append(c + (q - c) * 1.35)
	_over.draw_colored_polygon(outline, Color(0, 0, 0, 0.75))
	_over.draw_colored_polygon(pts, Color("#6FF08A"))


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
