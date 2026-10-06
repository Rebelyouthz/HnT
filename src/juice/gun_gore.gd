class_name GunGore
extends Object

## What rounds do to a body. Landmarks are read off the sprite's head circle
## (BloodSim.head_of): the body is ~11.8 head radii tall.
##
## Wounds (the hit is survived): an entry hole where the round went in, an
## exit spray behind the body, blood running from it. A shotgun up close
## tears a ragged patch instead of a hole.
##
## Deaths:
##   head + shotgun close / orb  DECAP: the head comes off and flies, the
##                               neck pumps, the body stands a beat, drops.
##   head (any other round)      HEADSHOT: a mist of blood and skull out of
##                               the far side, the head snaps, he crumples
##                               where he stood with the hole in his head.
##   chest + shotgun close       GAPE: a hole clean through the chest.
##   legs + shotgun close        LEG OFF: the leg goes, he falls on the stump.
##   orb (anywhere)              FINAL NOTICE: dissolves into red ink and
##                               shredded invoices.

const CLOSE := 110.0


static func landmark(anim: CanvasItem, zone: String) -> Vector2:
	var h := BloodSim.head_of(anim)
	var r := maxf(h.z, 1.0)
	match zone:
		"head":
			return Vector2(h.x + r * 0.2, h.y)
		"gut":
			return Vector2(h.x, h.y + r * 4.3)
		"legs":
			return Vector2(h.x + r * 0.5, h.y + r * 7.8)
	return Vector2(h.x, h.y + r * 2.8)


## A survived hit: hole, exit spray, a run of blood.
static func wound(p: Punk, shot: Dictionary, dir: float) -> void:
	if FamilyProfile.less_gore():
		return
	var anim := p.get("_anim") as AnimatedSprite2D
	var zone := str(shot.get("zone", "chest"))
	var w := str(shot.get("weapon", "pistol"))
	var close := float(shot.get("dist", 999.0)) < CLOSE
	var blood := p.get_tree().get_first_node_in_group("blood_sim")
	var world_y: float = {"head": -56.0, "chest": -42.0, "gut": -32.0, "legs": -14.0}.get(zone, -40.0)
	var at := p.global_position + Vector2(0, world_y)
	var through := bool(shot.get("through", false))
	if blood:
		if through:
			# Clean through: a spray out of the far side, thrown on with the
			# round (it paints the street behind), a little back at the gun.
			blood.burst(at, p.global_position.y, dir, {"n": 14 if w != "shotgun" else 22, "speed": 300.0, "spread": 0.3, "rise": 0.12, "size": 1.1, "streak": true, "mist": zone == "head"})
			blood.burst(at, p.global_position.y, -dir, {"n": 3, "speed": 90.0, "spread": 0.6, "rise": 0.4, "size": 0.8})
		else:
			# The round stays in: a short spurt back out of the entry hole,
			# then it runs and drips.
			blood.burst(at, p.global_position.y, -dir, {"n": 6, "speed": 120.0, "spread": 0.5, "rise": 0.3, "size": 0.9})
			for k in 4:
				p.get_tree().create_timer(0.25 + 0.3 * float(k)).timeout.connect(func() -> void:
					if is_instance_valid(p) and p.hp > 0:
						blood.burst(p.global_position + Vector2(0, world_y + 4.0), p.global_position.y, dir * 0.1, {"n": 2, "speed": 20.0, "spread": 1.0, "rise": 0.0, "size": 0.8})
				)
		if zone == "head" and blood.has_method("gore"):
			blood.gore(p.global_position, dir, "teeth")
	if anim != null:
		var lm := landmark(anim, zone)
		var n := 1
		if w == "shotgun":
			n = 4 if close else 2
		for i in n:
			BloodSim.add_hole(anim, lm + Vector2(randf_range(-3.0, 3.0), randf_range(-4.0, 4.0)) * (2.0 if w == "shotgun" else 1.0))
		if through:
			# The exit is bigger and torn, a little further along the body.
			var r := maxf(BloodSim.head_of(anim).z, 1.0)
			BloodSim.add_hole(anim, lm + Vector2(r * 0.55 * dir * (-1.0 if anim.flip_h else 1.0), randf_range(-2.0, 3.0)), true)
	if zone == "legs":
		HitReact.react(p.visual, p.facing, "low" if w == "shotgun" and close else "gut", dir, 0.4)
	elif zone == "head":
		HitReact.react(p.visual, p.facing, "head", dir, 0.9)


