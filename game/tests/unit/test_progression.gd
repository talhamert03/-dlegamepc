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


func test_leadership_runes() -> void:
	GameState.new_game()
	GameState.add_gold(1000000)
	GameState.unlock_hero("nova", false)
	var before_k := float(GameState.hero_stats("kael").get("spell_pct", 0.0))
	var before_n := float(GameState.hero_stats("nova").get("spell_pct", 0.0))
	runner.check(not Runes.can_buy("academy1"), "academy1 locked before the core")
	runner.check(Runes.buy("core"), "core bought")
	runner.check(Runes.buy("academy1"), "academy1 bought after the core")
	runner.check(float(GameState.hero_stats("nova").get("spell_pct", 0.0)) > before_n, "caster rune reaches the mage")
	runner.check(is_equal_approx(float(GameState.hero_stats("kael").get("spell_pct", 0.0)), before_k), "caster rune skips the knight")
	GameState.save_game(9)
	GameState.reset_state()
	GameState.load_game(9)
	runner.check(Runes.rank("academy1") == 1, "rune rank restored")


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


func test_shop_purchases() -> void:
	GameState.new_game()
	var was_loaded: bool = GameState.loaded
	GameState.loaded = false   # keep the test from writing the player's save
	var box := {}
	Shop.buy("chest_gold_4", func(r): box["r"] = r)
	var got: Dictionary = box["r"]
	runner.check(got.get("chest", "") == "gold" and Chests.count() == 4, "gold chest pack bought")
	var before := GameState.heroes.size()
	Shop.buy("hero_random", func(r): box["r"] = r)
	got = box["r"]
	var hid := str(got.get("hero", ""))
	runner.check(hid != "" and GameState.heroes.has(hid) and GameState.heroes.size() == before + 1, "random hero granted")
	var order: String = GameState.purchases.keys()[GameState.purchases.size() - 1]
	runner.check(Shop.grant(Shop.product("hero_random"), order).is_empty(), "an order is granted only once")
	before = GameState.heroes.size()
	Shop.buy("starter", func(r): box["r"] = r)
	runner.check(GameState.heroes.size() == before + 2 and Chests.count() == 9, "starter pack: 2 heroes, 5 chests")
	runner.check(Shop.block_reason(Shop.product("starter")) != "", "starter pack is one time")
	runner.check(float(Shop.offline_bonus()["mult"]) == 1.0, "no offline boost before buying")
	Shop.buy("offline_boost", func(r): box["r"] = r)
	runner.check(float(Shop.offline_bonus()["mult"]) == 2.0, "hourglass doubles offline gains")
	GameState.loaded = was_loaded


func test_bag_grid_move() -> void:
	GameState.new_game()
	for i in 3:
		GameState.bag.append(LootSystem.generate(GameState.rng, 5, "magic", "knight"))
	var uid := str(GameState.bag[0]["uid"])
	GameState.move_in_bag(uid, 10)
	var grid := GameState.bag_layout()
	runner.check(grid[10] != null and str(grid[10]["uid"]) == uid and grid[0] == null, "item moved to an empty cell")
	var other := str(GameState.bag[1]["uid"])
	var at := int(GameState.bag[1]["bpos"])
	GameState.move_in_bag(other, 10)
	grid = GameState.bag_layout()
	runner.check(str(grid[10]["uid"]) == other and str(grid[at]["uid"]) == uid, "items swap cells")


func test_luck_safety() -> void:
	GameState.new_game()
	var was_loaded: bool = GameState.loaded
	GameState.loaded = false
	# enhance pity: certain after the pity count of failures
	var it := LootSystem.generate(GameState.rng, 20, "rare", "knight")
	it["enhance"] = 14
	it["enh_fail"] = int(DataDB.bal("enhance_pity", 6))
	runner.check(is_equal_approx(float(Blacksmith.enhance_info(it)["chance"]), 1.0), "enhance pity reaches 100%")
	# combine odds rise with pity and what is shown is what is rolled
	GameState.blacksmith["pity"] = 0
	var c0 := Blacksmith.combine_chance("legendary")
	GameState.blacksmith["pity"] = 5
	runner.check(Blacksmith.combine_chance("legendary") > c0, "combine odds rise after failures")
	# a successful combine never returns a lower item level than the best input
	GameState.blacksmith["pity"] = 99
	GameState.blacksmith["level"] = 50
	var uids: Array = []
	for i in 9:
		var x := LootSystem.generate(GameState.rng, 30 + i, "magic", "knight")
		GameState.bag.append(x)
		uids.append(x["uid"])
	var res := Blacksmith.combine(uids, "knight")
	runner.check(res.get("success", false) and int(res["item"].get("ilvl", 0)) >= 38, "combine keeps the best input level")
	# bad luck protection turns a long dry streak into an epic
	GameState.progress["dry_epic"] = 500
	runner.check(ItemUtil.rarity_rank(LootSystem._bad_luck("common")) >= ItemUtil.rarity_rank("epic"), "dry streak gives an epic")
	GameState.loaded = was_loaded


