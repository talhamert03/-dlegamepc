extends PanelWindow
## Battle ledger: each hero's share of the damage as a framed bar with their portrait, then the party's
## pace (kills a minute, XP and gold an hour, kills this session) in an inked ledger.

var _body: VBoxContainer
var _t := 0.0


func build(c: Control) -> void:
	_body = W.vbox(2)
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
	var w := content.size.x
	_body.add_child(Fancy.section(DataDB.t("dps_sec_share"), w))
	var total := 0.0
	for k in BattleSim.dmg_log:
		total += float(BattleSim.dmg_log[k])
	var secs: float = max(1.0, BattleSim.dmg_log_t)
	var ids: Array = BattleSim.dmg_log.keys()
	ids.sort_custom(func(a, b): return float(BattleSim.dmg_log[a]) > float(BattleSim.dmg_log[b]))
	if ids.is_empty():
		var none := UITheme.label(DataDB.t("dps_none"), UITheme.C_DIM, 8, UITheme.font_body)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.custom_minimum_size = Vector2(w, 14)
		_body.add_child(none)
	for k in ids.slice(0, 6):
		var v: float = float(BattleSim.dmg_log[k])
		var row := W.hbox(3)
		var frame := Control.new()
		frame.custom_minimum_size = Vector2(14, 14)
		var tex := SpriteLib.hero_icon(str(k)) if k != "summon" else UITheme.icon("claw")
		frame.draw.connect(func():
			var ci := frame.get_canvas_item()
			var r := Rect2(Vector2.ZERO, frame.size)
			UISkin.fill(ci, r, 2, Color("#2A1E14"), Color("#120C08"))
			if tex:
				frame.draw_texture_rect(tex, r.grow(-1.0), false)
			UISkin.stroke(ci, r, 2, UISkin.OUTLINE, 1.0)
			UISkin.stroke(ci, r.grow(-0.6), 1.5, Color(UISkin.BRONZE, 0.7), 0.6))
		row.add_child(frame)
		var nm := UITheme.label(str(DataDB.hero_def(k).get("name", DataDB.t("summons"))) if k != "summon" else DataDB.t("summons"), UITheme.C_TEXT, 8, UITheme.font_body)
		nm.custom_minimum_size = Vector2(44, 14)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(nm)
		var share := v / maxf(1.0, total)
		var bar := Fancy.bar(w - 66, 10, share, Color("#E8742A"), "%s/sn · %%%d" % [F.fmt_num(v / secs), int(round(share * 100.0))] if DataDB.lang == "tr" else "%s/s · %d%%" % [F.fmt_num(v / secs), int(round(share * 100.0))])
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		_body.add_child(row)
	_body.add_child(Fancy.section(DataDB.t("dps_sec_pace"), w))
	var r: Dictionary = GameState.rates
	for e in [["skull", DataDB.t("kills_min"), "%.1f" % float(r.get("kills", 0)), UITheme.C_TEXT],
			["star", DataDB.t("xp_hour"), F.fmt_num(float(r.get("xp", 0)) * 60.0), UITheme.C_GREEN],
			["gold", DataDB.t("gold_hour"), F.fmt_num(float(r.get("gold", 0)) * 60.0), UITheme.C_GOLD],
			["sword", DataDB.t("session_kills"), F.fmt_num(float(BattleSim.session["kills"])), UITheme.C_TEXT]]:
		var line := Control.new()
		line.custom_minimum_size = Vector2(w, 13)
		var ic := UITheme.icon(str(e[0]))
		var lab := str(e[1])
		var val := str(e[2])
		var col: Color = e[3]
		line.draw.connect(func():
			var ci := line.get_canvas_item()
			var fb := UITheme.font_body
			if ic:
				line.draw_texture_rect(ic, Rect2(3, 2, 9, 9), false)
			line.draw_string(fb, Vector2(16, 10), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#E8C98A"))
			var vw := fb.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var lw := fb.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			# dotted leader between the label and the value, like a ledger
			var x := 20.0 + lw
			while x < line.size.x - vw - 8.0:
				line.draw_rect(Rect2(x, 8.5, 1, 1), Color(UISkin.BRONZE, 0.35))
				x += 3.0
			line.draw_string(fb, Vector2(line.size.x - vw - 3, 10), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
			UISkin.line(ci, Vector2(3, 12.5), Vector2(line.size.x - 3, 12.5), Color(UISkin.BRONZE, 0.1), 0.6))
		_body.add_child(line)
	_body.add_child(W.spacer(0, 2))
	var rb := UITheme.button(DataDB.t("btn_reset"), "brown", func():
		BattleSim.dmg_log.clear()
		BattleSim.dmg_log_t = 0.0
		refresh(), Vector2(w, 14))
	_body.add_child(rb)
