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
	print("time  | zone            | st | lv  | heroes | kills  | deaths | gold")
	while t < hours * 3600.0:
		BattleSim.simulate(step)
		t += step
		_bot_actions()
		var z := DataDB.zone(BattleSim.zone_idx)
		print("%5.2fh | %-15s | %2d | %3d | %6d | %6d | %6d | %s" % [t / 3600.0, str(z.get("id", "")) + " d" + str(BattleSim.difficulty),
			BattleSim.stage, GameState.max_hero_level(), GameState.heroes.size(), int(GameState.totals["kills"]),
			int(GameState.totals["deaths"]), F.fmt_num(GameState.gold)])
	get_tree().quit()


func _bot_actions() -> void:
	# story joins (normally driven by the tutorial node)
	if not GameState.heroes.has("lyra"):
		GameState.unlock_hero("lyra", false)
		GameState.add_to_party("lyra")
	if not GameState.heroes.has("pip") and BattleSim.zone_idx > 0:
		GameState.unlock_hero("pip", false)
		GameState.add_to_party("pip")
	# recruit from the tavern when affordable
	if GameState.max_hero_level() >= 8:
		Tavern.ensure_offers()
		for hid in GameState.tavern.get("offers", []).duplicate():
			if GameState.party_count() < 5 and Tavern.can_afford(hid):
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
	# equip better items from the bag
	for it in GameState.bag.duplicate():
		GameState.bag.erase(it)
		if not GameState.try_auto_equip(it):
			GameState.add_gold(ItemUtil.sell_price(it))
	# enhance weapons a bit
	for h in GameState.party_heroes():
		for slot in ["weapon", "chest"]:
			var it: Dictionary = h.equipment.get(slot, {})
			if not it.is_empty() and int(it.get("enhance", 0)) < 9:
				var info := Blacksmith.enhance_info(it)
				if not info.is_empty() and GameState.gold > int(info["cost"]) * 3:
					Blacksmith.enhance(it)
	GameState.invalidate_stats()
	BattleSim.refresh_hero_stats()
