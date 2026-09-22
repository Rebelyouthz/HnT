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
const FALL_MUL := 1.65
const COYOTE := 6
const BUFFER := 8
const STREET_MIN := 430.0
const STREET_MAX := 520.0
const STEAM_MAX := 100.0
const JUMP_HEIGHT := (620.0 * 620.0) / (2.0 * 2400.0)

var hp: int
var steam: float = STEAM_MAX
var steam_lock := 0.0
var ammo: int = 3
var ammo_cd := 0.0
var facing := 1
var hop := 0.0
var hop_v := 0.0
var coyote := 0
var jump_buf := 0
var attack_cd := 0
var invuln := 0
var plane := "street"
var gliding := false
var vaulting := false
var sliding := false
var dashing := false
var web_incoming := false
var snap_ready := false
var downed := false
var armored := false
var charge_frames := 0
var dash_frames := 0
var slide_frames := 0
var wall_run := 0.0
var cape_guard := 0.0
var web_length := 160.0
var web_anchor: WebAnchor
var ladder: FireEscape
var bleed := 0.0
var revive_hold := 0.0
var web_line: Line2D
var visual: Node2D
var squash_root: Node2D
var cape: Polygon2D
var ears: Polygon2D
var blocking := false
var block_low := false
var pickup := ""
var bandage := 0
var extra_jump := 0
var buff_t := 0.0
var staple_ready := false
var guard: Node2D
var string_n := 0
var string_ttl := 0.0
var lights_clean := 0
var net_driven := false
var puppeted := false
var net_report := false
var snap_pos := Vector2.ZERO
var snap_hop := 0.0
var tape_t := 0.0
var grenades := 0
var _shadow: Polygon2D
var _slip: Polygon2D
var _breath := 0.0
var vs_mode := false
var magnet_r := 72.0
var pistol_shots := 0
var trick_boost := 1.0
var trick_t := 0.0
var stumble_t := 0.0
var ducking := false
var parkour_lock := 0.0
var stomp_n := 0
var stomp_cd := 0.0
var _foot_cd := 0.0
var _land_v := 0.0
var rolling := false
var van_seat := ""
var crawling := 0.0

signal died
signal hit_landed(kind: String, global_pos: Vector2)
signal downed_changed


func _ready() -> void:
	if FamilyProfile.has_cbt("thick_skin"):
		max_hp += 12
	hp = max_hp
	if FamilyProfile.has_cbt("bandage_pocket"):
		bandage = 1
	if FamilyProfile.has_cbt("long_commute"):
		magnet_r += 40.0
	collision_layer = 2
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	floor_snap_length = 8.0
	_build_body()
	_apply_locker()
	var bonus := FamilyProfile.gear_stat_bonus(role)
	max_hp += int(bonus.get("hp", 0))
	if FamilyProfile.has_cbt("wardrobe_stats"):
		max_hp += 4
	hp = max_hp
	speed += float(int(bonus.get("speed", 0))) * 1.6
	steam = mini(STEAM_MAX, steam + float(int(bonus.get("steam", 0))))
	if FamilyProfile.has_research("mag_plus"):
		if role == "son":
			ammo = 4
		else:
			ammo = 7
	if FamilyProfile.has_research("tape_wrap"):
		tape_t = 6.0
		armored = true
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.02, 0.02, 0.04, 0.45)
	_shadow.polygon = PackedVector2Array([
		Vector2(-20, 2), Vector2(20, 2), Vector2(12, 10), Vector2(-12, 10)
	])
	_shadow.z_index = -1
	add_child(_shadow)
	var cap := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14
	shape.height = 64
	cap.shape = shape
	cap.position = Vector2(0, -32)
	add_child(cap)
	web_line = Line2D.new()
	web_line.width = 2.0
	web_line.default_color = Color(0.85, 0.9, 1.0, 0.9)
	web_line.visible = false
	web_line.z_index = 8
	add_child(web_line)
	if role == "son":
		ammo = 3
	else:
		ammo = 6
	snap_pos = global_position
	hit_landed.connect(_on_hit_landed)


func _build_body() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	squash_root = Node2D.new()
	squash_root.name = "Squash"
	visual.add_child(squash_root)
	var outline := Palette.BRICK if role == "father" else Palette.LEMON
	_part(Vector2(-16, -72), Vector2(32, 14), outline)
	_part(Vector2(-14, -60), Vector2(28, 18), Palette.TEXT.darkened(0.15))
	if role == "son":
		ears = Polygon2D.new()
		ears.color = Color(0.12, 0.12, 0.14)
		ears.polygon = PackedVector2Array([
			Vector2(-14, -86), Vector2(-6, -72), Vector2(-18, -72),
			Vector2(14, -86), Vector2(18, -72), Vector2(6, -72)
		])
		ears.visible = false
		squash_root.add_child(ears)
		cape = Polygon2D.new()
		cape.color = Color(0.1, 0.1, 0.12, 0.92)
		cape.polygon = PackedVector2Array([
			Vector2(-8, -48), Vector2(8, -48), Vector2(18, -6), Vector2(-18, -6)
		])
		cape.visible = false
		squash_root.add_child(cape)
	_part(Vector2(-18, -42), Vector2(36, 28), accent)
	_part(Vector2(-28, -38), Vector2(10, 24), accent.darkened(0.2))
	_part(Vector2(18, -38), Vector2(10, 24), accent.darkened(0.2))
	_part(Vector2(-16, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18))
	_part(Vector2(4, -14), Vector2(12, 28), Color(0.15, 0.14, 0.18))


