class_name Fancy
extends RefCounted
## Hand-drawn fantasy controls shared by the panels: banner tabs, engraved section headers, brass lever
## toggles, one-piece segmented plaques, a gem-knob slider and a framed progress bar. Every control is
## drawn with UISkin so it matches the window chrome at any UI scale.


## Banner tab (used by W.tabs): raised crimson lacquer with a gilded bezel when active, a recessed dark
## groove otherwise (hover lights its rim).
static func tab_button(text: String, on: bool, w := 0.0) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.set_meta("on", on)
	b.set_meta("text", text)
	var f := UITheme.font_title
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	b.custom_minimum_size = Vector2(w if w > 0.0 else tw + 14.0, 12)
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var act: bool = b.get_meta("on", false)
		var hov := b.is_hovered()
		var r := Rect2(Vector2.ZERO, b.size)
		UISkin.tab(ci, r, act, hov)
		var t: String = b.get_meta("text", "")
		var fs := 8
		while fs > 6 and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 6.0:
			fs -= 1
		var tw2 := minf(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, r.size.x - 4.0)
		var tp := Vector2((r.size.x - tw2) / 2.0, r.size.y / 2.0 + fs * 0.36)
		b.draw_string_outline(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4.0, fs, 3, Color(0, 0, 0, 0.85))
		b.draw_string(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4.0, fs, Color("#FFF0C8") if act else (Color("#E8D6B0") if hov else Color("#BFA987"))))
	return b


