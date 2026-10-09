extends PanelWindow
## "While you were away" report: time plaque, four counting reward tiles, the heroes that levelled up and the
## best loot popping in one by one. Collect closes it with a coin sound.

var report: Dictionary = {}
var _host: Control
var _stage: Control
var _loot: HBoxContainer
var _t := 0.0

const TILE_H := 26.0
const COUNT_T := 0.9


func build(c: Control) -> void:
	_host = c
	_stage = Control.new()
	_stage.size = Vector2(c.size.x, c.size.y - 20)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
	c.add_child(_stage)
	_loot = W.hbox(3)
	c.add_child(_loot)
	var b := Fancy.small_button(DataDB.t("btn_collect"), "gold", func():
		AudioManager.play("coins")
		WindowManager.close_panel("away"), Vector2(c.size.x, 16))
	b.position = Vector2(0, c.size.y - 16)
	c.add_child(b)
	refresh()


func set_report(r: Dictionary) -> void:
	report = r
	_t = 0.0
	refresh()


func _process(delta: float) -> void:
	if _stage == null:
		return
	_t += delta
	if _t < 3.0:
		_stage.queue_redraw()


func refresh() -> void:
	if _loot == null:
		return
	for ch in _loot.get_children():
		ch.queue_free()
	var items: Array = report.get("items", [])
	var n := mini(items.size(), 6)
	_loot.position = Vector2((_host.size.x - (n * 26 + (n - 1) * 3)) / 2.0, _loot_y() + 8)
	for i in n:
		var sl := ItemSlot.new(26.0)
		sl.set_item(items[i])
		sl.pivot_offset = Vector2(13, 13)
		sl.scale = Vector2.ZERO
		_loot.add_child(sl)
		var tw := sl.create_tween()
		tw.tween_interval(0.5 + 0.12 * i)
		tw.tween_callback(func(): AudioManager.play("item_drop", 0.05, 0.25))
		tw.tween_property(sl, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stage.queue_redraw()


func _levels() -> Dictionary:
	return report.get("levels", {})


func _loot_y() -> float:
	return 100.0 + (26.0 if not _levels().is_empty() else 0.0)


func _draw_stage() -> void:
	if report.is_empty():
		return
	var ci := _stage.get_canvas_item()
	var w := _stage.size.x
	var ft := UITheme.font_title
	var fb := UITheme.font_body
	var fs := UITheme.font_small
	# ---- time plaque: hourglass medallion, time in big letters, efficiency underneath
	var plate := Rect2(0, 0, w, 32)
	UISkin.fill(ci, plate, 4, Color("#3A2A1E"), Color("#1E140E"))
	UISkin.stroke(ci, plate, 4, UISkin.OUTLINE, 1.0)
	UISkin.stroke(ci, plate.grow(-1.5), 3, Color(UISkin.BRONZE, 0.55), 0.8)
	UISkin.circle(ci, Vector2(17, 16), 12.5, UISkin.BRONZE_HI, UISkin.BRONZE_LO)
	UISkin.circle(ci, Vector2(17, 16), 10.5, Color("#2A3450"), Color("#141A2C"))
	var spin := sin(_t * 2.0) * 0.06
	_stage.draw_set_transform(Vector2(17, 16), spin, Vector2.ONE)
	_stage.draw_texture_rect(UITheme.icon("clock"), Rect2(-8, -8, 16, 16), false)
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var s := int(report.get("seconds", 0))
	var dur := DataDB.t("away_dur", {"h": s / 3600, "m": (s % 3600) / 60})
	_stage.draw_string_outline(ft, Vector2(36, 25), dur, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(0, 0, 0, 0.8))
	_stage.draw_string(ft, Vector2(36, 25), dur, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FFE7A6"))
	var eff := DataDB.t("away_eff", {"p": int(round(float(report.get("eff", 0.6)) * 100))})
	var x2 := float(Shop.offline_bonus()["mult"]) > 1.0
	var ew := fb.get_string_size(eff, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	var pill := Rect2(w - ew - 12, 5, ew + 8, 10)
	UISkin.fill(ci, pill, 3, Color("#2A4A30"), Color("#16281A"))
	UISkin.stroke(ci, pill, 3, UISkin.OUTLINE, 0.8)
	_stage.draw_string(fb, Vector2(pill.position.x + 4, pill.end.y - 2.3), eff, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#9CF0A0"))
	_stage.draw_string(fs, Vector2(36, 11), DataDB.t("away_head"), HORIZONTAL_ALIGNMENT_LEFT, pill.position.x - 40, 7, Color("#C9B08A"))
	if x2:
		var hg := "x2"
		var hw := fb.get_string_size(hg, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var p2 := Rect2(w - hw - 21, 18, hw + 17, 10)
		UISkin.fill(ci, p2, 3, Color("#6A4A16"), Color("#3A2408"))
		UISkin.stroke(ci, p2, 3, UISkin.OUTLINE, 0.8)
		_stage.draw_texture_rect(UITheme.icon("clock"), Rect2(p2.position + Vector2(2.5, 1.5), Vector2(7, 7)), false)
		_stage.draw_string(fb, Vector2(p2.position.x + 12, p2.end.y - 2.3), hg, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#FFD86A"))
	# ---- reward tiles, values count up
	var k := clampf(_t / COUNT_T, 0.0, 1.0)
	k = 1.0 - pow(1.0 - k, 3.0)
	var tiles := [
		["sword", DataDB.t("away_kills"), F.fmt_num(int(float(report.get("kills", 0)) * k)), Color("#F0E2C8")],
		["star", DataDB.t("away_xp"), F.fmt_num(float(report.get("xp", 0)) * k), Color("#9CF0A0")],
		["gold", DataDB.t("gold"), F.fmt_num(int(float(report.get("gold", 0)) * k)), Color("#FFD86A")],
		["chest", DataDB.t("away_items"), str(int(round(float(report.get("item_count", 0)) * k))), Color("#9FD8FF")],
	]
	var tw := (w - 3.0) / 2.0
	for i in 4:
		var appear := clampf((_t - 0.06 * i) / 0.25, 0.0, 1.0)
		var r := Rect2((i % 2) * (tw + 3.0), 36.0 + (i / 2) * (TILE_H + 3.0) + (1.0 - appear) * 4.0, tw, TILE_H)
		var a := appear
		UISkin.fill(ci, r, 3, Color(0.2, 0.15, 0.11, a), Color(0.1, 0.07, 0.05, a))
		UISkin.stroke(ci, r, 3, Color(UISkin.OUTLINE, a), 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color(1, 0.85, 0.55, 0.12 * a), 0.7)
		UISkin.circle(ci, r.position + Vector2(13, 13), 9.5, Color(0.35, 0.26, 0.16, a), Color(0.16, 0.11, 0.07, a))
		_stage.draw_texture_rect(UITheme.icon(tiles[i][0]), Rect2(r.position + Vector2(6, 6), Vector2(14, 14)), false, Color(1, 1, 1, a))
		var val: String = tiles[i][2]
		var col: Color = tiles[i][3]
		_stage.draw_string_outline(ft, r.position + Vector2(26, 13), val, HORIZONTAL_ALIGNMENT_LEFT, tw - 28, 11, 3, Color(0, 0, 0, 0.8 * a))
		_stage.draw_string(ft, r.position + Vector2(26, 13), val, HORIZONTAL_ALIGNMENT_LEFT, tw - 28, 11, Color(col, a))
		_stage.draw_string(fs, r.position + Vector2(26, 22), tiles[i][1], HORIZONTAL_ALIGNMENT_LEFT, tw - 28, 7, Color(0.78, 0.69, 0.55, a))
	# ---- heroes that levelled up: portrait chips with a green +n
	var lv := _levels()
	var y := 96.0
	if not lv.is_empty():
		var lt := DataDB.t("away_levels")
		_stage.draw_string(fs, Vector2(0, y + 13), lt, HORIZONTAL_ALIGNMENT_LEFT, 70, 7, Color("#C9B08A"))
		var x := minf(fs.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, 70.0) + 6.0
		var j := 0
		for hid in lv:
			if x > w - 24:
				break
			var pop := clampf((_t - 0.35 - 0.08 * j) / 0.2, 0.0, 1.0)
			var r2 := Rect2(x, y, 20, 20)
			# portrait in a jewel tile (green = levelled up) with a soft glow and a "+n" enamel lvpill
			if pop > 0.0:
				UISkin.stroke(ci, r2.grow(1.2), 4, Color(0.5, 1.0, 0.6, 0.25 * pop), 1.4)
			UISkin.slot(ci, r2, Color("#2F9A4A"), true, false)
			var ic := SpriteLib.hero_icon(str(hid))
			if ic:
				_stage.draw_texture_rect(ic, r2.grow(-2.0), false, Color(1, 1, 1, pop))
			var tag := "+%d" % int(lv[hid])
			var tw2 := fb.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			var lvpill := Rect2(r2.end.x - tw2 - 5.0, r2.end.y - 6.0, tw2 + 6.0, 9.0)
			UISkin.fill(ci, lvpill, 3, Color(0.35, 0.85, 0.45, pop), Color(0.12, 0.45, 0.2, pop))
			UISkin.stroke(ci, lvpill, 3, Color(UISkin.OUTLINE, pop), 0.8)
			_stage.draw_string_outline(fb, Vector2(lvpill.position.x + 3, lvpill.end.y - 2.2), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.6 * pop))
			_stage.draw_string(fb, Vector2(lvpill.position.x + 3, lvpill.end.y - 2.2), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, pop))
			x += 24.0
			j += 1
	# ---- best loot well (the slots are real ItemSlots laid over it)
	var items: Array = report.get("items", [])
	if not items.is_empty():
		var ly := _loot_y()
		var well := Rect2(0, ly, w, 40)
		UISkin.well(ci, well)
		var cap := DataDB.t("away_best").trim_suffix(":")
		var cw := fs.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var cr := Rect2((w - cw) / 2.0 - 6, ly - 4, cw + 12, 9)
		UISkin.fill(ci, cr, 3, Color("#4A3420"), Color("#2A1C10"))
		UISkin.stroke(ci, cr, 3, UISkin.OUTLINE, 0.8)
		UISkin.stroke(ci, cr.grow(-0.7), 2.5, Color(UISkin.BRONZE_HI, 0.6), 0.6)
		UISkin.diamond(ci, Vector2(cr.position.x, cr.get_center().y), 1.6)
		UISkin.diamond(ci, Vector2(cr.end.x, cr.get_center().y), 1.6)
		_stage.draw_string(fs, Vector2(cr.position.x + 6, cr.end.y - 2), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#E8C98A"))
	var sold := int(report.get("sold", 0))
	if sold > 0:
		var st := DataDB.t("away_sold", {"g": F.fmt_num(sold)})
		_stage.draw_string(fs, Vector2(0, _loot_y() + 50), st, HORIZONTAL_ALIGNMENT_CENTER, w, 7, Color("#B8A68A"))
