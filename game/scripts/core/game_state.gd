extends Node
## Owner of all persistent game data (heroes, party, items, progress) + save/load.

const SAVE_VERSION := 2      # 2 = taskbar-hero rework: older saves are archived and a fresh game starts
const SAVE_DIR := "user://saves/"
const PARTY_SIZE := 5

var rng := RandomNumberGenerator.new()
var heroes: Dictionary = {}           # id -> HeroState
var party: Array = ["", "", "", "", ""]  # index 0 = front-most slot
var gold: int = 0
var materials: Dictionary = {}
var chests: Array = []          # held treasure chests [{k, lv, t}]
var runes: Dictionary = {}      # leadership rune id -> rank (account-wide)
var bag: Array = []
var bag_slots: int = 60
var stash: Array = [[], [], [], [], [], [], []]
var stash_tabs: int = 1
var progress: Dictionary = {}
var totals: Dictionary = {}
var flags: Dictionary = {}
var purchases: Dictionary = {}   # store orders: order_id -> {p: product id, t: unix, x: extra}
var blacksmith: Dictionary = {"level": 1, "xp": 0, "pity": 0}
var tavern: Dictionary = {"offers": [], "refresh_at": 0}
var guild: Dictionary = {}
var codex: Dictionary = {"enemies": {}, "legendaries": {}}
var achievements: Dictionary = {}
var pets: Dictionary = {"owned": {}, "active": ""}
var rates: Dictionary = {"xp": 0.0, "gold": 0.0, "kills": 0.0}
var uid_counter: int = 1
var last_save_unix: int = 0
var created_unix: int = 0
var loaded := false
var _autosave_t := 0.0
var _ach_t := 0.0
var _playtime_acc := 0.0
var _rate_window: Array = []   # [time, xp, gold, kills] samples
var stats_cache: Dictionary = {}  # hero_id -> computed stats (invalidated on change)


func _ready() -> void:
	rng.randomize()
	reset_state()
	EventBus.equipment_changed.connect(func(_h): invalidate_stats())
	EventBus.party_changed.connect(invalidate_stats)


func _process(delta: float) -> void:
	if not loaded:
		return
	_autosave_t += delta
	_playtime_acc += delta
	if _playtime_acc >= 1.0:
		totals["playtime"] = float(totals.get("playtime", 0.0)) + _playtime_acc
		_playtime_acc = 0.0
	_ach_t += delta
	if _ach_t >= 5.0:
		_ach_t = 0.0
		Quests.check_achievements()
		Costumes.check_unlocks()
	if _autosave_t >= 60.0:
		_autosave_t = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if loaded:
			save_game()


func reset_state() -> void:
	heroes.clear()
	party = ["", "", "", "", ""]
	gold = 0
	materials = {}
	chests = []
	runes = {}
	purchases = {}
	bag = []
	bag_slots = int(DataDB.bal("inventory.base_slots", 60))
	stash = [[], [], [], [], [], [], []]
	stash_tabs = 1
	progress = {"difficulty": 0, "zone": 0, "stage": 1, "max_zone": [0, -1, -1], "max_stage": 1, "cleared": {}, "auto": true}
	totals = {"kills": 0, "gold": 0, "items": 0, "legendaries": 0, "mythics": 0, "deaths": 0, "bosses": 0, "playtime": 0.0,
		"offline": 0.0, "combines": 0, "enhances": 0}
	flags = {}
	blacksmith = {"level": 1, "xp": 0, "pity": 0}
	tavern = {"offers": [], "refresh_at": 0}
	guild = {}
	codex = {"enemies": {}, "legendaries": {}}
	achievements = {}
	pets = {"owned": {}, "active": ""}
	uid_counter = 1
	stats_cache.clear()


func new_game() -> void:
	reset_state()
	created_unix = int(Time.get_unix_time_from_system())
	unlock_hero("kael", false)
	party[0] = "kael"
	loaded = true
	flags["new_game"] = true
	save_game()


