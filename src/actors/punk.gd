class_name Punk
extends CharacterBody2D

@export var hp := 40
@export var max_hp := 40
@export var title := "Bag Snatch"
@export var home := "street"
@export var patrol_min := 0.0
@export var patrol_max := 0.0
@export var speed := 42.0
@export var cop := false
@export var armored := false

var facing := -1
var snared := 0.0
var visual: Node2D
var telegraph := 0.0
var recover := 0.0
var crush := false
var staples := 0
var staple_cd := 0.0
var guarding := false
var guard_low := false
var _alert := Color.WHITE
var _bob := 0.0
signal died
signal finish_ready


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	max_hp = hp
	visual = Node2D.new()
	add_child(visual)
	var band := Color(0.22, 0.28, 0.55) if cop else (Color(0.75, 0.2, 0.55) if home == "street" else Color(0.18, 0.18, 0.22))
	_part(Vector2(-18, -70), Vector2(36, 18), band.lightened(0.15))
	_part(Vector2(-16, -68), Vector2(32, 16), band)
	_part(Vector2(-14, -52), Vector2(28, 20), Palette.TEXT.darkened(0.25))
	_part(Vector2(-18, -32), Vector2(36, 32), Color(0.25, 0.22, 0.3) if home == "street" else Color(0.14, 0.14, 0.18))
	_part(Vector2(-14, 0), Vector2(12, 24), Color(0.12, 0.1, 0.14))
	_part(Vector2(2, 0), Vector2(12, 24), Color(0.12, 0.1, 0.14))
	var cap := CollisionShape2D.new()
	var sh := CapsuleShape2D.new()
	sh.radius = 14
	sh.height = 60
	cap.shape = sh
	cap.position = Vector2(0, -30)
	add_child(cap)
	var hurt := Area2D.new()
	hurt.name = "Hurt"
	hurt.collision_layer = 4
	hurt.collision_mask = 8
	var hc := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(28, 60)
	hc.shape = hr
	hc.position = Vector2(0, -30)
	hurt.add_child(hc)
	add_child(hurt)
	if title == "Drone":
		visual.modulate = Color(0.65, 0.75, 0.9)
	elif title == "Agent Lin":
		visual.modulate = Color(0.85, 0.8, 1.05)
	elif title == "Toll Bot":
		visual.modulate = Color(0.7, 0.75, 0.7)


func _part(pos: Vector2, size: Vector2, color: Color) -> void:
	var o := Polygon2D.new()
	o.color = Color(0.08, 0.07, 0.1)
	var op := pos - Vector2(2, 2)
	var os := size + Vector2(4, 4)
	o.polygon = PackedVector2Array([
		op, op + Vector2(os.x, 0), op + os, op + Vector2(0, os.y)
	])
	visual.add_child(o)
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)
	])
	visual.add_child(p)


func _physics_process(delta: float) -> void:
	if staple_cd > 0.0:
		staple_cd -= delta
	if staples > 0 and staple_cd <= 0.0:
		staples -= 1
		staple_cd = 0.4
		hp = maxi(0, hp - 2)
		Juice.flash_red(visual, 1)
		if hp <= 0:
			_die("blade", self)
			return
	if snared > 0.0:
		snared -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_mix_mod()
		return
	if recover > 0.0:
		recover -= delta
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		move_and_slide()
		_lane()
		_mix_mod()
		return
	if telegraph > 0.0:
		telegraph -= delta
		_alert = Color(1.0, 0.55, 0.2)
		velocity.x = 0
		move_and_slide()
		if telegraph <= 0.0:
			_alert = Color.WHITE
			_swing()
		_lane()
		_mix_mod()
		return
	var players := get_tree().get_nodes_in_group("players")
	var t: Node2D = null
	var best := 9999.0
	for n in players:
		if n is Fighter and not (n as Fighter).downed:
			var d: float = absf((n as Node2D).global_position.x - global_position.x)
			var same: bool = absf((n as Node2D).global_position.y - global_position.y) < 90.0
			if same and d < best:
				best = d
				t = n
	if t == null:
		velocity.x = 0
	else:
		var d := t.global_position.x - global_position.x
		facing = 1 if d > 0.0 else -1
		visual.scale.x = float(facing)
		if absf(d) < 46.0:
			if _maybe_guard(t as Fighter):
				velocity.x = 0
			else:
				_start_telegraph()
				velocity.x = 0
		elif title == "Roof Runner" and absf(d) > 90.0 and absf(d) < 260.0 and randf() < 0.012:
			_shuriken()
			velocity.x = 0
		else:
			velocity.x = clampf(d, -1.0, 1.0) * speed
	velocity.y = 0
	move_and_slide()
	_lane()
	_bob += delta * 4.8
	if visual:
		visual.position.y = 1.3 * sin(_bob)
	_mix_mod()