func test_one_shot_cap() -> void:
	GameState.new_game()
	var src := Combatant.new()
	src.side = Combatant.Side.ENEMY
	src.etype = "normal"
	src.level = 50
	src.stats = {"power": 1e7, "crit_chance": 0.0}
	var tgt := Combatant.new()
	tgt.side = Combatant.Side.HERO
	tgt.max_hp = 1000.0
	tgt.hp = 1000.0
	tgt.stats = {"def": 0.0}
	var dmg := float(BattleSim.calc_damage(src, tgt, 1.0, "physical", false)["amount"])
	runner.check(dmg <= 1000.0 * 0.45, "a normal enemy can't one-shot (%d)" % int(dmg))


func test_store_extras() -> void:
	GameState.new_game()
	var was_loaded: bool = GameState.loaded
	GameState.loaded = false
	var box := {}
	runner.check(Shop.daily_ready(), "daily gift ready on a new day")
	Shop.buy("daily_gift", func(r): box["r"] = r)
	runner.check(Chests.count() == 1 and not Shop.daily_ready(), "daily gift taken once")
	var g0 := GameState.gold
	var once := Shop.gold_amount(Shop.product("gold_s"))
	Shop.buy("gold_s", func(r): box["r"] = r)
	runner.check(GameState.gold - g0 == once * 2, "first gold pack pays double")
	runner.check(Shop.supporter_perks().is_empty(), "no supporter perks before buying")
	Shop.buy("supporter", func(r): box["r"] = r)
	runner.check(float(GameState.account_mods().get("gold_find", 0.0)) >= 10.0, "supporter perks active")
	var b0 := GameState.bag_slots
	Shop.buy("bag_expand", func(r): box["r"] = r)
	runner.check(GameState.bag_slots == b0 + 10, "bag expansion adds 10 slots")
	GameState.stash_tabs = 3
	Shop.buy("stash_tab", func(r): box["r"] = r)
	runner.check(GameState.stash_tabs == 4, "stash tab bought")
	runner.check(Shop.products("packs").filter(func(p): return str(p["kind"]) == "bag").is_empty(), "no bag items left in the store")
	GameState.loaded = was_loaded


func test_tavern_prices() -> void:
	GameState.new_game()
	runner.check(int(Tavern.cost("lyra")["gold"]) == 1000 and int(Tavern.cost("nova")["gold"]) == 20000, "starter companions 1k … 20k")
	runner.check(int(Tavern.cost("marcus")["gold"]) >= 70000, "other plain heroes start at 70k")
	runner.check(int(Tavern.cost("vesper")["gold"]) > int(Tavern.cost("marcus")["gold"]), "SR dearer than R")
	runner.check(int(Tavern.cost("aurelia")["gold"]) > int(Tavern.cost("vesper")["gold"]), "SSR dearest")
	var r0 := int(Tavern.cost("marcus")["gold"])
	for hid in ["lyra", "pip", "leon", "elowen", "rook", "vex"]:
		GameState.unlock_hero(hid, false)
	runner.check(int(Tavern.cost("marcus")["gold"]) > r0, "price grows past a full party")
	runner.check(int(Tavern.cost("lyra")["gold"]) == 1000, "starter price stays fixed")


func test_steam_cloud_newer_wins() -> void:
	SteamService.fake_cloud = {}
	GameState.new_game()
	GameState.gold = 111
	GameState.save_game(0, true)
	runner.check(SteamService.fake_cloud.has("slot_0.json"), "save mirrored to the cloud")
	# another PC played later: the cloud copy is newer and richer
	var w: Dictionary = JSON.parse_string(str(SteamService.fake_cloud["slot_0.json"]))
	var d: Dictionary = JSON.parse_string(str(w["data"]))
	d["gold"] = 999
	d["saved_at"] = int(d["saved_at"]) + 600
	var body := JSON.stringify(d)
	SteamService.fake_cloud["slot_0.json"] = JSON.stringify({"version": w["version"], "checksum": body.sha256_text(), "data": body})
	runner.check(GameState.load_game(0) and GameState.gold == 999, "newer cloud save is loaded")
	runner.check(FileAccess.file_exists(GameState.save_path(0) + ".before_cloud"), "local save kept as a backup")
	# a stale cloud copy never overwrites a newer local save
	GameState.gold = 1234
	GameState.save_game(0)
	d["gold"] = 5
	d["saved_at"] = 1000
	body = JSON.stringify(d)
	SteamService.fake_cloud["slot_0.json"] = JSON.stringify({"version": w["version"], "checksum": body.sha256_text(), "data": body})
	runner.check(GameState.load_game(0) and GameState.gold == 1234, "older cloud save ignored")
	SteamService.fake_cloud = null


