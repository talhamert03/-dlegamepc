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
var _hover := false


func _init() -> void:
	custom_minimum_size = Vector2(20, 20)
	size = Vector2(20, 20)
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
	draw_texture(UITheme.tex("slot_hover" if _hover else "slot_normal"), Vector2.ZERO)
	if item.is_empty():
		if placeholder:
			draw_texture_rect(placeholder, Rect2(5, 5, 10, 10), false, Color(1, 1, 1, 0.18))
		return
	var r: String = item.get("rarity", "common")
	if r != "common":
		var bg := ItemUtil.rarity_color(r)
		draw_rect(Rect2(2, 2, 16, 16), Color(bg, 0.12))
	var ic := SpriteLib.item_icon(item)
	if ic:
		draw_texture(ic, Vector2(2, 2), Color(1, 1, 1, 0.4) if dim else Color.WHITE)
	if r != "common":
		draw_texture(UITheme.tex("slot_" + r), Vector2.ZERO)
	var enh := int(item.get("enhance", 0))
	if enh > 0:
		draw_string(UITheme.font_small, Vector2(1, 8), "+%d" % enh, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#9FF3C0"))
	if item.get("locked", false):
		draw_texture_rect(UITheme.icon("lock"), Rect2(13, 13, 6, 6), false, Color(1, 1, 1, 0.85))
	if selected:
		draw_rect(Rect2(1, 1, 18, 18), Color("#FFE45C"), false, 1.0)
	if compare_hero != "" and source != "equip" and GameState.heroes.has(compare_hero):
		var h: HeroState = GameState.heroes[compare_hero]
		if ItemUtil.can_equip(h, item):
			var cur: Dictionary = h.equipment.get(ItemUtil.equip_slots(item)[0], {})
			if ItemUtil.power_score(item, h.cls()) > ItemUtil.power_score(cur, h.cls()) * 1.02:
				draw_texture(UITheme.icon("arrow_up"), Vector2(13, 1), Color("#7FE07A"))
		else:
			draw_rect(Rect2(2, 2, 16, 16), Color(0.6, 0.1, 0.1, 0.25))


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit(self)
			accept_event()
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(self)
			accept_event()


func _get_drag_data(_pos: Vector2) -> Variant:
	if item.is_empty():
		return null
	var p := TextureRect.new()
	p.texture = SpriteLib.item_icon(item)
	set_drag_preview(p)
	WindowManager.hide_tooltip()
	return {"item": item, "source": source, "key": key}


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	dropped.emit(self, data)
