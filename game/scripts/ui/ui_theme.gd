extends Node
## Premium UI kit: smooth fonts, vector styleboxes/frames, HD icons and widget factories.

const UI := "res://assets/ui/"
const UI_HD := "res://assets/ui_hd/"
const C_TEXT := Color("#ECE6D8")
const C_DIM := Color("#9AA1B5")
const C_GOLD := Color("#F2C45A")
const C_GREEN := Color("#6FE08A")
const C_RED := Color("#FF6A5A")
const C_BLUE := Color("#86B3FF")
const C_ORANGE := Color("#FFA552")
const C_PANEL := Color("#121622")
const C_TITLE := Color("#F3D58F")
## flat button palettes: [bg, border, hover bg, pressed bg]
const BTN := {
	"brown": ["#262C3D", "#4B5470", "#30384E", "#1B202D"],
	"orange": ["#B8752C", "#F2B864", "#CC8634", "#9A6024"],
	"gold": ["#A9822E", "#F5D27A", "#BE9436", "#8C6B24"],
	"blue": ["#2C54A0", "#6E98F0", "#3463B8", "#244684"],
	"red": ["#9C3434", "#E57A6E", "#B03C3C", "#822B2B"],
	"green": ["#2D8048", "#74D79A", "#349454", "#246A3B"],
	"gray": ["#353A48", "#565D70", "#3E4454", "#2B2F3B"],
}

var font_small: FontFile
var font_body: FontFile
var font_title: FontFile
var font_big: FontFile
var theme: Theme
var _tex: Dictionary = {}


func _ready() -> void:
	font_small = _font("res://assets/fonts/FiraSans-Medium.ttf")
	font_body = _font("res://assets/fonts/FiraSans-SemiBold.ttf")
	font_title = _font("res://assets/fonts/Cinzel-Bold.ttf")
	font_big = _font("res://assets/fonts/CinzelDecorative-Bold.ttf")
	theme = _make_theme()


func _font(path: String) -> FontFile:
	var f: FontFile = load(path)
	if f == null:
		return null
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	f.generate_mipmaps = false
	return f


func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	if name.begins_with("slot_"):
		var h := hd(name, Vector2(20, 20))
		if h:
			_tex[name] = h
			return h
	var path := UI + name
	if not path.ends_with(".png"):
		path += ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[name] = t
	return t


## HD texture from assets/ui_hd, tagged with its logical size (drawn downscaled, linear filtered).
func hd(name: String, logical := Vector2(7, 7)) -> Texture2D:
	var key := "hd:" + name
	if _tex.has(key):
		return _tex[key]
	var path := UI_HD + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if t:
		t.set_meta("hd", true)
		t.set_meta("lsize", logical)
	_tex[key] = t
	return t


func icon(name: String) -> Texture2D:
	var t := hd(name)
	return t if t else tex("icons/" + name)


func _flat(bg: Color, border: Color, radius := 4, bw := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 0.6
	sb.corner_detail = 8
	return sb


## Kept for API compatibility: named styleboxes are now vector styles.
func box(name: String, margin: int, content := -1) -> StyleBox:
	var sb: StyleBoxFlat
	match name:
		"tooltip":
			sb = _flat(Color(0.05, 0.06, 0.09, 0.96), Color("#C9A45C"), 3)
		"panel":
			sb = _flat(C_PANEL, Color("#C9A45C"), 5)
		_:
			sb = _flat(Color("#191E2C"), Color("#3A4258"), 3)
	var c := margin if content < 0 else content
	sb.content_margin_left = c + 2
	sb.content_margin_right = c + 2
	sb.content_margin_top = max(1, c - 1)
	sb.content_margin_bottom = max(1, c - 1)
	return sb


func btn_box(color: String, state: String) -> StyleBox:
	return GameStyleBox.new("button", color if UISkin.BTN.has(color) else "brown", state)


func btn_text_color(color: String) -> Color:
	return Color(UISkin.BTN.get(color, UISkin.BTN["brown"])[3])


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_small
	t.default_font_size = 8
	t.set_color("font_color", "Label", C_TEXT)
	t.set_constant("line_spacing", "Label", 0)
	for c in ["Button"]:
		t.set_stylebox("normal", c, btn_box("brown", "normal"))
		t.set_stylebox("hover", c, btn_box("brown", "hover"))
		t.set_stylebox("pressed", c, btn_box("brown", "pressed"))
		t.set_stylebox("disabled", c, btn_box("brown", "disabled"))
		t.set_stylebox("focus", c, StyleBoxEmpty.new())
		t.set_color("font_color", c, btn_text_color("brown"))
		t.set_color("font_hover_color", c, Color.WHITE)
		t.set_color("font_pressed_color", c, btn_text_color("brown"))
		t.set_color("font_disabled_color", c, C_DIM)
		t.set_font("font", c, font_body)
		t.set_font_size("font_size", c, 8)
	t.set_stylebox("panel", "PanelContainer", box("panel", 6, 6))
	t.set_stylebox("panel", "TooltipPanel", box("tooltip", 3, 3))
	var sb_scroll := _flat(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 2, 0)
	sb_scroll.content_margin_left = 1
	sb_scroll.content_margin_right = 1
	t.set_stylebox("scroll", "VScrollBar", sb_scroll)
	var grab := _flat(Color("#6B5A3E"), Color(0, 0, 0, 0), 2, 0)
	var grab_h := _flat(Color("#C9A45C"), Color(0, 0, 0, 0), 2, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_h)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_h)
	t.set_constant("separation", "VBoxContainer", 1)
	t.set_constant("separation", "HBoxContainer", 2)
	return t


