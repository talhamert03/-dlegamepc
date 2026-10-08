class_name DebugGallery
extends Control
## Screenshot-mode sheet (--gallery): every button colour in every state, plus the tabs, toggles, segmented
## plaques, slider and bar, on a real window frame, for side-by-side visual review of the control family.

const COLORS := ["gold", "orange", "brown", "red", "green", "blue", "gray"]
const STATES := ["normal", "hover", "pressed", "disabled"]
const BW := 62.0
const BH := 14.0


func _init() -> void:
	size = Vector2(16 + 50 + STATES.size() * (BW + 6) + 6, 0)
	size.y = 30 + COLORS.size() * (BH + 6) + 120
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var y0 := 30.0
	for i in STATES.size():
		var l := UITheme.label(STATES[i], UITheme.C_DIM, 8)
		l.position = Vector2(66 + i * (BW + 6), y0 - 12)
		add_child(l)
	for j in COLORS.size():
		var l := UITheme.label(COLORS[j], UITheme.C_DIM, 8)
		l.position = Vector2(14, y0 + j * (BH + 6) + 2)
		add_child(l)
	var yb := y0 + COLORS.size() * (BH + 6) + 4
	var tabs := W.tabs(["Envanter", "Diziliş", "Sandıklar"], 0, func(_i): pass)
	tabs.position = Vector2(14, yb)
	add_child(tabs)
	var t1 := Fancy.toggle(true, func(_v): pass)
	t1.position = Vector2(14, yb + 22)
	add_child(t1)
	var t2 := Fancy.toggle(false, func(_v): pass)
	t2.position = Vector2(44, yb + 22)
	add_child(t2)
	var seg := Fancy.segmented(["5", "10", "15", "30"], 2, func(_i): pass)
	seg.position = Vector2(80, yb + 22)
	add_child(seg)
	var sl := Fancy.slider(0.6, func(_v): pass)
	sl.position = Vector2(14, yb + 44)
	add_child(sl)
	var bar := Fancy.bar(120, 9, 0.62, Color("#E5B44E"), "62 / 100")
	bar.position = Vector2(130, yb + 44)
	add_child(bar)
	var sb := Fancy.small_button("Oto Doldur", "gold", func(): pass, Vector2(64, 13))
	sb.position = Vector2(14, yb + 64)
	add_child(sb)
	var b2 := UITheme.button("Tümü Depoya", "brown")
	b2.position = Vector2(84, yb + 64)
	add_child(b2)
	var b3 := UITheme.button("Sat", "red")
	b3.position = Vector2(170, yb + 64)
	add_child(b3)
	var b4 := UITheme.button("Oyna", "gold")
	b4.disabled = true
	b4.position = Vector2(206, yb + 64)
	add_child(b4)


func _draw() -> void:
	var ci := get_canvas_item()
	UISkin.panel(ci, Rect2(Vector2.ZERO, size))
	var y0 := 30.0
	var f := UITheme.font_body
	for j in COLORS.size():
		for i in STATES.size():
			var r := Rect2(66 + i * (BW + 6), y0 + j * (BH + 6), BW, BH)
			UISkin.button(ci, r, COLORS[j], STATES[i])
			var tc := Color("#7A7E8A") if STATES[i] == "disabled" else UITheme.btn_text_color(COLORS[j])
			var t := "Demirci"
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var tp := Vector2(r.position.x + (BW - tw) / 2.0, r.position.y + (1.0 if STATES[i] == "pressed" else 0.0) + BH / 2.0 + 8 * 0.36)
			if tc.v > 0.5 and STATES[i] != "disabled":
				draw_string_outline(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color(0, 0, 0, 0.55))
			draw_string(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, tc)
