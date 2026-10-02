extends PanelWindow
## Pet collection: pick the active companion, see levels and bonuses.

var _grid: GridContainer
var _info: VBoxContainer
var _sel := ""
var _icons: Dictionary = {}


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	v.add_child(UITheme.label(DataDB.t("pets_hint"), UITheme.C_DIM))
	_grid = W.grid(5, 2)
	v.add_child(_grid)
	v.add_child(UITheme.hsep(int(c.size.x)))
	_info = W.vbox(1)
	v.add_child(_info)
	_sel = str(GameState.pets.get("active", ""))
	EventBus.pet_changed.connect(func(_p): refresh())
	refresh()


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
	var all_pets: Dictionary = DataDB.pets.get("pets", {})
	var active: String = str(GameState.pets.get("active", ""))
	for pid in all_pets:
		var lv := GameState.pet_level(pid)
		var b := TextureButton.new()
		b.texture_normal = UITheme.tex("slot_normal")
		b.texture_hover = UITheme.tex("slot_hover")
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		b.custom_minimum_size = Vector2(26, 26)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.focus_mode = Control.FOCUS_NONE
		var ic := TextureRect.new()
		ic.texture = pet_icon(pid)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(3, 3)
		ic.size = Vector2(20, 20)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ic.texture and ic.texture.has_meta("hd"):
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if lv <= 0:
			ic.modulate = Color(0, 0, 0, 0.75)
		b.add_child(ic)
		if pid == active:
			var fr := W.icon_rect(UITheme.tex("slot_selected"))
			fr.size = Vector2(26, 26)
			fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(fr)
		if lv > 0:
			var l := UITheme.label(str(lv), UITheme.C_GOLD)
			l.position = Vector2(19, 15)
			b.add_child(l)
		var p2: String = pid
		b.pressed.connect(func():
			_sel = p2
			refresh())
		_grid.add_child(b)
	_build_info()


func _build_info() -> void:
	var owned: Dictionary = GameState.pets.get("owned", {})
	_info.add_child(UITheme.label(DataDB.t("pets_owned", {"n": owned.size(), "m": DataDB.pets.get("pets", {}).size()}), UITheme.C_GOLD))
	if _sel == "":
		return
	var pd := GameState.pet_def(_sel)
	if pd.is_empty():
		return
	var lv := GameState.pet_level(_sel)
	var rar: String = str(pd.get("rarity", "R"))
	var rcol: Color = {"R": Color("#9FDFFF"), "SR": Color("#C89BFF"), "SSR": Color("#FFD84A")}.get(rar, UITheme.C_TEXT)
	var head := W.hbox(4)
	head.add_child(UITheme.label(DataDB.tx(pd.get("name", {})) if lv > 0 else "???", UITheme.C_TEXT))
	head.add_child(UITheme.label(rar, rcol))
	if lv > 0:
		head.add_child(UITheme.label(DataDB.t("pet_level", {"n": lv, "m": int(DataDB.pets.get("max_level", 10))}), UITheme.C_DIM))
	_info.add_child(head)
	var bon: Dictionary = pd.get("bonus", {})
	for st in bon:
		var per: float = float(bon[st])
		var cur: float = per * max(1, lv)
		_info.add_child(W.stat_row(StatNames.label(st), "+%s%%  (+%s/%s)" % [_fmt(cur), _fmt(per), DataDB.t("lv_short")], Color("#8CFF7A")))
	var d := UITheme.label(DataDB.tx(pd.get("desc", {})) if lv > 0 else _source_text(pd), UITheme.C_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(190, 0)
	_info.add_child(d)
	if lv > 0:
		var active := str(GameState.pets.get("active", "")) == _sel
		var b := UITheme.button(DataDB.t("pet_active") if active else DataDB.t("pet_set_active"), "gray" if active else "orange", func():
			GameState.set_active_pet("" if active else _sel), Vector2(70, 12))
		_info.add_child(b)


func _source_text(pd: Dictionary) -> String:
	var a := int(pd.get("act", 1))
	if a == 0:
		return DataDB.t("pet_src_tower")
	return DataDB.t("pet_src_act", {"n": a})


func _fmt(x: float) -> String:
	return str(int(x)) if absf(x - roundf(x)) < 0.01 else "%.1f" % x
