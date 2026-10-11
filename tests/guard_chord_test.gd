extends SceneTree

## The strikes that used to need UP / DOWN on the stick are guard chords:
## BLOCK + HEAVY throws the uppercut without walking up the lane, and UP +
## HEAVY is a plain heavy now. Prints CHORD OK.

var _n := 0
var _p: Node2D = null
var _y0 := 0.0
var _bad: Array[String] = []
var _saw := ""


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.chord_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		fp.data["intro_done"] = true
		var dj: Dictionary = fp.data.get("dojo", {})
		dj["uppercut"] = 1
		fp.data["dojo"] = dj
		change_scene_to_file("res://scenes/levels/tutorial_alley.tscn")
	if _n == 200:
		paused = false
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		_p = get_first_node_in_group("players")
		print("uppercut learned: ", fp.call("dojo_learned", "uppercut"))
		_y0 = _p.global_position.y
		Input.action_press("p1_block")
	if _n == 206:
		Input.action_press("p1_heavy")
	if _n > 206 and _n < 230 and _p.get("_strike_clip") != "":
		if _saw == "":
			_saw = str(_p.get("_strike_clip")) + "/" + str(_p.get("anim_atk"))
	if _n == 210:
		Input.action_release("p1_heavy")
	if _n == 230:
		Input.action_release("p1_block")
		if not _saw.contains("uppercut"):
			_bad.append("BLOCK + HEAVY gave '%s', not the uppercut" % _saw)
		if absf(_p.global_position.y - _y0) > 2.0:
			_bad.append("moved %.1f along the lane" % (_p.global_position.y - _y0))
		_saw = ""
	if _n == 260:
		Input.action_press("p1_up")
		Input.action_press("p1_heavy")
	if _n == 264:
		Input.action_release("p1_heavy")
	if _n > 264 and _n < 290 and _saw == "" and _p.get("_strike_clip") != "":
		_saw = str(_p.get("_strike_clip")) + "/" + str(_p.get("anim_atk"))
	if _n == 290:
		Input.action_release("p1_up")
		if _saw.contains("uppercut"):
			_bad.append("UP + HEAVY still throws the uppercut")
		print("CHORD OK" if _bad.is_empty() else "CHORD FAIL " + str(_bad))
		if FileAccess.file_exists("user://family.chord_backup.json"):
			DirAccess.copy_absolute("user://family.chord_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.chord_backup.json")
		quit(0 if _bad.is_empty() else 1)
	return false
