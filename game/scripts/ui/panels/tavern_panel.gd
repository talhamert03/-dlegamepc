extends PanelWindow
## Tavern: three hero offers (refresh every 4h), recruit with gold + tavern seals.

var _body: VBoxContainer


func build(c: Control) -> void:
	_body = W.vbox(3)
	_body.size = c.size
	c.add_child(_body)
	EventBus.gold_changed.connect(func(_g): refresh())
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	if GameState.max_hero_level() < 8 and GameState.heroes.size() < 4:
		var l := UITheme.label(DataDB.t("tavern_locked"), UITheme.C_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(content.size.x, 0)
		_body.add_child(l)
		return
	Tavern.ensure_offers()
	var info := W.hbox(4)
	_body.add_child(info)
	info.add_child(UITheme.label(DataDB.t("seals", {"n": int(GameState.materials.get("tavern_seal", 0))}), UITheme.C_GOLD))
	var left: int = max(0, int(GameState.tavern.get("refresh_at", 0)) - TimeService.unix_now())
	info.add_child(UITheme.label(DataDB.t("refresh_in", {"t": "%d:%02d" % [left / 3600, (left % 3600) / 60]}), UITheme.C_DIM))
	var rc := Tavern.refresh_cost()
	info.add_child(UITheme.button(DataDB.t("btn_refresh") + " " + F.fmt_num(rc), "brown", func():
		if GameState.spend_gold(rc):
			Tavern.ensure_offers(true)
			refresh(), Vector2(0, 11)))
	var row := W.hbox(4)
	_body.add_child(row)
	var offers: Array = GameState.tavern.get("offers", [])
	if offers.is_empty():
		_body.add_child(UITheme.label(DataDB.t("tavern_empty"), UITheme.C_DIM))
	for hid in offers:
		row.add_child(_card(hid))


func _card(hid: String) -> Control:
	var d := DataDB.hero_def(hid)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.box("tooltip", 3, 3))
	box.custom_minimum_size = Vector2(66, 150)
	var v := W.vbox(1)
	box.add_child(v)
	var img := TextureRect.new()
	img.texture = SpriteLib.portrait(hid)
	img.custom_minimum_size = Vector2(60, 90)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if img.texture and img.texture.has_meta("hd") else CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(img)
	var rc := {"R": UITheme.C_TEXT, "SR": UITheme.C_BLUE, "SSR": UITheme.C_ORANGE}.get(d.get("rarity", "R"), UITheme.C_TEXT)
	var nm := UITheme.label("%s [%s]" % [d.get("name", hid), d.get("rarity", "R")], rc)
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(60, 0)
	v.add_child(nm)
	v.add_child(UITheme.label(DataDB.tx(DataDB.class_def(d["class"]).get("name", {})), UITheme.C_DIM))
	var sig: Dictionary = d.get("signature", {})
	var sl := UITheme.label(DataDB.tx(sig.get("name", {})), UITheme.C_GREEN)
	sl.clip_text = true
	sl.custom_minimum_size = Vector2(60, 0)
	sl.tooltip_text = "%s: +%s" % [StatNames.label(str(sig.get("stat", ""))), StatNames.fmt(str(sig.get("stat", "")), float(sig.get("value", 0)))]
	sl.mouse_filter = Control.MOUSE_FILTER_STOP
	v.add_child(sl)
	var c := Tavern.cost(hid)
	var txt := DataDB.t("free") if int(c["gold"]) == 0 else "%s+%d" % [F.fmt_num(int(c["gold"])), int(c["tavern_seal"])]
	var b := UITheme.button(txt, "gold", func():
		if Tavern.recruit(hid):
			AudioManager.play("recruit")
			refresh()
		else:
			EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED), Vector2(60, 12))
	b.disabled = not Tavern.can_afford(hid)
	v.add_child(b)
	return box