## The gun death. Returns true when it replaced the ordinary corpse.
static func death(p: Punk, shot: Dictionary, dir: float) -> bool:
	if FamilyProfile.less_gore():
		return false
	var anim := p.get("_anim") as AnimatedSprite2D
	if anim == null:
		return false
	var zone := str(shot.get("zone", "chest"))
	var w := str(shot.get("weapon", "pistol"))
	var close := float(shot.get("dist", 999.0)) < CLOSE
	var host := p.get_parent()
	var blood := p.get_tree().get_first_node_in_group("blood_sim")
	var head := BloodSim.head_of(anim)
	var r := maxf(head.z, 1.0)
	if w == "ray":
		_dissolve(p, anim, dir)
		return true
	# The corpse copies the sprite's material: make sure it is the wound
	# shader (a punk shot clean has never had a melee wound).
	BloodSim._wound_mat(anim).set_shader_parameter("head", head)
	var style := DeathFall.pick("bullet", "gun", "", "", 1.0, shot)
	if zone == "head" and close and w == "shotgun":
		style = "decap"
	elif zone == "legs" and close and w == "shotgun":
		style = "legs"
	elif zone == "chest" and close and w == "shotgun":
		style = "blown"
	var body := HitReact.corpse(host, anim, p.global_position, "shot", dir, p.facing, style)
	if body == null:
		return false
	var art := _art_of(body)
	var m: ShaderMaterial = art.material as ShaderMaterial if art != null else null
	if zone == "head" and (close and w == "shotgun"):
		# DECAP.
		if m:
			m.set_shader_parameter("cut_head", 1.0)
		_fly_piece(host, art, p.global_position, dir, 1, head)
		_neck_fountain(body, blood, dir)
		Juice.shout("DECAPITATED")
		Mixer.play_sfx("res://assets/audio/sfx/skull_crunch.ogg")
		Mixer.play_sfx("res://assets/audio/sfx/gib_splat.ogg", 1.0, -2.0)
		Juice.freeze_frames(6)
		if blood:
			blood.screen(dir, 1.0)
	elif zone == "head":
		# HEADSHOT: mist and skull out of the far side.
		if blood:
			var hp := p.global_position + Vector2(0, -56)
			if bool(shot.get("through", true)):
				blood.burst(hp, p.global_position.y, dir, {"n": 40, "speed": 380.0, "spread": 0.5, "rise": 0.25, "size": 1.3, "streak": true, "mist": true})
			else:
				blood.burst(hp, p.global_position.y, -dir, {"n": 14, "speed": 160.0, "spread": 0.6, "rise": 0.3, "size": 1.1})
			blood.burst(hp, p.global_position.y, dir, {"n": 16, "speed": 200.0, "spread": 0.9, "rise": 0.5, "size": 1.8})
			if blood.has_method("gore"):
				blood.gore(p.global_position, dir, "teeth")
				blood.gore(p.global_position, dir, "kill")
		if m:
			BloodSim.add_hole(art, Vector2(head.x + r * 0.2, head.y))
			m.set_shader_parameter("wound", 1.0)
		Juice.shout("HEADSHOT")
		Mixer.play_sfx("res://assets/audio/sfx/skull_crunch.ogg", 1.0, -2.0)
		Juice.freeze_frames(4)
	elif zone == "chest" and close and w == "shotgun":
		if m:
			m.set_shader_parameter("gape", Vector3(head.x - r * 0.45 * float(p.facing), head.y + r * 3.2, r * 1.2))
		if blood:
			blood.burst(p.global_position + Vector2(0, -40), p.global_position.y, dir, {"n": 50, "speed": 420.0, "spread": 0.4, "rise": 0.2, "size": 1.5, "streak": true})
			if blood.has_method("gore"):
				blood.gore(p.global_position, dir, "kill")
		Juice.shout("CLEAN THROUGH")
		Mixer.play_sfx("res://assets/audio/sfx/gib_splat.ogg", 1.0, -1.0)
	elif zone == "legs" and w == "shotgun" and close:
		var side := float(p.facing)
		if m:
			m.set_shader_parameter("cut_leg", side)
		_fly_piece(host, art, p.global_position, dir, 2, head, side)
		if blood:
			blood.burst(p.global_position + Vector2(0, -16), p.global_position.y, dir, {"n": 30, "speed": 260.0, "spread": 0.6, "rise": 0.3, "size": 1.4})
			blood.pool(p.global_position + Vector2(dir * 8.0, 2), 22.0)
		Juice.shout("LEG DAY")
		Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg")
	else:
		if m:
			BloodSim.add_hole(art, landmark(art, zone))
		if blood:
			if bool(shot.get("through", false)):
				blood.burst(p.global_position + Vector2(0, -40), p.global_position.y, dir, {"n": 18, "speed": 300.0, "spread": 0.4, "rise": 0.2, "size": 1.1, "streak": true})
			else:
				blood.burst(p.global_position + Vector2(0, -40), p.global_position.y, -dir, {"n": 8, "speed": 120.0, "spread": 0.5, "rise": 0.3, "size": 0.9})
	return true