# ------------------------------------------------------------------ factories
func label(text: String, color: Color = C_TEXT, size := 8, font: Font = null) -> Label:
	if font == font_title and size >= 13:
		size = 11
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font if font else font_small)
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func title_label(text: String, color: Color = C_TITLE) -> Label:
	var l := label(text, color, 10, font_title)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("shadow_offset_x", 0)
	return l


func button(text: String, color := "brown", cb: Callable = Callable(), min_size := Vector2(0, 12)) -> Button:
	var b := Button.new()
	b.theme = theme
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, btn_box(color, st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", font_body)
	b.add_theme_font_size_override("font_size", 8)
	var tc := btn_text_color(color)
	b.add_theme_color_override("font_color", tc)
	b.add_theme_color_override("font_pressed_color", tc)
	b.add_theme_color_override("font_hover_color", tc.lightened(0.2) if tc.v < 0.5 else Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55) if tc.v > 0.5 else Color(1, 1, 1, 0.0))
	b.add_theme_constant_override("outline_size", 2 if tc.v > 0.5 else 0)
	b.add_theme_color_override("font_disabled_color", Color("#7A7E8A"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cb.is_valid():
		b.pressed.connect(cb)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	return b


func set_button_color(b: Button, color: String) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, btn_box(color, st))
	var tc := btn_text_color(color)
	b.add_theme_color_override("font_color", tc)
	b.add_theme_color_override("font_pressed_color", tc)
	b.add_theme_color_override("font_hover_color", tc.lightened(0.2) if tc.v < 0.5 else Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55) if tc.v > 0.5 else Color(1, 1, 1, 0.0))
	b.add_theme_constant_override("outline_size", 2 if tc.v > 0.5 else 0)


func icon_button(icon_name: String, cb: Callable, tip := "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = icon(icon_name)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(8, 8)
	b.size = Vector2(8, 8)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.modulate = Color(0.92, 0.9, 0.86)
	b.mouse_entered.connect(func(): b.modulate = Color(1.25, 1.2, 1.05))
	b.mouse_exited.connect(func(): b.modulate = Color(0.92, 0.9, 0.86))
	b.pressed.connect(cb)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


## Notification badge: a small glowing red gem with a gold rim and a white "!" (pulses softly).
func badge(size := 9.0, mark := "!") -> Control:
	var c := Control.new()
	c.size = Vector2(size, size)
	c.custom_minimum_size = c.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.z_index = 5
	var t0 := randf() * 6.0
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var ctr := c.size / 2.0
		var r := size * 0.5
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 4.0 + t0)
		c.draw_circle(ctr, r + 1.5 + pulse * 1.2, Color(1.0, 0.3, 0.2, 0.18 + 0.12 * pulse))
		UISkin.circle(ci, ctr, r + 0.6, Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9))
		UISkin.circle(ci, ctr, r, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		UISkin.circle(ci, ctr, r - 1.1, Color("#FF6A55"), Color("#9E1414"))
		c.draw_circle(ctr + Vector2(-r * 0.3, -r * 0.35), r * 0.28, Color(1, 1, 1, 0.45))
		if mark != "":
			var fs := int(size * 0.95)
			var w := UITheme.font_body.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			c.draw_string_outline(UITheme.font_body, ctr + Vector2(-w / 2.0, fs * 0.36), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0.3, 0, 0, 0.8))
			c.draw_string(UITheme.font_body, ctr + Vector2(-w / 2.0, fs * 0.36), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE))
	var tm := Timer.new()
	tm.wait_time = 0.05
	tm.autostart = true
	tm.timeout.connect(c.queue_redraw)
	c.add_child(tm)
	return c


