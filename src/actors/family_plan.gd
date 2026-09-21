class_name FamilyPlan
extends Punk

## Late-act climax. Strip the armor plates first. Then SoR4-sized patterns.

const BODY_HP := 720
var plates := 4
var phase := 0
var stun := 0.0
var heavies_eaten := 0
var pattern_cd := 2.2
var halt := 1.4
var filed_alive := false
var _plates: Array[Polygon2D] = []
var _arms: Array[Polygon2D] = []
var _eyes: Array[Polygon2D] = []
var _crown: Polygon2D
var _pattern := ""
var _pat_t := 0.0


func _ready() -> void:
	title = "The Family Plan"
	home = "street"
	hp = BODY_HP
	speed = 22.0
	armored = true
	cop = false
	super._ready()
	add_to_group("act_boss")
	add_to_group("family_plan")
	max_hp = BODY_HP
	hp = BODY_HP
	set_meta("introed", false)
	_build_mech()
	var cap := get_node_or_null("Hurt") as Area2D
	if cap:
		var cs := cap.get_child(0) as CollisionShape2D
		if cs and cs.shape is RectangleShape2D:
			(cs.shape as RectangleShape2D).size = Vector2(70, 140)
			cs.position = Vector2(0, -70)
	for child in get_children():
		if child is CollisionShape2D:
			var c: CollisionShape2D = child
			if c.shape is CapsuleShape2D:
				(c.shape as CapsuleShape2D).radius = 28
				(c.shape as CapsuleShape2D).height = 120
				c.position = Vector2(0, -60)
	died.connect(_on_dead)


func _build_mech() -> void:
	visual.scale = Vector2(2.15, 2.15)
	_crown = Polygon2D.new()
	_crown.color = Palette.EDGE
	_crown.polygon = PackedVector2Array([
		Vector2(-28, -108), Vector2(28, -108), Vector2(20, -86), Vector2(-20, -86)
	])
	Blockout.add_glow(_crown)
	visual.add_child(_crown)
	for i in 4:
		var p := Polygon2D.new()
		p.color = Color(0.55, 0.52, 0.48, 0.95)
		var ox := -30.0 + float(i) * 16.0
		p.polygon = PackedVector2Array([
			Vector2(ox, -40), Vector2(ox + 14, -40), Vector2(ox + 14, 8), Vector2(ox, 8)
		])
		visual.add_child(p)
		_plates.append(p)
	for side in [-1.0, 1.0]:
		var arm := Polygon2D.new()
		arm.color = Color(0.22, 0.2, 0.24)
		arm.polygon = PackedVector2Array([
			Vector2(side * 22, -36), Vector2(side * 58, -28), Vector2(side * 62, -8), Vector2(side * 18, -12)
		])
		visual.add_child(arm)
		_arms.append(arm)
	for ox in [-10.0, 10.0]:
		var e := Polygon2D.new()
		e.color = Palette.EDGE
		e.polygon = PackedVector2Array([
			Vector2(ox - 5, -78), Vector2(ox + 5, -78), Vector2(ox + 5, -68), Vector2(ox - 5, -68)
		])
		Blockout.add_glow(e)
		visual.add_child(e)
		_eyes.append(e)


func _physics_process(delta: float) -> void:
	if halt > 0.0:
		halt -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_mix_mod()
		_flap(delta)
		return
	if stun > 0.0:
		stun -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_alert = Color(0.75, 0.88, 1.0)
		_mix_mod()
		_flap(delta)
		return
	_alert = Color.WHITE
	pattern_cd -= delta
	if plates <= 0 and pattern_cd <= 0.0 and _pattern == "":
		_pick_pattern()
	if _pattern != "":
		_run_pattern(delta)
	else:
		super._physics_process(delta)
	_flap(delta)
	if phase >= 4:
		for e in _eyes:
			e.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.014)


func _flap(_delta: float) -> void:
	var w := 10.0 * sin(Time.get_ticks_msec() * 0.006)
	if _arms.size() >= 2:
		_arms[0].position.y = w * 0.15
		_arms[1].position.y = -w * 0.15


