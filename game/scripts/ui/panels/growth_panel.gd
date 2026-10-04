extends PanelWindow
## Growth: Faction collection, Guild Hall upgrades, Codex summary.

var tab := 0
var _tabs: HBoxContainer
var _body: VBoxContainer


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.tabs([DataDB.t("tab_faction"), DataDB.t("tab_guild"), DataDB.t("tab_account")], tab, func(i):
		tab = i
		W.set_tab_active(_tabs, i)
		refresh(), (c.size.x - 4.0) / 3.0)
	v.add_child(_tabs)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 16))
	v.add_child(sc)
	_body = W.vbox(3)
	_body.custom_minimum_size = Vector2(c.size.x - 6, 0)
	sc.add_child(_body)
	EventBus.hero_unlocked.connect(func(_h): refresh())
	EventBus.gold_changed.connect(func(_g):
		if tab == 1:
			refresh())
	refresh()


func refresh() -> void:
	if _body == null:
		return
	for ch in _body.get_children():
		ch.queue_free()
	match tab:
		0:
			_factions()
		1:
			_guild()
		2:
			_account()


func _factions() -> void:
	var hint := UITheme.label(DataDB.t("faction_party_hint"), UITheme.C_DIM, 7)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(content.size.x - 8, 0)
	_body.add_child(hint)
	var counts := GameState.faction_counts()
	for f in DataDB.factions:
		var fd: Dictionary = DataDB.factions[f]
		var members: Array = DataDB.hero_order.filter(func(h): return DataDB.hero_def(h).get("faction", "") == f)
		var c := int(counts.get(f, 0))
		var active := c >= 2
		var fcol := Color(str(fd.get("color", "#FFFFFF")))
		var hdr := W.hbox(3)
		var nm := UITheme.label(DataDB.tx(fd["name"]), fcol.lightened(0.2), 9, UITheme.font_title)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hdr.add_child(nm)
		# active / inactive pill
		var pill := Control.new()
		pill.custom_minimum_size = Vector2(52, 11)
		var ptxt := ("✔ " + DataDB.t("faction_active")) if active else DataDB.t("faction_inactive")
		pill.draw.connect(func():
			var ci := pill.get_canvas_item()
			var r := Rect2(Vector2.ZERO, pill.size)
			UISkin.fill(ci, r, 5, Color("#3FA34D") if active else Color("#3A3640"), Color("#1F5A27") if active else Color("#1E1C22"))
			UISkin.stroke(ci, r, 5, Color(0, 0, 0, 0.9), 1.0)
			var fnt := UITheme.font_body
			var tw := fnt.get_string_size(ptxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			pill.draw_string(fnt, Vector2((r.size.x - tw) / 2.0, 8.5), ptxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE if active else UITheme.C_DIM))
		pill.tooltip_text = DataDB.t("faction_count", {"n": c})
		pill.mouse_filter = Control.MOUSE_FILTER_STOP
		hdr.add_child(pill)
		_body.add_child(hdr)
		var stat: String = fd.get("bonus_stat", "")
		var cur := float(fd.get("bonus_per2", 0)) * float(c / 2)
		var nxt := float(fd.get("bonus_per2", 0)) * float(c / 2 + 1)
		var bl := UITheme.label(DataDB.t("collection_bonus", {"stat": StatNames.label(stat), "v": StatNames.fmt(stat, cur), "n": StatNames.fmt(stat, nxt)}),
			UITheme.C_GREEN if active else UITheme.C_DIM, 7)
		_body.add_child(bl)
		var g := W.grid(10, 1)
		_body.add_child(g)
		for hid in members:
			var holder := Control.new()
			holder.custom_minimum_size = Vector2(20, 20)
			var in_party := GameState.party.has(hid)
			var owned := GameState.heroes.has(hid)
			var tex := SpriteLib.hero_icon(hid)
			holder.draw.connect(func():
				var ci := holder.get_canvas_item()
				var r := Rect2(Vector2.ZERO, holder.size)
				UISkin.fill(ci, r, 2, Color("#2A2428"), Color("#141016"))
				if tex:
					holder.draw_texture_rect(tex, r.grow(-1.0), false, Color.WHITE if in_party else (Color(0.55, 0.55, 0.6) if owned else Color(0.08, 0.08, 0.1)))
				UISkin.stroke(ci, r, 2, Color(0, 0, 0, 0.9), 1.2)
				if in_party:
					UISkin.stroke(ci, r.grow(-0.5), 2, Color("#7CFF9A"), 1.0))
			holder.mouse_filter = Control.MOUSE_FILTER_STOP
			holder.tooltip_text = "%s (%s)\n%s" % [DataDB.hero_def(hid)["name"], DataDB.hero_def(hid).get("rarity", "R"),
				DataDB.t("faction_in_party") if in_party else (DataDB.t("owned") if owned else DataDB.t("how_to_get_tavern"))]
			g.add_child(holder)
		_body.add_child(UITheme.hsep(int(content.size.x - 8)))


func _guild() -> void:
	_body.add_child(UITheme.label(DataDB.t("guild_hint"), UITheme.C_DIM))
	_body.add_child(W.stat_row(DataDB.t("gold"), F.fmt_num(GameState.gold), UITheme.C_GOLD, UITheme.C_TEXT, int(content.size.x - 8)))
	_body.add_child(W.stat_row(ItemUtil.material_name("guild_badge"), str(int(GameState.materials.get("guild_badge", 0))), UITheme.C_TEXT, UITheme.C_TEXT, int(content.size.x - 8)))
	for br in GuildHall.BRANCHES:
		_body.add_child(UITheme.label(DataDB.t("guild_" + br), UITheme.C_ORANGE))
		for nid in GuildHall.NODES:
			var nd: Dictionary = GuildHall.NODES[nid]
			if nd["branch"] != br:
				continue
			var lv := int(GameState.guild.get(nid, 0))
			var row := W.hbox(2)
			var l := UITheme.label("%s %d/%d" % [GuildHall.node_name(nid), lv, int(nd["max"])], UITheme.C_TEXT)
			l.custom_minimum_size = Vector2(110, 0)
			l.clip_text = true
			row.add_child(l)
			var eff := UITheme.label("+" + StatNames.fmt(str(nd["stat"]), float(nd["per"]) * max(1, lv)), UITheme.C_GREEN if lv > 0 else UITheme.C_DIM)
			eff.custom_minimum_size = Vector2(40, 0)
			row.add_child(eff)
			if lv < int(nd["max"]):
				var c := GuildHall.cost(nid, lv + 1)
				var txt := F.fmt_num(int(c["gold"]))
				if int(c["guild_badge"]) > 0:
					txt += "+%dB" % int(c["guild_badge"])
				var id2: String = nid
				var b := UITheme.button(txt, "gold", func():
					if GuildHall.buy(id2):
						BattleSim.refresh_hero_stats()
						refresh()
					else:
						EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED), Vector2(50, 11))
				b.disabled = GameState.gold < int(c["gold"]) or not GameState.has_material("guild_badge", int(c["guild_badge"]))
				row.add_child(b)
			_body.add_child(row)


