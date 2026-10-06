class_name BodySense
extends Node

## Bodies and the sounds of moving them (one per run):
##   SPACE     heroes and thugs in the same lane push apart instead of
##             walking through or standing inside each other
##   STEPS     quiet footsteps on roofs (the street has its own), and soft
##             steps from thugs walking close by
##   PARKOUR   ladder rungs, wall-run squeaks, vault and slide whooshes

const HERO_R := 15.0
const THUG_R := 13.0
const LANE := 12.0

var _t := {}
var _was := {}


func _physics_process(delta: float) -> void:
	var bodies: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed and not (n as Fighter).puppeted and (n as Fighter).art_lock <= 0.0:
			bodies.append(n)
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk:
			var e: Punk = n
			if e.hp > 0 and not e.flung and e.is_physics_processing() and e.home != "air" and e.vehicle == "" and not (e is ActBoss):
				bodies.append(e)
	_separate(bodies)
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			_sounds(n as Fighter, delta)
	_thug_steps(delta)


func _radius(b: Node2D) -> float:
	return HERO_R if b is Fighter else THUG_R


func _air(b: Node2D) -> bool:
	if b is Fighter:
		var f := b as Fighter
		return f.hop < -14.0 or f.plane != "street"
	return false


func _separate(bodies: Array[Node2D]) -> void:
	var n := bodies.size()
	for i in n:
		var a := bodies[i]
		if _air(a):
			continue
		for j in range(i + 1, n):
			var b := bodies[j]
			if _air(b):
				continue
			var dy := absf(a.global_position.y - b.global_position.y)
			# Two thugs nearly on top of each other in depth: ease them apart
			# up and down the lane so a group reads as a crowd, not a pile.
			if a is Punk and b is Punk and dy < 22.0 and absf(b.global_position.x - a.global_position.x) < 30.0:
				var sy := signf(b.global_position.y - a.global_position.y)
				if sy == 0.0:
					sy = 1.0 if i % 2 == 0 else -1.0
				var py := (22.0 - dy) * 0.04
				a.global_position.y -= sy * py
				b.global_position.y += sy * py
			if dy > LANE:
				continue
			var dx := b.global_position.x - a.global_position.x
			var need := _radius(a) + _radius(b)
			if absf(dx) >= need:
				continue
			var push := (need - absf(dx)) * 0.5
			var s := signf(dx) if dx != 0.0 else (1.0 if i % 2 == 0 else -1.0)
			# Heroes give less ground than thugs: they are the ones moving.
			var ka := 0.35 if a is Fighter and b is Punk else 0.5
			var kb := 0.35 if b is Fighter and a is Punk else 0.5
			a.global_position.x -= s * push * ka * 2.0
			b.global_position.x += s * push * kb * 2.0


func _every(key: String, secs: float, delta: float) -> bool:
	_t[key] = float(_t.get(key, 0.0)) - delta
	if float(_t[key]) <= 0.0:
		_t[key] = secs
		return true
	return false


func _sounds(f: Fighter, delta: float) -> void:
	var key := str(f.get_instance_id())
	var spd := absf(f.velocity.x)
	# Roof footsteps.
	if f.plane == "roof" and f.is_on_floor() and spd > 28.0 and _every(key + "rf", clampf(0.34 - spd / 900.0, 0.14, 0.34), delta):
		KitSfx.foot(f.role, clampf(spd / 280.0, 0.2, 1.2))
	# Ladder rungs.
	if f.plane == "climb" and absf(f.velocity.y) > 10.0 and _every(key + "cl", 0.22, delta):
		Mixer.play_sfx("res://assets/audio/cling.wav", randf_range(1.5, 1.8), -16.0)
	# Wall-run squeaks.
	if f.wall_run > 0.0 and _every(key + "wr", 0.12, delta):
		Mixer.play_sfx("res://assets/audio/sfx/foot_%d.ogg" % (1 + randi() % 4), randf_range(1.3, 1.5), -12.0)
	# Edge-triggered: vault and slide.
	var vault := f.parkour_lock > 0.0
	if vault and not bool(_was.get(key + "v", false)):
		Mixer.play_sfx("res://assets/audio/whoosh_light.wav", randf_range(1.0, 1.15), -9.0)
	_was[key + "v"] = vault
	var slide := f.sliding
	if slide and not bool(_was.get(key + "s", false)):
		Mixer.play_sfx("res://assets/audio/sfx/hit_sweep.ogg", 0.7, -12.0)
	_was[key + "s"] = slide


func _thug_steps(delta: float) -> void:
	if not _every("thugs", 0.3, delta):
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	var n := 0
	for m in get_tree().get_nodes_in_group("enemies"):
		if n >= 2:
			break
		if m is Punk:
			var e: Punk = m
			if e.hp > 0 and absf(e.velocity.x) > 20.0 and e.home != "air" and absf(e.global_position.x - c.x) < 260.0:
				n += 1
				Mixer.play_sfx("res://assets/audio/sfx/foot_%d.ogg" % (1 + randi() % 4), randf_range(0.8, 0.95), -21.0)
