extends SceneTree

## Every story errand, played by following the arrow only: for each gated
## map (Gant's THICK SKIN, the UPPERCUT, the STOLEN SCRUBS, the EXTENDED MAG,
## the TAPE) a family whose next map is that one comes home to the hideout,
## and the test presses whatever the arrow is on (a room on the floor, a card,
## BUILD, OPEN, a tab, the item, BUY) until the gate opens and the guide says
## READY. Prints ERRANDS OK on success.
##   godot --headless --fixed-fps 60 -s tests/errand_all_test.gd

const GATES := ["dock_street", "intake_lot", "fire_escapes", "group_circle", "neon_exchange"]

var _n := 0
var _gi := -1
var _t0 := 0
var _presses := 0
var _trail: Array = []
var _fail: Array[String] = []
var _report: Array = []


func _initialize() -> void:
	if FileAccess.file_exists("user://family.json"):
		DirAccess.copy_absolute("user://family.json", "user://family.errands_backup.json")


func _guide() -> Node:
	return get_first_node_in_group("errand_guide")


func _ctrl(key: String) -> Control:
	for c in root.find_children("*", "Control", true, false):
		if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree():
			return c
	if key.begins_with("button:"):
		for c in root.find_children("*", "Button", true, false):
			if (c as Button).text.to_upper().begins_with(key.substr(7).to_upper()) and (c as Button).is_visible_in_tree():
				return c
	return null


func _start_gate() -> void:
	_gi += 1
	_presses = 0
	_trail.clear()
	if _gi >= GATES.size():
		return
	var fp := root.get_node("FamilyProfile")
	fp.call("reset_progress")
	var g: Array = []
	for gk in load("res://src/ui/guides.gd").STEPS:
		g.append(str(gk))
	for m in GATES:
		g.append("errand_" + str(m))
	fp.data["guides_done"] = g
	fp.data["intro_done"] = true
	var order: Array = root.get_node("App").get("ORDER")
	var gate: String = GATES[_gi]
	for id in order:
		if id == gate:
			break
		fp.call("mark_map_filed", id)
		_meet(fp, str(id))
	if order.find(gate) > order.find("dock_street"):
		fp.data["crew_benny"] = true
	if order.find(gate) > order.find("intake_lot"):
		fp.data["crew_rico"] = true
		# Ember came home with Rico: her first forging leads the night.
		fp.data["crew_ember"] = gate == "fire_escapes"
		fp.data["crew_home_ember"] = true
	root.get_node("App").set("camp_next", "")
	_t0 = _n
	change_scene_to_file("res://scenes/levels/camp.tscn")


## A map the family already cleared had its gate met (the game never files
## one past a closed gate): build its room and grant what it asked for, so
## each gate is walked on its own (catch-up is errand_test's business).
func _meet(fp: Node, map_id: String) -> void:
	var need: Variant = load("res://src/app/power_book.gd").spec(map_id).get("need", {})
	if typeof(need) != TYPE_DICTIONARY:
		return
	var nd := need as Dictionary
	var shop := str(nd.get("shop", ""))
	if shop != "":
		(fp.data["buildings"] as Dictionary)[shop] = maxi(1, int((fp.data["buildings"] as Dictionary).get(shop, 0)))
	var id := str(nd.get("id", ""))
	match str(nd.get("kind", "")):
		"cbt":
			if not (fp.data["cbt"] as Array).has(id):
				(fp.data["cbt"] as Array).append(id)
		"dojo":
			var d: Dictionary = fp.data.get("dojo", {})
			d[id] = maxi(1, int(d.get(id, 0)))
			fp.data["dojo"] = d
		"gear":
			load("res://src/app/gear_inv.gd").add(id)
		"research", "weapon":
			var r: Array = fp.data.get("research", [])
			if not r.has(id):
				r.append(id)
			fp.data["research"] = r
		"craft":
			var c: Array = fp.data.get("crafts", [])
			if not c.has(id):
				c.append(id)
			fp.data["crafts"] = c


func _press(t: String) -> void:
	# Drilling on the dojo mat is a scene of its own: count the three reps.
	if t.begins_with("dojo_train_"):
		for k in 3:
			root.get_node("FamilyProfile").call("dojo_rep", t.substr(11))
		return
	if t.begins_with("station:"):
		var id := t.substr(8)
		if id == "command_board":
			current_scene.call("_open_hub", "clinic")
			return
		for st in current_scene.get("_stations"):
			if str(st["id"]) == id:
				current_scene.call("_use", st)
				return
		return
	var c := _ctrl(t)
	if c is BaseButton:
		(c as BaseButton).pressed.emit()
	# The forge's anvil: three clean strikes.
	if t.begins_with("forge_") and not t.begins_with("forge_tab_"):
		for a in root.find_children("*", "Control", true, false):
			if a.get_script() != null and str(a.get_script().resource_path).ends_with("forge_anvil.gd"):
				a.emit_signal("done", 3)
				a.queue_free()


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		_start_gate()
		return false
	if _gi >= GATES.size():
		if _fail.is_empty():
			print("ERRANDS OK")
			for r in _report:
				print("  ", r)
		else:
			print("ERRANDS FAIL ", _fail)
		if FileAccess.file_exists("user://family.errands_backup.json"):
			DirAccess.copy_absolute("user://family.errands_backup.json", "user://family.json")
			DirAccess.remove_absolute("user://family.errands_backup.json")
		return true
	paused = false
	var gate: String = GATES[_gi]
	if _n - _t0 < 300 or _n % 24 != 0:
		return false
	var g := _guide()
	var open: bool = load("res://src/app/power_book.gd").path(gate).is_empty()
	if open:
		_report.append("%s: %s" % [gate, _trail])
		_start_gate()
		return false
	if g == null:
		_fail.append("%s: no guide (trail %s)" % [gate, _trail])
		_start_gate()
		return false
	# Benny is still hammering: let him finish before the next press.
	if bool(current_scene.get("_busy")):
		return false
	var t := str(g.get("target"))
	if t == "":
		if _n - _t0 > 2400:
			_fail.append("%s: arrow points nowhere (trail %s, label %s)" % [gate, _trail, g.get("_label")])
			_start_gate()
		return false
	_trail.append(t)
	if OS.get_environment("ERR_DEBUG") != "":
		var keys: Array = []
		for c in root.find_children("*", "Control", true, false):
			if c.has_meta("key") and (c as Control).is_visible_in_tree():
				keys.append(str(c.get_meta("key")))
		print("dbg ", gate, " busy=", current_scene.get("_busy"), " leaving=", current_scene.get("_leaving"), " t=", t, " overlay=", current_scene.call("overlay_open") if current_scene.has_method("overlay_open") else "-", " keys=", keys.slice(0, 30))
	_presses += 1
	if _presses > 14:
		_fail.append("%s: stuck (trail %s, label %s)" % [gate, _trail, g.get("_label")])
		_start_gate()
		return false
	_press(t)
	return false
