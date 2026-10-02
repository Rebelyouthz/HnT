class_name DogBuddy
extends Node2D

## Rufus, the stray from Dock Street. Once he's joined he runs at the son's
## heel every night, barks at whoever comes close and goes for their legs:
## a bite stings, staggers them, and sometimes trips them flat.

var target: Node2D
var _sp: Sprite2D
var _stand: Texture2D
var _run: Texture2D
var _cd := 0.0
var _t := 0.0
var _bite_t := 0.0
var _victim: Node2D


static func joined() -> bool:
	return bool(FamilyProfile.data.get("dog_rufus", false))


func _ready() -> void:
	z_index = 4
	add_to_group("crew")
	_stand = load("res://assets/sprites/loot/dog.png")
	_run = load("res://assets/sprites/loot/dog_run.png")
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a) * 10.0, sin(a) * 2.2))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.4)
	add_child(sh)
	_sp = Sprite2D.new()
	_sp.texture = _stand
	_sp.scale = Vector2.ONE * SpriteBook.DRAW_SCALE * 0.95
	_sp.offset = Vector2(0, -float(_stand.get_height()) * 0.5)
	_sp.texture_filter = SpriteBook.world_filter()
	add_child(_sp)


func _process(delta: float) -> void:
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	if target == null or not is_instance_valid(target):
		for n in get_tree().get_nodes_in_group("players"):
			target = n
			break
		if target == null:
			return
	# Lunge in progress.
	if _bite_t > 0.0:
		_bite_t -= delta
		if _victim and is_instance_valid(_victim):
			global_position = global_position.lerp(_victim.global_position + Vector2(-8.0 * signf(_victim.global_position.x - global_position.x), 2.0), 0.3)
		return
	var foe := _nearest_foe()
	if foe and _cd <= 0.0 and foe.global_position.distance_to(global_position) < 90.0:
		_bite(foe)
		return
	var face := float((target as Node2D).get("facing")) if target.get("facing") != null else 1.0
	var want := target.global_position + Vector2(-26.0 * face, 6.0)
	var d := want - global_position
	var moving := d.length() > 6.0
	if moving:
		global_position += d.normalized() * minf(d.length(), (160.0 + d.length() * 2.0) * delta)
		_sp.flip_h = d.x < 0.0
	_sp.texture = _run if moving and d.length() > 14.0 else _stand
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.position.y = -absf(sin(_t * 14.0)) * 2.5 if _sp.texture == _run else 0.0


func _nearest_foe() -> Node2D:
	var best: Node2D = null
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and is_instance_valid(n) and (n as Punk).hp > 0:
			var e := n as Node2D
			if best == null or e.global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
				best = e
	return best


func _bite(foe: Node2D) -> void:
	_cd = 2.6
	_bite_t = 0.25
	_victim = foe
	_sp.texture = _run
	_sp.flip_h = foe.global_position.x < global_position.x
	Juice.play("res://assets/audio/dog_bark.wav" if ResourceLoader.exists("res://assets/audio/dog_bark.wav") else "res://assets/audio/whoosh_light.wav")
	Juice.popup_number(global_position + Vector2(0, -20), "WOOF", Palette.LEMON)
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if not is_instance_valid(foe) or not (foe is Punk):
			return
		var p := foe as Punk
		p.take_hit("slide" if randf() < 0.3 else "light", self)
		var blood := get_tree().get_first_node_in_group("blood_sim")
		if blood:
			blood.hit(p, "low", signf(p.global_position.x - global_position.x), 0.3, 0.0)
	)
