class_name ClinicVan
extends Node2D

## Cyberpunk chase. Not mil trucks. One drives, one rails 360°. Solo hops seats.

signal dumped
signal hit_ramp

var map_w := 3800.0
var life := 16.0
var spd := 300.0
var ramp_x := 2480.0
var crashing := false
var driver: Fighter
var gunner: Fighter
var _solo := false
var _rail := false
var _shot_cd := 0.0
var _body: Polygon2D
var _rail_bar: Polygon2D
var _hint: Label
var _crash: ChaseCrash


static func start(host: Node, at: Vector2, son: Fighter, dad: Fighter, width: float) -> ClinicVan:
	var v := ClinicVan.new()
	v.global_position = at
	v.map_w = width
	v.driver = son if son else dad
	v.gunner = dad if v.driver == son else son
	v._solo = son == null or dad == null
	host.add_child(v)
	return v


func _ready() -> void:
	add_to_group("clinic_van")
	z_index = 5
	_body = Polygon2D.new()
	_body.color = Color(0.92, 0.82, 0.22, 0.95)
	_body.polygon = PackedVector2Array([
		Vector2(-70, -18), Vector2(78, -18), Vector2(86, 18), Vector2(-78, 18)
	])
	add_child(_body)
	var cab := Polygon2D.new()
	cab.color = Color(0.12, 0.14, 0.18, 0.92)
	cab.polygon = PackedVector2Array([
		Vector2(18, -42), Vector2(70, -42), Vector2(78, -18), Vector2(18, -18)
	])
	add_child(cab)
	_rail_bar = Polygon2D.new()
	_rail_bar.color = Palette.LEMON
	_rail_bar.polygon = PackedVector2Array([
		Vector2(-66, -28), Vector2(12, -28), Vector2(12, -22), Vector2(-66, -22)
	])
	add_child(_rail_bar)
	Blockout.add_glow(_rail_bar)
	_hint = Label.new()
	_hint.position = Vector2(-120, -78)
	_hint.size = Vector2(280, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_hint, 13, Palette.LEMON)
	add_child(_hint)
	_seat_hint()
	Juice.shout("CHASE")
	Juice.unlock_logo("CLINIC COURIER", "The Son drives. The Father rails 360°. Swap with SPECIAL. Not a mil truck.", "CHASE  ·  DRIVE + RAIL")
	VoBank.son_trick()
	if ResourceLoader.exists("res://assets/audio/music_chase.wav"):
		Mixer.play_music("res://assets/audio/music_chase.wav")
	elif ResourceLoader.exists("res://assets/audio/music_tension.wav"):
		Mixer.play_music("res://assets/audio/music_tension.wav")
	KitSfx.hit("son", "dash")
	Mixer.play_sfx("res://assets/audio/van.wav" if ResourceLoader.exists("res://assets/audio/van.wav") else "res://assets/audio/dash.wav", 0.86)


func _seat_hint() -> void:
	if _solo:
		_hint.text = "SOLO  ·  STICK STEERS  ·  SHOOT 360  ·  SPECIAL RAIL"
		return
	var d := FamilyProfile.son_name() if driver and driver.role == "son" else FamilyProfile.father_name()
	var g := FamilyProfile.father_name() if gunner and gunner.role == "father" else FamilyProfile.son_name()
	_hint.text = "%s DRIVES  ·  %s RAIL 360" % [d, g]