func new_uid() -> String:
	uid_counter += 1
	return "i%d" % uid_counter


# ------------------------------------------------------------------ heroes / party
func unlock_hero(hid: String, notify := true) -> HeroState:
	if heroes.has(hid):
		return heroes[hid]
	var h := HeroState.create(hid)
	# late joiners start near the party level so they are useful
	var top := max_hero_level()
	if top > 3:
		h.level = max(1, top - 3)
		var bonus_pts := 0
		var bonus_sp := 0
		for lv in range(1, h.level):
			bonus_pts += int(DataDB.bal("points.stat_per_level", 5))
			bonus_sp += int(DataDB.bal("points.skill_per_level", 1))
			if (lv + 1) % int(DataDB.bal("points.stat_bonus_every", 10)) == 0:
				bonus_pts += int(DataDB.bal("points.stat_bonus", 5))
				bonus_sp += int(DataDB.bal("points.skill_bonus", 1))
		h.stat_points = bonus_pts
		h.skill_points = bonus_sp
	heroes[hid] = h
	if notify:
		EventBus.hero_unlocked.emit(hid)
		EventBus.notify.emit(DataDB.t("hero_joined", {"name": h.display_name()}), Color("#7FE07A"))
	return h


func max_hero_level() -> int:
	var m := 1
	for k in heroes:
		m = max(m, int(heroes[k].level))
	return m


func party_heroes() -> Array:
	var out: Array = []
	for hid in party:
		if hid != "" and heroes.has(hid):
			out.append(heroes[hid])
	return out


func party_classes() -> Array:
	var out: Array = []
	for h in party_heroes():
		if not out.has(h.cls()):
			out.append(h.cls())
	return out


func party_count() -> int:
	return party_heroes().size()


func unlocked_party_slots() -> int:
	var n := 1
	if heroes.size() >= 2:
		n = 2
	if heroes.size() >= 3:
		n = 3
	if heroes.size() >= 4:
		n = 4
	if max_hero_level() >= 8 or heroes.size() >= 5:
		n = 5
	return n


func set_party_slot(slot: int, hid: String) -> void:
	if slot < 0 or slot >= PARTY_SIZE:
		return
	var prev: int = party.find(hid)
	if hid != "" and prev >= 0:
		party[prev] = party[slot]
	party[slot] = hid
	EventBus.party_changed.emit()


func add_to_party(hid: String) -> bool:
	if party.has(hid):
		return true
	for i in unlocked_party_slots():
		if party[i] == "":
			party[i] = hid
			EventBus.party_changed.emit()
			return true
	return false


# ------------------------------------------------------------------ stats
func invalidate_stats(_x: Variant = null) -> void:
	stats_cache.clear()


## Party heroes per faction.
func faction_counts() -> Dictionary:
	var counts: Dictionary = {}
	for hid in party:
		if hid != "" and heroes.has(hid):
			var f: String = DataDB.hero_def(hid).get("faction", "")
			counts[f] = int(counts.get(f, 0)) + 1
	return counts


