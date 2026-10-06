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
	# one pool per event: the hero's own lines, their class's lines and the generic ones
	var cls: String = DataDB.hero_def(hero_id).get("class", "")
	var lines: Array = []
	lines.append_array(_data.get("heroes", {}).get(hero_id, {}).get(event, []))
	lines.append_array(_data.get("classes", {}).get(cls, {}).get(event, []))
	lines.append_array(_data.get("generic", {}).get(event, []))
	if lines.is_empty():
		return
	var l: Variant = lines[randi() % lines.size()]
	EventBus.bark.emit(hero_id, DataDB.tx(l))


## The hero's own first line for an event (no randomness), "" if they have none. Used by the recruit card.
static func line(hero_id: String, event: String) -> String:
	_load()
	var lines: Array = _data.get("heroes", {}).get(hero_id, {}).get(event, [])
	return DataDB.tx(lines[0]) if lines.size() > 0 else ""

