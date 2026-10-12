extends SceneTree
## Dev: the UNLOCKED banner with a room picture and with a pixel icon.  -- <out_prefix>
var _n := 0
var _out := "/tmp/banner"
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else _out
func _process(_d: float) -> bool:
	_n += 1
	if _n == 3:
		root.get_node("FamilyProfile").data["intro_done"] = true
		change_scene_to_file("res://scenes/levels/camp.tscn")
	if _n == 40:
		root.get_node("Juice").call("carpenter", "THERAPY COUCH", "SKILL TREE", "therapy_couch")
		print("BANNER on=", root.get_node("Juice").get("_banner_on"), " q=", (root.get_node("Juice").get("_banner_q") as Array).size(), " card=", get_first_node_in_group("stage_card"))
	if _n == 70:
		var ov: CanvasLayer = root.get_node("Juice").get("_overlay")
		for c in ov.get_children():
			print("OV t=", Time.get_ticks_msec(), " ", c, " vis=", (c as CanvasItem).visible if c is CanvasItem else "-", " kids=", c.get_child_count(), " mod=", (c as CanvasItem).modulate if c is CanvasItem else "")
		print("layer ", ov.layer, " vis ", ov.visible)
	if _n == 52:
		root.get_texture().get_image().save_png(_out + "_room.png")
	if _n == 300:
		root.get_node("Juice").call("unlock_banner", "SKILL TREE", "Spend gold on lasting upgrades", load("res://assets/sprites/icons/head_build.png"))
	if _n == 312:
		root.get_texture().get_image().save_png(_out + "_icon.png")
		quit()
	return false
