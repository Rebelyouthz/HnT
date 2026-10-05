class_name CapeFx
extends Node2D

## The BAT CAPE: a cloth strip hung from the drawn neck (measured per frame
## from the sprite), trailing with speed, flapping in the wind and spread
## wide like wings while gliding. Lives behind the body sprite.

const ROWS := 7

var anim: AnimatedSprite2D
var who: Node2D
var draw_cape := true
## The BAT COWL's ears, which stand out past the head's silhouette (the
## shader can only paint inside the sprite).
var draw_ears := false
var _t := 0.0
var _trail := 0.2
var _spread := 0.0
var _lift := 0.0


func _process(delta: float) -> void:
	_t += delta
	if who == null or not is_instance_valid(who):
		# On a menu paperdoll: a slow idle sway.
		_trail = 0.22 + 0.06 * sin(_t * 1.3)
		queue_redraw()
		return
	var gl := bool(who.get("gliding"))
	var v: Vector2 = who.get("velocity") if who.get("velocity") != null else Vector2.ZERO
	var hv := float(who.get("hop_v")) if who.get("hop_v") != null else 0.0
	var run := clampf(absf(v.x) / 320.0, 0.0, 1.0)
	_trail = lerpf(_trail, 0.18 + 0.55 * run + (0.35 if gl else 0.0), 1.0 - exp(-8.0 * delta))
	_spread = lerpf(_spread, 1.0 if gl else 0.0, 1.0 - exp(-10.0 * delta))
	# Rising pulls the cape down, falling blows it up.
	_lift = lerpf(_lift, clampf(hv / 700.0, -0.4, 0.6), 1.0 - exp(-6.0 * delta))
	queue_redraw()


func _draw() -> void:
	if anim == null or not is_instance_valid(anim) or not anim.visible:
		return
	var h := BloodSim.head_of(anim)
	var k := absf(anim.scale.y)
	var fx := -1.0 if anim.flip_h else 1.0
	var neck := Vector2(h.x * absf(anim.scale.x) * fx, anim.position.y + (h.y + h.z * 0.95) * k)
	if draw_ears:
		_ears(h, k, fx)
	if not draw_cape:
		return
	var length := h.z * 4.6 * k
	var flap := 9.0 + 7.0 * _trail
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in ROWS + 1:
		var s := float(i) / float(ROWS)
		var wave := sin(_t * flap - s * 3.4) * s * (2.0 + 5.0 * _trail) * k * 0.5
		var cx := neck.x - fx * (h.z * (0.7 + 0.5 * s) * k + s * _trail * length + wave)
		var cy := neck.y + s * length * (1.0 - 0.55 * _trail - 0.5 * _lift) + wave * 0.4
		var half := lerpf(h.z * 0.8, h.z * 1.7, s) * k * (1.0 + 1.4 * _spread * s)
		var hem := h.z * 0.4 * k if i == ROWS else 0.0
		# Hanging, the cloth is wide across; spread (gliding) it turns into a
		# wing stretched out behind along the trail.
		var hx := half * 0.5 * (1.0 - _spread)
		var hy := half * 0.55 * _spread
		left.append(Vector2(cx - hx, cy - hy - hem * 0.2))
		right.append(Vector2(cx + hx, cy + hy * 0.7 + hem * 0.2))
	var poly := PackedVector2Array()
	poly.append_array(left)
	var r := right.duplicate()
	r.reverse()
	poly.append_array(r)
	draw_colored_polygon(poly, Color(0.06, 0.06, 0.09, 0.97))
	# Lining fold and a rim of moonlight on the outer edge.
	var mid := PackedVector2Array()
	for i in ROWS + 1:
		mid.append(left[i].lerp(right[i], 0.62))
	draw_polyline(mid, Color(0.16, 0.15, 0.22, 0.9), maxf(1.0, k * 0.8))
	draw_polyline(left, Color(0.42, 0.46, 0.66, 0.95), maxf(1.5, k * 0.9))
	draw_polyline(right, Color(0.22, 0.24, 0.36, 0.9), maxf(1.0, k * 0.6))
	var hem_pts := PackedVector2Array([left[ROWS], left[ROWS].lerp(right[ROWS], 0.33) + Vector2(0, -h.z * 0.35 * k), left[ROWS].lerp(right[ROWS], 0.66), right[ROWS]])
	draw_polyline(hem_pts, Color(0.02, 0.02, 0.04), maxf(1.0, k * 0.7))


func _ears(h: Vector3, k: float, fx: float) -> void:
	var c := Vector2(h.x * absf(anim.scale.x) * fx, anim.position.y + h.y * k)
	var r := h.z * k
	var col := Color(0.06, 0.06, 0.09)
	for e in [[-0.55, -0.12, -0.38], [0.05, 0.45, 0.28]]:
		var a := Vector2(c.x + float(e[0]) * r * fx, c.y - r * 0.7)
		var b := Vector2(c.x + float(e[1]) * r * fx, c.y - r * 0.78)
		var tip := Vector2(c.x + float(e[2]) * r * fx, c.y - r * 1.6)
		draw_colored_polygon(PackedVector2Array([a, tip, b]), col)
		draw_line(a, tip, Color(0.4, 0.44, 0.62, 0.9), maxf(1.0, k * 0.5))
