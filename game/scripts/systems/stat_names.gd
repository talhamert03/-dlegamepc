class_name StatNames
extends RefCounted
## Localized labels for stat keys and whether a stat is a flat number or a percentage.

const FLAT := ["attack", "spell", "power", "max_hp", "def", "attack_flat", "spell_flat", "hp_flat", "def_flat", "weapon_atk",
	"str", "dex", "int", "vit", "luk", "all_stats", "threat", "max_summons", "cheat_death", "multishot", "level", "hp_regen"]

const L := {
	"level": ["Seviye", "Level"], "power": ["Saldırı Gücü", "Power"], "attack": ["Saldırı", "Attack"], "spell": ["Büyü Gücü", "Spell Power"],
	"max_hp": ["Can", "Life"], "def": ["Savunma", "Defense"], "attack_flat": ["Saldırı", "Attack"], "spell_flat": ["Büyü Gücü", "Spell Power"],
	"hp_flat": ["Can", "Life"], "def_flat": ["Savunma", "Defense"], "attack_pct": ["Saldırı", "Attack"], "spell_pct": ["Büyü Gücü", "Spell Power"],
	"hp_pct": ["Can", "Life"], "def_pct": ["Savunma", "Defense"], "weapon_atk": ["Silah Hasarı", "Weapon Damage"],
	"str": ["Kuvvet", "Strength"], "dex": ["Çeviklik", "Dexterity"], "int": ["Zekâ", "Intelligence"], "vit": ["Dayanıklılık", "Vitality"],
	"luk": ["Şans", "Luck"], "all_stats": ["Tüm Özellikler", "All Attributes"],
	"added_dmg": ["Eklenen Hasar", "Added Damage"], "elem_dmg": ["Elemental Hasar", "Elemental Damage"],
	"crit_chance": ["Kritik Şansı", "Critical Hit Chance"], "crit_dmg": ["Kritik Hasarı", "Critical Hit DMG"],
	"penetrate": ["Delme", "Penetrate"], "attack_speed": ["Saldırı Hızı", "Attack Speed"], "cast_speed": ["Büyü Hızı", "Cast Speed"],
	"skill_dmg": ["Yetenek Hasarı", "Skill Damage"], "ult_dmg": ["Nihai Hasarı", "Ultimate Damage"],
	"phys_dmg": ["Fiziksel Hasar", "Physical Damage"], "fire_dmg": ["Ateş Hasarı", "Fire Damage"], "cold_dmg": ["Soğuk Hasarı", "Cold Damage"],
	"lightning_dmg": ["Yıldırım Hasarı", "Lightning Damage"], "chaos_dmg": ["Kaos Hasarı", "Chaos Damage"], "holy_dmg": ["Kutsal Hasar", "Holy Damage"],
	"fire_res": ["Ateş Direnci", "Fire Resistance"], "cold_res": ["Soğuk Direnci", "Cold Resistance"],
	"lightning_res": ["Yıldırım Direnci", "Lightning Resistance"], "chaos_res": ["Kaos Direnci", "Chaos Resistance"],
	"all_res": ["Tüm Direnç", "All Resistance"], "crit_res": ["Kritik Direnci", "Critical Hit Resist"],
	"evasion": ["Kaçınma", "Evasion"], "block": ["Blok", "Block"], "lifesteal": ["Can Çalma", "Life Steal"],
	"hp_regen": ["Can Yenilenmesi/sn", "Life Regen/s"], "hp_regen_pct": ["Can Yenilenmesi %/sn", "Life Regen %/s"],
	"cdr": ["Bekleme Azaltma", "Cooldown Reduction"], "item_find": ["Eşya Bulma", "Item Find"], "gold_find": ["Altın Bulma", "Gold Find"],
	"xp_bonus": ["Tecrübe Bonusu", "XP Bonus"], "heal_bonus": ["İyileştirme", "Healing"], "elite_dmg": ["Elit Hasarı", "Elite Damage"],
	"boss_dmg": ["Boss Hasarı", "Boss Damage"], "threat": ["Tehdit", "Threat"], "dr": ["Hasar Azaltma", "Damage Reduction"],
	"ult_charge": ["Nihai Dolumu", "Ultimate Charge"], "revive_speed": ["Diriliş Hızı", "Revive Speed"],
	"summon_dmg": ["Çağrı Hasarı", "Summon Damage"], "summon_hp": ["Çağrı Canı", "Summon Life"], "max_summons": ["Maks. Çağrı", "Max Summons"],
	"aoe_dmg": ["Alan Hasarı", "Area Damage"], "buff_duration": ["Güçlendirme Süresi", "Buff Duration"], "pet_dmg": ["Evcil Dost Hasarı", "Pet Damage"],
	"undead_dmg": ["Ölümsüzlere Hasar", "Damage vs Undead"], "night_dmg": ["Gece Hasarı", "Night Damage"],
	"bleed_dmg": ["Kanama Hasarı", "Bleed Damage"], "poison_dmg": ["Zehir Hasarı", "Poison Damage"], "burn_dmg": ["Yanma Hasarı", "Burn Damage"],
	"bleed_chance": ["Kanama Şansı", "Bleed Chance"], "stun_chance": ["Sersemletme Şansı", "Stun Chance"],
	"weaken_chance": ["Zayıflatma Şansı", "Weaken Chance"], "status_chance": ["Durum Şansı", "Status Chance"],
	"execute_dmg": ["İnfaz Hasarı", "Execute Damage"], "rage_dmg": ["Öfke Hasarı", "Rage Damage"], "thorns": ["Diken", "Thorns"],
	"cheat_death": ["Ölümden Dönüş", "Cheat Death"], "multishot": ["Ek Ok", "Extra Arrows"], "offline_eff": ["Çevrimdışı Verim", "Offline Efficiency"],
	"legendary_find": ["Efsanevi Şansı", "Legendary Chance"], "mythic_find": ["Mitik Şansı", "Mythic Chance"],
	"move_speed": ["Hareket Hızı", "Move Speed"], "enemy_weaken": ["Düşman Zayıflatma", "Enemy Weaken"], "triple_cast": ["Üçlü Büyü", "Triple Cast"],
	"aps": ["Saldırı/sn", "Attacks/s"], "chest_find": ["Sandık Bulma", "Chest Find"], "invuln": ["Ölümsüzlük", "Invulnerable"],
}


