class_name Skinwalker
extends ActBoss

## Internet cryptid, not ceremonial. Deceive first. Then the slip. FILE it.

enum Shape { DOG, WALK, STOOP, CRAWL, LUNGE, BURST }

var dormant := true
var shape: Shape = Shape.DOG
var _head: Polygon2D
var _gape: Polygon2D
var _eye_l: Polygon2D
var _eye_r: Polygon2D
var _foot: Polygon2D
var _whistle_cd := 2.4
var _burst_cd := 0.0
var _burst_t := 0.0
var _stutter := 0.0
var _crawl_t := 0.0
var _jerk := 0.0
var _woke := false
var _gape_open := false
var _phase_cd := 0.8
var _form_hold := 1.0
var _help_said := false


func _ready() -> void:
	is_mini = true
	display = "Number 87"
	if title == "":
		title = "Number 87"
	sub = "ALREADY SITTING"
	accent = Color(0.78, 0.72, 0.22)
	home = "street"
	super._ready()
	add_to_group("skinwalker")
	set_meta("introed", true)
	_hide_crown()
	_paint_form(Shape.DOG)
	shape = Shape.DOG


func _hide_crown() -> void:
	if visual == null:
		return
	for c in visual.get_children():
		if c is Polygon2D:
			var p: Polygon2D = c
			if p.polygon.size() == 4 and absf(p.polygon[0].y + 86.0) < 2.0:
				p.visible = false


func _show_crown() -> void:
	if visual == null:
		return
	for c in visual.get_children():
		if c is Polygon2D:
			var p: Polygon2D = c
			if p.polygon.size() == 4 and absf(p.polygon[0].y + 86.0) < 2.0:
				p.visible = true
				p.color = Color(0.82, 0.78, 0.18)


func _clear_body() -> void:
	if visual == null:
		return
	for c in visual.get_children():
		if c is Polygon2D:
			var p: Polygon2D = c
			if p.polygon.size() == 4 and absf(p.polygon[0].y + 86.0) < 2.0:
				continue
			visual.remove_child(c)
			c.free()
	_head = null
	_gape = null
	_eye_l = null
	_eye_r = null
	_foot = null


