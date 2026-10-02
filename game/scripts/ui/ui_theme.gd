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
	font_small = _font("res://assets/fonts/Nunito-700.ttf")
	font_body = _font("res://assets/fonts/Nunito-800.ttf")
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
	var pal: Array = BTN.get(color, BTN["brown"])
	var bg := Color(pal[0])
	var border := Color(pal[1])
	match state:
		"hover":
			bg = Color(pal[2])
			border = border.lightened(0.15)
		"pressed":
			bg = Color(pal[3])
		"disabled":
			bg = Color("#1E222C")
			border = Color("#30353F")
	var sb := _flat(bg, border, 3)
	# subtle bevel: lighter top edge, darker bottom edge
	sb.border_width_top = 1
	sb.border_width_bottom = 2 if state != "pressed" else 1
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 0 if state == "pressed" else 1
	sb.shadow_offset = Vector2(0, 1)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1 if state != "pressed" else 2
	sb.content_margin_bottom = 1 if state != "pressed" else 0
	return sb


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
		t.set_color("font_color", c, C_TEXT)
		t.set_color("font_hover_color", c, Color.WHITE)
		t.set_color("font_pressed_color", c, C_GOLD)
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
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	b.add_theme_constant_override("shadow_offset_y", 1)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", C_DIM)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cb.is_valid():
		b.pressed.connect(cb)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	return b


func set_button_color(b: Button, color: String) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, btn_box(color, st))


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


## Glossy orb button (strip quick actions) with an HD glyph.
func round_button(color: String, glyph: String) -> TextureButton:
	var oc: String = {"red": "red", "green": "green", "blue": "blue"}.get(color, "gold")
	var b := TextureButton.new()
	b.texture_normal = hd("orb_%s_normal" % oc, Vector2(14, 14))
	b.texture_hover = hd("orb_%s_hover" % oc, Vector2(14, 14))
	b.texture_pressed = hd("orb_%s_pressed" % oc, Vector2(14, 14))
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.custom_minimum_size = Vector2(14, 14)
	b.size = Vector2(14, 14)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var g := TextureRect.new()
	g.texture = hd({"town": "town", "dps": "chart", "auto": "auto"}.get(glyph, glyph))
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.position = Vector2(3.5, 3.5)
	g.size = Vector2(7, 7)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.add_child(g)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	return b


func close_button(cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(11, 11)
	b.size = Vector2(11, 11)
	for st in ["normal", "hover", "pressed"]:
		var sb := btn_box("red", st)
		sb.content_margin_left = 1.5
		sb.content_margin_right = 1.5
		sb.content_margin_top = 1.5
		sb.content_margin_bottom = 1.5
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.icon = hd("close")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