func account_mods() -> Dictionary:
	var out: Dictionary = {}
	# faction bonuses: only heroes fighting in the party count
	var counts: Dictionary = faction_counts()
	for f in DataDB.factions:
		var fd: Dictionary = DataDB.factions[f]
		var c := int(counts.get(f, 0))
		var stat: String = fd.get("bonus_stat", "")
		if stat != "" and c >= 2:
			out[stat] = float(out.get(stat, 0.0)) + float(fd.get("bonus_per2", 0)) * float(c / 2)
		if c >= 4:
			var fb: Dictionary = fd.get("full_bonus", {})
			if fb.has("stat"):
				out[fb["stat"]] = float(out.get(fb["stat"], 0.0)) + float(fb["value"])
	# pets: active pet bonus scales with level, every owned pet adds a small collection bonus
	var pd: Dictionary = DataDB.pets
	var owned: Dictionary = pets.get("owned", {})
	var coll: Dictionary = pd.get("collection_per_pet", {})
	if coll.has("stat") and owned.size() > 0:
		out[coll["stat"]] = float(out.get(coll["stat"], 0.0)) + float(coll["value"]) * owned.size()
	var act_pet: String = str(pets.get("active", ""))
	if act_pet != "" and owned.has(act_pet):
		var bon: Dictionary = pet_def(act_pet).get("bonus", {})
		for st in bon:
			out[st] = float(out.get(st, 0.0)) + float(bon[st]) * pet_level(act_pet)
	# guild hall
	for node_id in guild:
		var nd: Dictionary = GuildHall.node_def(node_id)
		if nd.has("stat"):
			out[nd["stat"]] = float(out.get(nd["stat"], 0.0)) + float(nd.get("per", 0)) * int(guild[node_id])
	# store: the Guild Supporter pack's small permanent perks
	for st in Shop.supporter_perks():
		out[st] = float(out.get(st, 0.0)) + float(Shop.supporter_perks()[st])
	return out


func pet_def(pid: String) -> Dictionary:
	return DataDB.pets.get("pets", {}).get(pid, {})


func pet_level(pid: String) -> int:
	return int(pets.get("owned", {}).get(pid, 0))


## Grants a pet (or levels it up on duplicates). Returns true when something changed.
func grant_pet(pid: String) -> bool:
	if pet_def(pid).is_empty():
		return false
	var owned: Dictionary = pets.get("owned", {})
	var maxl := int(DataDB.pets.get("max_level", 10))
	var lv := int(owned.get(pid, 0))
	if lv >= maxl:
		add_material("star_dust", 2)
		return false
	owned[pid] = lv + 1
	pets["owned"] = owned
	if str(pets.get("active", "")) == "":
		pets["active"] = pid
	invalidate_stats()
	EventBus.pet_changed.emit(pid)
	var nm := DataDB.tx(pet_def(pid).get("name", {}))
	if lv == 0:
		EventBus.notify.emit(DataDB.t("pet_new", {"name": nm}), Color("#FFB0D8"))
	else:
		EventBus.notify.emit(DataDB.t("pet_up", {"name": nm, "n": lv + 1}), Color("#FFB0D8"))
	return true


func set_active_pet(pid: String) -> void:
	if pid != "" and pet_level(pid) <= 0:
		return
	pets["active"] = pid
	invalidate_stats()
	EventBus.pet_changed.emit(pid)


func hero_stats(hid: String) -> Dictionary:
	if stats_cache.has(hid):
		return stats_cache[hid]
	if not heroes.has(hid):
		return {}
	var pm := StatCalc.party_mods(party_heroes()) if party.has(hid) else {}
	var acc := account_mods().duplicate()
	var rt := Runes.totals_for(heroes[hid])
	for st in rt:
		acc[st] = float(acc.get(st, 0.0)) + float(rt[st])
	var s := StatCalc.compute(heroes[hid], pm, acc, int(progress.get("difficulty", 0)))
	stats_cache[hid] = s
	return s


# ------------------------------------------------------------------ XP
func grant_kill_xp(monster_level: int, etype: String) -> void:
	var base := F.xp_per_kill(monster_level, etype)
	for hid in heroes:
		var h: HeroState = heroes[hid]
		var in_party := party.has(hid)
		var share := 1.0 if in_party else float(DataDB.bal("xp.reserve_share", 0.25))
		var st: Dictionary = hero_stats(hid) if in_party else {}
		var bonus := 1.0 + float(st.get("xp_bonus", 0.0)) / 100.0
		var amt := base * share * bonus * F.xp_level_factor(h.level, monster_level)
		add_hero_xp(h, amt)


