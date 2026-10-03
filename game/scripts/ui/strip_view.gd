class_name StripView
extends Control
## The battle strip: parallax background, units, projectiles, VFX, damage numbers and HUD.

signal chest_landed(kind: String)

const W := 360
const H := 72
const BG_CROP := 12          # the background art is 84 px tall: drop the top of the sky so its ground meets GROUND_Y
const LAYERS := [["sky", 0.0], ["far", 0.1], ["mid", 0.4], ["ground", 1.0]]

var bg_root: Node2D
var bg_layers: Dictionary = {}
var fore: Sprite2D
var hd_bg: Sprite2D           # HD illustrated panorama (replaces the pixel layers when present)
const HD_BG_SCALE := 4.0      # panorama textures are 4x the strip's logical height
var units_root: Node2D
var fx_root: Node2D
var num_root: Node2D
var hud: Control
var views: Dictionary = {}       # uid -> UnitView
var _num_pool: Array = []
var _active_nums: Array = []
var _theme := ""
var _zone_label: Label
var _stage_label: Label
var _boss_bar: ProgressBar
var _boss_name: Label
var _boss_time: Label
var _wave_dots: Control
var _banner: Label
var _banner_t := 0.0
var _town_overlay: Control
var _shake := 0.0
var _weather: Array = []
var _weather_kind := ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	size = Vector2(W, H)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	bg_root = Node2D.new()
	add_child(bg_root)
	for l in LAYERS:
		var s := Sprite2D.new()
		s.centered = false
		s.region_enabled = true
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		bg_root.add_child(s)
		bg_layers[l[0]] = s
	hd_bg = Sprite2D.new()
	hd_bg.centered = false
	hd_bg.region_enabled = true
	hd_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	hd_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hd_bg.scale = Vector2.ONE / HD_BG_SCALE
	hd_bg.visible = false
	bg_root.add_child(hd_bg)
	units_root = Node2D.new()
	units_root.y_sort_enabled = false
	add_child(units_root)
	fx_root = Node2D.new()
	fx_root.z_index = 20
	add_child(fx_root)
	fore = Sprite2D.new()
	fore.centered = false
	fore.region_enabled = true
	fore.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fore.z_index = 25
	fore.modulate.a = 0.75
	add_child(fore)
	num_root = Node2D.new()
	num_root.z_index = 30
	add_child(num_root)
	_build_hud()
	EventBus.unit_spawned.connect(_on_unit_spawned)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.damage_dealt.connect(_on_damage)
	EventBus.healed.connect(_on_heal)
	EventBus.projectile_fired.connect(_on_projectile)
	EventBus.vfx_requested.connect(_on_vfx)
	EventBus.item_dropped.connect(_on_item_dropped)
	EventBus.chest_dropped.connect(_on_chest_dropped)
	EventBus.hero_leveled.connect(_on_level)
	EventBus.zone_changed.connect(_on_zone)
	EventBus.stage_changed.connect(func(_s): _update_hud_text())
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_defeated.connect(func(_z):
		_show_banner(DataDB.t("boss_defeated"), Color("#F7C948"))
		AudioManager.play("loot_legendary", 0.0, 0.6)
		AudioManager.play_music(str(BattleSim.zone().get("music", "act1"))))
	EventBus.boss_failed.connect(func(_z): AudioManager.play_music(str(BattleSim.zone().get("music", "act1"))))
	EventBus.party_wiped.connect(func(): _show_banner(DataDB.t("party_wiped"), Color("#FF6A5A")))
	EventBus.phase_changed.connect(_on_phase)
	EventBus.party_changed.connect(_rebuild_units)
	EventBus.language_changed.connect(_update_hud_text)
	EventBus.skill_cast.connect(_on_skill_cast)
	_rng.randomize()


