class_name WallMark
extends Node2D

## Where a round that went clean through ends up: a chipped hole in the wall
## behind the victim with the blood it carried fanned out around it (thrown
## the way the round flew, a few runs dripping down). Drawn behind the
## fighters, on the facade; they fade after a while and only the newest 30
## stay.

const MAX := 30

var dir := 1.0
var bloody := true
var _rays: Array = []
var _drops: Array = []
var _runs: Array = []
var _t := 0.0


static func mark(host: Node, at: Vector2, d: float, with_blood: bool = true) -> void:
	if host == null:
		return
	if FamilyProfile.less_gore():
		with_blood = false
	var m := WallMark.new()
	m.dir = d
	m.bloody = with_blood
	m.global_position = at
	# On the wall: over the painted facade, under everyone standing.
	m.z_index = 0
	host.add_child(m)
	var first := -1
	for c in host.get_children():
		if c.is_in_group("enemies") or c.is_in_group("players"):
			first = c.get_index() if first < 0 else mini(first, c.get_index())
	if first >= 0:
		host.move_child(m, first)
	m.add_to_group("wall_marks")
	var all := host.get_tree().get_nodes_in_group("wall_marks")
	if all.size() > MAX:
		(all[0] as Node).queue_free()


func _ready() -> void:
	for i in 9:
		var a := randf_range(-0.7, 0.7)
		_rays.append([Vector2(dir, 0).rotated(a), randf_range(6.0, 16.0), randf_range(0.8, 1.6)])
	for i in 12:
		var a2 := randf_range(-1.0, 1.0)
		_drops.append([Vector2(dir, 0).rotated(a2) * randf_range(4.0, 20.0), randf_range(0.5, 1.4)])
	for i in 3:
		_runs.append([Vector2(dir * randf_range(2.0, 10.0), randf_range(-3.0, 3.0)), 0.0, randf_range(6.0, 14.0)])
	var tw := create_tween()
	tw.tween_interval(24.0)
	tw.tween_property(self, "modulate:a", 0.0, 2.0)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	# The runs creep down the wall for a couple of seconds.
	if _t < 3.0:
		_t += delta
		for r in _runs:
			r[1] = minf(float(r[2]), float(r[1]) + delta * 6.0)
		queue_redraw()


func _draw() -> void:
	var red := Color(0.42, 0.03, 0.05, 0.85)
	var dark := Color(0.25, 0.01, 0.03, 0.9)
	if bloody:
		for r in _rays:
			var v: Vector2 = r[0]
			draw_line(v * 2.0, v * float(r[1]), red, float(r[2]))
		for dp in _drops:
			draw_circle(dp[0], float(dp[1]), red)
		for r in _runs:
			var p: Vector2 = r[0]
			draw_line(p, p + Vector2(0, float(r[1])), dark, 1.0)
			draw_circle(p + Vector2(0, float(r[1])), 0.9, dark)
		draw_circle(Vector2.ZERO, 4.0, Color(0.38, 0.02, 0.04, 0.8))
	# The hole: chipped plaster rim, a black core.
	draw_circle(Vector2.ZERO, 2.6, Color(0.62, 0.58, 0.52, 0.55))
	draw_circle(Vector2.ZERO, 1.6, Color(0.03, 0.02, 0.02, 1.0))
