extends SceneTree

## A family that cleared Dock Street without the couch (Easy used to skip the
## gate) is walked back to THICK SKIN first, then on to the next map's buy.
## Easy keeps the story gates. Prints CATCHUP OK.

var _n := 0


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var fp := root.get_node("FamilyProfile")
	var app := root.get_node("App")
	var bak := ""
	if FileAccess.file_exists("user://family.json"):
		bak = FileAccess.get_file_as_string("user://family.json")
	var fail: Array[String] = []
	fp.call("reset_progress")
	app.set("difficulty", "open_house")
	app.set("camp_next", "")
	fp.call("mark_map_filed", "dock_street")
	var eg: GDScript = load("res://src/ui/errand_guide.gd")
	var pb: GDScript = load("res://src/app/power_book.gd")
	if eg.errand_map() != "dock_street":
		fail.append("catch-up map is %s" % eg.errand_map())
	if not pb.story_shops().has("therapy_couch"):
		fail.append("couch not a story shop: %s" % pb.story_shops())
	(fp.data["buildings"] as Dictionary)["therapy_couch"] = 1
	(fp.data["cbt"] as Array).append("thick_skin")
	if eg.errand_map() != "intake_lot":
		fail.append("after catch-up map is %s" % eg.errand_map())
	if bak != "":
		var f := FileAccess.open("user://family.json", FileAccess.WRITE)
		f.store_string(bak)
		f.close()
	print("CATCHUP OK" if fail.is_empty() else "CATCHUP FAIL %s" % [fail])
	return true
