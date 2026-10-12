class_name PropMoments
extends Node

## A living prop at rest: it holds its calm frame and only now and then has
## a moment (a puff of steam, a spark, the lid lifting) before settling back,
## instead of strobing through every frame of its sheet. The frames come
## from tools/prop_moments.py ("rest", "moments" in the clip's json).

var anim: AnimatedSprite2D
var rest := 0
var moments: Array = []
var _wait := 0.0
var _run: Array = []
var _t := 0.0


func _ready() -> void:
	_wait = randf_range(1.5, 7.0)
	anim.stop()
	anim.frame = rest


func _process(delta: float) -> void:
	if anim == null or not is_instance_valid(anim):
		queue_free()
		return
	if _run.is_empty():
		_wait -= delta
		if _wait <= 0.0 and not moments.is_empty():
			_start()
		return
	_t -= delta
	if _t <= 0.0:
		_run.pop_front()
		if _run.is_empty():
			anim.frame = rest
			_wait = randf_range(4.0, 10.0)
		else:
			anim.frame = int(_run[0])
			_t = 1.0 / 7.0


## A short beat: a few of the allowed frames in sheet order from a random
## start, then back to rest.
func _start() -> void:
	var sorted := moments.duplicate()
	sorted.sort()
	var i := randi() % sorted.size()
	var n := randi_range(2, 4)
	_run = []
	for k in n:
		_run.append(sorted[(i + k) % sorted.size()])
	# Hold the last frame of the beat a moment longer.
	_run.append(_run[_run.size() - 1])
	anim.frame = int(_run[0])
	_t = 1.0 / 7.0
