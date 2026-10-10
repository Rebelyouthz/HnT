class_name SmashProp
extends Area2D

## SoR4 barrels: lights keep the combo, heavies and throws pop scrap.

@export var kind := "booth"
var hp := 2
var exploding := false
var _box: Polygon2D
## Breaks in stages: every blow chips it (lights 1, heavies 3), the art
## cracks, dents, sheds chunks and soots up until it bursts.
var _dur := 6
var _dmg := 0
var _art: CanvasItem
var _mat: ShaderMaterial


static func place(host: Node, at: Vector2, style: String) -> SmashProp:
	var p := SmashProp.new()
	p.kind = style
	p.global_position = at
	host.add_child(p)
	return p


func _ready() -> void:
	add_to_group("smashables")
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(52, 64)
	cs.shape = r
	cs.position = Vector2(0, -32)
	add_child(cs)
	_box = Polygon2D.new()
	match kind:
		"booth":
			_box.color = Color(0.18, 0.42, 0.55, 0.95)
			hp = 3
		"kiosk":
			_box.color = Color(0.55, 0.22, 0.18, 0.95)
		"dumpster":
			_box.color = Color(0.22, 0.38, 0.2, 0.95)
			hp = 3
		"fridge":
			_box.color = Color(0.72, 0.78, 0.82, 0.95)
		"billboard":
			_box.color = Color(0.9, 0.55, 0.18, 0.95)
			hp = 2
		"cop_car":
			_box.color = Color(0.12, 0.22, 0.55, 0.95)
			hp = 3
		"hydrant":
			_box.color = Color(0.72, 0.18, 0.16, 0.95)
			hp = 2
		"mail":
			_box.color = Color(0.42, 0.28, 0.16, 0.95)
			hp = 2
		"news":
			_box.color = Color(0.88, 0.78, 0.22, 0.95)
			hp = 2
		"vending":
			_box.color = Color(0.62, 0.12, 0.18, 0.95)
			hp = 3
		"barrel":
			_box.color = Color(0.62, 0.28, 0.08, 0.95)
			hp = 2
		"manhole":
			_box.color = Color(0.28, 0.3, 0.34, 0.95)
			hp = 2
		_:
			_box.color = Color(0.42, 0.28, 0.14, 0.95)
	_box.polygon = PackedVector2Array([
		Vector2(-22, -64), Vector2(22, -64), Vector2(22, 0), Vector2(-22, 0)
	])
	if kind == "hydrant":
		_box.polygon = PackedVector2Array([
			Vector2(-10, -42), Vector2(10, -42), Vector2(14, 0), Vector2(-14, 0)
		])
	elif kind == "mail":
		_box.polygon = PackedVector2Array([
			Vector2(-16, -48), Vector2(16, -48), Vector2(18, 0), Vector2(-18, 0)
		])
	elif kind == "barrel":
		_box.polygon = PackedVector2Array([
			Vector2(-18, -58), Vector2(18, -58), Vector2(20, 0), Vector2(-20, 0)
		])
	elif kind == "manhole":
		_box.polygon = PackedVector2Array([
			Vector2(-24, -16), Vector2(24, -16), Vector2(28, 0), Vector2(-28, 0)
		])
	add_child(_box)
	var strap := Polygon2D.new()
	strap.color = Palette.EDGE
	strap.polygon = PackedVector2Array([
		Vector2(-22, -38), Vector2(22, -38), Vector2(22, -32), Vector2(-22, -32)
	])
	add_child(strap)
	_mount_sprite()


func _mount_sprite() -> void:
	_dur = hp * 3
	if SpriteBook.attach_living(self, kind):
		for c in get_children():
			if c is AnimatedSprite2D:
				_dress(c)
		return
	var tex := SpriteBook.prop(kind)
	if tex == null:
		return
	if _box:
		_box.visible = false
	for c in get_children():
		if c is Polygon2D:
			(c as CanvasItem).visible = false
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
	s.position = Vector2(-float(tex.get_width()) * 0.5 * SpriteBook.DRAW_SCALE, -float(tex.get_height()) * SpriteBook.DRAW_SCALE)
	s.texture_filter = SpriteBook.world_filter()
	add_child(s)
	_dress(s)


