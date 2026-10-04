class_name TrickMove
extends RefCounted

## The body doing the trick: rotations and squashes on the fighter's art,
## turned around the hips (not the feet), on top of the vault hop:
##   vault / lazy / reverse - lean onto the hand, legs swing through
##   kong / kong2           - dive the hands forward, tuck the knees after
##   roll / dive_roll       - a full forward roll low over the shoulder
##   front_flip / back_flip - a full tucked rotation forward / backward
##   side_flip              - a sideways rotation (squash through the turn)
##   cork                   - back flip with a full twist
##   palm_spin / wall_spin  - spin around the vertical axis
##   wall / cat             - run up, kick off, chest up
## Plus the Vector feel: speed streaks across the screen while it happens.

const HIP := Vector2(0, -30)


static func play(f: Fighter, anim: String, perfect: bool) -> void:
	if ResourceLoader.exists("res://assets/audio/sfx/flip.ogg"):
		Mixer.play_sfx("res://assets/audio/sfx/flip.ogg", randf_range(0.95, 1.1) * (1.2 if perfect else 1.0), -6.0)
	VoBank.effort(str(f.role), 0.5)
	# The sprite itself turns (the art node above it is driven by the hop).
	var art := f.get("_anim") as Node2D
	if art == null:
		return
	if not art.has_meta("base_pos"):
		art.set_meta("base_pos", art.position)
		art.set_meta("base_scale", art.scale)
	art.scale = art.get_meta("base_scale")
	# Rotation is in the art's own (already facing-flipped) space.
	var face := 1.0
	var dur := 0.5 if not perfect else 0.58
	var spin := func(target: float, t: float, tw: Tween) -> void:
		tw.tween_method(func(a: float) -> void: _turn(art, a, face), 0.0, target, t)
	var tw := art.create_tween()
	match anim:
		"front_flip":
			_clip(f, "jump", 0.5)
			spin.call(TAU, dur, tw)
		"back_flip":
			_clip(f, "jump", 0.5)
			spin.call(-TAU, dur, tw)
		"cork":
			_clip(f, "jump", 0.5)
			spin.call(-TAU, dur, tw)
			_twist(art, face, dur, 2)
		"side_flip":
			_clip(f, "jump", 0.5)
			spin.call(TAU * 0.98, dur, tw)
			var sq := art.create_tween()
			var sy: float = (art.get_meta("base_scale") as Vector2).y
			sq.tween_property(art, "scale:y", sy * 0.7, dur * 0.5)
			sq.tween_property(art, "scale:y", sy, dur * 0.5)
		"roll", "dive_roll":
			_clip(f, "dive" if anim == "dive_roll" else "duck", 0.5)
			if anim == "dive_roll":
				spin.call(PI * 0.4, dur * 0.35, tw)
				tw.tween_method(func(a: float) -> void: _turn(art, a, face), PI * 0.4, TAU, dur * 0.65)
			else:
				spin.call(TAU, dur, tw)
		"kong", "kong2":
			_clip(f, "dive", 0.5)
			spin.call(PI * 0.42, dur * 0.3, tw)
			tw.tween_method(func(a: float) -> void: _turn(art, a, face), PI * 0.42, -0.25, dur * 0.3)
			if anim == "kong2":
				tw.tween_method(func(a: float) -> void: _turn(art, a, face), -0.25, PI * 0.42, dur * 0.2)
				tw.tween_method(func(a: float) -> void: _turn(art, a, face), PI * 0.42, 0.0, dur * 0.25)
			else:
				tw.tween_method(func(a: float) -> void: _turn(art, a, face), -0.25, 0.0, dur * 0.3)
		"vault", "lazy", "dash_vault":
			_clip(f, "jump", 0.3)
			var lean := 0.45 if anim != "dash_vault" else 1.2
			spin.call(lean, dur * 0.35, tw)
			tw.tween_method(func(a: float) -> void: _turn(art, a, face), lean, -0.3, dur * 0.35)
			tw.tween_method(func(a: float) -> void: _turn(art, a, face), -0.3, 0.0, dur * 0.3)
			if anim == "lazy":
				_twist(art, face, dur * 0.6, 1)
		"reverse", "palm_spin", "wall_spin":
			_clip(f, "jump", 0.4)
			_twist(art, face, dur, 2 if anim != "reverse" else 1)
		"wall", "cat":
			_clip(f, "jump", 0.2)
			spin.call(-0.5, dur * 0.4, tw)
			tw.tween_method(func(a: float) -> void: _turn(art, a, face), -0.5, 0.0, dur * 0.6)
		"webster":
			# One-leg take-off front flip: a lean in, then a fast forward turn.
			_clip(f, "air_spin_kick" if (f.get("_anim") as AnimatedSprite2D).sprite_frames.has_animation("air_spin_kick") else "jump", 0.3)
			spin.call(0.35, dur * 0.2, tw)
			tw.tween_method(func(a: float) -> void: _turn(art, a, face), 0.35, TAU, dur * 0.8)
		"gainer":
			# Back flip while travelling forward: a long, floaty backward turn.
			_clip(f, "jump", 0.55)
			spin.call(-TAU, dur * 1.3, tw)
			f.velocity.x += float(f.facing) * 120.0
		"aerial":
			# No-hands cartwheel: sideways turn, the body squashed flat mid-air.
			_clip(f, "cartwheel_kick" if (f.get("_anim") as AnimatedSprite2D).sprite_frames.has_animation("cartwheel_kick") else "jump", 0.5)
			spin.call(TAU, dur * 0.9, tw)
			var sq2 := art.create_tween()
			var sx: float = (art.get_meta("base_scale") as Vector2).x
			sq2.tween_property(art, "scale:x", sx * 0.55, dur * 0.45)
			sq2.tween_property(art, "scale:x", sx, dur * 0.45)
		"precision":
			var sq := art.create_tween()
			var sy: float = (art.get_meta("base_scale") as Vector2).y
			sq.tween_property(art, "scale:y", sy * 0.82, dur * 0.4)
			sq.tween_property(art, "scale:y", sy, dur * 0.3)
	tw.tween_callback(func() -> void: _turn(art, 0.0, face))
	streaks(f, perfect)


