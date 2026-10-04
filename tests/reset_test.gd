extends SceneTree

## Reset must leave a clean save: no backups, defaults everywhere, only the
## options kept.  godot --headless --script res://tests/reset_test.gd

var _n := 0


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	var fp := root.get_node("FamilyProfile")
	var had := FileAccess.file_exists("user://family.json")
	if had:
		DirAccess.copy_absolute("user://family.json", "user://reset_test_keep.tmp")
	fp.data["gold"] = 9999
	fp.data["gems"] = 77
	fp.data["vol_music"] = 0.31
	(fp.data["cbt"] as Array).append("thick_skin")
	fp.save()
	for extra in ["user://family.json.bak", "user://family-2026.bak.json", "user://open_room.json"]:
		var f := FileAccess.open(extra, FileAccess.WRITE)
		f.store_string("{}")
		f.close()
	fp.reset_progress()
	var ok := true
	for extra in ["user://family.json.bak", "user://family-2026.bak.json", "user://open_room.json"]:
		if FileAccess.file_exists(extra):
			push_error("left behind: " + extra)
			ok = false
	if int(fp.data["gold"]) == 9999 or int(fp.data["gems"]) == 77 or (fp.data["cbt"] as Array).has("thick_skin"):
		push_error("progress survived the reset")
		ok = false
	if not is_equal_approx(float(fp.data["vol_music"]), 0.31):
		push_error("options were not kept")
		ok = false
	if had:
		DirAccess.copy_absolute("user://reset_test_keep.tmp", "user://family.json")
		DirAccess.remove_absolute("user://reset_test_keep.tmp")
	print("RESET OK" if ok else "RESET FAILED")
	quit(0 if ok else 1)
	return true
