#!/usr/bin/env bash
# Windows build smoke test on Linux: export the exe, boot it under Wine headless, then render one
# screenshot under Xvfb. Catches export-only problems (missing/broken resources) that editor runs miss.
#
#   tools/windows_smoke.sh [out_dir]
#
# Needs: godot 4.4.1 + export templates, wine, xvfb-run. Optional: rcedit configured in the Godot editor
# settings (export/windows/rcedit + export/windows/wine) for the exe icon / version info.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/export/windows_smoke}"
mkdir -p "$OUT"

echo "== export"
(cd "$ROOT/game" && godot --headless --export-release "Windows Desktop" "$OUT/IdleParty.exe" > "$OUT/export.log" 2>&1)

echo "== headless boot (600 frames + 4000 frames with a full party)"
cd "$OUT"
IDLEPARTY_DEV=1 wine IdleParty.exe --headless --quit-after 600 > boot.log 2>&1 || true
IDLEPARTY_DEV=1 wine IdleParty.exe --headless --quit-after 4000 -- --fresh --level=30 --allheroes > run.log 2>&1 || true

echo "== rendered screenshot"
wineserver -k 2>/dev/null || true   # a wineserver started by the headless runs has no display
IDLEPARTY_DEV=1 xvfb-run -a -s "-screen 0 1920x1080x24" wine IdleParty.exe -- --fresh --screenshot --secs=5 --open=hero --level=20 > shot.log 2>&1 || true

# Wine's own chatter is "NNNN:err:/fixme:/warn:"; exit-time leak notices and the missing audio device (WASAPI) are expected
bad=$(cat boot.log run.log shot.log | grep -vE '^[0-9a-f]{4}:(err|fixme|warn)' \
	| grep -E '^(ERROR|SCRIPT ERROR)' | grep -vE 'resources still in use at exit|WASAPI|hr != \(\(HRESULT\)0x00000000\)' || true)
wineserver -k 2>/dev/null || true
shots="$(wine cmd /c echo %APPDATA% 2>/dev/null | tr -d '\r')"
echo "screenshots: $(winepath -u "$shots" 2>/dev/null)/IdleParty/screenshots/"
if [ -n "$bad" ]; then
	echo "== FAIL"; echo "$bad" | sort | uniq -c
	exit 1
fi
echo "== OK"
