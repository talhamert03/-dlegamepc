class_name Toast
extends Control
## PC-style reward notice: a framed plate that slides in above the battle strip's right end (like a loot
## toast in a desktop RPG), shows what was gained with its icon, waits and fades. No dimming, no pop-up,
## clicks go through. Several stack upwards.

const SIZE := Vector2(168, 32)
const LIFE := 4.2

var _icon: Texture2D = null
var _chest := ""
var _title := ""
var _sub := ""
var _t := 0.0
var _slot := 0
static var _live: Array = []


## icon: a texture, or chest: a chest kind drawn with ChestArt.
static func show_reward(icon: Texture2D, title: String, sub := "", chest := "") -> void:
	var layer: Control = WindowManager.top_layer
	if layer == null:
		return
	var t := Toast.new()
	t._icon = icon
	t._chest = chest
	t._title = title
	t._sub = sub
	t.size = SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.z_index = 60
	t.set_meta("region", true)
	_live = _live.filter(func(x): return is_instance_valid(x))
	t._slot = _live.size()
	_live.append(t)
	layer.add_child(t)
	t._place()
	AudioManager.play("chest_drop" if chest != "" else "coin", 0.05, 0.8)
	WindowManager.layout_changed()


func _place() -> void:
	var sr := WindowManager.strip_rect()
	var ease := 1.0 - pow(1.0 - clampf(_t / 0.35, 0.0, 1.0), 3.0)
	var x := sr.end.x - SIZE.x - 4.0 + (1.0 - ease) * 40.0
	var y := sr.position.y - SIZE.y - 4.0 - _slot * (SIZE.y + 3.0)
	if y < 2.0:
		y = sr.end.y + 4.0 + _slot * (SIZE.y + 3.0)
	position = Vector2(x, y).round()


func _process(delta: float) -> void:
	_t += delta
	_place()
	if _t < 0.45:
		WindowManager.layout_changed()   # the window region follows the slide-in
	var out := clampf((LIFE - _t) / 0.6, 0.0, 1.0)
	modulate.a = clampf(_t / 0.2, 0.0, 1.0) * out
	queue_redraw()
	if _t >= LIFE:
		_live.erase(self)
		queue_free()
		WindowManager.layout_changed()


func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	UISkin.fill(ci, r.grow(1.0), 4, Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.6))
	UISkin.fill(ci, r, 4, Color("#2E2230"), Color("#140E16"))
	UISkin.stroke(ci, r.grow(-1.0), 3, Color("#C9A46A", 0.85), 1.0)
	# a thin light sweep across the plate when it arrives
	var sw := clampf((_t - 0.2) / 0.7, 0.0, 1.0)
	if sw > 0.0 and sw < 1.0:
		var sx := r.size.x * sw
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 14, 1), Vector2(sx, 1), Vector2(sx - 10, r.size.y - 1), Vector2(sx - 24, r.size.y - 1)]),
			Color(1, 0.95, 0.8, 0.12))
	# icon well
	var well := Rect2(4, 4, 24, 24)
	UISkin.fill(ci, well, 3, Color("#1A1218"), Color("#0A070C"))
	UISkin.stroke(ci, well, 3, Color("#8A6A3A"), 1.0)
	if _chest != "":
		ChestArt.draw(self, well.position + Vector2(12, 20), 18.0, _chest, 0.0, _t, false)
	elif _icon:
		draw_texture_rect(_icon, well.grow(-3.0), false)
	var f := UITheme.font_title
	var fb := UITheme.font_body
	var tx := 33.0
	var tw := r.size.x - tx - 6.0
	draw_string(f, Vector2(tx, 14 if _sub != "" else 19), _title, HORIZONTAL_ALIGNMENT_LEFT, tw, 8, Color("#FFE2A0"))
	if _sub != "":
		draw_string(fb, Vector2(tx, 25), _sub, HORIZONTAL_ALIGNMENT_LEFT, tw, 7, Color("#CFC6B4"))