func _pick_pattern() -> void:
	var ratio := float(hp) / float(maxi(max_hp, 1))
	if ratio <= 0.28:
		phase = 4
		_pattern = "frenzy"
	elif ratio <= 0.5:
		phase = 3
		_pattern = ["rain", "slam", "slash", "sweep"][randi() % 4]
	else:
		phase = 2
		_pattern = ["slash", "sweep", "slam"][randi() % 3]
	_pat_t = 0.0
	pattern_cd = 2.6 if phase < 4 else 1.6
	Juice.shout(_pattern.to_upper())


func _run_pattern(delta: float) -> void:
	_pat_t += delta
	velocity = Vector2.ZERO
	match _pattern:
		"slash":
			if _pat_t < 0.28:
				_telegraph()
			elif _pat_t < 0.32:
				_spawn_slash()
				_pattern = "wait"
				_pat_t = 0.0
			move_and_slide()
		"sweep":
			if _pat_t < 0.34:
				_telegraph()
			elif _pat_t < 0.38:
				_spawn_sweep()
				_pattern = "wait"
				_pat_t = 0.0
			move_and_slide()
		"slam":
			if _pat_t < 0.22:
				_telegraph()
			elif int(_pat_t * 10.0) % 7 == 0:
				_spawn_slam(int(_pat_t / 0.28))
			if _pat_t > 1.05:
				_pattern = ""
			move_and_slide()
		"rain":
			if _pat_t < 0.18:
				_telegraph()
			elif _pat_t < 0.22:
				_spawn_rain()
				_pattern = "wait"
				_pat_t = 0.0
			move_and_slide()
		"frenzy":
			if int(_pat_t * 8.0) % 3 == 0:
				_spawn_slam(int(_pat_t * 4.0))
			if _pat_t > 1.4:
				_pattern = ""
			move_and_slide()
		"wait":
			if _pat_t > 0.85:
				_pattern = ""
			move_and_slide()
		_:
			_pattern = ""
			super._physics_process(delta)


func _telegraph() -> void:
	_alert = Color(1.0, 0.55, 0.25)
	_mix_mod()


func _spawn_slash() -> void:
	_hitbox(Vector2(-220, -40), Vector2(220, 70), 0.38, "heavy")
	_hitbox(Vector2(-80, -120), Vector2(280, 50), 0.38, "heavy")
	Juice.pulse_shake(7.0)
	Juice.play("res://assets/audio/hit_heavy.wav")


func _spawn_sweep() -> void:
	_hitbox(Vector2(-340, 10), Vector2(680, 48), 0.42, "slide")
	Juice.pulse_shake(8.0)
	Juice.play("res://assets/audio/dash.wav")


func _spawn_slam(n: int) -> void:
	var ox := float((n % 3) - 1) * 140.0
	_hitbox(Vector2(ox - 50, 8), Vector2(100, 70), 0.28, "dive")
	Juice.pulse_shake(6.0)
	Juice.hitstop(3)


func _spawn_rain() -> void:
	var host := get_parent()
	if host == null:
		return
	for i in 7:
		var sheet := Area2D.new()
		sheet.collision_layer = 8
		sheet.collision_mask = 2
		sheet.monitoring = true
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(22, 30)
		cs.shape = r
		sheet.add_child(cs)
		var paper := ColorRect.new()
		paper.color = Color(0.92, 0.9, 0.78, 0.92)
		paper.size = Vector2(22, 30)
		paper.position = Vector2(-11, -15)
		sheet.add_child(paper)
		sheet.global_position = Vector2(global_position.x - 240.0 + i * 80.0, 80.0)
		host.add_child(sheet)
		var vy := 240.0 + float(i) * 18.0
		sheet.body_entered.connect(func(b: Node) -> void:
			if b is Fighter:
				(b as Fighter).take_hit("light", self)
				if is_instance_valid(sheet):
					sheet.queue_free()
		)
		var tw := sheet.create_tween()
		tw.tween_property(sheet, "global_position:y", 620.0, (540.0 / vy))
		tw.tween_callback(sheet.queue_free)
	Juice.shout("PAST DUE")


