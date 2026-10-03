class_name XpOrb
extends Node2D

## Insight gems (XP) that burst out of a beaten enemy, bounce, bob and glow,
## then get pulled in once a fighter is inside his magnet radius (which
## grows with the run's level and the XP MAGNET upgrade). Elites drop a big
## blue one.

var amount := 4
var big := false
var floor_y := 500.0
var _v := Vector2.ZERO
var _t := 0.0
var _landed := false
var _pull: Fighter
var _sp: Sprite2D
var _glow: PointLight2D


static func burst(host: Node, at: Vector2, total: int, elite: bool = false) -> void:
	if host == null or total <= 0:
		return
	var n := clampi(total / 4, 1, 6)
	var each := maxi(1, total / n)
	for i in n:
		var o := XpOrb.new()
		o.amount = each if i < n - 1 else total - each * (n - 1)
		o.big = elite and i == 0
		o.floor_y = clampf(at.y, 432.0, 600.0) + randf_range(-6.0, 6.0)
		o.position = Vector2(at.x, o.floor_y - 26.0)
		o._v = Vector2(randf_range(-110.0, 110.0), randf_range(-260.0, -150.0))
		host.add_child(o)


func _ready() -> void:
	z_index = 5
	add_to_group("xp_orbs")
	_sp = Sprite2D.new()
	_sp.texture = load("res://assets/sprites/loot/xp_gem_big.png" if big else "res://assets/sprites/loot/xp_gem.png")
	_sp.scale = Vector2(0.28, 0.28)
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.texture_filter = SpriteBook.world_filter()
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_sp.material = m
	add_child(_sp)
	_glow = PointLight2D.new()
	_glow.texture = LightRig.radial_tex()
	_glow.texture_scale = 0.22 if not big else 0.32
	_glow.color = Color(0.35, 1.0, 0.55) if not big else Color(0.4, 0.85, 1.0)
	_glow.energy = 0.8
	_glow.position = Vector2(0, -6)
	add_child(_glow)


func _process(delta: float) -> void:
	_t += delta
	if _pull != null:
		if not is_instance_valid(_pull):
			_pull = null
			return
		var target := _pull.global_position + Vector2(0, -26)
		var spd := 260.0 + 520.0 * minf(_t, 1.5)
		global_position = global_position.move_toward(target, spd * delta)
		if global_position.distance_to(target) < 8.0:
			_take()
		return
	if not _landed:
		_v.y += 900.0 * delta
		position += _v * delta
		if position.y >= floor_y and _v.y > 0.0:
			position.y = floor_y
			if absf(_v.y) > 120.0:
				_v = Vector2(_v.x * 0.5, -_v.y * 0.35)
			else:
				_landed = true
				_t = 0.0
	else:
		_sp.position.y = -2.0 - 2.0 * sin(_t * 4.0)
		_glow.energy = 0.7 + 0.25 * sin(_t * 6.0)
	_sp.rotation = 0.15 * sin(_t * 3.0)
	# Magnet: the nearest fighter whose radius reaches.
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var f := n as Fighter
			if global_position.distance_to(f.global_position) < f.xp_magnet():
				_pull = f
				_t = 0.0
				break
	if _t > 40.0 and _landed:
		queue_free()


func _take() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_xp"):
		rs.add_xp(amount)
	Juice.popup_number(global_position, "+%d XP" % amount, Color(0.5, 1.0, 0.6))
	Mixer.play_sfx("res://assets/audio/ui_click.wav", randf_range(1.6, 2.0), -12.0)
	queue_free()