func add_hero_xp(h: HeroState, amount: float) -> void:
	h.xp += amount
	var max_lv := int(DataDB.bal("xp.max_level", 100))
	var leveled := false
	while h.xp >= F.xp_required(h.level):
		h.xp -= F.xp_required(h.level)
		if h.level >= max_lv:
			# past the cap progress never stops: every paragon level hands out stat points to spend
			h.paragon += 1
			h.stat_points += int(DataDB.bal("points.paragon", 3))
			EventBus.notify.emit(DataDB.t("paragon_up", {"name": h.display_name(), "n": h.paragon}), Color("#FFD36A"))
			invalidate_stats()
			continue
		h.level += 1
		h.stat_points += int(DataDB.bal("points.stat_per_level", 5))
		h.skill_points += int(DataDB.bal("points.skill_per_level", 1))
		if h.level % int(DataDB.bal("points.stat_bonus_every", 10)) == 0:
			h.stat_points += int(DataDB.bal("points.stat_bonus", 5))
			h.skill_points += int(DataDB.bal("points.skill_bonus", 1))
		leveled = true
		if Settings.get_v("auto_stats", false):
			h.auto_allocate()
		if Settings.get_v("auto_skills", false):
			h.auto_skills()
		EventBus.hero_leveled.emit(h.id, h.level)
	if leveled:
		invalidate_stats()


func _check_story_unlocks() -> void:
	var top := max_hero_level()
	for hid in DataDB.hero_order:
		var unlock: String = DataDB.hero_def(hid).get("unlock", "")
		if unlock.begins_with("story_") and not heroes.has(hid):
			var lv := int(unlock.substr(6))
			if top >= lv:
				unlock_hero(hid)
				add_to_party(hid)


# ------------------------------------------------------------------ economy
func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		totals["gold"] = int(totals.get("gold", 0)) + amount
	EventBus.gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true


func add_material(mid: String, n: int) -> void:
	materials[mid] = int(materials.get(mid, 0)) + n
	EventBus.materials_changed.emit()


func has_material(mid: String, n: int) -> bool:
	return int(materials.get(mid, 0)) >= n


func spend_material(mid: String, n: int) -> bool:
	if not has_material(mid, n):
		return false
	materials[mid] = int(materials[mid]) - n
	EventBus.materials_changed.emit()
	return true


## Adds an item to the bag honoring the loot filter. Returns "kept" | "sold" | "salvaged".
func receive_item(item: Dictionary) -> String:
	totals["items"] = int(totals.get("items", 0)) + 1
	var r: String = item.get("rarity", "common")
	if r == "legendary" or r == "set" or r == "mythic":
		totals["legendaries"] = int(totals.get("legendaries", 0)) + 1
		if item.get("leg", "") != "":
			codex["legendaries"][item["leg"]] = true
	if r == "mythic":
		totals["mythics"] = int(totals.get("mythics", 0)) + 1
	var action: String = Settings.loot_action(r)
	# gear nobody in the party can wear goes straight to gold (optional, never legendaries)
	if action == "keep" and Settings.get_v("loot_offclass_sell", true) and ItemUtil.rarity_rank(r) < ItemUtil.rarity_rank("legendary"):
		var usable := false
		for h in party_heroes():
			if ItemUtil.can_equip(h, item):
				usable = true
				break
		if not usable and party_count() > 0:
			action = "sell"
	if bag.size() >= bag_slots and action == "keep" and ItemUtil.rarity_rank(r) < ItemUtil.rarity_rank("legendary"):
		action = "sell"
	if action == "keep" and Settings.get_v("auto_equip", false):
		if try_auto_equip(item):
			return "equipped"
	match action:
		"sell":
			add_gold(ItemUtil.sell_price(item))
			return "sold"
		"salvage":
			_salvage_mats(item)
			return "salvaged"
	bag.append(item)
	EventBus.inventory_changed.emit()
	return "kept"


var last_equip_gain := 0       # % power gain of the latest auto-equip (for the notification)