## A blade takes the head (the MACHETE's killing chop). False = could not
## (no sprite, less gore), so the ordinary death plays.
static func decap(p: Punk, dir: float) -> bool:
	if FamilyProfile.less_gore():
		return false
	var anim := p.get("_anim") as AnimatedSprite2D
	if anim == null:
		return false
	var host := p.get_parent()
	var blood := p.get_tree().get_first_node_in_group("blood_sim")
	var head := BloodSim.head_of(anim)
	BloodSim._wound_mat(anim).set_shader_parameter("head", head)
	var body := HitReact.corpse(host, anim, p.global_position, "blade", dir, p.facing, "decap")
	if body == null:
		return false
	var art := _art_of(body)
	var m: ShaderMaterial = art.material as ShaderMaterial if art != null else null
	if m:
		m.set_shader_parameter("cut_head", 1.0)
	_fly_piece(host, art, p.global_position, dir, 1, head)
	_neck_fountain(body, blood, dir)
	Arsenal.bump("decaps")
	Juice.shout("DECAPITATED")
	Mixer.play_sfx("res://assets/audio/sfx/melee_machete.ogg", 0.85, 0.0)
	Mixer.play_sfx("res://assets/audio/sfx/gib_splat.ogg", 1.0, -2.0)
	Juice.freeze_frames(6)
	if blood:
		blood.screen(dir, 0.8)
	return true


static func _art_of(body: Node2D) -> CanvasItem:
	for c in body.get_children():
		for cc in c.get_children():
			if cc is Sprite2D or cc is AnimatedSprite2D:
				return cc
	return null