func _dress(art: CanvasItem) -> void:
	_art = art
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://src/shaders/prop_damage.gdshader")
	_mat.set_shader_parameter("seed", randf() * 40.0)
	art.material = _mat


## A blow lands: chips off, a flash, the prop rocks on its base.
func _chip(n: int, from: Node) -> void:
	_dmg += n
	var frac := clampf(float(_dmg) / float(maxi(_dur, 1)), 0.0, 1.0)
	if _mat:
		_mat.set_shader_parameter("damage", frac)
		_mat.set_shader_parameter("flash", 0.8)
		var tf := create_tween()
		tf.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 0.8, 0.0, 0.12)
	var dir := 1.0
	if from is Node2D:
		dir = signf(global_position.x - (from as Node2D).global_position.x)
		if dir == 0.0:
			dir = 1.0
	var tw := create_tween()
	tw.tween_property(self, "rotation", dir * 0.08 * float(mini(n, 3)), 0.04)
	tw.tween_property(self, "rotation", -dir * 0.04, 0.06)
	tw.tween_property(self, "rotation", 0.0, 0.08)
	_splinters(dir, n)


## A few chips of the prop's own colour fly off the blow.
func _splinters(dir: float, n: int) -> void:
	var host := get_parent()
	if host == null:
		return
	var col := _box.color if _box else Color(0.4, 0.3, 0.2)
	var tex: Texture2D = (_art as Sprite2D).texture if _art is Sprite2D else null
	if tex != null:
		var img := tex.get_image()
		if img != null:
			col = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	for i in 2 + n * 2:
		var bit := Polygon2D.new()
		var sz := randf_range(1.0, 2.5)
		bit.polygon = PackedVector2Array([Vector2(-sz, -sz * 0.5), Vector2(sz, -sz * 0.6), Vector2(sz * 0.6, sz * 0.5), Vector2(-sz * 0.8, sz * 0.4)])
		bit.color = col.darkened(randf() * 0.4)
		bit.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-40, -14))
		bit.z_index = 5
		host.add_child(bit)
		var land := global_position.y + randf_range(-4.0, 8.0)
		var end := Vector2(bit.global_position.x + dir * randf_range(14.0, 46.0), land)
		var tw := bit.create_tween().set_parallel(true)
		tw.tween_property(bit, "global_position:x", end.x, 0.4)
		tw.tween_property(bit, "global_position:y", bit.global_position.y - randf_range(10.0, 26.0), 0.15).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(bit, "global_position:y", land, 0.25).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(bit, "rotation", randf_range(-6.0, 6.0), 0.4)
		tw.chain().tween_interval(5.0)
		tw.chain().tween_property(bit, "modulate:a", 0.0, 1.0)
		tw.chain().tween_callback(bit.queue_free)


## What it is made of decides what you hear.
func _material_sfx(final: bool) -> void:
	var mat := "wood"
	if kind in ["kiosk", "vending", "cop_car", "booth", "dumpster", "drum", "hydrant", "mail", "news", "barrier"]:
		mat = "metal"
	elif kind in ["window", "glass", "bottle"]:
		mat = "glass"
	var path := {"wood": "res://assets/audio/sfx/crate_break.ogg", "metal": "res://assets/audio/sfx/metal_bang.ogg", "glass": "res://assets/audio/sfx/glass_break.ogg"}[mat] as String
	if ResourceLoader.exists(path):
		Mixer.play_sfx(path, randf_range(0.9, 1.1) * (0.85 if final else 1.15), -2.0 if final else -8.0)
	else:
		Juice.play("res://assets/audio/smash.wav" if ResourceLoader.exists("res://assets/audio/smash.wav") else "res://assets/audio/hit_light.wav")


