extends SceneTree

## Dev screenshots with a real renderer (not --headless):
## xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --resolution 1920x1080 --windowed --script res://tools/capture.gd -- <scene|map_id> <out.png> [frames] [walk]

var _out := "user://capture.png"
var _frames := 90
var _walk := false
var _n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var target := args[0] if args.size() > 0 else "res://scenes/ui/hub.tscn"
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_walk = args.size() > 3 and args[3] == "walk"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var fp := root.get_node_or_null("FamilyProfile")
	if fp != null and fp.get("data") is Dictionary:
		(fp.data as Dictionary)["intro_done"] = true
	if not target.begins_with("res://"):
		target = "res://scenes/levels/%s.tscn" % target
	change_scene_to_file.call_deferred(target)


func _process(_delta: float) -> bool:
	_n += 1
	if _walk and _n > 20:
		Input.action_press("p1_right")
	if _n == _frames:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("CAPTURED ", _out, " ", img.get_size())
		quit()
	return false
