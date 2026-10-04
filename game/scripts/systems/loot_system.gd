class_name LootSystem
extends RefCounted
## Item generation: rarity rolls, base selection, affix rolls, legendaries, sets.

const CAT_WEIGHTS := {"weapon": 24, "offhand": 8, "helm": 10, "chest": 10, "gloves": 9, "boots": 9, "belt": 7, "cape": 6,
	"amulet": 6, "ring": 9, "charm": 2}


static func roll_rarity(rng: RandomNumberGenerator, item_find: float, difficulty: int, min_rarity: String = "common", legendary_find: float = 0.0) -> String:
	var weights: Dictionary = DataDB.bal("loot.rarity_weights", {})
	var ifw: Dictionary = DataDB.bal("loot.if_weight", {})
	var min_rank := ItemUtil.rarity_rank(min_rarity)
	var total := 0.0
	var table: Array = []
	for r in ItemUtil.RARITY_ORDER:
		if ItemUtil.rarity_rank(r) < min_rank:
			continue
		if r == "mythic" and difficulty < 2:
			continue
		var w: float = float(weights.get(r, 0.0)) * (1.0 + item_find / 100.0 * float(ifw.get(r, 0.0)))
		if r == "legendary" or r == "set":
			w *= 1.0 + legendary_find / 100.0
		total += w
		table.append([r, w])
	var x := rng.randf() * total
	for e in table:
		x -= e[1]
		if x <= 0.0:
			return e[0]
	return table[-1][0] if table.size() > 0 else "common"


## Pick a base for a slot category, optionally biased to a class.
static func pick_base(rng: RandomNumberGenerator, cls: String, rarity: String) -> Dictionary:
	var cats: Array = []
	var total := 0.0
	for c in CAT_WEIGHTS:
		if c == "charm" and ItemUtil.rarity_rank(rarity) < ItemUtil.rarity_rank("epic"):
			continue
		cats.append([c, float(CAT_WEIGHTS[c])])
		total += float(CAT_WEIGHTS[c])
	var x := rng.randf() * total
	var cat: String = "weapon"
	for e in cats:
		x -= e[1]
		if x <= 0.0:
			cat = e[0]
			break
	var cd: Dictionary = DataDB.class_def(cls) if cls != "" else {}
	match cat:
		"weapon":
			var types: Array = cd.get("weapons", []) if cls != "" else DataDB.items["weapons"].keys()
			types = types.filter(func(t): return DataDB.items["weapons"].has(t))
			if types.is_empty():
				types = DataDB.items["weapons"].keys()
			return {"cat": "weapon", "btype": types[rng.randi() % types.size()], "slot": "weapon"}
		"offhand":
			var offs: Array = []
			if cls != "":
				for o in cd.get("offhand", []):
					offs.append("dagger_off" if o == "dagger" else o)
			if offs.is_empty():
				if cls != "":
					var wt: Array = cd.get("weapons", ["sword"])
					return {"cat": "weapon", "btype": wt[rng.randi() % wt.size()], "slot": "weapon"}
				offs = DataDB.items["offhands"].keys()
			return {"cat": "offhand", "btype": offs[rng.randi() % offs.size()], "slot": "offhand"}
		"helm", "chest", "gloves", "boots":
			return {"cat": "armor", "btype": cat, "slot": cat, "weight": _family_weight(rng, cls)}
		_:
			var base := {"cat": "acc", "btype": cat, "slot": cat}
			if DataDB.items["accessories"].get(cat, {}).get("family", false):
				base["weight"] = _family_weight(rng, cls)
			return base


## The armour family of a class, or a random one when the drop is not aimed at a class.
static func _family_weight(rng: RandomNumberGenerator, cls: String) -> String:
	if cls != "":
		return str(DataDB.class_def(cls).get("armor", "medium"))
	return ItemUtil.FAMILY_WEIGHTS[rng.randi() % ItemUtil.FAMILY_WEIGHTS.size()]


