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
var _hurt_t := 0.0
var _anim: AnimatedSprite2D
var stomp_hits := 0
var _base_mod := Color.WHITE
var _brain: Polygon2D
var _walk := 42.0
var kit: Dictionary = {}
var plates := 0
var attack_style := "brawl"
var vehicle := ""
var armor_grade := "none"
var tier := "light"
var flung := false
var flung_dir := -1.0
var flung_t := 0.0
var flung_ground := false
var _grenade_cd := 0.0
var _last_zone := "head"
var _splat := 0.0
## Where the swing being wound up will land (high / mid / low), read by the
## fighter's guard. A marker over the head shows it during the wind-up.
var atk_height := ""
var _height_mark: Polygon2D
## The drawn swing for this wind-up (punch_high / punch_mid / kick_low) and
## the playback rate that puts its contact frame on the end of the wind-up.
var _swing_clip := ""
var _overkill := false
var _swing_rate := 1.0
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
	_walk = speed
	KitBook.apply(self)
	_dress_vehicle()
	if _wants_sprite():
		_mount_sprite()
	if title == "Drone":
		visual.modulate = Color(0.65, 0.75, 0.9)
	elif title == "Agent Lin":
		visual.modulate = Color(0.85, 0.8, 1.05)
	elif title == "Toll Bot":
		visual.modulate = Color(0.7, 0.75, 0.7)
	elif title == "Coping Imp":
		if not SpriteBook.has_who("coping_imp"):
			visual.modulate = Color(0.55, 0.9, 0.62)
	elif title == "Clipboard":
		if not SpriteBook.has_who("clipboard_flier"):
			visual.modulate = Color(0.85, 0.86, 0.7)
	elif title == "Invoice Clerk":
		visual.modulate = Color(0.7, 0.88, 0.72)
	elif title == "Pier Gull":
		visual.modulate = Color(0.78, 0.82, 0.8)
	elif title == "Chapel Usher":
		visual.modulate = Color(0.35, 0.42, 0.32)
	elif title == "Hay Pin":
		visual.modulate = Color(0.72, 0.78, 0.32)
	elif title == "Scarecrow Ken":
		visual.modulate = Color(0.62, 0.48, 0.22)
	elif title == "Barn Cop":
		visual.modulate = Color(0.45, 0.52, 0.28)
	elif title == "Tractor Kid":
		visual.modulate = Color(0.9, 0.85, 0.25)
	elif title == "Combine Brute":
		visual.modulate = Color(0.4, 0.32, 0.18)
	elif title == "Sleet Imp":
		visual.modulate = Color(0.75, 0.88, 0.95)
	elif title == "Ice Drone":
		visual.modulate = Color(0.7, 0.85, 1.0)
	elif title == "Plow Cop":
		visual.modulate = Color(0.55, 0.62, 0.72)
	elif title == "Frost Clerk":
		visual.modulate = Color(0.8, 0.9, 0.95)
	elif title == "Snowmobile":
		visual.modulate = Color(0.2, 0.22, 0.28)
	elif title == "Grid Kid":
		visual.modulate = Color(0.2, 0.85, 0.9)
	elif title == "Courier Bike":
		visual.modulate = Color(0.92, 0.82, 0.22)
	elif title == "Neon Scooter":
		visual.modulate = Color(0.95, 0.35, 0.75)
	elif title == "Grid Car":
		visual.modulate = Color(0.92, 0.82, 0.22)
	elif title == "Invoice Chopper":
		visual.modulate = Color(0.4, 0.45, 0.42)
	elif title == "Ledger Eel":
		visual.modulate = Color(0.2, 0.55, 0.42)
	elif title == "Brine Clerk":
		visual.modulate = Color(0.45, 0.7, 0.68)
	elif title == "Billboard Gull":
		visual.modulate = Color(0.95, 0.55, 0.25)
	elif title == "Vault Guard":
		visual.modulate = Color(0.28, 0.32, 0.3)
	elif title == "Cenote Elite":
		visual.modulate = Color(0.15, 0.45, 0.4)
	elif title == "Phone Ghost":
		visual.modulate = Color(0.55, 0.85, 1.0)
	elif title == "Dumpster King":
		visual.modulate = Color(0.28, 0.48, 0.22)
	elif title == "Billboard Witch":
		visual.modulate = Color(0.95, 0.45, 0.7)
	elif title == "Lottery Goon":
		visual.modulate = Color(0.85, 0.72, 0.2)
	elif title == "Fridge Imp":
		visual.modulate = Color(0.7, 0.88, 0.92)
	elif title == "Meter Maid":
		visual.modulate = Color(0.35, 0.55, 0.95)
	elif title == "Coupon Cart":
		visual.modulate = Color(0.85, 0.55, 0.22)
	elif title == "Ticket Skipper":
		visual.modulate = Color(0.55, 0.22, 0.28)
	_base_mod = visual.modulate