func try_auto_equip(item: Dictionary) -> bool:
	var best_h: HeroState = null
	var best_gain := 0.0
	var best_slot := ""
	for h in party_heroes():
		if not ItemUtil.can_equip(h, item):
			continue
		for slot in ItemUtil.equip_slots(item):
			var cur: Dictionary = h.equipment.get(slot, {})
			var gain := ItemUtil.power_score(item, h.cls()) - ItemUtil.power_score(cur, h.cls())
			if gain > best_gain * 1.0 + 0.01 and gain > ItemUtil.power_score(cur, h.cls()) * 0.05:
				best_gain = gain
				best_h = h
				best_slot = slot
	if best_h == null:
		return false
	var old: Dictionary = best_h.equipment.get(best_slot, {})
	var base := ItemUtil.power_score(old, best_h.cls())
	last_equip_gain = int(round(best_gain / maxf(1.0, base) * 100.0)) if base > 0.0 else 0
	best_h.equipment[best_slot] = item
	if not old.is_empty():
		var act: String = Settings.loot_action(old.get("rarity", "common"))
		if act == "keep" and bag.size() < bag_slots:
			bag.append(old)
		else:
			add_gold(ItemUtil.sell_price(old))
	EventBus.equipment_changed.emit(best_h.id)
	EventBus.inventory_changed.emit()
	return true


func find_bag_index(uid: String) -> int:
	for i in bag.size():
		if bag[i].get("uid", "") == uid:
			return i
	return -1


func equip_from_bag(hid: String, uid: String, slot: String = "") -> String:
	var h: HeroState = heroes.get(hid)
	var idx := find_bag_index(uid)
	if h == null or idx < 0:
		return "missing"
	var item: Dictionary = bag[idx]
	var prob := ItemUtil.equip_problem(h, item)
	if prob != "":
		return prob
	var slots := ItemUtil.equip_slots(item)
	if slot == "" or not slots.has(slot):
		slot = slots[0]
		if slots.size() > 1 and not h.equipment.get(slots[0], {}).is_empty() and h.equipment.get(slots[1], {}).is_empty():
			slot = slots[1]
	bag.remove_at(idx)
	var old: Dictionary = h.equipment.get(slot, {})
	h.equipment[slot] = item
	if not old.is_empty():
		bag.insert(idx, old)
	# a two-handed weapon removes a blocking offhand
	if slot == "weapon" and int(DataDB.items["weapons"].get(item.get("btype", ""), {}).get("hand", 1)) == 2:
		var off: Dictionary = h.equipment.get("offhand", {})
		if not off.is_empty() and not ["quiver", "orb"].has(off.get("btype", "")):
			h.equipment.erase("offhand")
			bag.append(off)
	EventBus.equipment_changed.emit(hid)
	EventBus.inventory_changed.emit()
	return ""


func unequip(hid: String, slot: String) -> bool:
	var h: HeroState = heroes.get(hid)
	if h == null or not h.equipment.has(slot):
		return false
	if bag.size() >= bag_slots:
		EventBus.notify.emit(DataDB.t("bag_full"), Color("#FF6A5A"))
		return false
	bag.append(h.equipment[slot])
	h.equipment.erase(slot)
	EventBus.equipment_changed.emit(hid)
	EventBus.inventory_changed.emit()
	return true


func sell_item(uid: String) -> int:
	var idx := find_bag_index(uid)
	if idx < 0 or bag[idx].get("locked", false):
		return 0
	var p := ItemUtil.sell_price(bag[idx])
	bag.remove_at(idx)
	add_gold(p)
	AudioManager.play("sell", 0.08, 0.6)
	EventBus.inventory_changed.emit()
	return p


func salvage_item(uid: String) -> bool:
	var idx := find_bag_index(uid)
	if idx < 0 or bag[idx].get("locked", false):
		return false
	_salvage_mats(bag[idx])
	bag.remove_at(idx)
	EventBus.inventory_changed.emit()
	return true


func _salvage_mats(item: Dictionary) -> void:
	var tab: Dictionary = DataDB.items.get("salvage", {}).get(item.get("rarity", "common"), {})
	for m in tab:
		add_material(m, int(tab[m]) + int(item.get("enhance", 0)) / 5)


