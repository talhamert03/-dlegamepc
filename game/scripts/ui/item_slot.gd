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
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	# HD frames are minified (mipmaps), pixel item icons are magnified (stay crisp)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		_hover = true
		queue_redraw()
		if not item.is_empty():
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
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if not ev.double_click:
				ItemSfx.pick(item)
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


func _get_drag_data(_pos: Vector2) -> Variant:
	if item.is_empty():
		return null
	var p := TextureRect.new()
	p.texture = SpriteLib.item_icon(item)
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.size = Vector2(24, 24)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_drag_preview(p)
	WindowManager.hide_tooltip()
	return {"item": item, "source": source, "key": key}


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if source != "equip":
		ItemSfx.drop()
	dropped.emit(self, data)
