class_name Tutorial
extends Node
## First-session guidance + early story joins (Lyra, Pip) and hero barks.

var main: Control
var bubble: PanelContainer
var bubble_label: Label
var bubble_t := 0.0
var shown: Dictionary = {}
var _bark_cd := 0.0


static func start_if_needed(m: Control) -> void:
	var t := Tutorial.new()
	t.main = m
	t.name = "Tutorial"
	m.add_child(t)


func _ready() -> void:
	shown = GameState.flags.get("tut", {})
	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UITheme.box("tooltip", 3, 3))
	bubble.visible = false
	bubble.z_index = 60
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_label = UITheme.label("", UITheme.C_TEXT)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.custom_minimum_size = Vector2(150, 0)
	bubble.add_child(bubble_label)
	main.add_child(bubble)
	EventBus.wave_spawned.connect(_on_wave)
	EventBus.item_dropped.connect(_on_item)
	EventBus.hero_leveled.connect(_on_level)
	EventBus.stage_changed.connect(_on_stage)
	EventBus.boss_spawned.connect(_on_boss)
	EventBus.zone_unlocked.connect(_on_zone_unlocked)
	EventBus.hero_unlocked.connect(_on_hero_unlocked)
	EventBus.unit_died.connect(_on_died)
	EventBus.bark.connect(_say_bark)
	var gt := Timer.new()
	gt.wait_time = 15.0
	gt.autostart = true
	gt.timeout.connect(_check_lyra_gift)
	add_child(gt)


func _process(delta: float) -> void:
	_bark_cd -= delta
	if bubble_t > 0:
		bubble_t -= delta
		if bubble_t <= 0:
			bubble.visible = false


func _hint(key: String, text_key: String, args: Dictionary = {}) -> void:
	if Settings.get_v("tutorial_done", false) or shown.has(key):
		return
	shown[key] = true
	GameState.flags["tut"] = shown
	_show_bubble(DataDB.t(text_key, args), "kael", 7.0)


func _show_bubble(text: String, hero_id: String, dur: float) -> void:
	bubble_label.text = text
	bubble.visible = true
	bubble.reset_size()
	var x := 150.0
	for u in BattleSim.heroes:
		if u.id == hero_id:
			x = u.x
	var w := bubble.get_combined_minimum_size().x
	bubble.position = Vector2(clamp(x - w / 2.0, 20.0, 395.0 - w), 12)
	bubble_t = dur


func _say_bark(hero_id: String, text: String) -> void:
	if int(Settings.get_v("barks", 1)) == 0 or _bark_cd > 0 or bubble_t > 0:
		return
	_bark_cd = 25.0 if int(Settings.get_v("barks", 1)) == 1 else 10.0
	_show_bubble("%s: %s" % [DataDB.hero_def(hero_id).get("name", hero_id), text], hero_id, 3.5)


func _on_wave(w: int) -> void:
	if w == 1:
		_hint("intro", "tut_intro")


func _on_item(_item: Dictionary, _p: Vector2) -> void:
	_hint("item", "tut_item")


func _on_level(hid: String, lv: int) -> void:
	if lv == 2:
		_hint("stats", "tut_stats")
	elif lv == 3:
		_hint("skills_pts", "tut_skills")
	Barks.trigger(hid, "level_up")


## First companion as a gift around the eighth minute (or on reaching stage 5), so the first session is
## never a long solo grind. The rest of the tavern keeps its prices.
func _check_lyra_gift() -> void:
	if GameState.heroes.has("lyra") or GameState.flags.get("lyra_gift", false):
		return
	var far := int(GameState.progress.get("zone", 0)) > 0 or BattleSim.stage >= 5
	if far or float(GameState.totals.get("playtime", 0.0)) >= 480.0:
		GameState.flags["lyra_gift"] = true
		GameState.unlock_hero("lyra")
		GameState.add_to_party("lyra")
		AudioManager.play("recruit")
		Toast.show_reward(SpriteLib.hero_icon("lyra"), DataDB.t("gift_lyra_title"), DataDB.t("gift_lyra_sub"))


func _on_stage(s: int) -> void:
	_check_lyra_gift()
	var z := int(GameState.progress.get("zone", 0))
	# point at the tavern once the first recruit is affordable
	if GameState.heroes.size() == 2 and not GameState.heroes.has("pip") and GameState.gold >= int(Tavern.cost("pip")["gold"]):
		_hint("tavern_buy", "tut_tavern_buy")


func _on_boss(_u) -> void:
	_hint("boss", "tut_boss")
	var ph := GameState.party_heroes()
	if ph.size() > 0:
		Barks.trigger(ph[randi() % ph.size()].id, "boss")


func _on_zone_unlocked(_zid: String) -> void:
	if not shown.has("zone2"):
		_hint("zone2", "tut_world")
	elif not shown.has("done"):
		_hint("done", "tut_done")
		Settings.set_v("tutorial_done", true)


func _on_hero_unlocked(hid: String) -> void:
	Barks.trigger(hid, "join")


func _on_died(u) -> void:
	if u.is_hero_side() and u.etype == "hero":
		for o in BattleSim.heroes:
			if o.alive and o.etype == "hero" and o.id != u.id:
				Barks.trigger(o.id, "ally_down")
				break
