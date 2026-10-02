extends PanelWindow
## Battle statistics: damage share per hero, kills/min, XP/hour, gold/hour.

var _body: VBoxContainer
var _t := 0.0


func build(c: Control) -> void:
	_body = W.vbox(1)
	_body.size = c.size
	c.add_child(_body)
	refresh()


func _process(d: float) -> void:
	_t += d
	if _t >= 1.0:
		_t = 0.0
		refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	var total := 0.0
	for k in BattleSim.dmg_log:
		total += float(BattleSim.dmg_log[k])
	var secs: float = max(1.0, BattleSim.dmg_log_t)
	var ids: Array = BattleSim.dmg_log.keys()
	ids.sort_custom(func(a, b): return float(BattleSim.dmg_log[a]) > float(BattleSim.dmg_log[b]))
	for k in ids:
		var v: float = float(BattleSim.dmg_log[k])
		var row := W.hbox(2)
		var nm := UITheme.label(DataDB.hero_def(k).get("name", DataDB.t("summons")) if k != "summon" else DataDB.t("summons"), UITheme.C_TEXT)
		nm.custom_minimum_size = Vector2(46, 0)
		nm.clip_text = true
		row.add_child(nm)
		var b := UITheme.bar(60, 4, Color("#E8742A"))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.max_value = max(1.0, total)
		b.value = v
		row.add_child(b)
		row.add_child(UITheme.label("%s/s" % F.fmt_num(v / secs), UITheme.C_GOLD))
		_body.add_child(row)
	_body.add_child(UITheme.hsep(int(content.size.x)))
	var r: Dictionary = GameState.rates
	_body.add_child(W.stat_row(DataDB.t("kills_min"), "%.1f" % float(r.get("kills", 0)), UITheme.C_TEXT, Color("#E8C98A"), int(content.size.x)))
	_body.add_child(W.stat_row(DataDB.t("xp_hour"), F.fmt_num(float(r.get("xp", 0)) * 60.0), UITheme.C_TEXT, Color("#E8C98A"), int(content.size.x)))
	_body.add_child(W.stat_row(DataDB.t("gold_hour"), F.fmt_num(float(r.get("gold", 0)) * 60.0), UITheme.C_GOLD, Color("#E8C98A"), int(content.size.x)))
	_body.add_child(W.stat_row(DataDB.t("session_kills"), str(int(BattleSim.session["kills"])), UITheme.C_TEXT, Color("#E8C98A"), int(content.size.x)))
	_body.add_child(UITheme.button(DataDB.t("btn_reset"), "brown", func():
		BattleSim.dmg_log.clear()
		BattleSim.dmg_log_t = 0.0
		refresh()))
