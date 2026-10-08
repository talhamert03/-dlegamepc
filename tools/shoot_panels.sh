#!/usr/bin/env bash
# Screenshot every panel + the strip into one folder, and build contact sheets for side-by-side review.
#
#   tools/shoot_panels.sh OUT_DIR [WxH] [lang]      e.g. tools/shoot_panels.sh /tmp/shots 3840x2160 en
#
# Uses the in-game screenshot mode (debug build). Each panel is opened with a mid-game save
# (lv 40, gear, loot, 15 zones cleared) so the panels have real content.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:?out dir}"
RES="${2:-1920x1080}"
LANG_ARG="${3:-tr}"
SHOTS="${XDG_DATA_HOME:-$HOME/.local/share}/IdleParty/screenshots"
PANELS="hero stats inventory stash blacksmith world growth tavern shop runes quests codex settings pets dps chests"
mkdir -p "$OUT"
cd "$ROOT/game"
# clean test profile: a settings.cfg left by an earlier run (scale, colourblind, ...) would leak into the shots
SETTINGS="${XDG_DATA_HOME:-$HOME/.local/share}/IdleParty/settings.cfg"
[ -f "$SETTINGS" ] && rm -f "$SETTINGS"
for p in $PANELS; do
	timeout 90 xvfb-run -a -s "-screen 0 ${RES}x24" godot --path . -- --fresh --screenshot --secs=3.5 \
		--open="$p" --level=40 --gear --loot --cleared=15 --scale=0 --lang="$LANG_ARG" > /dev/null 2>&1 || true
	cp "$SHOTS/panel_$p.png" "$OUT/$p.png" 2>/dev/null || echo "no shot for $p"
done
cp "$SHOTS/strip.png" "$OUT/strip.png" 2>/dev/null || true
# contact sheets: 4 panels per sheet, scaled to the same height
python3 - "$OUT" $PANELS <<'PY'
import sys, os
from PIL import Image
out, names = sys.argv[1], sys.argv[2:]
ims = [(n, Image.open(os.path.join(out, n + ".png"))) for n in names if os.path.exists(os.path.join(out, n + ".png"))]
for k in range(0, len(ims), 4):
    group = ims[k:k + 4]
    h = max(im.height for _, im in group)
    scaled = [im.resize((int(im.width * h / im.height), h)) for _, im in group]
    sheet = Image.new("RGB", (sum(s.width for s in scaled) + 10 * len(scaled), h), (40, 40, 44))
    x = 0
    for s in scaled:
        sheet.paste(s, (x, 0)); x += s.width + 10
    sheet.save(os.path.join(out, "sheet_%d.png" % (k // 4)))
print("sheets:", (len(ims) + 3) // 4)
PY