func _hitbox(local: Vector2, size: Vector2, life: float, kind: String) -> void:
	var a := Area2D.new()
	a.collision_layer = 8
	a.collision_mask = 2
	a.monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(size.x * 0.5, size.y * 0.5)
	a.add_child(cs)
	var vis := ColorRect.new()
	vis.color = Color(0.95, 0.55, 0.2, 0.35)
	vis.size = size
	a.add_child(vis)
	a.position = local
	add_child(a)
	a.body_entered.connect(func(b: Node) -> void:
		if b is Fighter:
			(b as Fighter).take_hit(kind, self)
	)
	var tw := create_tween()
	tw.tween_interval(life)
	tw.tween_callback(a.queue_free)


func take_hit(kind: String, from: Node) -> void:
	if plates > 0:
		if kind == "light" or kind == "snare" or kind == "jump-kick" or kind == "gut-punch":
			Juice.play("res://assets/audio/block.wav")
			Juice.flash_red(visual, 1)
			Juice.shout("CLINK")
			return
		if kind == "snap":
			Juice.shout("NOT UNTIL THE ARMOR'S A RECEIPT")
			Juice.flash_red(visual, 2)
			return
		_strip_plate(from)
		var rs := get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("has_card") and rs.has_card("invoice_void") and plates > 0:
			_strip_plate(from)
		return
	if kind == "light":
		Juice.play("res://assets/audio/block.wav")
		Juice.flash_red(visual, 1)
		Juice.shout("PARRY")
		hp = maxi(1, hp - 1)
		_score(from, 8)
		return
	if kind == "heavy" or kind == "launcher" or kind == "web-slam":
		heavies_eaten += 1
		if heavies_eaten >= 3:
			stun = 1.6
			heavies_eaten = 0
			Juice.shout("STUN")
			Juice.freeze_frames(6)
	if kind == "snap":
		if stun <= 0.0:
			Juice.shout("NOT YET")
			Juice.flash_red(visual, 2)
			return
		if not filed_alive:
			filed_alive = true
			FamilyProfile.add_gold(40)
			FamilyProfile.mark_file_alive()
			Juice.unlock_logo("FILE ALIVE", "Huntdown would call it a bounty. We call it extra billing.")
			Juice.toast("achievement", "FILE ALIVE", "+40 gold. The Director is still a problem.")
			_score(from, 500)
	_score(from, 28 if kind != "snap" else 120)
	super.take_hit(kind, from)


func _strip_plate(from: Node) -> void:
	plates = maxi(0, plates - 1)
	if plates < _plates.size():
		_plates[plates].visible = false
	Juice.shout("PLATE %d" % (4 - plates))
	Juice.hitstop(6)
	Juice.pulse_shake(7.0)
	Juice.flash_white_red(visual)
	_score(from, 150)
	if plates <= 0:
		armored = false
		halt = 1.35
		phase = 1
		Juice.freeze_frames(8)
		Juice.unlock_logo("ARMOR STRIPPED", "The suit is a receipt. The body is the invoice.")
		Juice.toast("challenge", "NAKED BILLING", "Now the patterns. Stay off the floor.")
		Juice.shout("NAKED BILLING")
		Mixer.play_music("res://assets/audio/music_finale.wav")


func _score(from: Node, n: int) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points") and from is Fighter:
		rs.add_points((from as Fighter).role, n, "plan")


func _on_dead() -> void:
	FamilyProfile.mark_family_plan()
	var act := get_tree().get_first_node_in_group("run_act")
	Juice.toast("quest", "DIRECTOR FILED", "The Family Plan is a corpse. The fridge stays.")
	if act and act.has_method("finish_boss"):
		act.finish_boss()
