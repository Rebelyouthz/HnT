class_name WeaponPickup
extends Area2D

## A weapon lying on the street. Walking over it shows PICK UP (or SWAP when
## the hands are full); X + Y together (J + K) takes it, dropping what you
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
	_make_bubble()


## A small speech bubble over the weapon when a hero comes close: its
## picture and a little down arrow, bobbing. Says "this can be picked up"
## without a word; the X+Y line appears only when standing on it.
var _bubble: Node2D


func _make_bubble() -> void:
	_bubble = Node2D.new()
	_bubble.z_index = 19
	_bubble.position = Vector2(0, -34)
	_bubble.modulate.a = 0.0
	add_child(_bubble)
	var bg := Polygon2D.new()
	var pts := PackedVector2Array()
	# Rounded box 26 x 18 with a tail at the bottom centre.
	for i in 24:
		var ang := TAU * float(i) / 24.0
		var c := Vector2(cos(ang), sin(ang))
		pts.append(Vector2(clampf(c.x * 1.6, -1.0, 1.0) * 13.0, clampf(c.y * 1.6, -1.0, 1.0) * 9.0) + c * 1.5)
	bg.polygon = pts
	bg.color = Color(0.97, 0.95, 0.88, 0.94)
	_bubble.add_child(bg)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(-3, 9), Vector2(3, 9), Vector2(0, 14)])
	tail.color = bg.color
	_bubble.add_child(tail)
	var path := "res://assets/sprites/held/%s.png" % kind
	if not ResourceLoader.exists(path):
		path = "res://assets/sprites/guns/%s.png" % kind
	if ResourceLoader.exists(path):
		var ic := Sprite2D.new()
		ic.texture = load(path)
		var tex_w := float(ic.texture.get_width())
		var k := minf(20.0 / maxf(1.0, tex_w), 12.0 / maxf(1.0, float(ic.texture.get_height())))
		ic.scale = Vector2(k, k)
		ic.position = Vector2(-2, -1)
		ic.rotation = -0.3
		ic.texture_filter = SpriteBook.world_filter()
		_bubble.add_child(ic)
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(7, 1), Vector2(13, 1), Vector2(10, 6)])
	arrow.color = UiKit.GOLD.darkened(0.25)
	_bubble.add_child(arrow)


func _process(delta: float) -> void:
	var f := _standing()
	_prompt.visible = f != null
	if _bubble:
		var near := 9999.0
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and not (n as Fighter).downed:
				near = minf(near, (n as Node2D).global_position.distance_to(global_position))
		var want := 1.0 if near < 120.0 and f == null else 0.0
		_bubble.modulate.a = move_toward(_bubble.modulate.a, want, delta * 4.0)
		_bubble.position.y = -34.0 + sin(float(Time.get_ticks_msec()) / 260.0) * 1.5
	if f != null:
		var key := "X+Y" if PadRouter.pad_prompts() else "J+K"
		_prompt.text = "%s  %s %s" % [key, "SWAP" if f.pickup != "" else "PICK UP", kind.to_upper().replace("_", " ")]


## A hero standing on it (nearest first), or null.
func _standing() -> Fighter:
	for b in get_overlapping_bodies():
		if b is Fighter and not (b as Fighter).downed:
			return b as Fighter
	return null


## The weapon this hero stands on (X + Y picks it up).
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
	# The weapon's own picture pops over the spot, in its rarity colour.
	var wtex: Texture2D = load("res://assets/sprites/held/%s.png" % kind) if ResourceLoader.exists("res://assets/sprites/held/%s.png" % kind) else null
	Juice.pickup_icon(global_position, wtex, Rarity.label(rarity) if Rarity.normalize(rarity) != "common" else "", Rarity.color(rarity))
	Rarity.juice(rarity, kind.to_upper())
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and rs.has_method("add_points"):
		rs.add_points(f.role, 16 + Rarity.rank(rarity) * 8, "pickup")
	queue_free()
