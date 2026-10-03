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


## Gold price of a gold-priced product, scaled to the party's level (and growing per earlier buy).
static func gold_price(p: Dictionary) -> int:
	var pr: Dictionary = p.get("price", {})
	var k := float(pr.get("gold_kills", 0)) * pow(float(pr.get("growth", 1.0)), times_bought(str(p.get("id", ""))))
	return int(round(F.gold_per_kill(_level()) * k / 10.0) * 10.0)


static func is_free(p: Dictionary) -> bool:
	return bool(p.get("price", {}).get("free", false))


static func today() -> int:
	return int(TimeService.unix_now() / 86400)


## The daily gift: a chest that fits the party's progress, free once a day.
static func daily_ready() -> bool:
	return int(GameState.progress.get("daily_gift_day", -1)) != today()


static func daily_chest() -> String:
	var lv := _level()
	return "gold" if lv >= 45 else ("iron" if lv >= 12 else "wood")


## Gold packs pay double the first time each one is bought.
static func first_double(p: Dictionary) -> bool:
	return bool(p.get("first_double", false)) and times_bought(str(p["id"])) == 0


## Permanent perks of the Guild Supporter pack ({} when not owned).
static func supporter_perks() -> Dictionary:
	if GameState.purchases.is_empty() or times_bought("supporter") == 0:
		return {}
	var p := product("supporter")
	var perks: Dictionary = p.get("perks", {})
	return perks


## Gold a gold pack or bundle grants now (worth `kills` normal kills, never less than `min`).
static func gold_amount(p: Dictionary) -> int:
	var g := F.gold_per_kill(_level()) * float(p.get("kills", 0))
	return int(maxf(float(p.get("min", 0)), round(g / 100.0) * 100.0))


## "50,00 ₺" in Turkish, "$2.49" otherwise. Steam charges in the player's own currency.
static func price_text(p: Dictionary) -> String:
	var pr: Dictionary = p.get("price", {})
	if pr.has("free"):
		return DataDB.t("shop_free")
	if pr.has("gold_kills"):
		return F.fmt_num(gold_price(p)) + " " + DataDB.t("gold")
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
		"stash":
			if GameState.stash_tabs >= int(DataDB.bal("stash.tabs", 7)):
				return DataDB.t("shop_bought")
		"daily":
			if not daily_ready():
				return DataDB.t("shop_daily_taken")
			if Chests.count() >= Chests.MAX_HELD:
				return DataDB.t("shop_chests_full")
		"bundle":
			var n := 0
			for k in p.get("chests", {}):
				n += int(p["chests"][k])
			if Chests.count() + n > Chests.MAX_HELD:
				return DataDB.t("shop_chests_full")
			if unowned().size() < int(p.get("heroes", 0)):
				return DataDB.t("shop_all_heroes")
	if p.get("once", false) and times_bought(str(p["id"])) > 0:
		return DataDB.t("shop_bought")
	if p.has("max_buys") and times_bought(str(p["id"])) >= int(p["max_buys"]):
		return DataDB.t("shop_bought")
	if not is_real_money(p) and not is_free(p) and GameState.gold < gold_price(p):
		return DataDB.t("not_enough_gold")
	return ""


## Buys a product. on_done(result: Dictionary) is called once the purchase finished ({} = cancelled / failed).
static func buy(pid: String, on_done: Callable, hero_id := "") -> void:
	var p := product(pid)
	if p.is_empty() or block_reason(p, hero_id) != "":
		on_done.call({})
		return
	if not is_real_money(p):
		if not is_free(p) and not GameState.spend_gold(gold_price(p)):
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
		"daily":
			GameState.progress["daily_gift_day"] = today()
			Chests.add(daily_chest(), lv)
			out["kind"] = "chest"
			out["chest"] = daily_chest()
			out["count"] = 1
		"supporter":
			GameState.bag_slots += int(p.get("slots", 20))
			EventBus.inventory_changed.emit()
			GameState.invalidate_stats()
		"gold":
			var g := gold_amount(p) * (2 if first_double(p) else 1)
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
			var g2 := int(p["gold"]) if p.has("gold") else gold_amount(p)
			GameState.add_gold(g2)
			out["gold"] = g2
			var got: Array = []
			for i in int(p.get("heroes", 0)):
				var h := _roll_hero(p.get("weights", {"R": 70, "SR": 25, "SSR": 5}))
				_give_hero(h)
				if h != "":
					got.append(h)
			out["heroes"] = got
			if got.size() > 0:
				out["hero"] = got[0]
			for k in p.get("chests", {}):
				for i in int(p["chests"][k]):
					Chests.add(str(k), lv)
			for m in p.get("mats", {}):
				GameState.add_material(str(m), int(p["mats"][m]))
		"offline":
			pass   # permanent: read by offline_bonus() from the purchase record
		"stash":
			GameState.stash_tabs = mini(int(DataDB.bal("stash.tabs", 7)), GameState.stash_tabs + 1)
			EventBus.inventory_changed.emit()
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


## Permanent offline bonus from the store ({"hours", "eff"} — eff as a fraction).
static func offline_bonus() -> Dictionary:
	var p := product("offline_boost")
	if p.is_empty() or times_bought("offline_boost") == 0:
		return {"hours": 0.0, "eff": 0.0}
	return {"hours": float(p.get("hours", 0)), "eff": float(p.get("eff", 0.0))}
