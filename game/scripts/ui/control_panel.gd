class_name ControlPanel
extends Control
## Right-hand side control block of the strip (menu buttons, gold, quick icons).

const W := 80
const H := 72

var _gold: Label
var _btns: Dictionary = {}
var _dots: Dictionary = {}
var _xp_bar: ProgressBar
var _lvl: Label


func _ready() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := UITheme.nine("strip_panel", 4)
	bg.size = size
	add_child(bg)
	# top icon row
	var icons := [["power", _on_power, "tip_quit"], ["minus", func(): WindowManager.minimize(), "tip_minimize"],
		["gear", func(): WindowManager.toggle_panel("settings"), "tip_settings"],
		["quest", func(): WindowManager.toggle_panel("quests"), "tip_quests"], ["chart", func(): WindowManager.toggle_panel("dps"), "tip_dps"],
		["note", _on_mute, "tip_mute"]]
	var x := 5
	for ic in icons:
		var b := UITheme.icon_button(ic[0], ic[1], DataDB.t(ic[2]))
		b.position = Vector2(x, 3)
		add_child(b)
		_btns[ic[0]] = b
		x += 12
	# main menu: two rows of bronze medallions (tooltips + hotkeys name them)
	var defs := [["hero", "shield", "btn_hero"], ["stats", "cross", "panel_stats"], ["runes", "rune", "tip_runes"],
		["world", "map", "btn_world"], ["growth", "star", "btn_growth"], ["tavern", "town", "btn_tavern"]]
	for i in defs.size():
		var d: Array = defs[i]
		var pid: String = d[0]
		var m := UITheme.medallion(d[1], func(): WindowManager.toggle_panel(pid), DataDB.t(d[2]), 9.5)
		m.position = Vector2(5 + (i % 3) * 24.0, 12 + (i / 3) * 20)
		m.set_meta("panel", pid)
		add_child(m)
		_btns[pid] = m
		var dot := UITheme.badge(8.0)
		dot.position = m.position + Vector2(13, -1)
		dot.visible = false
		add_child(dot)
		_dots[pid] = dot
	# quest "!" badge and the mute slash over the top icons
	var qb := UITheme.badge(7.0)
	qb.position = _btns["quest"].position + Vector2(5, -2)
	qb.visible = false
	add_child(qb)
	_dots["quest"] = qb
	var slash := Control.new()
	slash.position = _btns["note"].position
	slash.size = Vector2(8, 8)
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slash.draw.connect(func():
		if Settings.get_v("mute", false):
			slash.draw_line(Vector2(2.5, 7.5), Vector2(7.5, 2.5), Color(0, 0, 0, 0.75), 1.6, true)
			slash.draw_line(Vector2(2.5, 7.5), Vector2(7.5, 2.5), Color("#FF5A4A"), 0.8, true))
	add_child(slash)
	_slash = slash
	# gold
	var coin: TextureRect = preload("res://scripts/ui/widgets.gd").icon_rect(UITheme.icon("gold"))
	coin.position = Vector2(5, 57)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	_gold = UITheme.label("0", UITheme.C_GOLD)
	_gold.position = Vector2(14, 54)
	add_child(_gold)
	_lvl = UITheme.label("", UITheme.C_DIM)
	_lvl.position = Vector2(50, 54)
	add_child(_lvl)
	_xp_bar = UITheme.bar(60, 3, Color("#F2B33D"))
	_xp_bar.position = Vector2(5, 66)
	add_child(_xp_bar)
	var menu := UITheme.icon_button("menu", func(): WindowManager.toggle_panel("codex"), DataDB.t("tip_codex"))
	menu.position = Vector2(68, 62)
	add_child(menu)
	EventBus.gold_changed.connect(func(_g): _refresh())
	EventBus.hero_leveled.connect(func(_h, _l): _refresh())
	EventBus.inventory_changed.connect(_refresh)
	EventBus.language_changed.connect(_relabel)
	_refresh()


func _relabel() -> void:
	for d in [["hero", "btn_hero"], ["stats", "panel_stats"], ["runes", "tip_runes"], ["world", "btn_world"], ["growth", "btn_growth"], ["tavern", "btn_tavern"]]:
		_btns[d[0]].tooltip_text = DataDB.t(d[1])
	_btns["tavern"].text = DataDB.t("btn_tavern")


var _tick := 0
var _slash: Control


func _process(_d: float) -> void:
	_tick += 1
	if _tick % 30 == 0:
		_refresh()
	for pid in ["hero", "stats", "runes", "world", "growth", "tavern"]:
		var m: BaseButton = _btns[pid]
		var on := WindowManager.is_open(pid)
		if m.get_meta("active", false) != on:
			m.set_meta("active", on)
			m.queue_redraw()
	# xp bar of the highest level hero in party (cheap)
	var ph := GameState.party_heroes()
	if ph.size() > 0:
		var h: HeroState = ph[0]
		_xp_bar.max_value = F.xp_required(h.level)
		_xp_bar.value = h.xp


func _refresh() -> void:
	_gold.text = F.fmt_num(GameState.gold)
	_lvl.text = "Lv%d" % GameState.max_hero_level()
	var sp := false
	var kp := false
	for h in GameState.heroes.values():
		sp = sp or h.stat_points > 0
		kp = kp or h.skill_points > 0
	_dots["stats"].visible = sp or kp
	_dots["runes"].visible = Runes.points_spent() < 3 and Runes.any_affordable() and not WindowManager.is_open("runes")
	_dots["hero"].visible = GameState.bag.size() >= GameState.bag_slots - 4
	_dots["quest"].visible = Quests.claimable() > 0


func _on_power() -> void:
	WindowManager.ask_quit()


func _on_mute() -> void:
	Settings.set_v("mute", not Settings.get_v("mute", false))
	_btns["note"].modulate = Color(0.55, 0.55, 0.6) if Settings.get_v("mute", false) else Color(0.95, 0.9, 0.85)
	_slash.queue_redraw()
