extends RefCounted
var runner


func test_party_clears_first_zone_stages() -> void:
	GameState.new_game()
	for hid in ["lyra", "pip"]:
		GameState.unlock_hero(hid, false)
		GameState.add_to_party(hid)
	BattleSim.quiet = true
	BattleSim.start()
	BattleSim.simulate(420.0)
	runner.check(int(GameState.totals["kills"]) > 30, "kills %d" % int(GameState.totals["kills"]))
	runner.check(BattleSim.stage > 1 or BattleSim.zone_idx > 0, "progressed (stage %d wave %d)" % [BattleSim.stage, BattleSim.wave])
	runner.check(GameState.gold > 0, "gold earned")
	BattleSim.stop()
	BattleSim.quiet = false


func test_offline_progress() -> void:
	GameState.new_game()
	GameState.last_save_unix = TimeService.unix_now() - 3600 * 3
	GameState.rates = {"xp": 200.0, "gold": 100.0, "kills": 20.0}
	var before: float = GameState.heroes["kael"].xp + GameState.heroes["kael"].level * 1000
	var rep := OfflineSim.apply()
	runner.check(int(rep["seconds"]) >= 3 * 3600 - 5, "seconds")
	runner.check(GameState.gold > 0, "offline gold")
	runner.check(GameState.heroes["kael"].level > 1, "offline levels")


func test_offline_clock_tamper() -> void:
	GameState.new_game()
	GameState.last_save_unix = TimeService.unix_now() + 5000
	var rep := OfflineSim.apply()
	runner.check(int(rep["seconds"]) == 0, "no reward when clock moved back")


func test_tower_runs() -> void:
	GameState.new_game()
	for hid in ["lyra", "pip"]:
		GameState.unlock_hero(hid, false)
		GameState.add_to_party(hid)
	for hid in GameState.party:
		if hid != "":
			var need := 0.0
			for l in range(1, 60):
				need += F.xp_required(l)
			GameState.add_hero_xp(GameState.heroes[hid], need)
	runner.check(BattleSim.tower_unlocked(), "tower unlocked at high level")
	BattleSim.quiet = true
	BattleSim.start()
	BattleSim.enter_tower()
	runner.check(BattleSim.mode == "tower", "in tower")
	BattleSim.simulate(120.0)
	runner.check(BattleSim.tower_floor >= 1, "tower floor valid")
	BattleSim.leave_tower()
	runner.check(BattleSim.mode == "zone", "left tower")
	BattleSim.stop()
	BattleSim.quiet = false


func test_boss_fatigue_after_fails() -> void:
	GameState.new_game()
	BattleSim.quiet = true
	BattleSim.start()
	BattleSim.boss_fail_count = 0
	BattleSim._spawn_boss()
	runner.check(is_equal_approx(BattleSim.boss_unit.hp, BattleSim.boss_unit.max_hp), "fresh boss at full HP")
	BattleSim._clear_enemies()
	BattleSim.boss_fail_count = 3
	BattleSim._spawn_boss()
	runner.check(absf(BattleSim.boss_unit.hp / BattleSim.boss_unit.max_hp - 0.91) < 0.001, "3 fails -> 9% weaker")
	BattleSim._clear_enemies()
	BattleSim.boss_fail_count = 50
	BattleSim._spawn_boss()
	runner.check(BattleSim.boss_unit.hp / BattleSim.boss_unit.max_hp > 0.69, "fatigue capped at 30%")
	BattleSim.boss_fail_count = 0
	BattleSim.stop()
	BattleSim.quiet = false


func test_treasure_goblin_runs_or_pays() -> void:
	GameState.new_game()
	BattleSim.quiet = true
	BattleSim.start()
	BattleSim._clear_enemies()
	# it runs off the right edge if nobody catches it
	var g := BattleSim._spawn_enemy("treasure_goblin", 10, "elite", BattleSim.SPAWN_X)
	g.mech_t = 0.0
	g.set_meta("fleeing", true)
	for i in 400:
		BattleSim._treasure_move(g, 0.05, 0.0)
	runner.check(not g.alive, "the goblin escapes")
	# caught: gold and a golden chest
	var g2 := BattleSim._spawn_enemy("treasure_goblin", 10, "elite", BattleSim.SPAWN_X)
	var gold0 := GameState.gold
	var chests0 := GameState.chests.size()
	BattleSim._on_enemy_killed(g2)
	runner.check(GameState.gold - gold0 > int(F.gold_per_kill(10, "elite") * 10), "big gold for the goblin")
	runner.check(GameState.chests.size() > chests0, "a chest for the goblin")
	BattleSim.stop()
	BattleSim.quiet = false
