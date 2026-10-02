#!/usr/bin/env python3
"""Builds image-generation prompts for every hero from game/data/heroes.json.

Output: art_src/prompts_heroes.json  ->  {hero_id: prompt}
The style block is shared so the whole roster reads as one consistent art set.
"""
import colorsys
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GAME = os.path.join(ROOT, "game")

STYLE = ("High-resolution detailed pixel art game character sprite, in the style of premium modern anime "
         "pixel-art RPGs (a detailed character portrait sprite from an idle RPG). Single full-body character, "
         "standing in a relaxed ready stance, three-quarter view facing to the RIGHT. {who} "
         "Natural human proportions (about 6.5 heads tall), not chibi. Tasteful, fully clothed fantasy outfit. "
         "Crisp clean pixels, rich hue-shifted shading with many tones, soft highlights, dark selective outline, "
         "no blur. Isolated on a fully transparent background, no ground, no text, no frame.")

CLASS = {
    "knight": "a knight in polished plate armor with a {p} tabard and {s} details, a cape, a longsword and a kite shield bearing an emblem",
    "berserker": "a berserker warrior in rugged fur-trimmed leather and partial armor in {p} tones, bare muscular arms with bracers, wielding a huge two-handed battle axe",
    "archer": "a ranger in fitted leather armor in {p} and {s} colors, arm bracers, tall boots, a quiver of arrows on the back, holding an elegant longbow",
    "assassin": "an assassin in sleek dark fitted leather with a {p} scarf and sash, a short hood, dual daggers held in reverse grip",
    "mage": "a mage in flowing layered robes in {p} and {s} with gold embroidery, holding an ornate magic staff with a glowing {a} crystal",
    "necromancer": "a necromancer in dark tattered robes in {p} tones with bone ornaments, holding a skull-topped staff with eerie green-violet magic wisps",
    "cleric": "a cleric in white and {p} holy vestments with gold trim, holding a gilded mace-scepter, a small holy symbol pendant, soft light aura",
    "bard": "a bard in a stylish {p} doublet with {s} accents, a feathered cap, holding an ornate lute",
}
FACTION = {
    "empire": "Imperial style: polished steel, crimson-and-gold heraldry.",
    "holy": "Holy order style: white, gold and sky-blue, radiant details.",
    "tower": "Arcane tower style: starry patterns, glowing runes.",
    "abyss": "Abyssal style: dark violet and black, demonic accents, faint purple glow.",
    "wild": "Wildland style: natural leather, leaves, feathers, tribal patterns.",
    "shadow": "Shadow guild style: dark charcoal, crimson accents, mysterious mood.",
}
HAIR = {
    "short": "short {c} hair", "long": "long flowing {c} hair", "ponytail": "{c} hair in a high ponytail",
    "spiky": "spiky {c} hair", "bob": "{c} bob-cut hair", "twin": "{c} hair in twin tails",
    "bald": "a shaved head", "braid": "{c} hair in a long braid",
}
# character notes that make individual heroes recognisable
NOTES = {
    "aurelia": "a regal paladin princess, white and crimson armor with gold filigree, a winged circlet",
    "gareth": "a big grizzled veteran with a thick brown beard and a huge greatsword instead of an axe",
    "draven": "a stern dark knight in black-steel armor with crimson accents, gray hair and a short beard",
    "seraphina": "an angelic high priestess with small feathered wings and a halo",
    "oswin": "a jolly middle-aged monk with a brown beard, simple robes, a lute",
    "hale": "a cold inquisitor in pale white coat-armor with a wide-brimmed hat and a crossbow-like dagger",
    "aldric": "an old king with a white beard, a golden crown and royal blue armor",
    "thalos": "a wise old archmage with a long white beard and a tall pointed hat",
    "fizz": "a cheerful young inventor bard with goggles on his head and gadgets on his belt",
    "mordecai": "a pale young necromancer with long black hair and glowing green eyes",
    "zephyr": "a swift wind assassin with teal hair and flowing turquoise scarves",
    "lilith": "a beautiful demon sorceress with small curved horns and glowing red eyes",
    "grimm": "a hulking demon berserker with purple skin and horns",
    "malakar": "an ancient horned lich-necromancer with pale gray skin and a bone crown",
    "kharon": "a dark ferryman knight with a violet-glowing visor helmet held at his side",
    "thorne": "a tall elven ranger lord with long green hair and a leaf cloak",
    "kira": "a playful cat-eared rogue girl with orange hair and a tail",
    "ursa": "a strong shieldmaiden with a bear-pelt cloak",
    "oakheart": "a druid with bark-like skin details, moss and flowers in long green hair",
    "raka": "a towering tribal warrior with long white hair, tan skin and war paint",
    "fern": "a cheerful elf bard girl with green hair and a flower crown",
    "nyxara": "an elegant shadow assassin queen with long purple hair",
    "mags": "a kindly old herbalist woman with gray hair, a shawl and potion bottles",
    "viktor": "a tough bald brawler with scars",
    "masked": "a mysterious mage wearing a white porcelain mask with gold trim and a black hooded robe",
    "pip": "a small cheerful young priestess girl with a big smile",
    "selene": "a calm moon priestess with silver hair and a crescent-moon staff",
    "nyx": "a gothic nun with a violet veil",
    "ezra": "a melancholic pale bard with silver hair and a dark violin instead of a lute",
    "dahlia": "a gothic necromancer girl with crimson bob hair",
    "iris": "a sky archer girl with blue hair and a crystal bow",
    "silas": "a hooded dark-haired sharpshooter with a crimson scarf",
    "raven": "a crimson-clad female assassin with short black hair",
    "finn": "a young green-clad bard boy with a flute-lute",
    "vex": "a young warlock with short dark hair and violet magic",
    "nova": "a young star mage girl with long silver-white hair",
    "lucia": "a cheerful sun mage girl with blonde bob hair and golden-white robes",
    "vesper": "a confident battle mage woman with purple bob hair and fire magic",
    "tristan": "a noble young paladin in white armor",
    "elowen": "a gentle holy archer with a long brown braid",
    "cassia": "a freckled red-haired huntress",
    "leon": "a charming blond bard in purple",
    "marcus": "a young battle priest in gold and white",
    "rook": "a young tower guard knight with spiky brown hair",
    "morrigan": "a mysterious long-haired violet assassin",
    "bjorn": "a big red-haired, red-bearded northern berserker",
    "lyra": "a young elf ranger woman with pointed ears, long golden-blonde hair and rose-pink outfit",
    "kael": "a young knight captain with short dark navy-black hair, royal blue tabard and a round blue shield",
}
RARITY = {"R": "", "SR": "Fine, detailed outfit.", "SSR": "Legendary, ornate and majestic outfit with glowing accents."}

