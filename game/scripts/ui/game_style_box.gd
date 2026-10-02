class_name GameStyleBox
extends StyleBox
## StyleBox drawn with the vector Skin (wooden buttons, tabs, parchment, wells).

var kind := "button"      # button | parchment | well | panel
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
		_:
			UISkin.button(to_canvas_item, rect, color, state)