func _build_hud() -> void:
	hud = Control.new()
	hud.size = Vector2(W, H)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.z_index = 40
	add_child(hud)
	var plate := ColorRect.new()
	plate.color = Color(0.08, 0.06, 0.09, 0.55)
	plate.position = Vector2(20, 1)
	plate.size = Vector2(150, 9)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(plate)
	_zone_label = UITheme.label("", UITheme.C_TEXT)
	_zone_label.position = Vector2(23, 0)
	_zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_zone_label.add_theme_constant_override("shadow_offset_x", 1)
	_zone_label.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(_zone_label)
	_stage_label = UITheme.label("", UITheme.C_GOLD)
	_stage_label.position = Vector2(140, 0)
	hud.add_child(_stage_label)
	_wave_dots = Control.new()
	_wave_dots.position = Vector2(23, 10)
	_wave_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_dots.draw.connect(_draw_wave_dots)
	hud.add_child(_wave_dots)
	_boss_bar = UITheme.bar(110, 4, Color("#D63A3A"))
	_boss_bar.position = Vector2(196, 5)
	_boss_bar.visible = false
	hud.add_child(_boss_bar)
	_boss_name = UITheme.label("", Color("#FF9A8A"))
	_boss_name.position = Vector2(196, -2)
	_boss_name.visible = false
	hud.add_child(_boss_name)
	_boss_time = UITheme.label("", UITheme.C_TEXT)
	_boss_time.position = Vector2(310, 0)
	_boss_time.visible = false
	hud.add_child(_boss_time)
	_banner = UITheme.label("", UITheme.C_GOLD, 13, UITheme.font_title)
	_banner.size = Vector2(W, 16)
	_banner.position = Vector2(0, 22)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_outline_color", Color("#140E10"))
	_banner.add_theme_constant_override("outline_size", 2)
	_banner.visible = false
	hud.add_child(_banner)
	_town_overlay = Control.new()
	_town_overlay.visible = false
	_town_overlay.size = Vector2(W, H)
	_town_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_town_overlay)


func _draw_wave_dots() -> void:
	if BattleSim.phase == "boss" or BattleSim.is_boss_stage():
		return
	var n := BattleSim.waves_per_stage()
	for i in n:
		var c := Color("#F7C948") if i < BattleSim.wave else Color("#4A3A30")
		_wave_dots.draw_rect(Rect2(i * 5, 0, 3, 2), c)


