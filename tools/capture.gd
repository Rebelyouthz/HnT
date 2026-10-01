extends SceneTree

## Dev screenshots with a real renderer (not --headless):
## xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --resolution 1920x1080 --windowed --script res://tools/capture.gd -- <scene|map_id> <out.png> [frames] [walk]

var _out := "user://capture.png"
var _frames := 90
var _walk := false
var _n := 0
var _target := ""
var _tab := ""


## Autoloads are only in the tree once the loop runs: seed the profile on the
## first frame, change scene on the second.
func _prepare() -> void:
	var fp := root.get_node_or_null("FamilyProfile")
	if fp != null and fp.get("data") is Dictionary:
		var d := fp.data as Dictionary
		d["intro_done"] = true
		d["named"] = true
		if str(d.get("father_name", "")) == "":
			d["father_name"] = "Dad"
		if str(d.get("son_name", "")) == "":
			d["son_name"] = "Kid"
	var app := root.get_node_or_null("App")
	if app != null and _tab != "" and not _tab.begins_with("title"):
		app.set("pending_tab", _tab)
	if _tab == "stats":
		# Demo numbers so the report has something to draw.
		var d2 := fp.data as Dictionary
		var demo := {"runs": 23, "lights": 1840, "heavies": 612, "snaps": 97, "dual_snaps": 12, "parries": 140,
			"perfect_parries": 38, "clashes": 44, "stomps": 71, "smash_kills": 210, "revenges": 9, "catches": 33,
			"combo_banks": 58, "towers_climbed": 11, "summit_meals": 6, "tricks": 320, "perfect_tricks": 88,
			"wallkicks": 145, "grinds": 77, "poles": 52, "slides": 190, "dives": 64, "awnings": 41, "bounces": 99,
			"hoods": 27, "high_score": 184300, "streak_best": 7, "solo_clears": 9, "raven_kills": 2, "unmasks": 3}
		for k in demo:
			d2[k] = demo[k]
	change_scene_to_file(_target)


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
	# title / title:credits / title:options open the start screen.
	if target.begins_with("title"):
		_tab = "title_" + (target.get_slice(":", 1) if ":" in target else "")
		target = "res://scenes/ui/title.tscn"
	# hub:<tab> opens the hub on that tab.
	elif target.begins_with("hub"):
		_tab = target.get_slice(":", 1) if ":" in target else ""
		target = "res://scenes/ui/hub.tscn"
	if not target.begins_with("res://"):
		target = "res://scenes/levels/%s.tscn" % target
	_target = target


func _process(_delta: float) -> bool:
	_n += 1
	if _n == 2:
		_prepare()
	if _tab == "stats" and _n == 40 and current_scene != null and current_scene.has_method("_open_stats"):
		current_scene.call("_open_stats")
	if _tab.begins_with("title_") and _n == 60 and current_scene != null:
		var page := _tab.substr(6)
		if page != "" and current_scene.has_method("_" + page):
			current_scene.call("_" + page)
	if _walk and _n > 20:
		Input.action_press("p1_right")
	if _n == _frames:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("CAPTURED ", _out, " ", img.get_size())
		quit()
	return false
