extends SceneTree

## A new player's first nights, scene by scene: prologue, the alley lesson,
## Dock Street (turned back at Gant), the hideout (one thing: the QUEST
## BOARD), the portal (Dock Street again, never the alley), back home (now
## the couch and THICK SKIN). Prints NIGHT FLOW OK with the scene trail.

var _n := 0
var _t0 := 0
var _stage := 0
var _trail: Array = []
var _fail: Array = []
var _last := ""


func _scene() -> String:
	return current_scene.scene_file_path.get_file().get_basename() if current_scene else ""


func _check(c: bool, what: String) -> void:
	if not c:
		_fail.append(what)


func _steps() -> Array:
	var fp := root.get_node("FamilyProfile")
	var hop: String = fp.call("next_run_map")
	return load("res://src/ui/errand_guide.gd").steps(hop)


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	var sc := _scene()
	if sc != _last and sc != "":
		_last = sc
		_trail.append(sc)
		_t0 = _n
	var fp := root.get_node("FamilyProfile")
	var app := root.get_node("App")
	if _n == 2:
		fp.call("reset_progress")
		var g: Array = []
		for gk in load("res://src/ui/guides.gd").STEPS:
			g.append(str(gk))
		fp.data["guides_done"] = g
		app.set("solo_role", "father")
		app.call("play_intro")
		return false
	if _n - _t0 < 40:
		return false
	match _stage:
		0:
			if sc == "prologue":
				current_scene.call("_finish")
				_stage = 1
		1:
			if sc == "tutorial_alley":
				current_scene.call("_finish_intro")
				_stage = 2
		2:
			if sc == "dock_street":
				_check(bool(fp.data.get("intro_done", false)), "intro marked done after the alley")
				# Turned back at Gant: the night ends, home to the hideout.
				fp.call("mark_run_finished", false)
				app.call("back_to_hub", "clinic")
				_stage = 3
		3:
			if sc == "camp":
				var st := _steps()
				_check(st.size() == 1 and str(st[0].get("id", "")) == "bounty_board", "night 1 is only the quest board (got %s)" % str(st.map(func(x: Dictionary) -> String: return str(x.get("id", "")))))
				fp.data["gold"] = 999
				fp.call("try_build", "bounty_board")
				_check(_steps().is_empty(), "after the board the night is done (got %s)" % str(_steps()))
				_check(not (fp.data.get("guides_done", []) as Array).has("errand_dock_street"), "the couch talk is kept for night 2")
				app.call("leave_camp")
				_stage = 4
		4:
			if sc == "tutorial_alley" or sc == "prologue":
				_fail.append("the portal sent us back to %s" % sc)
				_stage = 99
			elif sc == "dock_street":
				fp.call("mark_run_finished", false)
				app.call("back_to_hub", "clinic")
				_stage = 5
		5:
			if sc == "camp":
				var st2 := _steps()
				var ids: Array = st2.map(func(x: Dictionary) -> String: return str(x.get("what", "")) + ":" + str(x.get("id", "")))
				_check(ids.has("BUILD:therapy_couch") or ids.has("LEARN:thick_skin"), "night 2 brings the couch / skill tree (got %s)" % str(ids))
				_stage = 6
		6:
			# Dad and the Kid explain the couch and THICK SKIN tonight (the
			# talk was not used up on the quest board night).
			var told := false
			for g in get_nodes_in_group("guide"):
				if str(g.get("id")) == "errand_dock_street":
					told = true
			if told:
				_stage = 99
			elif _n - _t0 > 400:
				_fail.append("night 2: no couch / skill tree talk")
				_stage = 99
		99:
			print("NIGHT FLOW OK " if _fail.is_empty() else "NIGHT FLOW FAIL %s " % str(_fail), _trail)
			quit(0 if _fail.is_empty() else 1)
	if _n > 60 * 90:
		print("NIGHT FLOW TIMEOUT stage=", _stage, " ", _trail)
		quit(1)
	return false
