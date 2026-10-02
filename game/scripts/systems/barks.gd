class_name Barks
extends RefCounted
## Hero speech bubbles ("barks") with per-hero and per-class lines.

static var _data: Dictionary = {}


static func _load() -> void:
	if not _data.is_empty():
		return
	if FileAccess.file_exists("res://data/barks.json"):
		var p: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/barks.json"))
		if p is Dictionary:
			_data = p


static func trigger(hero_id: String, event: String, chance := 0.6) -> void:
	_load()
	if randf() > chance:
		return
	var lines: Array = _data.get("heroes", {}).get(hero_id, {}).get(event, [])
	if lines.is_empty():
		var cls: String = DataDB.hero_def(hero_id).get("class", "")
		lines = _data.get("classes", {}).get(cls, {}).get(event, [])
	if lines.is_empty():
		lines = _data.get("generic", {}).get(event, [])
	if lines.is_empty():
		return
	var l: Variant = lines[randi() % lines.size()]
	EventBus.bark.emit(hero_id, DataDB.tx(l))