func _dress_vehicle() -> void:
	if vehicle == "":
		return
	var body := Polygon2D.new()
	match vehicle:
		"scooter":
			body.color = Color(0.85, 0.82, 0.2)
			body.polygon = PackedVector2Array([Vector2(-22, 4), Vector2(26, 4), Vector2(22, 16), Vector2(-18, 16)])
		"skate":
			body.color = Color(0.2, 0.7, 0.85)
			body.polygon = PackedVector2Array([Vector2(-24, 10), Vector2(24, 10), Vector2(20, 16), Vector2(-20, 16)])
		"moto":
			body.color = Color(0.18, 0.18, 0.22)
			body.polygon = PackedVector2Array([Vector2(-30, -8), Vector2(34, -4), Vector2(30, 16), Vector2(-26, 16)])
		"car":
			body.color = Color(0.92, 0.82, 0.22)
			body.polygon = PackedVector2Array([Vector2(-40, -8), Vector2(44, -8), Vector2(48, 16), Vector2(-44, 16)])
		"heli":
			body.color = Color(0.35, 0.4, 0.38)
			body.polygon = PackedVector2Array([Vector2(-36, -28), Vector2(36, -28), Vector2(28, -8), Vector2(-28, -8)])
		_:
			body.color = Color(0.5, 0.55, 0.6)
			body.polygon = PackedVector2Array([Vector2(-16, -20), Vector2(16, -20), Vector2(12, -6), Vector2(-12, -6)])
	visual.add_child(body)


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


func _sprite_who() -> String:
	if title == "Number 87" or title == "Skinwalker":
		return ""
	if vehicle != "":
		return ""
	if title == "Drone":
		return ""
	if home == "air" and title != "Clipboard":
		return ""
	if cop:
		return "cop"
	if title == "Collector Gant":
		return "gant"
	if title == "Shift Lead":
		return "shift_lead"
	if title == "Mohawk Bo":
		return "mohawk"
	if title == "Coping Imp":
		return "coping_imp"
	if title == "Valet":
		return "valet"
	if title == "Clamp King":
		return "clamp_king"
	if title == "Lot Hydra":
		return "lot_hydra"
	if title == "Clipboard":
		return "clipboard_flier"
	return "punk"


func _wants_sprite() -> bool:
	var who := _sprite_who()
	if who == "":
		return false
	if SpriteBook.has_who(who):
		return true
	return who != "punk" and SpriteBook.has_who("punk")


func _mount_sprite() -> void:
	SpriteBook.hide_polys(visual)
	var who := _sprite_who()
	if not SpriteBook.has_who(who):
		who = "punk"
	_anim = SpriteBook.make_anim(who)
	visual.add_child(_anim)


func _tick_sprite() -> void:
	if _anim == null or _anim.sprite_frames == null:
		return
	var clip := "idle"
	if telegraph <= 0.0 and recover <= 0.0:
		_swing_clip = ""
	if _hurt_t > 0.0:
		clip = "hurt"
	elif telegraph > 0.0 or (recover > 0.0 and _swing_clip != ""):
		clip = _swing_clip if _swing_clip != "" else "attack"
	elif recover > 0.0:
		clip = "idle"
	elif absf(velocity.x) > 8.0:
		clip = "walk"
	if not _anim.sprite_frames.has_animation(clip):
		clip = "attack" if clip.begins_with("punch") or clip == "kick_low" else clip
		if not _anim.sprite_frames.has_animation(clip):
			return
	if _anim.animation != clip:
		_anim.play(clip)
		_anim.speed_scale = _swing_rate if clip == _swing_clip else 1.0
	if clip == "walk":
		_anim.speed_scale = clampf(absf(velocity.x) / 42.0, 0.6, 1.6)