func _update_hud_text() -> void:
	if BattleSim.mode == "tower":
		_zone_label.text = DataDB.t("tower_name")
		_stage_label.text = DataDB.t("floor_n", {"n": BattleSim.tower_floor})
		_stage_label.position.x = 26 + UITheme.font_small.get_string_size(_zone_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 4
		return
	var z := BattleSim.zone()
	_zone_label.text = DataDB.tx(z.get("name", {}))
	var act := int(z.get("act", 1))
	var stage_txt := "%d-%d" % [int(z.get("index", 1)), BattleSim.stage]
	if BattleSim.is_boss_stage():
		stage_txt = "BOSS"
	_stage_label.text = stage_txt
	var nm_w := UITheme.font_small.get_string_size(_zone_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_stage_label.position.x = 26 + nm_w + 4
	var plate: ColorRect = hud.get_child(0)
	plate.size.x = nm_w + 36
	if BattleSim.difficulty > 0:
		_stage_label.text += " " + ["", "[K]", "[C]"][BattleSim.difficulty] if DataDB.lang == "tr" else " " + ["", "[NM]", "[H]"][BattleSim.difficulty]
	_wave_dots.queue_redraw()
	if act > 0:
		pass


# ------------------------------------------------------------------ background
func _on_zone(_zid: String) -> void:
	if _zid == "tower":
		_set_theme("void")
		_update_hud_text()
		_show_banner(DataDB.t("tower_name"), Color("#9FDFFF"))
		AudioManager.play_music("boss")
		return
	var z := BattleSim.zone()
	_set_theme(str(z.get("background", "meadow")))
	_update_hud_text()
	_show_banner(DataDB.tx(z.get("name", {})), UITheme.C_TEXT)
	AudioManager.play_music(str(z.get("music", "act1")))


func _set_theme(theme_name: String) -> void:
	if theme_name == _theme:
		return
	_theme = theme_name
	for l in LAYERS:
		var path := "res://assets/backgrounds/%s/%s.png" % [theme_name, l[0]]
		var s: Sprite2D = bg_layers[l[0]]
		s.texture = load(path) if ResourceLoader.exists(path) else null
	var fpath := "res://assets/backgrounds/%s/fore.png" % theme_name
	fore.texture = load(fpath) if ResourceLoader.exists(fpath) else null
	var hpath := "res://assets/hd/bg/%s.jpg" % theme_name
	hd_bg.texture = load(hpath) if ResourceLoader.exists(hpath) else null
	hd_bg.visible = hd_bg.texture != null
	for l in LAYERS:
		bg_layers[l[0]].visible = not hd_bg.visible
	fore.visible = not hd_bg.visible
	_weather_kind = {"snow": "snow", "ice": "snow", "storm": "rain", "forest_fog": "fog", "lava": "ember", "ash": "ember",
		"graveyard": "fog", "dark_forest": "leaf", "forest": "leaf", "void": "ember", "blood": "ember"}.get(theme_name, "")
	_weather.clear()
	queue_redraw()


func _process(delta: float) -> void:
	var sc := BattleSim.scroll
	var tint := TimeService.world_tint()
	for l in LAYERS:
		var s: Sprite2D = bg_layers[l[0]]
		if s.texture:
			s.region_rect = Rect2(floor(sc * float(l[1])), BG_CROP, W, H)
			s.modulate = tint if l[0] != "ground" else tint.lerp(Color.WHITE, 0.35)
	if hd_bg.visible:
		hd_bg.region_rect = Rect2(sc * 0.75 * HD_BG_SCALE, BG_CROP * HD_BG_SCALE, W * HD_BG_SCALE, H * HD_BG_SCALE)
		hd_bg.modulate = tint.lerp(Color.WHITE, 0.25)
	if fore.texture:
		fore.region_rect = Rect2(floor(sc * 1.3), BG_CROP, W, H)
		fore.modulate = Color(tint.r, tint.g, tint.b, 0.75)
	units_root.modulate = tint.lerp(Color.WHITE, 0.6)
	# boss HUD
	if BattleSim.phase == "boss" and BattleSim.boss_unit != null:
		_boss_bar.visible = true
		_boss_name.visible = true
		_boss_time.visible = true
		_boss_bar.max_value = BattleSim.boss_unit.max_hp
		_boss_bar.value = max(0.0, BattleSim.boss_unit.hp)
		_boss_time.text = "%d" % int(ceil(BattleSim.boss_t))
		_boss_time.add_theme_color_override("font_color", UITheme.C_RED if BattleSim.boss_t < 10 else UITheme.C_TEXT)
	else:
		_boss_bar.visible = false
		_boss_name.visible = false
		_boss_time.visible = false
	if _banner_t > 0:
		_banner_t -= delta
		_banner.modulate.a = clamp(_banner_t, 0.0, 1.0)
		if _banner_t <= 0:
			_banner.visible = false
	UnitView.hitstop = max(0.0, UnitView.hitstop - delta)
	if _shake > 0 and Settings.get_v("screen_shake", true):
		_shake = max(0.0, _shake - delta)
		var amp := _shake * 5.0
		position = Vector2(_rng.randf_range(-1, 1) * amp, _rng.randf_range(-1, 1) * amp * 0.5)
	else:
		position = Vector2.ZERO
	_update_numbers(delta)
	_update_weather(delta)
	queue_redraw()


func _draw() -> void:
	# fallback background when no art exists
	if bg_layers["sky"].texture == null and not hd_bg.visible:
		var tint := TimeService.world_tint()
		for i in 8:
			var c := Color("#7FB8E8").lerp(Color("#CFE8F6"), i / 8.0) * tint
			draw_rect(Rect2(0, i * 7, W, 7), c)
		draw_rect(Rect2(0, 44, W, 28), Color("#5A8A3A") * tint)
		draw_rect(Rect2(0, 64, W, 8), Color("#7A5A3A") * tint)
	for p in _weather:
		match _weather_kind:
			"snow":
				draw_rect(Rect2(round(p[0]), round(p[1]), 1, 1), Color(1, 1, 1, 0.85))
			"rain":
				draw_line(Vector2(p[0], p[1]), Vector2(p[0] - 1, p[1] + 3), Color(0.7, 0.8, 1.0, 0.6))
			"ember":
				draw_rect(Rect2(round(p[0]), round(p[1]), 1, 1), Color(1.0, 0.6, 0.2, 0.8))
			"leaf":
				draw_rect(Rect2(round(p[0]), round(p[1]), 2, 1), Color(0.55, 0.75, 0.3, 0.8))
			"fog":
				draw_rect(Rect2(round(p[0]), round(p[1]), 24, 3), Color(1, 1, 1, 0.06))


func _update_weather(delta: float) -> void:
	if _weather_kind == "":
		return
	var maxn := int(30 * float(Settings.get_v("particles", 1.0)))
	while _weather.size() < maxn:
		_weather.append([_rng.randf_range(0, W), _rng.randf_range(-H, H), _rng.randf_range(0.6, 1.4)])
	var scroll_speed := 40.0 if BattleSim.phase == "travel" else 0.0
	for p in _weather:
		match _weather_kind:
			"snow":
				p[1] += 10 * delta * p[2]
				p[0] -= (scroll_speed + sin(p[1] * 0.1) * 6) * delta
			"rain":
				p[1] += 90 * delta * p[2]
				p[0] -= (scroll_speed + 20) * delta
			"ember":
				p[1] -= 8 * delta * p[2]
				p[0] -= (scroll_speed + 3) * delta
			"leaf":
				p[1] += 6 * delta * p[2]
				p[0] -= (scroll_speed + 8 + sin(p[1] * 0.2) * 5) * delta
			"fog":
				p[0] -= (scroll_speed * 1.2 + 4) * delta * p[2]
				p[1] = 40 + fmod(p[2] * 37.0, 30.0)
		if p[1] > H or p[1] < -H or p[0] < -30:
			p[0] = _rng.randf_range(0, W + 30) if p[0] < -30 else p[0]
			p[1] = -2.0 if _weather_kind != "ember" else H
			if p[0] < -30:
				p[0] = W + 10


# ------------------------------------------------------------------ units
func _rebuild_units() -> void:
	for uid in views:
		if is_instance_valid(views[uid]):
			views[uid].queue_free()
	views.clear()
	for u in BattleSim.heroes:
		_on_unit_spawned(u)
	for e in BattleSim.enemies:
		_on_unit_spawned(e)


func _on_unit_spawned(u: Combatant) -> void:
	if views.has(u.uid) and is_instance_valid(views[u.uid]):
		return
	var v := UnitView.new()
	v.setup(u)
	units_root.add_child(v)
	views[u.uid] = v
	if u.etype == "summon":
		_spawn_vfx("summon", Vector2(u.x, BattleSim.GROUND_Y), Color("#8CFF7A"), 8)


func _on_unit_died(u: Combatant) -> void:
	if u.is_hero_side() and u.etype == "hero":
		return
	var v: UnitView = views.get(u.uid)
	if v == null:
		return
	views.erase(u.uid)
	var tw := create_tween()
	tw.tween_interval(1.2 if u.side == Combatant.Side.ENEMY else (0.0 if u.etype == "pet" else 0.3))
	tw.tween_callback(v.queue_free)
	if u.side == Combatant.Side.ENEMY:
		AudioManager.play("death", 0.12, 0.45)
		AudioManager.play("coin", 0.15, 0.35)
		_spawn_vfx("coin", Vector2(u.x, BattleSim.GROUND_Y - 8), Color("#F7C948"), 4)
		if u.etype == "boss" or u.etype == "actboss":
			_shake = 0.5


func _unit_pos(u: Combatant, head := false) -> Vector2:
	var v: UnitView = views.get(u.uid)
	var y := BattleSim.GROUND_Y - (18.0 if not head else 34.0)
	if v:
		y = BattleSim.GROUND_Y + v._head_y * (0.5 if not head else 1.0)
	return Vector2(u.x, y)


# ------------------------------------------------------------------ numbers
func _get_num() -> Label:
	var l: Label
	if _num_pool.size() > 0:
		l = _num_pool.pop_back()
	else:
		l = Label.new()
		l.add_theme_font_override("font", UITheme.font_small)
		l.add_theme_color_override("font_outline_color", Color("#140E10"))
		l.add_theme_constant_override("outline_size", 2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		num_root.add_child(l)
	l.visible = true
	return l


func _spawn_number(text: String, pos: Vector2, color: Color, big := false) -> void:
	var mode := int(Settings.get_v("dmg_numbers", 2))
	if mode == 0 or (mode == 1 and not big):
		return
	if _active_nums.size() > 40:
		var old: Dictionary = _active_nums.pop_front()
		old["l"].visible = false
		_num_pool.append(old["l"])
	var l := _get_num()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", UITheme.font_big if big else UITheme.font_small)
	l.add_theme_font_size_override("font_size", 12 if big else 9)
	var sz := l.get_minimum_size()
	l.pivot_offset = sz / 2.0
	l.position = (pos - Vector2(sz.x / 2.0, sz.y * 0.6)).round()
	_active_nums.append({"l": l, "t": 0.0, "life": 0.95 if big else 0.75, "vx": _rng.randf_range(-10, 10), "y0": l.position.y, "big": big})


func _update_numbers(delta: float) -> void:
	for n in _active_nums.duplicate():
		n["t"] = float(n["t"]) + delta
		var l: Label = n["l"]
		var k: float = float(n["t"]) / float(n["life"])
		if k >= 1.0:
			l.visible = false
			_num_pool.append(l)
			_active_nums.erase(n)
			continue
		# pop up on an arc, overshoot-scale in, then fade
		l.position.y = float(n["y0"]) - 16.0 * sqrt(k) + 10.0 * k * k
		l.position.x += float(n["vx"]) * delta * (1.0 - k)
		l.modulate.a = 1.0 if k < 0.65 else (1.0 - (k - 0.65) / 0.35)
		var pop: float = 1.0 + (0.6 if n["big"] else 0.35) * max(0.0, 1.0 - k * 7.0)
		l.scale = Vector2.ONE * pop


func _on_damage(src, tgt, amount: float, crit: bool, element: String, kind: String) -> void:
	if tgt == null:
		return
	var pos := _unit_pos(tgt)
	if kind == "miss":
		_spawn_number("MISS", pos, Color("#A8A8B8"))
		return
	var col := UITheme.element_color(element)
	if tgt.is_hero_side():
		col = Color("#FF8A7A")
	var txt := F.fmt_num(amount)
	if crit:
		txt += "!"
	if kind == "block":
		_spawn_number("BLOCK", pos + Vector2(0, -6), Color("#8FB4FF"))
	_spawn_number(txt, pos, Color("#FFD84A") if crit and not tgt.is_hero_side() else col, crit)
	if kind != "dot":
		AudioManager.play("crit" if crit else _hit_sound(src, element), 0.08, 0.55 if not crit else 0.75)
		var tv: UnitView = views.get(tgt.uid)
		var hp := tv.center() if tv else pos
		var melee_src: bool = src != null and bool(src.stats.get("melee", true)) and src.projectile == ""
		var sz: float = 7.0 if not crit else 10.0
		if tv:
			sz *= clampf(tv._h / 34.0, 0.8, 1.8)
		if melee_src:
			_spawn_vfx("cut", hp + Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-3, 3)), col, sz * 1.3,
				{"dir": 1.0 if src.is_hero_side() else -1.0})
		_spawn_vfx("impact", hp + Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-4, 4)), col, sz)
		if crit:
			_spawn_vfx("crit", hp, col, sz)
			UnitView.hitstop = 0.07
			_shake = max(_shake, 0.12)
	if crit and src != null and (src.etype == "boss" or src.etype == "actboss"):
		_shake = 0.25


