import json, re, glob, os, sys
root = sys.argv[1]
strings = json.load(open(os.path.join(root, "data/strings.json")))
used = {}
for f in glob.glob(os.path.join(root, "scripts/**/*.gd"), recursive=True):
    src = open(f).read()
    for m in re.finditer(r'DataDB\.t\("([a-zA-Z0-9_]+)"', src):
        used.setdefault(m.group(1), set()).add(os.path.relpath(f, root))
missing = sorted(k for k in used if k not in strings)
print("MISSING KEYS:", len(missing))
for k in missing: print("  ", k, sorted(used[k])[:2])
half = [k for k, v in strings.items() if isinstance(v, dict) and (not v.get("tr") or not v.get("en"))]
print("HALF-TRANSLATED:", half)
eng_words = re.compile(r"\b(item|items|skill|skills|level|damage|boss fight|loot|stash|quest|gold|attack|defense|health)\b", re.I)
bad = []
for k, v in strings.items():
    if isinstance(v, dict) and isinstance(v.get("tr"), str):
        t = v["tr"]
        if eng_words.search(t) and "Boss" not in t:
            bad.append((k, t))
print("ENGLISH WORDS IN TR:", len(bad))
for k, t in bad: print("  ", k, "|", t[:90])
# data files
for f in glob.glob(os.path.join(root, "data/*.json")):
    d = json.load(open(f))
    probs = []
    def walk(x, path):
        if isinstance(x, dict):
            if "tr" in x or "en" in x:
                if set(x.keys()) >= {"tr"} and set(x.keys()) <= {"tr", "en"}:
                    if not x.get("tr") or not x.get("en"):
                        probs.append(path)
                    elif isinstance(x["tr"], str) and eng_words.search(x["tr"]) and "Boss" not in x["tr"]:
                        probs.append(path + " EN-WORD: " + x["tr"][:60])
            for k, v in x.items():
                walk(v, path + "." + str(k))
        elif isinstance(x, list):
            for i, v in enumerate(x):
                walk(v, path + "[%d]" % i)
    walk(d, os.path.basename(f))
    if probs:
        print("DATA", os.path.basename(f), len(probs))
        for p in probs[:15]: print("  ", p)
unused = [k for k in strings if k not in used]
print("UNUSED KEYS (maybe dynamic):", len(unused))
