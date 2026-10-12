extends SceneTree

## Screenshots of the first story errand (needs a renderer):
## xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/errand_show.gd -- <out_prefix>

var _n := 0
var _out := "user://errand"
var _shots := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.show_backup.json")


func _snap() -> void:
	_shots += 1
	root.get_texture().get_image().save_png("%s_%d.png" % [_out, _shots])


func _press(key: String) -> void:
	for c in root.find_children("*", "Control", true, false):
		if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree() and c is BaseButton:
			(c as BaseButton).pressed.emit()
			return


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		fp.data["named"] = true
		change_scene_to_file("res://scenes/levels/camp.tscn")
	match _n:
		330:
			_snap()
		460:
			_snap()
		520:
			var g2 := root.find_children("*", "CanvasLayer", true, false)
			for c in g2:
				if c.is_in_group("guide"):
					c.queue_free()
		560:
			_snap()
			current_scene.call("_open_hub", "clinic")
		640:
			_snap()
			_press("card_therapy_couch")
		700:
			_snap()
			_press("build_btn_therapy_couch")
		780:
			_snap()
			_press("tab_build")
		860:
			_snap()
		900:
			if FileAccess.file_exists("user://family.show_backup.json"):
				DirAccess.copy_absolute("user://family.show_backup.json", "user://family.json")
				DirAccess.remove_absolute("user://family.show_backup.json")
			return true
	return false