COLORS = [
    ("black", (20, 18, 24)), ("charcoal", (50, 46, 56)), ("dark navy", (40, 44, 70)), ("silver-white", (232, 230, 240)),
    ("white", (250, 250, 250)), ("silver-gray", (160, 160, 170)), ("gray", (110, 110, 120)), ("platinum blonde", (240, 232, 200)),
    ("golden blonde", (242, 204, 94)), ("honey blonde", (245, 213, 122)), ("light brown", (184, 138, 90)), ("brown", (122, 90, 62)),
    ("dark brown", (90, 62, 46)), ("auburn", (168, 72, 46)), ("fiery red", (210, 80, 50)), ("orange", (232, 132, 58)),
    ("crimson", (200, 65, 75)), ("burgundy", (110, 30, 46)), ("rose pink", (224, 123, 175)), ("pink", (255, 154, 200)),
    ("purple", (122, 79, 184)), ("deep violet", (92, 62, 128)), ("lavender", (197, 140, 255)), ("royal blue", (61, 111, 214)),
    ("sky blue", (127, 184, 240)), ("navy", (46, 50, 112)), ("teal", (62, 201, 176)), ("mint", (159, 224, 208)),
    ("forest green", (62, 122, 62)), ("leaf green", (106, 184, 74)), ("lime green", (159, 224, 122)), ("olive", (106, 138, 90)),
    ("gold", (232, 184, 74)), ("bronze", (184, 134, 46)), ("tan", (201, 180, 154)), ("cream", (240, 230, 210)),
]


def cname(hexs):
    h = hexs.lstrip("#")
    rgb = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    return min(COLORS, key=lambda c: sum((a - b) ** 2 for a, b in zip(c[1], rgb)))[0]