func _poly(pts: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = pts
	visual.add_child(p)
	return p


func _paint_form(next: Shape) -> void:
	_clear_body()
	match next:
		Shape.DOG:
			_paint_dog()
		Shape.WALK:
			_paint_human(false)
		Shape.STOOP:
			_paint_human(true)
		Shape.CRAWL:
			_paint_crawl()
		Shape.LUNGE, Shape.BURST:
			_paint_true()
	_form_hold = 0.0
	visual.modulate = Color(1, 1, 1, 1)
	_base_mod = visual.modulate


func _paint_dog() -> void:
	# Practiced pet. Something is already wrong if you look.
	_poly(PackedVector2Array([Vector2(-28, -8), Vector2(30, -10), Vector2(26, 14), Vector2(-24, 16)]), Color(0.28, 0.22, 0.18))
	_poly(PackedVector2Array([Vector2(18, -18), Vector2(36, -8), Vector2(28, 6), Vector2(12, 2)]), Color(0.32, 0.24, 0.18))
	_head = _poly(PackedVector2Array([Vector2(22, -22), Vector2(40, -16), Vector2(34, 2), Vector2(16, -4)]), Color(0.36, 0.28, 0.2))
	_eye_l = _poly(PackedVector2Array([Vector2(28, -16), Vector2(34, -16), Vector2(33, -11), Vector2(27, -11)]), Color(0.82, 0.78, 0.18))
	_eye_r = _poly(PackedVector2Array([Vector2(22, -14), Vector2(26, -14), Vector2(25, -10), Vector2(21, -10)]), Color(0.72, 0.7, 0.2))
	_foot = _poly(PackedVector2Array([Vector2(-22, 12), Vector2(-8, 12), Vector2(-10, 20), Vector2(-20, 20)]), Color(0.18, 0.14, 0.12))
	_poly(PackedVector2Array([Vector2(8, 12), Vector2(22, 10), Vector2(20, 20), Vector2(6, 20)]), Color(0.18, 0.14, 0.12))
	_gape = _poly(PackedVector2Array([Vector2(32, -4), Vector2(38, -2), Vector2(36, 4), Vector2(30, 2)]), Color(0.35, 0.12, 0.12))
	_gape.visible = false
	visual.modulate = Color(0.86, 0.78, 0.62)
	_base_mod = visual.modulate


func _paint_human(stoop: bool) -> void:
	# Practiced person. Joints still invent a new animal.
	var drop := 18.0 if stoop else 0.0
	_poly(PackedVector2Array([Vector2(-10, -72 + drop), Vector2(12, -74 + drop), Vector2(10, -52 + drop), Vector2(-12, -50 + drop)]), Color(0.86, 0.78, 0.7))
	_head = _poly(PackedVector2Array([Vector2(-12, -88 + drop), Vector2(14, -90 + drop), Vector2(12, -68 + drop), Vector2(-14, -66 + drop)]), Color(0.88, 0.8, 0.72))
	_eye_l = _poly(PackedVector2Array([Vector2(-6, -82 + drop), Vector2(0, -82 + drop), Vector2(-1, -76 + drop), Vector2(-7, -76 + drop)]), Color(0.78, 0.72, 0.16))
	_eye_r = _poly(PackedVector2Array([Vector2(4, -83 + drop), Vector2(11, -84 + drop), Vector2(10, -76 + drop), Vector2(3, -76 + drop)]), Color(0.9, 0.86, 0.2))
	_gape = _poly(PackedVector2Array([Vector2(-4, -70 + drop), Vector2(8, -70 + drop), Vector2(6, -64 + drop), Vector2(-2, -64 + drop)]), Color(0.42, 0.12, 0.14))
	_poly(PackedVector2Array([Vector2(-16, -50 + drop), Vector2(16, -52 + drop), Vector2(12, -8 + drop), Vector2(-14, -6 + drop)]), Color(0.72, 0.7, 0.66))
	_poly(PackedVector2Array([Vector2(-14, -6 + drop), Vector2(-2, -6 + drop), Vector2(-4, 18), Vector2(-16, 18)]), Color(0.22, 0.2, 0.2))
	_foot = _poly(PackedVector2Array([Vector2(0, -6 + drop), Vector2(12, -6 + drop), Vector2(10, 18), Vector2(-2, 18)]), Color(0.22, 0.2, 0.2))
	_poly(PackedVector2Array([Vector2(-22, -44 + drop), Vector2(-12, -44 + drop), Vector2(-8, -8 + drop), Vector2(-20, -6 + drop)]), Color(0.8, 0.72, 0.66))
	_poly(PackedVector2Array([Vector2(12, -46 + drop), Vector2(26, -48 + drop), Vector2(22, -10 + drop), Vector2(10, -8 + drop)]), Color(0.8, 0.72, 0.66))
	visual.modulate = Color(0.92, 0.86, 0.78)
	_base_mod = visual.modulate


func _paint_crawl() -> void:
	_poly(PackedVector2Array([Vector2(-40, -18), Vector2(36, -8), Vector2(28, 10), Vector2(-36, 8)]), Color(0.86, 0.82, 0.76))
	_head = _poly(PackedVector2Array([Vector2(-48, 4), Vector2(-20, -6), Vector2(-16, 18), Vector2(-52, 22)]), Color(0.9, 0.86, 0.8))
	_eye_l = _poly(PackedVector2Array([Vector2(-44, 8), Vector2(-36, 8), Vector2(-37, 14), Vector2(-45, 14)]), Color(0.92, 0.86, 0.12))
	_eye_r = _poly(PackedVector2Array([Vector2(-34, 6), Vector2(-26, 4), Vector2(-26, 12), Vector2(-34, 12)]), Color(0.95, 0.9, 0.16))
	_gape = _poly(PackedVector2Array([Vector2(-48, 16), Vector2(-22, 12), Vector2(-24, 28), Vector2(-50, 26)]), Color(0.28, 0.08, 0.08))
	_foot = _poly(PackedVector2Array([Vector2(18, 6), Vector2(38, -4), Vector2(40, 12), Vector2(16, 16)]), Color(0.78, 0.74, 0.7))
	_poly(PackedVector2Array([Vector2(-18, -22), Vector2(-4, -28), Vector2(0, -8), Vector2(-14, -4)]), Color(0.84, 0.8, 0.74))
	visual.modulate = Color(0.9, 0.86, 0.8)
	_base_mod = visual.modulate


func _paint_true() -> void:
	# Pale thin. Form never fully holds. Huge gape. Sick yellow stare.
	_poly(PackedVector2Array([Vector2(-10, -78), Vector2(10, -82), Vector2(8, -18), Vector2(-12, -14)]), Color(0.9, 0.88, 0.82))
	_head = _poly(PackedVector2Array([Vector2(-14, -108), Vector2(16, -112), Vector2(14, -76), Vector2(-16, -72)]), Color(0.93, 0.9, 0.84))
	_eye_l = _poly(PackedVector2Array([Vector2(-8, -100), Vector2(0, -102), Vector2(-1, -90), Vector2(-9, -90)]), Color(0.95, 0.88, 0.12))
	_eye_r = _poly(PackedVector2Array([Vector2(4, -102), Vector2(14, -104), Vector2(13, -90), Vector2(3, -90)]), Color(0.98, 0.92, 0.08))
	_gape = _poly(PackedVector2Array([Vector2(-10, -82), Vector2(12, -84), Vector2(8, -52), Vector2(-8, -50)]), Color(0.18, 0.04, 0.05))
	_poly(PackedVector2Array([Vector2(-28, -70), Vector2(-8, -66), Vector2(-4, -8), Vector2(-30, -12)]), Color(0.88, 0.84, 0.78))
	_poly(PackedVector2Array([Vector2(8, -72), Vector2(32, -78), Vector2(28, -10), Vector2(6, -12)]), Color(0.88, 0.84, 0.78))
	_foot = _poly(PackedVector2Array([Vector2(-14, -12), Vector2(-2, -12), Vector2(-6, 22), Vector2(-18, 18)]), Color(0.82, 0.78, 0.72))
	_poly(PackedVector2Array([Vector2(0, -12), Vector2(12, -14), Vector2(16, 22), Vector2(2, 18)]), Color(0.82, 0.78, 0.72))
	visual.modulate = Color(0.94, 0.9, 0.82)
	_base_mod = visual.modulate


func wake() -> void:
	if _woke:
		return
	_slip()


func _slip() -> void:
	if _woke:
		return
	_woke = true
	dormant = false
	title = "Skinwalker"
	display = "Skinwalker"
	sub = "THAT"
	var keep_hp := hp
	var keep_max := max_hp
	KitBook.apply(self)
	hp = keep_hp
	max_hp = keep_max
	_walk = maxf(speed, 38.0)
	_paint_form(Shape.WALK)
	shape = Shape.WALK
	_show_crown()
	Juice.slip(global_position)
	Juice.yellow_stare(global_position)
	Juice.gape(global_position)
	Juice.named_slowmo()
	Juice.shout(Copy.THAT_WALKER)
	VoBank.dad_skinwalker()
	set_meta("introed", false)
	var act := get_tree().get_first_node_in_group("run_act")
	if act and act.has_method("_tick_boss_intro"):
		act._tick_boss_intro(global_position.x)
	if act and act.get("_talk") != null:
		var talk: Variant = act.get("_talk")
		if talk is Talk:
			(talk as Talk).play([
				{"who": "son", "text": "I asked a hundred times. Those photos were trash."},
				{"who": "father", "text": "THAT is a skinwalker."}
			], true)
	BossCard.present(get_parent(), "SKINWALKER", "THE FORM NEVER HOLDS", Color(0.92, 0.86, 0.18), false)


func _physics_process(delta: float) -> void:
	if flung:
		_fling(delta)
		return
	_jerk += delta
	_phase_cd -= delta
	if _burst_cd > 0.0:
		_burst_cd -= delta
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
	if dormant:
		_idle_lie(delta)
		return
	if snared > 0.0:
		snared -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_lane()
		_mix_mod()
		_tick_wrong(delta)
		return
	if recover > 0.0:
		recover -= delta
		velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
		move_and_slide()
		_lane()
		_mix_mod()
		_tick_wrong(delta)
		return
	if telegraph > 0.0:
		telegraph -= delta
		_alert = Color(1.0, 0.82, 0.2)
		velocity.x = 0
		_gape_open = true
		if _gape:
			_gape.scale = Vector2(1.0, 1.0 + (0.32 - telegraph) * 2.4)
		move_and_slide()
		if telegraph <= 0.0:
			_alert = Color.WHITE
			_gape_open = false
			if _gape:
				_gape.scale = Vector2.ONE
			_land_shape_hit()
		_lane()
		_mix_mod()
		_tick_wrong(delta)
		return
	var t := _target()
	if t == null:
		velocity.x = 0
		move_and_slide()
		_lane()
		_mix_mod()
		_tick_wrong(delta)
		return
	var d := t.global_position.x - global_position.x
	facing = 1 if d > 0.0 else -1
	visual.scale.x = float(facing)
	_drive_shape(t, d, delta)
	velocity.y = 0
	move_and_slide()
	_lane()
	_mix_mod()
	_tick_wrong(delta)


func _idle_lie(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_lane()
	if visual:
		visual.rotation = sin(_jerk * 1.7) * 0.04
		if _foot:
			_foot.position.y = -6.0 + absf(sin(_jerk * 0.9)) * 10.0
		if _head:
			_head.rotation = sin(_jerk * 2.4) * 0.12
	_whistle_cd -= delta
	if _whistle_cd <= 0.0:
		_whistle_cd = randf_range(4.2, 7.1)
		Juice.whistle(global_position)
		if not _help_said and randf() < 0.45:
			_help_said = true
			Juice.help_call(global_position)
	var players := get_tree().get_nodes_in_group("players")
	for n in players:
		if n is Fighter and not (n as Fighter).downed:
			if absf((n as Node2D).global_position.x - global_position.x) < 118.0:
				_slip()
				return
	_mix_mod()


func _target() -> Node2D:
	var best: Node2D = null
	var dist := 9999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d: float = absf((n as Node2D).global_position.x - global_position.x)
			if absf((n as Node2D).global_position.y - global_position.y) < 110.0 and d < dist:
				dist = d
				best = n
	return best


func _drive_shape(t: Node2D, d: float, delta: float) -> void:
	var dist := absf(d)
	var frac := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	if _burst_t > 0.0:
		_burst_t -= delta
		_stutter -= delta
		if _stutter <= 0.0:
			_stutter = 0.09
			velocity.x = 0.0
		else:
			velocity.x = float(facing) * _walk * 2.35
		if dist < 50.0:
			_burst_t = 0.0
			_begin_lunge()
		return
	if frac < 0.28 and _burst_cd <= 0.0 and dist > 90.0:
		_begin_burst()
		return
	if frac < 0.48 and dist > 56.0:
		_hold_shape(Shape.CRAWL)
		_crawl_t += delta
		visual.scale.x = float(-facing)
		velocity.x = float(-facing) * _walk * 0.72
		if dist < 64.0:
			_begin_lunge()
		return
	if frac < 0.72:
		_hold_shape(Shape.STOOP)
		if dist < 58.0:
			_begin_stoop()
			velocity.x = 0
		else:
			velocity.x = clampf(d, -1.0, 1.0) * _walk * 0.7
		return
	_hold_shape(Shape.WALK)
	if dist < 48.0:
		_begin_walk_hit()
		velocity.x = 0
	else:
		# Weird foot lifts — practiced walk that still looks learned.
		velocity.x = clampf(d, -1.0, 1.0) * _walk * 0.86
		if _foot:
			_foot.position.y = -absf(sin(_jerk * 5.2)) * 14.0


func _hold_shape(next: Shape) -> void:
	if shape == next:
		return
	shape = next
	_paint_form(next)
	Juice.phase_flicker(visual)


func _begin_walk_hit() -> void:
	kit["attack"] = "light"
	_start_telegraph()
	telegraph = maxf(telegraph, 0.18)


func _begin_stoop() -> void:
	kit["attack"] = "heavy"
	_start_telegraph()
	telegraph = maxf(telegraph, 0.28)
	Juice.gape(global_position)


func _begin_lunge() -> void:
	_hold_shape(Shape.LUNGE)
	kit["attack"] = "blade"
	_start_telegraph()
	telegraph = maxf(telegraph, 0.34)
	_gape_open = true
	Juice.gape(global_position)
	Juice.yellow_stare(global_position)


func _begin_burst() -> void:
	_hold_shape(Shape.BURST)
	_burst_t = 0.42
	_burst_cd = 2.6
	_stutter = 0.08
	Juice.shout("LEARNED FAST")
	Juice.phase_flicker(visual)
	Juice.play("res://assets/audio/sfx_crawl.wav" if ResourceLoader.exists("res://assets/audio/sfx_crawl.wav") else "res://assets/audio/dash.wav")


func _land_shape_hit() -> void:
	var atk := str(kit.get("attack", "light"))
	var reach := 52.0
	var tall := 78.0
	match shape:
		Shape.STOOP:
			reach = 64.0
			tall = 70.0
		Shape.CRAWL:
			reach = 70.0
			tall = 48.0
			atk = "slide"
		Shape.LUNGE, Shape.BURST:
			reach = 78.0
			tall = 86.0
			atk = "heavy"
		_:
			atk = "light"
	recover = 0.38 if shape != Shape.LUNGE else 0.52
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter:
			var f: Fighter = n
			if f.downed:
				continue
			if absf(f.global_position.x - global_position.x) < reach and absf(f.global_position.y - global_position.y) < tall:
				f.take_hit(atk, self)


func _tick_wrong(delta: float) -> void:
	if visual == null:
		return
	# Form never fully holds.
	if _head:
		_head.rotation = sin(_jerk * 7.4) * 0.28 + (0.4 if shape == Shape.CRAWL else 0.0)
		if randf() < 0.012:
			_head.rotation += (1.0 if randf() < 0.5 else -1.0) * 0.55
	if _eye_l:
		_eye_l.modulate = Color(1.2, 1.1, 0.2)
		_eye_r.modulate = Color(1.15, 1.05, 0.15) if _eye_r else Color.WHITE
	if _phase_cd <= 0.0:
		_phase_cd = randf_range(0.7, 1.6)
		Juice.phase_flicker(visual)
	if _foot and shape == Shape.WALK:
		_foot.position.y = -absf(sin(_jerk * 4.6)) * 12.0
	_form_hold += delta
	if _form_hold > 2.8 and shape != Shape.DOG and randf() < 0.008:
		# Learning a new animal looks wrong — a one-frame dog ghost.
		Juice.phase_flicker(visual)


func take_hit(kind: String, from: Node) -> void:
	if dormant:
		_slip()
	if _gape_open and from is Fighter and (kind == "snap" or kind == "special" or kind == "heavy"):
		Juice.shout(Copy.UNMASK)
		Juice.gape(global_position)
		hp = maxi(1, hp - 18)
		_gape_open = false
		FamilyProfile.mark_unmask()
	super.take_hit(kind, from)


func _on_dead() -> void:
	FamilyProfile.mark_skinwalker()
	Juice.unlock_logo(Copy.THAT_WALKER, "You asked a hundred times. He finally said it.", "FILED")
	super._on_dead()
