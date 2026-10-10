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
const HD_BG_SCALE := 5.0      # panorama textures are 5x the strip's logical height (crisp at the 5x UI scale)
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


var _weather_node: Node2D


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
	_weather_node = Node2D.new()
	_weather_node.draw.connect(_draw_weather)
	add_child(_weather_node)
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
		var bu = BattleSim.boss_unit
		var bx: float = bu.x if bu != null else W * 0.7
		_spawn_vfx("burst", Vector2(bx, BattleSim.GROUND_Y - 14), Color("#FFD36A"), 22)
		_spawn_vfx("levelup", Vector2(bx, BattleSim.GROUND_Y), Color("#FFE08A"), 12)
		_shake = maxf(_shake, 0.3)
		slowmo(0.55, 0.3)
		AudioManager.play("loot_legendary", 0.0, 0.6)
		AudioManager.play_music(str(BattleSim.zone().get("music", "act1"))))
	EventBus.boss_failed.connect(func(_z): AudioManager.play_music(str(BattleSim.zone().get("music", "act1"))))
	EventBus.party_wiped.connect(func(): _show_banner(DataDB.t("party_wiped"), Color("#FF6A5A"), true))
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
	plate.visible = false
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
	# the drawn HUD replaces the plain labels above (kept for their text)
	_zone_label.visible = false
	_stage_label.visible = false
	_wave_dots.visible = false
	_plaque = Control.new()
	_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plaque.size = Vector2(W, 20)
	_plaque.draw.connect(_draw_plaque)
	hud.add_child(_plaque)
	_boss_hud = Control.new()
	_boss_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hud.size = Vector2(W, 22)
	_boss_hud.visible = false
	_boss_hud.draw.connect(_draw_boss_hud)
	hud.add_child(_boss_hud)
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
	var sx := 150.0
	for d in [["tavern", "btn_tavern_town", "town"], ["shop", "btn_shop", "gem"]]:
		var sign := _town_sign(str(d[0]), DataDB.t(str(d[1])), str(d[2]))
		sign.position = Vector2(sx, 3)
		_town_overlay.add_child(sign)
		sx += sign.size.x + 6.0


var _plaque: Control
var _boss_hud: Control
var _goal := ""
var _goal_t := 0
var _boss_trail := 1.0


