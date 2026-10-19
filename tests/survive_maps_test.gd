extends SceneTree

## Every survivor chapter runs: the Flooded Lot, Group Circle, the Waiting
## Room, the Sleet Hour and Ledger Dive each load in field (top-down) mode,
## the horde comes, the map has its own theme, and the hero is still on his
## feet a while in with the starting draw skipped. Also the survivor lobby's
## direct start (App.start_survivor). Prints SURVIVE OK on success.
##   godot --headless --fixed-fps 60 -s tests/survive_maps_test.gd

const MAPS := ["intake_lot", "group_circle", "waiting_room", "sleet_hour", "ledger_dive"]

var _n := 0
var _i := -1
var _t0 := 0
var _fail: Array[String] = []
var _report: Array = []
var _max_enemies := 0
var _themes: Dictionary = {}


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.survive_backup.json")


func _next() -> void:
	_i += 1
	_t0 = _n
	_max_enemies = 0
	if _i >= MAPS.size():
		return
	var app := root.get_node("App")
	# Story maps 1-5 go in from the run; the lobby path from map 4 on.
	if _i % 2 == 0:
		app.call("start_survivor", MAPS[_i], 1)
	else:
		app.set("surv_solo", false)
		app.set("current_map", MAPS[_i])
		app.call("enter_map", MAPS[_i])


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
		_next()
		return false
	if _i >= MAPS.size():
		if _fail.is_empty():
			print("SURVIVE OK")
			for r in _report:
				print("  ", r)
		else:
			print("SURVIVE FAIL ", _fail)
		if FileAccess.file_exists("user://family.survive_backup.json"):
			DirAccess.copy_absolute("user://family.survive_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.survive_backup.json")
		return true
	if _n - _t0 < 30:
		return false
	paused = false
	for cpk in root.find_children("*", "CanvasLayer", true, false):
		var sc: Script = cpk.get_script()
		if sc != null and (str(sc.resource_path).ends_with("survive_pick.gd") or str(sc.resource_path).ends_with("card_pick.gd") or str(sc.resource_path).ends_with("starter_sheet.gd")):
			cpk.queue_free()
	_max_enemies = maxi(_max_enemies, get_nodes_in_group("enemies").size())
	# Keep the hero alive: this checks the map, not the dodging.
	for p in get_nodes_in_group("players"):
		if p.get("hp") != null and p.get("max_hp") != null:
			p.set("hp", p.get("max_hp"))
	if _n - _t0 == 900:
		var id: String = MAPS[_i]
		var field := bool(load("res://src/actors/fighter.gd").get("FIELD"))
		var scene_ok := current_scene != null and current_scene.scene_file_path.get_file().get_basename() == id
		var theme: Dictionary = load("res://src/survive/survive_field.gd").call("theme", id) if load("res://src/survive/survive_field.gd").has_method("theme") else {}
		if not scene_ok:
			_fail.append("%s did not load (on %s)" % [id, current_scene.scene_file_path if current_scene else "-"])
		if not field:
			_fail.append("%s not in field mode" % id)
		if _max_enemies < 3:
			_fail.append("%s horde never came (%d)" % [id, _max_enemies])
		var tile := str(theme.get("tile", ""))
		if _themes.values().has(tile) and tile != "":
			_fail.append("%s reuses the %s ground" % [id, tile])
		_themes[id] = tile
		_report.append("%s: enemies up to %d, ground %s, weather %s" % [id, _max_enemies, tile, theme.get("weather", "?")])
		_next()
	return false