func toggle_lock(uid: String) -> void:
	var idx := find_bag_index(uid)
	if idx >= 0:
		bag[idx]["locked"] = not bag[idx].get("locked", false)
		EventBus.inventory_changed.emit()


func move_to_stash(uid: String, tab: int) -> bool:
	var idx := find_bag_index(uid)
	if idx < 0 or tab >= stash_tabs:
		return false
	if stash[tab].size() >= int(DataDB.bal("stash.slots_per_tab", 36)):
		return false
	stash[tab].append(bag[idx])
	bag.remove_at(idx)
	EventBus.inventory_changed.emit()
	return true


func move_to_bag(tab: int, uid: String) -> bool:
	if bag.size() >= bag_slots:
		return false
	for i in stash[tab].size():
		if stash[tab][i].get("uid", "") == uid:
			bag.append(stash[tab][i])
			stash[tab].remove_at(i)
			EventBus.inventory_changed.emit()
			return true
	return false


## The bag as a grid: every cell holds an item or null. Items keep the cell they were put in ("bpos");
## new or displaced items take the first free cell.
func bag_layout() -> Array:
	var n: int = maxi(bag_slots, bag.size())
	var grid: Array = []
	grid.resize(n)
	var rest: Array = []
	for it in bag:
		var p := int(it.get("bpos", -1))
		if p >= 0 and p < n and grid[p] == null:
			grid[p] = it
		else:
			rest.append(it)
	var i := 0
	for it in rest:
		while grid[i] != null:
			i += 1
		grid[i] = it
		it["bpos"] = i
	return grid


## Drag inside the bag: the item goes to cell `to`; an item already there swaps into its old cell.
func move_in_bag(uid: String, to: int) -> void:
	var idx := find_bag_index(uid)
	var grid := bag_layout()
	if idx < 0 or to < 0 or to >= grid.size():
		return
	var it: Dictionary = bag[idx]
	var from := int(it.get("bpos", -1))
	var other: Variant = grid[to]
	it["bpos"] = to
	if other != null and other != it:
		other["bpos"] = from
	EventBus.inventory_changed.emit()


func sort_bag() -> void:
	for it in bag:
		it.erase("bpos")
	bag.sort_custom(func(a, b):
		var ra := ItemUtil.rarity_rank(a.get("rarity", "common"))
		var rb := ItemUtil.rarity_rank(b.get("rarity", "common"))
		if ra != rb:
			return ra > rb
		if a.get("slot", "") != b.get("slot", ""):
			return str(a.get("slot", "")) < str(b.get("slot", ""))
		return int(a.get("ilvl", 0)) > int(b.get("ilvl", 0)))
	EventBus.inventory_changed.emit()