func _fling(delta: float) -> void:
	flung_t -= delta
	velocity.x = flung_dir * 400.0
	velocity.y = 0.0
	move_and_slide()
	_lane()
	for n in get_tree().get_nodes_in_group("smashables"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if global_position.distance_to((n as Node2D).global_position) > 56.0:
			continue
		if n.has_method("take_hit"):
			n.take_hit("throw", self)
		flung_dir *= -1.0
		flung_t = 0.22
		hp = maxi(1, hp - 8)
		Juice.shout(Copy.WALL_BOUNCE)
		Juice.play("res://assets/audio/wall_bounce.wav" if ResourceLoader.exists("res://assets/audio/wall_bounce.wav") else "res://assets/audio/hit_heavy.wav")
		FamilyProfile.mark_bounce()
		Juice.named_slowmo()
		break
	if flung_t <= 0.0:
		if not flung_ground:
			flung_ground = true
			flung_t = 0.16
			flung_dir *= -0.75
			hp = maxi(1, hp - 6)
			Juice.shout(Copy.GROUND_BOUNCE)
			Juice.named_slowmo()
			Juice.play("res://assets/audio/wall_bounce.wav" if ResourceLoader.exists("res://assets/audio/wall_bounce.wav") else "res://assets/audio/hit_heavy.wav")
			FamilyProfile.mark_bounce()
			return
		flung = false
		velocity.x = 0.0


func _physics_process(delta: float) -> void:
	if flung:
		_fling(delta)
		return
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
			if vehicle != "" and str(kit.get("attack", "")) == "ram":
				_ram_hit(t as Fighter)
				velocity.x = 0
			elif _maybe_guard(t as Fighter):
				velocity.x = 0
			else:
				_start_telegraph()
				velocity.x = 0
		elif str(kit.get("attack", "")) == "gun" and absf(d) > 90.0 and absf(d) < 300.0 and randf() < 0.016:
			_shuriken()
			velocity.x = 0
		elif str(kit.get("attack", "")) == "grenade" and absf(d) > 80.0 and absf(d) < 320.0 and randf() < 0.012:
			_lob()
			velocity.x = 0
		elif title == "Roof Runner" and absf(d) > 90.0 and absf(d) < 260.0 and randf() < 0.012:
			_shuriken()
			velocity.x = 0
		elif title in ["Invoice Clerk", "Coping Imp", "Badge Broker"] and absf(d) > 90.0 and absf(d) < 280.0 and randf() < 0.014:
			_shuriken()
			velocity.x = 0
		else:
			velocity.x = clampf(d, -1.0, 1.0) * speed
	velocity.y = 0
	move_and_slide()
	_lane()
	_canal()
	_bob += delta * 4.8
	if visual and _anim == null:
		visual.position.y = 1.3 * sin(_bob)
	if _hurt_t > 0.0:
		_hurt_t -= delta
	_mix_mod()
	_tick_sprite()


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


func _canal() -> void:
	if home == "air":
		return
	var act := get_tree().get_first_node_in_group("run_act")
	if act == null or not act.has_meta("canal"):
		return
	var c: Rect2 = act.get_meta("canal")
	if global_position.x <= c.position.x - 8.0 or global_position.x >= c.end.x + 8.0:
		return
	if global_position.x < c.position.x + c.size.x * 0.5:
		global_position.x = c.position.x - 28.0
		facing = -1
		velocity.x = -absf(speed)
	else:
		global_position.x = c.end.x + 28.0
		facing = 1
		velocity.x = absf(speed)


func _maybe_guard(f: Fighter) -> bool:
	if telegraph > 0.0 or recover > 0.0:
		return false
	var chance := float(kit.get("block", 0.2))
	match App.difficulty:
		"open_house":
			chance *= 0.45
		"finals":
			chance *= 1.7
	if vehicle != "":
		return false
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
	var atk := str(kit.get("attack", "light"))
	var t := 0.25
	match atk:
		"light", "blade", "slide":
			t = 0.14
		"gun":
			t = 0.2
		"grenade":
			t = 0.36
		"roundhouse", "jump-kick":
			t = 0.3
		"heavy":
			t = 0.32
		"ram":
			t = 0.08
		_:
			t = 0.22
	match App.difficulty:
		"open_house":
			t *= 1.45
		"finals":
			t *= 0.7
	telegraph = t
	VoBank.line(VoBank.who_of(self), "taunt", 0.1)
	atk_height = _pick_height(atk)
	_show_height()
	_pick_swing()


func _pick_swing() -> void:
	_swing_clip = ""
	if _anim == null or _anim.sprite_frames == null:
		return
	var c := "punch_high" if atk_height == "high" else ("kick_low" if atk_height == "low" else "punch_mid")
	if not _anim.sprite_frames.has_animation(c):
		return
	_swing_clip = c
	var who := _sprite_who()
	var info := SpriteBook.clip_info(who if SpriteBook.has_who(who) else "punk", c)
	var hit_f := maxi(1, int(info.get("hit", 6)))
	var fps := maxf(1.0, float(info.get("fps", 10.0)))
	_swing_rate = clampf((float(hit_f) / fps) / maxf(0.08, telegraph), 0.8, 3.5)
	_anim.play(c)
	_anim.frame = 0
	_anim.speed_scale = _swing_rate


## Light swings go for the face or the body; heavies the body or a low
## kick; spinning kicks are high, slides low. Brawlers mix in leg kicks.
func _pick_height(atk: String) -> String:
	match atk:
		"slide":
			return "low"
		"roundhouse", "jump-kick":
			return "high"
		"heavy":
			return "low" if randf() < 0.3 else "mid"
		"blade":
			return "mid"
		"gun", "grenade", "ram":
			return ""
	var r := randf()
	return "high" if r < 0.45 else ("mid" if r < 0.8 else "low")


func _show_height() -> void:
	if atk_height == "":
		return
	if _height_mark == null:
		_height_mark = Polygon2D.new()
		_height_mark.z_index = 12
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_height_mark.material = m
		add_child(_height_mark)
	var pts := PackedVector2Array()
	match atk_height:
		"high":
			pts = PackedVector2Array([Vector2(0, -6), Vector2(6, 3), Vector2(-6, 3)])
			_height_mark.color = Color(1.0, 0.3, 0.25)
		"low":
			pts = PackedVector2Array([Vector2(-6, -3), Vector2(6, -3), Vector2(0, 6)])
			_height_mark.color = Color(1.0, 0.85, 0.2)
		_:
			pts = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
			_height_mark.color = Color(1.0, 0.6, 0.2)
	_height_mark.polygon = pts
	_height_mark.position = Vector2(0, -92)
	_height_mark.visible = true
	_height_mark.scale = Vector2(1.6, 1.6)
	var tw := _height_mark.create_tween()
	tw.tween_property(_height_mark, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(maxf(0.05, telegraph))
	tw.tween_callback(func() -> void:
		if is_instance_valid(_height_mark):
			_height_mark.visible = false
	)


func _clash(from: Fighter) -> void:
	telegraph = 0.0
	recover = 0.42
	hp = maxi(1, hp - 8)
	Juice.clash(global_position)
	Juice.shout(Copy.CLASH)
	VoBank.clash()
	FamilyProfile.mark_clash()
	from.steam = minf(from.STEAM_MAX, from.steam + 10.0)
	from.invuln = maxi(from.invuln, 8)
	var rs := get_tree().get_first_node_in_group("run_state")
	var policy := false
	if rs != null and rs.has_method("has_card"):
		policy = bool(rs.call("has_card", "clash_policy"))
	if policy:
		from.steam = minf(from.STEAM_MAX, from.steam + 8.0)
		hp = maxi(1, hp - 6)
	if rs and rs.has_method("add_points"):
		rs.add_points(from.role, 18, "clash")
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "clash", float(from.facing))


func _ram_hit(f: Fighter) -> void:
	if recover > 0.0:
		return
	recover = 0.38
	f.take_hit("heavy", self)
	Juice.sparks(global_position)
	Juice.shout(vehicle.to_upper() if vehicle != "" else "RAM")


func _lob() -> void:
	recover = 0.85
	var shot := KitShot.new()
	shot.kind = "pistol"
	shot.owner_role = "enemy"
	shot.vel = Vector2(float(facing) * 220.0, -180.0)
	shot.global_position = global_position + Vector2(float(facing) * 16.0, -50.0)
	get_parent().add_child(shot)
	Juice.shout("GRENADE")


func _swing() -> void:
	recover = 0.42 if title != "Mohawk Bo" else 0.62
	var atk := str(kit.get("attack", "heavy" if title == "Mohawk Bo" else "light"))
	if atk == "gun":
		_shuriken()
		return
	if atk == "grenade":
		_lob()
		return
	if atk == "ram":
		return
	var kind := atk
	if kind == "slide":
		kind = "slide"
	elif kind == "blade":
		kind = "blade"
	elif kind == "roundhouse" or kind == "jump-kick" or kind == "heavy":
		pass
	else:
		kind = "light"
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			var f: Fighter = n
			if f.downed:
				continue
			if absf(f.global_position.x - global_position.x) < 50.0 and absf(f.global_position.y - global_position.y) < 70.0:
				f.take_hit(kind, self)
	atk_height = ""


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
	var frac := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var hurt := Color(0.72, 0.32, 0.28)
	# Sprites show damage as blood and wounds; only a hint of flush here.
	var body := _base_mod.lerp(hurt, (1.0 - frac) * (0.18 if _anim != null else 0.7))
	visual.modulate = body * _alert * lamp
	speed = _walk * (0.55 if frac < 0.4 else 1.0)
	if frac < 0.4 and visual:
		visual.position.y = 4.0 + 2.2 * sin(_bob * 0.7)
	if _brain:
		_brain.visible = stomp_hits >= 3 or (crush and frac <= 0.0)


func take_hit(kind: String, from: Node) -> void:
	_hurt_t = 0.28
	if telegraph > 0.0 and from is Fighter and (kind == "heavy" or kind == "roundhouse" or kind == "blade" or kind == "special"):
		if get_tree().get_first_node_in_group("chase_crash") == null:
			_clash(from as Fighter)
			return
	if guarding and kind != "throw" and kind != "snap" and kind != "finish" and kind != "web-slam":
		var high_beats_low := guard_low and (kind == "jump-kick" or kind == "dive" or kind == "heavy" or kind == "launcher")
		var low_beats_high := (not guard_low) and (kind == "slide" or kind == "jump-kick")
		if not high_beats_low and not low_beats_high:
			Juice.play("res://assets/audio/block.wav")
			Juice.flash_red(visual, 1)
			guarding = false
			return
		guarding = false
	if plates > 0 and (kind == "light" or kind == "jump-kick" or kind == "slide"):
		hp = maxi(0, hp - 2)
		Juice.flash_red(visual, 1)
		Juice.hitstop(1)
		Juice.shout("PLATE")
		if hp <= 0:
			_die(kind, from)
		return
	if plates > 0 and kind != "snap" and kind != "finish" and kind != "web-slam":
		plates -= 1
		var voided := false
		var rs_p := get_tree().get_first_node_in_group("run_state")
		if rs_p != null and rs_p.has_method("has_card") and (kind == "heavy" or kind == "dive"):
			voided = bool(rs_p.call("has_card", "landlord_void"))
		if voided and plates > 0:
			plates -= 1
		armored = plates > 0
		Juice.shout("STRIP %d" % plates)
		Juice.sparks(global_position)
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
	if kind == "jab":
		dmg = HitGrade.dmg("jab")
	elif kind == "cross":
		dmg = HitGrade.dmg("cross")
	elif kind == "bam" or kind == "gut-punch":
		dmg = HitGrade.dmg("bam")
	elif kind == "heavy" or kind == "dive":
		dmg = 22
	elif kind == "launcher":
		dmg = 20
		snared = 0.3
		global_position.y -= 24.0
	elif kind == "uppercut" or kind == "air-upper":
		dmg = 18 + FamilyProfile.dojo_rank("uppercut") * 4
		global_position.y -= 18.0
	elif kind == "roundhouse":
		dmg = 20 + FamilyProfile.dojo_rank("roundhouse") * 4
	elif kind == "air-mix":
		dmg = 16
	elif kind.begins_with("stomp"):
		stomp_hits += 1
		dmg = 12 + stomp_hits * 10
		if stomp_hits >= 3:
			dmg = maxi(dmg, hp)
			_show_brain()
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
	elif kind == "air-spin":
		dmg = 22
	elif kind == "slide":
		dmg = 10
	elif kind == "snare":
		dmg = 4
		snared = 1.1
	elif kind == "combo":
		dmg = int(from.get("combo_dmg")) if from != null and from.get("combo_dmg") != null else 24
	if FamilyProfile.has_cbt("pocket_sand") and kind == "throw":
		dmg += 8
	if FamilyProfile.has_cbt("night_eyes") and kind == "snap":
		dmg += 12
	if from is Fighter and (from as Fighter).buff_t > 0.0:
		dmg = int(round(float(dmg) * 1.25))
	if from is Fighter:
		dmg += int(FamilyProfile.gear_stat_bonus((from as Fighter).role).get("dmg", 0))
	if from is Fighter and Charms.has("rabbit_foot") and randf() < 0.12:
		dmg *= 2
		Juice.popup_number(global_position + Vector2(0, -60), "CRIT", UiKit.GOLD)
		Juice.hitstop(3)
	var before_hp := hp
	hp = maxi(0, hp - dmg)
	_overkill = hp <= 0 and (dmg - before_hp >= 14 or kind in ["combo", "finish", "stomp3", "snap", "air-spin", "web-slam"])
	_hit_noise(kind, from)
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
		if rs and rs.has_method("add_points"):
			var pts := 12
			if kind == "heavy" or kind == "launcher" or kind == "roundhouse":
				pts = 28
			elif kind == "uppercut" or kind == "air-upper":
				pts = 32
			elif kind.begins_with("stomp"):
				pts = 18 * stomp_hits
				if rs.has_method("has_card") and rs.has_card("stomp_policy"):
					pts *= 2
			elif kind == "snap":
				pts = 90
			elif kind == "web-slam" or kind == "finish" or kind == "air-mix":
				pts = 40
			if rs.has_method("has_card") and rs.has_card("open_tab"):
				pts += 4
			rs.add_points((from as Fighter).role, pts, kind)
			Juice.last_hitter = (from as Fighter).role
		if rs and rs.has_method("has_card") and rs.has_card("family_discount"):
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and n != from:
					(n as Fighter).steam = minf(Fighter.STEAM_MAX, (n as Fighter).steam + 12.0)
		if rs and rs.has_method("has_card") and rs.has_card("head_trampoline") and kind == "heavy" and not (from as Fighter)._street_grounded():
			(from as Fighter).extra_jump = 1
			global_position.y -= 80.0
	if from is Node2D:
		var dir := signf(global_position.x - (from as Node2D).global_position.x)
		if dir == 0.0:
			dir = -float(facing)
		global_position.x += dir * (8.0 if kind == "light" else 20.0)
		_gore(kind, from, dir)
		var blood := get_tree().get_first_node_in_group("blood_sim")
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
	if kind == "combo" and hp > 0 and from is Fighter:
		_combo_fx(str((from as Fighter).combo_fx), from as Fighter)
	if hp <= 0:
		_die(kind, from)


## What a dojo finisher does to a body that survives it.
func _combo_fx(fx: String, from: Fighter) -> void:
	var dir := signf(global_position.x - from.global_position.x)
	if dir == 0.0:
		dir = float(from.facing)
	telegraph = 0.0
	atk_height = ""
	match fx:
		"launch":
			flung = true
			flung_dir = dir
			flung_t = 0.18
			flung_ground = false
		"fling":
			flung = true
			flung_dir = dir
			flung_t = 0.34
			flung_ground = false
		"knockdown", "crush":
			recover = maxf(recover, 1.2)
		"stun":
			recover = maxf(recover, 0.95)
			Juice.shout("STUNNED")


## The sound of the blow landing, layered on the old hit sounds: bone and
## teeth on the big ones, meat on the finishers; a grunt now and then.
func _hit_noise(kind: String, from: Node) -> void:
	var dir := -float(facing)
	if from is Node2D:
		dir = signf(global_position.x - (from as Node2D).global_position.x)
	var big := kind in ["heavy", "combo", "uppercut", "air-upper", "roundhouse", "air-spin", "launcher", "dive", "finish", "web-slam"]
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if kind == "light" or kind == "jab" or kind == "cross" or kind == "jump-kick":
		Mixer.play_sfx("res://assets/audio/sfx/punch_light.ogg", 1.0, -4.0)
	elif big:
		Mixer.play_sfx("res://assets/audio/sfx/kick_heavy.ogg" if kind in ["roundhouse", "air-spin", "jump-kick"] else "res://assets/audio/sfx/punch_heavy.ogg")
		if randf() < 0.45:
			Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 1.0, -3.0)
			if blood and blood.has_method("gore"):
				blood.gore(global_position, dir, "crack")
		if randf() < 0.3 and blood and blood.has_method("gore"):
			blood.gore(global_position, dir, "teeth")
			Mixer.play_sfx("res://assets/audio/sfx/teeth.ogg", 1.0, -6.0)
	if kind == "combo":
		Mixer.play_sfx("res://assets/audio/sfx/gore_squelch.ogg", 1.0, -2.0)
	if hp > 0:
		VoBank.line(VoBank.who_of(self), "hurt", 0.14)


