extends SceneTree

## Every script under res://src loads and compiles (a parse error in one
## scene's script only shows when that scene opens). Prints SCRIPTS OK.

var _bad: Array[String] = []


func _walk(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var path := dir.path_join(f)
			var s: Variant = load(path)
			if s == null or not (s as GDScript).can_instantiate():
				_bad.append(path)
	for d in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(d))


func _initialize() -> void:
	_walk("res://src")
	print("SCRIPTS OK" if _bad.is_empty() else "SCRIPTS FAIL " + str(_bad))
	quit(0 if _bad.is_empty() else 1)
