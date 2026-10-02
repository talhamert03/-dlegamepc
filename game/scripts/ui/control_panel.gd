class_name ControlPanel
extends Control
## Right-hand side control block of the strip (menu buttons, gold, quick icons).

const W := 80
const H := 84

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
	var icons := [["power", _on_power, "tip_quit"], ["gear", func(): WindowManager.toggle_panel("settings"), "tip_settings"],
		["quest", func(): WindowManager.toggle_panel("quests"), "tip_quests"], ["chart", func(): WindowManager.toggle_panel("dps"), "tip_dps"],
		["note", _on_mute, "tip_mute"]]
	var x := 5
	for ic in icons:
		var b := UITheme.icon_button(ic[0], ic[1], DataDB.t(ic[2]))
		b.position = Vector2(x, 4)
		add_child(b)
		_btns[ic[0]] = b
		x += 14
	# main 2x2 buttons
	var defs := [["hero", "btn_hero", Vector2(4, 15)], ["bag", "btn_bag", Vector2(42, 15)],
		["growth", "btn_growth", Vector2(4, 30)], ["world", "btn_world", Vector2(42, 30)]]
	for d in defs:
		var gid: String = d[0]
		var b := UITheme.button(DataDB.t(d[1]), "brown", func(): WindowManager.toggle_group(gid), Vector2(36, 13))
		b.add_theme_font_size_override("font_size", 7)
		b.clip_text = true
		add_child(b)
		b.position = d[2]
		b.size = Vector2(36, 13)
		_btns[gid] = b
		var dot := ColorRect.new()
		dot.color = Color("#FF5A4A")
		dot.size = Vector2(3, 3)
		dot.position = d[2] + Vector2(33, 0)
		dot.visible = false
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_dots[gid] = dot
	# party / tavern quick buttons
	var pb := UITheme.button(DataDB.t("btn_party"), "blue", func(): WindowManager.toggle_panel("party"), Vector2(36, 12))
	pb.add_theme_font_size_override("font_size", 7)
	add_child(pb)
	pb.position = Vector2(4, 45)
	pb.size = Vector2(36, 12)
	_btns["party"] = pb
	var tb := UITheme.button(DataDB.t("btn_tavern"), "gold", func(): WindowManager.toggle_panel("tavern"), Vector2(36, 12))
	tb.add_theme_font_size_override("font_size", 7)
	add_child(tb)
	tb.position = Vector2(42, 45)
	tb.size = Vector2(36, 12)
	_btns["tavern"] = tb
	# gold
	var coin: TextureRect = preload("res://scripts/ui/widgets.gd").icon_rect(UITheme.icon("gold"))
	coin.position = Vector2(5, 61)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	_gold = UITheme.label("0", UITheme.C_GOLD)
	_gold.position = Vector2(14, 59)
	add_child(_gold)
	_lvl = UITheme.label("", UITheme.C_DIM)
	_lvl.position = Vector2(50, 59)
	add_child(_lvl)
	_xp_bar = UITheme.bar(70, 3, Color("#F2B33D"))
	_xp_bar.position = Vector2(5, 71)
	add_child(_xp_bar)
	var menu := UITheme.icon_button("menu", func(): WindowManager.toggle_panel("codex"), DataDB.t("tip_codex"))
	menu.position = Vector2(68, 76)
	add_child(menu)
	EventBus.gold_changed.connect(func(_g): _refresh())
	EventBus.hero_leveled.connect(func(_h, _l): _refresh())
	EventBus.inventory_changed.connect(_refresh)
	EventBus.language_changed.connect(_relabel)
	_refresh()


func _relabel() -> void:
	for gid in ["hero", "bag", "growth", "world"]:
		_btns[gid].text = DataDB.t("btn_" + gid)
	_btns["party"].text = DataDB.t("btn_party")
	_btns["tavern"].text = DataDB.t("btn_tavern")


func _process(_d: float) -> void:
	# xp bar of the highest level hero in party (cheap)
	var ph := GameState.party_heroes()
	if ph.size() > 0:
		var h: HeroState = ph[0]
		_xp_bar.max_value = F.xp_required(h.level)
		_xp_bar.value = h.xp


func _refresh() -> void:
	_gold.text = F.fmt_num(GameState.gold)
	_lvl.text = "Lv%d" % GameState.max_hero_level()
	var pts := false
	for h in GameState.heroes.values():
		if h.stat_points > 0 or h.skill_points > 0:
			pts = true
	_dots["hero"].visible = pts
	_dots["bag"].visible = GameState.bag.size() >= GameState.bag_slots - 4


func _on_power() -> void:
	WindowManager.quit_game()


func _on_mute() -> void:
	Settings.set_v("mute", not Settings.get_v("mute", false))
	_btns["note"].modulate = Color(0.5, 0.5, 0.5) if Settings.get_v("mute", false) else Color(0.95, 0.9, 0.85)
