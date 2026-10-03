#!/usr/bin/env python3
"""Class rune trees -> game/data/runes.json

Every class gets its own tree: a core rune and three themed branches. A branch is five runes in a line,
one side rune off its middle and a capstone at its end (one rank, big effect). Branch directions differ per
class so the trees also look different.

  python3 tools/data/gen_runes.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "data", "runes.json")

R, L, U, D = (1, 0), (-1, 0), (0, -1), (0, 1)

# entry: (stat, per rank, max rank, glyph, tr, en)
# branch: (key, tr, en, colour, direction, [5 line runes, side rune, capstone])
CLASSES = {
    "knight": ("rune", [
        ("bulwark", "Kale", "Bulwark", "#6FB7FF", L, [
            ("hp_pct", 3, 5, "heart", "Demir Beden", "Iron Body"),
            ("def_pct", 4, 5, "shield", "Kalkan Duvarı", "Shield Wall"),
            ("block", 1.5, 5, "lock", "Siper", "Bulwark"),
            ("dr", 0.6, 5, "tower", "Sarsılmaz", "Unshakeable"),
            ("hp_pct", 4, 5, "heart", "Dev Yürek", "Giant's Heart"),
            ("thorns", 4, 5, "spikes", "Dikenli Zırh", "Thorned Plate"),
            ("cheat_death", 1, 1, "cross", "Son Direniş", "Last Stand")]),
        ("blade", "Kılıç", "Blade", "#FF8A4A", R, [
            ("added_dmg", 3, 5, "sword", "Keskin Kılıç", "Keen Blade"),
            ("attack_speed", 2, 5, "bolt", "Hızlı Darbe", "Swift Strike"),
            ("phys_dmg", 4, 5, "hammer", "Ağır Vuruş", "Heavy Blow"),
            ("crit_chance", 1, 5, "target", "Gedik Bulan", "Gap Finder"),
            ("stun_chance", 2, 5, "star", "Kalkan Darbesi", "Shield Slam"),
            ("crit_dmg", 6, 5, "claw", "Cellat", "Headsman"),
            ("attack_pct", 12, 1, "crown", "Kral Kılıcı", "King's Sword")]),
        ("oath", "Yemin", "Oath", "#FFD35A", U, [
            ("all_res", 2, 5, "gem", "Kutsal Zırh", "Blessed Armour"),
            ("hp_regen_pct", 0.2, 5, "plus", "Toparlanma", "Recovery"),
            ("revive_speed", 6, 5, "cross", "Yeniden Doğuş", "Rebirth"),
            ("xp_bonus", 4, 5, "book", "Usta Eğitimi", "Master's Drill"),
            ("ult_charge", 5, 5, "potion", "Yemin Ateşi", "Oathfire"),
            ("gold_find", 5, 5, "gold", "Lonca Payı", "Guild Share"),
            ("ult_dmg", 30, 1, "sparkle", "Adalet Kılıcı", "Sword of Justice")]),
    ]),
    "berserker": ("claw", [
        ("rage", "Öfke", "Rage", "#FF5A4A", R, [
            ("added_dmg", 4, 5, "sword", "Kızgın Kan", "Hot Blood"),
            ("rage_dmg", 5, 5, "flame", "Kudurmuşluk", "Frenzy"),
            ("attack_speed", 2.5, 5, "bolt", "Çılgın Hız", "Mad Pace"),
            ("crit_dmg", 8, 5, "claw", "Parçalayıcı", "Ripper"),
            ("phys_dmg", 5, 5, "hammer", "Dev Balta", "Great Axe"),
            ("bleed_chance", 4, 5, "drop", "Yarılma", "Lacerate"),
            ("attack_pct", 15, 1, "crown", "Ragnarok", "Ragnarok")]),
        ("blood", "Kan", "Blood", "#C83A5A", L, [
            ("lifesteal", 0.4, 5, "drop", "Kana Susamış", "Bloodthirst"),
            ("hp_pct", 4, 5, "heart", "Kalın Deri", "Thick Hide"),
            ("dr", 0.5, 5, "tower", "Acı Bilmez", "Painless"),
            ("hp_regen_pct", 0.25, 5, "plus", "Vahşi Bünye", "Wild Vigour"),
            ("lifesteal", 0.6, 5, "drop", "Kan Ziyafeti", "Blood Feast"),
            ("evasion", 1.5, 5, "boot", "Çevik Dövüşçü", "Nimble Brawler"),
            ("cheat_death", 1, 1, "skull", "Ölümsüz Öfke", "Undying Rage")]),
        ("storm", "Fırtına", "Storm", "#FFD35A", D, [
            ("aoe_dmg", 5, 5, "star", "Kasırga", "Whirlwind"),
            ("crit_chance", 1, 5, "target", "Gözü Dönmüş", "Seeing Red"),
            ("elite_dmg", 6, 5, "flag", "Dev Avcısı", "Giant Hunter"),
            ("boss_dmg", 6, 5, "skull", "Kral Katili", "Kingslayer"),
            ("gold_find", 5, 5, "gold", "Yağmacı", "Raider"),
            ("item_find", 5, 5, "bag", "Ganimetçi", "Looter"),
            ("aoe_dmg", 30, 1, "bolt", "Gök Gürültüsü", "Thunderclap")]),
    ]),
    "archer": ("arrow", [
        ("hawk", "Şahin", "Hawk", "#7CE07A", R, [
            ("added_dmg", 3, 5, "arrow", "Gergin Yay", "Taut String"),
            ("crit_chance", 1.2, 5, "target", "Kartal Gözü", "Eagle Eye"),
            ("penetrate", 2, 5, "arrow", "Delici Uç", "Piercing Tip"),
            ("crit_dmg", 7, 5, "claw", "Nişancı", "Marksman"),
            ("boss_dmg", 6, 5, "skull", "Dev Avı", "Big Game"),
            ("elite_dmg", 6, 5, "flag", "Avcı Ödülü", "Bounty"),
            ("crit_dmg", 40, 1, "sparkle", "Yıldızkıran", "Starbreaker")]),
        ("wind", "Rüzgâr", "Wind", "#7FE8FF", U, [
            ("attack_speed", 2.5, 5, "bolt", "Hızlı Çekiş", "Quick Draw"),
            ("evasion", 2, 5, "boot", "Rüzgâr Adımı", "Wind Step"),
            ("aoe_dmg", 5, 5, "star", "Ok Yağmuru", "Arrow Rain"),
            ("attack_speed", 3, 5, "bolt", "Seri Atış", "Rapid Fire"),
            ("skill_dmg", 5, 5, "flame", "Fırtına Oku", "Storm Arrow"),
            ("cdr", 1.5, 5, "clock", "Soğukkanlı", "Cool Head"),
            ("attack_pct", 12, 1, "crown", "Rüzgârın Efendisi", "Windlord")]),
        ("wild", "Yaban", "Wild", "#FFD35A", L, [
            ("hp_pct", 3, 5, "heart", "Ormanın Çocuğu", "Child of the Wood"),
            ("pet_dmg", 8, 5, "heart", "Kurt Dostu", "Wolf Friend"),
            ("item_find", 5, 5, "bag", "İz Sürücü", "Tracker"),
            ("chest_find", 10, 5, "chest", "Define Avcısı", "Treasure Hunter"),
            ("xp_bonus", 4, 5, "book", "Gezgin", "Wanderer"),
            ("all_res", 2, 5, "gem", "Doğanın Koruması", "Nature's Ward"),
            ("legendary_find", 3, 1, "crown", "Efsane İzi", "Legend's Trail")]),
    ]),
    "assassin": ("claw", [
        ("shadow", "Gölge", "Shadow", "#B48CFF", R, [
            ("crit_chance", 1.2, 5, "target", "Sinsi", "Sneaky"),
            ("crit_dmg", 8, 5, "claw", "Ölümcül Hassasiyet", "Lethal Precision"),
            ("execute_dmg", 6, 5, "skull", "İnfaz", "Execute"),
            ("night_dmg", 6, 5, "eye", "Gece Avcısı", "Night Hunter"),
            ("penetrate", 2, 5, "arrow", "Zayıf Nokta", "Weak Spot"),
            ("boss_dmg", 6, 5, "crown", "Suikast", "Assassination"),
            ("crit_dmg", 45, 1, "sparkle", "Ay Tutulması", "Eclipse")]),
        ("venom", "Zehir", "Venom", "#7CE07A", D, [
            ("chaos_dmg", 5, 5, "drop", "Zehirli Bıçak", "Poisoned Blade"),
            ("status_chance", 3, 5, "star", "Bulaşıcı", "Contagion"),
            ("poison_dmg", 8, 5, "drop", "Veba", "Plague"),
            ("attack_speed", 2.5, 5, "bolt", "Çift Bıçak", "Dual Wield"),
            ("aoe_dmg", 5, 5, "star", "Veba Bulutu", "Plague Cloud"),
            ("weaken_chance", 3, 5, "skull", "Zayıflatan", "Enfeeble"),
            ("poison_dmg", 40, 1, "flame", "Kara Ölüm", "Black Death")]),
        ("veil", "Peçe", "Veil", "#FFD35A", L, [
            ("evasion", 2, 5, "boot", "Gölge Pelerini", "Shadow Cloak"),
            ("lifesteal", 0.4, 5, "drop", "Kan Bedeli", "Blood Price"),
            ("hp_pct", 3, 5, "heart", "Tetikte", "Alert"),
            ("gold_find", 5, 5, "gold", "Yankesici", "Pickpocket"),
            ("chest_find", 10, 5, "chest", "Kilit Ustası", "Lockpick"),
            ("item_find", 5, 5, "bag", "Hırsız", "Thief"),
            ("cheat_death", 1, 1, "cross", "Kaçış", "Vanish")]),
    ]),
    "mage": ("flame", [
        ("fire", "Ateş", "Fire", "#FF7A3A", R, [
            ("fire_dmg", 5, 5, "flame", "Kor", "Ember"),
            ("burn_dmg", 8, 5, "flame", "Yakıcı", "Scorch"),
            ("aoe_dmg", 5, 5, "star", "Alev Halkası", "Ring of Fire"),
            ("fire_dmg", 6, 5, "flame", "Cehennem", "Inferno"),
            ("skill_dmg", 6, 5, "rune", "Meteor", "Meteor"),
            ("crit_dmg", 7, 5, "claw", "Patlama", "Combustion"),
            ("fire_dmg", 40, 1, "sparkle", "Ejderha Nefesi", "Dragon's Breath")]),
        ("arcane", "Gizem", "Arcane", "#C58BFF", U, [
            ("spell_pct", 4, 5, "book", "Odak", "Focus"),
            ("cast_speed", 3, 5, "bolt", "Hız Büyüsü", "Haste"),
            ("cdr", 1.5, 5, "clock", "Döngü", "Cycle"),
            ("elem_dmg", 5, 5, "gem", "Uyum", "Attunement"),
            ("ult_charge", 5, 5, "potion", "Mana Pınarı", "Wellspring"),
            ("crit_chance", 1, 5, "target", "Kristal Zihin", "Crystal Mind"),
            ("spell_pct", 15, 1, "crown", "Başbüyücü", "Archmage")]),
        ("ward", "Kalkan", "Ward", "#7FB3FF", L, [
            ("hp_pct", 3, 5, "heart", "Mana Kalkanı", "Mana Shield"),
            ("all_res", 2.5, 5, "gem", "Element Koruması", "Elemental Ward"),
            ("dr", 0.5, 5, "tower", "Buz Zırhı", "Ice Armour"),
            ("xp_bonus", 5, 5, "book", "Âlim", "Scholar"),
            ("hp_regen_pct", 0.2, 5, "plus", "Yenilenme", "Renewal"),
            ("item_find", 5, 5, "bag", "Simyacı", "Alchemist"),
            ("cheat_death", 1, 1, "cross", "Zaman Bükümü", "Time Warp")]),
    ]),
    "necromancer": ("skull", [
        ("legion", "Lejyon", "Legion", "#9FE07A", R, [
            ("summon_dmg", 6, 5, "people", "İskelet Ordusu", "Skeleton Army"),
            ("summon_hp", 6, 5, "heart", "Kemik Zırh", "Bone Armour"),
            ("summon_dmg", 7, 5, "people", "Golem", "Golem"),
            ("aoe_dmg", 5, 5, "star", "Ceset Patlaması", "Corpse Explosion"),
            ("summon_dmg", 8, 5, "people", "Lejyon", "Legion"),
            ("summon_hp", 8, 5, "tower", "Kemik Kale", "Bone Fortress"),
            ("max_summons", 1, 1, "crown", "Ölüler Hükümdarı", "Sovereign of the Dead")]),
        ("curse", "Lanet", "Curse", "#B48CFF", D, [
            ("chaos_dmg", 5, 5, "drop", "Kara Büyü", "Dark Magic"),
            ("weaken_chance", 3, 5, "skull", "Lanet", "Curse"),
            ("poison_dmg", 8, 5, "drop", "Çürüme", "Rot"),
            ("spell_pct", 4, 5, "book", "Yasak Bilgi", "Forbidden Lore"),
            ("skill_dmg", 6, 5, "rune", "Kemik Mızrak", "Bone Spear"),
            ("lifesteal", 0.4, 5, "drop", "Ruh Emme", "Drain"),
            ("chaos_dmg", 40, 1, "sparkle", "Kıyamet", "Doom")]),
        ("grave", "Mezar", "Grave", "#FFD35A", L, [
            ("hp_pct", 3, 5, "heart", "Soğuk Kan", "Cold Blood"),
            ("all_res", 2, 5, "gem", "Mezar Taşı", "Gravestone"),
            ("cdr", 1.5, 5, "clock", "Hasat", "Harvest"),
            ("xp_bonus", 5, 5, "book", "Ruh Hasadı", "Soul Harvest"),
            ("gold_find", 5, 5, "gold", "Mezar Soyguncusu", "Grave Robber"),
            ("chest_find", 10, 5, "chest", "Lahit", "Sarcophagus"),
            ("cheat_death", 1, 1, "cross", "Ölümden Dönüş", "Return from Death")]),
    ]),
    "cleric": ("cross", [
        ("light", "Işık", "Light", "#FFE07A", U, [
            ("heal_bonus", 6, 5, "plus", "Şifa", "Heal"),
            ("buff_duration", 6, 5, "clock", "Kutsama", "Blessing"),
            ("heal_bonus", 7, 5, "plus", "Toplu Şifa", "Mass Heal"),
            ("revive_speed", 8, 5, "cross", "Diriltme", "Resurrection"),
            ("ult_charge", 5, 5, "potion", "Mucize", "Miracle"),
            ("hp_regen_pct", 0.25, 5, "drop", "Arınma", "Purify"),
            ("heal_bonus", 35, 1, "sparkle", "Melek", "Angel")]),
        ("judgement", "Hüküm", "Judgement", "#FF8A4A", R, [
            ("holy_dmg", 5, 5, "star", "Kutsal Gürz", "Holy Mace"),
            ("spell_pct", 4, 5, "book", "İnanç", "Faith"),
            ("undead_dmg", 8, 5, "skull", "Ölümsüz Avcısı", "Undead Bane"),
            ("crit_chance", 1, 5, "target", "Hüküm", "Verdict"),
            ("skill_dmg", 6, 5, "rune", "Cennet Kapısı", "Heaven's Gate"),
            ("stun_chance", 2, 5, "star", "Çarpma", "Smite"),
            ("holy_dmg", 40, 1, "crown", "İlahi Gazap", "Divine Wrath")]),
        ("sanctuary", "Sığınak", "Sanctuary", "#6FB7FF", L, [
            ("hp_pct", 3, 5, "heart", "Işık Kalkanı", "Light Shield"),
            ("def_pct", 4, 5, "shield", "Kutsal Kalkan", "Holy Shield"),
            ("all_res", 2, 5, "gem", "Bilgelik", "Wisdom"),
            ("dr", 0.5, 5, "tower", "Huzur", "Serenity"),
            ("xp_bonus", 5, 5, "book", "Hacı", "Pilgrim"),
            ("gold_find", 5, 5, "gold", "Bağış", "Tithe"),
            ("cheat_death", 1, 1, "cross", "Gözyaşı", "Tear of the Goddess")]),
    ]),
    "bard": ("note", [
        ("song", "Şarkı", "Song", "#FFD35A", U, [
            ("buff_duration", 6, 5, "note", "Uzun Nakarat", "Long Refrain"),
            ("ult_charge", 5, 5, "potion", "Destan", "Epic"),
            ("cdr", 1.5, 5, "clock", "Ritim", "Rhythm"),
            ("buff_duration", 7, 5, "note", "Cesaret Marşı", "March of Courage"),
            ("heal_bonus", 6, 5, "plus", "Ninni", "Lullaby"),
            ("hp_regen_pct", 0.2, 5, "plus", "Huzur Şarkısı", "Song of Calm"),
            ("ult_dmg", 35, 1, "sparkle", "Efsaneler", "Legends")]),
        ("thunder", "Gök", "Thunder", "#7FE8FF", R, [
            ("lightning_dmg", 5, 5, "bolt", "Uyumsuzluk", "Discord"),
            ("spell_pct", 4, 5, "book", "Usta Parmaklar", "Nimble Fingers"),
            ("cast_speed", 3, 5, "bolt", "Davullar", "War Drums"),
            ("aoe_dmg", 5, 5, "star", "Koro", "Choir"),
            ("skill_dmg", 6, 5, "rune", "Gök Gürültüsü", "Thunder"),
            ("crit_chance", 1, 5, "target", "Doruk Notası", "High Note"),
            ("lightning_dmg", 40, 1, "crown", "Fırtına Senfonisi", "Storm Symphony")]),
        ("fortune", "Talih", "Fortune", "#7CE07A", L, [
            ("gold_find", 6, 5, "gold", "Altın Ses", "Golden Voice"),
            ("item_find", 6, 5, "bag", "Şans Şarkısı", "Lucky Tune"),
            ("chest_find", 12, 5, "chest", "Hazine Türküsü", "Treasure Ballad"),
            ("xp_bonus", 5, 5, "book", "Hikâye Anlatıcı", "Storyteller"),
            ("legendary_find", 1.5, 5, "crown", "Efsane Avcısı", "Legend Seeker"),
            ("hp_pct", 3, 5, "heart", "Neşe", "Joy"),
            ("legendary_find", 5, 1, "sparkle", "Altın Çağ", "Golden Age")]),
    ]),
}


# branch shapes per class (one per branch, in order): every class tree has its own silhouette
SHAPES = {
    "knight": ["line", "line", "line"],
    "berserker": ["zig", "zig", "bend"],
    "archer": ["diag", "diag_r", "line"],
    "assassin": ["bend", "zig", "bend_r"],
    "mage": ["zig", "line", "bend"],
    "necromancer": ["bend", "bend_r", "zig"],
    "cleric": ["line", "bend", "bend_r"],
    "bard": ["zig", "diag", "diag_r"],
}


def path(shape, d, p):
    """Five cumulative grid positions for a branch growing along d (p = perpendicular)."""
    dx, dy = d
    px, py = p
    out = []
    for i in range(1, 6):
        if shape == "line":
            out.append((dx * i, dy * i))
        elif shape == "zig":
            k = i % 2
            out.append((dx * i + px * k, dy * i + py * k))
        elif shape in ("bend", "bend_r"):
            s = 1 if shape == "bend" else -1
            if i <= 3:
                out.append((dx * i, dy * i))
            else:
                out.append((dx * 3 + px * s * (i - 3), dy * 3 + py * s * (i - 3)))
        elif shape in ("diag", "diag_r"):
            s = 1 if shape == "diag" else -1
            out.append((dx * i + px * s * min(i, 3), dy * i + py * s * min(i, 3)))
    return out


def build():
    out = {}
    for cls, (core_glyph, branches) in CLASSES.items():
        nodes = {"core": {"x": 0, "y": 0, "stat": "all_stats", "per": 3, "max": 1, "glyph": core_glyph, "links": [],
                          "br": "", "name": {"tr": "Öz Rün", "en": "Core Rune"}}}
        brs = []
        used = {(0, 0)}
        for bi, (key, tr, en, col, (dx, dy), runes) in enumerate(branches):
            brs.append({"key": key, "name": {"tr": tr, "en": en}, "color": col})
            px, py = -dy, dx
            shape = SHAPES[cls][bi]
            pts = path(shape, (dx, dy), (px, py))
            prev = "core"
            for i in range(5):
                st, per, mx, gl, ntr, nen = runes[i]
                nid = "%s%d" % (key, i + 1)
                nodes[nid] = {"x": pts[i][0], "y": pts[i][1], "stat": st, "per": per, "max": mx, "glyph": gl,
                              "links": [prev], "br": key, "name": {"tr": ntr, "en": nen}}
                prev = nid
            # side rune next to the 3rd, capstone past the 5th, each on a free cell
            def free_near(base, cands):
                for c in cands:
                    q = (base[0] + c[0], base[1] + c[1])
                    if q not in used and q not in pts:
                        return q
                raise SystemExit("no room in %s/%s" % (cls, key))
            for q in pts:
                if q in used:
                    raise SystemExit("overlap in %s/%s at %s" % (cls, key, q))
                used.add(q)
            side = free_near(pts[2], [(-px, -py), (px, py), (dx, dy)])
            used.add(side)
            last = pts[4]
            step = (pts[4][0] - pts[3][0], pts[4][1] - pts[3][1])
            cap = free_near(last, [step, (dx, dy), (px, py), (-px, -py)])
            used.add(cap)
            st, per, mx, gl, ntr, nen = runes[5]
            nodes[key + "_side"] = {"x": side[0], "y": side[1], "stat": st, "per": per, "max": mx, "glyph": gl,
                                   "links": [key + "3"], "br": key, "name": {"tr": ntr, "en": nen}}
            st, per, mx, gl, ntr, nen = runes[6]
            nodes[key + "_cap"] = {"x": cap[0], "y": cap[1], "stat": st, "per": per, "max": mx, "glyph": gl,
                                  "links": [key + "5"], "br": key, "cap": True, "name": {"tr": ntr, "en": nen}}
        out[cls] = {"branches": brs, "nodes": nodes}
    return out


if __name__ == "__main__":
    data = build()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print("classes:", len(data), "nodes:", sum(len(v["nodes"]) for v in data.values()))