func _lane() -> void:
	if home == "air" or title == "Drone":
		global_position.y = clampf(global_position.y, 150.0, 360.0)
		if patrol_max > patrol_min:
			global_position.x = clampf(global_position.x, patrol_min, patrol_max)
		return
	if home == "street":
		global_position.y = clampf(global_position.y, 430.0, 520.0)
	else:
		if patrol_max > patrol_min:
			global_position.x = clampf(global_position.x, patrol_min, patrol_max)
		global_position.y = 248.0


func _maybe_guard(f: Fighter) -> bool:
	if telegraph > 0.0 or recover > 0.0:
		return false
	var chance := 0.0
	match App.difficulty:
		"open_house":
			chance = 0.06
		"finals":
			chance = 0.42
		_:
			chance = 0.2
	if not randf() < chance:
		return false
	guarding = true
	guard_low = f.sliding or PadRouter.stick(f.prefix).y > 0.45
	recover = 0.48
	_alert = Color(0.7, 0.78, 1.0)
	get_tree().create_timer(0.48).timeout.connect(func() -> void:
		if is_instance_valid(self):
			guarding = false
			_alert = Color.WHITE
	)
	return true


func _start_telegraph() -> void:
	match App.difficulty:
		"open_house":
			telegraph = 0.38
		"finals":
			telegraph = 0.16
		_:
			telegraph = 0.25


func _swing() -> void:
	recover = 0.42 if title != "Mohawk Bo" else 0.62
	var kind := "heavy" if title == "Mohawk Bo" else "light"
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			var f: Fighter = n
			if f.downed:
				continue
			if absf(f.global_position.x - global_position.x) < 50.0 and absf(f.global_position.y - global_position.y) < 70.0:
				f.take_hit(kind, self)


func _shuriken() -> void:
	recover = 0.7
	var shot := KitShot.new()
	shot.kind = "shuriken"
	shot.owner_role = "enemy"
	shot.vel = Vector2(float(facing) * 380.0, 0.0)
	shot.global_position = global_position + Vector2(float(facing) * 20.0, -40.0)
	get_parent().add_child(shot)


func _mix_mod() -> void:
	if visual == null:
		return
	var lamp := Color.WHITE
	var rig := get_tree().get_first_node_in_group("light_rig")
	if rig and rig.has_method("tint_at"):
		lamp = rig.tint_at(global_position)
	visual.modulate = _alert * lamp


