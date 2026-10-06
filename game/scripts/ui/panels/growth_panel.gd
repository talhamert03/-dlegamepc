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


const BRANCH_ICON := {"war": "sword", "defense": "shield", "wealth": "gold", "time": "clock", "explore": "map"}


## Guild hall: a purse plate with gold and badges, then each branch as a section of upgrade cards
## (medallion, name, level pips, now -> next, price button).
func _guild() -> void:
	var w := content.size.x - 8
	var hint := UITheme.para(DataDB.t("guild_hint"), w, UITheme.C_DIM, 7)
	_body.add_child(hint)
	var purse := Control.new()
	purse.custom_minimum_size = Vector2(w, 16)
	purse.draw.connect(func():
		var ci := purse.get_canvas_item()
		var r := Rect2(Vector2.ZERO, purse.size)
		UISkin.well(ci, r)
		var f := UITheme.font_title
		var half := r.size.x / 2.0
		purse.draw_texture_rect(UITheme.icon("gold"), Rect2(6, 2, 12, 12), false)
		purse.draw_string(f, Vector2(21, 11.5), F.fmt_num(GameState.gold), HORIZONTAL_ALIGNMENT_LEFT, half - 24, 9, Color("#FFD86A"))
		purse.draw_texture_rect(UITheme.icon("flag"), Rect2(half + 6, 2, 12, 12), false)
		purse.draw_string(f, Vector2(half + 21, 11.5), "%d  %s" % [int(GameState.materials.get("guild_badge", 0)), ItemUtil.material_name("guild_badge")],
			HORIZONTAL_ALIGNMENT_LEFT, half - 24, 9, Color("#E8D8B8")))
	_body.add_child(purse)
	for br in GuildHall.BRANCHES:
		_body.add_child(Fancy.section(DataDB.t("guild_" + br), w))
		for nid in GuildHall.NODES:
			if GuildHall.NODES[nid]["branch"] == br:
				_body.add_child(_guild_card(nid, str(BRANCH_ICON.get(br, "star")), w))


