class_name AmbientProp
extends Node2D

## Living street motion. Lamps breathe. Bystanders already walk themselves.


static func lamp(host: Node, at: Vector2, z: int = 3) -> void:
	if SpriteBook.has_who("lamp"):
		var n := AmbientProp.new()
		n.z_index = z
		n.global_position = at
		n.add_child(SpriteBook.make_anim("lamp"))
		host.add_child(n)
		return
	SpriteBook.stamp(host, "lamp", at, z)
