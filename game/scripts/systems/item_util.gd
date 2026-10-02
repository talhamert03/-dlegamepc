class_name ItemUtil
extends RefCounted
## Helpers for item dictionaries.
## Item fields: uid, cat (weapon|offhand|armor|acc), btype, slot, weight, tier, ilvl, rarity,
## base {atk, aps, def, hp}, implicit {stat: v}, affixes [{id, v}], enhance, locked, leg, set, mythic

const RARITY_ORDER := ["common", "magic", "rare", "epic", "legendary", "set", "mythic"]
const WEIGHT_MULT := {"heavy": 1.5, "medium": 1.0, "light": 0.6}


static func rarity_rank(r: String) -> int:
	return RARITY_ORDER.find(r)


static func rarity_color(r: String) -> Color:
	return Color(str(DataDB.items.get("rarity_colors", {}).get(r, "#FFFFFF")))


static func rarity_name(r: String) -> String:
	return DataDB.tx(DataDB.items.get("rarity_names", {}).get(r, {}))


static func base_names(item: Dictionary) -> Dictionary:
	var cat: String = item.get("cat", "")
	var bt: String = item.get("btype", "")
	match cat:
		"weapon":
			return DataDB.items["weapons"].get(bt, {}).get("names", {})
		"offhand":
			return DataDB.items["offhands"].get(bt, {}).get("names", {})
		"armor":
			return DataDB.items["armor"].get(bt, {}).get("names", {}).get(item.get("weight", "medium"), {})
		"acc":
			return DataDB.items["accessories"].get(bt, {}).get("names", {})
	return {}


static func display_name(item: Dictionary) -> String:
	if item.get("leg", "") != "":
		for l in DataDB.items.get("legendaries", []):
			if l["id"] == item["leg"]:
				return DataDB.tx(l["name"])
	var names: Dictionary = base_names(item)
	var arr: Array = names.get(DataDB.lang, names.get("en", []))
	var t := int(item.get("tier", 0))
	var n: String = str(arr[clamp(t, 0, arr.size() - 1)]) if arr.size() > 0 else str(item.get("btype", "?"))
	if item.get("set", "") != "":
		var sd: Dictionary = DataDB.items.get("sets", {}).get(item["set"], {})
		n = DataDB.tx(sd.get("name", {})) + " " + n
	if int(item.get("enhance", 0)) > 0:
		n = "+%d %s" % [int(item["enhance"]), n]
	return n


static func slot_group(slot: String) -> String:
	if slot == "ring1" or slot == "ring2":
		return "ring"
	return slot


## Equipment slot candidates for an item ("ring" -> ring1/ring2).
static func equip_slots(item: Dictionary) -> Array:
	var s: String = item.get("slot", "")
	if s == "ring":
		return ["ring1", "ring2"]
	return [s]


static func req_level(item: Dictionary) -> int:
	return max(1, int(item.get("ilvl", 1)) - 3)


static func can_equip(hero: HeroState, item: Dictionary) -> bool:
	return equip_problem(hero, item) == ""


static func equip_problem(hero: HeroState, item: Dictionary) -> String:
	if hero.level < req_level(item):
		return DataDB.t("req_level", {"lv": req_level(item)})
	var cd: Dictionary = hero.class_def()
	match item.get("cat", ""):
		"weapon":
			if not cd.get("weapons", []).has(item["btype"]):
				return DataDB.t("wrong_class")
		"offhand":
			var bt: String = item["btype"]
			if bt == "dagger_off":
				bt = "dagger"
			if not cd.get("offhand", []).has(bt):
				return DataDB.t("wrong_class")
			# two-handed weapon blocks offhand (except quiver/orb style offhands for 2h classes)
			var w: Dictionary = hero.equipment.get("weapon", {})
			if not w.is_empty() and int(DataDB.items["weapons"].get(w.get("btype", ""), {}).get("hand", 1)) == 2 \
					and not ["quiver", "orb"].has(item["btype"]):
				return DataDB.t("two_handed")
		"armor":
			var allowed := {"heavy": ["heavy", "medium"], "medium": ["medium", "light"], "light": ["light"]}
			if not allowed.get(cd.get("armor", "medium"), []).has(item.get("weight", "medium")):
				return DataDB.t("wrong_armor")
	return ""


