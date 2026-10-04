class_name Bystander
extends CharacterBody2D

## Crowd juice. They scatter. They are not XP. They are witnesses with invoices.


var home := Vector2.ZERO
var spook := 0.0
var _spoke := false
var _female := randf() < 0.45
var visual: Node2D


static func place(host: Node, at: Vector2) -> Bystander:
	var b := Bystander.new()
	b.global_position = at
	host.add_child(b)
	return b


func _ready() -> void:
	add_to_group("bystanders")
	collision_layer = 0
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	home = global_position
	visual = Node2D.new()
	add_child(visual)
	if SpriteBook.has_who("bystander"):
		var a := SpriteBook.make_anim("bystander")
		visual.add_child(a)
	else:
		var coat := Polygon2D.new()
		coat.color = Color(0.28, 0.26, 0.32, 0.92)
		coat.polygon = PackedVector2Array([
			Vector2(-10, -36), Vector2(10, -36), Vector2(12, 0), Vector2(-12, 0)
		])
		visual.add_child(coat)
		var head := Polygon2D.new()
		head.color = Palette.TEXT.darkened(0.25)
		head.polygon = PackedVector2Array([
			Vector2(-8, -52), Vector2(8, -52), Vector2(7, -36), Vector2(-7, -36)
		])
		visual.add_child(head)


func _physics_process(delta: float) -> void:
	# Bystanders react out loud the first time a fight comes close.
	if not _spoke:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node2D and (e as Node2D).global_position.distance_to(global_position) < 160.0:
				_spoke = true
				VoBank.line("bystander_f" if _female else "bystander", "react", 0.7)
				break
	var scare := Vector2.ZERO
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d: Vector2 = global_position - (n as Node2D).global_position
			if d.length() < 140.0:
				scare += d.normalized() * 180.0
				spook = 1.4
	if spook > 0.0:
		spook -= delta
		velocity = scare
		visual.modulate = Color(1.15, 0.9, 0.85)
	else:
		velocity = (home - global_position) * 1.4
		visual.modulate = Color.WHITE
	move_and_slide()
	global_position.y = clampf(global_position.y, 430.0, 520.0)
