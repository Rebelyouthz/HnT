extends SceneTree

## ManualRack: dry -> next gun; all dry -> reload one by one, the first back
## in fires while the next loads. Prints RACK OK.

const FAKE := """extends ManualRack
func owned() -> Array:
	return ["a", "b", "c"]

func mag_size(_id: String) -> int:
	return 2
"""

var _n := 0
var r: Node2D
var each := 0.75
var ok := true


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("RACK FAIL ", what)


func _process(delta: float) -> bool:
	_n += 1
	if _n == 2:
		# Built at run time: autoloads (Mixer, Juice) exist by now.
		var sc := GDScript.new()
		sc.source_code = FAKE
		sc.reload()
		r = sc.new()
		each = float(load("res://src/survive/manual_rack.gd").RELOAD_EACH)
		root.add_child(r)
	if _n == 4:
		r._sync()
		_check(r.active == "a" and r.can_fire("a"), "starts on a")
		for i in 2:
			r.spend("a")
		_check(r.active == "b", "swap to b on dry a")
		for i in 2:
			r.spend("b")
		for i in 2:
			r.spend("c")
		_check(r.reloading(), "all dry -> reloading")
		_check(not r.can_fire(r.active), "cannot fire before first mag")
	if _n == 4 + int(each * 60.0) + 4:
		_check(r.can_fire(r.active), "first mag live after one reload")
		_check(not r.reloading(), "not blocked while next loads")
		_check(r._queue.size() == 2, "two still queued: %d" % r._queue.size())
	if _n == 4 + int(each * 180.0) + 12:
		_check(r._queue.is_empty(), "all loaded")
		_check(int(r.ammo["a"]) == 2 and int(r.ammo["b"]) == 2 and int(r.ammo["c"]) == 2, "all full")
		print("RACK OK" if ok else "RACK FAILED")
		quit()
	return false
