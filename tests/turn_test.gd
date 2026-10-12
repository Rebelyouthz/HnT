extends SceneTree
## Facing right, LEFT held + LIGHT: the hero whips round (turn_punch clip)
## and faces left; with no stick a light is an ordinary jab facing the same
## way. Prints TURN OK.

var _n := 0
var ok := true
var _h: Node2D


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("FamilyProfile").data["intro_done"] = true
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "dock_street")
	if _n > 40 and paused:
		paused = false
	if _n == 60:
		for c in current_scene.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("stage_card.gd"):
				c.queue_free()
		_h = get_first_node_in_group("players")
		_h.set("facing", 1)
	if _n == 70:
		Input.action_press("p1_left")
	if _n == 72:
		Input.action_press("p1_light")
	if _n == 74:
		Input.action_release("p1_light")
	if _n == 78:
		_check(int(_h.get("facing")) == -1, "faces the way he steered (got %d)" % int(_h.get("facing")))
		_check(str(_h.get("_strike_clip")) == "turn_punch", "spins into turn_punch (got %s)" % _h.get("_strike_clip"))
		Input.action_release("p1_left")
	if _n == 140:
		Input.action_press("p1_light")
	if _n == 142:
		Input.action_release("p1_light")
	if _n == 146:
		_check(str(_h.get("_strike_clip")) != "turn_punch", "a plain light is not a turn (got %s)" % _h.get("_strike_clip"))
		print("TURN OK" if ok else "TURN FAILED")
		quit()
	return false
