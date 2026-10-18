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
var _shadow: Polygon2D
var _trail: Line2D


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
		"chain":
			_poly.color = Color(0.62, 0.64, 0.68)
			_poly.polygon = PackedVector2Array([Vector2(-28, -3), Vector2(28, -3), Vector2(26, 3), Vector2(-26, 3)])
		"crowbar":
			_poly.color = Color(0.42, 0.18, 0.14)
			_poly.polygon = PackedVector2Array([Vector2(-22, -5), Vector2(22, 5), Vector2(18, 6), Vector2(-22, 5)])
		"clipboard":
			_poly.color = Color(0.88, 0.82, 0.7)
			_poly.polygon = PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(12, 12), Vector2(-12, 12)])
		"stapler":
			_poly.color = Color(0.72, 0.22, 0.18)
			_poly.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(12, -8), Vector2(12, 6), Vector2(-10, 6)])
		"invoice_star":
			_poly.color = Palette.EDGE
			_poly.polygon = PackedVector2Array([Vector2(0, -14), Vector2(6, -4), Vector2(14, 0), Vector2(6, 4), Vector2(0, 14), Vector2(-6, 4), Vector2(-14, 0), Vector2(-6, -4)])
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
	if ResourceLoader.exists("res://assets/sprites/held/%s.png" % kind):
		var art := Sprite2D.new()
		art.texture = load("res://assets/sprites/held/%s.png" % kind)
		art.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE) * 1.25
		art.texture_filter = SpriteBook.world_filter()
		_poly.add_child(art)
		_poly.color.a = 0.0
	# A dark outline so it reads against the wet street.
	var rim := Line2D.new()
	var pts := _poly.polygon.duplicate()
	if pts.size() > 0:
		pts.append(pts[0])
	rim.points = pts
	rim.width = 1.5
	rim.default_color = Color(0, 0, 0, 0.0 if _poly.color.a == 0.0 else 0.7)
	_poly.add_child(rim)
	# Speed streak behind it and its shadow on the street below.
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.width = 5.0
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1.0, 0.95, 0.8, 0.45))
	_trail.gradient = g
	add_child(_trail)
	_shadow = Polygon2D.new()
	var sh := PackedVector2Array()
	for i in 14:
		var ang := TAU * float(i) / 14.0
		sh.append(Vector2(cos(ang) * 16.0, sin(ang) * 3.5))
	_shadow.polygon = sh
	_shadow.color = Color(0, 0, 0, 0.35)
	_shadow.z_index = -1
	add_child(_shadow)
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
		if kind in ["knife", "invoice_star"]:
			_poly.rotation = vel.angle() if kind == "knife" else _poly.rotation + 20.0 * delta
		else:
			# Blunt things tumble end over end.
			_poly.rotation += signf(vel.x) * 17.0 * delta
	if _shadow:
		var h := maxf(0.0, 508.0 - global_position.y)
		_shadow.position = Vector2(0, h)
		_shadow.scale = Vector2.ONE * clampf(1.0 - h / 220.0, 0.45, 1.0)
	if _trail:
		_trail.add_point(global_position)
		while _trail.get_point_count() > 7:
			_trail.remove_point(0)
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
		e.take_hit("blade" if kind in ["knife", "clipboard", "stapler", "invoice_star"] else "heavy", from)
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
		host.add_child.call_deferred(wp)
	queue_free()