func _process(delta: float) -> void:
	if crashing:
		return
	life -= delta
	if _shot_cd > 0.0:
		_shot_cd -= delta
	if not crashing and (global_position.x >= ramp_x - 36.0 or life <= 0.0):
		_begin_crash()
		return
	var steer := 0.0
	var boost := 1.0
	if driver and is_instance_valid(driver):
		driver.van_seat = "cab" if not (_solo and _rail) else "rail"
		steer = driver._stick().x
		if driver._just("jump"):
			boost = 1.35
		if driver._just("special"):
			_swap_or_rail()
		driver.global_position = global_position + Vector2(36.0 if driver.van_seat == "cab" else -28.0, -8.0)
		driver.velocity = Vector2.ZERO
		driver.hop = -8.0
		driver.invuln = 4
	if gunner and is_instance_valid(gunner) and gunner != driver:
		gunner.van_seat = "rail"
		gunner.global_position = global_position + Vector2(-24.0, -18.0)
		gunner.velocity = Vector2.ZERO
		gunner.hop = -18.0
		gunner.invuln = 4
		if gunner._just("special"):
			_swap_or_rail()
		_try_shot(gunner, gunner._stick())
	elif _solo and driver:
		var aim := driver._stick()
		if absf(aim.y) > 0.25 or absf(aim.x) > 0.25:
			_try_shot(driver, aim)
		elif driver._just("shoot") or driver._pressed("shoot"):
			_try_shot(driver, Vector2(float(driver.facing), 0.0))
	global_position.x += spd * boost * delta
	global_position.y = clampf(global_position.y + steer * 90.0 * delta, 430.0, 520.0)
	global_position.x = clampf(global_position.x, 80.0, map_w - 80.0)
	_ram(delta)


func _swap_or_rail() -> void:
	if _solo:
		_rail = not _rail
		Juice.shout("RAIL" if _rail else "CAB")
		_seat_hint()
		return
	var a := driver
	driver = gunner
	gunner = a
	_seat_hint()
	Juice.shout("SWAP")


func _try_shot(who: Fighter, stick: Vector2) -> void:
	if _shot_cd > 0.0:
		return
	var want := who._just("shoot") or who._pressed("shoot")
	if not want and stick.length() < 0.55:
		return
	if not want:
		return
	_shot_cd = 0.16
	var dir := stick
	if dir.length() < 0.2:
		dir = Vector2(float(who.facing), 0.0)
	dir = dir.normalized()
	who.facing = 1 if dir.x >= 0.0 else -1
	var shot := KitShot.new()
	shot.kind = "pistol"
	shot.caliber = "9mm"
	shot.owner_role = who.role
	shot.vel = dir * 560.0
	shot.global_position = who.global_position + dir * 28.0 + Vector2(0, -20)
	get_parent().add_child(shot)
	KitSfx.gun("pistol", who.role)
	Juice.muzzle(shot.global_position, who.facing, "9mm")
	if who.ammo > 0:
		who.ammo -= 1


func _ram(_delta: float) -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk) or not is_instance_valid(n):
			continue
		var p: Punk = n
		if p.global_position.distance_to(global_position) > 70.0:
			continue
		p.take_hit("heavy", driver if driver else self)
		Juice.sparks(p.global_position)


func seat_keep() -> void:
	if driver and is_instance_valid(driver):
		driver.van_seat = "cab" if not (_solo and _rail) else "rail"
		driver.global_position = global_position + Vector2(36.0 if driver.van_seat == "cab" else -28.0, -8.0).rotated(rotation)
		driver.rotation = rotation
		driver.velocity = Vector2.ZERO
		driver.hop = -8.0
		driver.invuln = 8
	if gunner and is_instance_valid(gunner) and gunner != driver:
		gunner.van_seat = "rail"
		gunner.global_position = global_position + Vector2(-24.0, -18.0).rotated(rotation)
		gunner.rotation = rotation
		gunner.velocity = Vector2.ZERO
		gunner.hop = -18.0
		gunner.invuln = 8


func release_seats() -> void:
	for f in [driver, gunner]:
		if f and is_instance_valid(f):
			f.van_seat = ""
			f.rotation = 0.0
			f.hop = 0.0
			f.global_position.y = clampf(f.global_position.y, 430.0, 520.0)


func _begin_crash() -> void:
	if crashing:
		return
	crashing = true
	hit_ramp.emit()
	_crash = ChaseCrash.begin(get_parent(), self)
	_crash.finished.connect(func() -> void:
		dumped.emit()
	)


func _dump() -> void:
	release_seats()
	Juice.shout("UNDERPASS")
	dumped.emit()
	queue_free()
