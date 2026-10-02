class_name GuildHall
extends RefCounted
## Permanent account upgrades bought with gold + guild badges.

const BRANCHES := ["war", "defense", "wealth", "time", "explore"]

const NODES := {
	"war_dmg": {"branch": "war", "stat": "added_dmg", "per": 2.0, "max": 10, "name": ["Savaş Ustalığı", "War Mastery"]},
	"war_crit": {"branch": "war", "stat": "crit_chance", "per": 0.5, "max": 10, "name": ["Keskin Bıçaklar", "Keen Blades"]},
	"war_boss": {"branch": "war", "stat": "boss_dmg", "per": 3.0, "max": 10, "name": ["Dev Avcısı", "Giant Slayer"]},
	"war_critdmg": {"branch": "war", "stat": "crit_dmg", "per": 4.0, "max": 10, "name": ["Ölümcül Darbeler", "Deadly Blows"]},
	"def_hp": {"branch": "defense", "stat": "hp_pct", "per": 2.0, "max": 10, "name": ["Sağlam Bünye", "Sturdy Body"]},
	"def_dr": {"branch": "defense", "stat": "dr", "per": 0.5, "max": 10, "name": ["Kalkan Eğitimi", "Shield Training"]},
	"def_res": {"branch": "defense", "stat": "all_res", "per": 1.5, "max": 10, "name": ["Element Koruması", "Elemental Ward"]},
	"def_revive": {"branch": "defense", "stat": "revive_speed", "per": 5.0, "max": 6, "name": ["Hızlı Diriliş", "Quick Revival"]},
	"wealth_gold": {"branch": "wealth", "stat": "gold_find", "per": 3.0, "max": 10, "name": ["Altın Kese", "Gold Purse"]},
	"wealth_sell": {"branch": "wealth", "stat": "sell_bonus", "per": 2.0, "max": 10, "name": ["Pazarlık", "Haggling"]},
	"wealth_smith": {"branch": "wealth", "stat": "smith_discount", "per": 2.0, "max": 10, "name": ["Demirci Dostu", "Smith's Friend"]},
	"time_eff": {"branch": "time", "stat": "offline_eff", "per": 4.0, "max": 10, "name": ["Sabırlı Lonca", "Patient Guild"]},
	"time_cap": {"branch": "time", "stat": "offline_hours", "per": 1.0, "max": 12, "name": ["Uzun Yolculuk", "Long Journey"]},
	"time_xp": {"branch": "time", "stat": "xp_bonus", "per": 2.0, "max": 10, "name": ["Hızlı Öğrenme", "Fast Learner"]},
	"explore_if": {"branch": "explore", "stat": "item_find", "per": 3.0, "max": 10, "name": ["Hazine Kokusu", "Treasure Sense"]},
	"explore_leg": {"branch": "explore", "stat": "legendary_find", "per": 1.0, "max": 10, "name": ["Efsane Avcısı", "Legend Hunter"]},
	"explore_reserve": {"branch": "explore", "stat": "reserve_xp", "per": 5.0, "max": 10, "name": ["Antrenman Kampı", "Training Camp"]},
}


static func node_def(id: String) -> Dictionary:
	return NODES.get(id, {})


static func node_name(id: String) -> String:
	var n: Array = NODES.get(id, {}).get("name", [id, id])
	return n[0] if DataDB.lang == "tr" else n[1]


static func cost(id: String, level: int) -> Dictionary:
	# level = target level (1-based)
	var g := int(500 * pow(2.2, level - 1))
	var badges := 0 if level <= 2 else (level - 2)
	return {"gold": g, "guild_badge": badges}


static func buy(id: String) -> bool:
	var cur := int(GameState.guild.get(id, 0))
	var nd := node_def(id)
	if nd.is_empty() or cur >= int(nd.get("max", 10)):
		return false
	var c := cost(id, cur + 1)
	if GameState.gold < int(c["gold"]) or not GameState.has_material("guild_badge", int(c["guild_badge"])):
		return false
	GameState.spend_gold(int(c["gold"]))
	if int(c["guild_badge"]) > 0:
		GameState.spend_material("guild_badge", int(c["guild_badge"]))
	GameState.guild[id] = cur + 1
	GameState.invalidate_stats()
	return true
