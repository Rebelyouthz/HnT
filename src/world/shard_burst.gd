class_name ShardBurst
extends Node2D

## A prop's last moment: its own sprite cut into jagged pieces that fly off
## the blow, spin, bounce on the street at their own depth and lie there as
## debris before fading. Pieces keep the damage material (cracked, sooted).

var _bits: Array[Dictionary] = []
var _t := 0.0


static func shatter(host: Node, art: CanvasItem, feet: Vector2, dir: float, power: float = 1.0) -> void:
	if host == null or art == null:
		return
	var tex: Texture2D = null
	var scl := Vector2.ONE
	var top_left := Vector2.ZERO
	if art is Sprite2D:
		var s := art as Sprite2D
		tex = s.texture
		scl = s.global_scale
		top_left = s.global_position + (Vector2.ZERO if not s.centered else -Vector2(tex.get_size()) * 0.5 * scl)
	elif art is AnimatedSprite2D:
		var a := art as AnimatedSprite2D
		tex = a.sprite_frames.get_frame_texture(a.animation, a.frame)
		scl = a.global_scale
		top_left = a.global_position - Vector2(tex.get_size()) * 0.5 * scl
	if tex == null:
		return
	var b := ShardBurst.new()
	b.z_index = 3
	host.add_child(b)
	var size := tex.get_size()
	var cols := 4
	var rows := 4
	var cw := size.x / float(cols)
	var ch := size.y / float(rows)
	for r in rows:
		for c in cols:
			var piece := Sprite2D.new()
			var at := AtlasTexture.new()
			at.atlas = tex
			# Jitter the cut so pieces are not a neat grid.
			var jx := randf_range(-0.15, 0.15) * cw
			var jy := randf_range(-0.15, 0.15) * ch
			at.region = Rect2(maxf(0.0, c * cw + jx), maxf(0.0, r * ch + jy), cw * randf_range(0.9, 1.2), ch * randf_range(0.9, 1.2))
			piece.texture = at
			piece.scale = scl
			piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if art.material != null:
				piece.material = art.material.duplicate()
				if piece.material is ShaderMaterial:
					(piece.material as ShaderMaterial).set_shader_parameter("damage", 0.75)
			var centre := top_left + (at.region.position + at.region.size * 0.5) * scl
			piece.global_position = centre
			b.add_child(piece)
			var out := (centre - (feet + Vector2(0, -size.y * scl.y * 0.5))).normalized()
			var v := Vector2(dir * randf_range(60.0, 200.0), randf_range(-260.0, -90.0)) * power + out * 60.0
			b._bits.append({"n": piece, "v": v, "spin": randf_range(-12.0, 12.0),
				"floor": feet.y + randf_range(-6.0, 10.0), "rest": false, "half": at.region.size.y * scl.y * 0.3})


func _process(delta: float) -> void:
	_t += delta
	for bit in _bits:
		if bit["rest"]:
			continue
		var n: Sprite2D = bit["n"]
		var v: Vector2 = bit["v"]
		v.y += 980.0 * delta
		n.position += v * delta
		n.rotation += float(bit["spin"]) * delta
		var fl := float(bit["floor"]) - float(bit["half"])
		if n.position.y >= fl and v.y > 0.0:
			n.position.y = fl
			if v.y > 140.0:
				v = Vector2(v.x * 0.5, -v.y * 0.3)
				bit["spin"] = float(bit["spin"]) * 0.5
			else:
				bit["rest"] = true
				# Lie flat-ish on the ground.
				n.rotation = snappedf(n.rotation, PI * 0.5) + randf_range(-0.2, 0.2)
		bit["v"] = v
	if _t > 9.0:
		modulate.a = maxf(0.0, 1.0 - (_t - 9.0) / 1.5)
		if _t > 10.5:
			queue_free()
