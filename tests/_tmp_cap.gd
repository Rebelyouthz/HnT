extends SceneTree

var _n := 0
var _f: Node2D
const OUT := "/tmp/claude-0/-home-user-Cursor-game/c1368381-f1a9-5ff4-8de3-c7ed53e24c3a/scratchpad/sorc7/"


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	for g in get_nodes_in_group("guide"):
		g.queue_free()
	if _n == 2:
		root.get_node("FamilyProfile").call("reset_progress")
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "tutorial_alley")
	if _n == 150:
		for f in get_nodes_in_group("players"):
			_f = f
	if _n == 200:
		Input.action_press("p1_light")
	if _n == 203:
		Input.action_release("p1_light")
	if _n > 200 and _n < 240 and _f and str(_f.get("_strike_phase")) == "2" and not FileAccess.file_exists(OUT + "hitX.png"):
		_shot("hitX")
	if _n == 280:
		Input.action_press("p1_heavy")
	if _n == 283:
		Input.action_release("p1_heavy")
	if _n > 283 and _n < 330 and _f and str(_f.get("_strike_phase")) == "2" and not FileAccess.file_exists(OUT + "hitY.png"):
		_shot("hitY")
	if _n == 340:
		quit()
	return false