func _die(kind: String, from: Node) -> void:
	var dir := -float(facing)
	if from is Node2D and (from as Node2D).global_position.x != global_position.x:
		dir = signf(global_position.x - (from as Node2D).global_position.x)
	# Brutal: the body comes apart on an overkill, chunks and teeth otherwise.
	var gb := get_tree().get_first_node_in_group("blood_sim")
	if gb and gb.has_method("gore"):
		gb.gore(global_position, dir, "overkill" if _overkill else "kill")
	if _overkill:
		_last_zone = "blast"
		Mixer.play_sfx("res://assets/audio/sfx/gib_splat.ogg")
		Mixer.play_sfx("res://assets/audio/sfx/skull_crunch.ogg", 1.0, -2.0)
		Mixer.play_sfx("res://assets/audio/vo/ann_overkill.ogg", 1.0, -1.0)
		Juice.freeze_frames(5)
	else:
		Mixer.play_sfx("res://assets/audio/sfx/gore_squelch.ogg", 1.0, -4.0)
		if randf() < 0.25:
			Mixer.play_sfx("res://assets/audio/vo/ann_brutal.ogg", 1.0, -3.0)
	get_tree().create_timer(0.55).timeout.connect(func() -> void:
		Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 1.0, -3.0)
	)
	VoBank.line(VoBank.who_of(self), "death", 0.55)
	if from is Fighter:
		var role := (from as Fighter).role
		get_tree().create_timer(1.1).timeout.connect(func() -> void:
			VoBank.line(role, "kill", 0.35)
		)
	if kind != "light" and kind != "snap":
		Juice.kill_burst(global_position, kind)
		if kind == "finish" or kind == "stomp3":
			Juice.kill_cam(global_position)
	Juice.play("res://assets/audio/kill.wav")
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("pump") and _last_zone != "low":
		blood.pump(global_position, dir)
	if _anim != null and not FamilyProfile.less_gore():
		HitReact.corpse(get_parent(), _anim, global_position, _last_zone, dir, facing)
	elif kind != "light" and kind != "snap":
		StreetRagdoll.burst(get_parent(), global_position, dir, _base_mod)
	var rs_heat := get_tree().get_first_node_in_group("run_state")
	InvoiceHeat.bump(rs_heat, 2 if cop else 1)
	if cop:
		FamilyProfile.bump_bounty("cop")
	if title == "Bag Snatch":
		FamilyProfile.bump_bounty("bag")
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
	if from is Fighter:
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_points"):
			rs.add_points((from as Fighter).role, 100 if title != "Bag Snatch" else 70, "kill")
		if Charms.has("fight_tape"):
			var ff := from as Fighter
			ff.hp = mini(ff.max_hp, ff.hp + 3)
	_drops(from)
	died.emit()
	queue_free()


