class_name Fancy
extends RefCounted
## Hand-drawn fantasy controls shared by the panels: banner tabs, engraved section headers, brass lever
## toggles, one-piece segmented plaques, a gem-knob slider and a framed progress bar. Every control is
## drawn with UISkin so it matches the window chrome at any UI scale.


## Banner tab (used by W.tabs): crimson when active, dark wood otherwise.
static func tab_button(text: String, on: bool, w := 0.0) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.set_meta("on", on)
	b.set_meta("text", text)
	var f := UITheme.font_title
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	b.custom_minimum_size = Vector2(maxf(w, tw + 14.0), 12)
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var act: bool = b.get_meta("on", false)
		var hov := b.is_hovered()
		var r := Rect2(Vector2.ZERO, b.size)
		if act:
			UISkin.stroke(ci, r.grow(0.8), 4, Color(1.0, 0.85, 0.4, 0.4), 1.6)
			UISkin.fill(ci, r, 3, UISkin.RIBBON_TOP.lightened(0.05), UISkin.RIBBON_BOT.darkened(0.2))
		else:
			UISkin.fill(ci, r, 3, Color("#4A3020").lightened(0.1 if hov else 0.0), Color("#24160C"))
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color("#F2CB7A", 0.85) if act else Color("#B08A5A", 0.35), 0.8)
		var t: String = b.get_meta("text", "")
		var tw2 := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var tp := Vector2((r.size.x - tw2) / 2.0, r.size.y / 2.0 + 2.9)
		b.draw_string_outline(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, 0.85))
		b.draw_string(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFE7B0") if act else Color("#D8C4A0")))
	return b


## Engraved section header: gold small caps between two rules that end in lozenges.
static func section(text: String, w: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(w, 14)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var f := UITheme.font_title
		var t := text.to_upper()
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
		UISkin.fill(ci, r, 4.5, Color("#1E5A2C") if on else Color("#1A1410"), Color("#0E3018") if on else Color("#0C0806"))
		if on:
			UISkin.stroke(ci, r.grow(0.6), 5, Color(0.5, 1.0, 0.55, 0.35), 1.2)
		UISkin.stroke(ci, r, 4.5, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-0.8), 4, Color(UISkin.BRONZE, 0.55 if not hov else 0.9), 0.7)
		var k := Vector2(r.end.x - 5.0, r.get_center().y) if on else Vector2(r.position.x + 5.0, r.get_center().y)
		UISkin.circle(ci, k + Vector2(0, 0.6), 4.6, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
		UISkin.circle(ci, k, 4.4, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, k, 3.9, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		UISkin.circle(ci, k, 2.3, Color("#8CF09A") if on else Color("#7A6A5A"), Color("#1E6A2E") if on else Color("#3A3028"))
		b.draw_circle(k + Vector2(-0.7, -0.8), 0.7, Color(1, 1, 1, 0.6)))
	return b


## One plaque split into segments; the chosen one is gilded. cb(index).
static func segmented(names: Array, cur: int, cb: Callable, seg_w := 0.0) -> Control:
	var f := UITheme.font_body
	var widths: Array = []
	var tot := 0.0
	for n in names:
		var w := maxf(seg_w, f.get_string_size(str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0)
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
		UISkin.fill(ci, r, 3, Color("#3A2616"), Color("#1A0F08"))
		var x := 0.0
		for i in widths.size():
			var sr := Rect2(x, 0, float(widths[i]), r.size.y)
			if i == cur:
				UISkin.fill(ci, sr.grow(-1.0), 2, Color("#F2C55A"), Color("#A8661E"))
			elif i == int(c.get_meta("hover")):
				UISkin.fill(ci, sr.grow(-1.0), 2, Color(1, 0.9, 0.6, 0.12), Color(1, 0.9, 0.6, 0.05))
			if i > 0:
				UISkin.line(ci, Vector2(x, 2), Vector2(x, r.size.y - 2), Color(0, 0, 0, 0.7), 0.8)
			var t := str(names[i])
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			c.draw_string(f, Vector2(x + (sr.size.x - tw) / 2.0, 8.6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color("#2A1606") if i == cur else Color("#E8DCC4"))
			x += float(widths[i])
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-0.6), 2.5, Color(UISkin.BRONZE, 0.45), 0.6))
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
		UISkin.fill(ci, g.grow(1.0), 2, Color("#0C0806"), Color("#1A120C"))
		UISkin.fill(ci, Rect2(g.position, Vector2(g.size.x * v, g.size.y)), 1.5, Color("#F2C55A"), Color("#A8661E"))
		UISkin.stroke(ci, g.grow(1.0), 2, UISkin.OUTLINE, 0.8)
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
		UISkin.fill(ci, r, 2, Color("#0C0806"), Color("#1A120C"))
		var k := clampf(frac, 0.0, 1.0)
		if k > 0.0:
			var fr := Rect2(r.position + Vector2(1, 1), Vector2(maxf(2.0, (r.size.x - 2) * k), r.size.y - 2))
			UISkin.fill(ci, fr, 1.5, col.lightened(0.25), col.darkened(0.3))
			c.draw_rect(Rect2(fr.position, Vector2(fr.size.x, 1)), Color(1, 1, 1, 0.25))
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
