extends PanelWindow
## Hero portrait in front of a stained-glass window, with level / EXP / stars / faction.

var _glass: Control
var _img: TextureRect
var _lvl: Label
var _name: Label
var _xp: ProgressBar
var _xpl: Label
var _stars: Label
var _fac: Label
var _costume: Label
const PORTRAIT_SHADER := preload("res://assets/shaders/portrait.gdshader")


func build(c: Control) -> void:
	_glass = Control.new()
	_glass.size = Vector2(c.size.x, 176)
	_glass.draw.connect(_draw_glass)
	c.add_child(_glass)
	_img = TextureRect.new()
	_img.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_img.size = Vector2(c.size.x, 160)
	_img.position = Vector2(0, 12)
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_img)
	_name = UITheme.title_label("")
	_name.position = Vector2(0, 176)
	_name.size = Vector2(c.size.x, 14)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_name)
	_stars = UITheme.label("", UITheme.C_GOLD)
	_stars.position = Vector2(0, 189)
	_stars.size = Vector2(c.size.x, 9)
	_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_stars)
	_fac = UITheme.label("", UITheme.C_DIM)
	_fac.position = Vector2(0, 197)
	_fac.size = Vector2(c.size.x, 9)
	_fac.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_fac)
	var plate := UITheme.nine("plaque", 6)
	plate.position = Vector2(2, 207)
	plate.size = Vector2(c.size.x - 4, 16)
	c.add_child(plate)
	_lvl = UITheme.title_label("Lv.1")
	_lvl.position = Vector2(6, 207)
	c.add_child(_lvl)
	_xpl = UITheme.label("", UITheme.C_TEXT)
	_xpl.position = Vector2(46, 206)
	c.add_child(_xpl)
	_xp = UITheme.bar(int(c.size.x - 52), 3, Color("#F2B33D"))
	_xp.position = Vector2(46, 215)
	c.add_child(_xp)
	_img.material = ShaderMaterial.new()
	_img.material.shader = PORTRAIT_SHADER
	var crow := W.hbox(2)
	crow.position = Vector2(4, 160)
	c.add_child(crow)
	crow.add_child(UITheme.button("<", "brown", func(): _cycle_costume(-1), Vector2(12, 11)))
	_costume = UITheme.label("", UITheme.C_TEXT)
	_costume.custom_minimum_size = Vector2(c.size.x - 40, 0)
	_costume.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crow.add_child(_costume)
	crow.add_child(UITheme.button(">", "brown", func(): _cycle_costume(1), Vector2(12, 11)))
	EventBus.hero_leveled.connect(func(_h, _l): refresh())
	refresh()


func _cycle_costume(dir: int) -> void:
	var hid := W.current_hero()
	if hid == "":
		return
	var h: HeroState = GameState.heroes[hid]
	var opts: Array = [""] + Costumes.unlocked()
	var i: int = max(0, opts.find(h.costume))
	h.costume = str(opts[(i + dir + opts.size()) % opts.size()])
	EventBus.equipment_changed.emit(hid)
	refresh()


func _process(_d: float) -> void:
	var hid := W.current_hero()
	if hid != "" and _xp:
		var h: HeroState = GameState.heroes[hid]
		_xp.max_value = F.xp_required(h.level)
		_xp.value = h.xp
		_xpl.text = "EXP %s/%s" % [F.fmt_num(h.xp), F.fmt_num(F.xp_required(h.level))]


func refresh() -> void:
	var hid := W.current_hero()
	if hid == "" or _img == null:
		return
	var h: HeroState = GameState.heroes[hid]
	set_panel_title(h.class_title())
	_img.texture = SpriteLib.portrait(hid)
	Costumes.apply(_img.material as ShaderMaterial, hid)
	var cd: Dictionary = Costumes.defs().get(h.costume, {})
	_costume.text = "%s: %s (%d/%d)" % [DataDB.t("costume"), DataDB.tx(cd.get("name", {})) if not cd.is_empty() else DataDB.t("costume_default"),
		Costumes.unlocked().size() + 1, Costumes.defs().size() + 1]
	_costume.tooltip_text = "\n".join(Costumes.defs().keys().map(func(k): return ("✓ " if Costumes.is_unlocked(k) else "✗ ") + DataDB.tx(Costumes.defs()[k].get("name", {})) + " — " + DataDB.tx(Costumes.defs()[k].get("hint", {}))))
	_name.text = h.display_name()
	_name.add_theme_color_override("font_color", {"R": UITheme.C_TEXT, "SR": UITheme.C_BLUE, "SSR": UITheme.C_ORANGE}.get(h.def().get("rarity", "R"), UITheme.C_TEXT))
	_stars.text = "★".repeat(h.stars) + "☆".repeat(6 - h.stars)
	_fac.text = DataDB.tx(DataDB.factions.get(h.def().get("faction", ""), {}).get("name", {}))
	_lvl.text = "Lv.%d" % h.level
	_glass.queue_redraw()


func _draw_glass() -> void:
	# stained glass window: lead frame + coloured panes tinted by faction colour
	var hid := W.current_hero()
	var fac: String = DataDB.hero_def(hid).get("faction", "empire") if hid != "" else "empire"
	var fc := Color(str(DataDB.factions.get(fac, {}).get("color", "#7A5A44")))
	var r := Rect2(6, 4, _glass.size.x - 12, 168)
	_glass.draw_rect(r, Color("#140E10"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fac)
	var cols := [fc.darkened(0.35), fc.darkened(0.55), Color("#3A2A4A"), Color("#2A3A5A"), Color("#5A2A2A"), fc.darkened(0.2)]
	var cx := r.position.x + r.size.x / 2.0
	var cy := r.position.y + r.size.y * 0.42
	# radial panes
	var rings := [18.0, 38.0, 60.0, 90.0]
	for ri in rings.size():
		var segs := 6 + ri * 4
		for s in segs:
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			var r0: float = 0.0 if ri == 0 else rings[ri - 1]
			var r1: float = rings[ri]
			var pts := PackedVector2Array()
			for a in [a0, a1]:
				pts.append(Vector2(cx + cos(a) * r0, cy + sin(a) * r0 * 1.25))
			for a in [a1, a0]:
				pts.append(Vector2(cx + cos(a) * r1, cy + sin(a) * r1 * 1.25))
			var col: Color = cols[rng.randi() % cols.size()]
			col = col.lerp(Color("#E8D9A8"), 0.05 * (3 - ri))
			_glass.draw_colored_polygon(_clip_poly(pts, r), col)
			_glass.draw_polyline(_clip_poly(pts, r) + PackedVector2Array([_clip_poly(pts, r)[0]]), Color("#140E10"), 1.0)
	# arch frame
	_glass.draw_rect(r, Color("#5C4033"), false, 2.0)
	_glass.draw_rect(r.grow(-3), Color("#3A2A22"), false, 1.0)


func _clip_poly(pts: PackedVector2Array, r: Rect2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(clamp(p.x, r.position.x, r.end.x), clamp(p.y, r.position.y, r.end.y)))
	return out