## A severed piece (only = 1 head, 2 leg): the same frame drawn with only
## that part kept, thrown, spinning, bouncing, bleeding where it lands.
static func _fly_piece(host: Node, art: CanvasItem, feet: Vector2, dir: float, only: int, head: Vector3, side: float = 1.0) -> void:
	if host == null or art == null:
		return
	var tex: Texture2D = null
	if art is AnimatedSprite2D:
		var a := art as AnimatedSprite2D
		tex = a.sprite_frames.get_frame_texture(a.animation, a.frame)
	elif art is Sprite2D:
		tex = (art as Sprite2D).texture
	if tex == null:
		return
	var piece := Node2D.new()
	piece.z_index = 4
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = true
	sp.scale = (art as Node2D).scale
	sp.flip_h = art.get("flip_h") if art.get("flip_h") != null else false
	sp.texture_filter = art.texture_filter
	var mat := (art.material as ShaderMaterial).duplicate() as ShaderMaterial if art.material is ShaderMaterial else null
	if mat:
		mat.set_shader_parameter("only", only)
		mat.set_shader_parameter("cut_leg", side)
		mat.set_shader_parameter("cut_head", 0.0)
		sp.material = mat
	# Pivot the piece on its own centre so it tumbles believably.
	var r := maxf(head.z, 1.0)
	var c := Vector2(head.x, head.y) if only == 1 else Vector2(head.x - r * 0.2 * side, head.y + r * 8.5)
	sp.position = -c * sp.scale
	piece.add_child(sp)
	var start := (art as Node2D).global_position + c * sp.scale
	piece.global_position = start
	host.add_child(piece)
	var land := Vector2(start.x + dir * randf_range(50.0, 110.0), feet.y - 3.0)
	var tw := piece.create_tween()
	tw.set_parallel(true)
	tw.tween_property(piece, "global_position:x", land.x, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(piece, "global_position:y", start.y - (70.0 if only == 1 else 30.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(piece, "rotation", dir * randf_range(6.0, 11.0), 0.75)
	tw.chain().tween_property(piece, "global_position:y", land.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(piece, "global_position:y", land.y - 8.0, 0.1)
	tw.chain().tween_property(piece, "global_position:y", land.y, 0.1)
	tw.chain().tween_callback(func() -> void:
		Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 1.5, -8.0)
		var b := piece.get_tree().get_first_node_in_group("blood_sim") if piece.is_inside_tree() else null
		if b and b.has_method("pool"):
			b.pool(Vector2(land.x, feet.y + 1.0), 10.0)
	)
	tw.chain().tween_interval(18.0)
	tw.chain().tween_property(piece, "modulate:a", 0.0, 1.5)
	tw.chain().tween_callback(piece.queue_free)
	# A thin trail of drops while it flies.
	var b2 := host.get_tree().get_first_node_in_group("blood_sim")
	if b2:
		for i in 6:
			host.get_tree().create_timer(0.08 * float(i)).timeout.connect(func() -> void:
				if is_instance_valid(piece):
					b2.burst(piece.global_position, feet.y, dir, {"n": 3, "speed": 60.0, "spread": 1.2, "rise": 0.2, "size": 0.9})
			)


static func _neck_fountain(body: Node2D, blood: Node, dir: float) -> void:
	if blood == null:
		return
	for k in 9:
		body.get_tree().create_timer(0.1 * float(k)).timeout.connect(func() -> void:
			if is_instance_valid(body):
				var neck := body.global_position + Vector2(0, -50.0 + float(k) * 4.0)
				if body is DeathFall:
					# The neck rides the falling body.
					neck = body.to_global(Vector2(0, -(body as DeathFall).H * 0.38))
				blood.burst(neck, body.global_position.y, dir * 0.3, {"n": 8, "speed": 260.0 - float(k) * 20.0, "spread": 0.3, "rise": 1.4, "size": 1.3, "streak": true})
		)


## FINAL NOTICE: the body goes red, shrinks to nothing in a cloud of ink and
## shredded paper.
static func _dissolve(p: Punk, anim: AnimatedSprite2D, dir: float) -> void:
	var host := p.get_parent()
	var body := HitReact.corpse(host, anim, p.global_position, "head", dir, p.facing)
	var blood := p.get_tree().get_first_node_in_group("blood_sim")
	if blood:
		blood.burst(p.global_position + Vector2(0, -40), p.global_position.y, dir, {"n": 50, "speed": 240.0, "spread": 1.4, "rise": 0.8, "size": 1.4})
	if body != null:
		var tw := body.create_tween()
		tw.tween_property(body, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.15)
		tw.tween_property(body, "scale", Vector2(1.15, 0.05), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(body, "modulate:a", 0.0, 0.35)
		tw.tween_callback(body.queue_free)
	var conf := CPUParticles2D.new()
	conf.global_position = p.global_position + Vector2(0, -36)
	conf.amount = 40
	conf.one_shot = true
	conf.explosiveness = 0.9
	conf.lifetime = 1.4
	conf.direction = Vector2(dir, -1)
	conf.spread = 70.0
	conf.initial_velocity_min = 60.0
	conf.initial_velocity_max = 180.0
	conf.gravity = Vector2(0, 160)
	conf.scale_amount_min = 1.0
	conf.scale_amount_max = 2.2
	conf.color = Color(0.95, 0.93, 0.86)
	conf.emitting = true
	host.add_child(conf)
	host.get_tree().create_timer(2.0).timeout.connect(conf.queue_free)
	Juice.shout("FINAL NOTICE")
	Mixer.play_sfx("res://assets/audio/sfx/gore_squelch.ogg", 0.8)
