class_name WeaponPickup
extends Area2D

## A weapon lying on the street. Walking over it shows PICK UP (or SWAP when
## the hands are full); the THROW button (LT / U) takes it, dropping what you
## held in its place. Nothing is picked up by just walking past.

var kind := "pipe"
var _prompt: Label


func _ready() -> void:
	add_to_group("pickups")
	add_to_group("weapon_pickups")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	# Generous in depth: the lane is wide, and taking it is a button press
	# now, so standing roughly over it has to be enough.
	r.size = Vector2(44, 44)
	cs.shape = r
	add_child(cs)
	var p := Polygon2D.new()
	match kind:
		"knife":
			p.color = Color(0.82, 0.84, 0.9)
			p.polygon = PackedVector2Array([Vector2(-16, -3), Vector2(16, 0), Vector2(-16, 3)])
		"pistol":
			p.color = Color(0.22, 0.22, 0.24)
			p.polygon = PackedVector2Array([Vector2(-14, -6), Vector2(16, -4), Vector2(16, 4), Vector2(-10, 6), Vector2(-18, 2)])
		"nailgun":
			p.color = Color(0.28, 0.24, 0.18)
			p.polygon = PackedVector2Array([Vector2(-16, -8), Vector2(18, -5), Vector2(18, 5), Vector2(-12, 8), Vector2(-20, 2)])
		"board":
			p.color = Color(0.55, 0.38, 0.18)
			p.polygon = PackedVector2Array([Vector2(-24, -5), Vector2(24, -5), Vector2(24, 5), Vector2(-24, 5)])
		"chain":
			p.color = Color(0.62, 0.64, 0.68)
			p.polygon = PackedVector2Array([Vector2(-28, -3), Vector2(28, -3), Vector2(26, 3), Vector2(-26, 3)])
		"crowbar":
			p.color = Color(0.42, 0.18, 0.14)
			p.polygon = PackedVector2Array([Vector2(-22, -5), Vector2(18, -4), Vector2(22, 2), Vector2(14, 6), Vector2(-22, 5)])
		"clipboard":
			p.color = Color(0.88, 0.82, 0.7)
			p.polygon = PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(12, 12), Vector2(-12, 12)])
		"stapler":
			p.color = Color(0.72, 0.22, 0.18)
			p.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(12, -8), Vector2(12, 6), Vector2(-10, 6)])
		"invoice_star":
			p.color = Palette.EDGE
			p.polygon = PackedVector2Array([Vector2(0, -14), Vector2(6, -4), Vector2(14, 0), Vector2(6, 4), Vector2(0, 14), Vector2(-6, 4), Vector2(-14, 0), Vector2(-6, -4)])
		"can":
			p.color = Color(0.82, 0.22, 0.18)
			p.polygon = PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(8, 10), Vector2(-8, 10)])
		"envelope":
			p.color = Color(0.92, 0.9, 0.82)
			p.polygon = PackedVector2Array([Vector2(-14, -8), Vector2(14, -8), Vector2(14, 8), Vector2(-14, 8)])
		_:
			p.color = Color(0.45, 0.32, 0.2)
			p.polygon = PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(20, 4), Vector2(-20, 4)])
	add_child(p)
	p.color = Rarity.color(Rarity.of_pickup(kind))
	# Weapons lie on the street at hand size: the held / gun art first (the
	# old living pickup sprites were drawn about three times too big).
	var has_art := ResourceLoader.exists("res://assets/sprites/held/%s.png" % kind) or ResourceLoader.exists("res://assets/sprites/guns/%s.png" % kind)
	if not has_art and SpriteBook.attach_living(self, kind):
		p.visible = false
	elif ResourceLoader.exists("res://assets/sprites/held/%s.png" % kind):
		# New melee lies on the street as its held art, glinting.
		p.visible = false
		var hw := Sprite2D.new()
		hw.texture = load("res://assets/sprites/held/%s.png" % kind)
		hw.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE) * 1.3
		hw.position = Vector2(0, -4)
		hw.rotation = -0.18
		hw.texture_filter = SpriteBook.world_filter()
		add_child(hw)
		var tw2 := hw.create_tween().set_loops()
		tw2.tween_property(hw, "position:y", -7.0, 0.7).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(hw, "position:y", -4.0, 0.7).set_trans(Tween.TRANS_SINE)
	elif ResourceLoader.exists("res://assets/sprites/guns/%s.png" % kind):
		# Hand guns lie on the street as their own art, glinting.
		var g := Sprite2D.new()
		g.texture = load("res://assets/sprites/guns/%s.png" % kind)
		g.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE) * 1.3
		g.position = Vector2(0, -4)
		g.rotation = -0.12
		g.texture_filter = SpriteBook.world_filter()
		add_child(g)
		var tw := g.create_tween().set_loops()
		tw.tween_property(g, "position:y", -7.0, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(g, "position:y", -4.0, 0.7).set_trans(Tween.TRANS_SINE)
		p.visible = false
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", UiKit.pixel_font())
	_prompt.add_theme_font_size_override("font_size", 11)
	_prompt.add_theme_color_override("font_color", UiKit.GOLD)
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = Vector2(120, 14)
	_prompt.position = Vector2(-60, -40)
	_prompt.z_index = 20
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var f := _standing()
	_prompt.visible = f != null
	if f != null:
		var key := "LT" if not Input.get_connected_joypads().is_empty() else "U"
		_prompt.text = "%s  %s %s" % [key, "SWAP" if f.pickup != "" else "PICK UP", kind.to_upper().replace("_", " ")]


## A hero standing on it (nearest first), or null.
func _standing() -> Fighter:
	for b in get_overlapping_bodies():
		if b is Fighter and not (b as Fighter).downed:
			return b as Fighter
	return null


## The weapon this hero stands on, for the THROW button.
static func under(f: Fighter) -> WeaponPickup:
	for n in f.get_tree().get_nodes_in_group("weapon_pickups"):
		var w := n as WeaponPickup
		if w != null and is_instance_valid(w) and not w.is_queued_for_deletion() and w.overlaps_body(f):
			return w
	return null


func take(f: Fighter) -> void:
	# Hands full: the old one goes down where the new one lay.
	if f.pickup != "":
		var drop := WeaponPickup.new()
		drop.kind = f.pickup
		drop.global_position = global_position + Vector2(0, 2)
		get_parent().call_deferred("add_child", drop)
		f.pickup = ""
		var g: Variant = f.get("_gun")
		if g is CanvasItem and is_instance_valid(g):
			(g as CanvasItem).visible = false
	f.equip_pickup(kind)
	var rarity := Rarity.of_pickup(kind)
	Juice.play("res://assets/audio/shop.wav")
	Juice.popup_number(global_position, "%s  %s" % [kind.to_upper(), Rarity.label(rarity)], Rarity.color(rarity))
	Rarity.juice(rarity, kind.to_upper())
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(f.role, 16 + Rarity.rank(rarity) * 8, "pickup")
	queue_free()