## Right-click menu in the game's style. It is a separate OS popup window, so it gets the UI scale itself.
func context_menu() -> PopupMenu:
	var m := PopupMenu.new()
	m.add_theme_font_override("font", font_body)
	m.add_theme_font_size_override("font_size", 10)
	m.add_theme_color_override("font_color", Color("#EBDCC4"))
	m.add_theme_color_override("font_hover_color", Color.WHITE)
	m.add_theme_constant_override("v_separation", 6)
	m.add_theme_constant_override("h_separation", 6)
	m.add_theme_constant_override("item_start_padding", 8)
	m.add_theme_constant_override("item_end_padding", 10)
	var bg := _flat(Color("#16171D"), Color("#8C6A3A"), 3, 1)
	bg.content_margin_left = 3
	bg.content_margin_right = 3
	bg.content_margin_top = 4
	bg.content_margin_bottom = 4
	m.add_theme_stylebox_override("panel", bg)
	var hv := _flat(Color("#8C4716"), Color("#F3C77A"), 2, 1)
	m.add_theme_stylebox_override("hover", hv)
	m.about_to_popup.connect(func(): m.content_scale_factor = WindowManager.ui_scale)
	return m


## Bronze medallion button with an HD glyph (hero panel bottom bar).
func medallion(icon_name: String, cb: Callable, tip := "", rad := 11.0) -> BaseButton:
	var b := TextureButton.new()
	b.custom_minimum_size = Vector2(rad * 2 + 2, rad * 2 + 3)
	b.size = b.custom_minimum_size
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var colour := icon_name.begins_with("item:")
	var ic: Texture2D = load("res://assets/hd/items/%s.png" % icon_name.substr(5)) if colour else hd(icon_name)
	b.draw.connect(func():
		var st := "pressed" if b.button_pressed else ("hover" if b.is_hovered() else "normal")
		var c := Vector2(rad + 1, rad + 1 + (1.0 if st == "pressed" else 0.0))
		UISkin.medallion(b.get_canvas_item(), c, rad, st, b.has_meta("active") and b.get_meta("active"))
		if ic:
			var s2 := rad * (1.45 if colour else 1.05)
			b.draw_texture_rect(ic, Rect2(c - Vector2(s2, s2) / 2.0, Vector2(s2, s2)), false, Color.WHITE if colour else Color(1.0, 0.94, 0.82)))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.button_down.connect(b.queue_redraw)
	b.button_up.connect(b.queue_redraw)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.pressed.connect(cb)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	return b


## Glossy orb button (strip quick actions) with an HD glyph.
## Jewelled quick-action button for the strip: bronze bezel with rivets, a coloured gem with a glossy
## highlight and an embossed HD glyph. Hover brightens, press sinks.
func round_button(color: String, glyph: String) -> BaseButton:
	var gem: Array = {"red": [Color("#FF7A6A"), Color("#8A1A22")], "green": [Color("#8CF09A"), Color("#1E6A2E")],
		"blue": [Color("#8CC0FF"), Color("#1E3A8A")]}.get(color, [Color("#FFD27A"), Color("#8A5A18")])
	var ic := hd({"town": "town", "dps": "chart", "auto": "auto"}.get(glyph, glyph))
	var b := TextureButton.new()
	b.custom_minimum_size = Vector2(15, 15)
	b.size = Vector2(15, 15)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var st := "pressed" if b.button_pressed or b.is_pressed() else ("hover" if b.is_hovered() else "normal")
		var c := Vector2(7.5, 7.5 + (0.6 if st == "pressed" else 0.0))
		UISkin.circle(ci, c + Vector2(0, 1.0), 7.6, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45))
		UISkin.circle(ci, c, 7.4, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, c, 7.0, UISkin.BRONZE_HI if st == "hover" else UISkin.BRONZE, UISkin.BRONZE_LO)
		for k in 4:
			var a := PI / 4.0 + k * PI / 2.0
			UISkin.circle(ci, c + Vector2(cos(a), sin(a)) * 6.0, 0.55, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		var g0: Color = gem[0].lightened(0.15) if st == "hover" else gem[0]
		var g1: Color = gem[1]
		if st == "pressed":
			g0 = g0.darkened(0.2)
		UISkin.circle(ci, c, 5.2, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, c, 4.8, g0, g1)
		b.draw_circle(c + Vector2(-1.4, -1.8), 2.0, Color(1, 1, 1, 0.28))
		if ic:
			b.draw_texture_rect(ic, Rect2(c - Vector2(3.4, 3.4), Vector2(6.8, 6.8)), false, Color(1, 0.98, 0.92)))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.button_down.connect(b.queue_redraw)
	b.button_up.connect(b.queue_redraw)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	return b


