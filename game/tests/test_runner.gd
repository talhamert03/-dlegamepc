extends Node
## Minimal headless test runner. Run with:
##   godot --headless res://tests/TestRunner.tscn
## Every script in res://tests/unit/ whose methods start with "test_" is executed.

var failures := 0
var passed := 0
var current := ""


func _ready() -> void:
	await get_tree().process_frame
	var dir := DirAccess.open("res://tests/unit")
	var files: Array = []
	for f in dir.get_files():
		if f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		var scr: Script = load("res://tests/unit/" + f)
		var inst: Object = scr.new()
		if inst.has_method("setup"):
			inst.call("setup")
		for m in inst.get_method_list():
			var n: String = m["name"]
			if n.begins_with("test_"):
				current = f + ":" + n
				inst.set("runner", self)
				var before := failures
				await inst.call(n)
				if failures == before:
					passed += 1
					print("  ok   ", current)
	print("\n%d passed, %d failed" % [passed, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg := "") -> void:
	if not cond:
		failures += 1
		printerr("  FAIL ", current, " ", msg)


func near(a: float, b: float, tol: float, msg := "") -> void:
	check(abs(a - b) <= tol, "%s expected %s got %s" % [msg, b, a])
