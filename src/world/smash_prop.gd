class_name SmashProp
extends Area2D

## SoR4 barrels: lights keep the combo, heavies and throws pop scrap.

@export var kind := "booth"
var hp := 2
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
		_:
			_box.color = Color(0.42, 0.28, 0.14, 0.95)
	_box.polygon = PackedVector2Array([
		Vector2(-22, -64), Vector2(22, -64), Vector2(22, 0), Vector2(-22, 0)
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
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(global_position, "smash", 1.0)
	queue_free()


func _drop_pipe(host: Node) -> void:
	if host == null:
		return
	var wp := WeaponPickup.new()
	wp.kind = "pipe"
	wp.global_position = global_position + Vector2(0, -18)
	host.add_child(wp)
	Juice.toast("reward", "PIPE", "SoR4 barrels drop bats. Ours drop invoices with a handle.")


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
