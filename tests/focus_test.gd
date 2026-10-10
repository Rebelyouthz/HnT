extends SceneTree

## Pad check: every menu must give keyboard/pad focus to something when it
## opens, or a controller player is stuck.
##   godot --headless --script res://tests/focus_test.gd

var _queue: Array = []
var _cur: Node
var _n := 0
var _bad: Array = []


func _initialize() -> void:
	var sheets: Array = []
	var cs: Script = load("res://src/ui/camp_sheets.gd")
	for p in (cs.get("PATHS") as Dictionary).values():
		sheets.append(str(p))
	for f in ["hub_clinic", "hub_build", "hub_locker", "hub_awards", "hub_run", "settings_sheet", "character_select"]:
		var p := "res://src/ui/%s.gd" % f
		if ResourceLoader.exists(p):
			sheets.append(p)
	_queue = sheets


func _process(_d: float) -> bool:
	_n += 1
	if _n < 3:
		return false
	if _cur != null:
		if _n % 6 != 0:
			return false
		var f := root.gui_get_focus_owner()
		if f == null or not _cur.is_ancestor_of(f):
			_bad.append(str(_cur.get_meta("path")))
		_cur.queue_free()
		_cur = null
		return false
	if _queue.is_empty():
		for b in _bad:
			push_error("NO FOCUS: " + str(b))
		print("FOCUS OK" if _bad.is_empty() else "FOCUS MISSING %d" % _bad.size())
		quit(0 if _bad.is_empty() else 1)
		return true
	var path := str(_queue.pop_front())
	var s: Script = load(path)
	var node: Node = s.new()
	node.set_meta("path", path)
	if node is Control:
		(node as Control).size = Vector2(1280, 720)
	root.add_child(node)
	_cur = node
	_n = 6 * int(_n / 6.0) + 1
	return false