# ------------------------------------------------------------------ rates (for offline)
func record_rate_sample(xp: float, g: float, kills: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_rate_window.append([now, xp, g, kills])
	while _rate_window.size() > 0 and now - float(_rate_window[0][0]) > 300.0:
		_rate_window.pop_front()
	var sx := 0.0
	var sg := 0.0
	var sk := 0
	for s in _rate_window:
		sx += float(s[1])
		sg += float(s[2])
		sk += int(s[3])
	var span: float = max(60.0, now - float(_rate_window[0][0])) / 60.0
	rates = {"xp": sx / span, "gold": sg / span, "kills": float(sk) / span}


# ------------------------------------------------------------------ save / load
func to_dict() -> Dictionary:
	var hd: Dictionary = {}
	for k in heroes:
		hd[k] = heroes[k].to_dict()
	return {"heroes": hd, "party": party, "gold": gold, "materials": materials, "chests": chests, "runes": runes, "purchases": purchases, "bag": bag, "bag_slots": bag_slots,
		"stash": stash, "stash_tabs": stash_tabs, "progress": progress, "totals": totals, "flags": flags,
		"blacksmith": blacksmith, "tavern": tavern, "guild": guild, "codex": codex, "achievements": achievements,
		"pets": pets, "rates": rates, "uid_counter": uid_counter, "created": created_unix,
		"saved_at": int(Time.get_unix_time_from_system())}


func from_dict(d: Dictionary) -> void:
	reset_state()
	for k in d.get("heroes", {}):
		heroes[k] = HeroState.from_dict(d["heroes"][k])
	party = Array(d.get("party", party))
	while party.size() < PARTY_SIZE:
		party.append("")
	gold = int(d.get("gold", 0))
	materials = d.get("materials", {})
	chests = d.get("chests", [])
	runes = {}
	var rd: Dictionary = d.get("runes", {})
	for rid in rd:
		if Runes.nodes().has(rid):
			runes[rid] = int(rd[rid])
	purchases = d.get("purchases", {})
	bag = d.get("bag", [])
	bag_slots = int(d.get("bag_slots", bag_slots))
	stash = d.get("stash", stash)
	while stash.size() < 7:
		stash.append([])
	stash_tabs = int(d.get("stash_tabs", 1))
	progress.merge(d.get("progress", {}), true)
	totals.merge(d.get("totals", {}), true)
	flags = d.get("flags", {})
	blacksmith.merge(d.get("blacksmith", {}), true)
	tavern.merge(d.get("tavern", {}), true)
	guild = d.get("guild", {})
	codex.merge(d.get("codex", {}), true)
	achievements = d.get("achievements", {})
	pets.merge(d.get("pets", {}), true)
	rates = d.get("rates", rates)
	uid_counter = int(d.get("uid_counter", 1))
	created_unix = int(d.get("created", 0))
	last_save_unix = int(d.get("saved_at", 0))
	loaded = true


func save_path(slot := 0) -> String:
	return SAVE_DIR + "slot_%d.json" % slot


func save_game(slot := 0) -> bool:
	if not loaded:
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := to_dict()
	var body := JSON.stringify(data)
	var wrapper := {"version": SAVE_VERSION, "checksum": body.sha256_text(), "data": body}
	var path := save_path(slot)
	# rotate backups (.bak1 newest)
	for i in range(2, 0, -1):
		var src := path + (".bak%d" % i)
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, path + (".bak%d" % (i + 1)))
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak1")
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("save failed: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(wrapper))
	f.close()
	DirAccess.rename_absolute(tmp, path)
	last_save_unix = int(data["saved_at"])
	return true


func has_save(slot := 0) -> bool:
	_archive_legacy(slot)
	return FileAccess.file_exists(save_path(slot)) or FileAccess.file_exists(save_path(slot) + ".bak1")


## Saves from before the rework (version 1) are moved to legacy_v1/ so the game starts fresh with one hero.
func _archive_legacy(slot: int) -> void:
	var path := save_path(slot)
	if not FileAccess.file_exists(path):
		return
	var w: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (w is Dictionary) or int(w.get("version", 1)) >= SAVE_VERSION:
		return
	var dir := SAVE_DIR + "legacy_v1/"
	DirAccess.make_dir_recursive_absolute(dir)
	for suffix in ["", ".bak1", ".bak2", ".bak3"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.rename_absolute(path + suffix, dir + path.get_file() + suffix)


func load_game(slot := 0) -> bool:
	var path := save_path(slot)
	for candidate in [path, path + ".bak1", path + ".bak2", path + ".bak3"]:
		var d := _read_save(candidate)
		if not d.is_empty():
			from_dict(_migrate(d))
			return true
	return false


func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var w: Variant = JSON.parse_string(txt)
	if not (w is Dictionary) or not w.has("data"):
		return {}
	var body: String = str(w["data"])
	if body.sha256_text() != str(w.get("checksum", "")):
		push_warning("save checksum mismatch: %s" % path)
		return {}
	var d: Variant = JSON.parse_string(body)
	if d is Dictionary:
		d["_version"] = int(w.get("version", 1))
		return d
	return {}


func _migrate(d: Dictionary) -> Dictionary:
	# future: if d["_version"] < 2: ...
	return d