func take_hit(hit: String, from: Node) -> void:
	Juice.keep_combo()
	_material_sfx(false)
	if _box:
		_box.modulate = Color(1.35, 1.1, 0.85)
		get_tree().create_timer(0.08, true, false, true).timeout.connect(func() -> void:
			if is_instance_valid(_box):
				_box.modulate = Color.WHITE
		)
	if hit == "light" or hit == "jump-kick" or hit == "slide" or hit == "jab":
		Juice.register_hit("light", global_position, 1)
		if from is Fighter:
			var rs0 := get_tree().get_first_node_in_group("run_state")
			if rs0 and rs0.has_method("add_points"):
				rs0.add_points((from as Fighter).role, 4, "prop")
		_chip(1, from)
		if _dmg >= _dur:
			_pop(from)
		return
	if kind == "barrel" and _dmg + 3 >= _dur:
		_explode(from)
		return
	_chip(4 if hit == "throw" or hit == "finish" else 3, from)
	Juice.pulse_shake(2.5)
	if _dmg < _dur:
		return
	_pop(from)


func _pop(from: Node) -> void:
	FamilyProfile.mark_smash()
	var orb := ScrapOrb.new()
	orb.amount = 3 if kind == "kiosk" or kind == "fridge" else 2
	orb.global_position = global_position + Vector2(0, -16)
	var host := get_parent()
	host.add_child(orb)
	if kind in ["dumpster", "kiosk", "barrel", "cop_car"]:
		FamilyProfile.add_parts("scrap_coil", 1)
	elif kind in ["mail", "news", "booth"]:
		FamilyProfile.add_parts("clinic_thread", 1)
	Juice.smash_burst(global_position, kind)
	Juice.shout(kind.to_upper() + " POP")
	var rs := get_tree().get_first_node_in_group("run_state")
	var pts := 28
	if kind == "dumpster":
		pts = 36
	elif kind == "billboard":
		pts = 32
	elif kind == "cop_car":
		pts = 40
	elif kind == "hydrant":
		pts = 30
	elif kind == "vending":
		pts = 34
	elif kind == "barrel":
		pts = 44
	elif kind == "manhole":
		pts = 34
	if from is Fighter and rs and rs.has_method("add_points"):
		rs.add_points((from as Fighter).role, pts, "smash")
	Rarity.juice("uncommon" if kind != "dumpster" and kind != "cop_car" else "rare", kind.to_upper())
	if rs and rs.has_method("has_card") and rs.has_card("snack_break"):
		var extra := ScrapOrb.new()
		extra.amount = 2
		extra.global_position = global_position + Vector2(18, -20)
		host.add_child(extra)
	if kind == "booth":
		_drop_pipe(host)
	if kind == "fridge":
		FamilyProfile.stash_snack("bandage")
		if rs and rs.has_method("add_lunch"):
			rs.add_lunch()
		Juice.toast("reward", "COLD SNACK", "The street fridge packed a bandage and a lunch for 140m.")
		VoBank.fridge()
		_spawn_named(host, "Fridge Imp", 28, "street")
	elif kind == "dumpster":
		VoBank.dumpster()
		Juice.unlock_logo("DUMPSTER", "Sunset Overdrive called this a trampoline. We call it billing.", "NAMED PROP")
	elif kind == "billboard" and rs:
		_spawn_witch(host)
	elif kind == "kiosk":
		_spawn_named(host, "Coupon Cart", 58, "street")
		Juice.toast("challenge", "COUPON CART", "You popped the till. Groceries learned to ram.")
	elif kind == "cop_car":
		if rs and rs.has_method("add_wanted"):
			rs.add_wanted(1)
		Juice.play("res://assets/audio/siren.wav" if ResourceLoader.exists("res://assets/audio/siren.wav") else "res://assets/audio/heat_up.wav")
		Juice.unlock_logo("COP CAR", "Huntdown wrecked hovercrafts. We wrecked a citation.", "NAMED PROP")
		_spawn_named(host, "Ticket Skipper", 38, "street")
		Juice.toast("challenge", "TICKET SKIPPER", "The fare slid under the bumper.")
	elif kind == "hydrant":
		_spawn_geyser(host)
		_spawn_named(host, "Hydrant Cop", 44, "street")
		Juice.toast("challenge", "HYDRANT COP", "You opened the city. He brought a ticket and a spray.")
		Juice.unlock_logo("GEYSER", "Sunset Overdrive bounced awnings. We billed the hydrant.", "NAMED PROP")
	elif kind == "mail":
		_drop_kind(host, "envelope")
		_spawn_named(host, "Envelope Clerk", 40, "street")
		Juice.toast("challenge", "ENVELOPE CLERK", "You popped the box. Certified mail learned to stab.")
	elif kind == "news":
		_spawn_named(host, "Paper Boy", 36, "street")
		FamilyProfile.mark_paper()
		Juice.toast("challenge", "PAPER BOY", "The headline rammed first. Subscriptions are violence.")
		var cycle := false
		if rs != null and rs.has_method("has_card"):
			cycle = bool(rs.call("has_card", "news_cycle"))
		if cycle:
			_drop_pipe(host)
	elif kind == "vending":
		FamilyProfile.stash_snack("boost")
		_drop_kind(host, "can")
		Juice.toast("reward", "VENDING", "A can. A tutoring bar packed itself. The machine still wants a copay.")
		VoBank.fridge()
	elif kind == "barrel":
		_explode(from)
		return
	elif kind == "manhole":
		FamilyProfile.mark_manhole()
		_spawn_geyser(host)
		_launch_near()
		_spawn_named(host, "Steam Mole", 30, "street")
		Juice.toast("challenge", "STEAM MOLE", "You popped the lid. The underpass billed the steam.")
		Juice.unlock_logo("MANHOLE", "SoR4 hid knives under crates. We hid a copay under iron.", "NAMED PROP")
		VoBank.manhole()
		var steam := false
		if rs != null and rs.has_method("has_card"):
			steam = bool(rs.call("has_card", "steam_lid"))
		if steam:
			for n in get_tree().get_nodes_in_group("enemies"):
				if not (n is Punk) or not is_instance_valid(n):
					continue
				if global_position.distance_to((n as Node2D).global_position) > 78.0:
					continue
				(n as Punk).take_hit("light", from if from != null else self)
	_burst_apart(from)
	queue_free()


