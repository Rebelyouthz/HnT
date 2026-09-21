class_name Punk
extends CharacterBody2D

@export var hp := 40
@export var title := "Bag Snatch"
@export var home := "street"
@export var patrol_min := 0.0
@export var patrol_max := 0.0
@export var speed := 42.0

var facing := -1
var snared := 0.0
var visual: Node2D
signal died


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	visual = Node2D.new()
	add_child(visual)
	var band := Color(0.75, 0.2, 0.55) if home == "street" else Color(0.18, 0.18, 0.22)
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


func _part(pos: Vector2, size: Vector2, color: Color) -> void:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)
	])
	visual.add_child(p)


func _physics_process(delta: float) -> void:
	if snared > 0.0:
		snared -= delta
		velocity = Vector2.ZERO
		move_and_slide()
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
		velocity.x = clampf(d, -1.0, 1.0) * speed
	velocity.y = 0
	move_and_slide()
	if home == "street":
		global_position.y = clampf(global_position.y, 430.0, 520.0)
	else:
		if patrol_max > patrol_min:
			global_position.x = clampf(global_position.x, patrol_min, patrol_max)
		global_position.y = 248.0


func take_hit(kind: String, from: Node) -> void:
	var dmg := 8
	if kind == "heavy":
		dmg = 22
	elif kind == "snap":
		dmg = 48
	elif kind == "special":
		dmg = 18
	elif kind == "web-slam":
		dmg = 28
	elif kind == "snare":
		dmg = 4
		snared = 1.1
	hp = maxi(0, hp - dmg)
	if kind == "light":
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
		else:
			Juice.hitstop(4)
			Juice.pulse_shake(3.0)
		Juice.play("res://assets/audio/hit_heavy.wav")
		FamilyProfile.mark_heavy()
		if kind != "snap":
			Juice.register_hit(kind, global_position, dmg)
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		global_position.x += dir * (8.0 if kind == "light" else 20.0)
	if hp <= 0:
		if kind != "light" and kind != "snap":
			Juice.kill_burst(global_position, kind)
		died.emit()
		queue_free()