static func generate(rng: RandomNumberGenerator, ilvl: int, rarity: String, cls: String = "", forced: Dictionary = {}) -> Dictionary:
	ilvl = clamp(ilvl, 1, 120)
	var base: Dictionary = forced if not forced.is_empty() else pick_base(rng, cls, rarity)
	var item: Dictionary = base.duplicate()
	item["uid"] = GameState.new_uid()
	item["ilvl"] = ilvl
	item["rarity"] = rarity
	item["tier"] = F.tier_for_level(ilvl)
	item["enhance"] = 0
	item["locked"] = false
	item["affixes"] = []
	item["implicit"] = {}
	item["base"] = {}
	item["leg"] = ""
	item["set"] = ""
	# legendary / set picks may change base
	if rarity == "legendary" or rarity == "mythic":
		var leg := _pick_legendary(rng, ilvl, cls)
		if leg.is_empty():
			rarity = "epic"
			item["rarity"] = "epic"
		else:
			item = _apply_leg_base(item, leg, cls, rng)
			item["leg"] = leg["id"]
			if rarity == "mythic":
				item["mythic"] = true
	elif rarity == "set":
		var sp := _pick_set_piece(rng, cls)
		if sp.is_empty():
			rarity = "epic"
			item["rarity"] = "epic"
		else:
			item.merge(sp, true)
	_roll_base(item, rng)
	var counts: Array = DataDB.bal("items.affix_count", {}).get(item["rarity"], [0, 0])
	var n := rng.randi_range(int(counts[0]), int(counts[1]))
	_roll_affixes(item, n, rng)
	return item


static func _pick_legendary(rng: RandomNumberGenerator, ilvl: int, cls: String) -> Dictionary:
	var cands: Array = []
	for l in DataDB.items.get("legendaries", []):
		if int(l.get("min_lv", 1)) > ilvl + 5:
			continue
		if cls != "" and rng.randf() < float(DataDB.bal("loot.class_bias", 0.6)):
			if not _usable_base(l["base"], cls, l.get("weight", "")):
				continue
		cands.append(l)
	if cands.is_empty():
		return {}
	return cands[rng.randi() % cands.size()]


static func _usable_base(bt: String, cls: String, weight: String) -> bool:
	var cd: Dictionary = DataDB.class_def(cls)
	if DataDB.items["weapons"].has(bt):
		return cd.get("weapons", []).has(bt)
	if DataDB.items["offhands"].has(bt):
		return cd.get("offhand", []).has(bt)
	if weight != "":
		return cd.get("armor", "") == weight
	return true


static func _apply_leg_base(item: Dictionary, leg: Dictionary, cls: String, rng: RandomNumberGenerator) -> Dictionary:
	var bt: String = leg["base"]
	item.erase("weight")   # the rolled base may have been armour
	if DataDB.items["weapons"].has(bt):
		item.merge({"cat": "weapon", "btype": bt, "slot": "weapon"}, true)
	elif DataDB.items["offhands"].has(bt):
		item.merge({"cat": "offhand", "btype": bt, "slot": "offhand"}, true)
	elif DataDB.items["armor"].has(bt):
		var w: String = leg.get("weight", "")
		if w == "":
			w = _family_weight(rng, cls)
		item.merge({"cat": "armor", "btype": bt, "slot": bt, "weight": w}, true)
	else:
		item.merge({"cat": "acc", "btype": bt, "slot": bt}, true)
		if DataDB.items["accessories"].get(bt, {}).get("family", false):
			item["weight"] = leg.get("weight", _family_weight(rng, cls))
	return item


