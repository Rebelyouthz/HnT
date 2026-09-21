class_name Fighter
extends CharacterBody2D

@export var role: String = "son"
@export var prefix: StringName = &"p1_"
@export var max_hp: int = 92
@export var speed: float = 210.0
@export var depth_speed: float = 110.0
@export var accent: Color = Palette.LEMON

const GRAV := 2400.0
const JUMP := -620.0
const COYOTE := 6
const BUFFER := 8
const STREET_MIN := 430.0
const STREET_MAX := 520.0

var hp: int
var facing := 1
var hop := 0.0
var hop_v := 0.0
var coyote := 0
var jump_buf := 0
var attack_cd := 0
var visual: Node2D
signal died
signal hit_landed(kind: String, global_pos: Vector2)


func _ready() -> void:
	hp = max_hp
	collision_layer = 2
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	_build_body()
	var cap := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14
	shape.height = 64
	cap.shape = shape
	cap.position = Vector2(0, -32)
	add_child(cap)


func _build_body() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	var outline := Palette.BRICK if role == "father" else Palette.LEMON
	_part(Vector2(-16, -72), Vector2(32, 14), outline) # headband
	_part(Vector2(-14, -60), Vector2(28, 18), Palette.TEXT.darkened(0.15)) # head
	_part(Vector2(-18, -42), Vector2(36, 28), accent) # torso
	_part(Vector2(-28, -38), Vector2(10, 24), accent.darkened(0.2)) # arm L
	_part(Vector2(18, -38), Vector2(10, 24), accent.darkened(0.2)) # arm R
	_part(Vector2(-16, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18)) # leg L
	_part(Vector2(4, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18)) # leg R


func _part(pos: Vector2, size: Vector2, color: Color) -> void:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		pos,
		pos + Vector2(size.x, 0),
		pos + size,
		pos + Vector2(0, size.y)
	])
	visual.add_child(p)


func _physics_process(delta: float) -> void:
	if attack_cd > 0:
		attack_cd -= 1
	if hop >= 0.0:
		coyote = COYOTE if coyote < COYOTE else coyote
	if coyote > 0:
		coyote -= 1
	if jump_buf > 0:
		jump_buf -= 1
	if _pressed("jump"):
		jump_buf = BUFFER

	var x := Input.get_axis(prefix + "left", prefix + "right")
	var y := Input.get_axis(prefix + "up", prefix + "down")
	velocity.x = x * speed
	if hop >= -1.0 and hop_v == 0.0:
		velocity.y = y * depth_speed
	else:
		velocity.y = 0.0
	if jump_buf > 0 and coyote > 0 and hop >= -1.0:
		hop_v = JUMP
		hop = -1.0
		jump_buf = 0
		coyote = 0
	if hop < 0.0 or hop_v != 0.0:
		hop_v += GRAV * delta
		hop += hop_v * delta
		if hop >= 0.0:
			hop = 0.0
			hop_v = 0.0
	visual.position.y = hop
	move_and_slide()
	global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	if absf(x) > 0.1:
		facing = 1 if x > 0.0 else -1
		visual.scale.x = float(facing)

	if attack_cd == 0 and _just("light"):
		_attack("light")
	elif attack_cd == 0 and _just("heavy"):
		_attack("heavy")


func _pressed(action: String) -> bool:
	return Input.is_action_pressed(StringName(str(prefix) + action))


func _just(action: String) -> bool:
	return Input.is_action_just_pressed(StringName(str(prefix) + action))


func _attack(kind: String) -> void:
	attack_cd = 14 if kind == "light" else 22
	var box := Area2D.new()
	box.collision_layer = 8
	box.collision_mask = 4
	box.monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(46 if kind == "light" else 62, 40)
	cs.shape = r
	box.position = Vector2(36 * facing, -34 + hop)
	box.add_child(cs)
	add_child(box)
	var hits: Array[Node] = []
	box.area_entered.connect(func(a: Area2D) -> void:
		if a in hits:
			return
		hits.append(a)
		var victim := a.get_parent()
		if victim and victim.has_method("take_hit"):
			victim.take_hit(kind, self)
			hit_landed.emit(kind, a.global_position)
	)
	box.body_entered.connect(func(b: Node) -> void:
		if b in hits:
			return
		hits.append(b)
		if b.has_method("take_hit"):
			b.take_hit(kind, self)
			hit_landed.emit(kind, b.global_position)
	)
	await get_tree().create_timer(0.12 if kind == "light" else 0.18).timeout
	if is_instance_valid(box):
		box.queue_free()


func take_hit(kind: String, _from: Node) -> void:
	var dmg := 6 if kind == "light" else 16
	hp = maxi(0, hp - dmg)
	Juice.flash_red(visual, 2 if kind == "light" else 4)
	if kind == "light":
		Juice.hitstop(1)
		Juice.popup_number(global_position + Vector2(0, -80), str(dmg), Palette.TEXT)
		Juice.play("res://assets/audio/hit_light.wav")
	else:
		Juice.hitstop(4)
		Juice.pulse_shake(3.0)
		Juice.popup_number(global_position + Vector2(0, -80), str(dmg), Color(1.0, 0.55, 0.2))
		Juice.play("res://assets/audio/hit_heavy.wav")
	if hp <= 0:
		died.emit()
