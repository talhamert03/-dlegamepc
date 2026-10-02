extends Window
## Floating tooltip as its own native window so it can extend beyond panel bounds.

var root: Control
var box: VBoxContainer
var bg: NinePatchRect
var _showing := false


func _init() -> void:
	borderless = true
	transparent = false
	transparent_bg = false
	unfocusable = true
	always_on_top = true
	unresizable = true
	visible = false
	content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	mouse_passthrough = true


func _ready() -> void:
	root = Control.new()
	root.theme = UITheme.theme
	add_child(root)
	bg = UITheme.nine("tooltip", 3)
	root.add_child(bg)
	box = VBoxContainer.new()
	box.position = Vector2(5, 4)
	box.add_theme_constant_override("separation", 1)
	root.add_child(box)


func _clear() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _line(text: String, color: Color = UITheme.C_TEXT, font: Font = null, fsize := 8) -> Label:
	var l := UITheme.label(text, color, fsize, font)
	box.add_child(l)
	return l


func show_text(text: String) -> void:
	_clear()
	for ln in text.split("\n"):
		_line(ln)
	_present()


func show_item(item: Dictionary, compare_hero := "") -> void:
	_clear()
	if item.is_empty():
		hide_tip()
		return
	var r: String = item.get("rarity", "common")
	var col := ItemUtil.rarity_color(r)
	_line(ItemUtil.display_name(item), col, UITheme.font_title, 13)
	var slot_name: String = DataDB.tx(DataDB.items["slot_names"].get(item.get("slot", "") if item.get("slot", "") != "ring" else "ring1", {}))
	var sub := "%s %s  iLvl %d" % [ItemUtil.rarity_name(r), slot_name, int(item.get("ilvl", 1))]
	if item.get("cat", "") == "armor":
		sub += "  " + DataDB.t("weight_" + str(item.get("weight", "medium")))
	_line(sub, UITheme.C_DIM)
	box.add_child(UITheme.hsep(100))
	var base: Dictionary = item.get("base", {})
	var st := ItemUtil.item_stats(item)
	if base.has("atk"):
		_line("%s: %s   %s: %.2f" % [DataDB.t("weapon_damage"), F.fmt_num(float(st.get("weapon_atk", 0))), DataDB.t("aps"), float(base.get("aps", 1.0))])
	if base.has("def"):
		_line("%s: %s" % [StatNames.label("def"), F.fmt_num(float(base["def"]) * (1.0 + float(DataDB.bal("enhance_bonus", [0])[clamp(int(item.get("enhance", 0)), 0, 15)]) / 100.0))])
	if base.has("hp"):
		_line("%s: %s" % [StatNames.label("max_hp"), F.fmt_num(float(base["hp"]))])
	for k in item.get("implicit", {}):
		_line(ItemUtil.affix_label(k, float(item["implicit"][k])), Color("#C9B8E8"))
	if item.get("affixes", []).size() > 0:
		box.add_child(UITheme.hsep(100))
	for a in item.get("affixes", []):
		_line(ItemUtil.affix_label(str(a["id"]), float(a["v"])), UITheme.C_BLUE)
	if item.get("leg", "") != "":
		for l in DataDB.items.get("legendaries", []):
			if l["id"] == item["leg"]:
				box.add_child(UITheme.hsep(100))
				for k in l.get("stats", {}):
					_line(ItemUtil.affix_label(k, float(l["stats"][k])), UITheme.C_ORANGE)
				_line(DataDB.tx(l.get("desc", {})), Color("#FFC08A"))
	if item.get("set", "") != "":
		var sd: Dictionary = DataDB.items["sets"].get(item["set"], {})
		box.add_child(UITheme.hsep(100))
		_line(DataDB.tx(sd.get("name", {})), Color("#3DDC84"))
		for need in sd.get("bonus", {}):
			var parts: Array = []
			for k in sd["bonus"][need]:
				parts.append(ItemUtil.affix_label(k, float(sd["bonus"][need][k])))
			_line("(%s) %s" % [need, ", ".join(parts)], Color("#7FD8A0"))
	if item.get("mythic", false):
		_line(DataDB.t("mythic_power"), Color("#FF6A8A"))
	box.add_child(UITheme.hsep(100))
	_line(DataDB.t("req_level", {"lv": ItemUtil.req_level(item)}), UITheme.C_DIM)
	if compare_hero != "" and GameState.heroes.has(compare_hero):
		var h: HeroState = GameState.heroes[compare_hero]
		var prob := ItemUtil.equip_problem(h, item)
		if prob != "":
			_line(prob, UITheme.C_RED)
		else:
			var slots := ItemUtil.equip_slots(item)
			var cur: Dictionary = h.equipment.get(slots[0], {})
			var diff := ItemUtil.power_score(item, h.cls()) - ItemUtil.power_score(cur, h.cls())
			var txt := DataDB.t("compare_better") if diff > 0 else DataDB.t("compare_worse")
			_line("%s %s (%+d)" % [h.display_name(), txt, int(round(diff))], UITheme.C_GREEN if diff > 0 else UITheme.C_RED)
	_line(DataDB.t("sell_price", {"g": F.fmt_num(ItemUtil.sell_price(item))}), UITheme.C_GOLD)
	if item.get("locked", false):
		_line(DataDB.t("locked"), UITheme.C_DIM)
	_present()


func _present() -> void:
	await get_tree().process_frame
	var sz := box.get_combined_minimum_size() + Vector2(10, 8)
	sz = sz.ceil()
	bg.size = sz
	var sc: int = WindowManager.ui_scale
	content_scale_size = Vector2i(sz)
	size = Vector2i(sz) * sc
	var m := DisplayServer.mouse_get_position()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var p := m + Vector2i(16, -size.y - 8)
	if p.y < usable.position.y:
		p.y = m.y + 16
	if p.x + size.x > usable.end.x:
		p.x = m.x - size.x - 16
	position = p
	visible = true
	_showing = true


func hide_tip() -> void:
	visible = false
	_showing = false
