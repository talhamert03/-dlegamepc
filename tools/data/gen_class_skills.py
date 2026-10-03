#!/usr/bin/env python3
"""Extra class skills unlocked by hero level (10 / 20 / 50) -> merged into game/data/skills.json.

Each class gets five: at Lv 10 an active and a passive, at Lv 20 an active and a passive, at Lv 50 a big
active. They carry "req_lv" and their own battle effects ("vfx"). Re-running replaces them in place.

  python3 tools/data/gen_class_skills.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "game", "data", "skills.json")


def act(cid, cls, lv, icon, vfx, tr, en, dtr, den, params, target, effects, cd, extra=None, mx=10):
    s = {"id": cid, "class": cls, "tier": 0, "req_lv": lv, "type": "active", "max": mx, "cd": cd, "icon": icon, "vfx": vfx,
         "name": {"tr": tr, "en": en}, "desc": {"tr": dtr, "en": den}, "params": params, "target": target, "effects": effects}
    if extra:
        s.update(extra)
    return s


def pas(cid, cls, lv, icon, tr, en, stat, base, step, unit="p", mx=10):
    lab = {"tr": "+{v} " + tr[1], "en": "+{v} " + en[1]}
    return {"id": cid, "class": cls, "tier": 0, "req_lv": lv, "type": "passive", "max": mx, "icon": icon,
            "name": {"tr": tr[0], "en": en[0]}, "desc": lab, "params": {"v": [base, step, unit]}, "stats": {stat: "v"}}


D = lambda m="dmg", **kw: dict({"type": "damage", "mult": m}, **kw)
ST = lambda s, dur, stacks=1, chance=1.0: {"type": "status", "status": s, "dur": dur, "stacks": stacks, "chance": chance}

SKILLS = [
    # knight
    act("knight_sword_rain", "knight", 10, "sword_mastery", "sword_rain", "Kılıç Yağmuru", "Rain of Blades",
        "Gökten kılıçlar yağar: tüm düşmanlara {dmg}.", "Blades fall from the sky: {dmg} to all enemies.",
        {"dmg": [0.9, 0.12, "%"]}, "enemy_all", [D()], 14),
    pas("knight_guardian", "knight", 10, "shield_wall", ("Muhafız", "Savunma"), ("Guardian", "Defense"), "def_pct", 6, 3),
    act("knight_holy_charge", "knight", 20, "judgement", "holy_beam", "Kutsal Hücum", "Holy Charge",
        "Işıkla hücum: {dmg} Kutsal hasar ve 1.5sn sersemletme.", "Charge in light: {dmg} Holy damage and a 1.5s stun.",
        {"dmg": [3.0, 0.4, "%"]}, "enemy_front", [D(element="holy"), ST("stun", 1.5)], 12),
    pas("knight_vigor", "knight", 20, "recovery", ("Dinç Beden", "HP Yenilenme %/sn"), ("Vigor", "HP Regen %/s"), "hp_regen_pct", 0.3, 0.15),
    act("knight_aegis", "knight", 50, "fortress", "aegis", "Ebedi Kalkan", "Eternal Aegis",
        "Partiye can kadar {s} kalkan ve 5sn %15 hasar azaltma.", "Shields the party for {s} of HP and 15% damage reduction for 5s.",
        {"s": [0.15, 0.02, "%"]}, "ally_all", [{"type": "shield", "pct": "s"}, {"type": "buff", "stat": "dr", "value": 15, "dur": 5}], 25),
    # berserker
    act("berserker_shockwave", "berserker", 10, "quake", "shockwave", "Şok Dalgası", "Shockwave",
        "Yeri döver: tüm düşmanlara {dmg}, %30 sersemletme.", "Slams the ground: {dmg} to all enemies, 30% stun.",
        {"dmg": [1.1, 0.15, "%"]}, "enemy_all", [D(), ST("stun", 1.0, 1, 0.3)], 12),
    pas("berserker_bloodlust", "berserker", 10, "thirst", ("Kan Hırsı", "Can Çalma"), ("Bloodlust", "Life Steal"), "lifesteal", 1, 0.5),
    act("berserker_blade_storm", "berserker", 20, "whirl", "blade_storm", "Kılıç Fırtınası", "Blade Storm",
        "Dönerek öndekilere 6 kez {dmg}.", "Spins through the front line: 6 hits of {dmg}.",
        {"dmg": [0.5, 0.07, "%"]}, "enemy_aoe", [D(hits=6)], 15, {"radius": 60}),
    pas("berserker_titan", "berserker", 20, "twohand", ("Titan Kolu", "Kritik Hasarı"), ("Titan's Arm", "Crit Damage"), "crit_dmg", 10, 5),
    act("berserker_earthsplitter", "berserker", 50, "ragnarok", "earth_split", "Yer Yaran", "Earthsplitter",
        "Toprağı yarar: tüm düşmanlara {dmg} ve Savunmasız.", "Splits the earth: {dmg} to all enemies and Vulnerable.",
        {"dmg": [4.0, 0.5, "%"]}, "enemy_all", [D(), ST("vulnerable", 4)], 22),
    # archer
    act("archer_volley", "archer", 10, "rain", "arrow_volley", "Ok Yağdırma", "Volley",
        "Ok bulutu: tüm düşmanlara 2 kez {dmg}.", "A cloud of arrows: 2 hits of {dmg} to all enemies.",
        {"dmg": [0.7, 0.1, "%"]}, "enemy_all", [D(hits=2)], 12),
    pas("archer_eagle", "archer", 10, "keen_eye", ("Kartal Bakışı", "Kritik Şansı"), ("Eagle Gaze", "Crit Chance"), "crit_chance", 2, 1),
    act("archer_frost_arrow", "archer", 20, "ice_lance", "frost_arrow", "Ayaz Oku", "Frost Arrow",
        "{dmg} Soğuk hasar ve 3 yığın Üşüme.", "{dmg} Cold damage and 3 Chill stacks.",
        {"dmg": [2.6, 0.35, "%"]}, "enemy_front", [D(element="cold"), ST("chill", 3, 3)], 9),
    pas("archer_hunter", "archer", 20, "mark", ("Usta Avcı", "Elit Hasarı"), ("Master Hunter", "Elite Damage"), "elite_dmg", 8, 4),
    act("archer_comet", "archer", 50, "starbreaker", "comet", "Kuyrukluyıldız Oku", "Comet Arrow",
        "Gökten inen ok: bölgeye {dmg} Yıldırım hasarı.", "An arrow from the sky: {dmg} Lightning damage in an area.",
        {"dmg": [5.0, 0.6, "%"]}, "enemy_aoe", [D(element="lightning")], 24, {"radius": 50}),
    # assassin
    act("assassin_fan", "assassin", 10, "thousand", "blade_fan", "Bıçak Yelpazesi", "Fan of Knives",
        "Tüm düşmanlara {dmg} ve Kanama.", "{dmg} to all enemies and Bleed.",
        {"dmg": [0.8, 0.11, "%"]}, "enemy_all", [D(), ST("bleed", 4, 2)], 11),
    pas("assassin_ghost", "assassin", 10, "cloak", ("Hayalet", "Kaçınma"), ("Ghost", "Evasion"), "evasion", 3, 1.5),
    act("assassin_shadow_clone", "assassin", 20, "shadow_step", "shadow_strike", "Gölge İkizi", "Shadow Twin",
        "Gölgesi en zayıf düşmana 3 kez {dmg} Kaos hasarı vurur.", "Its shadow strikes the weakest foe 3 times for {dmg} Chaos damage.",
        {"dmg": [1.4, 0.2, "%"]}, "enemy_lowest", [D(hits=3, element="chaos")], 13),
    pas("assassin_lethal", "assassin", 20, "execute", ("Ölümcül", "İnfaz Hasarı"), ("Lethal", "Execute Damage"), "execute_dmg", 10, 5),
    act("assassin_death_mark", "assassin", 50, "eclipse", "death_mark", "Ölüm İşareti", "Mark of Death",
        "Arkadaki düşmana {dmg} ve Savunmasız.", "{dmg} to the rearmost foe and Vulnerable.",
        {"dmg": [7.0, 0.8, "%"]}, "enemy_back", [D(), ST("vulnerable", 5)], 25),
    # mage
    act("mage_ice_rain", "mage", 10, "zero", "ice_rain", "Buz Yağmuru", "Ice Rain",
        "Düşmanların üstüne buz yağar: herkese 2 kez {dmg} Soğuk hasar, Üşüme.", "Ice rains on the foes: 2 hits of {dmg} Cold damage, Chill.",
        {"dmg": [1.0, 0.14, "%"]}, "enemy_all", [D(hits=2, element="cold"), ST("chill", 3, 2)], 14),
    pas("mage_frostbite", "mage", 10, "crystal", ("Ayaz Isırığı", "Soğuk Hasarı"), ("Frostbite", "Cold Damage"), "cold_dmg", 8, 4),
    act("mage_arcane_orb", "mage", 20, "focus", "arcane_orb", "Arkana Küresi", "Arcane Orb",
        "Patlayan küre: bölgeye {dmg} Yıldırım hasarı.", "An exploding orb: {dmg} Lightning damage in an area.",
        {"dmg": [2.4, 0.3, "%"]}, "enemy_aoe", [D(element="lightning")], 11, {"radius": 50}),
    pas("mage_mana_flow", "mage", 20, "wellspring", ("Mana Akışı", "Bekleme Azaltma"), ("Mana Flow", "Cooldown Reduction"), "cdr", 2, 1),
    act("mage_blizzard", "mage", 50, "zero", "blizzard", "Kar Fırtınası", "Blizzard",
        "Dondurucu fırtına: herkese 5 kez {dmg} Soğuk hasar, %30 Donma.", "A freezing storm: 5 hits of {dmg} Cold damage to all, 30% Freeze.",
        {"dmg": [0.8, 0.1, "%"]}, "enemy_all", [D(hits=5, element="cold"), ST("stun", 1.5, 1, 0.3)], 26),
    # necromancer
    act("necro_skull_storm", "necromancer", 10, "doom", "skull_storm", "Kafatası Fırtınası", "Skull Storm",
        "Rastgele 4 düşmana {dmg} Kaos hasarı.", "{dmg} Chaos damage to 4 random foes.",
        {"dmg": [1.3, 0.18, "%"]}, "enemy_random", [D(element="chaos")], 12, {"max_targets": 4}),
    pas("necro_dark_pact", "necromancer", 10, "lore", ("Karanlık Ant", "Kaos Hasarı"), ("Dark Pact", "Chaos Damage"), "chaos_dmg", 8, 4),
    act("necro_soul_siphon", "necromancer", 20, "drain", "soul_siphon", "Ruh Emme", "Soul Siphon",
        "{dmg} Kaos hasarı; hasarın %30'u partiyi iyileştirir.", "{dmg} Chaos damage; 30% of it heals the party.",
        {"dmg": [2.5, 0.32, "%"]}, "enemy_front", [D(element="chaos", party_heal=0.3)], 12),
    pas("necro_grave_lord", "necromancer", 20, "sovereign", ("Mezar Lordu", "Çağrı Hasarı"), ("Grave Lord", "Summon Damage"), "summon_dmg", 10, 5),
    act("necro_bone_prison", "necromancer", 50, "bone_armor", "bone_prison", "Kemik Hapsi", "Bone Prison",
        "Tüm düşmanlara {dmg} Kaos hasarı, %50 sersemletme.", "{dmg} Chaos damage to all foes, 50% stun.",
        {"dmg": [2.0, 0.26, "%"]}, "enemy_all", [D(element="chaos"), ST("stun", 2.0, 1, 0.5)], 24),
    # cleric
    act("cleric_holy_beam", "cleric", 10, "smite", "holy_beam", "Kutsal Işın", "Holy Beam",
        "Gökten inen ışın: {dmg} Kutsal hasar.", "A beam from the heavens: {dmg} Holy damage.",
        {"dmg": [2.8, 0.35, "%"]}, "enemy_front", [D(element="holy")], 9),
    pas("cleric_grace", "cleric", 10, "blessing", ("Lütuf", "İyileştirme"), ("Grace", "Healing"), "heal_bonus", 6, 3),
    act("cleric_sanctuary", "cleric", 20, "light_shield", "sanctuary", "Sığınak", "Sanctuary",
        "Partiye canının {h}'i kadar şifa ve 5sn %10 hasar azaltma.", "Heals the party for {h} of HP and 10% damage reduction for 5s.",
        {"h": [0.12, 0.015, "%"]}, "ally_all", [{"type": "heal_pct", "value": "h"}, {"type": "buff", "stat": "dr", "value": 10, "dur": 5}], 18),
    pas("cleric_devotion", "cleric", 20, "faith", ("Adanmışlık", "Kutsal Hasar"), ("Devotion", "Holy Damage"), "holy_dmg", 8, 4),
    act("cleric_sun_burst", "cleric", 50, "gate", "sun_burst", "Güneş Patlaması", "Sunburst",
        "Tüm düşmanlara {dmg} Kutsal hasar, %30 sersemletme.", "{dmg} Holy damage to all foes, 30% stun.",
        {"dmg": [3.5, 0.45, "%"]}, "enemy_all", [D(element="holy"), ST("stun", 1.5, 1, 0.3)], 24),
    # bard
    act("bard_sonic_wave", "bard", 10, "discord", "sonic_wave", "Ses Dalgası", "Sonic Wave",
        "Tüm düşmanlara {dmg} Yıldırım hasarı ve Şok.", "{dmg} Lightning damage to all foes and Shock.",
        {"dmg": [0.9, 0.12, "%"]}, "enemy_all", [D(element="lightning"), ST("shock", 3)], 11),
    pas("bard_tempo", "bard", 10, "rhythm", ("Tempo", "Saldırı Hızı"), ("Tempo", "Attack Speed"), "attack_speed", 3, 1.5),
    act("bard_anthem", "bard", 20, "march", "anthem", "Zafer Marşı", "Victory Anthem",
        "Partiye 6sn +{v} Eklenen Hasar.", "+{v} Added Damage to the party for 6s.",
        {"v": [10, 1.5, "p"]}, "ally_all", [{"type": "buff", "stat": "added_dmg", "value": "v", "dur": 6}], 16),
    pas("bard_harmony", "bard", 20, "serenity", ("Ahenk", "Buff Süresi"), ("Harmony", "Buff Duration"), "buff_duration", 8, 4),
    act("bard_thunder_chord", "bard", 50, "legends", "thunder_chord", "Gök Akoru", "Thunder Chord",
        "Bölgeye {dmg} Yıldırım hasarı, %40 sersemletme.", "{dmg} Lightning damage in an area, 40% stun.",
        {"dmg": [4.0, 0.5, "%"]}, "enemy_aoe", [D(element="lightning"), ST("stun", 1.5, 1, 0.4)], 22, {"radius": 70}),
]


def main():
    data = json.load(open(PATH, encoding="utf-8"))
    ids = {s["id"] for s in SKILLS}
    data["skills"] = [s for s in data["skills"] if s["id"] not in ids] + SKILLS
    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print("class skills:", len(SKILLS), "total:", len(data["skills"]))


if __name__ == "__main__":
    main()
