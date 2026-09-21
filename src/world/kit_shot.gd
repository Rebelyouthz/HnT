class_name KitShot
extends Area2D

var vel := Vector2.ZERO
var kind := "shuriken"
var ricochet_left := 0
var life := 1.4
var owner_role := "son"


func _ready() -> void:
	collision_layer = 8
	collision_mask = 5
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	cs.shape = c
	add_child(cs)
	var blob := Polygon2D.new()
	if kind == "shuriken":
		blob.color = Palette.LEMON
		blob.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)
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
	if b is Fighter and owner_role == "enemy":
		(b as Fighter).take_hit("light", self)
		queue_free()
		return
	if b.is_in_group("metal") and ricochet_left > 0:
		vel.x *= -1.0
		vel.y *= 0.4
		ricochet_left -= 1
		return
	queue_free()


func _on_area(a: Area2D) -> void:
	var p := a.get_parent()
	if p is Punk:
		_hit_punk(p as Punk)


func _hit_punk(p: Punk) -> void:
	if kind == "snare":
		p.take_hit("snare", self)
	else:
		p.take_hit("light", self)
	queue_free()
