extends PanelWindow
## "While you were away" report with collected rewards.

var report: Dictionary = {}
var _body: VBoxContainer


func build(c: Control) -> void:
	_body = W.vbox(2)
	_body.size = c.size
	c.add_child(_body)
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
	for hid in lv:
		_body.add_child(UITheme.label(DataDB.t("away_level", {"name": DataDB.hero_def(hid).get("name", hid), "n": lv[hid]}), UITheme.C_GOLD))
	var items: Array = report.get("items", [])
	if items.size() > 0:
		_body.add_child(UITheme.label(DataDB.t("away_best"), Color("#E8C98A")))
		var row := W.hbox(2)
		_body.add_child(row)
		for it in items:
			var sl := ItemSlot.new()
			sl.set_item(it)
			row.add_child(sl)
	var b := UITheme.button(DataDB.t("btn_collect"), "gold", func():
		AudioManager.play("coins")
		WindowManager.close_panel("away"), Vector2(content.size.x, 13))
	_body.add_child(b)
