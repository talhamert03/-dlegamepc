extends RefCounted
var runner


func test_party_clears_first_zone_stages() -> void:
	GameState.new_game()
	for hid in ["lyra", "pip"]:
		GameState.unlock_hero(hid, false)
		GameState.add_to_party(hid)
	BattleSim.quiet = true
	BattleSim.start()
	BattleSim.simulate(240.0)
	runner.check(int(GameState.totals["kills"]) > 30, "kills %d" % int(GameState.totals["kills"]))
	runner.check(BattleSim.stage > 1 or BattleSim.zone_idx > 0, "progressed")
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
