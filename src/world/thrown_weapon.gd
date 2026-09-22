class_name ThrownWeapon
extends Area2D

## SoR4 throw-and-catch. Pipe/board/knife/envelope fly, then drop. Cans break.

var kind := "pipe"
var vel := Vector2(480, -80)
var thrower: Node
var bounced := false
var life := 1.35
var arm := 0.16
var caught := false
var _poly: Polygon2D


func _ready() -> void:
	add_to_group("thrown_weapons")
	collision_layer = 0
	collision_mask = 6
	monitoring = true
	monitorable = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32, 14)
	cs.shape = r
	add_child(cs)
	_poly = Polygon2D.new()
	match kind:
		"knife":
			_poly.color = Color(0.82, 0.84, 0.9)
			_poly.polygon = PackedVector2Array([Vector2(-16, -3), Vector2(16, 0), Vector2(-16, 3)])
		"board":
			_poly.color = Color(0.55, 0.38, 0.18)
			_poly.polygon = PackedVector2Array([Vector2(-24, -5), Vector2(24, -5), Vector2(24, 5), Vector2(-24, 5)])
		"can":
			_poly.color = Color(0.82, 0.22, 0.18)
			_poly.polygon = PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(8, 10), Vector2(-8, 10)])
		"envelope":
			_poly.color = Color(0.92, 0.9, 0.82)
			_poly.polygon = PackedVector2Array([Vector2(-14, -8), Vector2(14, -8), Vector2(14, 8), Vector2(-14, 8)])
		_:
			_poly.color = Color(0.45, 0.32, 0.2)
			_poly.polygon = PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(20, 4), Vector2(-20, 4)])
	add_child(_poly)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	Juice.play("res://assets/audio/throw.wav")


func _physics_process(delta: float) -> void:
	if caught:
		return
	arm = maxf(0.0, arm - delta)
	life -= delta
	vel.y += 920.0 * delta
	global_position += vel * delta
	if _poly:
		_poly.rotation = vel.angle()
	if global_position.y > 508.0:
		global_position.y = 508.0
		_land()
		return
	if life <= 0.0:
		_land()


func catch_by(f: Fighter) -> bool:
	if caught or not is_instance_valid(f):
		return false
	if f == thrower and arm > 0.0:
		return false
	caught = true
	f.equip_pickup(kind)
	FamilyProfile.mark_catch()
	Juice.shout(Copy.CATCH)
	Juice.catch_flash(global_position)
	VoBank.catch_vo(f.role)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(f.role, 24, "catch")
	queue_free()
	return true


func _on_body(b: Node) -> void:
	if caught:
		return
	if b is Fighter:
		return
	if b is Punk:
		if b == thrower and arm > 0.0:
			return
		var e: Punk = b
		var from: Node = thrower if is_instance_valid(thrower) else self
		e.take_hit("blade" if kind == "knife" else "heavy", from)
		Juice.sparks(global_position)
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood and blood.has_method("spray"):
			blood.spray(e.global_position, "throw", signf(vel.x))
		if _should_boomerang():
			_boomerang()
			return
		_land()


func _on_area(a: Area2D) -> void:
	if caught:
		return
	var victim: Node = a
	if a.get_parent() and a.get_parent().is_in_group("smashables"):
		victim = a.get_parent()
	if victim.is_in_group("smashables") and victim.has_method("take_hit"):
		var from: Node = thrower if is_instance_valid(thrower) else self
		victim.take_hit("heavy", from)
		if _should_boomerang():
			_boomerang()
			return
		_land()


func _should_boomerang() -> bool:
	if bounced or kind == "can":
		return false
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs != null and rs.has_method("has_card"):
		return bool(rs.call("has_card", "weapon_catch"))
	return false


func _boomerang() -> void:
	bounced = true
	life = 0.85
	arm = 0.0
	vel.x *= -0.85
	vel.y = -160.0
	thrower = null
	Juice.shout("COMEBACK")
	Juice.play("res://assets/audio/catch.wav" if ResourceLoader.exists("res://assets/audio/catch.wav") else "res://assets/audio/throw.wav")


func _land() -> void:
	if caught:
		return
	caught = true
	if kind == "can":
		Juice.sparks(global_position)
		Juice.play("res://assets/audio/pop.wav" if ResourceLoader.exists("res://assets/audio/pop.wav") else "res://assets/audio/hit_light.wav")
		queue_free()
		return
	var host := get_parent()
	if host:
		var wp := WeaponPickup.new()
		wp.kind = kind
		wp.global_position = global_position
		host.add_child(wp)
	queue_free()
