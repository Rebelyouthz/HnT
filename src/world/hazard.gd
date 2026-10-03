class_name Hazard
extends Node2D

## Street hazards for environmental kills: knock a thug into one (while he
## is reeling from a hit) and the street finishes him.
##   wire     a downed power line sparking over a puddle: ZAPPED (skeleton
##            flash, smoke). It bites you too if you stand in it.
##   manhole  an open manhole steaming: he drops straight in. DOWN THE DRAIN.
## Each environmental kill pays extra coins and XP.

var kind := "wire"
var _t := 0.0
var _zap_cd := 0.0
var _busy: Dictionary = {}


static func place_for(host: Node, map_w: float) -> void:
	for spec in [["manhole", 0.32], ["wire", 0.68]]:
		var h := Hazard.new()
		h.kind = str(spec[0])
		h.position = Vector2(map_w * float(spec[1]) + randf_range(-60, 60), 540.0)
		host.add_child(h)


func _ready() -> void:
	z_index = 1
	add_to_group("hazards")
	if kind == "wire":
		var l := PointLight2D.new()
		l.texture = LightRig.radial_tex()
		l.texture_scale = 0.35
		l.color = Color(0.5, 0.75, 1.0)
		l.energy = 0.8
		l.name = "Glow"
		add_child(l)


func _reach() -> Vector2:
	return Vector2(34, 12) if kind == "wire" else Vector2(20, 10)


func _process(delta: float) -> void:
	_t += delta
	_zap_cd -= delta
	if kind == "wire" and has_node("Glow"):
		(get_node("Glow") as PointLight2D).energy = 0.4 + (1.4 if fmod(_t * 7.0, 1.0) < 0.15 else 0.0)
	var r := _reach()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Punk) or _busy.has(e.get_instance_id()):
			continue
		var p := e as Punk
		if p.hp <= 0 or p.home != "street":
			continue
		var d := p.global_position - global_position
		if absf(d.x) > r.x or absf(d.y) > r.y:
			continue
		var reeling := float(p.get("recover")) > 0.0 and absf(p.velocity.x) > 40.0
		if reeling or (p.flung and absf(p.velocity.x) > 200.0):
			_busy[p.get_instance_id()] = true
			_kill(p)
	if kind == "wire" and _zap_cd <= 0.0:
		for f in get_tree().get_nodes_in_group("players"):
			if f is Fighter and not (f as Fighter).downed:
				var d2 := (f as Fighter).global_position - global_position
				if absf(d2.x) < r.x and absf(d2.y) < r.y and (f as Fighter).hop > -6.0:
					_zap_cd = 1.0
					(f as Fighter).take_hit("light", self)
					Juice.popup_number((f as Fighter).global_position + Vector2(0, -70), "ZAP", Color(0.6, 0.85, 1.0))
	queue_redraw()


func _kill(p: Punk) -> void:
	var host := get_parent()
	if kind == "wire":
		Juice.shout("ZAPPED")
		Mixer.play_sfx("res://assets/audio/sfx/ray.ogg" if ResourceLoader.exists("res://assets/audio/sfx/ray.ogg") else "res://assets/audio/hit_heavy.wav", 0.6, -2.0)
		var tw := p.create_tween().set_loops(6)
		tw.tween_property(p, "modulate", Color(3, 3, 4), 0.05)
		tw.tween_property(p, "modulate", Color(0.1, 0.1, 0.12), 0.05)
		await p.get_tree().create_timer(0.6).timeout
		if is_instance_valid(p) and p.hp > 0:
			p.modulate = Color(0.25, 0.22, 0.2)
			p.hp = 1
			p.take_hit("finish", self)
	else:
		Juice.shout("DOWN THE DRAIN")
		Mixer.play_sfx("res://assets/audio/body_fall.wav" if ResourceLoader.exists("res://assets/audio/body_fall.wav") else "res://assets/audio/hit_heavy.wav", 0.8, -2.0)
		p.set_physics_process(false)
		p.set_process(false)
		var tw2 := p.create_tween().set_parallel(true)
		tw2.tween_property(p, "global_position", global_position + Vector2(0, 6), 0.12)
		tw2.tween_property(p.visual, "scale:y", 0.0, 0.35).set_delay(0.1)
		tw2.tween_property(p.visual, "position:y", 30.0, 0.35).set_delay(0.1)
		await p.get_tree().create_timer(0.5).timeout
		if is_instance_valid(p):
			p.hp = 0
			p.call("_drops", self)
			QuestGiver.note(p.get_tree(), "kill", p.title)
			p.died.emit()
			p.queue_free()
	# The street's bonus.
	if is_instance_valid(host):
		for i in 3:
			LootDrop.spawn(host, global_position + Vector2(randf_range(-10, 10), -4), "coin", 1, 1.2)
		XpOrb.burst(host, global_position, 20)
	Juice.toast("reward", "ENVIRONMENTAL", "The street did the paperwork. +3 coins, +20 XP.")
	FamilyProfile.data["env_kills"] = int(FamilyProfile.data.get("env_kills", 0)) + 1


func _draw() -> void:
	match kind:
		"manhole":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 18.0, Color(0.05, 0.04, 0.05))
			draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color(0.35, 0.36, 0.4), 2.0)
			draw_set_transform(Vector2(22, 4), 0.3, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 17.0, Color(0.28, 0.29, 0.32))
			for k in 4:
				draw_line(Vector2(-12, -8 + k * 5), Vector2(12, -8 + k * 5), Color(0.2, 0.2, 0.22), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for k in 3:
				var ph := fmod(_t * 0.5 + float(k) * 0.33, 1.0)
				draw_circle(Vector2(sin(_t + k) * 4.0, -ph * 40.0), 4.0 + ph * 8.0, Color(0.8, 0.82, 0.86, 0.18 * (1.0 - ph)))
		"wire":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, 34.0, Color(0.15, 0.2, 0.3, 0.55))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var pts := PackedVector2Array([Vector2(-60, -60), Vector2(-30, -20), Vector2(-8, -2), Vector2(10, 2), Vector2(26, -1)])
			draw_polyline(pts, Color(0.08, 0.08, 0.1), 2.0)
			if fmod(_t * 7.0, 1.0) < 0.3:
				var rng := RandomNumberGenerator.new()
				rng.seed = int(_t * 30.0)
				for k in 4:
					var a := Vector2(rng.randf_range(-30, 30), rng.randf_range(-8, 4))
					draw_line(Vector2(26, -1), a, Color(0.7, 0.85, 1.0, 0.9), 1.0)
				draw_circle(Vector2(26, -1), 3.0, Color(1, 1, 1, 0.9))
