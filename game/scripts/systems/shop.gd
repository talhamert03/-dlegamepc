class_name Shop
extends RefCounted
## Town store (data/shop.json): chests and gold for gold, and real-money products (gold packs, chest packs,
## heroes, bundles). Real-money products go through SteamService.purchase(): while the Steam payment
## backend is not connected it completes at once ("direct" mode); with Steam it waits for the player's
## approval in the Steam overlay. A finished order is recorded by its order id, so it is granted only once.

const RARITY_ORDER := ["R", "SR", "SSR"]


static func products(tab: String = "") -> Array:
	var out: Array = []
	for p in DataDB.shop.get("products", []):
		if tab == "" or str(p.get("tab", "")) == tab:
			out.append(p)
	return out


static func tabs() -> Array:
	return DataDB.shop.get("tabs", [])


static func product(pid: String) -> Dictionary:
	for p in DataDB.shop.get("products", []):
		if str(p["id"]) == pid:
			return p
	return {}


static func is_real_money(p: Dictionary) -> bool:
	return p.get("price", {}).has("try") or p.get("price", {}).has("usd")


static func _level() -> int:
	return maxi(1, GameState.max_hero_level())


## Gold price of a gold-priced product, scaled to the party's level.
static func gold_price(p: Dictionary) -> int:
	var k := float(p.get("price", {}).get("gold_kills", 0))
	return int(round(F.gold_per_kill(_level()) * k / 10.0) * 10.0)


## Gold a gold pack or bundle grants now (worth `kills` normal kills, never less than `min`).
static func gold_amount(p: Dictionary) -> int:
	var g := F.gold_per_kill(_level()) * float(p.get("kills", 0))
	return int(maxf(float(p.get("min", 0)), round(g / 100.0) * 100.0))


## "50,00 ₺" in Turkish, "$2.49" otherwise. Steam charges in the player's own currency.
static func price_text(p: Dictionary) -> String:
	var pr: Dictionary = p.get("price", {})
	if pr.has("gold_kills"):
		return F.fmt_num(gold_price(p))
	if DataDB.lang == "tr" and pr.has("try"):
		var v := float(pr["try"])
		return ("%.2f" % v).replace(".", ",") + " ₺"
	return "$%.2f" % float(pr.get("usd", 0.0))


static func times_bought(pid: String) -> int:
	var n := 0
	for o in GameState.purchases.values():
		if str(o.get("p", "")) == pid:
			n += 1
	return n


static func unowned(rarity := "") -> Array:
	var out: Array = []
	for hid in Tavern.roster():
		if not GameState.heroes.has(hid) and (rarity == "" or Tavern.rarity(hid) == rarity):
			out.append(hid)
	return out


## Why a product can't be bought right now ("" = it can).
static func block_reason(p: Dictionary, hero_id := "") -> String:
	match str(p.get("kind", "")):
		"chest":
			if Chests.count() + int(p.get("count", 1)) > Chests.MAX_HELD:
				return DataDB.t("shop_chests_full")
		"hero_random":
			if unowned().is_empty():
				return DataDB.t("shop_all_heroes")
		"hero_pick":
			if hero_id == "" or GameState.heroes.has(hero_id):
				return DataDB.t("shop_all_heroes")
		"bundle":
			if Chests.count() + 3 > Chests.MAX_HELD:
				return DataDB.t("shop_chests_full")
	if p.get("once", false) and times_bought(str(p["id"])) > 0:
		return DataDB.t("shop_bought")
	if p.has("max_buys") and times_bought(str(p["id"])) >= int(p["max_buys"]):
		return DataDB.t("shop_bought")
	if not is_real_money(p) and GameState.gold < gold_price(p):
		return DataDB.t("not_enough_gold")
	return ""


## Buys a product. on_done(result: Dictionary) is called once the purchase finished ({} = cancelled / failed).
static func buy(pid: String, on_done: Callable, hero_id := "") -> void:
	var p := product(pid)
	if p.is_empty() or block_reason(p, hero_id) != "":
		on_done.call({})
		return
	if not is_real_money(p):
		if not GameState.spend_gold(gold_price(p)):
			on_done.call({})
			return
		on_done.call(grant(p, "g%d_%d" % [TimeService.unix_now(), GameState.rng.randi()], hero_id))
		return
	SteamService.purchase(p, func(ok: bool, order_id: String):
		on_done.call(grant(p, order_id, hero_id) if ok else {}))


## Hands out a finished order once. Returns what was given, for the reveal.
static func grant(p: Dictionary, order_id: String, hero_id := "") -> Dictionary:
	if order_id == "" or GameState.purchases.has(order_id):
		return {}
	var out := {"id": str(p["id"]), "kind": str(p.get("kind", ""))}
	var lv := _level()
	match str(p.get("kind", "")):
		"chest":
			for i in int(p.get("count", 1)):
				Chests.add(str(p["chest"]), lv)
			out["chest"] = str(p["chest"])
			out["count"] = int(p.get("count", 1))
		"gold":
			var g := gold_amount(p)
			GameState.add_gold(g)
			out["gold"] = g
		"hero_random":
			hero_id = _roll_hero(p.get("weights", {}))
			out["hero"] = hero_id
			_give_hero(hero_id)
		"hero_pick":
			out["hero"] = hero_id
			_give_hero(hero_id)
		"bundle":
			var g2 := gold_amount(p)
			GameState.add_gold(g2)
			out["gold"] = g2
			for k in p.get("chests", {}):
				for i in int(p["chests"][k]):
					Chests.add(str(k), lv)
			for m in p.get("mats", {}):
				GameState.add_material(str(m), int(p["mats"][m]))
		"bag":
			GameState.bag_slots += int(p.get("slots", 20))
			EventBus.inventory_changed.emit()
		"mats":
			for m in p.get("mats", {}):
				GameState.add_material(str(m), int(p["mats"][m]))
	GameState.purchases[order_id] = {"p": str(p["id"]), "t": TimeService.unix_now(), "x": hero_id}
	GameState.save_game()
	return out


static func _roll_hero(weights: Dictionary) -> String:
	var pool := unowned()
	var total := 0.0
	for hid in pool:
		total += float(weights.get(Tavern.rarity(hid), 1.0))
	var x := GameState.rng.randf() * total
	for hid in pool:
		x -= float(weights.get(Tavern.rarity(hid), 1.0))
		if x <= 0.0:
			return hid
	return pool[pool.size() - 1] if pool.size() > 0 else ""


static func _give_hero(hid: String) -> void:
	if hid == "" or GameState.heroes.has(hid):
		return
	GameState.unlock_hero(hid)
	GameState.add_to_party(hid)
