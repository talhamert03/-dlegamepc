#!/usr/bin/env bash
# Runs the headless test-suite; fails on test failures or any script error.
set -o pipefail
cd "$(dirname "$0")"
godot --headless --import >/dev/null 2>&1 || true
out=$(godot --headless res://tests/TestRunner.tscn 2>&1)
code=$?
echo "$out" | grep -vE "^\s*$|Godot Engine"
if echo "$out" | grep -q "SCRIPT ERROR"; then
  echo "Script errors detected"; exit 1
fi
exit $code
