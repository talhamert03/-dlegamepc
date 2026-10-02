extends Node
## User settings persisted in user://settings.cfg

const PATH := "user://settings.cfg"

var values: Dictionary = {
	"lang": "tr",
	"scale": 0,               # 0 = auto
	"strip_pos": "taskbar",   # taskbar | top | free
	"strip_x": -1, "strip_y": -1, "strip_screen": -1,
	"always_on_top": true,
	"hide_fullscreen": true,
	"fps_focus": 60, "fps_idle": 15,
	"vol_master": 0.4, "vol_music": 0.7, "vol_sfx": 0.8, "unfocus_duck": 0.6, "mute": false,
	"dmg_numbers": 2,         # 0 off, 1 crits only, 2 all
	"screen_shake": true,
	"particles": 1.0,
	"auto_equip": true,
	"auto_stats": true,
	"auto_progress": true,
	"barks": 1,               # 0 off 1 few 2 normal
	"loot_common": "sell", "loot_magic": "keep", "loot_rare": "keep", "loot_epic": "keep",
	"strip_opacity": 1.0,
	"show_bg": true,
	"colorblind": false,
	"panel_pos": {},
	"tutorial_done": false,
	"start_with_os": false,
}


func _ready() -> void:
	load_settings()
	DataDB.lang = str(values.get("lang", "tr"))


func get_v(key: String, default: Variant = null) -> Variant:
	return values.get(key, default)


func set_v(key: String, v: Variant, save := true) -> void:
	values[key] = v
	if key == "lang":
		DataDB.set_lang(str(v))
	if save:
		save_settings()
	EventBus.settings_changed.emit()


func loot_action(rarity: String) -> String:
	match rarity:
		"common", "magic", "rare", "epic":
			return str(values.get("loot_" + rarity, "keep"))
	return "keep"


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in cf.get_section_keys("settings"):
		values[k] = cf.get_value("settings", k)


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in values:
		cf.set_value("settings", k, values[k])
	cf.save(PATH)
