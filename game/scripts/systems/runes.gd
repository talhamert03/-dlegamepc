class_name Runes
extends RefCounted
## Rune trees: every class has its own tree (data/runes.json, built by tools/data/gen_runes.py) and every
## hero grows it with gold. A core rune and three themed branches: five runes in a line, a side rune and a
## one-rank capstone at the end. A rune can be bought once a rune it is linked to has a rank. Ranks feed
## only that hero's stats (chest find counts as the party average).


static func tree(h: HeroState) -> Dictionary:
	return DataDB.runes.get(h.cls(), {}) if h else {}


static func nodes(h: HeroState) -> Dictionary:
	return tree(h).get("nodes", {})


static func branches(h: HeroState) -> Array:
	return tree(h).get("branches", [])


static func node(h: HeroState, id: String) -> Dictionary:
	return nodes(h).get(id, {})


static func rank(h: HeroState, id: String) -> int:
	return int(h.runes.get(id, 0)) if h else 0


static func max_rank(h: HeroState, id: String) -> int:
	return int(node(h, id).get("max", 1))


static func pos(h: HeroState, id: String) -> Vector2i:
	var n := node(h, id)
	return Vector2i(int(n.get("x", 0)), int(n.get("y", 0)))


static func stat(h: HeroState, id: String) -> String:
	return str(node(h, id).get("stat", ""))


static func per(h: HeroState, id: String) -> float:
	return float(node(h, id).get("per", 0.0))


static func glyph(h: HeroState, id: String) -> String:
	return str(node(h, id).get("glyph", "rune"))


static func links(h: HeroState, id: String) -> Array:
	return node(h, id).get("links", [])


static func is_cap(h: HeroState, id: String) -> bool:
	return bool(node(h, id).get("cap", false))


static func display_name(h: HeroState, id: String) -> String:
	return DataDB.tx(node(h, id).get("name", {}))


static func branch_of(h: HeroState, id: String) -> Dictionary:
	var key := str(node(h, id).get("br", ""))
	for b in branches(h):
		if b["key"] == key:
			return b
	return {}


static func branch_color(h: HeroState, id: String) -> Color:
	var b := branch_of(h, id)
	return Color(str(b["color"])) if not b.is_empty() else Color("#FFE9B0")


static func ring(h: HeroState, id: String) -> int:
	var p := pos(h, id)
	return absi(p.x) + absi(p.y)


## Gold price of the next rank; capstones cost like three ranks.
static func cost(h: HeroState, id: String) -> int:
	var r := rank(h, id)
	var c := 150.0 * pow(2.2, maxi(0, ring(h, id) - 1)) * pow(1.6, r)
	if is_cap(h, id):
		c *= 4.0
	return int(round(c / 10.0) * 10.0)


## Open = linked from a rune that already has a rank (the core is always open).
static func is_open(h: HeroState, id: String) -> bool:
	if links(h, id).is_empty():
		return true
	for l in links(h, id):
		if rank(h, str(l)) > 0:
			return true
	return false


static func can_buy(h: HeroState, id: String) -> bool:
	return h != null and nodes(h).has(id) and is_open(h, id) and rank(h, id) < max_rank(h, id) and GameState.gold >= cost(h, id)


static func buy(h: HeroState, id: String) -> bool:
	if not can_buy(h, id):
		return false
	GameState.spend_gold(cost(h, id))
	h.runes[id] = rank(h, id) + 1
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
	EventBus.runes_changed.emit()
	return true


## Summed bonuses of every learned rank of one hero, by stat.
static func totals(h: HeroState) -> Dictionary:
	var out := {}
	if h == null:
		return out
	var ns := nodes(h)
	for id in h.runes:
		if ns.has(id):
			var s := str(ns[id]["stat"])
			out[s] = float(out.get(s, 0.0)) + float(ns[id]["per"]) * int(h.runes[id])
	return out


static func points_spent(h: HeroState) -> int:
	var n := 0
	if h:
		for id in h.runes:
			n += int(h.runes[id])
	return n


## Party average of a stat from runes (chest find).
static func party_average(stat_key: String) -> float:
	var ph := GameState.party_heroes()
	if ph.is_empty():
		return 0.0
	var t := 0.0
	for h in ph:
		t += float(totals(h).get(stat_key, 0.0))
	return t / ph.size()


static func any_affordable() -> bool:
	for h in GameState.party_heroes():
		for id in nodes(h):
			if can_buy(h, id):
				return true
	return false
