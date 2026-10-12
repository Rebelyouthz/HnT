class_name ImpactFeel
extends RefCounted

## Every hero blow lands differently on the thug's body (BrawlMore.on_blow):
##   HEAD     jab, cross, hook, roundhouse...  the head snaps back, the body
##            tilts away from the fist
##   GUT      gut, body hook, knee, front kick  he folds over the blow
##   RISE     uppercut, launcher                he is lifted off his heels
##   LEGS     sweep, low kick, slide            the legs go, he tips forward
##   BIG      heavy kicks and finishers         a shockwave ring, speed lines
##            and a camera kick in the direction of the blow
## Kicks kick up dust at the feet and push harder than punches.

const HEAD := ["jab", "cross", "heavy", "superman_punch", "spin_backfist", "headbutt", "hammer", "elbow", "roundhouse", "jump_roundhouse", "side_kick", "air_spin_kick", "jump_high_kick", "jump_spin_kick", "boot_kick", "backflip_kick"]
const GUT := ["gut", "body_hook", "clinch_knee", "front_kick", "flying_knee", "shoulder_charge", "dropkick"]
const RISE := ["uppercut", "air_mix", "cartwheel_kick"]
const LEGS := ["sweep", "slide", "dive"]


static func zone(move: String, kind: String) -> String:
	if move in RISE or kind == "launcher":
		return "rise"
	if move in GUT:
		return "gut"
	if move in LEGS or kind == "slide":
		return "legs"
	return "head"


static func is_kick(move: String) -> bool:
	return move.contains("kick") or move in ["roundhouse", "jump_roundhouse", "sweep", "flying_knee", "clinch_knee", "dropkick"]


static func blow(e: Punk, f: Fighter, kind: String) -> void:
	if e == null or f == null or not is_instance_valid(e) or e.visual == null:
		return
	var move := str(f.anim_atk)
	var dir := signf(e.global_position.x - f.global_position.x)
	if dir == 0.0:
		dir = float(f.facing)
	var big := kind in ["heavy", "special", "combo", "finish", "roundhouse"] or move in ["roundhouse", "jump_roundhouse", "dropkick", "superman_punch", "hammer", "backflip_kick"]
	var kick := is_kick(move)
	var z := zone(move, kind)
	var v: Node2D = e.visual
	# Body reaction: a quick pose, then back to rest.
	var rot := 0.0
	var sy := 1.0
	var k := 1.0 if big else 0.6
	match z:
		"head":
			rot = 0.20 * dir * k
		"gut":
			rot = -0.16 * dir * k
			sy = 1.0 - 0.12 * k
		"rise":
			rot = 0.12 * dir
			sy = 1.0 + 0.1 * k
		"legs":
			rot = -0.28 * dir * k
	var tw := v.create_tween().set_ignore_time_scale(true)
	tw.tween_property(v, "rotation", rot, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(v, "scale:y", sy, 0.04)
	tw.tween_interval(0.06 if not big else 0.1)
	tw.tween_property(v, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(v, "scale:y", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Kicks push harder and throw up dust at the feet.
	var host := e.get_parent()
	if kick and host != null:
		e.global_position.x += dir * (6.0 if not big else 12.0)
		Juice.land_puff(e.global_position + Vector2(-dir * 8.0, 0))
	# Where it landed: a white star for punches, a wider ring for kicks.
	var at := e.global_position + Vector2(-dir * 6.0, {"head": -92.0, "gut": -60.0, "rise": -80.0, "legs": -18.0}[z])
	if host != null:
		ArtFx.spawn(host, at, "ring", Color(1, 1, 1, 0.9) if not kick else Color(1.0, 0.85, 0.5), 22.0 if not big else 40.0, 0.14)
	if big and host != null:
		var sl := Lines.new()
		sl.dir = dir
		sl.global_position = at
		sl.z_index = 6
		host.add_child(sl)
		Juice.kick(Vector2(dir, -0.2 if z == "rise" else 0.0), 7.0 if kick else 5.0)


## Speed lines streaking out of a big hit, gone in a few frames.
class Lines extends Node2D:
	var dir := 1.0
	var _t := 0.0
	var _rows: Array = []

	func _ready() -> void:
		for i in 7:
			_rows.append([randf_range(-26, 26), randf_range(18, 46), randf_range(0.0, 0.05)])

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.18:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - _t / 0.18, 0.0, 1.0)
		for r in _rows:
			var y: float = r[0]
			var l: float = r[1] * (0.6 + _t * 4.0)
			var x0 := dir * (6.0 + _t * 120.0)
			draw_line(Vector2(x0, y), Vector2(x0 + dir * l, y), Color(1, 1, 1, 0.8 * a), 1.5)
