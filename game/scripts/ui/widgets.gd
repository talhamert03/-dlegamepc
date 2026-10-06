class_name W
extends RefCounted
## Shared UI widget builders.


static func vbox(sep := 1) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	return v


static func hbox(sep := 2) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	return h


static func grid(cols: int, sep := 1) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	return g


static func scroll(size: Vector2) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.custom_minimum_size = size
	s.size = size
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var sb := s.get_v_scroll_bar()
	sb.custom_minimum_size = Vector2(3, 0)
	return s


static func spacer(w := 0, h := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


## Row "Label ....... value"
static func stat_row(label: String, value: String, vcol: Color = UITheme.C_TEXT, lcol: Color = Color("#E8C98A"), width := 150) -> HBoxContainer:
	var h := hbox(0)
	h.custom_minimum_size = Vector2(width, 9)
	var l := UITheme.label(label, lcol)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	var v := UITheme.label(value, vcol)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(l)
	h.add_child(v)
	return h


## Tab strip: returns HBox; calls cb(index) on change.
static func tabs(names: Array, active: int, cb: Callable, w := 0) -> HBoxContainer:
	var h := hbox(2)
	for i in names.size():
		var b := Fancy.tab_button(str(names[i]), i == active, w)
		var idx := i
		b.pressed.connect(func():
			AudioManager.play("ui_click", 0.05, 0.5)
			cb.call(idx))
		h.add_child(b)
	return h


static func set_tab_active(h: HBoxContainer, active: int) -> void:
	for i in h.get_child_count():
		var b := h.get_child(i)
		if b.has_meta("on"):
			b.set_meta("on", i == active)
			b.queue_redraw()
		else:
			UITheme.set_button_color(b, "orange" if i == active else "brown")


static func icon_rect(tex: Texture2D, size := Vector2.ZERO) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	if tex and tex.has_meta("hd"):
		# HD UI art is drawn at its logical size with smooth filtering
		if size == Vector2.ZERO:
			size = tex.get_meta("lsize", Vector2(7, 7))
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if size != Vector2.ZERO:
		t.custom_minimum_size = size
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Row of party hero icons; the selected one is highlighted.
static func hero_selector(selected: String, cb: Callable, include_roster := false) -> HBoxContainer:
	var h := hbox(2)
	var ids: Array = []
	for hid in GameState.party:
		if hid != "":
			ids.append(hid)
	if include_roster:
		for hid in GameState.heroes:
			if not ids.has(hid):
				ids.append(hid)
	for hid in ids:
		var b := TextureButton.new()
		b.texture_normal = UITheme.tex("slot_normal")
		b.texture_hover = UITheme.tex("slot_hover")
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		b.custom_minimum_size = Vector2(20, 20)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = DataDB.hero_def(hid).get("name", hid)
		var ic := icon_rect(SpriteLib.hero_icon(hid))
		ic.position = Vector2(0, 0)
		ic.size = Vector2(20, 20)
		b.add_child(ic)
		if hid == selected:
			var fr := icon_rect(UITheme.tex("slot_selected"))
			fr.size = Vector2(20, 20)
			b.add_child(fr)
		var h2: HeroState = GameState.heroes.get(hid)
		if h2 and (h2.stat_points > 0 or h2.skill_points > 0):
			var dot := UITheme.badge(7.0)
			dot.position = Vector2(14, -2)
			b.add_child(dot)
		var id2: String = hid
		b.pressed.connect(func(): cb.call(id2))
		h.add_child(b)
	return h


static func current_hero() -> String:
	var sel: String = WindowManager.selected_hero
	if sel == "" or not GameState.heroes.has(sel):
		for hid in GameState.party:
			if hid != "":
				sel = hid
				break
		WindowManager.selected_hero = sel
	return sel


static func select_hero(hid: String) -> void:
	WindowManager.selected_hero = hid
	EventBus.hero_stats_changed.emit(hid)
	for id in ["stats", "hero", "skills", "portrait", "inventory"]:
		if id == "stats" and WindowManager.is_open(id):
			WindowManager.panels[id].queue_redraw()
		if WindowManager.is_open(id):
			WindowManager.panels[id].refresh()


## Modal "are you sure?" card laid over `host` (a panel's content): dims it, asks, calls `on_yes`.
static func confirm(host: Control, text: String, on_yes: Callable, yes_text := "", danger := false) -> Control:
	var veil := Control.new()
	veil.size = host.size
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 50
	veil.draw.connect(func(): veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.02, 0.01, 0.03, 0.72)))
	host.add_child(veil)
	var w: float = minf(host.size.x - 16.0, 190.0)
	var card := Control.new()
	card.size = Vector2(w, 66)
	card.position = ((host.size - card.size) / 2.0).round()
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		var r := Rect2(Vector2.ZERO, card.size)
		UISkin.fill(ci, r, 4, Color("#2E2630"), Color("#161118"))
		UISkin.ornate(ci, r.grow(-3.0)))
	veil.add_child(card)
	var l := UITheme.label(text, UITheme.C_TEXT, 8, UITheme.font_body)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(8, 7)
	l.size = Vector2(w - 16, 34)
	card.add_child(l)
	var yes := Fancy.small_button(yes_text if yes_text != "" else DataDB.t("btn_yes"), "red" if danger else "gold", func():
		veil.queue_free()
		on_yes.call(), Vector2(64, 15))
	card.add_child(yes)
	yes.position = Vector2(w / 2.0 - 68, 46)
	var no := Fancy.small_button(DataDB.t("btn_cancel"), "brown", func(): veil.queue_free(), Vector2(64, 15))
	card.add_child(no)
	no.position = Vector2(w / 2.0 + 4, 46)
	return veil
