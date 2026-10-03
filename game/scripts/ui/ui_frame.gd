class_name UIFrame
extends Control
## Vector-drawn premium frame: dark layered panel, gold trim, optional header band and corner ornaments.
## Drawn at native resolution (canvas_items stretch), so it stays crisp at any UI scale.

var kind := "panel"     # panel | strip | tooltip | plaque | inset | parchment
var header := false
var ribbon_w := 0.0     # width of the title ribbon (panels with a header)
const HEADER_H := 18.0


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
	var ci := get_canvas_item()
	match kind:
		"tooltip":
			# dark vellum with a gold rule and small corner lozenges
			UISkin.fill(ci, r, 3, Color(0.11, 0.08, 0.06, 0.97), Color(0.05, 0.035, 0.025, 0.97))
			UISkin.stroke(ci, r, 3, Color(0, 0, 0, 1), 1.0)
			UISkin.stroke(ci, r.grow(-1.2), 2, Color("#B08A4E"), 1.0)
			UISkin.stroke(ci, r.grow(-2.6), 2, Color(0.69, 0.54, 0.31, 0.25), 0.7)
			for c in [r.position + Vector2(2.5, 2.5), Vector2(r.end.x - 2.5, r.position.y + 2.5), r.end - Vector2(2.5, 2.5), Vector2(r.position.x + 2.5, r.end.y - 2.5)]:
				UISkin.diamond(ci, c, 2.0)
		"plaque":
			UISkin.well(ci, r)
		"inset":
			UISkin.well(ci, r)
		"parchment":
			UISkin.parchment(ci, r)
		"strip":
			UISkin.panel(ci, r)
		_:
			UISkin.panel(ci, r, HEADER_H if header else 0.0, ribbon_w)


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
