extends SceneTree

## Dev: hold RUN (dash) and walk right on a story street; frames saved.
##   -- <father|son> <map> <out_prefix>
var _n := 0
var _who := "father"
var _map := "dock_street"
var _out := "/tmp/run"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_who = a[0] if a.size() > 0 else _who
	_map = a[1] if a.size() > 1 else _map
	_out = a[2] if a.size() > 2 else _out


func _process(_dt: float) -> bool:
	_n += 1
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		root.get_node("App").set("solo_role", _who)
		root.get_node("App").call("enter_map", _map)
	if _n > 10 and paused:
		paused = false
	if _n == 70:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
		Input.action_press("p1_right")
	if _n == 80:
		Input.action_press("p1_dash")
	if _n == 90:
		var h: Node2D = get_first_node_in_group("players")
		for n in current_scene.find_children("*", "CanvasItem", true, false):
			if n is Node2D and absf((n as Node2D).global_position.x - h.global_position.x - 330.0) < 140.0 and absf((n as Node2D).global_position.y - h.global_position.y) < 60.0 and n.get_script() != null:
				print("NEAR ", n.name, " ", n.get_script().resource_path, " ", (n as Node2D).global_position - h.global_position)
	if _n in [90, 100, 110, 125, 140, 160]:
		root.get_texture().get_image().save_png("%s_%03d.png" % [_out, _n])
	if _n == 165:
		quit()
	return false
