extends PanelWindow
## Pet collection: pick the active companion, see levels and bonuses.

const SILHOUETTE_SHADER := preload("res://assets/shaders/silhouette.gdshader")
var _silhouette: ShaderMaterial

var _grid: GridContainer
var _info: VBoxContainer
var _sel := ""
var _icons: Dictionary = {}


const RCOL := {"R": Color("#9FDFFF"), "SR": Color("#C89BFF"), "SSR": Color("#FFD84A")}
const STALL := Vector2(40, 50)
var _t := 0.0
var _stalls: Array = []
var _host: Control


## Stable of companions: a collection bar, ten stalls with name plates (owned ones lit, the active one
## marked), and a card for the selected pet with its bonus, level pips and the "take along" button.
func build(c: Control) -> void:
	_host = c
	var v := W.vbox(4)
	v.size = c.size
	c.add_child(v)
	_grid = W.grid(5, 4)
	_info = W.vbox(2)
	var top := Control.new()
	top.custom_minimum_size = Vector2(c.size.x, 12)
	v.add_child(top)
	var gwrap := Control.new()
	gwrap.custom_minimum_size = Vector2(c.size.x, STALL.y * 2 + 4 + 8)
	gwrap.draw.connect(func(): UISkin.well(gwrap.get_canvas_item(), Rect2(Vector2.ZERO, gwrap.size)))
	v.add_child(gwrap)
	gwrap.add_child(_grid)
	_grid.position = Vector2((c.size.x - (STALL.x * 5 + 16)) / 2.0, 4)
	v.add_child(_info)
	_sel = str(GameState.pets.get("active", ""))
	if _sel == "":
		for pid in DataDB.pets.get("pets", {}):
			if GameState.pet_level(pid) > 0:
				_sel = pid
				break
	EventBus.pet_changed.connect(func(_p): refresh())
	set_meta("top", top)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	for s2 in _stalls:
		if is_instance_valid(s2):
			s2.queue_redraw()


## Idle frame cropped to its visible pixels so small creatures fill the slot.
func pet_icon(pid: String) -> Texture2D:
	if _icons.has(pid):
		return _icons[pid]
	var hd := SpriteLib.hd_sprite("pets", pid)
	if hd:
		hd.set_meta("hd", true)
		_icons[pid] = hd
		return hd
	var sf := SpriteLib.frames_for("enemy", "pet_" + pid)
	if sf == null or not sf.has_animation("idle"):
		return null
	var t: Texture2D = sf.get_frame_texture("idle", 0)
	var img := t.get_image()
	var r := img.get_used_rect()
	if r.size.x <= 0:
		return t
	var at := AtlasTexture.new()
	at.atlas = ImageTexture.create_from_image(img)
	at.region = Rect2(r)
	_icons[pid] = at
	return at


func refresh() -> void:
	if _grid == null:
		return
	for ch in _grid.get_children():
		ch.queue_free()
	for ch in _info.get_children():
		ch.queue_free()
	_stalls.clear()
	var all_pets: Dictionary = DataDB.pets.get("pets", {})
	var owned: Dictionary = GameState.pets.get("owned", {})
	var top: Control = get_meta("top")
	for ch in top.get_children():
		ch.queue_free()
	var per := float(DataDB.pets.get("collection_per_pet", {}).get("value", 1.0))
	var bar := Fancy.bar(_host.size.x, 12, float(owned.size()) / maxf(1.0, all_pets.size()), Color("#5FBF5A"),
		DataDB.t("pets_collection", {"n": owned.size(), "m": all_pets.size(), "b": F.pct(per * owned.size(), true)}))
	top.add_child(bar)
	for pid in all_pets:
		_grid.add_child(_stall(pid))
	_build_info()


