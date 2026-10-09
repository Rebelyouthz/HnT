class_name AmbientProp
extends Node2D

## Street props drawn from sprite clips. Lamps stand still (their clip was
## cut from video: every frame a few texels off, so the post wobbled and
## changed size); the lamp light itself flickers in LightRig.


static func lamp(host: Node, at: Vector2, z: int = 3) -> void:
	place(host, "lamp", at, z)


## Measured against the heroes: a cone comes to the kid's knee, a drum to
## his hip, a sodium lamp well over everyone.
const SIZE := {"cone": 0.55, "drum": 0.7, "barrier": 0.75, "sodium_lamp": 2.6}


static func place(host: Node, who: String, at: Vector2, z: int = 3) -> void:
	if SpriteBook.has_who(who):
		var n := AmbientProp.new()
		n.z_index = z
		n.global_position = at
		var a := SpriteBook.make_anim(who)
		n.add_child(a)
		if who == "lamp":
			a.stop()
			a.frame = 4
			n.add_to_group("street_lamps")
			# A street lamp stands well over a grown man.
			n.scale = Vector2(2.9, 2.9)
		elif SIZE.has(who):
			n.scale = Vector2(SIZE[who], SIZE[who])
		host.add_child(n)
		return
	SpriteBook.stamp(host, who, at, z)
