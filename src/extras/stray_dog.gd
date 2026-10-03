class_name StrayDog
extends Node2D

## Rufus waits by the bins on Dock Street. Walk up to him and he's yours:
## from then on he runs with the family every night (DogBuddy).

var _sp: Sprite2D
var _t := 0.0
var _done := false


func _ready() -> void:
	z_index = 3
	_sp = Sprite2D.new()
	_sp.texture = load("res://assets/sprites/loot/dog.png")
	_sp.scale = Vector2.ONE * SpriteBook.DRAW_SCALE * 0.95
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.flip_h = true
	_sp.texture_filter = SpriteBook.world_filter()
	add_child(_sp)
	var l := Label.new()
	l.text = "?"
	l.position = Vector2(-4, -44)
	l.scale = Vector2(0.5, 0.5)
	UiKit.apply_label(l, 22, UiKit.GOLD)
	add_child(l)


func _process(delta: float) -> void:
	_t += delta
	_sp.position.y = -absf(sin(_t * 3.0)) * 1.0
	if _done:
		return
	for n in get_tree().get_nodes_in_group("players"):
		if n is Node2D and (n as Node2D).global_position.distance_to(global_position) < 40.0:
			_join(n as Node2D)
			return


func _join(by: Node2D) -> void:
	_done = true
	FamilyProfile.data["dog_rufus"] = true
	FamilyProfile.save()
	Juice.unlock_logo("RUFUS", "A stray with a red bandana. He bites thugs' ankles now.", "COMPANION  ·  JOINED")
	Juice.play("res://assets/audio/dog_bark.wav" if ResourceLoader.exists("res://assets/audio/dog_bark.wav") else "res://assets/audio/cling_ok.wav")
	var buddy := DogBuddy.new()
	buddy.global_position = global_position
	buddy.target = by
	get_parent().add_child(buddy)
	queue_free()
