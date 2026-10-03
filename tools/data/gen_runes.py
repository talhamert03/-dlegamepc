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

# rune: (stat, per rank, max rank, glyph, classes or None, tr, en)
BRANCHES = [
    ("academy", "Büyü Akademisi", "Arcane Academy", "#B48CFF", U, [
        ("spell_pct", 4, 5, "book", CASTERS, "Büyü Dersleri", "Spell Lessons"),
        ("fire_dmg", 6, 5, "flame", ["mage"], "Büyücü: Ateş Ustalığı", "Mage: Fire Mastery"),
        ("cast_speed", 3, 5, "bolt", CASTERS, "Hızlı Büyü", "Quick Casting"),
        ("summon_dmg", 8, 5, "people", ["necromancer"], "Nekromant: Ölü Ordusu", "Necromancer: Army of the Dead"),
        ("skill_dmg", 5, 5, "rune", CASTERS, "Kadim Formüller", "Ancient Formulae"),
        ("cdr", 1.5, 5, "clock", CASTERS, "Mana Akışı", "Mana Flow"),
        ("lightning_dmg", 8, 5, "bolt", ["bard"], "Ozan: Gök Ezgisi", "Bard: Sky Song"),
        ("crit_chance", 1, 5, "target", CASTERS, "Kristal Odak", "Crystal Focus"),
        ("spell_pct", 15, 1, "crown", CASTERS, "Başbüyücü Kürsüsü", "Archmage's Chair"),
    ]),
    ("war", "Savaş Okulu", "War College", "#FF8A4A", R, [
        ("attack_pct", 4, 5, "sword", MARTIAL, "Silah Talimi", "Weapon Drill"),
        ("attack_speed", 2, 5, "bolt", ["archer", "assassin"], "Okçu & Suikastçı: Çevik El", "Archer & Assassin: Quick Hands"),
        ("crit_chance", 1, 5, "target", MARTIAL, "Zayıf Noktalar", "Weak Points"),
        ("hp_pct", 5, 5, "heart", ["knight", "berserker"], "Şövalye & Barbar: Demir Beden", "Knight & Berserker: Iron Body"),
        ("crit_dmg", 8, 5, "claw", MARTIAL, "Ölümcül Darbe", "Deadly Blow"),
        ("boss_dmg", 6, 5, "skull", None, "Dev Avcıları", "Giant Hunters"),
        ("penetrate", 2, 5, "arrow", ["archer"], "Okçu: Delici Ok", "Archer: Piercing Shot"),
        ("elite_dmg", 6, 5, "flag", None, "Elit Avı", "Elite Hunt"),
        ("attack_pct", 15, 1, "crown", MARTIAL, "Savaş Lordu", "Warlord"),
    ]),
    ("guard", "Muhafız Kalesi", "Warden's Keep", "#6FB7FF", L, [
        ("hp_pct", 3, 5, "heart", None, "Sağlam Saflar", "Firm Ranks"),
        ("heal_bonus", 6, 5, "plus", ["cleric", "bard"], "Rahip & Ozan: Şifa Bilgisi", "Cleric & Bard: Healing Lore"),
        ("def_pct", 4, 5, "shield", None, "Kalkan Duvarı", "Shield Wall"),
        ("block", 1.5, 5, "lock", ["knight"], "Şövalye: Siper", "Knight: Bulwark"),
        ("all_res", 2, 5, "gem", None, "Element Muskası", "Elemental Charm"),
        ("revive_speed", 8, 5, "cross", None, "Saha Hekimi", "Field Medic"),
        ("buff_duration", 6, 5, "note", ["bard", "cleric"], "Uzun Kutsama", "Long Blessing"),
        ("dr", 0.5, 5, "tower", None, "Sarsılmaz", "Unshakeable"),
        ("cheat_death", 1, 1, "cross", None, "Son Direniş", "Last Stand"),
    ]),
    ("guild", "Hazine Loncası", "Treasure Guild", "#FFD35A", D, [
        ("gold_find", 5, 5, "gold", None, "Lonca Kesesi", "Guild Purse"),
        ("xp_bonus", 4, 5, "book", None, "Usta Eğitmenler", "Master Trainers"),
        ("item_find", 5, 5, "bag", None, "Ganimet Gözü", "Loot Eye"),
        ("chest_find", 10, 5, "chest", None, "Define Haritaları", "Treasure Maps"),
        ("gold_find", 6, 5, "gold", None, "Pazarlıkçı", "Haggler"),
        ("legendary_find", 1.5, 5, "crown", None, "Efsane Avcısı", "Legend Seeker"),
        ("pet_dmg", 10, 5, "heart", None, "Evcil Dostlar", "Loyal Pets"),
        ("xp_bonus", 6, 5, "book", None, "Kahramanlar Okulu", "School of Heroes"),
        ("chest_find", 25, 1, "chest", None, "Kraliyet Hazinesi", "Royal Treasury"),
    ]),
]


def build():
    nodes = {"core": {"x": 0, "y": 0, "stat": "added_dmg", "per": 3, "max": 1, "glyph": "rune", "links": [], "br": "",
                      "name": {"tr": "Komutan Mührü", "en": "Commander's Seal"}}}
    brs = []
    for key, tr, en, col, (dx, dy), runes in BRANCHES:
        brs.append({"key": key, "name": {"tr": tr, "en": en}, "color": col})
        px, py = -dy, dx
        line = runes[:6]
        prev = "core"
        for i, (st, per, mx, gl, cls, ntr, nen) in enumerate(line):
            nid = "%s%d" % (key, i + 1)
            nodes[nid] = {"x": dx * (i + 1), "y": dy * (i + 1), "stat": st, "per": per, "max": mx, "glyph": gl,
                          "links": [prev], "br": key, "name": {"tr": ntr, "en": nen}}
            if cls:
                nodes[nid]["cls"] = cls
            prev = nid
        for j, (base, side) in enumerate(((2, 1), (4, -1))):
            st, per, mx, gl, cls, ntr, nen = runes[6 + j]
            nid = "%s_s%d" % (key, j + 1)
            nodes[nid] = {"x": dx * base + px * side, "y": dy * base + py * side, "stat": st, "per": per, "max": mx,
                          "glyph": gl, "links": ["%s%d" % (key, base)], "br": key, "name": {"tr": ntr, "en": nen}}
            if cls:
                nodes[nid]["cls"] = cls
        st, per, mx, gl, cls, ntr, nen = runes[8]
        nid = key + "_cap"
        nodes[nid] = {"x": dx * 7, "y": dy * 7, "stat": st, "per": per, "max": mx, "glyph": gl, "links": [key + "6"],
                      "br": key, "cap": True, "name": {"tr": ntr, "en": nen}}
        if cls:
            nodes[nid]["cls"] = cls
    return {"branches": brs, "nodes": nodes}


if __name__ == "__main__":
    data = build()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print("runes:", len(data["nodes"]))