func _part(pos: Vector2, size: Vector2, color: Color) -> void:
	var outline_c := Palette.BRICK if role == "father" else Palette.LEMON
	var o := Polygon2D.new()
	o.color = outline_c
	var op := pos - Vector2(2, 2)
	var os := size + Vector2(4, 4)
	o.polygon = PackedVector2Array([
		op, op + Vector2(os.x, 0), op + os, op + Vector2(0, os.y)
	])
	squash_root.add_child(o)
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		pos,
		pos + Vector2(size.x, 0),
		pos + size,
		pos + Vector2(0, size.y)
	])
	squash_root.add_child(p)


func _apply_locker() -> void:
	var clothes := FamilyProfile.equipped_id(role, "clothes")
	var spec := GearBook.item(clothes)
	if not spec.is_empty():
		var tint: Variant = spec.get("tint", [])
		if typeof(tint) == TYPE_ARRAY and (tint as Array).size() >= 3:
			accent = Color(float(tint[0]), float(tint[1]), float(tint[2]))
	if (clothes == "night_tutor" or clothes == "void_cape") and cape:
		cape.visible = true
		cape.color = Color(0.07, 0.07, 0.1, 0.96)
		if ears:
			ears.visible = true
	if clothes == "pink_slip" or clothes == "eviction_polo":
		_slip = Polygon2D.new()
		_slip.color = Color(0.86, 0.32, 0.52, 0.92) if clothes == "pink_slip" else Palette.BRICK
		_slip.polygon = PackedVector2Array([
			Vector2(-12, -40), Vector2(12, -40), Vector2(12, -24), Vector2(-12, -24)
		])
		squash_root.add_child(_slip)
	var hat := FamilyProfile.equipped_id(role, "hat")
	if hat != "" and hat != "headband":
		var brim := Polygon2D.new()
		brim.color = Rarity.color(str(GearBook.item(hat).get("rarity", "common")))
		brim.polygon = PackedVector2Array([
			Vector2(-18, -78), Vector2(18, -78), Vector2(14, -70), Vector2(-14, -70)
		])
		squash_root.add_child(brim)
	var shoes := FamilyProfile.equipped_id(role, "shoes")
	if shoes == "gold_wingtips":
		var tip := Polygon2D.new()
		tip.color = Palette.EDGE
		tip.polygon = PackedVector2Array([
			Vector2(-16, 10), Vector2(16, 10), Vector2(12, 16), Vector2(-12, 16)
		])
		squash_root.add_child(tip)


func _physics_process(delta: float) -> void:
	_tick_meters(delta)
	if van_seat != "":
		return
	if crawling > 0.0:
		crawling -= delta
		velocity.x = float(facing) * 34.0
		velocity.y = 0.0
		hop = 10.0
		motion_mode = MOTION_MODE_FLOATING
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
		if crawling <= 0.0:
			hop = 0.0
		return
	if puppeted:
		if snap_pos != Vector2.ZERO:
			global_position = global_position.lerp(snap_pos, 0.4)
		visual.position.y = lerpf(visual.position.y, snap_hop, 0.4)
		if downed:
			_process_downed(delta)
		return
	if downed:
		_process_downed(delta)
		return
	if _pressed("jump"):
		jump_buf = BUFFER
	ladder = _find_ladder()
	if plane == "climb":
		_process_climb(delta)
		_combat()
		return
	if web_anchor != null:
		_process_web(delta)
		_combat()
		return
	if plane == "roof":
		_process_roof(delta)
	else:
		_process_street(delta)
	_combat()
	if cape:
		cape.visible = gliding or cape_guard > 0.0 or FamilyProfile.costume_for(role) == "night_tutor"
	if ears:
		ears.visible = gliding or cape_guard > 0.0 or FamilyProfile.costume_for(role) == "night_tutor"


