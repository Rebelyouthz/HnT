extends SceneTree

## Street walk picks the smooth profile walk for straight and diagonal
## moves, the back/front walk only straight up/down the lane. Prints the
## clip, the playback rate and the speed for each.

var _n := 0
var _p: Node2D = null
var _seen := {}


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.walk_backup.json")


func _rec(tag: String) -> void:
	var a := _p.get("_anim") as AnimatedSprite2D
	var v: Vector2 = _p.get("velocity")
	var fps := a.sprite_frames.get_animation_speed(a.animation) * a.speed_scale
	_seen[tag] = str(a.animation)
	print("%-6s clip=%-12s speed=%.2f frames/s=%.1f v=(%.0f,%.0f)" % [tag, a.animation, a.speed_scale, fps, v.x, v.y])


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
		var app := root.get_node("App")
		app.set("solo_role", OS.get_environment("HERO") if OS.get_environment("HERO") != "" else "son")
		change_scene_to_file("res://scenes/levels/tutorial_alley.tscn")
	if _n == 200:
		paused = false
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_p = get_first_node_in_group("players")
		Input.action_press("p1_right")
	if _n == 240:
		_rec("right")
		Input.action_press("p1_up")
	if _n == 270:
		_rec("diag")
		Input.action_release("p1_right")
	if _n == 300:
		_rec("up")
		Input.action_release("p1_up")
	if _n == 310:
		var ok: bool = _seen.get("right") == "walk" and _seen.get("diag") == "walk"
		print("WALK CLIP OK" if ok else "WALK CLIP FAIL")
		if FileAccess.file_exists("user://family.walk_backup.json"):
			DirAccess.copy_absolute("user://family.walk_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.walk_backup.json")
		quit(0 if ok else 1)
	return false
