class_name HitReact
extends RefCounted

## How a body answers a blow, by where it landed:
##   head  - the head snaps away, a half step back
##   gut   - folds over the fist, knees bend, a cough of blood
##   low   - legs swept: they go down on their back and get up again
##   up    - lifted off the street, head thrown back
##   bullet- a jolt back, a hole, blood out the far side
## and how they die from it (corpse()): face-first after a gut shot, flat on
## the back when the legs went, launched and spinning off an uppercut, a
## crumple and a spreading pool for a gun, a long tumble from a blast.

## Where a strike lands, from the hit kind and the attacker's move clip.
static func zone_of(kind: String, clip: String) -> String:
	match kind:
		"slide", "snare":
			return "low"
		"uppercut", "air-upper", "launcher":
			return "up"
		"bam", "gut-punch":
			return "gut"
		"blade":
			return "blade"
		"stomp1", "stomp2", "stomp3":
			return "crush"
		"bullet":
			return "bullet"
		"blast":
			return "blast"
	match clip:
		"gut", "front_kick", "side_kick":
			return "gut"
		"uppercut":
			return "up"
		"slide", "sweep":
			return "low"
	return "head"


static func power_of(kind: String) -> float:
	match kind:
		"light", "jab", "snare":
			return 0.2
		"cross", "slide", "jump-kick":
			return 0.4
		"bam", "gut-punch", "blade", "air-mix", "special":
			return 0.6
		"heavy", "dive", "roundhouse", "uppercut", "air-upper", "launcher", "throw", "web-slam":
			return 0.85
		"snap", "finish", "stomp3", "blast":
			return 1.0
	return 0.5


