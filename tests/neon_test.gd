extends SceneTree

## Chapter 5 (Neon Exchange) check: the map loads with its smile cams, side
## quests, Dot's cage and spray cans; punching breaks a smash prop and a
## smile cam (Area2D smashables take the hit themselves); a cam that sees
## the player bills an agent; Dot's crew perk is off until she is rescued.
## Prints NEON OK on success.
##   godot --headless --fixed-fps 60 -s tests/neon_test.gd

var _n := 0
var _p: Node2D = null
var _prop: Node = null
var _cam: Node = null
var _fail: Array[String] = []
var _agents0 := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.neon_backup.json")


func _agents() -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if str(e.get("title")) == "Agent Lin":
			n += 1
	return n


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
		root.get_node("App").set("current_map", "neon_exchange")
		change_scene_to_file("res://scenes/levels/neon_exchange.tscn")
	if _n == 220:
		paused = false
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		if get_nodes_in_group("smile_cams").size() != 5:
			_fail.append("smile cams %d" % get_nodes_in_group("smile_cams").size())
		var cages := 0
		var givers := 0
		var cans := 0
		for n in current_scene.get_children():
			var sc: Script = n.get_script()
			var path := sc.resource_path if sc else ""
			if path.ends_with("rescue_cage.gd"):
				cages += 1
			elif path.ends_with("quest_giver.gd"):
				givers += 1
			elif path.ends_with("spray_can.gd"):
				cans += 1
		if cages != 1:
			_fail.append("cages %d" % cages)
		if givers < 3:
			_fail.append("quest givers %d" % givers)
		if cans != 3:
			_fail.append("spray cans %d" % cans)
		if float(load("res://src/story/story_book.gd").crew_gold_mul()) != 1.0:
			_fail.append("dot perk before rescue")
		_p = get_first_node_in_group("players")
		# A prop and a cam right in front of the player, nothing else near.
		_prop = load("res://src/world/smash_prop.gd").place(current_scene, _p.global_position + Vector2(40, 0), "booth")
		_cam = load("res://src/world/smile_cam.gd").place(current_scene, _p.global_position + Vector2(40, 10))
		_cam.set("reach", 0.0)
		_p.set("facing", 1)
	if _n > 220 and _n < 640:
		paused = false
	for k in [240, 262, 284, 306, 328, 350, 372, 394, 416, 438, 460, 482]:
		if _n == k:
			Input.action_press("p1_light")
		if _n == k + 4:
			Input.action_release("p1_light")
	if _n == 520:
		if not bool(_cam.get("_dead")):
			_fail.append("smile cam not broken by punches")
		if is_instance_valid(_prop) and not _prop.is_queued_for_deletion() and int(_prop.get("_dmg")) <= 0:
			_fail.append("smash prop took no damage")
		_agents0 = _agents()
		# A second cam that stares straight down on the player.
		var c2: Node = load("res://src/world/smile_cam.gd").place(current_scene, _p.global_position + Vector2(-70, 0))
		c2.set("phase", -PI * 0.5)
		c2.set("spread", PI)
		# The starting card draw re-pauses the tree every frame; a cam added
		# after it in the tree would never tick in this headless run.
		c2.process_mode = Node.PROCESS_MODE_ALWAYS
	if _n == 640:
		if _agents() <= _agents0:
			_fail.append("cam did not bill an agent")
		root.get_node("FamilyProfile").data["crew_dot"] = true
		if float(load("res://src/story/story_book.gd").crew_gold_mul()) <= 1.0:
			_fail.append("dot perk missing")
		if _fail.is_empty():
			print("NEON OK")
		else:
			print("NEON FAIL ", _fail)
		if FileAccess.file_exists("user://family.neon_backup.json"):
			DirAccess.copy_absolute("user://family.neon_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.neon_backup.json")
		return true
	return false
