class_name XpGem
extends Area2D

## Survivor XP crystal. It POPS out of the body like a real object: thrown up
## and out with a height of its own (shadow on the floor, smaller the higher
## it is), tumbling in every axis (a flip round its long axis plus a spin),
## bouncing twice and falling over onto its side with a glint. Then it waits
## on the floor until a hero's pickup radius pulls it in (lifting off again).
## Colour climbs with the XP it holds: green, blue, purple, gold.

const G := 980.0

var amount := 4
## Ground position is the node's position; height above it in _h (up < 0).
var _h := -26.0
var _vh := -320.0
var _v := Vector2.ZERO
var _bounces := 0
var _landed := false
var _flip := 0.0
var _flip_v := 12.0
var _spin_v := 6.0
var _lie := 0.0
var _t := 0.0
var _art: Node2D
var _sp: Sprite2D
var _glow: Sprite2D
var _shadow: Polygon2D


## Thrown out of a body standing at `at` (feet).
static func pop(host: Node, at: Vector2, amt: int) -> XpGem:
	var g := XpGem.new()
	g.amount = amt
	g.position = at + Vector2(randf_range(-6, 6), randf_range(-4, 4))
	var a := randf() * TAU
	g._v = Vector2(cos(a), sin(a) * 0.7) * randf_range(50.0, 130.0)
	g._vh = -randf_range(260.0, 380.0)
	g._h = -randf_range(22.0, 34.0)
	g._flip_v = randf_range(9.0, 16.0) * (1.0 if randf() < 0.5 else -1.0)
	g._spin_v = randf_range(-14.0, 14.0)
	host.add_child.call_deferred(g)
	return g


func _ready() -> void:
	add_to_group("xp_gems")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10
	cs.shape = c
	add_child(cs)
	z_index = 3
	_shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var ang := TAU * float(i) / 12.0
		pts.append(Vector2(cos(ang) * 6.0, sin(ang) * 2.2))
	_shadow.polygon = pts
	_shadow.color = Color(0, 0, 0, 0.45)
	add_child(_shadow)
	_art = Node2D.new()
	add_child(_art)
	_glow = Sprite2D.new()
	_glow.texture = LightRig.radial_tex()
	_glow.scale = Vector2.ONE * (34.0 / float(_glow.texture.get_width()))
	Blockout.add_glow(_glow)
	_art.add_child(_glow)
	_sp = Sprite2D.new()
	var big := amount >= 18
	_sp.texture = load("res://assets/sprites/loot/xp_gem_big.png" if big else "res://assets/sprites/loot/xp_gem.png")
	_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sp.scale = Vector2.ONE * (0.32 if big else 0.36)
	_art.add_child(_sp)
	_tint()
	body_entered.connect(_eat)


func _tint() -> void:
	var col := Color(0.55, 1.0, 0.65)
	if amount >= 60:
		col = Color(1.0, 0.82, 0.3)
	elif amount >= 25:
		col = Color(0.85, 0.5, 1.0)
	elif amount >= 10:
		col = Color(0.45, 0.75, 1.0)
	if _sp:
		_sp.self_modulate = Color.WHITE if amount < 10 else col.lightened(0.3)
	if _glow:
		_glow.modulate = Color(col.r, col.g, col.b, 0.55)
	var k := clampf(1.0 + float(amount - 4) / 40.0, 1.0, 1.8)
	if _art:
		_art.scale = Vector2(k, k)


## Merged gems (the floor is capped) grow and change colour.
func refresh_tint() -> void:
	_tint()


