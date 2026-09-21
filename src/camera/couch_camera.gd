class_name CouchCamera
extends Camera2D

var targets: Array[Node2D] = []
var _base := Vector2.ZERO


func _ready() -> void:
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	limit_top = 0
	limit_bottom = 720
	limit_left = 0
	limit_right = 3200


func _physics_process(_delta: float) -> void:
	var living: Array[Node2D] = []
	for t in targets:
		if is_instance_valid(t):
			living.append(t)
	if living.is_empty():
		offset = Juice.shake_offset()
		return
	var mid := Vector2.ZERO
	for t in living:
		mid += t.global_position
	mid /= float(living.size())
	mid.x += 80.0
	_base = mid
	global_position = mid
	if living.size() == 2:
		var dist := absf(living[0].global_position.x - living[1].global_position.x)
		var max_sep := get_viewport_rect().size.x * 0.7
		if dist > max_sep:
			var left := living[0] if living[0].global_position.x < living[1].global_position.x else living[1]
			var right := living[1] if left == living[0] else living[0]
			var center := (left.global_position.x + right.global_position.x) * 0.5
			if right.global_position.x > center + max_sep * 0.5:
				right.global_position.x = center + max_sep * 0.5
	offset = Juice.shake_offset()