func _show_brain() -> void:
	if FamilyProfile.less_gore():
		return
	if _brain != null:
		_brain.visible = true
		return
	_brain = Polygon2D.new()
	_brain.color = Color(0.82, 0.42, 0.5, 0.95)
	_brain.polygon = PackedVector2Array([
		Vector2(-8, -68), Vector2(8, -68), Vector2(10, -54), Vector2(-10, -54)
	])
	visual.add_child(_brain)


func _drops(from: Node) -> void:
	var host := get_parent()
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_xp"):
		rs.add_xp(18 if title == "Mohawk Bo" else 10)
	var orb := ScrapOrb.new()
	orb.amount = 5 if title == "Mohawk Bo" else 3
	orb.global_position = global_position + Vector2(0, -20)
	host.add_child(orb)
	if title == "Lottery Goon":
		FamilyProfile.add_gems(1)
		Juice.toast("reward", "RAFFLE", "The goon dropped a gem. Civic engagement.")
	var chance := 0.35
	if FamilyProfile.has_cbt("disarm_habit"):
		chance += 0.2
	if randf() < chance:
		var drop := WeaponPickup.new()
		drop.kind = "knife" if title == "Bag Snatch" else "pipe"
		if title == "Invoice Clerk":
			drop.kind = "pistol"
		elif title == "Chapel Usher" or title == "Shift Lead":
			drop.kind = "board"
		drop.global_position = global_position + Vector2(12, -8)
		host.add_child(drop)
	if from is Fighter and rs and rs.has_method("has_card") and rs.has_card("head_trampoline"):
		pass


