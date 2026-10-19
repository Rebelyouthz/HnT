extends SceneTree

## The run's STARTING DRAW waits for the first thug down, not the first step.
## Prints FIRST DRAW OK.

var _n := 0
var ok := true


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _pick() -> Node:
	return current_scene.get_node_or_null("CardPick") if current_scene else null


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("App").call("enter_map", "dock_street")
	# Title card closes itself; give the street a long look.
	if _n == 30:
		for c in current_scene.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("stage_card.gd"):
				c.queue_free()
				c.emit_signal("closed")
	if _n == 700:
		_check(_pick() == null, "no card pick before any kill")
		var killed := false
		for e in get_nodes_in_group("enemies"):
			if e.has_method("_die") and e.is_inside_tree():
				e.call("_die", "light", get_first_node_in_group("players"))
				killed = true
				break
		_check(killed, "found a thug to drop")
	# First-use guides / the pre-start hold pause the street; a player
	# closes them, the test just lets time run.
	if _n > 40 and paused:
		paused = false
	if _n == 900:
		_check(_pick() != null, "starting draw after the first kill")
		print("FIRST DRAW OK" if ok else "FIRST DRAW FAILED")
		quit()
	return false
