extends PanelWindow
## "While you were away" report with collected rewards.

var report: Dictionary = {}
var _body: VBoxContainer


func build(c: Control) -> void:
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 18))
	c.add_child(sc)
	_body = W.vbox(2)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	var b := UITheme.button(DataDB.t("btn_collect"), "gold", func():
		AudioManager.play("coins")
		WindowManager.close_panel("away"), Vector2(c.size.x, 15))
	c.add_child(b)
	b.size = Vector2(c.size.x, 15)
	b.position = Vector2(0, c.size.y - 15)
	refresh()


func set_report(r: Dictionary) -> void:
	report = r
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	if report.is_empty():
		return
	var s := int(report.get("seconds", 0))
	_body.add_child(UITheme.label(DataDB.t("away_time", {"h": s / 3600, "m": (s % 3600) / 60}), UITheme.C_TEXT))
	_body.add_child(UITheme.label(DataDB.t("away_eff", {"p": int(round(float(report.get("eff", 0.6)) * 100))}), UITheme.C_DIM))
	var w := int(content.size.x)
	_body.add_child(W.stat_row(DataDB.t("away_kills"), F.fmt_num(int(report.get("kills", 0))), UITheme.C_TEXT, Color("#E8C98A"), w))
	_body.add_child(W.stat_row(DataDB.t("away_xp"), F.fmt_num(float(report.get("xp", 0))), UITheme.C_GREEN, Color("#E8C98A"), w))
	_body.add_child(W.stat_row(DataDB.t("gold"), F.fmt_num(int(report.get("gold", 0))), UITheme.C_GOLD, Color("#E8C98A"), w))
	_body.add_child(W.stat_row(DataDB.t("away_items"), str(int(report.get("item_count", 0))), UITheme.C_TEXT, Color("#E8C98A"), w))
	var lv: Dictionary = report.get("levels", {})
	var parts: Array = []
	for hid in lv:
		parts.append(DataDB.t("away_level", {"name": DataDB.hero_def(hid).get("name", hid), "n": lv[hid]}))
	if parts.size() > 0:
		var ll := UITheme.label("  ".join(parts), UITheme.C_GOLD)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(content.size.x - 6, 0)
		_body.add_child(ll)
	var items: Array = report.get("items", [])
	if items.size() > 0:
		_body.add_child(UITheme.label(DataDB.t("away_best"), Color("#E8C98A")))
		var row := W.hbox(2)
		_body.add_child(row)
		for it in items:
			var sl := ItemSlot.new(26.0)
			sl.set_item(it)
			row.add_child(sl)
