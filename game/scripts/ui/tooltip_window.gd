extends Control
## Floating tooltip drawn in the overlay's top layer (never takes input).

var box: VBoxContainer
var bg: Control
var _showing := false


func _ready() -> void:
	theme = UITheme.theme
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 100
	bg = UITheme.tooltip_bg()
	add_child(bg)
	box = VBoxContainer.new()
	box.position = Vector2(6, 5)
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)


func _clear() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _line(text: String, color: Color = UITheme.C_TEXT, font: Font = null, fsize := 8) -> Label:
	var l := UITheme.label(text, color, fsize, font)
	box.add_child(l)
	return l


const WRAP_W := 176.0


## Plain tooltip: the first line of a multi-line tip reads as its heading, long lines wrap instead of
## stretching the tooltip across the screen.
func show_text(text: String) -> void:
	_clear()
	var lines := text.split("\n")
	for i in lines.size():
		var ln: String = lines[i]
		var head := i == 0 and lines.size() > 1 and ln.length() < 40
		var l := _line(ln, UITheme.C_TITLE if head else UITheme.C_TEXT, UITheme.font_body if head else null, 9 if head else 8)
		var w := UITheme.font_small.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		if w > WRAP_W:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = WRAP_W
			l.add_theme_constant_override("line_spacing", 2)
	_present()


func show_item(item: Dictionary, compare_hero := "") -> void:
	_clear()
	if item.is_empty():
		hide_tip()
		return
	var r: String = item.get("rarity", "common")
	var col := ItemUtil.rarity_color(r)
	var slot_name: String = DataDB.tx(DataDB.items["slot_names"].get(item.get("slot", "") if item.get("slot", "") != "ring" else "ring1", {}))
	var sub := "%s %s  ·  %s %d" % [ItemUtil.rarity_name(r), slot_name, DataDB.t("item_level_short"), int(item.get("ilvl", 1))]
	if item.get("cat", "") == "armor":
		sub += "  " + DataDB.t("weight_" + str(item.get("weight", "medium")))
	# header: the item in a rarity-lit slot beside its name and kind
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 5)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(26, 26)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := SpriteLib.item_icon(item)
	ic.draw.connect(func():
		var rr := Rect2(Vector2.ZERO, ic.size)
		for k in 3:
			UISkin.fill(ic.get_canvas_item(), rr.grow(2.0 - k), 4, Color(col, 0.08), Color(col, 0.08))
		UISkin.slot(ic.get_canvas_item(), rr, UISkin.rarity_fill(r), true, false)
		if tex:
			ic.draw_texture_rect(tex, rr.grow(-2.5), false))
	head.add_child(ic)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(names)
	var nl := UITheme.label(ItemUtil.display_name(item), col, 10, UITheme.font_title)
	names.add_child(nl)
	names.add_child(UITheme.label(sub, UITheme.C_DIM, 8))
	var who := ItemUtil.usable_classes(item)
	if who.size() > 0:
		var fam_col := {"heavy": Color("#FF9A7A"), "light": Color("#C9A0FF"), "holy": Color("#FFE7A0"), "medium": Color("#9EE08A")}
		var fc: Color = fam_col.get(str(item.get("weight", "")), Color("#E8C98A"))
		_line(DataDB.t("item_for", {"list": ", ".join(who)}), fc)
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
	_line(DataDB.t("item_hint_dbl"), UITheme.C_DIM)
	if item.get("locked", false):
		_line(DataDB.t("locked"), UITheme.C_DIM)
	_present()


func _present() -> void:
	await get_tree().process_frame
	var sz := (box.get_combined_minimum_size() + Vector2(12, 10)).ceil()
	bg.size = sz
	size = sz
	var area: Vector2 = get_parent().size
	var m: Vector2 = get_parent().get_local_mouse_position()
	var p := m + Vector2(10, -sz.y - 6)
	if p.y < 0:
		p.y = m.y + 12
	if p.x + sz.x > area.x:
		p.x = m.x - sz.x - 10
	position = Vector2(clampf(p.x, 0, max(0.0, area.x - sz.x)), clampf(p.y, 0, max(0.0, area.y - sz.y)))
	visible = true
	_showing = true
	WindowManager.layout_changed()


func hide_tip() -> void:
	if visible:
		visible = false
		WindowManager.layout_changed()
	_showing = false
