extends PanelWindow
## Daily quests as parchment notices pinned to a board: the task, a framed progress bar, the rewards as
## icons and a wax-seal claim button (a "claimed" stamp once taken).

const MAT_ICON := {"gold": "gold", "iron_scrap": "mat_iron_scrap", "shiny_essence": "mat_shiny_essence", "epic_essence": "mat_epic_essence", "legendary_essence": "mat_legendary_essence", "star_dust": "mat_star_dust", "mythic_essence": "mat_mythic_essence", "soul_shard": "mat_soul_shard", "tavern_seal": "mat_tavern_seal", "guild_badge": "mat_guild_badge"}

var _body: VBoxContainer


func build(c: Control) -> void:
	var sc := W.scroll(c.size)
	c.add_child(sc)
	_body = W.vbox(4)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	refresh()


func refresh() -> void:
	if _body == null:
		return
	Quests.ensure_daily()
	for ch in _body.get_children():
		ch.queue_free()
	var w := _body.custom_minimum_size.x
	_body.add_child(Fancy.section(DataDB.t("daily_quests"), w))
	var list: Array = GameState.flags.get("daily", {}).get("list", [])
	for i in list.size():
		_body.add_child(_notice(i, list[i], w))
	# when the board refreshes (local midnight)
	var clock := Label.new()
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock.custom_minimum_size = Vector2(w, 10)
	clock.add_theme_font_override("font", UITheme.font_body)
	clock.add_theme_font_size_override("font_size", 7)
	clock.add_theme_color_override("font_color", UITheme.C_DIM)
	clock.set_meta("refresh_clock", true)
	_body.add_child(clock)
	_tick_clock(clock)


func _notice(i: int, q: Dictionary, w: float) -> Control:
	var target := float(q["target"])
	var p: float = minf(Quests.progress(q), target)
	var done := p >= target
	var claimed: bool = q["claimed"]
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 44)
	var title := DataDB.t("quest_" + str(q["id"]), {"n": F.fmt_num(target)})
	var seed := float(i) * 1.7
	c.draw.connect(func():
		var ci := c.get_canvas_item()
		var r := Rect2(Vector2(2, 2), c.size - Vector2(4, 3))
		c.draw_set_transform(r.get_center(), sin(seed) * 0.012, Vector2.ONE)
		var rr := Rect2(-r.size / 2.0, r.size)
		UISkin.fill(ci, Rect2(rr.position + Vector2(1, 2), rr.size), 2, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.4))
		UISkin.parchment(ci, rr)
		if claimed:
			c.draw_rect(rr, Color(0.1, 0.08, 0.06, 0.35))
		# nail at the top
		UISkin.rivet(ci, Vector2(0, rr.position.y + 3.0), 1.5)
		c.draw_string(UITheme.font_body, rr.position + Vector2(7, 13), title, HORIZONTAL_ALIGNMENT_LEFT, rr.size.x - 60, 8, UISkin.INK)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	var bar := Fancy.bar(w - 66, 9, p / maxf(1.0, target), Color("#5FBF5A") if not done else Color("#E8B84A"), "%s / %s" % [F.fmt_num(p), F.fmt_num(target)])
	bar.position = Vector2(9, 18)
	bar.size = bar.custom_minimum_size
	c.add_child(bar)
	# rewards: icon + amount
	var rx := 9.0
	for k in q["reward"]:
		var amt := F.fmt_num(float(q["reward"][k]))
		var ic := UITheme.icon(MAT_ICON.get(str(k), "gem"))
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.tooltip_text = DataDB.t("gold") if k == "gold" else ItemUtil.material_name(str(k))
		var tw := UITheme.font_body.get_string_size(amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		holder.position = Vector2(rx, 30)
		holder.size = Vector2(tw + 12, 10)
		holder.draw.connect(func():
			if ic:
				holder.draw_texture_rect(ic, Rect2(0, 1, 8, 8), false)
			holder.draw_string(UITheme.font_body, Vector2(10, 8), amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UISkin.INK))
		c.add_child(holder)
		rx += tw + 18.0
	# wax seal claim button
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(46, 26)
	b.position = Vector2(w - 52, 11)
	b.disabled = claimed or not done
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not b.disabled else Control.CURSOR_ARROW
	var idx := i
	b.pressed.connect(func():
		if Quests.claim(idx):
			AudioManager.play("coins")
		refresh())
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var ctr := b.size / 2.0
		var f := UITheme.font_title
		if claimed:
			var t := UITheme.upper(DataDB.t("claimed"))
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			b.draw_set_transform(ctr, -0.2, Vector2.ONE)
			var sr := Rect2(-tw / 2.0 - 4, -6, tw + 8, 12)
			UISkin.stroke(ci, sr, 2, Color("#2E7A3A", 0.85), 1.2)
			b.draw_string(f, Vector2(-tw / 2.0, 2.6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#2E7A3A", 0.9))
			b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		var hov := b.is_hovered() and done
		var wax := Color("#B3141E") if done else Color("#6A5E58")
		if done:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
			b.draw_circle(ctr, 12.5, Color(1.0, 0.8, 0.4, 0.15 + 0.15 * pulse))
		# irregular wax blob
		var pts := PackedVector2Array()
		for k in 14:
			var a := TAU * k / 14.0
			var rad := 10.5 + (1.2 if k % 2 == 0 else 0.0)
			pts.append(ctr + Vector2(cos(a), sin(a)) * rad)
		UISkin.poly(ci, pts, wax.lightened(0.2 if hov else 0.05), wax.darkened(0.35))
		UISkin.ring(ci, ctr, 7.5, Color(0, 0, 0, 0.35), 1.0)
		var t := DataDB.t("btn_claim")
		# fit inside the 15 px seal (CLAIM is wider than AL)
		var fs := 8
		while fs > 5 and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 15.0:
			fs -= 1
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		b.draw_string(f, ctr + Vector2(-tw / 2.0, fs * 0.37), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FFE7C8") if done else Color("#C8BEB8")))
	if done and not claimed:
		var tm := Timer.new()
		tm.wait_time = 0.05
		tm.autostart = true
		tm.timeout.connect(b.queue_redraw)
		b.add_child(tm)
	c.add_child(b)
	return c


var _clock_t := 0.0


func _process(delta: float) -> void:
	_clock_t += delta
	if _clock_t < 1.0 or _body == null:
		return
	_clock_t = 0.0
	for ch in _body.get_children():
		if ch.has_meta("refresh_clock"):
			_tick_clock(ch)
	if Quests.today() != str(GameState.flags.get("daily", {}).get("date", "")):
		refresh()


func _tick_clock(l: Label) -> void:
	var t := Time.get_time_dict_from_system()
	var left := 86400 - (int(t["hour"]) * 3600 + int(t["minute"]) * 60 + int(t["second"]))
	var txt := ("%d sa %d dk" % [left / 3600, (left % 3600) / 60]) if DataDB.lang == "tr" else ("%dh %dm" % [left / 3600, (left % 3600) / 60])
	l.text = "↺ " + DataDB.t("refresh_in", {"t": txt})