func _physics_process(delta: float) -> void:
	_t += delta
	var best := _magnet()
	if best != null and (_landed or _t > 0.35):
		var to := best.global_position + Vector2(0, -6) - global_position
		var spd := (420.0 + best.magnet_r) * (1.0 + _t * 0.2)
		global_position += to.normalized() * minf(to.length(), spd * delta)
		# Lifts off the floor and stands up on the way in.
		_h = lerpf(_h, -14.0, 1.0 - exp(-10.0 * delta))
		_lie = lerpf(_lie, 0.0, 1.0 - exp(-12.0 * delta))
		_flip += 12.0 * delta
		_art.rotation = _lie
	elif not _landed:
		_air(delta)
	else:
		# On the floor: settles flat-on and breathes a little glow.
		_flip = lerpf(_flip, round(_flip / PI) * PI, 1.0 - exp(-6.0 * delta))
		_glow.modulate.a = 0.35 + 0.2 * sin(_t * 3.0 + position.x)
	_art.position.y = _h
	var sx := cos(_flip)
	var base := absf(_sp.scale.y)
	_sp.scale.x = base * (sx if absf(sx) > 0.12 else 0.12 * (1.0 if sx >= 0.0 else -1.0))
	# Turned edge-on or away it reads darker, like the far facet.
	var v := 0.7 + 0.3 * absf(sx)
	_sp.modulate = Color(v, v, v)
	var air := clampf(-_h / 60.0, 0.0, 1.0)
	_shadow.scale = Vector2.ONE * (1.0 - air * 0.5)
	_shadow.color.a = 0.45 - air * 0.25


func _air(delta: float) -> void:
	_vh += G * delta
	_h += _vh * delta
	position += _v * delta
	_v = _v.move_toward(Vector2.ZERO, 40.0 * delta)
	_flip += _flip_v * delta
	_art.rotation += _spin_v * delta
	if _h >= 0.0 and _vh > 0.0:
		_h = 0.0
		if _bounces < 2 and _vh > 120.0:
			_bounces += 1
			_vh = -_vh * 0.42
			_v *= 0.55
			_flip_v *= 0.6
			_spin_v *= 0.5
			Mixer.play_sfx("res://assets/audio/ui_click.wav", randf_range(2.4, 2.9), -24.0)
		else:
			_landed = true
			_v = Vector2.ZERO
			# Falls over onto its side.
			_lie = (PI * 0.5 - randf_range(0.1, 0.35)) * (1.0 if randf() < 0.5 else -1.0)
			var tw := _art.create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(_art, "rotation", _lie, 0.28)
			_glint()


func _glint() -> void:
	var s := Sprite2D.new()
	s.texture = LightRig.radial_tex()
	s.scale = Vector2.ONE * (8.0 / float(s.texture.get_width()))
	s.position = Vector2(randf_range(-3, 3), -4)
	Blockout.add_glow(s)
	_art.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", s.scale * 4.0, 0.12)
	tw.tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_callback(s.queue_free)


func _magnet() -> Fighter:
	var best: Fighter = null
	var best_d := 9999.0
	var srun := SurviveRun.get_run(get_tree())
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d: float = global_position.distance_to((n as Node2D).global_position)
			var reach: float = (n as Fighter).magnet_r
			if srun:
				reach *= srun.pickup_mul()
			if d < best_d and d < reach:
				best_d = d
				best = n
	return best


func _eat(b: Node) -> void:
	if not (b is Fighter) or (not _landed and _t < 0.3):
		return
	var rs := get_tree().get_first_node_in_group("run_state")
	var amt := amount
	if FamilyProfile.has_cbt("group_rate"):
		amt += 2
	var srun := SurviveRun.get_run(get_tree())
	if srun:
		srun.add_xp(amt)
	elif rs and rs.has_method("add_xp"):
		rs.add_xp(amt)
	Juice.keep_combo()
	if amt >= 10:
		Juice.popup_number(global_position + Vector2(0, -20), "+%d XP" % amt, Color(_glow.modulate, 1.0))
	Mixer.play_sfx("res://assets/audio/ui_click.wav", randf_range(1.6, 2.0) + minf(0.6, float(amt) / 80.0), -14.0)
	var hud := get_tree().get_first_node_in_group("mission_hud")
	var horde := get_tree().get_first_node_in_group("horde")
	if hud and hud.has_method("complete_side") and horde and int(horde.gems) >= 8:
		hud.complete_side()
	# A little burst where it was swallowed.
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, -12)
	p.one_shot = true
	p.emitting = true
	p.amount = 8
	p.lifetime = 0.3
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2.ZERO
	p.color = Color(_glow.modulate, 1.0)
	get_parent().add_child(p)
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)
	queue_free()
