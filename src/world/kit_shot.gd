class_name KitShot
extends Area2D

var vel := Vector2.ZERO
var kind := "shuriken"
var ricochet_left := 0
var life := 1.4
var owner_role := "son"
var caliber := ""
var hollow := false
var quiet := false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 7
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0 if kind != "pistol" else 5.0
	cs.shape = c
	add_child(cs)
	var blob := Polygon2D.new()
	if kind == "shuriken":
		blob.color = Palette.LEMON
		blob.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)
		])
	elif kind == "pistol":
		blob.color = Color(0.95, 0.82, 0.35)
		blob.polygon = PackedVector2Array([
			Vector2(-8, -3), Vector2(10, -2), Vector2(10, 2), Vector2(-8, 3)
		])
	else:
		blob.color = Color(0.85, 0.9, 1.0, 0.85)
		blob.polygon = PackedVector2Array([
			Vector2(-10, -4), Vector2(10, -4), Vector2(10, 4), Vector2(-10, 4)
		])
	add_child(blob)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)


func _physics_process(delta: float) -> void:
	position += vel * delta
	rotation += 14.0 * delta * signf(vel.x)
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(b: Node) -> void:
	if b is Punk and owner_role != "enemy":
		_hit_punk(b as Punk)
		return
	if b is Fighter:
		var f: Fighter = b
		if owner_role == "enemy":
			f.take_hit("light", self)
			queue_free()
			return
		if f.vs_mode and f.role != owner_role:
			f.take_hit("light", self)
			queue_free()
			return
		return
	if b.is_in_group("metal") and ricochet_left > 0:
		vel.x *= -1.0
		vel.y *= 0.4
		ricochet_left -= 1
		Juice.sparks(global_position)
		return
	Juice.sparks(global_position)
	Juice.hole(global_position)
	queue_free()


func _on_area(a: Area2D) -> void:
	var p := a.get_parent()
	if p is Punk:
		_hit_punk(p as Punk)


func _hit_punk(p: Punk) -> void:
	var hit := "snare" if kind == "snare" else "light"
	if kind == "pistol":
		hit = "heavy"
	if hollow and kind != "snare":
		hit = "heavy"
	p.take_hit(hit, self)
	Juice.sparks(p.global_position)
	Juice.hole(p.global_position + Vector2(0, -28))
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(p.global_position, "blade" if hollow else hit, signf(vel.x))
	if blood and blood.has_method("run_pool") and hit != "light":
		blood.run_pool(p.global_position, signf(vel.x))
	queue_free()