## Carved zone plaque in the top left: a small difficulty shield, the zone name, a gold stage tag and the
## wave pips as little diamonds hanging under it.
func _draw_plaque() -> void:
	var ci := _plaque.get_canvas_item()
	var f := UITheme.font_title
	var fb := UITheme.font_body
	var name := _zone_label.text
	var stage := _stage_label.text
	var boss := BattleSim.mode != "tower" and BattleSim.is_boss_stage()
	var nw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var sw := (fb.get_string_size(stage, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 8.0) if stage != "" else -6.0
	var x0 := 20.0
	var r := Rect2(x0, 1, nw + sw + 24.0, 11)
	_plate(ci, r)
	# difficulty shield
	var dc: Color = [Color("#E8C27A"), Color("#C98BFF"), Color("#FF6A4A")][clampi(BattleSim.difficulty, 0, 2)]
	var s := Vector2(x0 + 6.5, 6.5)
	var sh := PackedVector2Array([s + Vector2(-3.4, -3.8), s + Vector2(3.4, -3.8), s + Vector2(3.4, 0.4), s + Vector2(0, 4.2), s + Vector2(-3.4, 0.4)])
	UISkin.poly(ci, sh, dc.lightened(0.2), dc.darkened(0.45))
	var shc := sh.duplicate()
	shc.append(sh[0])
	_plaque.draw_polyline(shc, UISkin.OUTLINE, 0.8, true)
	var tp := Vector2(x0 + 13, 9.6)
	_plaque.draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color(0, 0, 0, 0.8))
	_plaque.draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFE7B0"))
	if stage == "":
		return
	# stage tag
	var tag := Rect2(x0 + 16 + nw + 2, 2.5, sw, 8)
	# small enamel tag: too short for the button bevel, so a flat gradient with a lit top edge
	var tcol := Color("#C0392B") if boss else Color("#E0AA4E")
	UISkin.fill(ci, tag, 2, tcol.lightened(0.25), tcol.darkened(0.3))
	UISkin.line(ci, tag.position + Vector2(2, 0.8), Vector2(tag.end.x - 2, tag.position.y + 0.8), Color(1, 1, 1, 0.45), 0.6)
	UISkin.stroke(ci, tag, 2, UISkin.OUTLINE, 0.8)
	_plaque.draw_string(fb, tag.position + Vector2(4, 6.6), stage, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#FFF4DA") if boss else Color("#2A1606"))
	# the next goal on the right during the first hours
	if BattleSim.phase != "boss" and BattleSim.phase != "town":
		if Time.get_ticks_msec() - _goal_t > 1000:
			_goal_t = Time.get_ticks_msec()
			_goal = Goals.current()
		if _goal != "":
			var gfs := 7 if fb.get_string_size(_goal, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= 170.0 else 6
			var gw := minf(fb.get_string_size(_goal, HORIZONTAL_ALIGNMENT_LEFT, -1, gfs).x, 170.0)
			var gr := Rect2(W - gw - 22, 1.5, gw + 18, 10)
			_plate(ci, gr, 0.78)
			var fl := UITheme.icon("flag")
			if fl:
				_plaque.draw_texture_rect(fl, Rect2(gr.position + Vector2(3, 1.5), Vector2(7, 7)), false, Color("#FFD36A"))
			_plaque.draw_string(fb, gr.position + Vector2(13, 7.6), _goal, HORIZONTAL_ALIGNMENT_LEFT, 170.0, gfs, Color("#FFE7B0"))
	# wave pips
	if BattleSim.mode != "tower" and not boss and BattleSim.phase != "boss":
		var n := BattleSim.waves_per_stage()
		for i in n:
			var c := Vector2(x0 + 8 + i * 6.0, 15.0)
			var done: bool = i < BattleSim.wave
			UISkin.diamond(ci, c, 2.2, Color("#FFE08A") if done else Color("#4A3A30"), Color("#B07420") if done else Color("#241A14"))


## HUD plate (zone name, goal): smoked glass over the battlefield in a bronze bezel, a lit top lip and a
## small gilded lozenge at each end.
func _plate(ci: RID, r: Rect2, alpha := 0.92) -> void:
	UISkin.fill(ci, Rect2(r.position + Vector2(0, 1), r.size), 2, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35))
	UISkin.fill(ci, r, 2, Color(0.24, 0.15, 0.09, alpha), Color(0.08, 0.05, 0.03, alpha))
	UISkin.fill(ci, Rect2(r.position + Vector2(1.5, 1.0), Vector2(r.size.x - 3.0, r.size.y * 0.42)), 1.5, Color(1, 0.9, 0.7, 0.10), Color(1, 0.9, 0.7, 0.0))
	UISkin.stroke(ci, r, 2, UISkin.OUTLINE, 1.0)
	UISkin.stroke(ci, r.grow(-0.9), 1.5, Color(UISkin.BRONZE_HI, 0.65), 0.6)
	for x in [r.position.x, r.end.x]:
		UISkin.diamond(ci, Vector2(x, r.get_center().y), 1.7)


## Boss bar across the top: the boss's name on a ribbon, a framed health bar with a draining trail and a
## timer medallion that turns red in the last ten seconds.
func _draw_boss_hud() -> void:
	var b := BattleSim.boss_unit
	if b == null:
		return
	var ci := _boss_hud.get_canvas_item()
	var frac := clampf(b.hp / maxf(1.0, b.max_hp), 0.0, 1.0)
	if _boss_trail < frac:
		_boss_trail = frac
	else:
		_boss_trail = move_toward(_boss_trail, frac, get_process_delta_time() * 0.35)
	var bar := Rect2(196, 9, 118, 5)
	var case := bar.grow(1.5)
	# name ribbon (the title ribbon, small), drawn first so its folded tails tuck in behind the gauge
	var f := UITheme.font_title
	var nm := str(b.name)
	var nw := minf(f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, 100.0)
	var rr := Rect2(bar.get_center().x - nw / 2.0 - 7.0, 0.0, nw + 14.0, 8.5)
	UISkin.ribbon(ci, rr)
	# an iron-and-gold gauge: drop shadow, recessed channel, glossy blood fill with a pale "damage just
	# taken" trail, quarter notches, gilded bezel with spiked end caps
	UISkin.fill(ci, Rect2(case.position + Vector2(0, 1.2), case.size), 2, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45))
	UISkin.fill(ci, case, 2, Color(0.10, 0.05, 0.04, 0.96), Color(0.03, 0.01, 0.01, 0.96))
	UISkin.groove(ci, bar, 1.5)
	if _boss_trail > frac:
		UISkin.fill(ci, Rect2(bar.position.x + bar.size.x * frac, bar.position.y, bar.size.x * (_boss_trail - frac), bar.size.y), 1, Color("#FFE7C0"), Color("#E0A070"))
	if frac > 0.0:
		var fr := Rect2(bar.position, Vector2(maxf(1.5, bar.size.x * frac), bar.size.y))
		UISkin.fill(ci, fr, 1.5, Color("#FF6A52"), Color("#7A0E12"))
		UISkin.fill(ci, Rect2(fr.position + Vector2(0.3, 0.2), Vector2(fr.size.x - 0.6, fr.size.y * 0.42)), 1, Color(1, 0.85, 0.8, 0.5), Color(1, 0.85, 0.8, 0.08))
		UISkin.line(ci, Vector2(fr.end.x - 0.3, fr.position.y + 0.4), Vector2(fr.end.x - 0.3, fr.end.y - 0.4), Color(1, 0.95, 0.85, 0.75), 0.6)
	for k in range(1, 4):
		var x := bar.position.x + bar.size.x * k / 4.0
		_boss_hud.draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(0, 0, 0, 0.5), 0.6)
	UISkin.stroke(ci, case, 2, UISkin.OUTLINE, 1.0)
	UISkin.stroke(ci, case.grow(-0.7), 1.5, Color(UISkin.BRONZE_HI, 0.8), 0.6)
	for sd in [-1.0, 1.0]:
		var ex: float = case.position.x if sd < 0 else case.end.x
		var cy := case.get_center().y
		var cap := PackedVector2Array([Vector2(ex, cy - 4.0), Vector2(ex + sd * 4.5, cy), Vector2(ex, cy + 4.0), Vector2(ex - sd * 1.2, cy)])
		var capc := cap.duplicate()
		capc.append(cap[0])
		UISkin.poly(ci, cap, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
		_boss_hud.draw_polyline(capc, UISkin.OUTLINE, 0.7, true)
	_boss_hud.draw_string_outline(f, Vector2(rr.position.x + 7.0, 6.9), nm, HORIZONTAL_ALIGNMENT_LEFT, 100.0, 7, 2, Color("#3A0A0C"))
	_boss_hud.draw_string(f, Vector2(rr.position.x + 7.0, 6.9), nm, HORIZONTAL_ALIGNMENT_LEFT, 100.0, 7, Color("#FFF0D2"))
	var sk := UITheme.icon("skull")
	if sk:
		var sc := Vector2(case.position.x - 9.5, case.get_center().y)
		UISkin.circle(ci, sc, 4.6, UISkin.OUTLINE, UISkin.OUTLINE)
		UISkin.circle(ci, sc, 4.0, Color("#C8382E"), Color("#5A0A0A"))
		_boss_hud.draw_texture_rect(sk, Rect2(sc - Vector2(2.8, 2.8), Vector2(5.6, 5.6)), false, Color(1, 0.95, 0.9))
	# timer medallion
	var tc := Vector2(case.end.x + 9, case.get_center().y)
	var low := BattleSim.boss_t < 10.0
	UISkin.circle(ci, tc, 6.4, UISkin.OUTLINE, UISkin.OUTLINE)
	UISkin.circle(ci, tc, 5.8, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
	UISkin.circle(ci, tc, 4.6, Color("#8A1A16") if low else Color("#2A1A10"), Color("#3A0808") if low else Color("#140C08"))
	var tt := "%d" % int(ceil(BattleSim.boss_t))
	var fb := UITheme.font_body
	var tw := fb.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	_boss_hud.draw_string(fb, tc + Vector2(-tw / 2.0, 2.5), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#FFD0C0") if low else Color("#FFE7B0"))
	# boss fatigue tag: the boss starts weaker after failed tries
	if BattleSim.boss_pity > 0.0:
		var pt := DataDB.t("boss_fatigue", {"p": int(round(BattleSim.boss_pity * 100))})
		var pw := fb.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		var pr := Rect2(case.end.x - pw - 6, case.end.y + 2, pw + 6, 8)
		UISkin.fill(ci, pr, 2, Color("#5A3A10"), Color("#2A1A06"))
		UISkin.stroke(ci, pr, 2, UISkin.OUTLINE, 0.8)
		_boss_hud.draw_string(fb, Vector2(pr.position.x + 3, pr.end.y - 2), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#FFC870"))


func _draw_wave_dots() -> void:
	if BattleSim.phase == "town":
		return
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
	if BattleSim.phase == "town":
		# in town the plaque names the town, no stage tag or wave pips
		_zone_label.text = DataDB.t("town_name")
		_stage_label.text = ""
		_wave_dots.queue_redraw()
		_plaque.queue_redraw()
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
		"graveyard": "fog", "dark_forest": "leaf", "forest": "leaf", "void": "ember", "blood": "ember", "desert": "sand",
		"oasis": "sand", "cave": "dust", "mine": "dust", "ice_cave": "dust", "tomb": "dust", "bones": "fog",
		"meadow": "pollen", "town": "pollen", "camp": "ember", "temple": "motes", "temple_dark": "ember", "throne": "ember",
		"ruins": "dust", "harbor": "fog", "library": "dust", "hall": "dust", "castle": "dust"}.get(theme_name, "")
	_weather.clear()
	queue_redraw()


func _process(delta: float) -> void:
	_spread_plates()
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
	_plaque.queue_redraw()
	if BattleSim.phase == "boss" and BattleSim.boss_unit != null:
		_boss_hud.visible = true
		_boss_hud.queue_redraw()
		_boss_bar.visible = false
		_boss_name.visible = false
		_boss_time.visible = false
		_boss_bar.max_value = BattleSim.boss_unit.max_hp
		_boss_bar.value = max(0.0, BattleSim.boss_unit.hp)
		_boss_time.text = "%d" % int(ceil(BattleSim.boss_t))
		_boss_time.add_theme_color_override("font_color", UITheme.C_RED if BattleSim.boss_t < 10 else UITheme.C_TEXT)
	else:
		_boss_hud.visible = false
		_boss_trail = 1.0
		_boss_bar.visible = false
		_boss_name.visible = false
		_boss_time.visible = false
	if _banner_t > 0:
		_banner_t -= delta
		_banner.modulate.a = clamp(_banner_t, 0.0, 1.0)
		if _banner_bg:
			_banner_bg.modulate.a = _banner.modulate.a
		if _banner_t <= 0:
			_banner.visible = false
			if _banner_bg:
				_banner_bg.visible = false
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


## Weather lives on its own layer between the background and the units (drawn in StripView._draw it sat
## underneath the HD background sprite and never showed).
func _draw_weather() -> void:
	var n := _weather_node
	# weather drawn as soft shapes so it stays clean at 4-5x (was 1 px squares)
	var tms := Time.get_ticks_msec() / 1000.0
	for p in _weather:
		var wp := Vector2(p[0], p[1])
		match _weather_kind:
			"snow":
				n.draw_circle(wp, 1.5 * p[2], Color(1, 1, 1, 0.2))
				n.draw_circle(wp, 0.8 * p[2], Color(1, 1, 1, 0.85))
			"rain":
				n.draw_line(wp, wp + Vector2(-1.5, 4.5), Color(0.75, 0.85, 1.0, 0.4), 0.7, true)
			"ember":
				var fl: float = 0.6 + 0.4 * sin(tms * 6.0 + p[2] * 11.0)
				n.draw_circle(wp, 2.0, Color(1.0, 0.45, 0.1, 0.16 * fl))
				n.draw_circle(wp, 0.75, Color(1.0, 0.78, 0.4, 0.9 * fl))
			"leaf":
				n.draw_set_transform(wp, sin(tms * 2.0 + p[2] * 5.0) * 1.2, Vector2(1.0, 0.45))
				n.draw_circle(Vector2.ZERO, 1.6, Color(0.62, 0.8, 0.32, 0.75))
				n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"fog":
				n.draw_set_transform(wp + Vector2(12, 1.5), 0.0, Vector2(1.0, 0.16))
				n.draw_circle(Vector2.ZERO, 22.0, Color(0.85, 0.95, 0.95, 0.045))
				n.draw_circle(Vector2.ZERO, 12.0, Color(0.85, 0.95, 0.95, 0.05))
				n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"sand":
				n.draw_circle(wp, 0.7, Color(0.98, 0.86, 0.6, 0.6))
			"dust":
				n.draw_circle(wp, 1.3, Color(1.0, 0.95, 0.8, 0.06))
				n.draw_circle(wp, 0.65, Color(1.0, 0.95, 0.8, 0.35 + 0.2 * sin(p[2] * 9.0 + tms * 1.6)))
			"pollen":
				n.draw_circle(wp, 1.5, Color(1.0, 0.98, 0.75, 0.14))
				n.draw_circle(wp, 0.7, Color(1.0, 0.98, 0.8, 0.65 + 0.25 * sin(p[2] * 7.0 + tms * 2.0)))
			"motes":
				var tw: float = 0.5 + 0.5 * sin(tms * 3.0 + p[2] * 13.0)
				n.draw_circle(wp, 2.2, Color(1.0, 0.85, 0.45, 0.14 * tw))
				n.draw_circle(wp, 0.8, Color(1.0, 0.95, 0.7, 0.9 * tw))


func _update_weather(delta: float) -> void:
	_weather_node.queue_redraw()
	if _weather_kind == "":
		return
	# kept sparse on purpose: atmosphere only, never in the way of the fight
	var maxn := int({"fog": 10, "dust": 12, "sand": 16, "rain": 22, "pollen": 12, "motes": 14}.get(_weather_kind, 18) * float(Settings.get_v("particles", 1.0)))
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
			"sand":
				p[0] -= (scroll_speed + 22) * delta * p[2]
				p[1] += sin(p[0] * 0.08) * 3.0 * delta
			"dust":
				p[0] -= (scroll_speed + 1.5) * delta * p[2]
				p[1] += sin(p[0] * 0.05 + p[2]) * 1.5 * delta
			"pollen":
				p[0] -= (scroll_speed + 4.0) * delta * p[2]
				p[1] += sin(p[0] * 0.07 + p[2] * 3.0) * 2.5 * delta
			"motes":
				p[1] -= 3.5 * delta * p[2]
				p[0] -= (scroll_speed + sin(p[1] * 0.15) * 1.5) * delta
		if p[1] > H or p[1] < -H or p[0] < -30:
			p[0] = _rng.randf_range(0, W + 30) if p[0] < -30 else p[0]
			p[1] = H if _weather_kind in ["ember", "motes"] else -2.0
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
		if head and v._plate != "":
			y -= 9.0   # start above the elite / mini-boss name plate, not on it
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
	l.size = sz   # pooled labels keep their old size otherwise, which would skew the overlap rects
	l.pivot_offset = sz / 2.0
	# place the number where it covers no label already on screen: try its own spot, then step up by the
	# label height (big crits are taller than 8 px), then down; rects keep a gap so "132" "130" never read
	# as "132130" and numbers born a moment apart don't print over each other
	var base := pos - Vector2(sz.x / 2.0, sz.y * 0.6)
	base.y = maxf(base.y, 21.0)   # clear of the zone plaque / goal ribbon along the top edge
	# enemies entering from the right edge: keep the whole number (plus its sideways drift) on the strip
	base.x = clampf(base.x, 4.0, maxf(4.0, size.x - sz.x - 8.0))
	var step := maxf(8.0, sz.y * 0.72)
	var taken: Array = []
	for n in _active_nums:
		var ol: Label = n["l"]
		if ol.visible and ol.modulate.a > 0.2:
			taken.append(Rect2(ol.position - ol.size * (ol.scale - Vector2.ONE) * 0.5, ol.size * ol.scale).grow_individual(4, 1, 4, 1))
	var best := base
	for off in [0, -1, -2, -3, 1, 2]:
		var cand := base + Vector2(0, step * off)
		if cand.y < 21.0:
			continue
		var r := Rect2(cand, sz)
		if not taken.any(func(t): return t.intersects(r)):
			best = cand
			break
	base = best
	l.position = base.round()
	_active_nums.append({"l": l, "t": 0.0, "life": 0.95 if big else 0.75, "vx": _rng.randf_range(-6, 6), "y0": l.position.y, "big": big, "x0": pos.x, "w": sz.x})


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
		_spawn_number(DataDB.t("fx_miss"), pos, Color("#A8A8B8"))
		return
	var col := UITheme.element_color(element)
	if tgt.is_hero_side():
		col = Color("#FF8A7A")
	var txt := F.fmt_num(amount)
	if crit:
		txt += "!"
	if kind == "block":
		_spawn_number(DataDB.t("fx_block"), pos + Vector2(0, -6), Color("#8FB4FF"))
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
	if SkillFx.handles(vfx):
		var pts: Array = []
		for uid in tgts:
			var tv: UnitView = views.get(uid)
			if tv:
				pts.append(Vector2(tv.position.x, BattleSim.GROUND_Y))
		pts.sort_custom(func(a, b): return a.x < b.x)
		var sv: UnitView = views.get(data.get("src", -1))
		var sp := Vector2(sv.position.x, BattleSim.GROUND_Y) if sv else pos
		var fx := SkillFx.new()
		fx.setup(vfx, sp, pts)
		fx_root.add_child(fx)
		if vfx in ["comet", "earth_split", "blizzard", "sun_burst", "thunder_chord", "shockwave"]:
			_shake = maxf(_shake, 0.18)
		return
	var col := Color.WHITE
	match vfx:
		"enrage":
			# the boss turns: a danger banner, a red burst on it and a jolt, instead of a line of text
			_show_banner(DataDB.t("boss_enraged", {"name": str(data.get("name", ""))}), Color("#FF5A3A"), true)
			_spawn_vfx("burst", pos - Vector2(0, 22), Color("#FF4A2A"), 22)
			_spawn_vfx("burst", pos - Vector2(0, 12), Color("#FFB04A"), 12)
			_shake = maxf(_shake, 0.3)
			return
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
		slowmo(0.35, 0.4)
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
			_spawn_number(DataDB.t("level_up_n", {"n": lv}), _unit_pos(u, true) + Vector2(0, -10), Color("#FFE08A"), true)
	AudioManager.play("levelup", 0.0, 0.9)


func _on_boss_spawned(u) -> void:
	_boss_name.text = u.name
	_dim(0.45, 1.4)
	_show_banner(DataDB.t("boss_appears", {"name": u.name}), Color("#FF6A5A"), true)
	AudioManager.play("boss_warning", 0.0, 1.0)
	AudioManager.play_music("boss")


func _on_phase(p: String) -> void:
	_update_hud_text()
	_town_overlay.visible = p == "town"
	if p == "town":
		_set_theme("town")
		_show_banner(DataDB.t("town_name"), UITheme.C_TEXT)
		AudioManager.play_music("town")
	elif _theme == "town":
		_set_theme(str(BattleSim.zone().get("background", "meadow")))
		AudioManager.play_music(str(BattleSim.zone().get("music", "act1")))
	if p == "travel" and BattleSim.is_boss_stage():
		_show_banner(DataDB.t("boss_incoming"), Color("#FF9A6A"), true)


## Hanging wooden signboard in town (tavern, store): swings a little, glows on hover.
func _town_sign(panel_id: String, text: String, icon_name: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var f := UITheme.font_title
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	b.size = Vector2(tw + 26.0, 20)
	b.tooltip_text = text
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.6)
		WindowManager.toggle_panel(panel_id))
	var ic := UITheme.icon(icon_name)
	var phase := randf() * TAU
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var hov := b.is_hovered()
		var t := Time.get_ticks_msec() / 1000.0
		var sway := sin(t * 1.6 + phase) * 0.035
		var open := WindowManager.is_open(panel_id)
		var gift := panel_id == "shop" and Shop.daily_ready()
		b.draw_set_transform(Vector2(b.size.x / 2.0, 0), sway, Vector2.ONE)
		var r := Rect2(Vector2(-b.size.x / 2.0, 4), Vector2(b.size.x, 15))
		# chains
		for cx in [r.position.x + 5.0, r.end.x - 5.0]:
			b.draw_line(Vector2(cx, 0), Vector2(cx, 5), Color("#2A1E16"), 1.4)
			b.draw_line(Vector2(cx, 0), Vector2(cx, 5), Color("#B79868"), 0.6)
		if hov or open:
			UISkin.stroke(ci, r.grow(1.5), 4, Color(1.0, 0.85, 0.4, 0.55), 2.0)
		elif gift:
			UISkin.stroke(ci, r.grow(1.5), 4, Color(0.5, 1.0, 0.55, 0.35 + 0.3 * sin(t * 4.0)), 2.0)
		# a walnut plank cut from the window frame's painted wood (same grain as every window)
		UISkin.fill(ci, r, 3, Color("#5A3720"), Color("#2A170C"))
		var wood := Rect2(UISkin.FRAME_CORNER * UISkin.FRAME_PX, 4.0, UISkin.FRAME_EDGE * UISkin.FRAME_PX, 22.0)
		RenderingServer.canvas_item_add_texture_rect_region(ci, r.grow(-1.0), UISkin.FRAME_TEX.get_rid(), wood,
			Color(1.25, 1.2, 1.15) if hov else Color.WHITE)
		UISkin.fill(ci, r.grow(-1.0), 2, Color(1, 0.9, 0.7, 0.10), Color(0, 0, 0, 0.30))
		UISkin.stroke(ci, r, 3, Color("#1A0E08"), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color("#D8A85A", 0.7), 0.8)
		UISkin.rivet(ci, r.position + Vector2(3, 3), 1.1)
		UISkin.rivet(ci, Vector2(r.end.x - 3, r.position.y + 3), 1.1)
		b.draw_texture_rect(ic, Rect2(r.position + Vector2(4, 2.5), Vector2(10, 10)), false)
		var tp := r.position + Vector2(17, 11)
		b.draw_string_outline(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color(0, 0, 0, 0.85))
		b.draw_string(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFE7B0") if not hov else Color("#FFF6D8"))
		b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	var tm := Timer.new()
	tm.wait_time = 1.0 / 20.0
	tm.autostart = true
	tm.timeout.connect(func():
		if b.is_visible_in_tree():
			b.queue_redraw())
	b.add_child(tm)
	return b


## A short slow-motion beat (boss kill, legendary drop). Real time, so it always ends.
func slowmo(dur: float, factor: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = factor
	get_tree().create_timer(dur, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


## Darkens the battlefield for a moment (boss entrance).
func _dim(amount: float, dur: float) -> void:
	if _dimmer == null:
		_dimmer = ColorRect.new()
		_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dimmer.size = Vector2(W, H)
		_dimmer.color = Color(0.05, 0.0, 0.02, 0.0)
		hud.add_child(_dimmer)
		hud.move_child(_dimmer, 0)
	var tw := _dimmer.create_tween()
	tw.tween_property(_dimmer, "color:a", amount, dur * 0.25)
	tw.tween_interval(dur * 0.35)
	tw.tween_property(_dimmer, "color:a", 0.0, dur * 0.4)


var _dimmer: ColorRect
var _banner_bg: Control
var _banner_red := false


## danger: the crimson ribbon (boss coming / arrived, party wiped); otherwise walnut with the text in `color`.
func _show_banner(text: String, color: Color, danger := false) -> void:
	if _banner_bg == null:
		# ribbon behind the banner text
		_banner_bg = Control.new()
		_banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_banner_bg.size = Vector2(W, 20)
		_banner_bg.position = Vector2(0, 20)
		_banner_bg.draw.connect(func():
			var tw := UITheme.font_title.get_string_size(_banner.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var rr := Rect2((W - tw) / 2.0 - 16.0, 2, tw + 32.0, 16)
			var ci := _banner_bg.get_canvas_item()
			# a banner of the window-title family: crimson for danger (bosses), deep walnut otherwise,
			# with a soft shadow on the battlefield below it
			UISkin.fill(ci, Rect2(rr.position + Vector2(2, 3), rr.size), 4, Color(0, 0, 0, 0.30), Color(0, 0, 0, 0.30))
			if _banner_red:
				UISkin.ribbon(ci, rr)
			else:
				UISkin.ribbon(ci, rr, Color("#5A3A22"), Color("#2A170C")))
		hud.add_child(_banner_bg)
		hud.move_child(_banner_bg, _banner.get_index())
	_banner_bg.visible = true
	_banner_bg.queue_redraw()
	_banner.text = text
	_banner_red = danger
	# on the crimson ribbon the text is cream (the red text colour would vanish into it)
	_banner.add_theme_color_override("font_color", Color("#FFF0D2") if _banner_red else (Color("#FFE7B0") if color == UITheme.C_TEXT else color))
	_banner.add_theme_color_override("font_outline_color", Color("#3A0A0C") if _banner_red else Color(0, 0, 0, 0.85))
	_banner.add_theme_constant_override("outline_size", 3)
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner_t = 2.2


## Elite / mini-boss name plates of units standing close together would overlap: lay them out left to
## right with a 2 px gap, keep the group centred on its units, and stay inside the strip.
func _spread_plates() -> void:
	var items: Array = []
	for uid in views:
		var v = views[uid]
		if is_instance_valid(v) and v.visible and v.plate_width() > 0.0:
			items.append([v.position.x, v.plate_width(), v])
	if items.size() < 2:
		for it in items:
			it[2].plate_dx = 0.0
		return
	items.sort_custom(func(a, b): return a[0] < b[0])
	# left edges after pushing each plate right of the previous one
	var lefts: Array = []
	var cur := -INF
	for it in items:
		var l: float = maxf(float(it[0]) - float(it[1]) / 2.0, cur)
		lefts.append(l)
		cur = l + float(it[1]) + 2.0
	# shift the whole row back so it is centred on the units, then clamp to the strip
	var want := 0.0
	var got := 0.0
	for i in items.size():
		want += float(items[i][0])
		got += float(lefts[i]) + float(items[i][1]) / 2.0
	var shift := (want - got) / items.size()
	shift = clampf(shift, 2.0 - float(lefts[0]), W - 2.0 - (float(lefts[-1]) + float(items[-1][1])))
	for i in items.size():
		var cx: float = float(lefts[i]) + shift + float(items[i][1]) / 2.0
		items[i][2].plate_dx = cx - float(items[i][0])
