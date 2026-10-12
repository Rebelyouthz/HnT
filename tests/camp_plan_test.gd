extends SceneTree

## The hideout plan after the first night out: the QUEST BOARD is tonight's
## build (the arrow's first step), then the THERAPY COUCH (skill tree) from
## the story gate; two rooms a night, then a run resets the count.
## Prints CAMP PLAN OK.

var _n := 0


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.plan_backup.json")


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var fp := root.get_node("FamilyProfile")
	var app := root.get_node("App")
	var keep := str(app.get("difficulty"))
	app.set("difficulty", "night_class")
	fp.call("reset_progress")
	var fail: Array[String] = []
	var d: Dictionary = fp.get("data")
	d["runs"] = 1
	d["night_builds"] = 0
	d["gold"] = 500
	var guide: GDScript = load("res://src/ui/errand_guide.gd")
	var steps: Array = guide.call("steps", "dock_street")
	if steps.is_empty() or str(steps[0].get("id", "")) != "bounty_board":
		fail.append("first step not the quest board: %s" % [steps])
	if not fp.call("try_build", "bounty_board"):
		fail.append("quest board would not build")
	steps = guide.call("steps", "dock_street")
	if steps.is_empty() or str(steps[0].get("id", "")) != "therapy_couch":
		fail.append("second step not the couch: %s" % [steps])
	fp.call("try_build", "therapy_couch")
	if int(d.get("night_builds", 0)) != 2:
		fail.append("night_builds %d after two rooms" % int(d.get("night_builds", 0)))
	if str(guide.call("night_room")) != "":
		fail.append("a third room offered the same night")
	fp.call("mark_run_finished", false)
	if int(d.get("night_builds", 0)) != 0:
		fail.append("a night out did not reset the count")
	app.set("difficulty", keep)
	fp.call("reset_progress")
	if FileAccess.file_exists("user://family.plan_backup.json"):
		DirAccess.copy_absolute("user://family.plan_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.plan_backup.json")
	print("CAMP PLAN OK" if fail.is_empty() else "CAMP PLAN FAIL %s" % [fail])
	return true
