class_name Tutorial
extends Node
## First-session guidance + early story joins (Lyra, Pip) and hero barks.

var main: Control
var bubble: Control
var bubble_label: Label
var bubble_t := 0.0
var _speaker := "kael"
var _tail_x := 0.0
const PAD := 4.0
const PORTRAIT := 18.0
const TEXT_W := 200.0
var shown: Dictionary = {}
var _bark_cd := 0.0


static func start_if_needed(m: Control) -> void:
	var t := Tutorial.new()
	t.main = m
	t.name = "Tutorial"
	m.add_child(t)


func _ready() -> void:
	shown = GameState.flags.get("tut", {})
	bubble = Control.new()
	bubble.visible = false
	bubble.z_index = 60
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.draw.connect(_draw_bubble)
	bubble_label = UITheme.label("", Color("#F3E6CC"), 8, UITheme.font_body)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.custom_minimum_size = Vector2(TEXT_W, 0)
	bubble_label.position = Vector2(PAD * 2 + PORTRAIT, PAD)
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
	EventBus.chest_dropped.connect(func(_k, _p): _tip("chest", "tut_chest"))
	EventBus.boss_defeated.connect(func(_z): _party_bark("boss_down", 0.7))
	var it := Timer.new()
	it.wait_time = 170.0
	it.autostart = true
	it.timeout.connect(func():
		it.wait_time = randf_range(140.0, 260.0)
		var hr := int(Time.get_datetime_dict_from_system()["hour"])
		_party_bark("night" if hr < 5 else "idle", 0.8))
	add_child(it)
	var gt := Timer.new()
	gt.wait_time = 15.0
	gt.autostart = true
	gt.timeout.connect(_check_lyra_gift)
	add_child(gt)


func _process(delta: float) -> void:
	_bark_cd -= delta
	if bubble_t > 0:
		bubble_t -= delta
		if bubble_t < 0.25:
			bubble.modulate.a = maxf(0.0, bubble_t / 0.25)
		if bubble_t <= 0:
			bubble.visible = false


func _hint(key: String, text_key: String, args: Dictionary = {}) -> void:
	if Settings.get_v("tutorial_done", false) or shown.has(key):
		return
	shown[key] = true
	GameState.flags["tut"] = shown
	_show_bubble(DataDB.t(text_key, args), "kael", 7.0)


## Feature tips that outlive the tutorial: each shows once, the first time the feature matters.
func _tip(key: String, text_key: String) -> void:
	if shown.has(key) or bubble_t > 0.0:
		return
	shown[key] = true
	GameState.flags["tut"] = shown
	_show_bubble(DataDB.t(text_key), "kael", 7.0)


func _show_bubble(text: String, hero_id: String, dur: float) -> void:
	_speaker = hero_id
	bubble_label.text = text
	bubble_label.size = Vector2(TEXT_W, 0)
	bubble_label.reset_size()
	var h := maxf(bubble_label.get_combined_minimum_size().y + PAD * 2, PORTRAIT + PAD * 2)
	bubble.size = Vector2(TEXT_W + PORTRAIT + PAD * 3, h)
	var x := 150.0
	for u in BattleSim.heroes:
		if u.id == hero_id:
			x = u.x
	var w := bubble.size.x
	bubble.position = Vector2(clamp(x - w / 2.0, 20.0, 395.0 - w), 13)
	_tail_x = clampf(x - bubble.position.x, 10.0, w - 10.0)
	bubble.pivot_offset = Vector2(_tail_x, h)
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble.scale = Vector2(0.6, 0.6)
	var tw := bubble.create_tween()
	tw.tween_property(bubble, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bubble.queue_redraw()
	bubble_t = dur


## Speech bubble: dark leather card with a bronze rim, the speaker's portrait chip and a tail pointing down at them.
func _draw_bubble() -> void:
	var ci := bubble.get_canvas_item()
	var r := Rect2(Vector2.ZERO, bubble.size)
	UISkin.fill(ci, Rect2(r.position + Vector2(0, 2), r.size), 4, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35))
	var tail := PackedVector2Array([Vector2(_tail_x - 5, r.end.y - 1), Vector2(_tail_x + 5, r.end.y - 1), Vector2(_tail_x, r.end.y + 6)])
	bubble.draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(-1.2, 0), tail[1] + Vector2(1.2, 0), tail[2] + Vector2(0, 1.6)]), UISkin.OUTLINE)
	UISkin.fill(ci, r, 4, Color("#3A2C22"), Color("#1E1610"))
	bubble.draw_colored_polygon(tail, Color("#1E1610"))
	UISkin.stroke(ci, r, 4, UISkin.OUTLINE, 1.0)
	UISkin.stroke(ci, r.grow(-1.2), 3, Color(UISkin.BRONZE, 0.7), 0.8)
	var pr := Rect2(PAD, PAD, PORTRAIT, PORTRAIT)
	UISkin.fill(ci, pr, 3, Color("#4A3826"), Color("#22180F"))
	var ic := SpriteLib.hero_icon(_speaker)
	if ic:
		bubble.draw_texture_rect(ic, pr.grow(-1.0), false)
	UISkin.stroke(ci, pr, 3, UISkin.OUTLINE, 1.0)
	UISkin.stroke(ci, pr.grow(-0.8), 2, Color(UISkin.BRONZE_HI, 0.6), 0.6)


func _say_bark(hero_id: String, text: String) -> void:
	if int(Settings.get_v("barks", 1)) == 0 or _bark_cd > 0 or bubble_t > 0:
		return
	_bark_cd = 25.0 if int(Settings.get_v("barks", 1)) == 1 else 10.0
	_show_bubble("%s: %s" % [DataDB.hero_def(hero_id).get("name", hero_id), text], hero_id, 3.5)


func _on_wave(w: int) -> void:
	if w == 1:
		_hint("intro", "tut_intro")


func _on_item(item: Dictionary, _p: Vector2) -> void:
	_hint("item", "tut_item")
	if str(item.get("rarity", "")) in ["legendary", "mythic"]:
		_party_bark("legendary", 0.9)


## A random hero of the party says something about the moment.
func _party_bark(event: String, chance: float) -> void:
	var ph := GameState.party_heroes()
	if ph.size() > 0:
		Barks.trigger(ph[randi() % ph.size()].id, event, chance)


func _on_level(hid: String, lv: int) -> void:
	if lv == 2:
		_hint("stats", "tut_stats")
	elif lv == 3:
		_hint("skills_pts", "tut_skills")
	elif lv == 8:
		_tip("smith", "tut_smith")
	if lv >= 4 and Runes.points_spent() == 0 and Runes.any_affordable():
		_tip("runes", "tut_runes")
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
