extends Node
## Fast-forward bot playthrough for balance checks:
##   godot --headless res://tests/BalanceBot.tscn -- --hours=6
## Prints a progress line every simulated 15 minutes.

func _ready() -> void:
	await get_tree().process_frame
	var hours := 4.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hours="):
			hours = float(a.substr(8))
	Settings.values["tutorial_done"] = true
	GameState.new_game()
	BattleSim.quiet = true
	EventBus.boss_failed.connect(func(z):
		var b = BattleSim.boss_unit
		var dps := 0.0
		for h in GameState.party_heroes():
			dps += StatCalc.dps_estimate(GameState.hero_stats(h.id))
		if b:
			print("  boss fail %s hp left %.0f%% (max %s) party est dps %s lv %d" % [z, b.hp_frac() * 100, F.fmt_num(b.max_hp), F.fmt_num(dps), b.level]))
	BattleSim.start()
	var t := 0.0
	var step := 900.0
	var fails_prev := 0
	print("time  | zone            | st | lv  | heroes | kills  | deaths | gold | runes | earned | seals")
	while t < hours * 3600.0:
		BattleSim.simulate(step)
		t += step
		_bot_actions()
		var z := DataDB.zone(BattleSim.zone_idx)
		print("%5.2fh | %-15s | %2d | %3d | %6d | %6d | %6d | %s" % [t / 3600.0, str(z.get("id", "")) + " d" + str(BattleSim.difficulty),
			BattleSim.stage, GameState.max_hero_level(), GameState.heroes.size(), int(GameState.totals["kills"]),
			int(GameState.totals["deaths"]), F.fmt_num(GameState.gold) + " | " + str(Runes.points_spent()) + " | " + F.fmt_num(int(GameState.totals.get("gold", 0))) + " | " + str(int(GameState.materials.get("tavern_seal", 0)))])
	get_tree().quit()


func _bot_actions() -> void:
	# the tutorial gives Lyra around minute 8 (Tutorial._check_lyra_gift)
	if not GameState.heroes.has("lyra") and not GameState.flags.get("lyra_gift", false):
		GameState.flags["lyra_gift"] = true
		GameState.unlock_hero("lyra")
		GameState.add_to_party("lyra")
	# recruit the cheapest affordable hero (story heroes first) while the party has room
	var by_price := Tavern.roster()
	by_price.sort_custom(func(a, b): return int(Tavern.cost(a)["gold"]) < int(Tavern.cost(b)["gold"]))
	for hid in by_price:
		if GameState.party_count() < 5 and not GameState.heroes.has(hid) and Tavern.can_afford(hid):
			Tavern.recruit(hid)
	for h in GameState.heroes.values():
		h.auto_allocate()
		h.auto_skills()
		if h.level >= 30 and h.advancement == 0:
			h.advancement = 1
			h.skill_points += 3
		if h.level >= 70 and h.advancement == 1:
			h.advancement = 2
			h.spec = "a"
			h.skill_points += 3
	# like a real player: once the party is full, buy rarer heroes and swap them in for a plain one
	# of the same armour family (keeps healer/ranger/mage/warrior balance)
	if GameState.party_count() >= 5:
		var best := ""
		for hid in Tavern.roster():
			if GameState.heroes.has(hid) or Tavern.rarity(hid) == "R" or not Tavern.can_afford(hid):
				continue
			if best == "" or ["R", "SR", "SSR"].find(Tavern.rarity(hid)) > ["R", "SR", "SSR"].find(Tavern.rarity(best)):
				best = hid
		if best != "":
			var fam := str(DataDB.class_def(str(DataDB.hero_def(best).get("class", ""))).get("armor", ""))
			var out := ""
			for ph in GameState.party_heroes():
				if Tavern.rarity(ph.id) == "R" and str(ph.class_def().get("armor", "")) == fam:
					out = ph.id
					break
			if out != "" and Tavern.recruit(best):
				var j: int = GameState.party.find(best)
				if j >= 0:
					GameState.party[j] = ""
				GameState.set_party_slot(GameState.party.find(out), best)
				print("  recruit %s (%s) for %s at %s" % [best, Tavern.rarity(best), out, F.fmt_num(GameState.gold)])
	# equip better items from the bag
	for it in GameState.bag.duplicate():
		GameState.bag.erase(it)
		if not GameState.try_auto_equip(it):
			GameState.add_gold(ItemUtil.sell_price(it))
	# enhance weapons a bit
	for h in GameState.party_heroes():
		for slot in ["weapon", "chest", "helm", "gloves", "boots", "offhand"]:
			var it: Dictionary = h.equipment.get(slot, {})
			if not it.is_empty() and int(it.get("enhance", 0)) < 12:
				var info := Blacksmith.enhance_info(it)
				if not info.is_empty() and GameState.gold > int(info["cost"]) * 3:
					Blacksmith.enhance(it)
	# a player saving for the next recruit: runes only from gold beyond the cheapest hero in reach
	var save := 0
	if GameState.party_count() < 5:
		save = 1 << 40
		for hid in Tavern.roster():
			if not GameState.heroes.has(hid) and Tavern.level_ok(hid):
				save = mini(save, int(Tavern.cost(hid)["gold"]))
		if save == 1 << 40:
			save = 0
	for k in 200:
		var best := ""
		for rid in Runes.nodes():
			if Runes.can_buy(rid) and (best == "" or Runes.cost(rid) < Runes.cost(best)):
				best = rid
		if best == "" or GameState.gold - save < Runes.cost(best) * 3:
			break
		Runes.buy(best)
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
