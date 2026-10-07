class_name XpGem
extends Area2D

var amount := 4
var _blob: Polygon2D


func _ready() -> void:
	add_to_group("xp_gems")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9
	cs.shape = c
	add_child(cs)
	_blob = Polygon2D.new()
	_blob.color = Color(0.45, 0.92, 0.62, 0.95)
	_blob.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)
	])
	Blockout.add_glow(_blob)
	add_child(_blob)
	body_entered.connect(_eat)


func _physics_process(delta: float) -> void:
	var best: Fighter = null
	var best_d := 9999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d: float = global_position.distance_to((n as Node2D).global_position)
			var reach: float = (n as Fighter).magnet_r
			var srun := SurviveRun.get_run(get_tree())
			if srun:
				reach *= srun.pickup_mul()
			if d < best_d and d < reach:
				best_d = d
				best = n
	if best:
		global_position = global_position.move_toward(best.global_position + Vector2(0, -20), (420.0 + best.magnet_r) * delta)
	if _blob:
		_blob.rotation += delta * 4.0
		# Merged gems grow instead of piling up.
		var k := clampf(1.0 + float(amount - 4) / 30.0, 1.0, 2.2)
		_blob.scale = Vector2(k, k)


func _eat(b: Node) -> void:
	if not (b is Fighter):
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
	Juice.popup_number(global_position, "+%d XP" % amt, Palette.READY)
	Juice.play("res://assets/audio/ui_click.wav")
	var hud := get_tree().get_first_node_in_group("mission_hud")
	var horde := get_tree().get_first_node_in_group("horde")
	if hud and hud.has_method("complete_side") and horde and int(horde.gems) >= 8:
		hud.complete_side()
	queue_free()
