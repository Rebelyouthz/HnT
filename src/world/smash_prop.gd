class_name SmashProp
extends Area2D

## SoR4 barrels: lights keep the combo, heavies and throws pop scrap.

@export var kind := "booth"
var hp := 2
var exploding := false
var _box: Polygon2D
var _lab: Label


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
	_lab = Label.new()
	_lab.position = Vector2(-48, -86)
	_lab.size = Vector2(96, 18)
	_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab.text = kind.to_upper()
	UiKit.apply_label(_lab, 11, Palette.LEMON)
	add_child(_lab)


func take_hit(hit: String, from: Node) -> void:
	Juice.keep_combo()
	Juice.play("res://assets/audio/smash.wav" if ResourceLoader.exists("res://assets/audio/smash.wav") else "res://assets/audio/hit_light.wav")
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
		return
	if kind == "barrel":
		_explode(from)
		return
	hp -= 1
	Juice.sparks(global_position + Vector2(0, -28))
	Juice.pulse_shake(2.5)
	if hp > 0:
		return
	_pop(from)


func _pop(from: Node) -> void:
	FamilyProfile.mark_smash()
	var orb := ScrapOrb.new()
	orb.amount = 3 if kind == "kiosk" or kind == "fridge" else 2
	orb.global_position = global_position + Vector2(0, -16)
	var host := get_parent()
	host.add_child(orb)
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
		Juice.toast("reward", "COLD SNACK", "The street fridge packed a bandage for later.")
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
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "manhole" if kind == "manhole" else "smash", 1.0)
	queue_free()


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
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "barrel", 0.0)
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
