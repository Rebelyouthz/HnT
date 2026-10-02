extends SceneTree

## Dev screenshots with a real renderer (not --headless):
## xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --resolution 1920x1080 --windowed --script res://tools/capture.gd -- <scene|map_id> <out.png> [frames] [walk]

var _out := "user://capture.png"
var _frames := 90
var _walk := false
var _left := false
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
	if app != null and _tab.begins_with("film_"):
		var pair := _tab.substr(5)
		app.set("film_from", pair.get_slice("->", 0))
		app.set("film_next", pair.get_slice("->", 1))
		app.set("film_kind", "bridge")
		app.set("film_to_camp", true)
	if app != null and _tab != "" and not _tab.begins_with("title") and not _tab.begins_with("camp") and not _tab.begins_with("tower") and not _tab.begins_with("film") and not _tab.begins_with("ui"):
		app.set("pending_tab", _tab)
	# Hideout shots: both brothers home and lumber money.
	if _tab.begins_with("camp_") and fp != null:
		(fp.data as Dictionary)["crew_benny"] = true
		(fp.data as Dictionary)["crew_rico"] = true
		(fp.data as Dictionary)["gold"] = 500
	# Menu shots: open the gated tabs so BUILD / LOCKER / AWARDS render.
	if _tab in ["build", "locker", "awards"] and fp != null:
		var b: Dictionary = (fp.data as Dictionary).get("buildings", {})
		for id in ["therapy_couch", "wardrobe_cage", "trophy_cabinet"]:
			b[id] = maxi(1, int(b.get(id, 0)))
		(fp.data as Dictionary)["buildings"] = b
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


var _had_profile := false


func _initialize() -> void:
	# Shots edit the profile (names, unlocked tabs, demo stats) and the hub
	# saves it; put things back afterwards so tests see a clean profile.
	_had_profile = FileAccess.file_exists("user://family.json")
	if _had_profile:
		DirAccess.copy_absolute("user://family.json", "user://family.capture_backup.json")
	var args := OS.get_cmdline_user_args()
	var target := args[0] if args.size() > 0 else "res://scenes/ui/hub.tscn"
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_walk = args.size() > 3 and (args[3] == "walk" or args[3] == "left")
	_left = args.size() > 3 and args[3] == "left"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	# ui:<what> on Dock Street: results | cards | toasts
	if target.begins_with("ui:"):
		_tab = "ui_" + target.substr(3)
		target = "res://scenes/levels/dock_street.tscn"
	# film:<from>-><to> plays a bridge film.
	elif target.begins_with("film:"):
		_tab = "film_" + target.substr(5)
		target = "res://scenes/levels/act_film.tscn"
	# tower:<map> plays the giant tower film on autopilot.
	elif target.begins_with("tower:"):
		_tab = "tower_" + target.get_slice(":", 1)
		target = "res://scenes/levels/%s.tscn" % target.get_slice(":", 1)
	# camp:hub / camp:dojo open a hideout menu over the camp.
	elif target.begins_with("camp:"):
		_tab = "camp_" + target.get_slice(":", 1)
		target = "res://scenes/levels/camp.tscn"
	# title / title:credits / title:options open the start screen.
	elif target.begins_with("title"):
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
	if _tab.begins_with("ui_") and _n == 80 and current_scene != null:
		match _tab.substr(3):
			"results":
				current_scene.call("_banner", "DOCK STREET FILED", "Gant is down. Benny is free.", true, false)
			"cards":
				var cp: Node = load("res://src/combat/card_pick.gd").new()
				current_scene.add_child(cp)
			"toasts":
				var j := root.get_node("Juice")
				j.call("toast", "reward", "SECRET FOUND", "The Harbour Clock  ·  128 metres")
				j.call("toast", "quest", "CHECKPOINT", "Gant's office is ahead")
				j.call("toast", "challenge", "LOCKED", "Buy Thick Skin at the therapy couch")
	# ui:gore - the nearest thug eats a jab, cross, gut, uppercut, a bullet
	# and a slide, then a heavy finish: blood, wounds, reactions, a body.
	if _tab == "ui_gore" and _n >= 70 and _n % 14 == 0 and _n <= 70 + 14 * 9 and current_scene != null:
		var p1: Node2D = null
		for n in root.get_tree().get_nodes_in_group("players"):
			p1 = n
			break
		var best: Node2D = null
		for n in root.get_tree().get_nodes_in_group("enemies"):
			if best == null or (n as Node2D).global_position.distance_to(p1.global_position) < best.global_position.distance_to(p1.global_position):
				best = n
		if best != null and p1 != null:
			best.global_position = p1.global_position + Vector2(40, 0)
			var step := (_n - 70) / 14
			var seq := [["light", "jab"], ["light", "cross"], ["heavy", "gut"], ["light", "jab"], ["uppercut", "uppercut"], ["heavy", "cross"], ["slide", "slide"], ["light", "jab"], ["heavy", "roundhouse"], ["heavy", "heavy"]]
			var row: Array = seq[mini(step, seq.size() - 1)]
			p1.set("_strike_clip", row[1])
			if step >= 8:
				best.set("hp", 4)
			best.call("take_hit", row[0], p1)
	if _tab.begins_with("tower_") and _n == 60:
		load("res://src/ui/timing_ring.gd").set("autoplay", true)
		root.get_tree().paused = true
		var film: Node = load("res://src/world/giant_tower_film.gd").new()
		film.set("map_id", _tab.substr(6))
		root.add_child(film)
	if _tab.begins_with("camp_") and _n == 90 and current_scene != null:
		var what := _tab.substr(5)
		if what == "hub":
			current_scene.call("_open_hub", "clinic")
		elif what.begins_with("build_"):
			for st: Dictionary in current_scene.get("_stations"):
				if str(st["id"]) == what.substr(6):
					current_scene.get("_walker").position.x = float(st["x"]) + 30.0
					current_scene.call("_construct", st)
		else:
			current_scene.call("_use", {"id": what, "locked": false})
	if _tab.begins_with("title_") and _n == 60 and current_scene != null:
		var page := _tab.substr(6)
		if page != "" and current_scene.has_method("_" + page):
			current_scene.call("_" + page)
	if _walk and _n > 20:
		Input.action_press("p1_left" if _left else "p1_right")
	if _n == _frames:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("CAPTURED ", _out, " ", img.get_size())
		_restore_profile()
		quit()
	return false


func _restore_profile() -> void:
	if _had_profile:
		DirAccess.copy_absolute("user://family.capture_backup.json", "user://family.json")
		DirAccess.remove_absolute("user://family.capture_backup.json")
	elif FileAccess.file_exists("user://family.json"):
		DirAccess.remove_absolute("user://family.json")
