extends Node2D
## Dev tool: renders single-image monsters large through their states (idle, attack wind-up, strike,
## hit, death) and saves a contact sheet to user://screenshots/anim_preview.png.
## godot --rendering-driver opengl3 res://tools/AnimPreview.tscn -- --ids=zombie,skeleton

const SCALE := 3.0
const TIMES := [0.4, 1.1, 1.8, 2.25, 2.55, 2.8, 3.45, 4.4, 5.0]   # snapshot moments
var _units: Array = []
var _views: Array = []
var _t := 0.0
var _shots: Array = []
var _next := 0
var _vp: SubViewport


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#2A3A2A"))
	var ids := ["zombie", "skeleton", "spider", "ghost", "ent_sapling", "crystal_golem", "snow_wolf", "sand_worm", "ice_slime", "harpy"]
	for a in OS.get_cmdline_user_args():
		if a == "--gif":
			_gif = true
		if a.begins_with("--ids="):
			ids = a.substr(6).split(",")
	BattleSim.set_process(false)
	_vp = SubViewport.new()
	_vp.size = Vector2i(40 + ids.size() * 150, 230)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var bg := ColorRect.new()
	bg.color = Color("#33402F")
	bg.size = Vector2(_vp.size)
	_vp.add_child(bg)
	var col := 0
	for eid in ids:
		var d := DataDB.enemy_def(eid)
		var u := Combatant.new()
		u.side = Combatant.Side.ENEMY
		u.id = eid
		u.etype = "normal"
		u.stats = {"melee": float(d.get("range", 24)) < 60.0, "range": float(d.get("range", 24))}
		u.max_hp = 100.0
		u.hp = 100.0
		u.visual = {"kind": "enemy", "id": eid, "def": d.get("visual", {}), "elite": false, "boss": false}
		u.act_impact = 0.35
		u.act_len = 0.75
		var v := UnitView.new()
		v.setup(u)
		var holder := Node2D.new()
		holder.scale = Vector2(SCALE, SCALE)
		holder.position = Vector2(95 + col * 150, 215)
		_vp.add_child(holder)
		holder.add_child(v)
		v.position = Vector2.ZERO
		_units.append(u)
		_views.append(v)
		col += 1


var _gif := false
var _gif_n := 0


func _process(delta: float) -> void:
	if _gif:
		delta = 1.0 / 15.0
	_t += delta
	for u in _units:
		u.anim_t += delta
		if _t > 2.0 and _t - delta <= 2.0:
			u.set_anim("attack")
		if _t > 3.2 and _t - delta <= 3.2:
			u.set_anim("hit")
			u.flash_t = 0.12
		if _t > 4.0 and _t - delta <= 4.0:
			u.alive = false
			u.set_anim("death")
		u.flash_t = maxf(0.0, u.flash_t - delta)
	for v in _views:
		v.position = Vector2.ZERO
	if _gif:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://screenshots/gif")
		_vp.get_texture().get_image().save_png("user://screenshots/gif/f_%03d.png" % _gif_n)
		_gif_n += 1
		if _t >= 5.6:
			print("PREVIEW_DONE")
			get_tree().quit()
		return
	if _next < TIMES.size() and _t >= float(TIMES[_next]):
		await RenderingServer.frame_post_draw
		_shots.append(_vp.get_texture().get_image())
		_next += 1
		if _next == TIMES.size():
			var w: int = _shots[0].get_width()
			var h: int = _shots[0].get_height()
			var sheet := Image.create(w, h * _shots.size(), false, _shots[0].get_format())
			for i in _shots.size():
				sheet.blit_rect(_shots[i], Rect2i(0, 0, w, h), Vector2i(0, i * h))
			DirAccess.make_dir_recursive_absolute("user://screenshots")
			sheet.save_png("user://screenshots/anim_preview.png")
			print("PREVIEW_DONE")
			get_tree().quit()
