class_name Punk
extends CharacterBody2D

var hp := 40
var visual: Node2D
signal died


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	visual = Node2D.new()
	add_child(visual)
	_part(Vector2(-16, -68), Vector2(32, 16), Color(0.75, 0.2, 0.55))
	_part(Vector2(-14, -52), Vector2(28, 20), Palette.TEXT.darkened(0.25))
	_part(Vector2(-18, -32), Vector2(36, 32), Color(0.25, 0.22, 0.3))
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


func _physics_process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var t: Node2D = players[0]
	var d := t.global_position.x - global_position.x
	velocity.x = clampf(d, -1.0, 1.0) * 40.0
	velocity.y = 0
	move_and_slide()
	global_position.y = clampf(global_position.y, 430.0, 520.0)


func take_hit(kind: String, from: Node) -> void:
	var dmg := 8 if kind == "light" else 22
	hp = maxi(0, hp - dmg)
	Juice.flash_red(visual, 2 if kind == "light" else 5)
	if kind == "light":
		Juice.hitstop(1)
		Juice.popup_number(global_position + Vector2(0, -80), str(dmg), Palette.TEXT)
		Juice.play("res://assets/audio/hit_light.wav")
		FamilyProfile.mark_light()
	else:
		Juice.hitstop(4)
		Juice.pulse_shake(3.0)
		Juice.popup_number(global_position + Vector2(0, -80), str(dmg), Color(1.0, 0.5, 0.15))
		Juice.play("res://assets/audio/hit_heavy.wav")
		FamilyProfile.mark_heavy()
	var dir := signf(global_position.x - from.global_position.x)
	global_position.x += dir * (8.0 if kind == "light" else 18.0)
	if hp <= 0:
		died.emit()
		queue_free()
