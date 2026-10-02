class_name UIFrame
extends Control
## Vector-drawn premium frame: dark layered panel, gold trim, optional header band and corner ornaments.
## Drawn at native resolution (canvas_items stretch), so it stays crisp at any UI scale.

var kind := "panel"     # panel | strip | tooltip | plaque | inset
var header := false


func _init(k := "panel", with_header := false) -> void:
	kind = k
	header = with_header
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _sb(bg: Color, border: Color, bw: float, radius: int, draw_center := true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(int(ceil(bw)))
	sb.set_corner_radius_all(radius)
	sb.draw_center = draw_center
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 0.6
	sb.corner_detail = 10
	return sb


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match kind:
		"tooltip":
			draw_style_box(_sb(Color(0.05, 0.06, 0.09, 0.97), Color("#C9A45C"), 1, 3), r)
			draw_style_box(_sb(Color(0, 0, 0, 0), Color(1, 1, 1, 0.05), 1, 2, false), r.grow(-1.5))
		"plaque":
			draw_style_box(_sb(Color("#191E2C"), Color("#B8924A"), 1, 3), r)
		"inset":
			draw_style_box(_sb(Color(0.03, 0.04, 0.06, 0.75), Color("#2C3346"), 1, 3), r)
		_:
			_draw_panel(r)


func _draw_panel(r: Rect2) -> void:
	var gold := Color("#C9A45C")
	# body + dark outer edge
	draw_style_box(_sb(Color("#121622"), Color("#05070B"), 1, 6), r)
	# soft vertical light from the top
	var inner := r.grow(-2)
	var top := Color(0.20, 0.24, 0.35, 0.35)
	var bot := Color(0.20, 0.24, 0.35, 0.0)
	draw_polygon(PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y),
		Vector2(inner.end.x, inner.position.y + inner.size.y * 0.45), Vector2(inner.position.x, inner.position.y + inner.size.y * 0.45)]),
		PackedColorArray([top, top, bot, bot]))
	# header band
	if header:
		var hb := Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 16))
		draw_style_box(_sb(Color(0.16, 0.19, 0.28, 0.85), Color(0, 0, 0, 0), 0, 5), hb)
		_divider(Vector2(r.position.x + 6, r.position.y + 18.5), r.size.x - 12, gold)
	# gold trim + inner hairline
	draw_style_box(_sb(Color(0, 0, 0, 0), gold, 1, 5, false), r.grow(-1))
	draw_style_box(_sb(Color(0, 0, 0, 0), Color(1, 0.9, 0.7, 0.07), 1, 4, false), r.grow(-3))
	# corner ornaments
	for c in [r.position + Vector2(4, 4), Vector2(r.end.x - 4, r.position.y + 4), Vector2(r.position.x + 4, r.end.y - 4), r.end - Vector2(4, 4)]:
		_diamond(c, 2.2, Color("#F2D48A"))
	if kind == "strip":
		return


func _divider(p: Vector2, w: float, col: Color) -> void:
	var clear := Color(col, 0.0)
	var mid := p + Vector2(w / 2.0, 0)
	draw_polyline_colors(PackedVector2Array([p, mid]), PackedColorArray([clear, col]), 1.0, true)
	draw_polyline_colors(PackedVector2Array([mid, p + Vector2(w, 0)]), PackedColorArray([col, clear]), 1.0, true)
	_diamond(mid, 2.5, Color("#F2D48A"))


func _diamond(c: Vector2, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.5, 0), c + Vector2(0, s * 0.5), c + Vector2(-s * 0.5, 0)]), Color(1, 1, 1, 0.55))