func test_class_family_items() -> void:
	var missing: Array = []
	var wrong_family := 0
	for cls in DataDB.classes:
		var fam := str(DataDB.classes[cls].get("armor", ""))
		for i in 300:
			var it := LootSystem.generate(GameState.rng, 34, ["rare", "epic", "legendary", "set"][i % 4], cls)
			if SpriteLib.item_icon(it) == null:
				var key := "%s/%s" % [it.get("btype"), it.get("weight", "")]
				if not missing.has(key):
					missing.append(key)
			if it.get("cat", "") == "armor" and str(it.get("weight", "")) != fam and it.get("set", "") == "":
				wrong_family += 1
	runner.check(missing.is_empty(), "every class item has an icon " + str(missing))
	runner.check(wrong_family < 40, "class drops are mostly the class family's armour (%d off)" % wrong_family)
	var h := HeroState.new()
	h.id = "pip"
	h.level = 50
	var holy := LootSystem.generate(GameState.rng, 20, "rare", "", {"cat": "armor", "btype": "chest", "slot": "chest", "weight": "holy"})
	var plate := LootSystem.generate(GameState.rng, 20, "rare", "", {"cat": "armor", "btype": "chest", "slot": "chest", "weight": "heavy"})
	runner.check(ItemUtil.can_equip(h, holy) and not ItemUtil.can_equip(h, plate), "a cleric wears holy vestments, not plate")


func test_steam_achievement_ids() -> void:
	var seen := {}
	var bad: Array = []
	var re := RegEx.new()
	re.compile("^[A-Z0-9_]+$")
	for a in DataDB.achievements:
		var id := str(a.get("id", ""))
		if re.search(id) == null or seen.has(id) or id.length() > 64:
			bad.append(id)
		seen[id] = true
		if DataDB.tx(a.get("name", {})) == "" or str(a.get("name", {}).get("en", "")) == "":
			bad.append(id + " (name)")
	runner.check(bad.is_empty(), "achievement ids are valid Steam API names " + str(bad))


func test_data_files_parse() -> void:
	var bad: Array = []
	for f in DirAccess.get_files_at("res://data"):
		if not f.ends_with(".json"):
			continue
		var j := JSON.new()
		if j.parse(FileAccess.get_file_as_string("res://data/" + f)) != OK:
			bad.append("%s:%d" % [f, j.get_error_line()])
	runner.check(bad.is_empty(), "every data/*.json parses " + str(bad))


## The patch notes, project.godot and the Windows exe properties must name the same version (they had drifted to
## 0.2.7 / 0.2.0 / 0.1.0 once).
func test_version_stamps_agree() -> void:
	var notes := str(DataDB.patch_notes.get("current", ""))
	var proj := str(ProjectSettings.get_setting("application/config/version", ""))
	var cfg := ConfigFile.new()
	var exe := ""
	if cfg.load("res://export_presets.cfg") == OK:
		for sec in cfg.get_sections():
			if sec.ends_with(".options") and cfg.has_section_key(sec, "application/file_version"):
				exe = str(cfg.get_value(sec, "application/file_version"))
	runner.check(notes != "" and proj == notes, "project.godot version %s == patch notes %s" % [proj, notes])
	runner.check(exe == notes + ".0", "Windows exe version %s == patch notes %s.0" % [exe, notes])


func test_daily_quests_have_text() -> void:
	var bad: Array = []
	for q in Quests.DAILY_POOL:
		if DataDB.t("quest_" + str(q["id"]), {"n": 1}).begins_with("quest_"):
			bad.append(q["id"])
	runner.check(bad.is_empty(), "every daily quest has a title " + str(bad))


func test_barks_have_both_languages() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/barks.json"))
	var bad := 0
	for group in ["generic", "classes", "heroes"]:
		var g: Dictionary = d.get(group, {})
		var pools: Array = [g] if group == "generic" else g.values()
		for pool in pools:
			for ev in pool:
				for l in pool[ev]:
					if str(l.get("tr", "")) == "" or str(l.get("en", "")) == "":
						bad += 1
	runner.check(bad == 0, "every bark has tr and en (%d missing)" % bad)


func test_every_hero_has_a_join_line() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/barks.json"))
	var missing: Array = []
	for hid in DataDB.hero_order:
		if d.get("heroes", {}).get(hid, {}).get("join", []).is_empty():
			missing.append(hid)
	runner.check(missing.is_empty(), "join line for every hero " + str(missing))


func test_goal_ribbon_after_level_25() -> void:
	GameState.new_game()
	GameState.heroes["kael"].level = 40
	BattleSim.quiet = true
	BattleSim.start()
	var g := Goals.current()
	runner.check(g != "" and not g.begins_with("goal_"), "a goal is shown past level 25: " + g)
	BattleSim.stop()
	BattleSim.quiet = false