static func _pick_set_piece(rng: RandomNumberGenerator, cls: String) -> Dictionary:
	var sets: Dictionary = DataDB.items.get("sets", {})
	var keys: Array = sets.keys()
	if keys.is_empty():
		return {}
	var sid: String = keys[rng.randi() % keys.size()]
	if cls != "" and rng.randf() < float(DataDB.bal("loot.class_bias", 0.6)):
		for k in keys:
			if sets[k].get("class", "") == cls:
				sid = k
				break
	var sd: Dictionary = sets[sid]
	var scls: String = sd.get("class", "knight")
	var piece: String = sd["pieces"][rng.randi() % sd["pieces"].size()]
	var cd: Dictionary = DataDB.class_def(scls)
	var out := {"set": sid}
	match piece:
		"weapon":
			out.merge({"cat": "weapon", "btype": cd["weapons"][0], "slot": "weapon"})
		"offhand":
			var o: String = cd.get("offhand", ["shield"])[0] if cd.get("offhand", []).size() > 0 else "shield"
			out.merge({"cat": "offhand", "btype": "dagger_off" if o == "dagger" else o, "slot": "offhand"})
		"helm", "chest", "gloves", "boots":
			out.merge({"cat": "armor", "btype": piece, "slot": piece, "weight": cd.get("armor", "medium")})
		_:
			out.merge({"cat": "acc", "btype": piece, "slot": piece})
			if DataDB.items["accessories"].get(piece, {}).get("family", false):
				out["weight"] = cd.get("armor", "medium")
	return out


static func _roll_base(item: Dictionary, rng: RandomNumberGenerator) -> void:
	var ilvl := int(item["ilvl"])
	var rp: float = float(DataDB.bal("items.rarity_power", {}).get(item["rarity"], 1.0))
	var tfrac: Array = DataDB.bal("items.tier_frac", [1.0])
	var tf: float = float(tfrac[clamp(int(item["tier"]), 0, tfrac.size() - 1)])
	match item["cat"]:
		"weapon":
			var wd: Dictionary = DataDB.items["weapons"][item["btype"]]
			var growth: float = float(DataDB.bal("ref.weapon_growth", 1.055))
			item["base"] = {"atk": round(float(wd["atk"]) * pow(growth, ilvl) * rp * rng.randf_range(0.9, 1.1) * 10.0) / 10.0, "aps": float(wd["aps"])}
			item["implicit"] = wd.get("implicit", {}).duplicate()
		"offhand":
			var od: Dictionary = DataDB.items["offhands"][item["btype"]]
			if od.has("def"):
				item["base"] = {"def": round(float(od["def"]) * F.armor_scale(ilvl) * rp)}
			for k in od.get("implicit", {}):
				var r: Array = od["implicit"][k]
				item["implicit"][k] = round(lerp(float(r[0]), float(r[1]), tf) * 10.0) / 10.0
		"armor":
			var ad: Dictionary = DataDB.items["armor"][item["btype"]]
			var wm: float = float(ItemUtil.WEIGHT_MULT.get(item.get("weight", "medium"), 1.0))
			item["base"] = {"def": round(float(ad["def"]) * wm * F.armor_scale(ilvl) * rp * rng.randf_range(0.9, 1.1)),
				"hp": round(float(ad.get("hp", 0)) * pow(1.045, ilvl) * rp)}
		"acc":
			var cd: Dictionary = DataDB.items["accessories"].get(item["btype"], {})
			if cd.has("hp"):
				item["base"] = {"hp": round(float(cd["hp"]) * pow(1.045, ilvl) * rp)}
			elif cd.has("def"):
				item["base"] = {"def": round(float(cd["def"]) * F.armor_scale(ilvl) * rp)}


static func _roll_affixes(item: Dictionary, n: int, rng: RandomNumberGenerator) -> void:
	var group: String = ItemUtil.slot_group(item["slot"])
	var pool: Array = []
	var aff: Dictionary = DataDB.items.get("affixes", {})
	for id in aff:
		var slots: Array = aff[id].get("slots", [])
		if slots.has("*") or slots.has(group):
			pool.append(id)
	var have := {}
	for a in item["affixes"]:
		have[a["id"]] = true
	var pre := 0
	var suf := 0
	var tries := 0
	while item["affixes"].size() < n and tries < 60 and pool.size() > 0:
		tries += 1
		var id: String = pool[rng.randi() % pool.size()]
		if have.has(id):
			continue
		var kind: String = aff[id].get("kind", "suffix")
		if kind == "prefix" and pre >= 3:
			continue
		if kind == "suffix" and suf >= 3:
			continue
		have[id] = true
		if kind == "prefix":
			pre += 1
		else:
			suf += 1
		item["affixes"].append({"id": id, "v": roll_affix_value(id, int(item["ilvl"]), rng)})


