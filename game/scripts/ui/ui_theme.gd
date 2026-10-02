extends Node
## Pixel UI kit: fonts, nine-slice styleboxes and small widget factories.

const UI := "res://assets/ui/"
const C_TEXT := Color("#F2E6C9")
const C_DIM := Color("#A89A86")
const C_GOLD := Color("#F7C948")
const C_GREEN := Color("#7FE07A")
const C_RED := Color("#FF6A5A")
const C_BLUE := Color("#8FB4FF")
const C_ORANGE := Color("#FF9A4A")
const C_PANEL := Color("#1E1A1F")

var font_small: FontFile
var font_title: FontFile
var font_big: FontFile
var theme: Theme
var _tex: Dictionary = {}


func _ready() -> void:
	font_small = _font("res://assets/fonts/Tiny5.ttf")
	font_title = _font("res://assets/fonts/PixelifySans.ttf")
	font_big = _font("res://assets/fonts/Jersey10.ttf")
	theme = _make_theme()


func _font(path: String) -> FontFile:
	var f: FontFile = load(path)
	if f == null:
		return null
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	f.oversampling = 1.0
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


func icon(name: String) -> Texture2D:
	return tex("icons/" + name)


func box(name: String, margin: int, content := -1) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(name)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	var c := margin if content < 0 else content
	sb.content_margin_left = c
	sb.content_margin_right = c
	sb.content_margin_top = max(1, c - 2)
	sb.content_margin_bottom = max(1, c - 2)
	return sb


func btn_box(color: String, state: String) -> StyleBoxTexture:
	var sb := box("btn_%s_%s" % [color, state], 4, 2)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	if state == "pressed":
		sb.content_margin_top = 3
		sb.content_margin_bottom = 1
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_small
	t.default_font_size = 8
	t.set_color("font_color", "Label", C_TEXT)
	t.set_constant("line_spacing", "Label", 1)
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
		t.set_font("font", c, font_small)
		t.set_font_size("font_size", c, 8)
	t.set_stylebox("panel", "PanelContainer", box("panel", 8, 6))
	t.set_stylebox("panel", "TooltipPanel", box("tooltip", 3, 3))
	var sb_scroll := StyleBoxFlat.new()
	sb_scroll.bg_color = Color("#2A2226")
	t.set_stylebox("scroll", "VScrollBar", sb_scroll)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("#7A5A44")
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_constant("separation", "VBoxContainer", 1)
	t.set_constant("separation", "HBoxContainer", 2)
	return t


# ------------------------------------------------------------------ factories
func label(text: String, color: Color = C_TEXT, size := 8, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font if font else font_small)
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func title_label(text: String, color: Color = C_TEXT) -> Label:
	return label(text, color, 13, font_title)


func button(text: String, color := "brown", cb: Callable = Callable(), min_size := Vector2(0, 12)) -> Button:
	var b := Button.new()
	b.theme = theme
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, btn_box(color, st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", font_small)
	b.add_theme_font_size_override("font_size", 8)
	b.add_theme_color_override("font_color", C_TEXT)
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
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.modulate = Color(0.95, 0.9, 0.85)
	b.mouse_entered.connect(func(): b.modulate = Color(1.2, 1.15, 1.0))
	b.mouse_exited.connect(func(): b.modulate = Color(0.95, 0.9, 0.85))
	b.pressed.connect(cb)
	b.pressed.connect(func(): AudioManager.play("ui_click", 0.05, 0.6))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func nine(name: String, margin: int) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex(name)
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n


func bar(w: int, h: int, fill: Color, bg := Color("#2A2226")) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(w, h)
	p.show_percentage = false
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = Color("#140E10")
	b.set_border_width_all(1)
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	f.border_color = fill.lightened(0.3)
	f.border_width_top = 1
	p.add_theme_stylebox_override("background", b)
	p.add_theme_stylebox_override("fill", f)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func hsep(w := 10) -> Control:
	var c := ColorRect.new()
	c.color = Color("#4A3A30")
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
