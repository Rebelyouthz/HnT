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
		"gut", "front_kick", "side_kick", "flying_knee", "body_hook", "clinch_knee", "shoulder_charge", "dropkick", "boot_kick":
			return "gut"
		"uppercut", "backflip_kick", "getup_upper", "getup_kick", "jump_spin_kick", "jump_high_kick", "air_spin_kick":
			return "up"
		"slide", "sweep":
			return "low"
		"hammer":
			return "crush"
	return "head"


static func power_of(kind: String) -> float:
	match kind:
		"light", "jab", "snare":
			return 0.2
		"cross", "slide", "jump-kick":
			return 0.4
		"bam", "gut-punch", "blade", "air-mix", "special":
			return 0.6
		"heavy", "dive", "roundhouse", "uppercut", "air-upper", "launcher", "throw", "web-slam", "air-spin":
			return 0.85
		"snap", "finish", "stomp3", "blast":
			return 1.0
		"combo":
			return 0.9
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
		"trip":
			# Knees buckle from a low blow: a dip and a stumble forward.
			tw.tween_property(visual, "rotation", toward * deg_to_rad(12.0 + 8.0 * power), 0.07)
			tw.parallel().tween_property(visual, "position:x", away * 4.0, 0.07)
			tw.tween_property(visual, "rotation", away * deg_to_rad(4.0), 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(visual, "rotation", 0.0, 0.14)
			tw.parallel().tween_property(visual, "position:x", 0.0, 0.14)
			busy = 0.34
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
static func corpse(host: Node, art: AnimatedSprite2D, feet: Vector2, zone: String, dir: float, facing: int, style: String = "") -> Node2D:
	if host == null or art == null or art.sprite_frames == null:
		return null
	if style != "" and style != "drawn" and style != "crush" and DeathFall.STYLES.has(style):
		return _fall(host, art, feet, style, dir, facing)
	if style == "drawn":
		zone = "head"
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
	# A drawn death fall (falls backward, lies still) beats a tweened still
	# for the ordinary deaths; launches, blasts and crushes keep the tween.
	var drawn := art.sprite_frames.has_animation("death") and zone in ["head", "gut", "low", "bullet", "blade"]
	var flip := Node2D.new()
	flip.scale.x = float(facing)
	if drawn:
		# The fall moves the head every frame, but the wound shader's head
		# point is fixed: keep only a light splash so the body does not drown
		# in pixel blood.
		var dm := sp.material as ShaderMaterial
		if dm != null and dm.shader == preload("res://src/shaders/wound.gdshader"):
			dm.set_shader_parameter("wound", 0.3)
			dm.set_shader_parameter("splat", 0.2)
		var an := AnimatedSprite2D.new()
		an.sprite_frames = art.sprite_frames
		an.position = art.position
		an.scale = art.scale
		an.flip_h = art.flip_h
		an.centered = art.centered
		an.offset = art.offset
		an.texture_filter = art.texture_filter
		an.material = sp.material
		an.play("death")
		an.speed_scale = randf_range(0.95, 1.15) * (1.25 if zone == "bullet" else 1.0)
		sp.free()
		flip.add_child(an)
	else:
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
	if drawn:
		# The art does the fall; the body only slides with the blow.
		tw.tween_property(body, "position:x", feet.x + away * 18.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35)
		zone = "drawn"
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
		"bullet", "shot":
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
		"homerun":
			# Knocked out of the park: high, far, spinning, a bounce.
			lie = away * PI * 0.5
			tw.set_parallel(true)
			tw.tween_property(body, "position:x", feet.x + away * 260.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "rotation", away * (TAU * 3.0 + PI * 0.5), 1.0).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "position:y", feet.y - 120.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.chain().tween_property(body, "position:y", feet.y - 4.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.set_parallel(false)
			tw.tween_property(body, "position:y", feet.y - 16.0, 0.1)
			tw.tween_property(body, "position:y", feet.y - 4.0, 0.1)
		"burn":
			# Charred where they stood, still smoking.
			body.modulate = Color(0.35, 0.3, 0.28)
			FireFx.on_body(body, 2.5)
			tw.tween_property(body, "scale", Vector2(1.05, 0.85), 0.3)
			lie = away * PI * 0.5
			tw.tween_property(body, "rotation", lie, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(body, "scale", Vector2.ONE, 0.35)
			tw.parallel().tween_property(body, "position:y", feet.y - 4.0, 0.35)
			bleed = 2.0
		"drawn":
			bleed = 14.0
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


## A physics body (DeathFall) instead of a tweened still: gravity, spin,
## bounce, topple, skid, rest.
static func _fall(host: Node, art: AnimatedSprite2D, feet: Vector2, style: String, dir: float, facing: int) -> Node2D:
	var body := DeathFall.new()
	body.add_to_group("corpses")
	body.z_index = 3
	var sp := Sprite2D.new()
	var clip := "hurt" if art.sprite_frames.has_animation("hurt") else str(art.animation)
	sp.texture = art.sprite_frames.get_frame_texture(clip, mini(1, art.sprite_frames.get_frame_count(clip) - 1))
	sp.scale = art.scale
	sp.flip_h = art.flip_h
	sp.centered = art.centered
	sp.offset = art.offset
	sp.texture_filter = art.texture_filter
	# The body is the drawn figure, not the frame: measure the painted part
	# so the rod is as long and thick as the person, pivoting on its middle.
	var used := _used_rect(sp.texture)
	var c := used.get_center() + sp.offset - (sp.texture.get_size() * 0.5 if sp.centered else Vector2.ZERO)
	if sp.flip_h:
		c.x = -c.x
	var cs := c * sp.scale.abs()
	body.H = clampf(used.size.y * absf(sp.scale.y), 30.0, 260.0)
	body.T = clampf(used.size.x * absf(sp.scale.x) * 0.75, 10.0, body.H * 0.5)
	sp.position = -cs
	body.gx = feet.x + float(facing) * (art.position.x + cs.x)
	body.gy = feet.y
	body.face = facing
	body.zc = body.H * 0.5
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
	body.art_root = flip
	if style == "burn":
		body.modulate = Color(0.35, 0.3, 0.28)
		FireFx.on_body(body, 2.5)
	body.setup(style, dir)
	host.add_child(body)
	var all := host.get_tree().get_nodes_in_group("corpses")
	if all.size() > 12:
		var first := all[0] as Node2D
		var ft := first.create_tween()
		ft.tween_property(first, "modulate:a", 0.0, 0.6)
		ft.tween_callback(first.queue_free)
	return body


static var _rects := {}


## The painted part of a frame (cached per texture).
static func _used_rect(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2(0, 0, 32, 96)
	var key := tex.get_instance_id()
	if _rects.has(key):
		return _rects[key]
	var r := Rect2(Vector2.ZERO, tex.get_size())
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var u := img.get_used_rect()
		if u.size.x > 2 and u.size.y > 2:
			r = Rect2(u)
			# An atlas frame's image is only its region; the margin puts it
			# back where it sits in the full frame.
			if tex is AtlasTexture:
				r.position += (tex as AtlasTexture).margin.position
	_rects[key] = r
	return r
