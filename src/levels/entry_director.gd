class_name EntryDirector
extends Node

## Nobody is standing in shot when the street opens. Each booked thug waits
## off camera until the heroes get near his patch, then ARRIVES:
##   walk   strolls in from the right edge
##   behind comes up from behind (left edge) once there is street back there
##   rope   rappels down from the rooftops on a line, lands, the line whips up
##   ladder climbs down a fire-escape ladder that is in view
## Roof thugs walk in along the roof; fliers drop in from the top corner.

const LOOK := 170.0

var host: Node
var hp_mul := 1.0
var speed_mul := 1.0
var _rows: Array = []
var _n := 0


func setup(rows: Array) -> void:
	_rows = rows.duplicate()
	_rows.sort_custom(func(a, b) -> bool: return float(a.get("x", 0.0)) < float(b.get("x", 0.0)))
	if not _rows.is_empty():
		add_to_group("entry_pending")


func _process(_delta: float) -> void:
	if _rows.is_empty():
		remove_from_group("entry_pending")
		set_process(false)
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	var half := get_viewport().get_visible_rect().size * 0.5 / cam.zoom
	var view := Rect2(c - half, half * 2.0)
	# One arrival at a time per frame keeps entrances readable.
	var row: Dictionary = _rows[0]
	if float(row.get("x", 0.0)) < view.end.x + LOOK:
		_rows.pop_front()
		_arrive(row, view)


func _arrive(row: Dictionary, view: Rect2) -> void:
	_n += 1
	var p := Party.spawn_row(host, row, hp_mul)
	if p == null:
		return
	p.speed *= speed_mul
	var lane := float(row.get("y", 500.0))
	var x := float(row.get("x", 800.0))
	if p.home == "air":
		_fly_in(p, view, lane)
		return
	if p.home != "street":
		p.global_position = Vector2(maxf(x, view.end.x + 50.0), lane)
		return
	var ladder := _ladder_in(view)
	var roll := randf()
	if ladder != null and roll < 0.3:
		_climb_down(p, ladder, lane)
	elif roll < 0.62 and _n > 1:
		_rope_down(p, view, x, lane)
	elif roll < 0.76 and view.position.x > 260.0:
		p.global_position = Vector2(view.position.x - 50.0, lane + randf_range(-10.0, 10.0))
	else:
		p.global_position = Vector2(maxf(x, view.end.x + 55.0), lane)


func _ladder_in(view: Rect2) -> FireEscape:
	for n in get_tree().get_nodes_in_group("ladders"):
		var fe := n as FireEscape
		if fe and fe.style == "ladder" and fe.climb_x > view.position.x + 120.0 and fe.climb_x < view.end.x - 40.0:
			return fe
	return null


## Frozen AI while the entrance plays; the walk clip still runs.
func _hold(p: Punk, clip: String, rate: float) -> void:
	p.set_physics_process(false)
	var a := p.get("_anim") as AnimatedSprite2D
	if a and a.sprite_frames and a.sprite_frames.has_animation(clip):
		a.play(clip)
		a.speed_scale = rate


func _release(p: Punk) -> void:
	if not is_instance_valid(p):
		return
	var a := p.get("_anim") as AnimatedSprite2D
	if a:
		a.speed_scale = 1.0
	p.rotation = 0.0
	p.set_physics_process(true)


func _rope_down(p: Punk, view: Rect2, x: float, lane: float) -> void:
	var at := clampf(x, view.position.x + view.size.x * 0.45, view.end.x - 70.0)
	var top := view.position.y - 30.0
	p.global_position = Vector2(at, top)
	_hold.call_deferred(p, "idle", 1.0)
	var rope := Line2D.new()
	rope.width = 2.0
	rope.default_color = Color(0.72, 0.64, 0.5)
	rope.z_index = 2
	rope.add_point(Vector2(at, top - 400.0))
	rope.add_point(Vector2(at, top - 40.0))
	host.add_child(rope)
	Juice.play("res://assets/audio/whoosh_light.wav")
	var tw := p.create_tween()
	tw.tween_method(func(y: float) -> void:
		if is_instance_valid(p):
			p.global_position.y = y
			p.rotation = sin(y * 0.05) * 0.06
		if is_instance_valid(rope):
			rope.set_point_position(1, Vector2(at, y - 52.0))
	, top, lane, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		Juice.play("res://assets/audio/land_dad.wav")
		Juice.pulse_shake(1.5)
		_release(p)
		if is_instance_valid(rope):
			var up := rope.create_tween()
			up.tween_method(func(y: float) -> void:
				if is_instance_valid(rope):
					rope.set_point_position(1, Vector2(at, y))
			, lane - 52.0, top - 400.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			up.tween_callback(rope.queue_free)
	)


func _climb_down(p: Punk, fe: FireEscape, lane: float) -> void:
	p.global_position = Vector2(fe.climb_x, fe.top_y)
	_hold.call_deferred(p, "walk", 0.55)
	var tw := p.create_tween()
	tw.tween_property(p, "global_position:y", fe.bottom_y, absf(fe.bottom_y - fe.top_y) / 150.0)
	tw.tween_property(p, "global_position:y", lane, 0.25)
	tw.tween_callback(func() -> void:
		Juice.play("res://assets/audio/land_son.wav")
		_release(p)
	)


func _fly_in(p: Punk, view: Rect2, lane: float) -> void:
	p.global_position = Vector2(view.end.x + 40.0, view.position.y - 20.0)
	_hold.call_deferred(p, "walk", 1.0)
	var tw := p.create_tween()
	tw.tween_property(p, "global_position", Vector2(view.end.x - 120.0, lane), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _release(p))