## Engraved section header: gold small caps between two rules that end in lozenges.
static func section(text: String, w: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(w, 14)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var f := UITheme.font_title
		var t := UITheme.upper(text)
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var cy := 8.0
		var x0 := (c.size.x - tw) / 2.0
		for sd in [-1.0, 1.0]:
			var a: float = x0 - 6.0 if sd < 0 else x0 + tw + 6.0
			var e: float = 6.0 if sd < 0 else c.size.x - 6.0
			UISkin.line(ci, Vector2(a, cy), Vector2(e, cy), Color(UISkin.BRONZE, 0.55), 0.8)
			UISkin.line(ci, Vector2(a, cy + 1.6), Vector2(e, cy + 1.6), Color(0, 0, 0, 0.5), 0.6)
			UISkin.diamond(ci, Vector2(e, cy), 1.8)
		c.draw_string_outline(f, Vector2(x0, cy + 3.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color(0, 0, 0, 0.8))
		c.draw_string(f, Vector2(x0, cy + 3.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#E8C27A")))
	return c


## Settings row: label on the left, the control right-aligned, a faint rule underneath.
static func row(label: String, w: float, ctrl: Control, tip := "") -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 15)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.tooltip_text = tip
	var l := UITheme.label(label, UITheme.C_TEXT, 8, UITheme.font_body)
	l.position = Vector2(4, 2)
	l.size = Vector2(w - ctrl.custom_minimum_size.x - 10, 11)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c.add_child(l)
	ctrl.position = Vector2(w - ctrl.custom_minimum_size.x - 2, (15 - ctrl.custom_minimum_size.y) / 2.0)
	ctrl.size = ctrl.custom_minimum_size
	c.add_child(ctrl)
	c.draw.connect(func(): UISkin.line(c.get_canvas_item(), Vector2(4, 14.5), Vector2(c.size.x - 4, 14.5), Color(UISkin.BRONZE, 0.12), 0.6))
	return c


## Brass lever switch: a groove that glows green when on, with a gem knob that sits left or right.
static func toggle(on: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(26, 11)
	b.tooltip_text = DataDB.t("on") if on else DataDB.t("off")
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.5)
		cb.call(not on))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var r := Rect2(Vector2(0, 1), b.size - Vector2(0, 2))
		var hov := b.is_hovered()
		UISkin.groove(ci, r, 4.5)
		if on:
			# lit emerald channel with a soft glow and a sheen on top
			UISkin.fill(ci, r.grow(-1.2), 3.5, Color("#3FB060"), Color("#14552A"))
			UISkin.fill(ci, Rect2(r.position + Vector2(2, 1.4), Vector2(r.size.x - 4, r.size.y * 0.35)), 2, Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0))
			UISkin.stroke(ci, r.grow(0.7), 5.2, Color(0.5, 1.0, 0.55, 0.30), 1.2)
		UISkin.stroke(ci, r, 4.5, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-0.7), 4, Color(UISkin.BRONZE_HI if hov else UISkin.BRONZE, 0.75 if hov else 0.45), 0.6)
		var k := Vector2(r.end.x - 5.0, r.get_center().y) if on else Vector2(r.position.x + 5.0, r.get_center().y)
		UISkin.circle(ci, k + Vector2(0, 0.6), 4.6, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
		UISkin.circle(ci, k, 4.4, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, k, 3.9, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		UISkin.circle(ci, k, 2.3, Color("#8CF09A") if on else Color("#7A6A5A"), Color("#1E6A2E") if on else Color("#3A3028"))
		b.draw_circle(k + Vector2(-0.7, -0.8), 0.7, Color(1, 1, 1, 0.6)))
	return b


## A recessed groove split into segments; the chosen one is a raised gold button. cb(index).
static func segmented(names: Array, cur: int, cb: Callable, seg_w := 0.0) -> Control:
	var f := UITheme.font_body
	var widths: Array = []
	var tot := 0.0
	for n in names:
		var w := maxf(seg_w, f.get_string_size(str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 14.0)
		widths.append(w)
		tot += w
	var c := Control.new()
	c.custom_minimum_size = Vector2(tot, 12)
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.set_meta("hover", -1)
	c.gui_input.connect(func(e: InputEvent):
		var idx := -1
		if e is InputEventMouse:
			var x := 0.0
			for i in widths.size():
				if e.position.x >= x and e.position.x < x + float(widths[i]):
					idx = i
				x += float(widths[i])
		if e is InputEventMouseMotion and int(c.get_meta("hover")) != idx:
			c.set_meta("hover", idx)
			c.queue_redraw()
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and idx >= 0 and idx != cur:
			AudioManager.play("ui_click", 0.05, 0.5)
			cb.call(idx))
	c.mouse_exited.connect(func():
		c.set_meta("hover", -1)
		c.queue_redraw())
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.groove(ci, r, 3)
		var x := 0.0
		for i in widths.size():
			var sr := Rect2(x, 0, float(widths[i]), r.size.y)
			if i > 0 and i != cur and i - 1 != cur:
				# engraved divider: a dark cut with a lit lower lip
				UISkin.line(ci, Vector2(x - 0.3, 2.5), Vector2(x - 0.3, r.size.y - 2.5), Color(0, 0, 0, 0.75), 0.7)
				UISkin.line(ci, Vector2(x + 0.4, 2.5), Vector2(x + 0.4, r.size.y - 2.5), Color(UISkin.BRONZE, 0.22), 0.5)
			if i == cur:
				UISkin.button(ci, sr.grow_individual(-0.6, -0.6, -0.6, -0.4), "gold", "normal")
			elif i == int(c.get_meta("hover")):
				UISkin.fill(ci, sr.grow(-1.2), 2, Color(1, 0.88, 0.6, 0.16), Color(1, 0.88, 0.6, 0.05))
			var t := str(names[i])
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			c.draw_string(f, Vector2(x + (sr.size.x - tw) / 2.0, 8.6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color("#2A1606") if i == cur else (Color("#FFF0D0") if i == int(c.get_meta("hover")) else Color("#D8CAB0")))
			x += float(widths[i])
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0))
	return c


## Groove with a coloured fill and a gem knob; drag or click to set. cb(value 0..1).
static func slider(value: float, cb: Callable, w := 90.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 11)
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.set_meta("v", value)
	var set_from := func(px: float):
		var v := snappedf(clampf((px - 5.0) / (c.size.x - 10.0), 0.0, 1.0), 0.05)
		if not is_equal_approx(v, float(c.get_meta("v"))):
			c.set_meta("v", v)
			cb.call(v)
			c.queue_redraw()
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			set_from.call(e.position.x)
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			set_from.call(e.position.x))
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var v := float(c.get_meta("v"))
		var g := Rect2(5, 3.5, c.size.x - 10, 4)
		UISkin.groove(ci, g.grow(1.0), 2)
		if v > 0.0:
			var fg := Rect2(g.position, Vector2(maxf(2.0, g.size.x * v), g.size.y))
			UISkin.fill(ci, fg, 1.5, Color("#FFD872"), Color("#A8661E"))
			UISkin.line(ci, fg.position + Vector2(1, 0.7), Vector2(fg.end.x - 1, fg.position.y + 0.7), Color(1, 1, 1, 0.45), 0.6)
		UISkin.stroke(ci, g.grow(1.0), 2, UISkin.OUTLINE, 0.8)
		# tick marks every quarter, engraved under the groove
		for q in 5:
			var tx := g.position.x + g.size.x * q / 4.0
			UISkin.line(ci, Vector2(tx, g.end.y + 1.6), Vector2(tx, g.end.y + 2.8), Color(UISkin.BRONZE, 0.45), 0.6)
		var k := Vector2(g.position.x + g.size.x * v, g.get_center().y)
		UISkin.circle(ci, k + Vector2(0, 0.6), 4.4, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
		UISkin.circle(ci, k, 4.2, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, k, 3.7, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		UISkin.circle(ci, k, 2.0, Color("#FF6A6A"), Color("#7A0C18"))
		var t := "%d%%" % int(round(v * 100.0))
		c.draw_string(UITheme.font_body, Vector2(c.size.x + 3, 8.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_DIM))
	return c


## Framed progress bar with an optional caption centred on it.
static func bar(w: float, h: float, frac: float, col: Color, caption := "") -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(w, h)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		UISkin.groove(ci, r, 2)
		var k := clampf(frac, 0.0, 1.0)
		if k > 0.0:
			var fr := Rect2(r.position + Vector2(1, 1), Vector2(maxf(2.0, (r.size.x - 2) * k), r.size.y - 2))
			UISkin.fill(ci, fr, 1.5, col.lightened(0.25), col.darkened(0.3))
			# glass sheen over the top half and a bright leading edge
			UISkin.fill(ci, Rect2(fr.position + Vector2(0.5, 0.3), Vector2(fr.size.x - 1.0, fr.size.y * 0.45)), 1.2, Color(1, 1, 1, 0.30), Color(1, 1, 1, 0.06))
			if k < 1.0 and fr.size.x > 3.0:
				UISkin.line(ci, Vector2(fr.end.x - 0.5, fr.position.y + 0.5), Vector2(fr.end.x - 0.5, fr.end.y - 0.5), Color(1, 1, 0.9, 0.55), 0.8)
		UISkin.stroke(ci, r, 2, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-0.6), 1.5, Color(UISkin.BRONZE, 0.5), 0.6)
		if caption != "":
			var f := UITheme.font_body
			var fs := 7
			var tw := f.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var tp := Vector2((r.size.x - tw) / 2.0, r.size.y / 2.0 + 2.6)
			c.draw_string_outline(f, tp, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, 0.9))
			c.draw_string(f, tp, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFF4DA")))
	return c


## Bag capacity pill: a groove that fills green, then amber near full, red when full, with "used / max"
## on it. Update with set_capacity().
static func capacity(w: float, h := 10.0) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.custom_minimum_size = Vector2(w, h)
	c.size = c.custom_minimum_size
	c.set_meta("used", 0)
	c.set_meta("max", 1)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		var used := int(c.get_meta("used"))
		var mx := maxi(1, int(c.get_meta("max")))
		var k := clampf(float(used) / mx, 0.0, 1.0)
		var col := Color("#4FAF6A") if k < 0.75 else (Color("#E0A63A") if k < 0.95 else Color("#D9483E"))
		UISkin.groove(ci, r, 3)
		if k > 0.0:
			var fr := Rect2(r.position + Vector2(1, 1), Vector2(maxf(3.0, (r.size.x - 2) * k), r.size.y - 2))
			UISkin.fill(ci, fr, 2, col.lightened(0.15), col.darkened(0.35))
			UISkin.fill(ci, Rect2(fr.position + Vector2(0.5, 0.3), Vector2(fr.size.x - 1.0, fr.size.y * 0.45)), 1.5, Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.05))
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 0.9)
		UISkin.stroke(ci, r.grow(-0.6), 2.5, Color(UISkin.BRONZE, 0.45), 0.5)
		var f := UITheme.font_body
		var t := "%d / %d" % [used, mx]
		var fs := 7
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := Vector2((r.size.x - tw) / 2.0, r.size.y / 2.0 + fs * 0.36)
		c.draw_string_outline(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, 0.9))
		c.draw_string(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFF4DA")))
	return c


static func set_capacity(c: Control, used: int, mx: int) -> void:
	if int(c.get_meta("used")) != used or int(c.get_meta("max")) != mx:
		c.set_meta("used", used)
		c.set_meta("max", mx)
		c.queue_redraw()


## Small hand-drawn wooden button with an exact size (theme buttons have a minimum height).
## kind: brown | gold | red | green
static func small_button(text: String, kind: String, cb: Callable, sz: Vector2) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = sz
	b.custom_minimum_size = sz
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.5)
		cb.call())
	for sig in [b.mouse_entered, b.mouse_exited, b.button_down, b.button_up]:
		sig.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var r := Rect2(Vector2(0, 1.0 if b.button_pressed else 0.0), b.size)
		var st := "disabled" if b.disabled else ("pressed" if b.button_pressed else ("hover" if b.is_hovered() else "normal"))
		UISkin.button(ci, Rect2(Vector2.ZERO, b.size), kind, st)
		var tc := Color("#8A8690") if b.disabled else UITheme.btn_text_color(kind)
		var f := UITheme.font_body
		var fs := 8 if r.size.y >= 13 else 7
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := Vector2((r.size.x - tw) / 2.0, r.position.y + r.size.y / 2.0 + fs * 0.36)
		if tc.v > 0.5 and not b.disabled:
			b.draw_string_outline(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, 0.5))
		b.draw_string(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc))
	return b