## Weapon-specific impacts: blades cut, axes chop, arrows thunk in, spells burst by element; monsters thud.
const SPELL_SFX := {"fire": "magic_fire", "cold": "magic_ice", "lightning": "magic_shock", "holy": "magic_holy", "chaos": "magic_dark"}


func _hit_sound(src, element: String) -> String:
	if element != "physical" and element != "":
		return SPELL_SFX.get(element, "hit_magic")
	if src == null:
		return "hit_blunt%d" % (_rng.randi() % 2)
	if src.is_hero_side() and src.etype == "hero":
		var cls: String = str(DataDB.hero_def(src.id).get("class", "knight"))
		if src.projectile.begins_with("arrow") or cls == "archer":
			return "arrow_hit"
		if cls in ["mage", "necromancer", "cleric", "bard"]:
			return "hit_magic"
		if cls == "berserker":
			return "chop"
		return "slash%d" % (_rng.randi() % 3)
	if src.projectile.begins_with("arrow"):
		return "arrow_hit"
	return "hit_blunt%d" % (_rng.randi() % 2)


func _on_heal(tgt, amount: float) -> void:
	AudioManager.play("heal", 0.1, 0.4)
	_spawn_number("+" + F.fmt_num(amount), _unit_pos(tgt, true), Color("#6CFF8A"))
	_spawn_vfx("heal", Vector2(tgt.x, BattleSim.GROUND_Y), Color("#8CFF9A"), 6)


