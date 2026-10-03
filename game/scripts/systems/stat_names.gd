class_name StatNames
extends RefCounted
## Localized labels for stat keys and whether a stat is a flat number or a percentage.

const FLAT := ["attack", "spell", "power", "max_hp", "def", "attack_flat", "spell_flat", "hp_flat", "def_flat", "weapon_atk",
	"str", "dex", "int", "vit", "luk", "all_stats", "threat", "max_summons", "cheat_death", "multishot", "level", "hp_regen"]

const L := {
	"level": ["Seviye", "Level"], "power": ["Güç", "Power"], "attack": ["Saldırı", "Attack"], "spell": ["Büyü Gücü", "Spell Power"],
	"max_hp": ["HP", "HP"], "def": ["Savunma", "Defense"], "attack_flat": ["Saldırı", "Attack"], "spell_flat": ["Büyü Gücü", "Spell Power"],
	"hp_flat": ["HP", "HP"], "def_flat": ["Savunma", "Defense"], "attack_pct": ["Saldırı", "Attack"], "spell_pct": ["Büyü Gücü", "Spell Power"],
	"hp_pct": ["HP", "HP"], "def_pct": ["Savunma", "Defense"], "weapon_atk": ["Silah Hasarı", "Weapon Damage"],
	"str": ["Güç", "Strength"], "dex": ["Çeviklik", "Dexterity"], "int": ["Zekâ", "Intelligence"], "vit": ["Dayanıklılık", "Vitality"],
	"luk": ["Şans", "Luck"], "all_stats": ["Tüm Statlar", "All Stats"],
	"added_dmg": ["Eklenen Hasar", "Added Damage"], "elem_dmg": ["Elemental Hasar", "Elemental Damage"],
	"crit_chance": ["Kritik Şansı", "Critical Hit Chance"], "crit_dmg": ["Kritik Hasarı", "Critical Hit DMG"],
	"penetrate": ["Delme", "Penetrate"], "attack_speed": ["Saldırı Hızı", "Attack Speed"], "cast_speed": ["Büyü Hızı", "Cast Speed"],
	"skill_dmg": ["Skill Hasarı", "Skill Damage"], "ult_dmg": ["Nihai Hasarı", "Ultimate Damage"],
	"phys_dmg": ["Fiziksel Hasar", "Physical Damage"], "fire_dmg": ["Ateş Hasarı", "Fire Damage"], "cold_dmg": ["Soğuk Hasarı", "Cold Damage"],
	"lightning_dmg": ["Yıldırım Hasarı", "Lightning Damage"], "chaos_dmg": ["Kaos Hasarı", "Chaos Damage"], "holy_dmg": ["Kutsal Hasar", "Holy Damage"],
	"fire_res": ["Ateş Direnci", "Fire Resistance"], "cold_res": ["Soğuk Direnci", "Cold Resistance"],
	"lightning_res": ["Yıldırım Direnci", "Lightning Resistance"], "chaos_res": ["Kaos Direnci", "Chaos Resistance"],
	"all_res": ["Tüm Direnç", "All Resistance"], "crit_res": ["Kritik Direnci", "Critical Hit Resist"],
	"evasion": ["Kaçınma", "Evasion"], "block": ["Blok", "Block"], "lifesteal": ["Can Çalma", "Life Steal"],
	"hp_regen": ["HP Yenilenme/sn", "HP Regen/s"], "hp_regen_pct": ["HP Yenilenme %/sn", "HP Regen %/s"],
	"cdr": ["Bekleme Azaltma", "Cooldown Reduction"], "item_find": ["Item Bulma", "Item Find"], "gold_find": ["Altın Bulma", "Gold Find"],
	"xp_bonus": ["XP Bonusu", "XP Bonus"], "heal_bonus": ["İyileştirme", "Healing"], "elite_dmg": ["Elit Hasarı", "Elite Damage"],
	"boss_dmg": ["Boss Hasarı", "Boss Damage"], "threat": ["Tehdit", "Threat"], "dr": ["Hasar Azaltma", "Damage Reduction"],
	"ult_charge": ["Nihai Dolumu", "Ultimate Charge"], "revive_speed": ["Diriliş Hızı", "Revive Speed"],
	"summon_dmg": ["Çağrı Hasarı", "Summon Damage"], "summon_hp": ["Çağrı HP", "Summon HP"], "max_summons": ["Maks. Çağrı", "Max Summons"],
	"aoe_dmg": ["Alan Hasarı", "Area Damage"], "buff_duration": ["Buff Süresi", "Buff Duration"], "pet_dmg": ["Evcil Hasarı", "Pet Damage"],
	"undead_dmg": ["Ölümsüzlere Hasar", "Damage vs Undead"], "night_dmg": ["Gece Hasarı", "Night Damage"],
	"bleed_dmg": ["Kanama Hasarı", "Bleed Damage"], "poison_dmg": ["Zehir Hasarı", "Poison Damage"], "burn_dmg": ["Yanma Hasarı", "Burn Damage"],
	"bleed_chance": ["Kanama Şansı", "Bleed Chance"], "stun_chance": ["Sersemletme Şansı", "Stun Chance"],
	"weaken_chance": ["Zayıflatma Şansı", "Weaken Chance"], "status_chance": ["Durum Şansı", "Status Chance"],
	"execute_dmg": ["İnfaz Hasarı", "Execute Damage"], "rage_dmg": ["Öfke Hasarı", "Rage Damage"], "thorns": ["Diken", "Thorns"],
	"cheat_death": ["Ölümden Dönüş", "Cheat Death"], "multishot": ["Ek Ok", "Extra Arrows"], "offline_eff": ["Offline Verim", "Offline Efficiency"],
	"legendary_find": ["Efsanevi Şansı", "Legendary Chance"], "mythic_find": ["Mitik Şansı", "Mythic Chance"],
	"move_speed": ["Hareket Hızı", "Move Speed"], "enemy_weaken": ["Düşman Zayıflatma", "Enemy Weaken"], "triple_cast": ["Üçlü Büyü", "Triple Cast"],
	"aps": ["Saldırı/sn", "Attacks/s"], "chest_find": ["Sandık Bulma", "Chest Find"], "invuln": ["Ölümsüzlük", "Invulnerable"],
}


static func label(key: String) -> String:
	var k := key
	var party := false
	if k.begins_with("party_"):
		k = k.substr(6)
		party = true
	var arr: Array = L.get(k, [k, k])
	var s: String = arr[0] if DataDB.lang == "tr" else arr[1]
	if party:
		s = ("Parti " if DataDB.lang == "tr" else "Party ") + s
	return s


static func is_flat(key: String) -> bool:
	var k := key.trim_prefix("party_")
	return FLAT.has(k)


static func fmt(key: String, v: float) -> String:
	if is_flat(key):
		return F.fmt_num(v)
	return ("%.1f%%" % v) if abs(v - round(v)) > 0.05 else ("%d%%" % int(round(v)))