static func roll_affix_value(id: String, ilvl: int, rng: RandomNumberGenerator) -> float:
	var ad: Dictionary = DataDB.items["affixes"][id]
	if ad.has("flat"):
		var r: Array = ad["flat"]
		var sc: float = F.armor_scale(ilvl) if ad.get("armor", false) else F.flat_scale(ilvl)
		return round(rng.randf_range(float(r[0]), float(r[1])) * sc)
	var rr: Array = ad.get("range", [1, 2])
	var tfrac: Array = DataDB.bal("items.tier_frac", [1.0])
	var tf: float = float(tfrac[F.tier_for_level(ilvl)])
	var v: float = rng.randf_range(float(rr[0]), float(rr[1])) * tf
	if v >= 10.0:
		return round(v)
	return round(v * 10.0) / 10.0


## Rolls drops for a killed enemy. Returns {"items": [...], "materials": {id: n}}.
## Bad-luck protection: a long dry streak turns the next drop into the rarity that has been missing
## (epic after `loot.dry_epic` drops, legendary after `loot.dry_legendary`), so nobody farms forever empty-handed.
static func _bad_luck(r: String) -> String:
	var p: Dictionary = GameState.progress
	var rank := ItemUtil.rarity_rank(r)
	var de := int(p.get("dry_epic", 0)) + 1
	var dl := int(p.get("dry_leg", 0)) + 1
	if rank < ItemUtil.rarity_rank("legendary") and dl >= int(DataDB.bal("loot.dry_legendary", 900)):
		r = "legendary"
	elif rank < ItemUtil.rarity_rank("epic") and de >= int(DataDB.bal("loot.dry_epic", 140)):
		r = "epic"
	rank = ItemUtil.rarity_rank(r)
	p["dry_epic"] = 0 if rank >= ItemUtil.rarity_rank("epic") else de
	p["dry_leg"] = 0 if rank >= ItemUtil.rarity_rank("legendary") else dl
	return r


static func roll_drops(rng: RandomNumberGenerator, level: int, etype: String, item_find: float, difficulty: int, party_classes: Array, legendary_find: float = 0.0) -> Dictionary:
	var out := {"items": [], "materials": {}}
	var chance: float = float(DataDB.bal("loot.drop_chance", {}).get(etype, 0.08))
	if rng.randf() > chance * (1.0 + item_find / 400.0):
		if rng.randf() < float(DataDB.bal("loot.material_chance", 0.05)):
			out["materials"]["iron_scrap"] = 1
		return out
	var count := int(DataDB.bal("loot.drop_count", {}).get(etype, 1))
	for i in count:
		var min_r := "common"
		if i == 0:
			if etype == "elite":
				min_r = "magic"
			elif etype == "boss" or etype == "miniboss":
				min_r = "rare"
			elif etype == "actboss":
				min_r = "epic"
		var r := roll_rarity(rng, item_find, difficulty, min_r, legendary_find)
		r = _bad_luck(r)
		var cls := ""
		if party_classes.size() > 0 and rng.randf() < float(DataDB.bal("loot.class_bias", 0.6)):
			cls = party_classes[rng.randi() % party_classes.size()]
		out["items"].append(generate(rng, level, r, cls))
	if etype == "boss" or etype == "actboss":
		out["materials"]["soul_shard"] = rng.randi_range(1, 3)
		out["materials"]["tavern_seal"] = 1 if etype == "boss" else 3
		if etype == "actboss":
			out["materials"]["guild_badge"] = 2
	return out