func _on_projectile(src, tgt, kind: String, travel: float) -> void:
	AudioManager.play("arrow_fly" if kind.begins_with("arrow") else "magic", 0.12, 0.3 if kind.begins_with("arrow") else 0.35)
	var p := Projectile.new()
	var sv: UnitView = views.get(src.uid)
	var tv: UnitView = views.get(tgt.uid)
	var a := sv.strike_point() if sv else _unit_pos(src) + Vector2(6 if src.is_hero_side() else -6, -4)
	var b := tv.center() if tv else _unit_pos(tgt)
	p.setup(kind, a, b, travel)
	fx_root.add_child(p)


func _spawn_vfx(kind: String, pos: Vector2, color: Color, sz: float, data: Dictionary = {}) -> VfxNode:
	if fx_root.get_child_count() > 60:
		return null
	var v := VfxNode.new()
	v.setup(kind, color, sz, data)
	v.position = pos.round()
	fx_root.add_child(v)
	return v


func _on_vfx(vfx: String, pos: Vector2, data: Dictionary) -> void:
	var tgts: Array = data.get("targets", [])
	var col := Color.WHITE
	match vfx:
		"telegraph":
			_spawn_vfx("telegraph", Vector2(170, BattleSim.GROUND_Y + 1), Color.RED, 110, data)
			return
		"heal":
			return
		"fireball", "fire_ring", "meteor":
			col = Color("#FF7A33")
		"ice", "freeze":
			col = Color("#9FDFFF")
		"lightning", "sound":
			col = Color("#FFE45C")
		"poison", "curse", "drain", "shadow", "eclipse", "smoke":
			col = Color("#B266FF")
		"holy_slash", "holy_burst", "holy_bolt", "banner":
			col = Color("#FFE08A")
		"notes":
			col = Color("#9FF3C0")
		"earth_spike", "vines", "quake":
			col = Color("#C9A06A")
	if vfx == "meteor" or vfx == "star_rain" or vfx == "arcane_storm":
		_spawn_vfx("meteor", pos, col, 10)
		_shake = 0.2
	if vfx == "arrow_rain" or vfx == "arrows" or vfx == "star_rain":
		_spawn_vfx("rain", Vector2(280, BattleSim.GROUND_Y), Color("#E8D9A8"), 70)
	if vfx == "lightning":
		for uid in tgts:
			var v: UnitView = views.get(uid)
			if v:
				_spawn_vfx("lightning", Vector2(v.position.x, BattleSim.GROUND_Y - 4), col, 8)
		return
	if vfx == "notes" or vfx == "sound":
		_spawn_vfx("notes", pos, col, 8)
	if vfx == "smoke":
		_spawn_vfx("smoke", pos, col, 8)
		return
	if vfx == "summon":
		return
	if vfx.begins_with("boss_"):
		_shake = 0.35
		for u in BattleSim.heroes:
			if u.alive:
				_spawn_vfx("burst", Vector2(u.x, BattleSim.GROUND_Y - 14), Color("#FF5A3A"), 10)
		return
	for uid in tgts:
		var v2: UnitView = views.get(uid)
		if v2 and v2.unit and not v2.unit.is_hero_side():
			_spawn_vfx("burst" if vfx != "slash_heavy" and vfx != "slash_multi" else "slash", Vector2(v2.position.x, BattleSim.GROUND_Y - 14), col, 10)
		elif v2:
			_spawn_vfx("shield" if vfx == "shield" else "heal", Vector2(v2.position.x, BattleSim.GROUND_Y), col, 8)