## One stall: arched wooden frame, straw floor, the creature (a shadow until found), its name plate.
func _stall(pid: String) -> Control:
	var pd := GameState.pet_def(pid)
	var lv := GameState.pet_level(pid)
	var own := lv > 0
	var active := str(GameState.pets.get("active", "")) == pid
	var rcol: Color = RCOL.get(str(pd.get("rarity", "R")), UITheme.C_TEXT)
	var ic := pet_icon(pid)
	var c := Control.new()
	c.custom_minimum_size = STALL
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.tooltip_text = DataDB.tx(pd.get("name", {})) if own else "???"
	c.mouse_entered.connect(func(): c.set_meta("hov", true))
	c.mouse_exited.connect(func(): c.set_meta("hov", false))
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_sel = pid
			AudioManager.play("ui_click", 0.05, 0.5)
			refresh())
	var seed := float(pid.length()) * 0.37
	if ic and not own:
		# not found yet: a flat cool silhouette (same shader as the bestiary) and a small "?" seal
		var art := Control.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.position = Vector2(STALL.x / 2.0 - 14, STALL.y - 44)
		art.size = Vector2(28, 28)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if _silhouette == null:
			_silhouette = ShaderMaterial.new()
			_silhouette.shader = SILHOUETTE_SHADER
		art.material = _silhouette
		art.draw.connect(func(): art.draw_texture_rect(ic, Rect2(Vector2.ZERO, art.size), false))
		c.add_child(art)
		var q := Control.new()
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.position = Vector2(STALL.x / 2.0 + 6, STALL.y - 30)
		q.size = Vector2(10, 10)
		q.draw.connect(func():
			UISkin.circle(q.get_canvas_item(), Vector2(5, 5), 4.6, UISkin.OUTLINE, UISkin.OUTLINE)
			UISkin.circle(q.get_canvas_item(), Vector2(5, 5), 4.0, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
			var fq := UITheme.font_title
			var qw := fq.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			q.draw_string(fq, Vector2(5 - qw / 2.0, 7.6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#2A1606")))
		c.add_child(q)
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2.ZERO, c.size)
		var sel := _sel == pid
		var hov: bool = c.get_meta("hov", false)
		# arched stall
		var arch := PackedVector2Array([Vector2(0, r.size.y), Vector2(0, 8)])
		for k in range(1, 10):
			var a := PI + PI * k / 10.0
			arch.append(Vector2(r.size.x / 2.0 + cos(a) * r.size.x / 2.0, 8 + sin(a) * 8))
		arch.append(Vector2(r.size.x, 8))
		arch.append(Vector2(r.size.x, r.size.y))
		UISkin.poly(ci, arch, Color("#5A3A22") if own else Color("#2E2420"), Color("#2A180C") if own else Color("#161210"))
		# back planks and straw floor
		for k in 4:
			c.draw_line(Vector2(6 + k * 9.0, 10), Vector2(6 + k * 9.0, r.size.y - 14), Color(0, 0, 0, 0.18), 1.0)
		UISkin.fill(ci, Rect2(2, r.size.y - 16, r.size.x - 4, 5), 1, Color("#C9A04E", 0.55 if own else 0.18), Color("#7A5A22", 0.4 if own else 0.12))
		if own:
			for k in 7:
				var x := 4.0 + k * 5.0
				c.draw_line(Vector2(x, r.size.y - 12), Vector2(x + 2, r.size.y - 16), Color("#E8C27A", 0.5), 0.6)
			for k in 4:
				c.draw_circle(Vector2(r.size.x / 2.0, r.size.y - 22), 16.0 - k * 4.0, Color(rcol, 0.05))
		# the creature: bobbing a little when owned
		if ic and own:
			var bob := sin(_t * 2.4 + seed) * 1.2
			var ir := Rect2(r.size.x / 2.0 - 14, r.size.y - 44 + bob, 28, 28)
			c.draw_texture_rect(ic, ir, false, Color.WHITE)
		# name plate
		var nm := DataDB.tx(pd.get("name", {})) if own else "???"
		var pl := Rect2(1, r.size.y - 11, r.size.x - 2, 10)
		UISkin.fill(ci, pl, 2, Color("#3A2614"), Color("#1A0F08"))
		UISkin.stroke(ci, pl, 2, UISkin.OUTLINE, 0.8)
		var f := UITheme.font_body
		var fs := 7
		while fs > 6 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > pl.size.x - 3:
			fs -= 1
		var tw := minf(f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, pl.size.x - 2)
		c.draw_string(f, Vector2(pl.get_center().x - tw / 2.0, pl.end.y - 2.2), nm, HORIZONTAL_ALIGNMENT_LEFT, pl.size.x - 2, fs, rcol if own else UITheme.C_DIM)
		# rarity gem, level, active banner
		UISkin.circle(ci, Vector2(r.size.x - 5, 12), 2.8, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, Vector2(r.size.x - 5, 12), 2.2, rcol.lightened(0.2), rcol.darkened(0.4))
		if own:
			c.draw_string_outline(f, Vector2(3, 17), str(lv), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.9))
			c.draw_string(f, Vector2(3, 17), str(lv), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.C_GOLD)
		var outline := arch.duplicate()
		outline.append(arch[0])
		c.draw_polyline(outline, UISkin.OUTLINE, 1.2, true)
		if active:
			c.draw_polyline(outline, Color("#7CFF9A", 0.85 + 0.15 * sin(_t * 4.0)), 1.0, true)
		elif sel:
			c.draw_polyline(outline, Color("#FFE45C"), 1.2, true)
		elif hov:
			c.draw_polyline(outline, Color(1, 0.9, 0.6, 0.6), 1.0, true))
	_stalls.append(c)
	return c


func _build_info() -> void:
	if _sel == "":
		_info.add_child(_empty_card())
		return
	var pd := GameState.pet_def(_sel)
	if pd.is_empty():
		return
	var lv := GameState.pet_level(_sel)
	var own := lv > 0
	var maxl := int(DataDB.pets.get("max_level", 10))
	var rar: String = str(pd.get("rarity", "R"))
	var rcol: Color = RCOL.get(rar, UITheme.C_TEXT)
	var w := _host.size.x
	var card := Control.new()
	card.custom_minimum_size = Vector2(w, 74)
	var ic := pet_icon(_sel)
	var bon: Dictionary = pd.get("bonus", {})
	var lines: Array = []
	for st in bon:
		var per: float = float(bon[st])
		lines.append("%s %s" % [F.pct(per * maxi(1, lv), true), StatNames.label(st)] + ("   (" + DataDB.t("pet_per_level", {"v": F.pct(per, true)}) + ")"))
	var desc := DataDB.tx(pd.get("desc", {})) if own else _source_text(pd)
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		var r := Rect2(Vector2.ZERO, card.size)
		UISkin.well(ci, r)
		# portrait on a little pedestal
		for k in 4:
			card.draw_circle(Vector2(24, 38), 22.0 - k * 5.0, Color(rcol, 0.06 if own else 0.02))
		card.draw_set_transform(Vector2(24, 58), 0.0, Vector2(1.0, 0.3))
		card.draw_circle(Vector2.ZERO, 16.0, Color("#3A2E36"))
		card.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if ic:
			card.draw_texture_rect(ic, Rect2(6, 18, 36, 36), false, Color.WHITE if own else Color(0.30, 0.31, 0.40, 0.55))
		var f := UITheme.font_title
		var fb := UITheme.font_body
		var x := 50.0
		var nm := DataDB.tx(pd.get("name", {})) if own else "???"
		card.draw_string(f, Vector2(x, 13), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x - 30, 10, rcol if own else UITheme.C_DIM)
		var tag := Rect2(r.size.x - 26, 4, 22, 10)
		UISkin.fill(ci, tag, 2, rcol.lightened(0.15), rcol.darkened(0.35))
		UISkin.stroke(ci, tag, 2, UISkin.OUTLINE, 0.8)
		var rw := fb.get_string_size(rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		card.draw_string(fb, Vector2(tag.get_center().x - rw / 2.0, tag.end.y - 2.4), rar, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#1A1208"))
		# level pips
		for k in maxl:
			var on := k < lv
			UISkin.diamond(ci, Vector2(x + 3 + k * 7.0, 21), 2.4, Color("#FFE08A") if on else Color("#3A3028"), Color("#B07420") if on else Color("#1A140E"))
		var y := 33.0
		for ln in lines:
			card.draw_string(fb, Vector2(x, y), str(ln), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x - 4, 8, Color("#8CFF7A") if own else UITheme.C_DIM)
			y += 10.0
		card.draw_multiline_string(fb, Vector2(x, y + 1), desc, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x - 4, 7, 2, UITheme.C_DIM))
	_info.add_child(card)
	if own:
		var active := str(GameState.pets.get("active", "")) == _sel
		var b := UITheme.button(DataDB.t("pet_active") if active else DataDB.t("pet_set_active"), "green" if active else "gold", func():
			GameState.set_active_pet("" if active else _sel), Vector2(w, 15))
		b.tooltip_text = DataDB.t("pet_toggle_tip")
		_info.add_child(b)


## Nothing picked yet: the same well as the detail card, with an empty pedestal under a claw seal, what pets
## do, and where they come from (boss / tower rows with their icons), so an empty collection is not a dead end.
func _empty_card() -> Control:
	var w := _host.size.x
	var card := Control.new()
	card.custom_minimum_size = Vector2(w, 74)
	var claw := UITheme.icon("claw")
	var srcs := [[UITheme.icon("skull"), DataDB.t("pet_src_act", {"n": "1-4"})], [UITheme.icon("tower"), DataDB.t("pet_src_tower")]]
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		var r := Rect2(Vector2.ZERO, card.size)
		UISkin.well(ci, r)
		for k in 4:
			card.draw_circle(Vector2(24, 40), 22.0 - k * 5.0, Color(UISkin.BRONZE, 0.035))
		card.draw_set_transform(Vector2(24, 58), 0.0, Vector2(1.0, 0.3))
		card.draw_circle(Vector2.ZERO, 16.0, Color("#3A2E36"))
		card.draw_circle(Vector2.ZERO, 11.0, Color("#2A2028"))
		card.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# bronze seal with the claw: "a companion goes here"
		var c := Vector2(24, 42)
		card.draw_circle(c, 12.5, UISkin.OUTLINE)
		card.draw_circle(c, 11.6, UISkin.BRONZE_LO)
		card.draw_circle(c, 10.4, Color("#2A1E16"))
		card.draw_arc(c, 11.0, PI * 1.05, PI * 1.95, 16, Color(UISkin.BRONZE_HI, 0.55), 0.8, true)
		if claw:
			card.draw_texture_rect(claw, Rect2(c - Vector2(7, 7), Vector2(14, 14)), false, Color(0.85, 0.72, 0.5, 0.85))
		var fb := UITheme.font_body
		var x := 50.0
		var tw := r.size.x - x - 6.0
		card.draw_multiline_string(fb, Vector2(x, 12), DataDB.t("pets_hint"), HORIZONTAL_ALIGNMENT_LEFT, tw, 8, 3, Color("#E8D8B8"))
		var y := 46.0
		UISkin.line(ci, Vector2(x, y - 8), Vector2(r.size.x - 6, y - 8), Color(UISkin.BRONZE, 0.25), 0.6)
		for e in srcs:
			if e[0]:
				card.draw_texture_rect(e[0], Rect2(x, y - 7, 8, 8), false)
			# long source lines (EN tower) step down a size instead of being cut off
			var fs := 7 if fb.get_string_size(str(e[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= tw - 11 else 6
			card.draw_string(fb, Vector2(x + 11, y), str(e[1]), HORIZONTAL_ALIGNMENT_LEFT, tw - 11, fs, Color("#C9B08A"))
			y += 11.0)
	return card


func _source_text(pd: Dictionary) -> String:
	var a := int(pd.get("act", 1))
	if a == 0:
		return DataDB.t("pet_src_tower")
	return DataDB.t("pet_src_act", {"n": a})


func _fmt(x: float) -> String:
	return str(int(x)) if absf(x - roundf(x)) < 0.01 else "%.1f" % x
