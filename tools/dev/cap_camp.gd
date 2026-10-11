extends SceneTree

## Dev shot of the hideout as a fresh save sees it (story errand open):
## xvfb-run godot --path . --script res://tools/dev/cap_camp.gd -- <station_id|-> <out.png> [build]

var _n := 0
var _args := PackedStringArray()


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.cap_backup.json")


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
		fp.data["gold"] = 300
		fp.data["errand_told_dock_street"] = true
		if _args.size() > 2:
			fp.data["crew_benny"] = true
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 40 and current_scene != null:
		for gd in get_nodes_in_group("guide"):
			gd.queue_free()
		paused = false
		var tk: Object = current_scene.get("_talk")
		if tk != null and tk.has_method("_close"):
			tk.call("_close")
		var id := _args[0] if _args.size() > 0 else "-"
		for st: Dictionary in current_scene.get("_stations"):
			if str(st["id"]) == id:
				current_scene.get("_walker").position.x = float(st["x"])
				if _args.size() > 2 and _args[2] == "build":
					current_scene.call("_construct", st, true)
	if _n == 320 and _args.size() > 2:
		for st: Dictionary in current_scene.get("_stations"):
			if str(st["id"]) == _args[0]:
				print("crew: ", current_scene.get("_crew").keys(), " busy ", current_scene.get("_busy"), " paused ", paused)
				print("station children: ", (st["node"] as Node).get_children().map(func(c: Node) -> String: return c.get_class()))
	if _args.size() > 2 and _n in [50, 62, 74, 86, 100, 130, 160, 190, 220]:
		root.get_texture().get_image().save_png(_args[1].replace(".png", "_%d.png" % _n))
	if _n == (330 if _args.size() > 2 else 100):
		var img := root.get_texture().get_image()
		img.save_png(_args[1] if _args.size() > 1 else "user://cap.png")
		if FileAccess.file_exists("user://family.cap_backup.json"):
			DirAccess.copy_absolute("user://family.cap_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.cap_backup.json")
		quit()
	return false
