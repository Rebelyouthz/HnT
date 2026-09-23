class_name AmbientProp
extends Node2D

## Living street motion. Lamps breathe. Bystanders already walk themselves.


static func lamp(host: Node, at: Vector2, z: int = 3) -> void:
	place(host, "lamp", at, z)


static func place(host: Node, who: String, at: Vector2, z: int = 3) -> void:
	if SpriteBook.has_who(who):
		var n := AmbientProp.new()
		n.z_index = z
		n.global_position = at
		n.add_child(SpriteBook.make_anim(who))
		host.add_child(n)
		return
	SpriteBook.stamp(host, who, at, z)