def hero_prompt(h):
    v = h.get("visual", {})
    female = v.get("female", True)
    gender = "woman" if female else "man"
    hair = HAIR.get(v.get("hair_style", "long"), "{c} hair").format(c=cname(v.get("hair", "#F2CC5E")))
    eye_word = {"golden blonde": "golden", "honey blonde": "amber", "platinum blonde": "pale gold", "cream": "pale",
                "silver-white": "silver", "white": "silver", "tan": "hazel", "bronze": "amber", "brown": "brown",
                "lime green": "bright green", "leaf green": "green", "olive": "green"}
    en = cname(v.get("eye", "#3E7BC9"))
    eyes = eye_word.get(en, en) + " eyes"
    cloth = {"golden blonde": "gold", "honey blonde": "gold", "platinum blonde": "ivory", "silver-white": "white",
             "cream": "ivory", "auburn": "rust red", "fiery red": "scarlet"}
    def cc(hexs):
        n = cname(hexs)
        return cloth.get(n, n)
    p = cc(v.get("primary", v.get("leather", "#8E5B3E")))
    s = cc(v.get("secondary", "#E8E2D6"))
    a = cc(v.get("accent", "#7FD8FF"))
    outfit = CLASS[h["class"]].format(p=p, s=s, a=a)
    if v.get("weapon") == "greatsword":
        outfit = outfit.replace("a huge two-handed battle axe", "a huge two-handed greatsword")
    extra = []
    if v.get("ears") == "elf":
        extra.append("pointed elf ears")
    elif v.get("ears") == "cat":
        extra.append("cat ears and a cat tail")
    elif v.get("ears") == "horns":
        extra.append("small curved horns")
    if v.get("beard"):
        extra.append("a beard")
    skin = v.get("skin")
    if skin and h["id"] not in NOTES:
        extra.append(cname(skin) + "-toned skin" if cname(skin) not in ("tan", "cream") else "")
    note = NOTES.get(h["id"], "")
    who = (f"{h['name']}: {note}. A young adult {gender}, {hair}, {eyes}"
           + (", " + ", ".join(e for e in extra if e) if any(extra) else "")
           + f", clear readable anime face. Outfit: {outfit}. {FACTION.get(h['faction'], '')} {RARITY.get(h['rarity'], '')}")
    if h["id"] in ("aldric", "thalos", "mags", "oswin", "malakar", "gareth"):
        who = who.replace("A young adult", "An older")
    return STYLE.format(who=who.strip())


def main():
    heroes = json.load(open(os.path.join(GAME, "data/heroes.json"), encoding="utf-8"))["heroes"]
    out = {h["id"]: hero_prompt(h) for h in heroes}
    os.makedirs(os.path.join(ROOT, "art_src"), exist_ok=True)
    json.dump(out, open(os.path.join(ROOT, "art_src/prompts_heroes.json"), "w"), indent=1, ensure_ascii=False)
    print(len(out))
    print(out["aldric"])


if __name__ == "__main__":
    main()


# =========================================================================== enemies & bosses
ESTYLE = ("High-resolution detailed pixel art game monster sprite, in the style of premium modern anime pixel-art RPGs "
          "(matching a detailed idle-RPG sprite set). Single full-body {what}, in an idle combat pose, three-quarter view "
          "facing to the LEFT. {desc} Crisp clean pixels, rich hue-shifted shading with many tones, soft highlights, dark "
          "selective outline, no blur. Isolated on a fully transparent background, no ground, no text, no frame.")
BOSS_EXTRA = " It is a powerful BOSS: larger, more ornate and menacing, with glowing accents and an imposing silhouette."

