extends SceneTree

## Buying a fighting move leaves it untrained: off the mat it is locked,
## on the dojo mat it works, and three clean reps on the dummy make it
## street-ready. Prints DOJO TRAIN OK.

var _n := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.train2_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var fp := root.get_node("FamilyProfile")
	var app := root.get_node("App")
	fp.call("reset_progress")
	var fail: Array[String] = []
	fp.data["buildings"]["dojo"] = 1
	fp.data["gold"] = 500
	if not fp.call("try_dojo", "haymaker"):
		fail.append("could not buy")
	app.set("current_map", "dock_street")
	if fp.call("dojo_learned", "haymaker"):
		fail.append("usable in the street before training")
	app.set("current_map", "dojo_practice")
	if not fp.call("dojo_learned", "haymaker"):
		fail.append("not usable on the mat")
	if not (fp.call("dojo_pending") as Array).has("haymaker"):
		fail.append("not pending")
	var ready := false
	for i in 3:
		ready = fp.call("dojo_rep", "haymaker")
	app.set("current_map", "dock_street")
	if not ready or not fp.call("dojo_learned", "haymaker"):
		fail.append("three reps did not make it street-ready")
	if FileAccess.file_exists("user://family.train2_backup.json"):
		DirAccess.copy_absolute("user://family.train2_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.train2_backup.json")
	print("DOJO TRAIN OK" if fail.is_empty() else "DOJO TRAIN FAIL %s" % [fail])
	return true
