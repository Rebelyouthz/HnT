extends SceneTree

## New-player flow: wipe progress, PLAY like a fresh save, tap confirm every
## 25 frames (talk lines / films), log every scene change and save a frame
## every 60. xvfb-run ... --fixed-fps 60 --script res://tools/flow_probe.gd -- <out_dir> [frames] [walk]

var _dir := ""
var _end := 3000
var _walk := false
var _n := 0
var _scene := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_dir = a[0]
	if a.size() > 1:
		_end = int(a[1])
	_walk = a.size() > 2 and a[2] == "walk"
	DirAccess.make_dir_recursive_absolute(_dir)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 3:
		var fp := root.get_node("FamilyProfile")
		fp.call("reset_progress")
		root.get_node("App").call("start_run")
	var cs := current_scene
	var nm := str(cs.scene_file_path) if cs else "<none>"
	if nm != _scene:
		_scene = nm
		print("FLOW ", _n, " ", nm)
	if _n > 30 and _n % 25 == 0:
		for act in ["ui_accept", "p1_jump"]:
			Input.action_press(act)
	if _n > 30 and _n % 25 == 3:
		for act in ["ui_accept", "p1_jump"]:
			Input.action_release(act)
	if _walk and _n > 30:
		Input.action_press("p1_right")
	if _n % 60 == 0:
		root.get_texture().get_image().save_png("%s/flow_%05d.png" % [_dir, _n])
	if _n >= _end:
		print("FLOW END ", _scene)
		quit()
	return false