ENEMY_DESC = {
    "slime_green": "cute but feisty green jelly slime with a glossy translucent body and big determined eyes",
    "bunny": "angry fluffy cream-white bunny with tiny fangs and a furious frown",
    "mushroom": "walking red-capped mushroom creature with white spots, little feet and grumpy eyes",
    "boar": "bristly brown wild boar with tusks, charging stance",
    "goblin_apprentice": "small green goblin in brown rags holding a rusty dagger, mischievous grin",
    "goblin_warrior": "green goblin warrior in a dented iron helmet and leather armor with a short sword",
    "goblin_archer": "green goblin archer in a green hood with a crude bow",
    "goblin_shaman": "green goblin shaman in magenta robes with a bone staff and feather headdress",
    "wolf": "gray forest wolf snarling, thick fur",
    "bat": "purple cave bat with spread wings and red eyes",
    "poison_shroom": "toxic purple mushroom creature dripping poisonous spores",
    "skeleton": "undead skeleton warrior with a chipped sword and glowing eye sockets",
    "ghost": "pale blue floating ghost with a wispy tail and hollow eyes",
    "zombie": "shambling green-skinned zombie in torn gray clothes",
    "spider": "big dark hairy spider with glowing red eyes",
    "cocoon_zombie": "zombie wrapped in white spider-silk cocoon threads",
    "goblin_bomber": "goblin in an orange vest holding a lit round bomb with a sparking fuse",
    "goblin_rider": "small goblin riding a dark gray wolf",
    "ent_sapling": "small walking tree sapling creature with leafy green crown and angry knot eyes",
    "dark_fairy": "wicked pink fairy with butterfly wings and a sly smile",
    "forest_spirit": "glowing green forest wisp spirit with leaf ornaments",
    "snow_wolf": "white snow wolf with frosty fur and icy blue eyes",
    "bandit": "human bandit thug in a bandana and leather vest with a sword",
    "bandit_archer": "human bandit archer in a green hood with a bow",
    "yeti_cub": "fluffy white yeti cub with blue horns, chubby and fierce",
    "ice_slime": "translucent light-blue ice slime with frost crystals",
    "ice_elemental": "ice elemental made of jagged blue crystals with a glowing core",
    "penguin": "penguin warrior wearing a tiny helmet and holding a small spear",
    "crystal_golem": "crystal golem made of periwinkle-blue gem shards",
    "ice_bat": "icy blue bat with frosted wings",
    "ghost_miner": "ghostly skeleton miner with a mining helmet and pickaxe, pale blue glow",
    "harpy": "harpy with brown feathered wings and talons, wild hair",
    "storm_spirit": "crackling yellow storm wisp crackling with lightning",
    "north_warrior": "northern barbarian warrior in a horned helmet with an axe",
    "ice_guard": "frozen skeleton guardian in ice armor with sword and shield",
    "snow_fairy": "snowflake fairy with icy crystal wings",
    "ice_knight": "mirror-like ice knight armor with a reflective crystal sword",
    "pirate": "pirate swordsman in a red coat and bandana with a cutlass",
    "sand_crab": "large orange sand crab with big pincers",
    "scorpion": "giant sand scorpion with a raised glowing stinger",
    "sand_worm": "sand worm bursting upward, ringed segments and round toothy maw",
    "lizardman": "green lizardman warrior with a spear and leather harness",
    "mirage": "shimmering golden mirage spirit, semi-transparent",
    "cactus": "angry walking cactus beast with pink flowers and spikes",
    "mummy": "bandaged mummy with glowing eyes and loose wrappings",
    "scarab": "large metallic blue scarab beetle",
    "anubis_guard": "jackal-headed Anubis temple guard with gold armor and a spear",
    "fire_elemental": "fire elemental, a humanoid of roaring orange flames",
    "lava_slime": "molten lava slime glowing orange with a cracked crust",
    "imp": "small red fire imp with horns, bat wings and a trident",
    "cursed_book": "flying cursed spellbook with teeth and glowing runes, pages flapping",
    "animated_armor": "empty animated suit of steel armor with sword and shield, ghostly glow inside",
    "ink_slime": "dark navy ink slime dripping ink",
    "clock_golem": "clockwork golem of brass gears and pipes with a clock-face chest",
    "time_ghost": "lavender time wraith with floating clock hands",
    "chimera": "chimera with a lion head, goat horns and a snake tail",
    "homunculus": "pale pink alchemical homunculus with claws in tattered robes",
    "hellhound": "dark red hellhound with burning orange eyes and fiery mane",
    "demon_imp": "purple demon imp with horns and a trident",
    "blood_elemental": "crimson blood elemental with a liquid body",
    "drowned": "drowned undead sailor, teal skin, seaweed and dripping water",
    "bone_drake": "skeletal bone dragon whelp",
    "skeleton_archer": "skeleton archer with a bow and quiver",
    "cursed_ent": "corrupted dark ent tree with purple glowing leaves",
    "shadow_wolf": "shadow wolf made of dark smoke with violet glowing eyes",
    "cultist": "hooded cultist in crimson-black robes with a ritual staff",
    "sacrifice_priest": "hooded sacrificial priest in black robes with a curved dagger",
    "void_spawn": "void spawn blob of dark purple matter with many eyes",
    "tentacle": "purple abyssal tentacle rising from a portal",
    "dark_knight": "dark knight in black armor with sword and shield, red glowing visor",
    "gargoyle": "stone gargoyle with bat wings and horns",
    "vampire": "pale vampire noble with a red-lined black cape and claws",
    "bat_swarm": "swarm of small black bats",
    "abyss_guard": "abyssal guard in violet-black armor with a great axe",
}
BOSS_DESC = {
    "giant_slime": "enormous green king slime with a tiny golden crown",
    "boar_mother": "huge raging sow boar with massive tusks and scars",
    "goblin_scout_chief": "goblin scout chief in a red cloak and helmet with a sword",
    "king_mushroom": "giant crimson king mushroom with a golden crown",
    "goblin_chief": "goblin chief Grubnak, burly, horned helmet, big axe",
    "grave_keeper": "hooded skeletal grave keeper with a huge scythe and lantern",
    "queen_spider": "queen spider Arachna, giant spider with a crown and violet markings",
    "goblin_engineer": "goblin engineer riding a clunky brass steam mech",
    "rotten_ent": "giant rotten ent tree with moss and glowing yellow eyes",
    "goblin_king": "Goblin King Grizzlecrown, huge goblin in golden armor and crown with a greatsword",
    "bandit_chief": "bandit chief, a big scarred man with a greatsword and red coat",
    "yeti": "huge white yeti with blue horns and frosty breath",
    "lake_monster": "blue lake serpent monster with tentacles rising from water",
    "crystal_spider": "giant crystal spider made of blue gemstone",
    "cursed_foreman": "cursed skeletal mine foreman with a helmet lamp and giant axe",
    "harpy_queen": "harpy queen with golden crown and great wings",
    "frozen_knight": "frozen undead knight in ice armor with a greatsword",
    "pirate_captain": "pirate captain with a tricorn hat, red coat and cutlass",
    "giant_worm": "colossal sandworm with a huge circular toothy maw",
    "mirage_queen": "golden mirage fairy queen with radiant wings and crown",
    "pharaoh": "pharaoh mummy in golden headdress and bandages with a scepter",
    "magma_golem": "giant magma golem of black rock and flowing lava",
    "mad_alchemist": "mad hooded alchemist with bubbling flasks and a green staff",
    "library_guardian": "library guardian golem made of books and bronze",
    "hourglass_keeper": "golden hourglass keeper construct with clock wings",
    "chimera_alpha": "alpha chimera with three heads, lion goat and serpent",
    "demon_hunter": "horned demon hunter with a dark longbow",
    "river_nightmare": "crimson river nightmare tentacle beast",
    "bone_colossus": "giant colossus made of bones and skulls",
    "shadow_ent": "shadow ent with violet glowing leaves and a hollow face",
    "high_cultist": "high cultist in crimson robes with a glowing ritual staff",
    "void_eye": "giant floating eye of the void with tentacles",
    "dark_commander": "dark commander in black plate armor with a greatsword",
    "vampire_countess": "elegant vampire countess in a crimson gown with a cape and claws",
    "abyss_twins": "abyssal twin knights in violet-black armor with axes",
    "ice_witch": "Ice Witch Isolde, an elegant sorceress in icy blue robes with a frost crown and a crystal staff",
    "corvus": "Traitor Archmage Corvus, a sinister mage in black-and-violet robes with a raven-feather collar and a dark staff",
    "morvath": "Morvath, King of the Abyss, a towering demon king in black spiked armor with a burning violet crown, huge horns and a dark greatsword",
}
HERO_ALIAS = {"bjorn_duel": "bjorn", "mirror_party": "kael"}   # bosses that reuse hero art


def enemy_prompts():
    out = {}
    for k, desc in ENEMY_DESC.items():
        out[k] = ESTYLE.format(what="monster", desc=desc[0].upper() + desc[1:] + ".")
    for k, desc in BOSS_DESC.items():
        out[k] = ESTYLE.format(what="boss monster", desc=desc[0].upper() + desc[1:] + "." + BOSS_EXTRA)
    return out


if __name__ == "__main__":
    ep = enemy_prompts()
    json.dump(ep, open(os.path.join(ROOT, "art_src/prompts_enemies.json"), "w"), indent=1, ensure_ascii=False)
    print("enemies", len(ep))