## Shards of the sprite, and what was inside: cash always, sometimes a
## flask, and on one prop per street the adrenaline syringe.
func _burst_apart(from: Node) -> void:
	var host := get_parent()
	var dir := 1.0
	if from is Node2D:
		dir = signf(global_position.x - (from as Node2D).global_position.x)
		if dir == 0.0:
			dir = 1.0
	if _art != null:
		ShardBurst.shatter(host, _art, global_position, dir)
		QuestGiver.note(get_tree(), "smash")
	_material_sfx(true)
	var cash := 3 + randi() % 6
	if kind in ["kiosk", "vending", "cop_car"]:
		cash += 8
	LootDrop.spawn(host, global_position, "cash", cash)
	for i in randi_range(1, 3):
		LootDrop.spawn(host, global_position + Vector2(randf_range(-8, 8), 0), "coin", 1, 1.4)
	if randf() < 0.22 or kind == "fridge":
		LootDrop.spawn(host, global_position, "flask")
	elif randf() < 0.07 or kind == "vending":
		LootDrop.spawn(host, global_position, "energy")
	elif randf() < 0.05:
		LootDrop.spawn(host, global_position, "smoke")
	if has_meta("syringe"):
		LootDrop.spawn(host, global_position, "syringe", 0, 0.4)


