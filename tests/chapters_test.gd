extends SceneTree

## Every story chapter from map 3 on loads with its own street content: three
## side quests of its own, three spray cans, a blessing machine, and (where
## it has one) its signature hazard. Prints CHAPTERS OK on success.
##   godot --headless --fixed-fps 60 -s tests/chapters_test.gd

const MAPS := {
	"neon_exchange": "smile_cams",
	"rail_bridge": "freight_line",
	"city_hall": "cabinet_drop",
	"copay_orchard": "",
	"raven_grid": "",
	"invoice_pier": "cabinet_drop",
	"processing_floor": "",
}

var _n := 0
var _i := 0
var _keys: Array = []
var _fail: Array[String] = []


func _initialize() -> void:
	_keys = MAPS.keys()
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.chapters_backup.json")


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
	var step := (_n - 2) % 160
	if _n >= 2 and step == 0:
		if _i >= _keys.size():
			if _fail.is_empty():
				print("CHAPTERS OK")
			else:
				print("CHAPTERS FAIL ", _fail)
			if FileAccess.file_exists("user://family.chapters_backup.json"):
				DirAccess.copy_absolute("user://family.chapters_backup.json", "user://family.json")
				DirAccess.remove_absolute("user://family.chapters_backup.json")
			return true
		var id: String = _keys[_i]
		root.get_node("App").set("current_map", id)
		change_scene_to_file("res://scenes/levels/%s.tscn" % id)
	if _n >= 2 and step == 120:
		var id2: String = _keys[_i]
		var own := 0
		var cans := 0
		var machines := 0
		var quests: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/side_quests.json")) as Dictionary).get(id2, [])
		var ids: Array = []
		for q in quests:
			ids.append(str(q.get("id", "")))
		for n in current_scene.get_children():
			var sc: Script = n.get_script()
			var path := sc.resource_path if sc else ""
			if path.ends_with("quest_giver.gd") and ids.has(str((n.get("quest") as Dictionary).get("id", ""))):
				own += 1
			elif path.ends_with("spray_can.gd"):
				cans += 1
			elif n.get("uses") != null and n.get("_prompt") != null:
				# BlessingMachine is an inner class of night_extras.gd.
				machines += 1
		if own < 3:
			_fail.append("%s quests %d" % [id2, own])
		if cans != 3:
			_fail.append("%s cans %d" % [id2, cans])
		if machines < 1:
			_fail.append("%s no machine" % id2)
		var grp: String = MAPS[id2]
		if grp != "" and get_nodes_in_group(grp).is_empty():
			_fail.append("%s no %s" % [id2, grp])
		_i += 1
	return false
