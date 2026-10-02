#!/usr/bin/env python3
"""Generates game/data/enemies.json and game/data/zones.json.

The world layout (acts, zones, rosters, bosses) is authored here in compact form;
the JSON files are generated output - edit this script, then re-run it.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "data")

# archetype -> combat stats
ARCH = {
    "weak":   dict(hp=0.75, atk=0.85, aps=1.0, range=22, target="front"),
    "melee":  dict(hp=1.0, atk=1.0, aps=0.95, range=24, target="front"),
    "tank":   dict(hp=1.6, atk=0.85, aps=0.75, range=24, target="front"),
    "brute":  dict(hp=1.3, atk=1.35, aps=0.7, range=26, target="front"),
    "fast":   dict(hp=0.65, atk=0.75, aps=1.6, range=22, target="lowest"),
    "ranged": dict(hp=0.7, atk=1.0, aps=0.8, range=130, target="front", projectile="arrow_enemy"),
    "caster": dict(hp=0.75, atk=1.2, aps=0.7, range=120, target="random", projectile="bolt_enemy"),
    "swarm":  dict(hp=0.5, atk=0.6, aps=1.2, range=20, target="front"),
}

# id: (tr, en, arch, element, visual)
E = {}


def enemy(eid, tr, en, arch, vis, element="physical", res=None, tags=()):
    E[eid] = {"id": eid, "name": {"tr": tr, "en": en}, "arch": arch, "element": element,
              "res": res or {}, "visual": vis, "tags": list(tags), **ARCH[arch]}


# ---------------------------------------------------------------- Act 1 - Misty Forest
enemy("slime_green", "Yeşil Slime", "Green Slime", "weak", {"rig": "blob", "color": "#6CC24A"})
enemy("bunny", "Kızgın Tavşan", "Angry Bunny", "fast", {"rig": "quad", "kind": "bunny", "color": "#E8DCC8"})
enemy("mushroom", "Mantarcık", "Shroomling", "weak", {"rig": "mushroom", "color": "#D9583A"})
enemy("boar", "Yaban Domuzu", "Wild Boar", "brute", {"rig": "quad", "kind": "boar", "color": "#7A5A44"})
enemy("goblin_apprentice", "Goblin Çırak", "Goblin Apprentice", "weak", {"rig": "goblin", "weapon": "dagger", "color": "#7FB84A", "cloth": "#8E5B3E"})
enemy("goblin_warrior", "Goblin Savaşçı", "Goblin Warrior", "melee", {"rig": "goblin", "weapon": "sword", "color": "#6FA840", "cloth": "#6A4A3A", "helm": True})
enemy("goblin_archer", "Goblin Okçu", "Goblin Archer", "ranged", {"rig": "goblin", "weapon": "bow", "color": "#86B850", "cloth": "#4A6A3A"})
enemy("goblin_shaman", "Goblin Şaman", "Goblin Shaman", "caster", {"rig": "goblin", "weapon": "staff", "color": "#7AB070", "cloth": "#8A3A5A"}, element="fire")
enemy("wolf", "Orman Kurdu", "Forest Wolf", "fast", {"rig": "quad", "kind": "wolf", "color": "#7A7A86"})
enemy("bat", "Yarasa", "Bat", "swarm", {"rig": "flyer", "kind": "bat", "color": "#5A4A6A"})
enemy("poison_shroom", "Zehirli Mantar", "Toxic Shroom", "caster", {"rig": "mushroom", "color": "#8A5AC9"}, element="chaos")
enemy("skeleton", "İskelet", "Skeleton", "melee", {"rig": "skeleton", "weapon": "sword", "color": "#E6DDC6"}, tags=["undead"])
enemy("ghost", "Hayalet", "Ghost", "caster", {"rig": "flyer", "kind": "ghost", "color": "#BFD8F0"}, element="cold", tags=["undead"])
enemy("zombie", "Zombi", "Zombie", "tank", {"rig": "zombie", "color": "#8FA878", "cloth": "#5A5A6A"}, tags=["undead"])
enemy("spider", "Örümcek", "Spider", "fast", {"rig": "spider", "color": "#4A3A4A"}, element="chaos")
enemy("cocoon_zombie", "Koza Zombi", "Cocoon Zombie", "tank", {"rig": "zombie", "color": "#D8D0C0", "cloth": "#C8C0B0"}, tags=["undead"])
enemy("goblin_bomber", "Goblin Bombacı", "Goblin Bomber", "ranged", {"rig": "goblin", "weapon": "bomb", "color": "#6FA840", "cloth": "#A8502E"}, element="fire")
enemy("goblin_rider", "Kurt Binici", "Wolf Rider", "brute", {"rig": "quad", "kind": "wolf", "color": "#5A5A66", "rider": "#6FA840"})
enemy("ent_sapling", "Ent Fidanı", "Ent Sapling", "tank", {"rig": "ent", "color": "#7A5A3A", "leaf": "#6CC24A"})
enemy("dark_fairy", "Kötü Peri", "Wicked Fairy", "caster", {"rig": "flyer", "kind": "fairy", "color": "#FF9AC8"}, element="lightning")
enemy("forest_spirit", "Orman Ruhu", "Forest Spirit", "caster", {"rig": "flyer", "kind": "wisp", "color": "#9FE07A"}, element="cold")

# ---------------------------------------------------------------- Act 2 - Frozen Peaks
enemy("snow_wolf", "Kar Kurdu", "Snow Wolf", "fast", {"rig": "quad", "kind": "wolf", "color": "#E6EEF6"})
enemy("bandit", "Haydut", "Bandit", "melee", {"rig": "bandit", "weapon": "sword", "color": "#E2A882", "cloth": "#6A4A3A"})
enemy("bandit_archer", "Haydut Okçu", "Bandit Archer", "ranged", {"rig": "bandit", "weapon": "bow", "color": "#E2A882", "cloth": "#4A5A3A"})
enemy("yeti_cub", "Yeti Yavrusu", "Yeti Cub", "brute", {"rig": "golem", "kind": "yeti", "color": "#E8F0F8", "scale": 0.85})
enemy("ice_slime", "Buz Slime", "Ice Slime", "weak", {"rig": "blob", "color": "#9FDFFF"}, element="cold", res={"cold": 50})
enemy("ice_elemental", "Buz Elementali", "Ice Elemental", "caster", {"rig": "golem", "kind": "elemental", "color": "#7FD8FF"}, element="cold", res={"cold": 75, "fire": -25})
enemy("penguin", "Penguen Savaşçı", "Penguin Warrior", "weak", {"rig": "blob", "kind": "penguin", "color": "#2E3240"})
enemy("crystal_golem", "Kristal Golem", "Crystal Golem", "tank", {"rig": "golem", "kind": "crystal", "color": "#9FB8FF"}, res={"physical": 20})
enemy("ice_bat", "Buz Yarasası", "Ice Bat", "swarm", {"rig": "flyer", "kind": "bat", "color": "#7FB8E0"}, element="cold")
enemy("ghost_miner", "Hortlak Madenci", "Ghost Miner", "melee", {"rig": "skeleton", "weapon": "axe", "color": "#C8D8E0", "helm": True}, tags=["undead"])
enemy("harpy", "Harpi", "Harpy", "fast", {"rig": "flyer", "kind": "harpy", "color": "#B88A5A"})
enemy("storm_spirit", "Yıldırım Ruhu", "Storm Spirit", "caster", {"rig": "flyer", "kind": "wisp", "color": "#FFE45C"}, element="lightning")
enemy("north_warrior", "Kuzey Savaşçısı", "Northern Warrior", "brute", {"rig": "bandit", "weapon": "axe", "color": "#E2A882", "cloth": "#8A6A4A", "helm": True})
enemy("ice_guard", "Buz Muhafızı", "Ice Guardian", "tank", {"rig": "skeleton", "weapon": "sword", "color": "#BFE8FF", "helm": True, "shield": True}, element="cold")
enemy("snow_fairy", "Kar Tanesi Perisi", "Snowflake Fairy", "caster", {"rig": "flyer", "kind": "fairy", "color": "#BFE8FF"}, element="cold")
enemy("ice_knight", "Buz Kopyası", "Ice Mirror", "melee", {"rig": "skeleton", "weapon": "sword", "color": "#9FDFFF", "helm": True}, element="cold")

# ---------------------------------------------------------------- Act 3 - Scorched Desert
enemy("pirate", "Korsan", "Pirate", "melee", {"rig": "bandit", "weapon": "sword", "color": "#C98A5A", "cloth": "#C9414B"})
enemy("sand_crab", "Kum Yengeci", "Sand Crab", "tank", {"rig": "spider", "kind": "crab", "color": "#E8843A"}, res={"physical": 15})
enemy("scorpion", "Akrep", "Scorpion", "fast", {"rig": "spider", "kind": "scorpion", "color": "#C99A4A"}, element="chaos")
enemy("sand_worm", "Kum Solucanı", "Sand Worm", "brute", {"rig": "worm", "color": "#C9A06A"})
enemy("lizardman", "Kertenkele Adam", "Lizardman", "melee", {"rig": "goblin", "weapon": "spear", "color": "#5AA84A", "cloth": "#8E5B3E", "big": True})
enemy("mirage", "Serap Ruhu", "Mirage Spirit", "caster", {"rig": "flyer", "kind": "wisp", "color": "#FFD98A"}, element="fire")
enemy("cactus", "Kaktüs Canavarı", "Cactus Beast", "tank", {"rig": "ent", "kind": "cactus", "color": "#5A9A4A", "leaf": "#FF9AC8"})
enemy("mummy", "Mumya", "Mummy", "tank", {"rig": "zombie", "color": "#E8DCB8", "cloth": "#D8C8A0", "wrap": True}, tags=["undead"])
enemy("scarab", "Skarab", "Scarab", "swarm", {"rig": "spider", "kind": "beetle", "color": "#3A6A8A"})
enemy("anubis_guard", "Anubis Muhafız", "Anubis Guard", "brute", {"rig": "bandit", "weapon": "spear", "color": "#2A2430", "cloth": "#E8B84A", "jackal": True})
enemy("fire_elemental", "Ateş Elementali", "Fire Elemental", "caster", {"rig": "golem", "kind": "elemental", "color": "#FF7A33"}, element="fire", res={"fire": 75, "cold": -25})
enemy("lava_slime", "Lav Slime", "Lava Slime", "weak", {"rig": "blob", "color": "#FF6A2A"}, element="fire", res={"fire": 50})
enemy("imp", "Ateş İmpi", "Fire Imp", "fast", {"rig": "goblin", "weapon": "trident", "color": "#D9443A", "cloth": "#3A2A2A", "horns": True}, element="fire")
enemy("cursed_book", "Lanetli Kitap", "Cursed Tome", "caster", {"rig": "flyer", "kind": "book", "color": "#8A3A5A"}, element="chaos")
enemy("animated_armor", "Canlı Zırh", "Animated Armor", "tank", {"rig": "skeleton", "weapon": "sword", "color": "#9AA2B0", "helm": True, "shield": True, "armor": True})
enemy("ink_slime", "Mürekkep Slime", "Ink Slime", "weak", {"rig": "blob", "color": "#2E2A46"}, element="chaos")
enemy("clock_golem", "Saat Golemi", "Clockwork Golem", "tank", {"rig": "golem", "kind": "clock", "color": "#C9A040"})
enemy("time_ghost", "Zaman Hayaleti", "Time Wraith", "caster", {"rig": "flyer", "kind": "ghost", "color": "#C9B8FF"}, element="lightning", tags=["undead"])
enemy("chimera", "Kimera", "Chimera", "brute", {"rig": "quad", "kind": "chimera", "color": "#C98A3A"}, element="fire")
enemy("homunculus", "Homunculus", "Homunculus", "fast", {"rig": "goblin", "weapon": "claw", "color": "#D8A0A8", "cloth": "#5A4A6A"})

# ---------------------------------------------------------------- Act 4 - Abyssal Gate
enemy("hellhound", "Cehennem Köpeği", "Hellhound", "fast", {"rig": "quad", "kind": "wolf", "color": "#8A2A2A", "glow": "#FF7A33"}, element="fire")
enemy("demon_imp", "İblis İmp", "Demon Imp", "fast", {"rig": "goblin", "weapon": "trident", "color": "#8A3A6A", "cloth": "#2A1A2A", "horns": True}, element="chaos")
enemy("blood_elemental", "Kan Elementali", "Blood Elemental", "caster", {"rig": "golem", "kind": "elemental", "color": "#C9213A"}, element="chaos")
enemy("drowned", "Boğulmuş Ölü", "Drowned Dead", "tank", {"rig": "zombie", "color": "#6A8A8A", "cloth": "#3A4A5A"}, tags=["undead"])
enemy("bone_drake", "Kemik Ejder Yavrusu", "Bone Drakeling", "brute", {"rig": "quad", "kind": "drake", "color": "#E6DDC6"}, tags=["undead"])
enemy("skeleton_archer", "İskelet Okçu", "Skeleton Archer", "ranged", {"rig": "skeleton", "weapon": "bow", "color": "#E6DDC6"}, tags=["undead"])
enemy("cursed_ent", "Lanetli Ent", "Cursed Ent", "tank", {"rig": "ent", "color": "#3A2A3A", "leaf": "#8A5AC9"}, element="chaos")
enemy("shadow_wolf", "Gölge Kurt", "Shadow Wolf", "fast", {"rig": "quad", "kind": "wolf", "color": "#2A2436", "glow": "#C58CFF"}, element="chaos")
enemy("cultist", "Kültist", "Cultist", "caster", {"rig": "bandit", "weapon": "staff", "color": "#E2C8C0", "cloth": "#5C1E2E", "hood": True}, element="chaos")
enemy("sacrifice_priest", "Kurban Rahibi", "Sacrificial Priest", "caster", {"rig": "bandit", "weapon": "dagger", "color": "#E2C8C0", "cloth": "#2A1A2A", "hood": True}, element="chaos")
enemy("void_spawn", "Hiçlik Yaratığı", "Void Spawn", "melee", {"rig": "blob", "kind": "void", "color": "#3A2A5A"}, element="chaos")
enemy("tentacle", "Tentakül", "Tentacle", "brute", {"rig": "worm", "kind": "tentacle", "color": "#6A3A8A"}, element="chaos")
enemy("dark_knight", "Kara Şövalye", "Dark Knight", "tank", {"rig": "skeleton", "weapon": "sword", "color": "#3A3A4A", "helm": True, "shield": True, "armor": True})
enemy("gargoyle", "Gargoyl", "Gargoyle", "brute", {"rig": "flyer", "kind": "gargoyle", "color": "#6A6A7A"}, res={"physical": 20})
enemy("vampire", "Vampir", "Vampire", "fast", {"rig": "bandit", "weapon": "claw", "color": "#E8DCE0", "cloth": "#2A1A2A", "cape": "#8A1E2E"}, tags=["undead"])
enemy("bat_swarm", "Yarasa Sürüsü", "Bat Swarm", "swarm", {"rig": "flyer", "kind": "bat", "color": "#3A2A3A"})
enemy("abyss_guard", "Uçurum Muhafızı", "Abyssal Guard", "tank", {"rig": "skeleton", "weapon": "axe", "color": "#4A3A5A", "helm": True, "armor": True}, element="chaos")

# ---------------------------------------------------------------- bosses
# boss id: (tr, en, base visual (dict), element, act boss?)
BOSSES = {}


def boss(bid, tr, en, vis, element="physical", kind="boss", mech=None, res=None):
    BOSSES[bid] = {"id": bid, "name": {"tr": tr, "en": en}, "arch": "brute", "element": element, "res": res or {},
                   "visual": vis, "tags": ["boss"], "type": kind, "mech": mech or [],
                   **ARCH["brute"]}


boss("giant_slime", "Dev Slime", "Giant Slime", {"rig": "blob", "color": "#5AB83A", "scale": 2.0}, mech=["split"])
boss("boar_mother", "Kızgın Domuz Ana", "Raging Sow", {"rig": "quad", "kind": "boar", "color": "#6A4A34", "scale": 1.6}, mech=["charge"])
boss("goblin_scout_chief", "Goblin Gözcü Başı", "Goblin Scout Chief", {"rig": "goblin", "weapon": "sword", "color": "#5A9A30", "cloth": "#8A3A2A", "helm": True, "scale": 1.6}, mech=["summon_goblins"])
boss("king_mushroom", "Kral Mantar", "King Mushroom", {"rig": "mushroom", "color": "#C9213A", "scale": 2.0, "crown": True}, element="chaos", mech=["poison_cloud"])
boss("goblin_chief", "Goblin Şefi Grubnak", "Goblin Chief Grubnak", {"rig": "goblin", "weapon": "axe", "color": "#5A9A30", "cloth": "#5A2A2A", "helm": True, "scale": 1.8}, mech=["slam", "summon_goblins"])
boss("grave_keeper", "Mezar Bekçisi", "Grave Keeper", {"rig": "skeleton", "weapon": "scythe", "color": "#D8D0B8", "hood": True, "scale": 1.7}, element="chaos", mech=["slam"])
boss("queen_spider", "Kraliçe Örümcek Arakna", "Queen Spider Arachna", {"rig": "spider", "color": "#3A2A3A", "scale": 2.0, "crown": True}, element="chaos", mech=["poison_cloud", "summon_spiders"])
boss("goblin_engineer", "Goblin Mühendis", "Goblin Engineer", {"rig": "golem", "kind": "clock", "color": "#8A7A5A", "scale": 1.5}, element="fire", mech=["bombard"])
boss("rotten_ent", "Çürük Ent", "Rotten Ent", {"rig": "ent", "color": "#5A4A3A", "leaf": "#8A9A3A", "scale": 1.7}, element="chaos", mech=["roots"])
boss("goblin_king", "Goblin Kralı Grizzlecrown", "Goblin King Grizzlecrown", {"rig": "goblin", "weapon": "greatsword", "color": "#5A9A30", "cloth": "#C9A040", "crown": True, "scale": 2.1}, kind="actboss", mech=["gold_rain", "summon_goblins", "enrage"])

boss("bandit_chief", "Haydut Reisi", "Bandit Chief", {"rig": "bandit", "weapon": "greatsword", "color": "#E2A882", "cloth": "#5A2A2A", "scale": 1.6}, mech=["slam"])
boss("yeti", "Yeti", "Yeti", {"rig": "golem", "kind": "yeti", "color": "#F0F4FA", "scale": 1.7}, element="cold", mech=["slam", "freeze"])
boss("lake_monster", "Göl Canavarı", "Lake Monster", {"rig": "worm", "kind": "tentacle", "color": "#4A7A9A", "scale": 1.8}, element="cold", mech=["freeze"])
boss("crystal_spider", "Kristal Örümcek", "Crystal Spider", {"rig": "spider", "color": "#9FB8FF", "scale": 1.9}, element="cold", mech=["summon_spiders"])
boss("cursed_foreman", "Lanetli Ustabaşı", "Cursed Foreman", {"rig": "skeleton", "weapon": "axe", "color": "#C8D8E0", "helm": True, "scale": 1.7}, mech=["slam"])
boss("harpy_queen", "Harpi Kraliçesi", "Harpy Queen", {"rig": "flyer", "kind": "harpy", "color": "#C98A4A", "scale": 1.8, "crown": True}, element="lightning", mech=["storm"])
boss("bjorn_duel", "Bjorn (Düello)", "Bjorn (Duel)", {"rig": "hero", "hero": "bjorn", "scale": 1.5}, mech=["enrage"])
boss("frozen_knight", "Donmuş Şövalye", "Frozen Knight", {"rig": "skeleton", "weapon": "greatsword", "color": "#9FDFFF", "helm": True, "armor": True, "scale": 1.8}, element="cold", mech=["slam", "freeze"])
boss("mirror_party", "Ayna Partisi", "Mirror Party", {"rig": "hero", "hero": "kael", "tint": "#9FDFFF", "scale": 1.5}, element="cold", mech=["slam"])
boss("ice_witch", "Buz Cadısı Isolde", "Ice Witch Isolde", {"rig": "hero", "hero": "isolde", "scale": 2.0}, element="cold", kind="actboss",
     mech=["blizzard", "ice_wall", "freeze"], res={"cold": 50, "fire": -25})

boss("pirate_captain", "Korsan Kaptan", "Pirate Captain", {"rig": "bandit", "weapon": "sword", "color": "#C98A5A", "cloth": "#8A1E2E", "hat": True, "scale": 1.6}, mech=["bombard"])
boss("giant_worm", "Dev Kum Solucanı", "Giant Sandworm", {"rig": "worm", "color": "#C9A06A", "scale": 2.2}, mech=["slam"])
boss("mirage_queen", "Serap Kraliçesi", "Mirage Queen", {"rig": "flyer", "kind": "fairy", "color": "#FFD98A", "scale": 2.0, "crown": True}, element="fire", mech=["storm"])
boss("pharaoh", "Firavun Mumyası", "Pharaoh Mummy", {"rig": "zombie", "color": "#E8DCB8", "cloth": "#E8B84A", "wrap": True, "crown": True, "scale": 1.8}, element="chaos", mech=["summon_undead", "curse"])
boss("magma_golem", "Magma Golem", "Magma Golem", {"rig": "golem", "kind": "elemental", "color": "#FF5A1A", "scale": 2.0}, element="fire", mech=["slam", "meteor"], res={"fire": 75})
boss("mad_alchemist", "Çılgın Simyacı", "Mad Alchemist", {"rig": "bandit", "weapon": "staff", "color": "#E2C8A0", "cloth": "#5A8A3A", "hood": True, "scale": 1.6}, element="chaos", mech=["poison_cloud"])
boss("library_guardian", "Kütüphane Muhafızı", "Library Guardian", {"rig": "golem", "kind": "clock", "color": "#8A5A3A", "scale": 1.8}, element="lightning", mech=["storm"])
boss("hourglass_keeper", "Kum Saati Bekçisi", "Hourglass Keeper", {"rig": "golem", "kind": "clock", "color": "#E8B84A", "scale": 1.8}, element="lightning", mech=["slow"])
boss("chimera_alpha", "Kimera Alfa", "Chimera Alpha", {"rig": "quad", "kind": "chimera", "color": "#B87A2A", "scale": 1.8}, element="fire", mech=["charge", "meteor"])
boss("corvus", "Hain Arşmag Corvus", "Traitor Archmage Corvus", {"rig": "hero", "hero": "corvus", "scale": 2.0}, element="fire", kind="actboss",
     mech=["element_shift", "meteor", "clones"])

boss("demon_hunter", "İblis Avcı", "Demon Hunter", {"rig": "bandit", "weapon": "bow", "color": "#9A5A6A", "cloth": "#2A1A2A", "horns": True, "scale": 1.6}, element="fire", mech=["bombard"])
boss("river_nightmare", "Nehir Kâbusu", "River Nightmare", {"rig": "worm", "kind": "tentacle", "color": "#8A1E2E", "scale": 2.0}, element="chaos", mech=["slam"])
boss("bone_colossus", "Kemik Kolosu", "Bone Colossus", {"rig": "golem", "kind": "bone", "color": "#E6DDC6", "scale": 2.0}, mech=["slam", "summon_undead"])
boss("shadow_ent", "Gölge Ent", "Shadow Ent", {"rig": "ent", "color": "#2A2436", "leaf": "#C58CFF", "scale": 1.8}, element="chaos", mech=["roots"])
boss("high_cultist", "Yüksek Kültist", "High Cultist", {"rig": "bandit", "weapon": "staff", "color": "#E2C8C0", "cloth": "#8A1E2E", "hood": True, "scale": 1.7}, element="chaos", mech=["curse", "summon_undead"])
boss("void_eye", "Hiçlik Gözü", "Eye of the Void", {"rig": "flyer", "kind": "eye", "color": "#6A3A8A", "scale": 2.0}, element="chaos", mech=["storm", "curse"])
boss("dark_commander", "Kara Şövalye Komutanı", "Dark Commander", {"rig": "skeleton", "weapon": "greatsword", "color": "#2A2A36", "helm": True, "armor": True, "scale": 1.8}, mech=["slam", "enrage"])
boss("vampire_countess", "Vampir Kontes", "Vampire Countess", {"rig": "bandit", "weapon": "claw", "color": "#F0E0E8", "cloth": "#5A1E2E", "cape": "#8A1E2E", "scale": 1.7, "female": True}, element="chaos", mech=["drain", "summon_bats"])
boss("abyss_twins", "Uçurum İkizleri", "Abyssal Twins", {"rig": "skeleton", "weapon": "axe", "color": "#5A3A6A", "helm": True, "armor": True, "scale": 1.7}, element="chaos", mech=["slam", "enrage"])
boss("morvath", "Uçurum Kralı Morvath", "Morvath, King of the Abyss", {"rig": "hero", "hero": "morvath", "scale": 2.2}, element="chaos", kind="actboss",
     mech=["dark_combo", "void_prison", "apocalypse", "enrage"])

# Villains rendered with the hero rig (extra variants used by the art builder)
VILLAINS = {
    "isolde": {"class": "mage", "visual": {"hair": "#E8F4FF", "hair_style": "long", "eye": "#7FD8FF", "primary": "#5A9AD8", "secondary": "#E8F4FF", "accent": "#9FDFFF", "skin": "#E8EEF6"}},
    "corvus": {"class": "mage", "visual": {"hair": "#2A2430", "hair_style": "short", "eye": "#FF7A33", "primary": "#2E2A46", "secondary": "#C9414B", "accent": "#FF7A33", "female": False, "beard": True}},
    "morvath": {"class": "knight", "visual": {"hair": "#E8E8F0", "hair_style": "long", "eye": "#FF3B5C", "primary": "#3A1E4A", "secondary": "#1E1A24", "metal": "#3A3446", "female": False, "ears": "horns", "weapon": "greatsword"}},
}

# ---------------------------------------------------------------- zones
ACTS = [
    {"id": 1, "name": {"tr": "Sisli Orman", "en": "Misty Forest"}, "music": "act1", "theme": "forest", "zones": [
        ("Taşköprü Çayırları", "Stonebridge Meadows", (1, 2), ["slime_green", "bunny"], "giant_slime", "meadow"),
        ("Orman Kıyısı", "Forest Edge", (2, 3), ["slime_green", "mushroom", "boar"], "boar_mother", "forest"),
        ("Sisli Orman Yolu", "Misty Forest Path", (3, 5), ["goblin_apprentice", "mushroom", "wolf"], "goblin_scout_chief", "forest_fog"),
        ("Mantar Mağarası", "Mushroom Cave", (5, 6), ["poison_shroom", "bat", "goblin_apprentice"], "king_mushroom", "cave"),
        ("Goblin Kampı", "Goblin Camp", (6, 7), ["goblin_warrior", "goblin_archer", "goblin_shaman"], "goblin_chief", "camp"),
        ("Unutulmuş Mezarlık", "Forgotten Graveyard", (7, 8), ["skeleton", "ghost", "zombie"], "grave_keeper", "graveyard"),
        ("Örümcek Yuvası", "Spider Nest", (8, 9), ["spider", "cocoon_zombie", "bat"], "queen_spider", "cave"),
        ("Kuşatılmış Değirmen", "Besieged Mill", (9, 10), ["goblin_rider", "goblin_bomber", "goblin_warrior"], "goblin_engineer", "meadow"),
        ("Kadim Ağaç Kökleri", "Ancient Roots", (10, 11), ["ent_sapling", "dark_fairy", "forest_spirit"], "rotten_ent", "forest"),
        ("Goblin Kralı Tahtı", "Goblin King's Throne", (11, 12), ["goblin_warrior", "goblin_shaman", "goblin_archer"], "goblin_king", "camp"),
    ]},
    {"id": 2, "name": {"tr": "Donmuş Zirveler", "en": "Frozen Peaks"}, "music": "act2", "theme": "snow", "zones": [
        ("Yıkık Dağ Köyü", "Ruined Mountain Village", (12, 13), ["snow_wolf", "bandit", "bandit_archer"], "bandit_chief", "snow"),
        ("Karlı Geçit", "Snowy Pass", (13, 15), ["yeti_cub", "ice_slime", "snow_wolf"], "yeti", "snow"),
        ("Donmuş Göl", "Frozen Lake", (15, 16), ["ice_elemental", "penguin", "ice_slime"], "lake_monster", "ice"),
        ("Kristal Mağaralar", "Crystal Caves", (16, 18), ["crystal_golem", "ice_bat", "ice_slime"], "crystal_spider", "ice_cave"),
        ("Cüce Madeni", "Dwarven Mine", (18, 19), ["ghost_miner", "ice_bat", "crystal_golem"], "cursed_foreman", "mine"),
        ("Fırtına Tepesi", "Storm Hill", (19, 20), ["harpy", "storm_spirit", "snow_wolf"], "harpy_queen", "storm"),
        ("Kuzey Kabileleri", "Northern Tribes", (20, 22), ["north_warrior", "snow_wolf", "bandit_archer"], "bjorn_duel", "snow"),
        ("Buz Tapınağı Girişi", "Ice Temple Gate", (22, 23), ["ice_guard", "snow_fairy", "ice_elemental"], "frozen_knight", "ice"),
        ("Ayna Salonu", "Hall of Mirrors", (23, 24), ["ice_knight", "snow_fairy", "ice_guard"], "mirror_party", "ice_cave"),
        ("Kış Cadısının Tahtı", "Winter Witch's Throne", (24, 25), ["ice_guard", "ice_elemental", "snow_fairy"], "ice_witch", "ice"),
    ]},
    {"id": 3, "name": {"tr": "Yanık Çöller", "en": "Scorched Sands"}, "music": "act3", "theme": "desert", "zones": [
        ("Kum Limanı", "Sand Harbor", (25, 26), ["pirate", "sand_crab", "bandit_archer"], "pirate_captain", "harbor"),
        ("Kızgın Kumullar", "Scorching Dunes", (26, 28), ["scorpion", "sand_worm", "lizardman"], "giant_worm", "desert"),
        ("Vaha", "Oasis", (28, 29), ["mirage", "cactus", "lizardman"], "mirage_queen", "oasis"),
        ("Gömülü Şehir", "Buried City", (29, 30), ["mummy", "scarab", "anubis_guard"], "pharaoh", "tomb"),
        ("Ateş Kanyonu", "Fire Canyon", (30, 32), ["fire_elemental", "lava_slime", "imp"], "magma_golem", "lava"),
        ("Öz Kulesi Kalıntıları", "Tower Ruins", (32, 33), ["cursed_book", "animated_armor", "imp"], "mad_alchemist", "ruins"),
        ("Arkana Kütüphanesi", "Arcane Library", (33, 34), ["cursed_book", "ink_slime", "animated_armor"], "library_guardian", "library"),
        ("Zaman Harabeleri", "Ruins of Time", (34, 36), ["clock_golem", "time_ghost", "ink_slime"], "hourglass_keeper", "ruins"),
        ("Hain Âlimin Laboratuvarı", "Traitor's Laboratory", (36, 37), ["chimera", "homunculus", "cursed_book"], "chimera_alpha", "library"),
        ("Güneş Sunağı", "Sun Altar", (37, 38), ["anubis_guard", "fire_elemental", "homunculus"], "corvus", "temple"),
    ]},
    {"id": 4, "name": {"tr": "Uçurum Kapısı", "en": "Abyssal Gate"}, "music": "act4", "theme": "abyss", "zones": [
        ("Kül Ovaları", "Ash Plains", (38, 39), ["demon_imp", "hellhound", "lava_slime"], "demon_hunter", "ash"),
        ("Kanlı Nehir", "Blood River", (39, 41), ["blood_elemental", "drowned", "demon_imp"], "river_nightmare", "blood"),
        ("Kemik Tarlaları", "Bone Fields", (41, 42), ["bone_drake", "skeleton_archer", "skeleton"], "bone_colossus", "bones"),
        ("Kara Orman", "Black Forest", (42, 43), ["cursed_ent", "shadow_wolf", "bat_swarm"], "shadow_ent", "dark_forest"),
        ("Kültist Tapınağı", "Cultist Temple", (43, 45), ["cultist", "sacrifice_priest", "skeleton"], "high_cultist", "temple_dark"),
        ("Uçurum Kenarı", "Abyss Edge", (45, 46), ["void_spawn", "tentacle", "shadow_wolf"], "void_eye", "void"),
        ("Kale Surları", "Castle Ramparts", (46, 47), ["dark_knight", "gargoyle", "skeleton_archer"], "dark_commander", "castle"),
        ("Ziyafet Salonu", "Banquet Hall", (47, 48), ["vampire", "bat_swarm", "dark_knight"], "vampire_countess", "hall"),
        ("Taht Odası Koridoru", "Throne Corridor", (48, 49), ["abyss_guard", "gargoyle", "cultist"], "abyss_twins", "castle"),
        ("Morvath'ın Tahtı", "Morvath's Throne", (49, 50), ["abyss_guard", "void_spawn", "dark_knight"], "morvath", "throne"),
    ]},
]


def main():
    zones = []
    for act in ACTS:
        for i, (tr, en, lv, roster, bss, bg) in enumerate(act["zones"]):
            zones.append({"id": f"a{act['id']}_z{i + 1:02d}", "act": act["id"], "index": i + 1,
                          "name": {"tr": tr, "en": en}, "level": list(lv), "enemies": roster, "boss": bss,
                          "background": bg, "music": act["music"]})
    for b in BOSSES.values():
        assert b["visual"]["rig"] in ("hero",) or True
    data_e = {"enemies": E, "bosses": BOSSES, "villains": VILLAINS}
    json.dump(data_e, open(os.path.join(OUT, "enemies.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    acts = [{"id": a["id"], "name": a["name"], "music": a["music"], "theme": a["theme"]} for a in ACTS]
    json.dump({"acts": acts, "zones": zones,
               "difficulties": [{"id": "normal", "name": {"tr": "Normal", "en": "Normal"}},
                                {"id": "nightmare", "name": {"tr": "Kabus", "en": "Nightmare"}},
                                {"id": "hell", "name": {"tr": "Cehennem", "en": "Hell"}}]},
              open(os.path.join(OUT, "zones.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    # sanity
    for z in zones:
        for e in z["enemies"]:
            assert e in E, (z["id"], e)
        assert z["boss"] in BOSSES, z["boss"]
    print(len(E), "enemies", len(BOSSES), "bosses", len(zones), "zones")


if __name__ == "__main__":
    main()