## Alive: a short body reaction on `visual` (the actor's art pivot at the
## feet). Returns how long the body is busy (s).
static func react(visual: Node2D, facing: int, zone: String, dir: float, power: float) -> float:
	if visual == null:
		return 0.0
	var old: Tween = visual.get_meta("react_tw") if visual.has_meta("react_tw") else null
	if old != null and old.is_valid():
		old.kill()
	visual.rotation = 0.0
	visual.position.x = 0.0
	var tw := visual.create_tween()
	visual.set_meta("react_tw", tw)
	# Positive rotation tips the top of the body toward +x.
	var away := dir
	var toward := -dir
	var busy := 0.2
	match zone:
		"gut":
			# Doubled over the fist: lean in toward the hitter, sink.
			tw.tween_property(visual, "rotation", toward * deg_to_rad(18.0 + 14.0 * power), 0.06)
			tw.parallel().tween_property(visual, "position:y", 3.0 + 3.0 * power, 0.06)
			tw.tween_interval(0.22 + 0.2 * power)
			tw.tween_property(visual, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_QUAD)
			tw.parallel().tween_property(visual, "position:y", 0.0, 0.18)
			busy = 0.45 + 0.2 * power
		"low", "crush":
			# Legs gone: down on the back, a beat on the ground, up again.
			tw.tween_property(visual, "rotation", away * deg_to_rad(82.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(visual, "position:y", 2.0, 0.16)
			tw.tween_property(visual, "rotation", away * deg_to_rad(74.0), 0.06)
			tw.tween_property(visual, "rotation", away * deg_to_rad(84.0), 0.06)
			tw.tween_interval(0.55)
			tw.tween_property(visual, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(visual, "position:y", 0.0, 0.28)
			busy = 1.15
		"up":
			tw.tween_property(visual, "rotation", away * deg_to_rad(22.0), 0.07)
			tw.parallel().tween_property(visual, "position:y", -10.0 - 10.0 * power, 0.12).set_ease(Tween.EASE_OUT)
			tw.tween_property(visual, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(visual, "rotation", 0.0, 0.22)
			busy = 0.42
		"bullet", "blade":
			tw.tween_property(visual, "rotation", away * deg_to_rad(10.0), 0.04)
			tw.parallel().tween_property(visual, "position:x", away * 3.0, 0.04)
			tw.tween_property(visual, "rotation", 0.0, 0.16)
			tw.parallel().tween_property(visual, "position:x", 0.0, 0.16)
			busy = 0.22
		_:
			# Head snapped away; harder blows rock the whole body.
			var a := deg_to_rad(6.0 + 16.0 * power)
			tw.tween_property(visual, "rotation", away * a, 0.04)
			tw.parallel().tween_property(visual, "position:x", away * (1.0 + 4.0 * power), 0.05)
			tw.tween_property(visual, "rotation", -away * a * 0.25, 0.1)
			tw.tween_property(visual, "rotation", 0.0, 0.12)
			tw.parallel().tween_property(visual, "position:x", 0.0, 0.14)
			busy = 0.18 + 0.2 * power
	return busy


## Dead: a still of the last frame becomes a body that falls the way the
## blow says, lies on the street and bleeds out. `art` is the sprite (its
## wound material is kept), `feet` the actor position, dir the blow.
static func corpse(host: Node, art: AnimatedSprite2D, feet: Vector2, zone: String, dir: float, facing: int) -> Node2D:
	if host == null or art == null or art.sprite_frames == null:
		return null
	var body := Node2D.new()
	body.position = feet
	body.z_index = 3
	body.add_to_group("corpses")
	var sp := Sprite2D.new()
	var clip := "hurt" if art.sprite_frames.has_animation("hurt") else str(art.animation)
	sp.texture = art.sprite_frames.get_frame_texture(clip, mini(1, art.sprite_frames.get_frame_count(clip) - 1))
	sp.position = art.position
	sp.scale = art.scale
	sp.flip_h = art.flip_h
	sp.centered = art.centered
	sp.offset = art.offset
	sp.texture_filter = art.texture_filter
	if art.material != null:
		sp.material = art.material.duplicate()
		var m := sp.material as ShaderMaterial
		if m != null and m.shader == preload("res://src/shaders/wound.gdshader"):
			m.set_shader_parameter("wound", 1.0)
			m.set_shader_parameter("head", BloodSim.head_of_tex(sp.texture))
			m.set_shader_parameter("splat", maxf(0.5, float(m.get_shader_parameter("splat"))))
	var flip := Node2D.new()
	flip.scale.x = float(facing)
	flip.add_child(sp)
	body.add_child(flip)
	host.add_child(body)
	# Old bodies make room.
	var all := host.get_tree().get_nodes_in_group("corpses")
	if all.size() > 9:
		var first := all[0] as Node2D
		var ft := first.create_tween()
		ft.tween_property(first, "modulate:a", 0.0, 0.6)
		ft.tween_callback(first.queue_free)
	var tw := body.create_tween()
	var away := dir
	var lie := 0.0
	var bleed := 10.0
	match zone:
		"gut":
			# Knees go, then face-first toward the one who did it.
			tw.tween_property(body, "rotation", -away * 0.35, 0.18)
			tw.parallel().tween_property(body, "position:y", feet.y + 4.0, 0.18)
			tw.tween_interval(0.12)
			lie = -away * PI * 0.5
			tw.tween_property(body, "rotation", lie, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(body, "position:y", feet.y - 4.0, 0.22)
			bleed = 12.0
		"low":
			# Feet swept out: a short flight, flat on the back.
			lie = away * PI * 0.5
			tw.tween_property(body, "position:y", feet.y - 10.0, 0.12).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(body, "rotation", lie, 0.2)
			tw.tween_property(body, "position:y", feet.y - 4.0, 0.12).set_ease(Tween.EASE_IN)
		"up":
			# Launched: up, back, a turn and a half in the air, slam.
			lie = away * PI * 0.5
			tw.set_parallel(true)
			tw.tween_property(body, "position:x", feet.x + away * 46.0, 0.62)
			tw.tween_property(body, "position:y", feet.y - 60.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "rotation", away * (TAU + PI * 0.5), 0.62)
			tw.chain().tween_property(body, "position:y", feet.y - 4.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.set_parallel(false)
			tw.tween_property(body, "position:y", feet.y - 9.0, 0.08)
			tw.tween_property(body, "position:y", feet.y - 4.0, 0.08)
		"bullet":
			# Jolt, sag, crumple where they stood. The pool does the rest.
			tw.tween_property(body, "position:x", feet.x + away * 5.0, 0.06)
			tw.tween_property(body, "scale", Vector2(1.05, 0.82), 0.25)
			tw.tween_interval(0.1)
			lie = away * PI * 0.5
			tw.tween_property(body, "rotation", lie, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(body, "scale", Vector2.ONE, 0.3)
			tw.parallel().tween_property(body, "position:y", feet.y - 4.0, 0.3)
			bleed = 22.0
		"blast":
			lie = away * PI * 0.5
			tw.set_parallel(true)
			tw.tween_property(body, "position:x", feet.x + away * 140.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "rotation", away * (TAU * 2.0 + PI * 0.5), 0.8).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "position:y", feet.y - 40.0, 0.25).set_ease(Tween.EASE_OUT)
			tw.chain().tween_property(body, "position:y", feet.y - 4.0, 0.3).set_ease(Tween.EASE_IN)
			tw.set_parallel(false)
		"crush":
			tw.tween_property(body, "scale", Vector2(1.25, 0.35), 0.1)
			bleed = 18.0
		_:
			# Spun off a head blow: a twist, then down on the back.
			lie = away * PI * 0.5
			tw.tween_property(body, "position:x", feet.x + away * 14.0, 0.3)
			tw.parallel().tween_property(body, "rotation", lie, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(body, "position:y", feet.y - 4.0, 0.3)
	tw.tween_callback(func() -> void:
		Juice.play("res://assets/audio/stumble.wav")
		Juice.pulse_shake(2.0)
		var blood := body.get_tree().get_first_node_in_group("blood_sim") if body.is_inside_tree() else null
		if blood and blood.has_method("pool"):
			blood.pool(Vector2(body.position.x + away * 6.0, feet.y + 2.0), bleed)
	)
	# Lie still a good while, then fade into the night.
	tw.tween_interval(18.0)
	tw.tween_property(body, "modulate:a", 0.0, 1.5)
	tw.tween_callback(body.queue_free)
	return body
