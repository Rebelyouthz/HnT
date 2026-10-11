extends SceneTree

## Dev probe (godot --headless -s res://tools/dev/hero_size_probe.gd, HERO=son|father MAP=id):
## logs each hero's drawn body height (frame height x global scale) and
## clip while the solo player walks into a fight. Dev probe.

var _n := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.size_backup.json")


func _h(f: Node) -> String:
	var a := f.get("_anim") as AnimatedSprite2D
	if a == null:
		return "-"
	var tex := a.sprite_frames.get_frame_texture(a.animation, a.frame)
	var reg := (tex as AtlasTexture).region.size.y if tex is AtlasTexture else 0.0
	var gs := a.get_global_transform().get_scale()
	var sq: Node2D = f.get("squash_root")
	return "%s/%s f%d gs=%.3f sq=%.2f vis=%.2f body=%.0f" % [f.get("role"), a.animation, a.frame, absf(gs.y), sq.scale.y if sq else 1.0, absf((f.get("visual") as Node2D).scale.y), reg * absf(gs.y)]


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
		root.get_node("App").set("solo_role", OS.get_environment("HERO") if OS.get_environment("HERO") != "" else "father")
		change_scene_to_file("res://scenes/levels/" + (OS.get_environment("MAP") if OS.get_environment("MAP") != "" else "dock_street") + ".tscn")
	if _n == 150:
		paused = false
		Input.action_press("p1_right")
	if _n > 150 and _n % 30 == 0:
		paused = false
		var line := "t%d " % _n
		for f in get_nodes_in_group("players"):
			line += " | " + _h(f)
		print(line)
	if _n == 400:
		Input.action_release("p1_right")
	if _n > 400 and _n % 12 == 0:
		Input.action_press("p1_light")
	if _n > 400 and _n % 12 == 6:
		Input.action_release("p1_light")
	if _n == 1000:
		if FileAccess.file_exists("user://family.size_backup.json"):
			DirAccess.copy_absolute("user://family.size_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.size_backup.json")
		quit()
	return false