## Where the blow landed decides the blood, the body reaction and later the
## death: face cuts and spray for head shots, a cough and a fold for the gut,
## legs swept for slides, a hole and an exit spray for bullets.
func _gore(kind: String, from: Node, dir: float) -> void:
	var clip := ""
	if from is Fighter:
		clip = str((from as Fighter).get("_strike_clip"))
	var hit_kind := kind
	if from is KitShot:
		hit_kind = "bullet"
	var zone := HitReact.zone_of(hit_kind, clip)
	var power := HitReact.power_of(kind)
	if clip == "cross":
		power = maxf(power, 0.4)
	elif clip == "roundhouse" or clip == "side_kick":
		power = maxf(power, 0.8)
	_last_zone = zone
	var hurt := 1.0 - float(hp) / float(maxi(max_hp, 1))
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("hit"):
		blood.hit(self, zone, dir, power, hurt)
		if kind == "bam" or kind == "gut-punch" or kind == "stomp3":
			blood.pump(global_position, dir)
		# Big blows splash the camera glass on the side the blood flies.
		if power >= 0.85 and randf() < 0.35:
			blood.screen(dir, power)
	if _anim != null:
		_splat = minf(1.0, _splat + power * 0.22)
		var face := hurt * 1.15 if zone != "low" else hurt * 0.6
		BloodSim.wound(_anim, face, _splat, -dir * float(facing))
		if zone == "bullet":
			var head := BloodSim.head_of(_anim)
			BloodSim.add_hole(_anim, Vector2(head.x + randf_range(-7.0, 7.0), head.y + head.z * randf_range(2.4, 5.2)))
	if hp > 0 and not flung:
		var busy := HitReact.react(visual, facing, zone, dir, power)
		if busy > 0.3:
			telegraph = 0.0
		recover = maxf(recover, busy)
