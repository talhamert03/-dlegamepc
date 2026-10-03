extends RefCounted
var runner


func test_xp_curve_matches_gdd() -> void:
	runner.near(F.xp_per_kill(50), 538, 0.5, "xp/kill L50")
	runner.check(F.kills_to_level(50) == 490, "kills L50")
	# GDD base 263620 at L50, stretched by the late-game factor (1 + 40 * 0.09)
	runner.near(F.xp_required(50), 263620 * 4.6, 1, "xp req L50")
	runner.near(F.xp_required(1), 490, 1, "xp req L1")


func test_xp_level_penalty() -> void:
	runner.near(F.xp_level_factor(20, 20), 1.0, 0.001)
	runner.near(F.xp_level_factor(20, 15), 0.9, 0.001, "5 below")
	runner.near(F.xp_level_factor(20, 23), 1.05, 0.001, "3 above")
	runner.check(F.xp_level_factor(50, 1) >= 0.1, "min penalty")


func test_defense_reduction_reference() -> void:
	# GDD 8.2: Lv 50 attacker vs DEF 276 -> 44.1%
	var src := Combatant.new()
	src.level = 50
	src.stats = {"power": 1000.0, "crit_chance": 0.0}
	var tgt := Combatant.new()
	tgt.side = Combatant.Side.ENEMY
	tgt.stats = {"def": 276.0}
	tgt.max_hp = 1e9
	tgt.hp = 1e9
	BattleSim.rng.seed = 1
	var total := 0.0
	for i in 200:
		total += float(BattleSim.calc_damage(src, tgt, 1.0, "physical", false)["amount"])
	runner.near(total / 200.0, 1000.0 * (1.0 - 276.0 / 626.0), 8.0, "avg dmg")


func test_enemy_scaling_monotonic() -> void:
	var d := {"hp": 1.0, "atk": 1.0}
	var prev := 0.0
	for lv in [1, 10, 20, 40, 60, 80, 100]:
		var s := F.enemy_stats(d, lv, "normal", 0)
		runner.check(float(s["hp"]) > prev, "hp grows at %d" % lv)
		prev = float(s["hp"])
	var b := F.enemy_stats(d, 40, "boss", 0)
	var n := F.enemy_stats(d, 40, "normal", 0)
	runner.near(float(b["hp"]) / float(n["hp"]), float(DataDB.bal("enemy.type_hp.boss", 25.0)), 0.5, "boss mult")


func test_monster_level_difficulty() -> void:
	var z: Dictionary = DataDB.zones[0]
	runner.check(F.monster_level(z, 1, 0) == 1)
	runner.check(F.monster_level(z, 10, 0) == 2)
	runner.check(F.monster_level(z, 1, 1) >= 50, "nightmare offset")
	runner.check(F.monster_level(z, 1, 2) >= 75, "hell offset")


func test_window_region_is_never_a_plain_rectangle() -> void:
	var WM = load("res://scripts/core/window_manager.gd")
	var strip: Array[Rect2i] = [Rect2i(100, 500, 880, 144)]
	var poly: PackedVector2Array = WM.union_outline(WM._notched(strip))
	runner.check(poly.size() > 5, "single strip region has a notch (%d points)" % poly.size())
	runner.check(Geometry2D.is_point_in_polygon(Vector2(500.5, 560.5), poly), "strip interior still inside")
	runner.check(not Geometry2D.is_point_in_polygon(Vector2(100.5, 500.5), poly), "corner pixel cut out")
	var two: Array[Rect2i] = [Rect2i(100, 500, 880, 144), Rect2i(300, 100, 400, 396)]
	var poly2: PackedVector2Array = WM.union_outline(WM._notched(two))
	runner.check(Geometry2D.is_point_in_polygon(Vector2(500.5, 300.5), poly2) and Geometry2D.is_point_in_polygon(Vector2(900.5, 600.5), poly2), "strip and panel both inside")