func _tick_meters(delta: float) -> void:
	if attack_cd > 0:
		attack_cd -= 1
	if invuln > 0:
		invuln -= 1
	if coyote > 0:
		coyote -= 1
	if jump_buf > 0:
		jump_buf -= 1
	if dash_frames > 0:
		dash_frames -= 1
		if dash_frames == 0:
			dashing = false
	if slide_frames > 0:
		slide_frames -= 1
		if slide_frames == 0:
			sliding = false
	if wall_run > 0.0:
		wall_run -= delta
	if cape_guard > 0.0:
		cape_guard -= delta
	if web_incoming:
		web_incoming = absf(velocity.x) > 220.0
	if ammo_cd > 0.0:
		ammo_cd -= delta
		if ammo_cd <= 0.0:
			var cap := 3 if role == "son" else 6
			if FamilyProfile.has_research("mag_plus"):
				cap += 1
			if ammo < cap:
				ammo += 1
				ammo_cd = 2.4 if ammo < cap else 0.0
	if steam_lock > 0.0:
		steam_lock -= delta
	else:
		var regen := 22.0
		if FamilyProfile.has_cbt("second_lungs"):
			regen *= 1.15
		steam = minf(STEAM_MAX, steam + regen * delta)
	blocking = _pressed("block") and steam > 2.0 and not downed
	if tape_t > 0.0:
		tape_t -= delta
		if tape_t <= 0.0:
			armored = charge_frames >= 18
	if trick_t > 0.0:
		trick_t -= delta
		if trick_t <= 0.0:
			trick_boost = 1.0
	if stumble_t > 0.0:
		stumble_t -= delta
	if parkour_lock > 0.0:
		parkour_lock -= delta
	if stomp_cd > 0.0:
		stomp_cd -= delta
		if stomp_cd <= 0.0:
			stomp_n = 0
	block_low = blocking and _stick().y > 0.4
	if blocking:
		steam = maxf(0.0, steam - 8.0 * delta)
		steam_lock = 0.15
	if buff_t > 0.0:
		buff_t -= delta
	if string_ttl > 0.0:
		string_ttl -= delta
		if string_ttl <= 0.0:
			string_n = 0
	_update_guard()
	armored = charge_frames >= 18 or tape_t > 0.0
	_update_web_line()
	_apply_lamp()
	_breath += delta * 6.0
	ducking = _street_grounded() and _stick().y > 0.55 and not dashing and not sliding
	if squash_root:
		if ducking:
			squash_root.scale.y = 0.62
			squash_root.position.y = 14.0
		elif _street_grounded() and attack_cd == 0 and not dashing and not sliding:
			squash_root.scale.y = 1.0
			squash_root.position.y = 1.6 * sin(_breath)
		else:
			squash_root.scale.y = 1.0
			squash_root.position.y = 0.0
		var hurt := clampf(1.0 - float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
		if hurt > 0.35:
			squash_root.modulate = squash_root.modulate.lerp(Color(0.85, 0.45, 0.4), hurt * 0.35)
	if _shadow:
		var air := absf(hop) if plane == "street" else maxf(0.0, -minf(velocity.y, 0.0))
		_shadow.scale.x = 1.1 - clampf(air / 200.0, 0.0, 0.5)
		_shadow.modulate.a = 0.7 - clampf(air / 240.0, 0.0, 0.5)


func _process_street(delta: float) -> void:
	motion_mode = MOTION_MODE_FLOATING
	gliding = false
	var stick := _stick()
	var x := stick.x
	var y := stick.y
	if dashing:
		velocity.x = float(facing) * 420.0
		velocity.y = 0.0
	elif sliding:
		velocity.x = float(facing) * 360.0
		velocity.y = 0.0
	else:
		var limp := 0.72 if hp <= int(float(max_hp) * 0.35) else 1.0
		var combo_spd := 1.0 + clampf(float(Juice.combo) * 0.008, 0.0, 0.14)
		if stumble_t > 0.0:
			limp *= 0.4
		velocity.x = x * speed * limp * trick_boost * combo_spd
		if _street_grounded():
			velocity.y = y * depth_speed * limp
		else:
			velocity.y = 0.0
	if _street_grounded():
		coyote = COYOTE
		_footsteps(delta, absf(velocity.x))
	if jump_buf > 0 and coyote > 0:
		hop_v = JUMP
		hop = -1.0
		jump_buf = 0
		coyote = 0
		KitSfx.hit(role, "jump")
	elif jump_buf > 0 and extra_jump > 0 and hop < -8.0:
		hop_v = JUMP * 0.8
		jump_buf = 0
		extra_jump -= 1
		KitSfx.hit(role, "jump")
	if hop < 0.0 or hop_v != 0.0:
		var g := GRAV
		if hop_v > 0.0:
			g *= FALL_MUL
		if role == "son" and hop < 0.0 and _pressed("jump") and hop_v > -80.0:
			gliding = true
			g = GRAV * 0.22
			hop_v = minf(hop_v, 90.0)
			velocity.x = move_toward(velocity.x, float(facing) * speed * 1.05, 600.0 * delta)
		if _released("jump") and hop_v < 0.0:
			hop_v *= 0.45
		hop_v += g * delta
		hop += hop_v * delta
		if hop >= 0.0:
			var fall := hop_v
			hop = 0.0
			hop_v = 0.0
			_on_land(fall)
	visual.position.y = hop
	move_and_slide()
	global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	_face(x)
	if ladder and y < -0.45:
		_start_climb()
	elif ladder and y > 0.45 and plane == "street":
		pass


func _process_roof(delta: float) -> void:
	motion_mode = MOTION_MODE_GROUNDED
	visual.position.y = 0.0
	var stick := _stick()
	var x := stick.x
	var y := stick.y
	if wall_run > 0.0:
		velocity = Vector2(float(facing) * 330.0, -50.0)
		move_and_slide()
		_face(x)
		return
	if not is_on_floor():
		var g := GRAV
		if velocity.y > 0.0:
			g *= FALL_MUL
		if role == "son" and _pressed("jump") and velocity.y > -90.0:
			gliding = true
			g = GRAV * 0.18
			velocity.y = minf(velocity.y, 10.0)
			velocity.x = move_toward(velocity.x, float(facing) * speed * 1.08, 700.0 * delta)
		else:
			gliding = false
		if _released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5
		velocity.y += g * delta
	else:
		gliding = false
		coyote = COYOTE
		if hop_v != 0.0:
			_on_land(absf(hop_v) if velocity.y >= 0.0 else 0.0)
		hop_v = 0.0
	if jump_buf > 0 and coyote > 0:
		velocity.y = JUMP
		jump_buf = 0
		coyote = 0
		KitSfx.hit(role, "jump")
	elif jump_buf > 0 and extra_jump > 0 and not is_on_floor():
		velocity.y = JUMP * 0.85
		jump_buf = 0
		extra_jump -= 1
		KitSfx.hit(role, "jump")
	if dashing:
		velocity.x = float(facing) * 400.0
	else:
		velocity.x = x * speed
	if is_on_wall() and jump_buf > 0 and role == "son":
		wall_run = 0.42
		jump_buf = 0
	move_and_slide()
	_face(x)
	if global_position.y >= STREET_MIN - 6.0:
		_enter_street()
		return
	if ladder and y > 0.4:
		_start_climb()
	_try_land_roof()


func _process_climb(delta: float) -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_mask = 0
	var y := _stick().y
	if absf(y) < 0.15:
		y = -1.0 if (ladder and global_position.y > ladder.top_y + 8.0) else 1.0
	velocity = Vector2.ZERO
	if ladder:
		global_position.x = move_toward(global_position.x, ladder.climb_x, 240.0 * delta)
		global_position.y += y * 190.0 * delta
		if global_position.y <= ladder.top_y + 2.0 and y < 0.0:
			global_position.y = ladder.top_y
			_enter_roof()
			return
		if global_position.y >= ladder.bottom_y - 2.0 and y > 0.0:
			global_position.y = clampf(ladder.bottom_y, STREET_MIN, STREET_MAX)
			_enter_street()
			return
	else:
		_enter_street()
	visual.position.y = 0.0
	_face(0.0)


func _process_web(delta: float) -> void:
	if web_anchor == null or not is_instance_valid(web_anchor):
		_release_web(false)
		return
	collision_mask = 1
	visual.position.y = 0.0
	var x := _stick().x
	velocity.y += GRAV * 0.62 * delta
	var to_me: Vector2 = global_position - web_anchor.global_position
	var dist := to_me.length()
	if dist > 4.0:
		var tangent := Vector2(-to_me.y, to_me.x).normalized()
		velocity += tangent * x * 280.0 * delta
		if dist > web_length:
			var n := to_me / dist
			global_position = web_anchor.global_position + n * web_length
			velocity -= n * velocity.dot(n)
	move_and_slide()
	if jump_buf > 0 or _just("special"):
		_release_web(true)
		jump_buf = 0
	_try_land_roof()
	if global_position.y >= STREET_MIN and plane != "street":
		_enter_street()
	_face(x)


func _process_downed(delta: float) -> void:
	velocity.x = _stick().x * 40.0
	velocity.y = 0.0
	if plane == "street":
		motion_mode = MOTION_MODE_FLOATING
		move_and_slide()
		global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	else:
		move_and_slide()
	if vs_mode:
		return
	bleed -= delta
	revive_hold = 0.0
	for n in get_tree().get_nodes_in_group("players"):
		if n == self or not (n is Fighter):
			continue
		var other: Fighter = n
		if other.downed:
			continue
		if other.global_position.distance_to(global_position) > 58.0:
			continue
		if other._pressed("snap"):
			revive_hold += delta
			if revive_hold >= 1.15:
				_revived()
			return
	if bleed <= 0.0:
		_life_lost()


func _combat() -> void:
	if parkour_lock > 0.0:
		return
	var y := _stick().y
	if snap_ready and (_just("light") or _just("snap")):
		return
	if attack_cd == 0 and _just("dash") and not dashing:
		if y > 0.45 and plane == "street":
			_slide()
		else:
			_dash()
	if _street_grounded() or (plane == "roof" and is_on_floor()):
		_try_vault()
	if _just("throw"):
		_throw()
	if _just("special"):
		if string_n >= 2:
			_attack("gut-punch", false)
			string_n = 0
			Juice.shout("STRING")
			return
		var air_mix := hop < -16.0 or (plane == "roof" and not is_on_floor())
		if air_mix:
			if not FamilyProfile.dojo_learned("air_mix"):
				Juice.shout("DOJO LOCK")
				return
			_attack("air-mix", false)
			return
		_special()
	if _just("shoot"):
		_shoot()
	var charge_need := 20
	if FamilyProfile.has_cbt("heavy_wrist"):
		charge_need = 16
	var airborne := hop < -16.0 or (plane == "roof" and not is_on_floor())
	if _pressed("heavy"):
		charge_frames += 1
		if charge_frames >= charge_need + 25:
			_attack("heavy", true)
	elif charge_frames > 0:
		if airborne and y > 0.35:
			_dive()
		elif airborne and y < -0.35:
			_attack("air-upper", false)
		elif airborne:
			_attack("jump-kick", false)
		elif y > 0.4 and _try_stomp():
			charge_frames = 0
		elif y < -0.35:
			if not FamilyProfile.dojo_learned("uppercut"):
				Juice.shout("DOJO LOCK")
				charge_frames = 0
			else:
				_attack("uppercut", false)
		elif string_n >= 2:
			if FamilyProfile.dojo_learned("roundhouse"):
				_attack("roundhouse", false)
			else:
				_attack("heavy", charge_frames >= charge_need)
		else:
			_attack("heavy", charge_frames >= charge_need)
	elif attack_cd == 0 and _just("light"):
		if airborne and y < -0.35:
			_attack("air-upper", false)
		elif airborne:
			_attack("jump-kick", false)
		else:
			_attack("light", false)


func _dash() -> void:
	if not _spend(18.0):
		return
	dashing = true
	dash_frames = 10
	invuln = 8
	var blitz := get_tree().get_first_node_in_group("run_state")
	if blitz and blitz.has_method("has_card") and blitz.has_card("family_blitz"):
		invuln = 12
		dash_frames = 12
	velocity.x = float(facing) * 420.0
	KitSfx.hit(role, "dash")


func _slide() -> void:
	if not _spend(18.0):
		return
	sliding = true
	slide_frames = 16
	invuln = 6
	dashing = false
	KitSfx.hit(role, "slide")
	_spawn_hit("slide", Vector2(52, 28), 0.22, Vector2(24 * facing, -12))
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("family_blitz"):
		_spawn_hit("slide", Vector2(64, 30), 0.18, Vector2(40 * facing, -10))


func _try_vault() -> void:
	if vaulting:
		return
	var x := _stick().x
	if absf(x) < 0.5:
		return
	for n in get_tree().get_nodes_in_group("vaults"):
		if n is VaultCrate and (n as VaultCrate).covers(global_position):
			vaulting = true
			invuln = 10
			(n as VaultCrate).smash()
			Juice.keep_combo()
			if plane == "street":
				hop_v = -420.0
				hop = -1.0
			else:
				velocity.y = -360.0
			velocity.x = signf(x) * 340.0
			get_tree().create_timer(0.26).timeout.connect(func() -> void:
				vaulting = false
			)
			return


func _special() -> void:
	if role == "father":
		if web_anchor != null:
			_release_web(true)
			return
		var a := WebAnchor.nearest_in_cone(global_position + Vector2(0, -40), facing, self)
		if a:
			_attach_web(a)
			return
		if not _spend(35.0):
			return
		_spawn_hit("special", Vector2(78, 44), 0.22, Vector2(44 * facing, -34))
		attack_cd = 22
	else:
		if not _spend(35.0):
			return
		cape_guard = 0.4
		_spawn_hit("special", Vector2(86, 52), 0.4, Vector2(36 * facing, -36))
		attack_cd = 18
		if cape:
			cape.visible = true


func _attack(kind: String, charged: bool) -> void:
	if attack_cd > 0 and kind == "heavy" and not charged:
		charge_frames = 0
		return
	if (kind == "heavy" or kind == "launcher") and charged and not _spend(12.0):
		charge_frames = 0
		return
	charge_frames = 0
	attack_cd = 14 if kind == "light" or kind == "jump-kick" else 24
	var size := Vector2(46, 40) if kind == "light" or kind == "jump-kick" else Vector2(66, 44)
	if kind == "light":
		string_n += 1
		string_ttl = 0.4
		lights_clean += 1
		var grade := HitGrade.of_lights(string_n)
		Juice.shout(HitGrade.shout(grade))
		if grade == "jab":
			KitSfx.hit(role, "jab")
		elif grade == "cross":
			KitSfx.hit(role, "cross")
		else:
			KitSfx.hit(role, "bam")
			VoBank.bam(role)
		if string_n >= 3:
			kind = "gut-punch"
			size = Vector2(54, 42)
			attack_cd = 12
	elif kind == "jump-kick":
		size = Vector2(50, 36)
	elif kind == "launcher":
		size = Vector2(72, 52)
		string_n = 0
	elif kind == "uppercut" or kind == "air-upper":
		size = Vector2(48, 70)
		attack_cd = 18
		if plane == "street":
			hop_v = -280.0 - 40.0 * float(FamilyProfile.dojo_rank("uppercut"))
			hop = -1.0
		Juice.shout("UPPERCUT")
	elif kind == "roundhouse":
		size = Vector2(86, 44)
		attack_cd = 18
		string_n = 0
		Juice.shout("ROUNDHOUSE")
	elif kind == "air-mix":
		size = Vector2(70, 56)
		attack_cd = 16
		Juice.shout("AIR MIX")
	if pickup == "pipe" or pickup == "board":
		size += Vector2(18, 6) if pickup == "pipe" else Vector2(24, 8)
	elif pickup == "knife":
		size += Vector2(10, 0)
		if kind == "light" or kind == "gut-punch":
			kind = "blade"
	elif pickup == "pistol" and (kind == "light" or kind == "gut-punch") and pistol_shots > 0:
		pistol_shots -= 1
		_fire_shot()
		if pistol_shots <= 0:
			pickup = ""
	if charged and kind == "heavy":
		size = Vector2(78, 50)
	if kind != "light" and kind != "gut-punch":
		KitSfx.hit(role, kind)
	var life := 0.12 if kind == "light" or kind == "jump-kick" or kind == "gut-punch" else 0.2
	_spawn_hit(kind, size, life, Vector2(36 * facing, -34 + hop))


func _dive() -> void:
	charge_frames = 0
	if attack_cd > 0:
		return
	attack_cd = 20
	if plane == "street":
		hop_v = 520.0
	else:
		velocity.y = 520.0
	_spawn_hit("dive", Vector2(58, 44), 0.24, Vector2(20 * facing, -18 + hop))


func _on_hit_landed(kind: String, _global_pos: Vector2) -> void:
	if kind == "light" or kind == "jump-kick" or kind == "gut-punch" or kind == "slide":
		attack_cd = mini(attack_cd, 7)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("steam_tax") and (kind == "heavy" or kind == "launcher"):
		steam = minf(STEAM_MAX, steam + 8.0)


func _shoot() -> void:
	if grenades > 0 and _stick().y < -0.35:
		grenades -= 1
		attack_cd = 16
		_spawn_hit("finish", Vector2(90, 70), 0.2, Vector2(50 * facing, -30))
		Juice.kill_burst(global_position + Vector2(float(facing) * 40.0, -20.0), "finish")
		Juice.shout("BOUNDARY")
		Juice.pulse_shake(7.0)
		return
	if ammo <= 0 or attack_cd > 0:
		return
	ammo -= 1
	ammo_cd = 2.4
	attack_cd = 12
	_fire_shot()
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("tutoring") and lights_clean > 0 and lights_clean % 8 == 0:
		_fire_shot(Vector2(0, -12))
		Juice.shout("TUTORING")


func _fire_shot(extra := Vector2.ZERO) -> void:
	var id := "pistol" if pickup == "pistol" else ("batwing" if role == "son" else "snare")
	var spec := WeaponBook.spec(id)
	var shot := KitShot.new()
	shot.kind = str(spec.get("kind", "shuriken" if role == "son" else "snare"))
	shot.caliber = str(spec.get("caliber", ""))
	shot.ricochet_left = 1 if role == "son" else 0
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("ricochet_policy") and role == "son":
		shot.ricochet_left += 1
	shot.owner_role = role
	shot.hollow = FamilyProfile.has_research("hollow")
	shot.quiet = FamilyProfile.has_research("silencer")
	var spd := float(spec.get("speed", 520.0 if role == "son" else 380.0))
	shot.vel = Vector2(float(facing) * spd, 0.0)
	shot.global_position = global_position + Vector2(float(facing) * 28.0, -42.0 + hop) + extra
	var recoil := float(spec.get("recoil", 6))
	if FamilyProfile.has_research("recoil_pad"):
		recoil = maxf(1.0, recoil - 2.0)
	velocity.x -= float(facing) * recoil * 8.0
	KitSfx.gun(id, role)
	Juice.muzzle(shot.global_position, facing, shot.caliber)
	get_parent().add_child(shot)


func _spawn_hit(kind: String, size: Vector2, life: float, offset: Vector2) -> void:
	var box := Area2D.new()
	box.collision_layer = 8
	box.collision_mask = 6 if vs_mode else 4
	box.monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	box.position = offset
	box.add_child(cs)
	add_child(box)
	var hits: Array[Node] = []
	var land := func(node: Node) -> void:
		if node in hits:
			return
		hits.append(node)
		var victim: Node = node
		if node is Area2D:
			victim = (node as Area2D).get_parent()
		if victim == self:
			return
		if victim is Fighter and not vs_mode:
			return
		if victim and victim.has_method("take_hit"):
			var hit_kind := kind
			if web_incoming:
				hit_kind = "web-slam"
			victim.take_hit(hit_kind, self)
			hit_landed.emit(hit_kind, (node as Node2D).global_position)
	box.area_entered.connect(func(a: Area2D) -> void:
		land.call(a)
	)
	box.body_entered.connect(func(b: Node) -> void:
		land.call(b)
	)
	await get_tree().create_timer(life).timeout
	if is_instance_valid(box):
		box.queue_free()


func take_hit(kind: String, from: Node) -> void:
	if downed or invuln > 0:
		return
	if blocking and kind != "throw" and kind != "snap":
		var chip := maxi(1, int(round(6 * 0.1)))
		if kind == "heavy":
			chip = 2
		steam = maxf(0.0, steam - 12.0)
		hp = maxi(0, hp - chip)
		Juice.play("res://assets/audio/block.wav")
		Juice.flash_red(visual, 1)
		if steam <= 0.0:
			blocking = false
			invuln = 0
		else:
			return
		if hp <= 0:
			_go_down()
			return
	if armored and kind == "light":
		Juice.flash_red(visual, 1)
		return
	if web_anchor:
		_release_web(false)
	if gliding:
		gliding = false
		hop_v = 280.0
		velocity.y = 280.0
	var dmg := 6
	if kind == "heavy":
		dmg = 16
	elif kind == "snap" or kind == "special":
		dmg = 18
	if buff_t > 0.0:
		dmg = int(round(float(dmg) * 0.85))
	hp = maxi(0, hp - dmg)
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("family_discount"):
		Juice.keep_combo()
	else:
		Juice.break_combo()
	if kind == "light":
		Juice.flash_red(visual, 2)
		Juice.hitstop(1)
		Juice.play("res://assets/audio/hit_light.wav")
		lights_clean = 0
	else:
		Juice.flash_white_red(visual)
		Juice.hitstop(4)
		Juice.pulse_shake(3.0)
		Juice.play("res://assets/audio/hit_heavy.wav")
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		global_position.x += dir * (6.0 if kind == "light" else 16.0)
	if hp <= int(round(float(max_hp) * 0.3)) and bandage > 0:
		bandage -= 1
		hp = mini(max_hp, hp + int(round(float(max_hp) * 0.3)))
		Juice.shout("BANDAGE")
	if hp <= 0:
		_go_down()


func _go_down() -> void:
	downed = true
	hp = 0
	bleed = 12.0
	var ally := false
	for n in get_tree().get_nodes_in_group("players"):
		if n != self and n is Fighter and not (n as Fighter).downed:
			ally = true
	if not ally:
		bleed = 0.85
	web_anchor = null
	died.emit()
	downed_changed.emit()


func _revived() -> void:
	downed = false
	hp = int(round(float(max_hp) * 0.4))
	bleed = 0.0
	invuln = 40
	Juice.shout("GROUNDED")
	Juice.pulse_shake(10.0)
	Juice.freeze_frames(6)
	Juice.hitstop(10)
	Juice.play("res://assets/audio/slap.wav")
	if ResourceLoader.exists("res://assets/audio/vo_grounded.wav"):
		Mixer.play_vo("res://assets/audio/vo_grounded.wav")
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("double_slap"):
		hp = mini(max_hp, hp + int(round(float(max_hp) * 0.2)))
		buff_t = 2.0
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and n != self:
				(n as Fighter).hp = mini((n as Fighter).max_hp, (n as Fighter).hp + int(round(float((n as Fighter).max_hp) * 0.2)))
				(n as Fighter).buff_t = 2.0
	downed_changed.emit()


func _life_lost() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("spend_life"):
		rs.spend_life()
		if rs.failed:
			return
		global_position = rs.checkpoint
	downed = false
	hp = int(round(float(max_hp) * 0.6))
	_enter_street()
	downed_changed.emit()


func _attach_web(a: WebAnchor) -> void:
	web_anchor = a
	web_length = clampf(global_position.distance_to(a.global_position), WebAnchor.MIN_LEN, WebAnchor.MAX_LEN)
	plane = "air"
	motion_mode = MOTION_MODE_FLOATING
	hop = 0.0
	hop_v = 0.0
	web_line.visible = true
	Juice.play("res://assets/audio/web.wav")


func _release_web(sling: bool) -> void:
	if sling:
		velocity *= 1.35
		web_incoming = absf(velocity.x) + absf(velocity.y) > 280.0
		invuln = 8
	web_anchor = null
	web_line.visible = false
	if global_position.y < STREET_MIN - 20.0:
		plane = "roof"
		motion_mode = MOTION_MODE_GROUNDED
	else:
		_enter_street()


func _update_web_line() -> void:
	if web_anchor == null or not is_instance_valid(web_anchor):
		if web_line:
			web_line.visible = false
		return
	web_line.visible = true
	var from := to_local(web_anchor.global_position)
	var to := Vector2(0, -40)
	var pts := PackedVector2Array()
	for i in 8:
		var t := float(i) / 7.0
		var p := from.lerp(to, t)
		p.y += sin(t * PI) * 10.0
		pts.append(p)
	web_line.points = pts


func _start_climb() -> void:
	if ladder == null:
		return
	plane = "climb"
	hop = 0.0
	hop_v = 0.0
	web_anchor = null
	collision_mask = 0


func _enter_roof() -> void:
	plane = "roof"
	collision_mask = 1
	motion_mode = MOTION_MODE_GROUNDED
	hop = 0.0
	hop_v = 0.0
	visual.position.y = 0.0
	velocity.y = 0.0
	web_anchor = null


func _enter_street() -> void:
	plane = "street"
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	visual.position.y = hop
	global_position.y = clampf(global_position.y, STREET_MIN, STREET_MAX)
	web_anchor = null


func _try_land_roof() -> void:
	for n in get_tree().get_nodes_in_group("roof_solids"):
		if not n.has_meta("rect"):
			continue
		var r: Rect2 = n.get_meta("rect")
		if global_position.x < r.position.x or global_position.x > r.end.x:
			continue
		if global_position.y >= r.position.y - 10.0 and global_position.y <= r.position.y + 20.0:
			if velocity.y >= -40.0:
				global_position.y = r.position.y
				_enter_roof()
				return


func _find_ladder() -> FireEscape:
	for n in get_tree().get_nodes_in_group("ladders"):
		if n is FireEscape and (n as FireEscape).covers(global_position):
			return n
	return null


func stumble() -> void:
	stumble_t = 0.55
	trick_boost = 0.85
	trick_t = 0.55
	KitSfx.foot(role, 0.2, true)
	Juice.squash(squash_root, facing)
	Juice.shout("STUMBLE")


func _on_land(fall: float) -> void:
	Juice.squash(squash_root, facing)
	Juice.land_puff(global_position)
	rolling = false
	if fall < 280.0:
		KitSfx.hit(role, "land")
		return
	var want_roll := _stick().y > 0.25 or _just("dash") or FamilyProfile.dojo_learned("land_roll")
	if want_roll:
		rolling = true
		trick_boost = 1.08 + 0.02 * float(FamilyProfile.dojo_rank("land_roll"))
		trick_t = 1.2
		slide_frames = 10
		sliding = true
		Juice.shout("LANDING ROLL")
		KitSfx.hit(role, "dash")
		Juice.toast("reward", "LANDING ROLL", "+SPEED  ·  VECTOR+")
		return
	KitSfx.foot(role, 1.0, true)
	stumble()
	if fall > 620.0:
		take_hit("light", self)


func _footsteps(delta: float, spd: float) -> void:
	if hop < -2.0 or not _street_grounded():
		return
	if spd < 28.0:
		_foot_cd = 0.0
		return
	_foot_cd -= delta
	if _foot_cd > 0.0:
		return
	_foot_cd = clampf(0.34 - spd / 900.0, 0.14, 0.34)
	KitSfx.foot(role, clampf(spd / 280.0, 0.2, 1.2), stumble_t > 0.0)


func _try_stomp() -> bool:
	if not FamilyProfile.dojo_learned("stomp_finish"):
		Juice.shout("DOJO LOCK")
		return false
	if attack_cd > 0:
		return false
	var best: Punk = null
	var best_d := 72.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var p: Punk = n
		if not p.crush:
			continue
		var d := global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return false
	stomp_n = mini(stomp_n + 1, 3)
	stomp_cd = 1.1
	attack_cd = 16
	var kind := "stomp%d" % stomp_n
	_spawn_hit(kind, Vector2(52, 36), 0.18, Vector2(8 * facing, 8))
	KitSfx.hit(role, kind)
	Juice.shout("STOMP %d" % stomp_n)
	if stomp_n >= 3:
		FamilyProfile.mark_stomp()
		Juice.unlock_logo("FACE STOMP", "Smash. Pop. Splash. Brain on three.", "FINISHER  ·  STOMP 3")
		stomp_n = 0
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_points"):
			rs.add_points(role, 80, "stomp")
	return true


func _street_grounded() -> bool:
	return hop >= -1.0 and hop_v == 0.0


func _face(x: float) -> void:
	if absf(x) > 0.1:
		facing = 1 if x > 0.0 else -1
		visual.scale.x = float(facing)


func _spend(n: float) -> bool:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("has_card") and rs.has_card("steam_tax") and n <= 12.0:
		return true
	if steam < n:
		return false
	steam -= n
	steam_lock = 0.4
	return true


func _pressed(action: String) -> bool:
	if net_driven:
		return NetSession.held(action)
	return Input.is_action_pressed(StringName(str(prefix) + action))


func _just(action: String) -> bool:
	if net_driven:
		return NetSession.tapped(action)
	return Input.is_action_just_pressed(StringName(str(prefix) + action))


func _released(action: String) -> bool:
	if net_driven:
		return NetSession.released(action)
	return Input.is_action_just_released(StringName(str(prefix) + action))


func _stick() -> Vector2:
	if net_driven:
		return NetSession.stick
	return PadRouter.stick(prefix)


func _throw() -> void:
	if attack_cd > 0:
		return
	attack_cd = 18
	Juice.play("res://assets/audio/throw.wav")
	if vs_mode:
		for n in get_tree().get_nodes_in_group("players"):
			if n == self or not (n is Fighter):
				continue
			var e: Fighter = n
			var dx := e.global_position.x - global_position.x
			if signf(dx) != float(facing) and absf(dx) > 8.0:
				continue
			if absf(dx) > 54.0 or absf(e.global_position.y - global_position.y) > 50.0:
				continue
			e.take_hit("throw", self)
			e.global_position.x += float(facing) * 86.0
			Juice.shout("DISARMED")
			return
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e: Punk = n
		var dx := e.global_position.x - global_position.x
		if signf(dx) != float(facing) and absf(dx) > 8.0:
			continue
		if absf(dx) > 54.0 or absf(e.global_position.y - global_position.y) > 50.0:
			continue
		if FamilyProfile.dojo_learned("grab_slam") and e.crush:
			e.take_hit("finish", self)
			Juice.shout("GRAB SLAM")
			KitSfx.hit(role, "heavy")
		else:
			e.take_hit("throw", self)
		e.global_position.x += float(facing) * 86.0
		Juice.shout("DISARMED")
		return


func equip_pickup(kind: String) -> void:
	pickup = kind
	if kind == "pistol":
		pistol_shots = 6
		ammo = maxi(ammo, 3)
	Juice.shout(kind.to_upper())


func _update_guard() -> void:
	if guard == null:
		guard = Polygon2D.new()
		guard.color = Color(0.85, 0.9, 1.0, 0.0)
		guard.polygon = PackedVector2Array([
			Vector2(10, -70), Vector2(28, -40), Vector2(22, -8), Vector2(8, -12)
		])
		visual.add_child(guard)
	guard.modulate.a = 0.85 if blocking else 0.0
	guard.scale.y = 0.55 if block_low else 1.0


func _apply_lamp() -> void:
	if squash_root == null:
		return
	var rig := get_tree().get_first_node_in_group("light_rig")
	if rig and rig.has_method("tint_at"):
		squash_root.modulate = rig.tint_at(global_position)