func take_hit(kind: String, from: Node) -> void:
	if guarding and kind != "throw" and kind != "snap" and kind != "finish" and kind != "web-slam":
		var high_beats_low := guard_low and (kind == "jump-kick" or kind == "dive" or kind == "heavy" or kind == "launcher")
		var low_beats_high := (not guard_low) and (kind == "slide" or kind == "jump-kick")
		if not high_beats_low and not low_beats_high:
			Juice.play("res://assets/audio/block.wav")
			Juice.flash_red(visual, 1)
			guarding = false
			return
		guarding = false
	if armored and kind == "light":
		hp = maxi(0, hp - 2)
		Juice.flash_red(visual, 1)
		Juice.hitstop(1)
		if hp <= 0:
			_die(kind, from)
		return
	if kind == "throw" and title == "Mohawk Bo" and randf() < 0.5:
		Juice.shout("NO")
		Juice.flash_red(visual, 2)
		return
	var dmg := 8
	if kind == "heavy" or kind == "dive":
		dmg = 22
	elif kind == "launcher":
		dmg = 20
		snared = 0.3
		global_position.y -= 24.0
	elif kind == "snap":
		dmg = 48
	elif kind == "special":
		dmg = 18
	elif kind == "web-slam":
		dmg = 28
	elif kind == "finish" or kind == "throw":
		dmg = 36
	elif kind == "blade" or kind == "gut-punch":
		dmg = 12
	elif kind == "jump-kick":
		dmg = 11
	elif kind == "slide":
		dmg = 10
	elif kind == "snare":
		dmg = 4
		snared = 1.1
	if FamilyProfile.has_cbt("pocket_sand") and kind == "throw":
		dmg += 8
	if FamilyProfile.has_cbt("night_eyes") and kind == "snap":
		dmg += 12
	if from is Fighter and (from as Fighter).buff_t > 0.0:
		dmg = int(round(float(dmg) * 1.25))
	hp = maxi(0, hp - dmg)
	if kind == "light":
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("has_card") and rs.has_card("office_rage"):
			staples += 4
			staple_cd = 0.05
		Juice.flash_red(visual, 2)
		Juice.hitstop(1)
		Juice.play("res://assets/audio/hit_light.wav")
		FamilyProfile.mark_light()
		Juice.register_hit("light", global_position, dmg)
	else:
		Juice.flash_white_red(visual)
		if kind == "snap":
			Juice.pulse_shake(8.0)
		elif kind == "web-slam":
			Juice.pulse_shake(9.0)
			Juice.hitstop(7)
		elif kind == "finish":
			Juice.pulse_shake(12.0)
			Juice.hitstop(12)
		else:
			Juice.hitstop(4)
			Juice.pulse_shake(3.0)
		Juice.play("res://assets/audio/hit_heavy.wav")
		FamilyProfile.mark_heavy()
		if kind != "snap":
			Juice.register_hit(kind, global_position, dmg)
	if from is Fighter:
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("has_card") and rs.has_card("family_discount"):
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and n != from:
					(n as Fighter).steam = minf(Fighter.STEAM_MAX, (n as Fighter).steam + 12.0)
		if rs and rs.has_method("has_card") and rs.has_card("head_trampoline") and kind == "heavy" and not (from as Fighter)._street_grounded():
			(from as Fighter).extra_jump = 1
			global_position.y -= 80.0
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		global_position.x += dir * (8.0 if kind == "light" else 20.0)
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and kind != "light" and blood.has_method("spray"):
			blood.spray(global_position, kind, dir)
		if not crush and hp > 0 and hp <= int(round(float(max_hp) * 0.12)):
			crush = true
			finish_ready.emit()
			Juice.freeze_frames(8)
			Juice.shout("FINISH")
			if blood and blood.has_method("pulse"):
				blood.pulse(global_position)
	elif not crush and hp > 0 and hp <= int(round(float(max_hp) * 0.12)):
		crush = true
		finish_ready.emit()
		Juice.freeze_frames(8)
		Juice.shout("FINISH")
	if hp <= 0:
		_die(kind, from)


func _die(kind: String, from: Node) -> void:
	if kind != "light" and kind != "snap":
		Juice.kill_burst(global_position, kind)
		Juice.play("res://assets/audio/kill.wav")
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("pump"):
			var dir := -1.0
			if from is Node2D:
				dir = signf(global_position.x - (from as Node2D).global_position.x)
			blood.pump(global_position, dir)
	if kind == "web-slam":
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("has_card") and rs.has_card("pendulum_politics"):
			var a := WebAnchor.new()
			a.position = global_position + Vector2(0, -90)
			get_parent().add_child(a)
	if staples >= 1:
		Juice.kill_burst(global_position, "special")
	if cop:
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_wanted"):
			var drop := 1
			if kind == "snap" and rs.has_method("has_card") and rs.has_card("cop_out"):
				drop = -1
				Juice.shout("COPED OUT")
			rs.add_wanted(drop)
	_drops(from)
	died.emit()
	queue_free()


func _drops(from: Node) -> void:
	var host := get_parent()
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_xp"):
		rs.add_xp(18 if title == "Mohawk Bo" else 10)
	var orb := ScrapOrb.new()
	orb.amount = 5 if title == "Mohawk Bo" else 3
	orb.global_position = global_position + Vector2(0, -20)
	host.add_child(orb)
	var chance := 0.35
	if FamilyProfile.has_cbt("disarm_habit"):
		chance += 0.2
	if randf() < chance:
		var drop := WeaponPickup.new()
		drop.kind = "knife" if title == "Bag Snatch" else "pipe"
		drop.global_position = global_position + Vector2(12, -8)
		host.add_child(drop)
	if from is Fighter and rs and rs.has_method("has_card") and rs.has_card("head_trampoline"):
		pass