func _drop_pipe(host: Node) -> void:
	if host == null:
		return
	var wp := WeaponPickup.new()
	wp.kind = "pipe"
	wp.global_position = global_position + Vector2(0, -18)
	host.add_child(wp)
	Juice.toast("reward", "PIPE", "SoR4 barrels drop bats. Ours drop invoices with a handle.")


func _drop_kind(host: Node, style: String) -> void:
	if host == null:
		return
	var wp := WeaponPickup.new()
	wp.kind = style
	wp.global_position = global_position + Vector2(0, -18)
	host.add_child(wp)


func _launch_near() -> void:
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter) or not is_instance_valid(n):
			continue
		var f: Fighter = n
		if global_position.distance_to(f.global_position) > 72.0:
			continue
		f.hop_v = -620.0
		f.hop = minf(f.hop, -4.0)


func _spawn_geyser(host: Node) -> void:
	if host == null:
		return
	var toy := ParkourToy.place(host, global_position + Vector2(0, 0), "geyser")
	toy.life = 3.4
	Juice.geyser(global_position)
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "geyser", 0.0)


func _spawn_named(host: Node, title: String, hp: int, home: String) -> void:
	if host == null:
		return
	var act := get_tree().get_first_node_in_group("run_act")
	if act is RunAct and (act as RunAct).map_id == "raven_grid" and global_position.x > 2200.0:
		return
	Party.spawn_row(host, {
		"title": title, "x": global_position.x + 36.0, "y": 500 if home == "street" else 430,
		"home": home, "hp": hp, "pmin": global_position.x - 140.0, "pmax": global_position.x + 200.0
	}, 1.0)


func _explode(from: Node) -> void:
	if exploding or not is_inside_tree():
		return
	exploding = true
	FamilyProfile.mark_smash()
	FamilyProfile.mark_barrel()
	var rad := 96.0
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs != null and rs.has_method("has_card"):
		if bool(rs.call("has_card", "oil_policy")):
			rad = 132.0
	var host := get_parent()
	if from is Fighter and rs and rs.has_method("add_points"):
		rs.add_points((from as Fighter).role, 44, "smash")
	Juice.boom(global_position)
	VoBank.barrel()
	Juice.unlock_logo("OIL DRUM", "SoR4 threw bodies into barrels. We bill the crater.", "NAMED PROP")
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk) or not is_instance_valid(n):
			continue
		if global_position.distance_to((n as Node2D).global_position) > rad:
			continue
		(n as Punk).take_hit("heavy", from if from != null else self)
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter) or not is_instance_valid(n):
			continue
		var f: Fighter = n
		if global_position.distance_to(f.global_position) > 58.0:
			continue
		if f.blocking or f.invuln > 0:
			continue
		f.hp = maxi(1, f.hp - 8)
		Juice.flash_red(f.visual, 2)
	var others: Array = get_tree().get_nodes_in_group("smashables")
	for n in others:
		if n == self or not (n is SmashProp) or not is_instance_valid(n):
			continue
		var other: SmashProp = n
		if other.kind != "barrel":
			continue
		if global_position.distance_to(other.global_position) > rad:
			continue
		other._explode(from)
	_spawn_named(host, "Oil Ghost", 32, "street")
	Juice.toast("challenge", "OIL GHOST", "You popped the drum. The slick learned to throw invoices.")
	_burst_apart(from)
	queue_free()


func _spawn_witch(host: Node) -> void:
	if host == null:
		return
	var act := get_tree().get_first_node_in_group("run_act")
	if act is RunAct and (act as RunAct).map_id == "raven_grid" and global_position.x > 2200.0:
		return
	Party.spawn_row(host, {
		"title": "Billboard Witch", "x": global_position.x + 40.0, "y": 500,
		"home": "roof", "hp": 42, "pmin": global_position.x - 120.0, "pmax": global_position.x + 180.0
	}, 1.0)
	Juice.toast("challenge", "BILLBOARD WITCH", "You popped the ad. She wants a quote.")
