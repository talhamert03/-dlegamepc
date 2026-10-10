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
var _base_title := ""
var _slot_f := 0.0
var _count := 1
static var _live: Array = []
const MAX_STACK := 3


## icon: a texture, or chest: a chest kind drawn with ChestArt.
static func show_reward(icon: Texture2D, title: String, sub := "", chest := "", sound := "") -> void:
	var layer: Control = WindowManager.top_layer
	if layer == null:
		return
	_live = _live.filter(func(x): return is_instance_valid(x))
	# a burst of the same notice (three achievements at once) folds into one plate: "×3" in the title and
	# the newest detail line, instead of a tower of plates over the windows
	for o in _live:
		if o._base_title == title and o._chest == chest and o._t < LIFE - 1.0:
			o._count += 1
			o._title = "%s  ×%d" % [title, o._count]
			if sub != "":
				o._sub = sub
			o._t = minf(o._t, 0.45)
			o.queue_redraw()
			AudioManager.play(sound if sound != "" else ("chest_drop" if chest != "" else "coin"), 0.05, 0.5)
			return
	var t := Toast.new()
	t._base_title = title
	t._icon = icon
	t._chest = chest
	t._title = title
	t._sub = sub
	t.size = SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.z_index = 60
	t.set_meta("region", true)
	# at most three plates: the oldest one hurries out
	if _live.size() >= MAX_STACK:
		var oldest = _live[0]
		oldest._t = maxf(oldest._t, LIFE - 0.3)
	t._slot = _live.size()
	_live.append(t)
	layer.add_child(t)
	t._place()
	AudioManager.play(sound if sound != "" else ("chest_drop" if chest != "" else "coin"), 0.05, 0.8)
	WindowManager.layout_changed()


func _place() -> void:
	var sr := WindowManager.strip_rect()
	var ease := 1.0 - pow(1.0 - clampf(_t / 0.35, 0.0, 1.0), 3.0)
	var x := sr.end.x - SIZE.x - 4.0 + (1.0 - ease) * 40.0
	# plates below this one that left free their place: settle down smoothly
	var want := maxi(0, _live.find(self))
	_slot_f = want if _t < 0.05 else lerpf(_slot_f, float(want), 0.25)
	var y := sr.position.y - SIZE.y - 4.0 - _slot_f * (SIZE.y + 3.0)
	if y < 2.0:
		y = sr.end.y + 4.0 + _slot_f * (SIZE.y + 3.0)
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
	UISkin.popup(ci, r, 0.5, 0.2)
	# a thin light sweep across the plate when it arrives
	var sw := clampf((_t - 0.2) / 0.7, 0.0, 1.0)
	if sw > 0.0 and sw < 1.0:
		var sx := r.size.x * sw
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 14, 1), Vector2(sx, 1), Vector2(sx - 10, r.size.y - 1), Vector2(sx - 24, r.size.y - 1)]),
			Color(1, 0.95, 0.8, 0.12))
	# icon well
	var well := Rect2(4, 4, 24, 24)
	UISkin.well(ci, well)
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
