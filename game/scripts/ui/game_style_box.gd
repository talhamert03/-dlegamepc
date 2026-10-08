class_name GameStyleBox
extends StyleBox
## StyleBox drawn with the vector Skin (wooden buttons, tabs, parchment, wells).

var kind := "button"      # button | parchment | well | panel | scroll | grab | tip
var color := "brown"
var state := "normal"


func _init(k := "button", c := "brown", s := "normal") -> void:
	kind = k
	color = c
	state = s
	content_margin_left = 5
	content_margin_right = 5
	content_margin_top = 1.5 if s != "pressed" else 2.5
	content_margin_bottom = 2.0 if s != "pressed" else 1.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	match kind:
		"parchment":
			UISkin.parchment(to_canvas_item, rect)
		"well":
			UISkin.well(to_canvas_item, rect)
		"panel":
			UISkin.panel(to_canvas_item, rect)
		"scroll":
			_scroll_track(to_canvas_item, rect)
		"grab":
			_grabber(to_canvas_item, rect, state == "hover")
		"tip":
			_tip(to_canvas_item, rect)
		_:
			UISkin.button(to_canvas_item, rect, color, state)



## Recessed groove with a faint bronze rail on each side.
func _scroll_track(ci: RID, r: Rect2) -> void:
	UISkin.fill(ci, r, 2, Color(0.04, 0.03, 0.02, 0.55), Color(0.10, 0.07, 0.05, 0.55))
	RenderingServer.canvas_item_add_line(ci, r.position + Vector2(0.4, 2), Vector2(r.position.x + 0.4, r.end.y - 2), Color(UISkin.BRONZE, 0.35), 0.6, true)
	RenderingServer.canvas_item_add_line(ci, Vector2(r.end.x - 0.4, r.position.y + 2), r.end - Vector2(0.4, 2), Color(0, 0, 0, 0.6), 0.6, true)


## Bronze thumb with a lit edge and three grip ridges in the middle.
func _grabber(ci: RID, r: Rect2, hot: bool) -> void:
	var g := r.grow_individual(-0.3, 0, -0.3, 0)
	UISkin.fill(ci, g, 2, UISkin.BRONZE_HI if hot else UISkin.BRONZE, UISkin.BRONZE_LO)
	UISkin.stroke(ci, g, 2, UISkin.OUTLINE, 0.7)
	RenderingServer.canvas_item_add_line(ci, g.position + Vector2(0.9, 1.5), Vector2(g.position.x + 0.9, g.end.y - 1.5), Color(1, 0.95, 0.75, 0.45), 0.5, true)
	if g.size.y > 10:
		var c := g.get_center()
		for k in [-2.0, 0.0, 2.0]:
			RenderingServer.canvas_item_add_line(ci, Vector2(g.position.x + 1.0, c.y + k), Vector2(g.end.x - 1.0, c.y + k), Color(0, 0, 0, 0.55), 0.6, true)
			RenderingServer.canvas_item_add_line(ci, Vector2(g.position.x + 1.0, c.y + k + 0.6), Vector2(g.end.x - 1.0, c.y + k + 0.6), Color(1, 0.9, 0.6, 0.35), 0.4, true)


## Plain tooltips: the popup family (leather + small walnut frame with brass corners).
func _tip(ci: RID, r: Rect2) -> void:
	UISkin.popup(ci, r, 0.45, 0.35)
