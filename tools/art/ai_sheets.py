#!/usr/bin/env python3
"""Prompts + bookkeeping for the animated chibi sprite sheets (gpt_image_2_5, reference = the unit's HD illustration).

  ai_sheets.py prompts                    write art_src/prompts_sheets_<kind>.json for heroes / enemies / pets
  ai_sheets.py batch <kind> <id,id,...>   print generate_image_batch requests for those ids
  ai_sheets.py jobs <kind> id=job ...     record submitted jobs  (art_src/jobs_sheets_<kind>.json)
  ai_sheets.py urls <kind> <url> ...      record finished URLs (urls_sheets_<kind>.json), job id in the URL maps to the id
  ai_sheets.py todo <kind>                ids that have a prompt but no job yet

Every sheet: 6 columns x 4 rows on flat magenta, facing RIGHT (enemies are mirrored in game):
  row 1 idle loop, row 2 move loop, row 3 attack, row 4 hurt x2 + death x4.
Then: python3 tools/art/import_sheets.py <kind>
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ai_prompts as P  # noqa: E402

ROOT = P.ROOT
SRC = os.path.join(ROOT, "art_src")

HEAD = ("Game sprite sheet of the referenced {what} ({desc}) redrawn as a tiny cute chibi pixel-art sprite{chibi}, "
        "in the style of premium modern pixel-art idle RPGs like TBH Task Bar Hero. Side view facing right. Crisp "
        "hand-placed pixels, dark 1-pixel outlines, limited palette, keep the same {keep} as the reference. Plain flat "
        "solid magenta #FF00FF background everywhere. Exactly 4 rows and 6 columns of evenly spaced frames, every frame "
        "the same scale, feet on the same baseline in every cell. ")
TAIL = ("Same {what} design in every frame. No text, no labels, no grid lines, no shadows on background.")

WEAPON = {"knight": "sword and shield", "berserker": "huge two-handed battle axe", "archer": "longbow",
          "assassin": "twin daggers", "mage": "magic staff", "necromancer": "skull-topped staff",
          "cleric": "holy scepter", "bard": "lute"}
ATTACK = {
    "knight": "sword attack: crouch wind-up, big overhead swing, slash with a white motion smear arc, follow-through, recover",
    "berserker": "heavy two-handed attack: lift the weapon high behind the head, jump forward, smash down with a big white "
                 "motion smear arc and a ground impact, recover",
    "archer": "bow attack: nock an arrow, draw the bowstring back, aim, release with the bow snapping forward (no arrow "
              "drawn after release), bow recoil, recover",
    "assassin": "lightning-fast dagger combo: dash-lunge, first slash, spin, second slash with white motion smear arcs, recover",
    "mage": "spell cast: raise the staff, gather glowing magic energy at its tip, thrust forward releasing a burst of magic, recover",
    "necromancer": "dark spell cast: raise the staff, swirling green-violet necrotic energy gathers, thrust forward "
                   "releasing it, recover",
    "cleric": "holy spell: raise the scepter overhead, golden holy light gathers, a radiant burst of light, recover",
    "bard": "performance: strum the lute energetically with musical notes floating, a strong chord with a sparkle burst, recover",
}
HERO_ROWS = ("Row 1: idle breathing loop (6 frames). Row 2: running loop (6 frames). Row 3: {attack} (6 frames). "
             "Row 4: hurt recoil (2 frames) then death falling to the ground (4 frames). ")
MON_ROWS = ("Row 1: idle loop (6 frames). Row 2: moving loop, {move} (6 frames). Row 3: {attack} (6 frames). "
            "Row 4: hurt recoil (2 frames) then death: collapsing and dissolving into the ground (4 frames). ")
PET_ROWS = ("Row 1: idle loop, happy and bouncy (6 frames). Row 2: moving loop following its owner (6 frames). "
            "Row 3: attack: wind-up, pounce or magic burst with a sparkle, recover (6 frames). "
            "Row 4: hurt recoil (2 frames) then fainting with dizzy stars (4 frames). ")

FLY = ("bat", "ghost", "dark_fairy", "forest_spirit", "ice_bat", "snow_fairy", "harpy", "storm_spirit", "mirage",
       "time_ghost", "cursed_book", "bat_swarm", "void_spawn", "gargoyle", "imp", "demon_imp", "blood_elemental",
       "ice_elemental", "fire_elemental", "wisp", "harpy_queen", "void_eye", "mirage_queen")
HOP = ("slime", "bunny", "cactus", "mushroom", "shroom", "penguin")
CRAWL = ("spider", "scorpion", "worm", "crab", "scarab", "tentacle")
RANGED_HINT = {"archer": "bow attack: draw and release an arrow, recover",
               "shaman": "spell cast: raise the staff and release a burst of magic, recover",
               "bomber": "throw a lit bomb overhand, recover",
               "witch": "spell cast: raise the staff and release a burst of icy magic, recover",
               "priest": "dark ritual cast: raise the hands, release a burst of dark magic, recover",
               "cultist": "dark spell cast: release a burst of dark magic from the hands, recover",
               "alchemist": "throw a bubbling potion flask, recover",
               "elemental": "magic attack: swell up and release a burst of elemental energy, recover",
               "corvus": "dark spell cast: raise the staff and release a burst of violet magic, recover",
               "mage": "spell cast: raise the staff and release a burst of magic, recover"}


def _move(eid):
    if any(k in eid for k in FLY):
        return "flying / floating"
    if any(k in eid for k in HOP):
        return "hopping"
    if any(k in eid for k in CRAWL):
        return "crawling"
    return "walking forward"


def _mon_attack(eid, rng):
    for k, v in RANGED_HINT.items():
        if k in eid:
            return v
    if rng and rng > 60:
        return "ranged attack: wind-up and release a projectile, recover"
    return "attack: wind-up, lunge forward and strike or bite with a white motion smear, recover"


def hero_desc(h):
    v = h.get("visual", {})
    gender = "female" if v.get("female", True) else "male"
    hair = P.HAIR.get(v.get("hair_style", "long"), "{c} hair").format(c=P.cname(v.get("hair", "#F2CC5E")))
    weapon = WEAPON[h["class"]]
    if v.get("weapon") == "greatsword":
        weapon = "huge two-handed greatsword"
    note = P.NOTES.get(h["id"], "")
    art = "" if weapon.startswith("twin") else "a "
    d = f"{h['name']}, a {gender} {h['class']} with {hair}, holding {art}{weapon}"
    return d + (f"; {note}" if note else "")


def prompts():
    heroes = json.load(open(os.path.join(P.GAME, "data/heroes.json"), encoding="utf-8"))["heroes"]
    hj = json.load(open(os.path.join(SRC, "jobs_heroes.json")))
    out = {}
    for h in heroes:
        att = ATTACK[h["class"]]
        if h.get("visual", {}).get("weapon") == "greatsword":
            att = att.replace("the weapon", "the greatsword")
        p = (HEAD.format(what="character", desc=hero_desc(h), chibi=" (big head about 40% of height, small body)",
                         keep="hair, face, outfit colours and weapon")
             + HERO_ROWS.format(attack=att) + TAIL.format(what="character"))
        out[h["id"]] = _keyed({"prompt": p, "ref": hj[h["id"]]}, hero_desc(h))
    json.dump(out, open(os.path.join(SRC, "prompts_sheets_heroes.json"), "w"), indent=1, ensure_ascii=False)

    ed = json.load(open(os.path.join(P.GAME, "data/enemies.json"), encoding="utf-8"))
    ej = json.load(open(os.path.join(SRC, "jobs_enemies.json")))
    out = {}
    for eid, desc in list(P.ENEMY_DESC.items()) + list(P.BOSS_DESC.items()):
        if eid not in ej:
            continue
        boss = eid in P.BOSS_DESC
        e = ed.get("enemies", {}).get(eid) or ed.get("bosses", {}).get(eid) or ed.get("villains", {}).get(eid) or {}
        rng = float(e.get("range", 22)) if isinstance(e, dict) else 22.0
        what = "boss monster" if boss else "monster"
        human = any(k in eid for k in ("goblin", "bandit", "pirate", "skeleton", "zombie", "knight", "guard", "warrior",
                                        "cultist", "priest", "vampire", "witch", "captain", "chief", "king", "alchemist",
                                        "corvus", "morvath", "commander", "hunter", "pharaoh", "mummy", "lizardman",
                                        "keeper", "foreman", "miner", "countess", "engineer", "armor"))
        chibi = " (big head, small body)" if human else " (cute rounded proportions)"
        p = (HEAD.format(what=what, desc=desc, chibi=chibi, keep="colours, features and weapon")
             + MON_ROWS.format(move=_move(eid), attack=_mon_attack(eid, rng))
             + (" It is a big imposing boss, drawn larger and more detailed. " if boss else "")
             + TAIL.format(what=what))
        out[eid] = _keyed({"prompt": p, "ref": ej[eid]}, desc)
    json.dump(out, open(os.path.join(SRC, "prompts_sheets_enemies.json"), "w"), indent=1, ensure_ascii=False)

    pets = json.load(open(os.path.join(P.GAME, "data/pets.json"), encoding="utf-8"))
    pets = pets.get("pets", pets)
    pj = json.load(open(os.path.join(SRC, "jobs_pets.json")))
    out = {}
    items = pets.items() if isinstance(pets, dict) else [(x["id"], x) for x in pets]
    for pid, pv in items:
        if pid not in pj:
            continue
        name = pv.get("name", {}).get("en", pid) if isinstance(pv.get("name"), dict) else str(pv.get("name", pid))
        p = (HEAD.format(what="pet companion", desc=name, chibi=" (cute rounded proportions)", keep="colours and features")
             + PET_ROWS + TAIL.format(what="pet"))
        out[pid] = {"prompt": p, "ref": pj[pid]}
    json.dump(out, open(os.path.join(SRC, "prompts_sheets_pets.json"), "w"), indent=1, ensure_ascii=False)
    print("ok")


CYAN_WORDS = ("magenta", "fuchsia", "hot pink")


def _keyed(entry, desc):
    """Units dressed in magenta get a cyan key colour instead (import_sheets reads "key")."""
    if any(w in desc.lower() for w in CYAN_WORDS):
        entry["prompt"] = entry["prompt"].replace("solid magenta #FF00FF", "solid cyan #00FFFF")
        entry["key"] = "cyan"
    return entry


def load(name):
    p = os.path.join(SRC, name)
    return json.load(open(p)) if os.path.exists(p) else {}


def main():
    cmd = sys.argv[1]
    if cmd == "prompts":
        prompts()
        return
    kind = sys.argv[2]
    jobs = load(f"jobs_sheets_{kind}.json")
    if cmd == "batch":
        pr = load(f"prompts_sheets_{kind}.json")
        ids = sys.argv[3].split(",")
        reqs = [{"index": i, "params": {"model": "gpt_image_2_5", "quality": "low", "aspect_ratio": "3:2", "use_unlim": False,
                 "medias": [{"value": pr[k]["ref"], "role": "image_references"}], "prompt": pr[k]["prompt"]}}
                for i, k in enumerate(ids)]
        print(json.dumps(reqs, ensure_ascii=False))
    elif cmd == "jobs":
        for a in sys.argv[3:]:
            k, v = a.split("=", 1)
            jobs[k] = v
        json.dump(jobs, open(os.path.join(SRC, f"jobs_sheets_{kind}.json"), "w"), indent=1)
        print(len(jobs), "jobs")
    elif cmd == "urls":
        urls = load(f"urls_sheets_{kind}.json")
        by_job = {v: k for k, v in jobs.items()}
        new = []
        for u in sys.argv[3:]:
            jid = u.rsplit("_", 1)[-1].replace(".png", "")
            if jid in by_job:
                urls[by_job[jid]] = u
                new.append(by_job[jid])
            else:
                print("unknown job", jid)
        json.dump(urls, open(os.path.join(SRC, f"urls_sheets_{kind}.json"), "w"), indent=1)
        print(" ".join(new))
    elif cmd == "todo":
        pr = load(f"prompts_sheets_{kind}.json")
        print(" ".join(k for k in pr if k not in jobs))


if __name__ == "__main__":
    main()