func close_button(cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(12, 12)
	b.size = Vector2(12, 12)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, btn_box("red", st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var xt := hd("close")
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.draw.connect(func():
		var o := 1.0 if b.button_pressed else 0.0
		if xt:
			b.draw_texture_rect(xt, Rect2(Vector2(2.5, 2.0 + o) + Vector2(0.6, 0.8), Vector2(7, 7)), false, Color(0, 0, 0, 0.55))
			b.draw_texture_rect(xt, Rect2(Vector2(2.5, 2.0 + o), Vector2(7, 7)), false, Color("#FFF4EA")))
	b.pressed.connect(cb)
	return b


## Premium frame (see UIFrame). kind: panel | strip | tooltip | plaque | inset
func frame(sz: Vector2, header := false, kind := "panel") -> Control:
	var f := UIFrame.new(kind, header)
	f.size = sz
	return f


func tooltip_bg() -> Control:
	return UIFrame.new("tooltip")


## Slot-style TextureButton replacement: a vector slot that keeps the TextureButton API callers use.
func slot_button(sz := Vector2(20, 20)) -> TextureButton:
	var b := TextureButton.new()
	b.custom_minimum_size = sz
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.draw.connect(func():
		var hov := b.is_hovered()
		var sb := _flat(Color("#0C0F17"), Color("#C9A45C") if hov else Color("#2F3649"), 3)
		b.draw_style_box(sb, Rect2(Vector2.ZERO, b.size)))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	return b


## Gold "selected" frame drawn over a slot.
func selected_frame(sz := Vector2(20, 20)) -> Control:
	var c := Control.new()
	c.size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var glow := _flat(Color(0, 0, 0, 0), Color(1.0, 0.85, 0.4, 0.35), 4, 2)
		glow.draw_center = false
		c.draw_style_box(glow, Rect2(Vector2(-0.5, -0.5), c.size + Vector2(1, 1)))
		var sb := _flat(Color(0, 0, 0, 0), Color("#FFD978"), 3)
		sb.draw_center = false
		c.draw_style_box(sb, Rect2(Vector2.ZERO, c.size)))
	return c


func nine(name: String, margin: int) -> Control:
	match name:
		"tooltip":
			return UIFrame.new("tooltip")
		"plaque":
			return UIFrame.new("plaque")
		"strip_panel":
			return UIFrame.new("strip")
		"parchment":
			return UIFrame.new("parchment")
		"well":
			return UIFrame.new("inset")
	return UIFrame.new("panel")


func bar(w: int, h: int, fill: Color, bg := Color("#0B0E15")) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(w, h)
	p.show_percentage = false
	var r := int(min(h / 2.0, 3.0))
	var b := _flat(bg, Color("#2C3346"), r)
	var f := _flat(fill, fill.lightened(0.35), r, 0)
	f.border_width_top = 1
	p.add_theme_stylebox_override("background", b)
	p.add_theme_stylebox_override("fill", f)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func hsep(w := 10) -> Control:
	var c := ColorRect.new()
	c.color = Color(0.79, 0.64, 0.36, 0.35)
	c.custom_minimum_size = Vector2(w, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func element_color(el: String) -> Color:
	match el:
		"fire":
			return Color("#FF7A33")
		"cold":
			return Color("#7FD8FF")
		"lightning":
			return Color("#FFE45C")
		"chaos":
			return Color("#B266FF")
		"holy":
			return Color("#FFD98A")
	return Color("#FFFFFF")