func _account() -> void:
	var t: Dictionary = GameState.totals
	var rows := [["acc_kills", F.fmt_num(int(t.get("kills", 0)))], ["acc_gold", F.fmt_num(int(t.get("gold", 0)))],
		["acc_items", F.fmt_num(int(t.get("items", 0)))], ["acc_legendaries", str(int(t.get("legendaries", 0)))],
		["acc_bosses", str(int(t.get("bosses", 0)))], ["acc_deaths", str(int(t.get("deaths", 0)))],
		["acc_playtime", _hms(float(t.get("playtime", 0)))], ["acc_offline", _hms(float(t.get("offline", 0)))],
		["acc_heroes", "%d / %d" % [GameState.heroes.size(), DataDB.hero_order.size()]],
		["acc_codex_enemies", "%d / %d" % [GameState.codex["enemies"].size(), DataDB.enemies.size() + DataDB.bosses.size()]],
		["acc_codex_legendaries", "%d / %d" % [GameState.codex["legendaries"].size(), DataDB.items.get("legendaries", []).size()]]]
	for r in rows:
		_body.add_child(W.stat_row(DataDB.t(r[0]), r[1], UITheme.C_TEXT, Color("#E8C98A"), int(content.size.x - 8)))
	_body.add_child(UITheme.hsep(int(content.size.x - 8)))
	_body.add_child(UITheme.label(DataDB.t("account_bonuses"), UITheme.C_ORANGE))
	var acc := GameState.account_mods()
	for k in acc:
		_body.add_child(W.stat_row(StatNames.label(k), "+" + StatNames.fmt(k, float(acc[k])), UITheme.C_GREEN, UITheme.C_TEXT, int(content.size.x - 8)))


func _hms(s: float) -> String:
	var h := int(s / 3600)
	var m := int(fmod(s, 3600) / 60)
	return "%dsa %ddk" % [h, m] if DataDB.lang == "tr" else "%dh %dm" % [h, m]