## Total stat contributions of one item (incl. enhancement).
static func item_stats(item: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var enh := int(item.get("enhance", 0))
	var eb: Array = DataDB.bal("enhance_bonus", [0])
	var emult: float = 1.0 + float(eb[clamp(enh, 0, eb.size() - 1)]) / 100.0
	var base: Dictionary = item.get("base", {})
	if base.has("atk"):
		_add(out, "weapon_atk", float(base["atk"]) * emult)
	if base.has("def"):
		_add(out, "def_flat", float(base["def"]) * emult)
	if base.has("hp"):
		_add(out, "hp_flat", float(base["hp"]) * emult)
	for k in item.get("implicit", {}):
		_add(out, k, float(item["implicit"][k]))
	for a in item.get("affixes", []):
		_add(out, str(a["id"]), float(a["v"]))
	if item.get("leg", "") != "":
		for l in DataDB.items.get("legendaries", []):
			if l["id"] == item["leg"]:
				for k in l.get("stats", {}):
					_add(out, k, float(l["stats"][k]))
	if item.get("mythic", false):
		_add(out, "added_dmg", 20.0)
		_add(out, "hp_pct", 10.0)
	return out


static func _add(d: Dictionary, k: String, v: float) -> void:
	d[k] = float(d.get(k, 0.0)) + v


static func affix_label(id: String, v: float) -> String:
	var ad: Dictionary = DataDB.items.get("affixes", {}).get(id, {})
	var nm := DataDB.tx(ad.get("name", {})) if not ad.is_empty() else StatNames.label(id)
	if ad.has("flat") or ["str", "dex", "int", "vit", "luk", "all_stats"].has(id) or StatNames.is_flat(id):
		return "+%s %s" % [F.fmt_num(v), nm]
	return "+%s%% %s" % [_pct(v), nm]


static func _pct(v: float) -> String:
	if abs(v - round(v)) < 0.05:
		return str(int(round(v)))
	return "%.1f" % v


static func sell_price(item: Dictionary) -> int:
	var m: float = float(DataDB.bal("sell_mult", {}).get(item.get("rarity", "common"), 1))
	return int(max(1.0, round((5.0 + float(item.get("ilvl", 1)) * 1.5) * m * (1.0 + 0.1 * int(item.get("enhance", 0))))))


## Simple class-weighted power score used for auto-equip & comparison arrows.
static func power_score(item: Dictionary, cls: String) -> float:
	if item.is_empty():
		return 0.0
	var st := item_stats(item)
	var cd: Dictionary = DataDB.class_def(cls)
	var w: Dictionary = cd.get("item_weights", {})
	var main: String = cd.get("primary", "str")
	var lv := float(item.get("ilvl", 1))
	var sc: float = F.flat_scale(int(lv))
	var score := 0.0
	score += float(st.get("weapon_atk", 0.0)) / max(1.0, sc) * 6.0
	score += float(st.get("def_flat", 0.0)) / max(1.0, F.armor_scale(int(lv))) * 2.0
	score += float(st.get("hp_flat", 0.0)) / max(1.0, sc) * 0.4
	for k in st:
		if ["weapon_atk", "def_flat", "hp_flat"].has(k):
			continue
		var weight: float = float(w.get(k, 0.25))
		if k == main:
			weight = 1.0
		var v: float = float(st[k])
		if k == "attack_flat" or k == "spell_flat":
			v = v / max(1.0, sc) * 4.0
		score += v * weight
	score *= 1.0 + rarity_rank(item.get("rarity", "common")) * 0.05
	return score


static func material_name(mid: String) -> String:
	return DataDB.tx(DataDB.items.get("materials", {}).get(mid, {}).get("name", {}))
