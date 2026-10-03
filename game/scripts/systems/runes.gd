class_name Runes
extends RefCounted
## Leadership rune tree: the player's own growth as commander (data/runes.json, built by
## tools/data/gen_runes.py). Account-wide, bought with gold. A core rune and four branches; a rune can be
## bought once a rune it is linked to has a rank. A rune may name the classes it empowers ("cls"), otherwise
## its bonus reaches every hero.


static func nodes() -> Dictionary:
	return DataDB.runes.get("nodes", {})


static func branches() -> Array:
	return DataDB.runes.get("branches", [])


static func node(id: String) -> Dictionary:
	return nodes().get(id, {})


static func rank(id: String) -> int:
	return int(GameState.runes.get(id, 0))


static func max_rank(id: String) -> int:
	return int(node(id).get("max", 1))


static func pos(id: String) -> Vector2i:
	var n := node(id)
	return Vector2i(int(n.get("x", 0)), int(n.get("y", 0)))


static func stat(id: String) -> String:
	return str(node(id).get("stat", ""))


static func per(id: String) -> float:
	return float(node(id).get("per", 0.0))


static func glyph(id: String) -> String:
	return str(node(id).get("glyph", "rune"))


static func links(id: String) -> Array:
	return node(id).get("links", [])


static func classes(id: String) -> Array:
	return node(id).get("cls", [])


static func is_cap(id: String) -> bool:
	return bool(node(id).get("cap", false))


static func display_name(id: String) -> String:
	return DataDB.tx(node(id).get("name", {}))


static func branch_of(id: String) -> Dictionary:
	var key := str(node(id).get("br", ""))
	for b in branches():
		if b["key"] == key:
			return b
	return {}


static func branch_color(id: String) -> Color:
	var b := branch_of(id)
	return Color(str(b["color"])) if not b.is_empty() else Color("#FFE9B0")


static func ring(id: String) -> int:
	var p := pos(id)
	return absi(p.x) + absi(p.y)


## Gold price of the next rank; capstones cost like four ranks.
static func cost(id: String) -> int:
	var c := 200.0 * pow(2.1, maxi(0, ring(id) - 1)) * pow(1.6, rank(id))
	if is_cap(id):
		c *= 4.0
	return int(round(c / 10.0) * 10.0)


static func is_open(id: String) -> bool:
	if links(id).is_empty():
		return true
	for l in links(id):
		if rank(str(l)) > 0:
			return true
	return false


static func can_buy(id: String) -> bool:
	return nodes().has(id) and is_open(id) and rank(id) < max_rank(id) and GameState.gold >= cost(id)


static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	GameState.spend_gold(cost(id))
	GameState.runes[id] = rank(id) + 1
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.runes_changed.emit()
	return true


## Bonuses reaching one hero (class-limited runes only count for their classes). h == null: every rune.
static func totals_for(h: HeroState) -> Dictionary:
	var out := {}
	var ns := nodes()
	for id in GameState.runes:
		if not ns.has(id):
			continue
		var cl: Array = ns[id].get("cls", [])
		if h != null and not cl.is_empty() and not cl.has(h.cls()):
			continue
		var s := str(ns[id]["stat"])
		out[s] = float(out.get(s, 0.0)) + float(ns[id]["per"]) * int(GameState.runes[id])
	return out


static func total(stat_key: String) -> float:
	return float(totals_for(null).get(stat_key, 0.0))


static func points_spent() -> int:
	var n := 0
	for id in GameState.runes:
		n += int(GameState.runes[id])
	return n


static func any_affordable() -> bool:
	for id in nodes():
		if can_buy(id):
			return true
	return false


## "Mage", "Archer & Assassin", "All heroes" for a rune's reach.
static func reach_text(id: String) -> String:
	var cl := classes(id)
	if cl.is_empty():
		return DataDB.t("rune_all_heroes")
	var names: Array = []
	for c in cl:
		names.append(DataDB.tx(DataDB.class_def(str(c)).get("name", {})))
	return ", ".join(names)
