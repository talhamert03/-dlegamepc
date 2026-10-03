extends Node
## Loads all JSON game data at startup and offers lookups + localization helpers.

var balance: Dictionary = {}
var classes: Dictionary = {}
var skills: Dictionary = {}
var skills_by_class: Dictionary = {}
var heroes: Dictionary = {}
var hero_order: Array = []
var factions: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var bosses: Dictionary = {}
var villains: Dictionary = {}
var zones: Array = []
var zone_by_id: Dictionary = {}
var acts: Array = []
var difficulties: Array = []
var strings: Dictionary = {}
var achievements: Array = []
var runes: Dictionary = {}       # class -> {branches, nodes} (tools/data/gen_runes.py)
var pets: Dictionary = {}
var hero_anims: Dictionary = {}
var lang: String = "tr"
var loaded := false


func _ready() -> void:
	load_all()


func load_all() -> void:
	balance = _load("res://data/balance.json")
	classes = _load("res://data/classes.json")
	var sk: Dictionary = _load("res://data/skills.json")
	skills.clear()
	skills_by_class.clear()
	for s in sk.get("skills", []):
		skills[s["id"]] = s
		if not skills_by_class.has(s["class"]):
			skills_by_class[s["class"]] = []
		skills_by_class[s["class"]].append(s["id"])
	var hd: Dictionary = _load("res://data/heroes.json")
	factions = hd.get("factions", {})
	heroes.clear()
	hero_order.clear()
	for h in hd.get("heroes", []):
		heroes[h["id"]] = h
		hero_order.append(h["id"])
	items = _load("res://data/items.json")
	var ed: Dictionary = _load("res://data/enemies.json")
	enemies = ed.get("enemies", {})
	bosses = ed.get("bosses", {})
	villains = ed.get("villains", {})
	var zd: Dictionary = _load("res://data/zones.json")
	zones = zd.get("zones", [])
	acts = zd.get("acts", [])
	difficulties = zd.get("difficulties", [])
	zone_by_id.clear()
	for i in zones.size():
		zones[i]["_idx"] = i
		zone_by_id[zones[i]["id"]] = zones[i]
	strings = _load("res://data/strings.json")
	var ach: Dictionary = _load("res://data/achievements.json")
	achievements = ach.get("achievements", [])
	pets = _load("res://data/pets.json")
	runes = _load("res://data/runes.json")
	hero_anims = _load("res://assets/sprites/heroes/anims.json")
	loaded = true


func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("DataDB: missing %s" % path)
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null or not (parsed is Dictionary):
		push_error("DataDB: failed to parse %s" % path)
		return {}
	return parsed


# ------------------------------------------------------------------ localization
func set_lang(l: String) -> void:
	lang = l
	EventBus.language_changed.emit()


## Localize a {"tr": "...", "en": "..."} dictionary (or pass-through strings).
func tx(v: Variant) -> String:
	if v is Dictionary:
		if v.has(lang):
			return str(v[lang])
		if v.has("en"):
			return str(v["en"])
		return ""
	return str(v)


## UI string by key from strings.json, with {name} placeholders.
func t(key: String, args: Dictionary = {}) -> String:
	var s: String = key
	if strings.has(key):
		s = tx(strings[key])
	for k in args:
		s = s.replace("{%s}" % k, str(args[k]))
	return s


# ------------------------------------------------------------------ lookups
func bal(path: String, default: Variant = null) -> Variant:
	var cur: Variant = balance
	for part in path.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		else:
			return default
	return cur


func zone(idx: int) -> Dictionary:
	if idx < 0 or idx >= zones.size():
		return {}
	return zones[idx]


func enemy_def(id: String) -> Dictionary:
	if enemies.has(id):
		return enemies[id]
	if bosses.has(id):
		return bosses[id]
	return {}


func class_def(id: String) -> Dictionary:
	return classes.get(id, {})


func hero_def(id: String) -> Dictionary:
	return heroes.get(id, {})


func skill_def(id: String) -> Dictionary:
	return skills.get(id, {})
