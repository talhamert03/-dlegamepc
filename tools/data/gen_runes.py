#!/usr/bin/env python3
"""Leadership rune tree (account-wide) -> game/data/runes.json

The player's own growth as the party's commander: a core rune and four branches, each opening outwards.
A rune may name the classes it empowers ("cls"); without it the bonus goes to every hero.
Each branch: six runes in a line, two side runes (off the 2nd and 4th) and a one-rank capstone at the end.

  python3 tools/data/gen_runes.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "data", "runes.json")

R, L, U, D = (1, 0), (-1, 0), (0, -1), (0, 1)
CASTERS = ["mage", "necromancer", "bard", "cleric"]
MARTIAL = ["knight", "berserker", "assassin", "archer"]

# Each branch: a line of ten runes, four side runes (off the 2nd, 4th, 6th and 8th) and a capstone.
# rune: (stat, per rank, max rank, glyph, classes or None, tr, en)
BRANCHES = [
    ("academy", "Büyü Akademisi", "Arcane Academy", "#B48CFF", U, [
        ("spell_pct", 3, 10, "book", CASTERS, "Büyü Dersleri", "Spell Lessons"),
        ("fire_dmg", 4, 10, "flame", ["mage"], "Büyücü: Ateş Ustalığı", "Mage: Fire Mastery"),
        ("cast_speed", 2, 10, "bolt", CASTERS, "Hızlı Büyü", "Quick Casting"),
        ("summon_dmg", 5, 10, "people", ["necromancer"], "Nekromant: Ölü Ordusu", "Necromancer: Army of the Dead"),
        ("skill_dmg", 3, 10, "rune", CASTERS, "Kadim Formüller", "Ancient Formulae"),
        ("cold_dmg", 4, 10, "gem", ["mage"], "Büyücü: Buz Kalbi", "Mage: Heart of Ice"),
        ("chaos_dmg", 4, 10, "skull", ["necromancer"], "Nekromant: Kara Bilgi", "Necromancer: Dark Lore"),
        ("lightning_dmg", 4, 10, "bolt", ["bard"], "Ozan: Gök Ezgisi", "Bard: Sky Song"),
        ("spell_pct", 4, 10, "book", CASTERS, "Yüksek Büyü", "High Sorcery"),
        ("ult_dmg", 6, 10, "sparkle", CASTERS, "Kıyamet Sözleri", "Words of Ruin"),
        # sides
        ("cdr", 1, 10, "clock", CASTERS, "Mana Akışı", "Mana Flow"),
        ("crit_chance", 0.6, 10, "target", CASTERS, "Kristal Odak", "Crystal Focus"),
        ("holy_dmg", 4, 10, "cross", ["cleric"], "Rahip: Işık Kelamı", "Cleric: Word of Light"),
        ("elem_dmg", 3, 10, "gem", CASTERS, "Element Uyumu", "Elemental Harmony"),
        ("spell_pct", 20, 1, "crown", CASTERS, "Başbüyücü Kürsüsü", "Archmage's Chair"),
    ]),
    ("war", "Savaş Okulu", "War College", "#FF8A4A", R, [
        ("attack_pct", 3, 10, "sword", MARTIAL, "Silah Talimi", "Weapon Drill"),
        ("attack_speed", 1.5, 10, "bolt", ["archer", "assassin"], "Okçu & Suikastçı: Çevik El", "Archer & Assassin: Quick Hands"),
        ("crit_chance", 0.6, 10, "target", MARTIAL, "Zayıf Noktalar", "Weak Points"),
        ("hp_pct", 3, 10, "heart", ["knight", "berserker"], "Şövalye & Barbar: Demir Beden", "Knight & Berserker: Iron Body"),
        ("crit_dmg", 5, 10, "claw", MARTIAL, "Ölümcül Darbe", "Deadly Blow"),
        ("phys_dmg", 4, 10, "hammer", MARTIAL, "Çelik Disiplin", "Steel Discipline"),
        ("rage_dmg", 5, 10, "flame", ["berserker"], "Barbar: Öfke Ateşi", "Berserker: Fire of Rage"),
        ("execute_dmg", 5, 10, "skull", ["assassin"], "Suikastçı: Son Darbe", "Assassin: Finishing Blow"),
        ("attack_pct", 4, 10, "sword", MARTIAL, "Usta Kılıççı", "Blademaster"),
        ("crit_dmg", 7, 10, "claw", MARTIAL, "Cellat", "Headsman"),
        ("boss_dmg", 4, 10, "skull", None, "Dev Avcıları", "Giant Hunters"),
        ("penetrate", 1.2, 10, "arrow", ["archer"], "Okçu: Delici Ok", "Archer: Piercing Shot"),
        ("elite_dmg", 4, 10, "flag", None, "Elit Avı", "Elite Hunt"),
        ("aoe_dmg", 4, 10, "star", None, "Yarma", "Cleave"),
        ("attack_pct", 20, 1, "crown", MARTIAL, "Savaş Lordu", "Warlord"),
    ]),
    ("guard", "Muhafız Kalesi", "Warden's Keep", "#6FB7FF", L, [
        ("hp_pct", 2, 10, "heart", None, "Sağlam Saflar", "Firm Ranks"),
        ("heal_bonus", 4, 10, "plus", ["cleric", "bard"], "Rahip & Ozan: Şifa Bilgisi", "Cleric & Bard: Healing Lore"),
        ("def_pct", 3, 10, "shield", None, "Kalkan Duvarı", "Shield Wall"),
        ("block", 1, 10, "lock", ["knight"], "Şövalye: Siper", "Knight: Bulwark"),
        ("all_res", 1.5, 10, "gem", None, "Element Muskası", "Elemental Charm"),
        ("dr", 0.4, 10, "tower", None, "Sarsılmaz", "Unshakeable"),
        ("hp_regen_pct", 0.1, 10, "drop", None, "Toparlanma", "Recovery"),
        ("evasion", 1, 10, "boot", None, "Çevik Adımlar", "Light Feet"),
        ("hp_pct", 3, 10, "heart", None, "Dev Yürek", "Giant's Heart"),
        ("def_pct", 4, 10, "shield", None, "Kale Duvarları", "Castle Walls"),
        ("revive_speed", 5, 10, "cross", None, "Saha Hekimi", "Field Medic"),
        ("buff_duration", 4, 10, "note", ["bard", "cleric"], "Uzun Kutsama", "Long Blessing"),
        ("thorns", 3, 10, "spikes", ["knight", "berserker"], "Dikenli Zırh", "Thorned Plate"),
        ("crit_res", 2, 10, "eye", None, "Tetikte", "Vigilance"),
        ("cheat_death", 1, 1, "cross", None, "Son Direniş", "Last Stand"),
    ]),
    ("guild", "Hazine Loncası", "Treasure Guild", "#FFD35A", D, [
        ("gold_find", 4, 10, "gold", None, "Lonca Kesesi", "Guild Purse"),
        ("xp_bonus", 3, 10, "book", None, "Usta Eğitmenler", "Master Trainers"),
        ("item_find", 4, 10, "bag", None, "Ganimet Gözü", "Loot Eye"),
        ("chest_find", 6, 10, "chest", None, "Define Haritaları", "Treasure Maps"),
        ("gold_find", 5, 10, "gold", None, "Pazarlıkçı", "Haggler"),
        ("xp_bonus", 4, 10, "book", None, "Kahramanlar Okulu", "School of Heroes"),
        ("item_find", 5, 10, "bag", None, "Hazine Avcısı", "Treasure Hunter"),
        ("legendary_find", 1, 10, "crown", None, "Efsane Avcısı", "Legend Seeker"),
        ("gold_find", 6, 10, "gold", None, "Altın Dağı", "Mountain of Gold"),
        ("chest_find", 8, 10, "chest", None, "Hazine Odası", "Treasure Vault"),
        ("pet_dmg", 6, 10, "heart", None, "Evcil Dostlar", "Loyal Pets"),
        ("xp_bonus", 5, 10, "book", None, "Bilge Rehber", "Wise Guide"),
        ("legendary_find", 1.5, 10, "sparkle", None, "Kahin", "Seer"),
        ("item_find", 6, 10, "bag", None, "Koleksiyoncu", "Collector"),
        ("chest_find", 30, 1, "chest", None, "Kraliyet Hazinesi", "Royal Treasury"),
    ]),
]
LINE = 10
SIDES = (2, 4, 6, 8)


def build():
    nodes = {"core": {"x": 0, "y": 0, "stat": "added_dmg", "per": 3, "max": 1, "glyph": "rune", "links": [], "br": "",
                      "name": {"tr": "Komutan Mührü", "en": "Commander's Seal"}}}
    brs = []
    for key, tr, en, col, (dx, dy), runes in BRANCHES:
        brs.append({"key": key, "name": {"tr": tr, "en": en}, "color": col})
        px, py = -dy, dx

        def put(nid, x, y, rune, links, cap=False):
            st, per, mx, gl, cls, ntr, nen = rune
            nodes[nid] = {"x": x, "y": y, "stat": st, "per": per, "max": mx, "glyph": gl, "links": links, "br": key,
                          "name": {"tr": ntr, "en": nen}}
            if cls:
                nodes[nid]["cls"] = cls
            if cap:
                nodes[nid]["cap"] = True
        prev = "core"
        for i in range(LINE):
            nid = "%s%d" % (key, i + 1)
            put(nid, dx * (i + 1), dy * (i + 1), runes[i], [prev])
            prev = nid
        for j, base in enumerate(SIDES):
            side = 1 if j % 2 == 0 else -1
            put("%s_s%d" % (key, j + 1), dx * base + px * side, dy * base + py * side, runes[LINE + j], ["%s%d" % (key, base)])
        put(key + "_cap", dx * (LINE + 1), dy * (LINE + 1), runes[LINE + 4], [key + str(LINE)], True)
    return {"branches": brs, "nodes": nodes}


if __name__ == "__main__":
    data = build()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print("runes:", len(data["nodes"]))