func _on_skill_cast(u, sid: String) -> void:
	if u == null or not u.is_hero_side():
		return
	var sdef := DataDB.skill_def(sid)
	var nm := DataDB.tx(sdef.get("name", {}))
	var big: bool = sdef.get("type", "") == "ult"
	_spawn_number(nm, _unit_pos(u, true) + Vector2(0, -8), Color("#9FDFFF") if not big else Color("#FFD84A"), big)
	if big:
		_shake = 0.3
		_show_banner(nm, Color("#FFD84A"))


func _on_item_dropped(item: Dictionary, pos: Vector2) -> void:
	var r: String = item.get("rarity", "common")
	var rank := ItemUtil.rarity_rank(r)
	if rank >= ItemUtil.rarity_rank("rare"):
		_spawn_vfx("loot_beam", pos, ItemUtil.rarity_color(r), 4)
	if rank >= ItemUtil.rarity_rank("legendary"):
		_show_banner(ItemUtil.display_name(item), ItemUtil.rarity_color(r))
		AudioManager.play("loot_legendary", 0.0, 1.0)
		_shake = 0.2
	elif rank >= ItemUtil.rarity_rank("rare"):
		AudioManager.play("loot_rare", 0.05, 0.8)


func _on_chest_dropped(kind: String, pos: Vector2) -> void:
	var c := ChestDrop.new()
	c.setup(kind, Vector2(pos.x, BattleSim.GROUND_Y - 2), Vector2(9, 68))
	c.collected.connect(func(): chest_landed.emit(kind))
	fx_root.add_child(c)
	_spawn_number(Chests.display_name(kind) + "!", Vector2(pos.x, BattleSim.GROUND_Y - 30), Chests.color(kind), Chests.rank(kind) >= 2)
	if Chests.rank(kind) >= 3:
		_shake = max(_shake, 0.15)


