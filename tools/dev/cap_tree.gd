extends SceneTree
## Dev: the BONE YARD tree over the camp, saved.  -- <out.png>
var _n := 0
var _out := "/tmp/tree.png"
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else _out
func _process(_d: float) -> bool:
	_n += 1
	paused = false
	if _n == 2:
		var fp := root.get_node("FamilyProfile")
		fp.data["intro_done"] = true
		fp.data["guides_done"] = ["boneyard_tree"]
		fp.data["maps_filed"] = ["dock_street", "intake_lot", "fire_escapes", "group_circle"]
		fp.data["brutal"] = ["arm_breaker", "knee_snap", "neck_crack", "eye_gouge"]
		fp.data["dojo_train"] = {"b_eye_gouge": 1}
		fp.data["fight_tokens"] = 3
		root.get_node("App").call("enter_map", "camp")
	if _n == 30:
		var cl := CanvasLayer.new()
		cl.layer = 120
		current_scene.add_child(cl)
		var host := Control.new()
		cl.add_child(host)
		var t: Control = load("res://src/ui/bone_tree.gd").new()
		load("res://src/ui/ui_kit.gd").call("open_over", host, t)
	if _n == 40:
		for g in get_nodes_in_group("guide"):
			g.queue_free()
	if _n == 69:
		for c in root.get_children():
			print("ROOT ", c.name, " ", c.get_class())
	if _n == 70:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
