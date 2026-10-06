extends RefCounted
var runner


func test_rarity_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := {}
	var n := 20000
	for i in n:
		var r := LootSystem.roll_rarity(rng, 0.0, 0)
		counts[r] = int(counts.get(r, 0)) + 1
	var w: Dictionary = DataDB.bal("loot.rarity_weights")
	var total := 0.0
	for k in w:
		if k != "mythic":
			total += float(w[k])
	for k in ["common", "magic", "rare"]:
		var exp: float = float(w[k]) / total
		var got: float = float(counts.get(k, 0)) / n
		runner.check(abs(got - exp) < 0.05 * max(exp, 0.02) + 0.01, "%s %.3f vs %.3f" % [k, got, exp])
	runner.check(not counts.has("mythic"), "no mythic on normal")


func test_generated_items_valid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 400:
		var r: String = ItemUtil.RARITY_ORDER[i % ItemUtil.RARITY_ORDER.size()]
		var cls: String = DataDB.classes.keys()[i % DataDB.classes.size()]
		var it := LootSystem.generate(rng, 1 + (i % 90), r, cls)
		runner.check(it.has("uid") and it.has("slot") and it.has("rarity"), "fields")
		runner.check(ItemUtil.display_name(it) != "", "name")
		var counts: Array = DataDB.bal("items.affix_count")[it["rarity"]]
		runner.check(it["affixes"].size() <= int(counts[1]), "affix count")
		var st := ItemUtil.item_stats(it)
		for k in st:
			runner.check(is_finite(float(st[k])), "finite stat " + k)


func test_item_find_increases_rare_rate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var base := 0
	var boosted := 0
	for i in 20000:
		if ItemUtil.rarity_rank(LootSystem.roll_rarity(rng, 0.0, 0)) >= 2:
			base += 1
		if ItemUtil.rarity_rank(LootSystem.roll_rarity(rng, 200.0, 0)) >= 2:
			boosted += 1
	runner.check(boosted > base * 1.5, "item find boosts rares %d vs %d" % [boosted, base])


func test_affix_labels_have_one_percent_sign() -> void:
	var bad: Array = []
	for id in DataDB.items.get("affixes", {}):
		var t := ItemUtil.affix_label(str(id), 10.0)
		if t.count("%") > 1:
			bad.append(t)
	runner.check(bad.is_empty(), "affix labels show a single % " + str(bad))