## Large menu plaque (title screen): dark leather plate in a bronze bevel with gem studs at both ends, the
## label in the title font; hover lifts it and lights the rim in the accent colour.
static func plaque_button(text: String, accent: Color, cb: Callable, sz: Vector2) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = sz
	b.custom_minimum_size = sz
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.6)
		cb.call())
	b.set_meta("sh", -1.0)
	b.mouse_entered.connect(func():
		AudioManager.play("ui_click", 0.15, 0.15)
		# one light sweep across the plate per hover
		var tw := b.create_tween()
		tw.tween_method(func(v: float):
			b.set_meta("sh", v)
			b.queue_redraw(), 0.0, 1.0, 0.45).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): b.set_meta("sh", -1.0)))
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		b.scale = Vector2(0.96, 0.94))
	b.button_up.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	for sig in [b.mouse_exited, b.button_down, b.button_up]:
		sig.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var hov := b.is_hovered()
		var lift := -1.0 if hov and not b.button_pressed else (1.0 if b.button_pressed else 0.0)
		var r := Rect2(Vector2(6, 1 + lift), b.size - Vector2(12, 3))
		if hov:
			for k in 3:
				UISkin.fill(ci, r.grow(3.0 - k), 5, Color(accent, 0.07), Color(accent, 0.07))
		UISkin.fill(ci, Rect2(r.position + Vector2(0, 2), r.size), 4, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45))
		UISkin.fill(ci, r, 4, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		var inner := r.grow(-2.0)
		UISkin.fill(ci, inner, 3, Color("#3A2618").lerp(accent, 0.18 if hov else 0.08), Color("#170E08"))
		UISkin.stroke(ci, inner, 3, Color(0, 0, 0, 0.8), 1.0)
		UISkin.line(ci, inner.position + Vector2(4, 1.5), Vector2(inner.end.x - 4, inner.position.y + 1.5), Color(1, 0.9, 0.7, 0.18), 1.0)
		UISkin.stroke(ci, r, 4, UISkin.OUTLINE, 1.0)
		for sx in [r.position.x, r.end.x]:
			UISkin.diamond(ci, Vector2(sx, r.get_center().y), 4.2)
			UISkin.diamond(ci, Vector2(sx, r.get_center().y), 2.2, accent.lightened(0.3), accent.darkened(0.3))
		var sh := float(b.get_meta("sh", -1.0))
		var bx := inner.position.x + 5.0 + (inner.size.x - 17.0) * sh
		if sh >= 0.0:
			var sa := 0.32 * sin(sh * PI)
			var band := PackedVector2Array([Vector2(bx, inner.position.y + 1), Vector2(bx + 7, inner.position.y + 1),
				Vector2(bx + 3, inner.end.y - 1), Vector2(bx - 4, inner.end.y - 1)])
			b.draw_colored_polygon(band, Color(1, 0.95, 0.8, sa))
		var f := UITheme.font_title
		var fs := int(clampf(b.size.y * 0.46, 9.0, 14.0))
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := Vector2((b.size.x - tw) / 2.0, r.get_center().y + fs * 0.36)
		b.draw_string_outline(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.85))
		b.draw_string(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFF2D0") if hov else Color("#F0DDB4")))
	return b

