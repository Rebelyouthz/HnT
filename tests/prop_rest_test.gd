extends SceneTree

## Living props hold their rest frame and only have the odd moment: over
## ten seconds each one sits on its rest frame most of the time, while the
## looping ones (flag, moths round a lamp) keep moving. Prints PROPS OK.
##   godot --headless --fixed-fps 60 -s tests/prop_rest_test.gd

const PROPS := ["manhole", "dumpster", "booth", "cart", "crate", "hood", "van", "cone", "board", "flag", "sodium_lamp"]
var _anims := {}
var _rest_frames := {}
var _changes := {}
var _last := {}
var _n := 0


func _initialize() -> void:
	var sb: GDScript = load("res://src/sprites/sprite_book.gd")
	for p in PROPS:
		var a: AnimatedSprite2D = sb.call("make_anim", p)
		root.add_child(a)
		_anims[p] = a
		_rest_frames[p] = 0
		_changes[p] = 0
		_last[p] = -1


func _process(_d: float) -> bool:
	_n += 1
	var sb: GDScript = load("res://src/sprites/sprite_book.gd")
	for p in PROPS:
		var a: AnimatedSprite2D = _anims[p]
		var info: Dictionary = sb.call("clip_info", p, "idle")
		if a.frame == int(info.get("rest", 0)):
			_rest_frames[p] += 1
		if a.frame != _last[p]:
			_changes[p] += 1
			_last[p] = a.frame
	if _n < 600:
		return false
	var fail: Array = []
	var rep: Array = []
	for p in PROPS:
		var info: Dictionary = sb.call("clip_info", p, "idle")
		var share := float(_rest_frames[p]) / 600.0
		rep.append("%s %s rest %d%% changes %d" % [p, info.get("mode"), int(share * 100.0), _changes[p]])
		if str(info.get("mode")) == "moments" and share < 0.7:
			fail.append("%s off its rest frame %d%% of the time" % [p, int((1.0 - share) * 100.0)])
		if str(info.get("mode")) == "loop" and _changes[p] < 20:
			fail.append("%s should loop" % p)
	if fail.is_empty():
		print("PROPS OK")
	else:
		print("PROPS FAIL ", fail)
	for r in rep:
		print("  ", r)
	return true