func _guild_card(nid: String, icon: String, w: float) -> Control:
	var nd: Dictionary = GuildHall.NODES[nid]
	var lv := int(GameState.guild.get(nid, 0))
	var mx := int(nd["max"])
	var st := str(nd["stat"])
	var per := float(nd["per"])
	var card := Control.new()
	card.custom_minimum_size = Vector2(w, 24)
	var now := ("+" + StatNames.fmt(st, per * lv)) if lv > 0 else "—"
	var nxt := ("→ +" + StatNames.fmt(st, per * (lv + 1))) if lv < mx else DataDB.t("guild_max")
	card.tooltip_text = StatNames.label(st)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.draw.connect(func():
		var ci := card.get_canvas_item()
		var r := Rect2(Vector2.ZERO, card.size)
		UISkin.fill(ci, r, 3, Color("#2E221A") if lv > 0 else Color("#221A16"), Color("#18110C"))
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		if lv >= mx:
			UISkin.stroke(ci, r.grow(-1.0), 2, Color("#FFD86A", 0.5), 0.8)
		UISkin.medallion(ci, Vector2(12, 12), 9.0, "normal", lv > 0)
		card.draw_texture_rect(UITheme.icon(icon), Rect2(6, 6, 12, 12), false, Color.WHITE if lv > 0 else Color(0.6, 0.55, 0.5))
		var fb := UITheme.font_body
		card.draw_string(fb, Vector2(25, 10), GuildHall.node_name(nid), HORIZONTAL_ALIGNMENT_LEFT, 82, 8, UITheme.C_TEXT if lv > 0 else Color("#C8B8A0"))
		for k in mx:
			var on := k < lv
			UISkin.diamond(ci, Vector2(27 + k * 6.0, 17.5), 2.4, Color("#FFE08A") if on else Color("#6A5A46"), Color("#B07420") if on else Color("#3A2E22"))
		var ex := 27.0 + mx * 6.0 + 2.0
		card.draw_string(fb, Vector2(ex, 20), now, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#8CFF7A") if lv > 0 else UITheme.C_DIM)
		var nw := fb.get_string_size(now, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		card.draw_string(fb, Vector2(ex + nw + 3, 20), nxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#C9B08A")))
	if lv < mx:
		var c := GuildHall.cost(nid, lv + 1)
		var txt := F.fmt_num(int(c["gold"]))
		if int(c["guild_badge"]) > 0:
			txt += " +%d⚑" % int(c["guild_badge"])
		var ok := GameState.gold >= int(c["gold"]) and GameState.has_material("guild_badge", int(c["guild_badge"]))
		var b := Fancy.small_button(txt, "gold", func():
			if GuildHall.buy(nid):
				BattleSim.refresh_hero_stats()
				AudioManager.play("smith_success", 0.05, 0.5)
				refresh()
			else:
				EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED), Vector2(54, 14))
		b.disabled = not ok
		b.tooltip_text = DataDB.t("guild_cost_tip", {"g": F.fmt_num(int(c["gold"])), "b": int(c["guild_badge"])})
		b.position = Vector2(w - 58, 5)
		card.add_child(b)
	return card


## Account ledger: two columns of small tiles (icon, value, label), then the permanent account bonuses.
func _account() -> void:
	var w := content.size.x - 8
	var t: Dictionary = GameState.totals
	var rows := [["sword", "acc_kills", F.fmt_num(int(t.get("kills", 0)))], ["gold", "acc_gold", F.fmt_num(int(t.get("gold", 0)))],
		["bag", "acc_items", F.fmt_num(int(t.get("items", 0)))], ["star", "acc_legendaries", str(int(t.get("legendaries", 0)))],
		["crown", "acc_bosses", str(int(t.get("bosses", 0)))], ["skull", "acc_deaths", str(int(t.get("deaths", 0)))],
		["clock", "acc_playtime", _hms(float(t.get("playtime", 0)))], ["auto", "acc_offline", _hms(float(t.get("offline", 0)))],
		["people", "acc_heroes", "%d / %d" % [GameState.heroes.size(), DataDB.hero_order.size()]],
		["book", "acc_codex_enemies", "%d / %d" % [GameState.codex["enemies"].size(), DataDB.enemies.size() + DataDB.bosses.size()]],
		["gem", "acc_codex_legendaries", "%d / %d" % [GameState.codex["legendaries"].size(), DataDB.items.get("legendaries", []).size()]]]
	var g := W.grid(2, 3)
	_body.add_child(g)
	var tw := (w - 3.0) / 2.0
	for r in rows:
		var tile := Control.new()
		tile.custom_minimum_size = Vector2(tw, 22)
		var ic: String = r[0]
		var lab := DataDB.t(r[1])
		var val: String = r[2]
		tile.draw.connect(func():
			var ci := tile.get_canvas_item()
			var rr := Rect2(Vector2.ZERO, tile.size)
			UISkin.fill(ci, rr, 3, Color("#2A1F18"), Color("#16100B"))
			UISkin.stroke(ci, rr, 3, UISkin.OUTLINE, 1.0)
			UISkin.circle(ci, Vector2(11, 11), 8.0, Color("#4A3826"), Color("#22180F"))
			tile.draw_texture_rect(UITheme.icon(ic), Rect2(5, 5, 12, 12), false)
			tile.draw_string(UITheme.font_title, Vector2(22, 10), val, HORIZONTAL_ALIGNMENT_LEFT, tw - 24, 9, Color("#FFE7A6"))
			tile.draw_string(UITheme.font_small, Vector2(22, 19), lab, HORIZONTAL_ALIGNMENT_LEFT, tw - 24, 7, Color("#B8A68A")))
		tile.tooltip_text = lab
		tile.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(tile)
	_body.add_child(Fancy.section(DataDB.t("account_bonuses"), w))
	var acc := GameState.account_mods()
	if acc.is_empty():
		_body.add_child(UITheme.para(DataDB.t("account_bonus_none"), w, UITheme.C_DIM, 7))
	for k in acc:
		_body.add_child(W.stat_row(StatNames.label(k), "+" + StatNames.fmt(k, float(acc[k])), UITheme.C_GREEN, UITheme.C_TEXT, int(w)))


func _hms(s: float) -> String:
	var h := int(s / 3600)
	var m := int(fmod(s, 3600) / 60)
	return "%dsa %ddk" % [h, m] if DataDB.lang == "tr" else "%dh %dm" % [h, m]