func _on_level(hid: String, lv: int) -> void:
	for u in BattleSim.heroes:
		if u.id == hid and u.etype == "hero":
			_spawn_vfx("levelup", Vector2(u.x, BattleSim.GROUND_Y), Color("#FFE08A"), 8)
			_spawn_number("LEVEL UP! %d" % lv, _unit_pos(u, true) + Vector2(0, -10), Color("#FFE08A"), true)
	AudioManager.play("levelup", 0.0, 0.9)


func _on_boss_spawned(u) -> void:
	_boss_name.text = u.name
	_show_banner(DataDB.t("boss_appears", {"name": u.name}), Color("#FF6A5A"))
	AudioManager.play("boss_warning", 0.0, 1.0)
	AudioManager.play_music("boss")


func _on_phase(p: String) -> void:
	_update_hud_text()
	if p == "town":
		_set_theme("town")
		_show_banner(DataDB.t("town_name"), UITheme.C_TEXT)
		AudioManager.play_music("town")
	elif _theme == "town":
		_set_theme(str(BattleSim.zone().get("background", "meadow")))
		AudioManager.play_music(str(BattleSim.zone().get("music", "act1")))
	if p == "travel" and BattleSim.is_boss_stage():
		_show_banner(DataDB.t("boss_incoming"), Color("#FF9A6A"))


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner_t = 2.2