## What a stat does, in one plain sentence (shown on hover in the status panel).
const DESC := {
	"aps": ["Saniyedeki temel saldırı sayısı.", "Basic attacks per second."],
	"crit_chance": ["Bir vuruşun kritik olma ihtimali (düz yüzde: %20 = her 5 vuruştan 1'i).", "Chance for a hit to crit (flat percent: 20% = 1 hit in 5)."],
	"crit_dmg": ["Kritik vuruşun normal hasara oranı (%150 = 1,5 kat).", "Critical hit damage relative to a normal hit (150% = 1.5x)."],
	"spell": ["Büyülerin ve iyileştirmelerin gücü.", "Strength of spells and heals."],
	"added_dmg": ["Tüm hasarına yüzde olarak eklenir (eksi değer hasarı düşürür).", "Percent added to all your damage (a negative value lowers it)."],
	"elem_dmg": ["Tüm elemental (ateş, soğuk, yıldırım, kaos) hasarını artırır.", "Raises all elemental damage (fire, cold, lightning, chaos)."],
	"penetrate": ["Düşman savunmasının bu yüzdesini yok sayar.", "Ignores this share of enemy defense."],
	"attack_speed": ["Saldırı hızını yüzde olarak artırır.", "Raises attack speed by this percent."],
	"cast_speed": ["Yetenek bekleme sürelerini kısaltır.", "Shortens skill cooldowns."],
	"skill_dmg": ["Yeteneklerin hasarını artırır.", "Raises skill damage."],
	"elite_dmg": ["Elit düşmanlara karşı ek hasar.", "Extra damage against elites."],
	"boss_dmg": ["Boss'lara karşı ek hasar.", "Extra damage against bosses."],
	"dr": ["Alınan tüm hasarı bu yüzde kadar azaltır (en fazla %75).", "Cuts all damage taken by this percent (max 75%)."],
	"crit_res": ["Düşman kritiklerinin ek hasarını azaltır.", "Reduces the extra damage of enemy crits."],
	"evasion": ["Bir saldırıdan tamamen kaçma ihtimali.", "Chance to dodge an attack entirely."],
	"block": ["Bloklanan vuruşun hasarı %60 azalır (en fazla %50 blok şansı).", "A blocked hit deals 60% less (block chance caps at 50%)."],
	"fire_res": ["Ateş hasarını azaltır (en fazla %75). Ateş saldıran bölgelerde önemli.", "Reduces fire damage (max 75%). Key in zones whose enemies use fire."],
	"cold_res": ["Soğuk hasarını azaltır (en fazla %75).", "Reduces cold damage (max 75%)."],
	"lightning_res": ["Yıldırım hasarını azaltır (en fazla %75).", "Reduces lightning damage (max 75%)."],
	"chaos_res": ["Kaos hasarını azaltır (en fazla %75).", "Reduces chaos damage (max 75%)."],
	"lifesteal": ["Verilen hasarın bu yüzdesi kadar can kazanılır.", "Heals for this share of damage dealt."],
	"thorns": ["Yakın dövüşte vurana, alınan hasarın bu yüzdesi geri yansır.", "Reflects this share of melee damage taken back to the attacker."],
	"hp_regen": ["Her saniye yenilenen can.", "Life regenerated every second."],
	"item_find": ["Eşya düşme şansı ve nadirliği.", "Item drop chance and rarity."],
	"gold_find": ["Kazanılan altını artırır.", "Raises gold earned."],
	"xp_bonus": ["Kazanılan tecrübeyi artırır.", "Raises experience earned."],
	"cdr": ["Yetenek bekleme sürelerini azaltır.", "Reduces skill cooldowns."],
	"heal_bonus": ["Yapılan iyileştirmeleri güçlendirir.", "Strengthens healing done."],
	"buff_duration": ["Destek etkilerinin süresini uzatır.", "Extends buff durations."],
	"ult_charge": ["Nihai yeteneğin daha hızlı dolmasını sağlar.", "Charges the ultimate faster."],
	"summon_dmg": ["Çağrılan yaratıkların hasarını artırır.", "Raises summon damage."],
}


static func describe(key: String) -> String:
	var d: Array = DESC.get(key, [])
	if d.is_empty():
		return ""
	return d[0] if DataDB.lang == "tr" else d[1]


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
	return F.pct(v)
