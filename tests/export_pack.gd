extends SceneTree

## Boot the SHIPPED exe's pack, not the project. FileAccess cannot see imported
## PNGs inside an export, so sprite code can pass in the editor and ship blank.
## godot --headless --main-pack build/windows/FatherAndSon.exe --script res://tests/export_pack.gd


func _initialize() -> void:
	var bad := 0
	for who in ["father", "son"]:
		if SpriteBook.frames(who).get_animation_names().size() < 2:
			push_error("%s has no clips in the pack" % who)
			bad += 1
	var sets := 0
	var d := DirAccess.open("res://assets/sprites")
	if d == null:
		push_error("assets/sprites missing from the pack")
		bad += 1
	else:
		for who in d.get_directories():
			if SpriteBook.has_who(who):
				sets += 1
	if sets < 20:
		push_error("only %d living sprite sets load from the pack" % sets)
		bad += 1
	if SpriteBook.tile("brick") == null:
		push_error("dock tiles missing from the pack")
		bad += 1
	if SpriteBook.icon("blood_fridge") == null:
		push_error("hub icons missing from the pack")
		bad += 1
	var main := str(ProjectSettings.get_setting("application/run/main_scene"))
	if not (load(main) is PackedScene):
		push_error("main scene %s does not load" % main)
		bad += 1
	if not FileAccess.file_exists("res://data/story.json"):
		push_error("data/*.json missing from the pack")
		bad += 1
	if bad > 0:
		quit(1)
		return
	print("EXPORT_PACK_OK sets=%d" % sets)
	quit()