## Rotate the art by `a` around the hips (flipped with the facing).
static func _turn(art: Node2D, a: float, face: float) -> void:
	if not is_instance_valid(art):
		return
	art.rotation = a * face
	var p0: Vector2 = art.get_meta("base_pos", art.position)
	art.position = HIP + (p0 - HIP).rotated(art.rotation)


## Spin around the vertical axis: flip the facing scale through zero.
static func _twist(art: Node2D, face: float, dur: float, turns: int) -> void:
	var tw := art.create_tween()
	var step := dur / float(turns * 2)
	var sx: float = (art.get_meta("base_scale", art.scale) as Vector2).x
	for i in turns * 2:
		var target := -sx if i % 2 == 0 else sx
		tw.tween_property(art, "scale:x", 0.0, step * 0.5)
		tw.tween_property(art, "scale:x", target, step * 0.5)


static func _clip(f: Fighter, clip: String, frac: float) -> void:
	var a: AnimatedSprite2D = f.get("_anim")
	if a == null or not a.sprite_frames.has_animation(clip):
		return
	a.play(clip)
	a.pause()
	a.frame = clampi(int(float(a.sprite_frames.get_frame_count(clip) - 1) * frac), 0, a.sprite_frames.get_frame_count(clip) - 1)
	f.get_tree().create_timer(0.55).timeout.connect(func() -> void:
		if is_instance_valid(a):
			a.play()
	)


## Vector feel: white speed streaks rushing past while a trick is in the air.
static func streaks(f: Fighter, perfect: bool) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	f.get_tree().current_scene.add_child(layer)
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(c)
	var lines: Array = []
	for i in (22 if perfect else 14):
		lines.append([randf() * 640.0, randf_range(20.0, 340.0), randf_range(30.0, 120.0), randf_range(500.0, 900.0)])
	var face := float(f.facing)
	var t0 := Time.get_ticks_msec()
	c.draw.connect(func() -> void:
		var t := float(Time.get_ticks_msec() - t0) / 1000.0
		var a := clampf(1.0 - t / 0.7, 0.0, 1.0)
		for l: Array in lines:
			var x := fposmod(float(l[0]) - face * float(l[3]) * t, 760.0) - 60.0
			c.draw_rect(Rect2(x, float(l[1]), float(l[2]), 1.0), Color(1, 1, 1, 0.35 * a))
		# Edge vignette.
		c.draw_rect(Rect2(0, 0, 640, 18), Color(0, 0, 0.02, 0.35 * a))
		c.draw_rect(Rect2(0, 342, 640, 18), Color(0, 0, 0.02, 0.35 * a))
	)
	var tw := layer.create_tween()
	tw.tween_method(func(_v: float) -> void: c.queue_redraw(), 0.0, 1.0, 0.7)
	tw.tween_callback(layer.queue_free)
