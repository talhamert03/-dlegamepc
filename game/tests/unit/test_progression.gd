extends RefCounted
var runner


func setup() -> void:
	GameState.new_game()


func test_hero_levels_and_points() -> void:
	var h: HeroState = GameState.heroes["kael"]
	var before_skills := 0
	for k in h.skill_levels:
		before_skills += int(h.skill_levels[k])
	GameState.add_hero_xp(h, F.xp_required(1) + F.xp_required(2) + 1)
	runner.check(h.level == 3, "level 3, got %d" % h.level)
	var after_skills := 0
	for k in h.skill_levels:
		after_skills += int(h.skill_levels[k])
	# points are either banked or auto-spent on skills
	runner.check(h.skill_points + after_skills - before_skills >= 2, "skill points")


func test_stat_calc_sane() -> void:
	for cls in DataDB.classes:
		for hid in DataDB.hero_order:
			if DataDB.hero_def(hid)["class"] == cls:
				var h := HeroState.create(hid)
				h.level = 30
				h.stat_points = 150
				h.auto_allocate()
				var s := StatCalc.compute(h)
				runner.check(float(s["max_hp"]) > 100, "%s hp" % hid)
				runner.check(float(s["power"]) > 20, "%s power" % hid)
				runner.check(float(s["aps"]) > 0.3 and float(s["aps"]) < 3.0, "%s aps" % hid)
				break


func test_skill_learning() -> void:
	var h := HeroState.create("lyra")
	h.skill_points = 3
	runner.check(h.level_skill("archer_keen_eye"), "learn passive")
	runner.check(not h.level_skill("archer_rain"), "tier-1 locked before advancement")
	var s := StatCalc.compute(h)
	runner.check(float(s["crit_chance"]) >= 6.0, "keen eye crit")


func test_save_load_roundtrip() -> void:
	GameState.new_game()
	GameState.add_gold(1234)
	var it := LootSystem.generate(GameState.rng, 10, "rare", "knight")
	GameState.bag.append(it)
	runner.check(GameState.save_game(9), "save ok")
	GameState.reset_state()
	runner.check(GameState.load_game(9), "load ok")
	runner.check(GameState.gold == 1234, "gold restored")
	runner.check(GameState.bag.size() == 1 and GameState.bag[0]["uid"] == it["uid"], "bag restored")
	runner.check(GameState.heroes.has("kael"), "hero restored")


func test_runes_are_personal() -> void:
	GameState.new_game()
	GameState.add_gold(100000)
	var kael: HeroState = GameState.heroes["kael"]
	var before := float(GameState.hero_stats("kael").get("hp_pct", 0.0))
	runner.check(not Runes.can_buy(kael, "d1"), "d1 locked before the core")
	runner.check(Runes.buy(kael, "core"), "core bought")
	runner.check(Runes.buy(kael, "d1"), "d1 bought after the core")
	runner.check(float(GameState.hero_stats("kael").get("hp_pct", 0.0)) > before, "rune raises the hero's stat")
	GameState.save_game(9)
	GameState.reset_state()
	GameState.load_game(9)
	runner.check(Runes.rank(GameState.heroes["kael"], "d1") == 1, "rune rank restored")


func test_corrupt_save_falls_back_to_backup() -> void:
	GameState.new_game()
	GameState.add_gold(50)
	GameState.save_game(8)
	GameState.add_gold(50)
	GameState.save_game(8)
	var f := FileAccess.open(GameState.save_path(8), FileAccess.WRITE)
	f.store_string("{garbage")
	f.close()
	GameState.reset_state()
	runner.check(GameState.load_game(8), "loaded backup")
	runner.check(GameState.gold == 50, "backup gold 50, got %d" % GameState.gold)


func test_pets() -> void:
	GameState.new_game()
	runner.check(GameState.grant_pet("jelly"), "grant pet")
	runner.check(GameState.pets["active"] == "jelly", "first pet auto active")
	GameState.grant_pet("jelly")
	runner.check(GameState.pet_level("jelly") == 2, "duplicate levels pet")
	var m := GameState.account_mods()
	runner.check(float(m.get("gold_find", 0.0)) >= 7.0, "pet bonus applied %s" % str(m.get("gold_find", 0.0)))
	BattleSim.quiet = true
	BattleSim.start()
	var pets_in := BattleSim.heroes.filter(func(u): return u.etype == "pet")
	runner.check(pets_in.size() == 1, "pet unit spawned")
	BattleSim.simulate(60.0)
	runner.check(BattleSim.heroes.filter(func(u): return u.etype == "pet").size() == 1, "pet persists")
	BattleSim.stop()
	BattleSim.quiet = false
	GameState.set_active_pet("")
	runner.check(GameState.pets["active"] == "", "pet dismissed")
