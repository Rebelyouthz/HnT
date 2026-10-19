extends SceneTree

## Dying on Dock Street works end to end: a fresh night has 2 lives, each
## fall costs one and respawns at the checkpoint, the last one ends the run
## on the THERAPY'S OVER sheet, and TRY AGAIN puts the hero back on the same
## street with 2 lives. Prints DEATH OK.
##   godot --headless --fixed-fps 60 -s tests/death_test.gd

var _n := 0
var _stage := 0
var _t := 0
var _lives_seen: Array = []
var _fail: Array[String] = []


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.death_backup.json")


func _finish() -> bool:
	if _fail.is_empty():
		print("DEATH OK  lives ", _lives_seen)
	else:
		print("DEATH FAIL ", _fail, "  lives ", _lives_seen)
	if FileAccess.file_exists("user://family.death_backup.json"):
		DirAccess.copy_absolute("user://family.death_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.death_backup.json")
	return true


func _hero() -> Node:
	for p in get_nodes_in_group("players"):
		if p.has_method("_go_down"):
			return p
	return null


func _sheet() -> Node:
	if current_scene == null:
		return null
	for c in current_scene.get_children():
		if c.get("fail_gold") != null and c.get("headline") != null:
			return c
	return null


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		fp.data["intro_done"] = true
		root.get_node("App").set("solo_role", "son")
		root.get_node("App").call("start_run")
		return false
	if _n > 6000:
		_fail.append("timed out at stage %d" % _stage)
		return _finish()
	if current_scene == null or _n < 20:
		return false
	for g in get_nodes_in_group("guide"):
		g.queue_free()
	var rs := get_first_node_in_group("run_state")
	var f = _hero()
	_t += 1
	match _stage:
		0:
			# On Dock Street with a hero and a run.
			if rs and f and current_scene.scene_file_path.get_file().get_basename() == "dock_street" and _t > 200:
				_lives_seen.append(int(rs.lives))
				if int(rs.lives) != 2:
					_fail.append("a fresh night should have 2 lives, has %d" % int(rs.lives))
				_stage = 1
				_t = 0
		1, 2:
			# Knock him out; alone, he bleeds out and loses a life.
			if _t == 5 and not f.downed:
				f.call("_go_down")
			if _t > 5 and not f.downed and _t < 400:
				_lives_seen.append(int(rs.lives))
				if _stage == 1 and int(rs.lives) != 1:
					_fail.append("first fall should leave 1 life, left %d" % int(rs.lives))
				if _stage == 1 and f.hp <= 0:
					_fail.append("respawned with no hp")
				_stage += 1
				_t = 0
			elif _stage == 2 and bool(rs.failed):
				_lives_seen.append(int(rs.lives))
				_stage = 3
				_t = 0
			elif _t >= 400:
				_fail.append("fall %d never resolved" % _stage)
				return _finish()
		3:
			var sh := _sheet()
			if sh and _t > 30:
				if str(sh.get("headline")) != "THERAPY'S OVER":
					_fail.append("fail sheet says %s" % str(sh.get("headline")))
				var again: Button = null
				for b in sh.find_children("*", "Button", true, false):
					if (b as Button).text == "TRY AGAIN":
						again = b
				if again == null:
					_fail.append("no TRY AGAIN on the fail sheet")
					return _finish()
				again.pressed.emit()
				_stage = 4
				_t = 0
			elif _t > 600:
				_fail.append("no fail sheet")
				return _finish()
		4:
			if _t > 240 and rs and f and current_scene.scene_file_path.get_file().get_basename() == "dock_street":
				_lives_seen.append(int(rs.lives))
				if int(rs.lives) != 2 or bool(rs.failed):
					_fail.append("TRY AGAIN came back with %d lives (failed=%s)" % [int(rs.lives), str(rs.failed)])
				return _finish()
			if _t > 900:
				_fail.append("TRY AGAIN never got back to Dock Street (scene %s)" % current_scene.scene_file_path)
				return _finish()
	return false
