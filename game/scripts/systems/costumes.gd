class_name Costumes
extends RefCounted
## Account-wide costume unlocks; a costume recolors a hero's primary outfit colour via shader.

static var _defs: Dictionary = {}


static func defs() -> Dictionary:
	if _defs.is_empty():
		_defs = DataDB._load("res://data/costumes.json").get("costumes", {})
	return _defs


static func unlocked() -> Array:
	return GameState.flags.get("costumes", [])


static func is_unlocked(cid: String) -> bool:
	return cid == "" or unlocked().has(cid)


## Checks unlock conditions; returns newly unlocked ids.
static func check_unlocks() -> Array:
	var have: Array = unlocked().duplicate()
	var fresh: Array = []
	for cid in defs():
		if have.has(cid):
			continue
		var u: Dictionary = defs()[cid].get("unlock", {})
		var ok := false
		match str(u.get("type", "")):
			"cleared":
				ok = GameState.progress.get("cleared", {}).has(str(u.get("key", "")))
			"flag":
				ok = bool(GameState.flags.get(str(u.get("key", "")), false))
			"difficulty":
				var mz: Array = GameState.progress.get("max_zone", [0, -1, -1])
				ok = int(mz[int(u.get("key", 1))]) >= 0
			"tower":
				ok = int(GameState.progress.get("tower_best", 0)) >= int(u.get("key", 10))
		if ok:
			have.append(cid)
			fresh.append(cid)
			# a reward plate above the strip (several at once fold into one "×3" plate), not text over the fight
			var nm := DataDB.tx(defs()[cid].get("name", {}))
			if Engine.get_main_loop() and WindowManager.top_layer:
				Toast.show_reward(UITheme.icon("sparkle"), DataDB.t("costume_new_title"), nm, "", "coin")
			else:
				EventBus.notify.emit(DataDB.t("costume_new", {"name": nm}), Color("#FFB0D8"))
	if not fresh.is_empty():
		GameState.flags["costumes"] = have
	return fresh


## Configures a ShaderMaterial (unit or portrait shader) for the hero's current costume.
static func apply(mat: ShaderMaterial, hid: String) -> void:
	if mat == null:
		return
	var h: HeroState = GameState.heroes.get(hid)
	var cid: String = h.costume if h else ""
	var cd: Dictionary = defs().get(cid, {})
	if cd.is_empty():
		mat.set_shader_parameter("recolor", 0.0)
		return
	var prim := Color(str(DataDB.hero_def(hid).get("visual", {}).get("primary", "#3D6FD6")))
	mat.set_shader_parameter("recolor", 1.0)
	mat.set_shader_parameter("src_hue", prim.h)
	mat.set_shader_parameter("dst_hue", float(cd.get("hue", 0.0)))
	mat.set_shader_parameter("sat_mul", float(cd.get("sat", 1.0)))
	mat.set_shader_parameter("val_mul", float(cd.get("val", 1.0)))
