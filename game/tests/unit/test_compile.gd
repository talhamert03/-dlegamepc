extends RefCounted
var runner


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		_walk(dir.path_join(sub), out)


func test_all_scripts_compile() -> void:
	var files: Array = []
	_walk("res://scripts", files)
	for f in files:
		var s: Script = load(f)
		runner.check(s != null and s.can_instantiate(), "compile " + f)
