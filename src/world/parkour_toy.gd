class_name ParkourToy
extends Area2D

## Rooftops, slide hills, high jumps, wires, rope swing, escape-and-land.

@export var kind := "hill"
var _used := 0.0
var life := 0.0
var _acrobat := false


static func place(host: Node, at: Vector2, style: String) -> ParkourToy:
	var t := ParkourToy.new()
	t.kind = style
	t.global_position = at
	host.add_child(t)
	return t


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	match kind:
		"hill":
			r.size = Vector2(140, 70)
		"awning":
			r.size = Vector2(110, 48)
		"pole":
			r.size = Vector2(36, 90)
		"hood":
			r.size = Vector2(96, 42)
		"bench":
			r.size = Vector2(100, 36)
		_:
			r.size = Vector2(80, 70)
	cs.shape = r
	add_child(cs)
	var col := Color(0.55, 0.42, 0.22, 0.9)
	match kind:
		"wire":
			col = Color(0.78, 0.82, 0.88, 0.9)
		"rope":
			col = Color(0.62, 0.38, 0.18, 0.95)
		"pad":
			col = Palette.LEMON
		"escape":
			col = Palette.EDGE
		"drop":
			col = Color(0.12, 0.22, 0.28, 0.85)
		"wallrun":
			col = Color(0.55, 0.62, 0.78, 0.95)
		"dumpster":
			col = Color(0.22, 0.4, 0.22, 0.95)
		"billboard":
			col = Palette.LEMON
		"grind":
			col = Color(0.78, 0.72, 0.42, 0.95)
		"cart":
			col = Color(0.72, 0.74, 0.78, 0.95)
		"awning":
			col = Color(0.82, 0.28, 0.22, 0.95)
		"scaffold":
			col = Color(0.62, 0.58, 0.42, 0.95)
		"geyser":
			col = Color(0.35, 0.72, 0.88, 0.9)
		"pole":
			col = Color(0.78, 0.62, 0.22, 0.95)
		"hood":
			col = Color(0.16, 0.22, 0.42, 0.95)
		"bench":
			col = Color(0.42, 0.32, 0.22, 0.95)
		"flag":
			col = Palette.BRICK
		"crate":
			col = Color(0.5, 0.36, 0.18, 0.95)
	var poly := Polygon2D.new()
	poly.color = col
	if kind == "hill":
		poly.polygon = PackedVector2Array([
			Vector2(-70, 18), Vector2(70, -16), Vector2(70, 22), Vector2(-70, 22)
		])
	elif kind == "wire":
		poly.polygon = PackedVector2Array([
			Vector2(-60, -2), Vector2(60, -2), Vector2(60, 4), Vector2(-60, 4)
		])
	elif kind == "rope":
		poly.polygon = PackedVector2Array([
			Vector2(-6, -40), Vector2(6, -40), Vector2(6, 24), Vector2(-6, 24)
		])
	elif kind == "drop":
		poly.polygon = PackedVector2Array([
			Vector2(-40, -8), Vector2(40, -8), Vector2(28, 28), Vector2(-28, 28)
		])
	elif kind == "wallrun":
		poly.polygon = PackedVector2Array([
			Vector2(-8, -48), Vector2(8, -48), Vector2(8, 24), Vector2(-8, 24)
		])
	elif kind == "dumpster":
		poly.polygon = PackedVector2Array([
			Vector2(-36, 4), Vector2(36, 4), Vector2(28, 22), Vector2(-28, 22)
		])
	elif kind == "grind":
		poly.polygon = PackedVector2Array([
			Vector2(-70, -4), Vector2(70, -4), Vector2(70, 6), Vector2(-70, 6)
		])
	elif kind == "cart":
		poly.polygon = PackedVector2Array([
			Vector2(-30, -8), Vector2(34, -8), Vector2(30, 22), Vector2(-26, 22)
		])
	elif kind == "awning":
		poly.polygon = PackedVector2Array([
			Vector2(-54, -6), Vector2(54, -18), Vector2(54, -4), Vector2(-54, 8)
		])
	elif kind == "scaffold":
		poly.polygon = PackedVector2Array([
			Vector2(-40, -6), Vector2(40, -6), Vector2(36, 8), Vector2(-36, 8)
		])
	elif kind == "geyser":
		poly.polygon = PackedVector2Array([
			Vector2(-10, 18), Vector2(10, 18), Vector2(22, -28), Vector2(-22, -28)
		])
	elif kind == "pole":
		poly.polygon = PackedVector2Array([
			Vector2(-6, -52), Vector2(6, -52), Vector2(8, 24), Vector2(-8, 24)
		])
	elif kind == "hood":
		poly.polygon = PackedVector2Array([
			Vector2(-46, 4), Vector2(40, -10), Vector2(46, 18), Vector2(-40, 20)
		])
	elif kind == "bench":
		poly.polygon = PackedVector2Array([
			Vector2(-48, 6), Vector2(48, 6), Vector2(44, 20), Vector2(-44, 20)
		])
	elif kind == "flag":
		poly.polygon = PackedVector2Array([
			Vector2(-4, -52), Vector2(4, -52), Vector2(4, 20), Vector2(-4, 20),
			Vector2(4, -48), Vector2(36, -36), Vector2(4, -24)
		])
	elif kind == "crate":
		poly.polygon = PackedVector2Array([
			Vector2(-22, -4), Vector2(22, -4), Vector2(22, 20), Vector2(-22, 20)
		])
	else:
		poly.polygon = PackedVector2Array([
			Vector2(-28, 8), Vector2(28, 8), Vector2(22, 20), Vector2(-22, 20)
		])
	add_child(poly)
	if SpriteBook.attach_living(self, kind, 20.0):
		return
	var tex := SpriteBook.prop(kind)
	if tex:
		poly.visible = false
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		s.position = Vector2(-float(tex.get_width()) * 0.5 * SpriteBook.DRAW_SCALE, -float(tex.get_height()) * SpriteBook.DRAW_SCALE + 20.0)
		s.texture_filter = SpriteBook.world_filter()
		add_child(s)


func _process(delta: float) -> void:
	if life > 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
	if _used > 0.0:
		_used -= delta
	for n in get_overlapping_bodies():
		if n is Fighter:
			_touch(n as Fighter)


func _touch(f: Fighter) -> void:
	match kind:
		"hill":
			if f._street_grounded():
				f.velocity.x = float(f.facing) * 420.0
				f.trick_boost = maxf(f.trick_boost, 1.12)
				f.trick_t = 1.1
				if _used <= 0.0:
					_used = 0.35
					Juice.shout("SLIDE HILL")
					KitSfx.hit(f.role, "dash")
		"wire":
			f.hop = -40.0
			f.hop_v = 0.0
			f.velocity.y = 0.0
			if f._just("jump"):
				f.hop_v = -520.0
				Juice.shout("WIRE POP")
		"rope":
			if f._just("jump") or f._just("special"):
				f.hop_v = -560.0
				f.hop = -8.0
				f.velocity.x = float(f.facing) * 360.0
				f.trick_boost = 1.14
				f.trick_t = 1.4
				Juice.shout("ROPE SWING")
				Juice.unlock_logo("ROPE SWING", "Escape and land. The silo still wants a copay.", "NAMED TRICK  ·  SWING")
				KitSfx.hit(f.role, "jump")
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs and rs.has_method("add_points"):
					rs.add_points(f.role, 36, "swing")
		"pad":
			if _used <= 0.0 and (f._just("jump") or f._street_grounded()):
				_used = 0.4
				f.hop_v = -780.0
				f.hop = -4.0
				Juice.shout("HIGH JUMP")
				KitSfx.hit(f.role, "jump")
		"escape":
			if f._just("jump") or f._just("special"):
				f.hop_v = -640.0
				f.velocity.x = float(f.facing) * 400.0
				f.trick_boost = 1.16
				f.trick_t = 1.6
				Juice.shout("ESCAPE LAND")
				FamilyProfile.mark_trick()
		"drop":
			if f.global_position.y < 400.0:
				f.hop_v = 380.0
				Juice.shout("THE DROP")
		"wallrun":
			if _used <= 0.0:
				_used = 0.45
				f.wall_run = 0.55
				f.hop = -52.0
				f.hop_v = -90.0
				f.velocity.x = float(f.facing) * 360.0
				f.trick_boost = 1.12
				f.trick_t = 1.2
				f.parkour_lock = 0.12
				Juice.shout("WALL RUN")
				Juice.named_slowmo()
				KitSfx.hit(f.role, "dash")
				FamilyProfile.mark_trick()
				if not _acrobat:
					_acrobat = true
					_spawn_named("Wall Kid", 34, "roof")
					Juice.toast("challenge", "WALL KID", "You rented the brick. He kicks the invoice.")
		"dumpster":
			if _used <= 0.0 and (f._just("jump") or f._street_grounded()):
				_used = 0.4
				f.hop_v = -640.0
				f.hop = -4.0
				f.velocity.x = float(f.facing) * 280.0
				f.trick_boost = 1.14
				f.trick_t = 1.3
				Juice.shout("DUMPSTER")
				VoBank.dumpster()
				Juice.unlock_logo("DUMPSTER LIFT", "Sunset Overdrive called this a car. We call it a lid.", "NAMED TRICK  ·  DUMPSTER")
				KitSfx.hit(f.role, "jump")
				FamilyProfile.mark_trick()
		"billboard":
			if _used <= 0.0 and (f._just("jump") or f._street_grounded() or f.hop < -8.0):
				_used = 0.35
				f.hop_v = -820.0
				f.hop = -6.0
				Juice.shout("BILLBOARD")
				Juice.named_slowmo()
				KitSfx.hit(f.role, "jump")
				FamilyProfile.mark_trick()
		"grind":
			f.hop = -28.0
			f.hop_v = 0.0
			f.velocity.x = float(f.facing) * 380.0
			Juice.keep_combo()
			if _used <= 0.0:
				_used = 0.4
				FamilyProfile.mark_grind()
				if not _acrobat:
					_acrobat = true
					_spawn_named("Rail Rat", 36, "street")
					Juice.toast("challenge", "RAIL RAT", "You rented the rail. He wants a quote for the sparks.")
			if f._just("jump"):
				f.hop_v = -540.0
				f.trick_boost = 1.16
				f.trick_t = 1.5
				Juice.shout("GRIND POP")
				Juice.trick_chain(3, "GRIND POP")
				FamilyProfile.mark_trick()
		"cart":
			if _used <= 0.0 and f.cart_t <= 0.0 and f._street_grounded():
				_used = 0.8
				f.cart_t = 1.25
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs and rs.has_method("has_card") and rs.has_card("cart_hop"):
					f.cart_t = 1.85
				f.velocity.x = float(f.facing) * 360.0
				f.hop = -10.0
				f.hop_v = 0.0
				Juice.shout(Copy.CART)
				VoBank.cart()
				KitSfx.hit(f.role, "dash")
				Juice.unlock_logo("CART RIDE", "Sunset Overdrive bounced cars. We stole a till on wheels.", "NAMED TRICK  ·  CART")
				FamilyProfile.mark_cart()
				FamilyProfile.mark_trick()
			elif f.cart_t > 0.0 and f._just("jump"):
				f.cart_t = 0.0
				f.hop_v = -560.0
				Juice.shout("CART POP")
				Juice.named_slowmo()
		"awning":
			if _used <= 0.0 and (f._just("jump") or f.hop < -8.0 or f._street_grounded()):
				_used = 0.38
				var lift := -820.0
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs and rs.has_method("has_card") and rs.has_card("awning_hop"):
					lift = -920.0
				f.hop_v = lift
				f.hop = -6.0
				f.velocity.x = float(f.facing) * 300.0
				f.trick_boost = 1.16
				f.trick_t = 1.4
				Juice.shout(Copy.AWNING)
				Juice.named_slowmo()
				Juice.play("res://assets/audio/awning.wav" if ResourceLoader.exists("res://assets/audio/awning.wav") else "res://assets/audio/dash.wav")
				KitSfx.hit(f.role, "jump")
				VoBank.awning()
				Juice.unlock_logo("AWNING", "Sunset Overdrive bounced storefronts. We bounce copays.", "NAMED TRICK  ·  AWNING")
				FamilyProfile.mark_awning()
				FamilyProfile.mark_trick()
				if not _acrobat:
					_acrobat = true
					_spawn_acrobat()
		"scaffold":
			f.hop = -36.0
			f.hop_v = 0.0
			f.velocity.x = float(f.facing) * 280.0
			if f._just("jump"):
				f.hop_v = -520.0
				f.trick_boost = 1.12
				f.trick_t = 1.1
				Juice.shout("SCAFFOLD POP")
				FamilyProfile.mark_trick()
		"geyser":
			if _used <= 0.0:
				_used = 0.32
				f.hop_v = -760.0
				f.hop = -4.0
				f.velocity.x = float(f.facing) * 220.0
				Juice.shout(Copy.GEYSER)
				Juice.geyser(global_position)
				KitSfx.hit(f.role, "jump")
				FamilyProfile.mark_trick()
		"pole":
			if _used <= 0.0 and (f._just("jump") or f._just("special") or f.hop < -8.0):
				_used = 0.48
				var lift := -680.0
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs != null and rs.has_method("has_card"):
					if bool(rs.call("has_card", "pole_vault")):
						lift = -780.0
				f.hop_v = lift
				f.hop = -8.0
				f.velocity.x = float(f.facing) * 420.0
				f.trick_boost = 1.16
				f.trick_t = 1.5
				Juice.shout(Copy.POLE)
				Juice.named_slowmo()
				Juice.play("res://assets/audio/pole.wav" if ResourceLoader.exists("res://assets/audio/pole.wav") else "res://assets/audio/dash.wav")
				KitSfx.hit(f.role, "jump")
				VoBank.pole()
				Juice.unlock_logo("POLE SWING", "Sunset Overdrive rented the lamp. We stole the copay.", "NAMED TRICK  ·  POLE")
				FamilyProfile.mark_pole()
				FamilyProfile.mark_trick()
				if rs and rs.has_method("add_points"):
					rs.add_points(f.role, 36, "swing")
				if not _acrobat:
					_acrobat = true
					_spawn_named("Pole Clerk", 40, "street")
					Juice.toast("challenge", "POLE CLERK", "You swung the lamp. He bills the orbit.")
		"hood":
			if _used <= 0.0 and (f._just("jump") or f.hop < -8.0 or f._street_grounded()):
				_used = 0.4
				var lift := -720.0
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs != null and rs.has_method("has_card"):
					if bool(rs.call("has_card", "hood_hop")):
						lift = -820.0
				f.hop_v = lift
				f.hop = -6.0
				f.velocity.x = float(f.facing) * 320.0
				f.trick_boost = 1.14
				f.trick_t = 1.3
				Juice.shout(Copy.HOOD)
				Juice.named_slowmo()
				Juice.hood(global_position)
				KitSfx.hit(f.role, "jump")
				VoBank.hood()
				Juice.unlock_logo("HOOD BOUNCE", "Sunset Overdrive bounced cars. We bounce a copay on a hood.", "NAMED TRICK  ·  HOOD")
				FamilyProfile.mark_hood()
				FamilyProfile.mark_trick()
				if rs and rs.has_method("add_points"):
					rs.add_points(f.role, 32, "swing")
				if not _acrobat:
					_acrobat = true
					_spawn_named("Hood Hopper", 38, "street")
					Juice.toast("challenge", "HOOD HOPPER", "You rented the bumper. He wants a quote for the paint.")
		"bench":
			if _used <= 0.0 and (f._just("jump") or f._just("dash") or f._street_grounded()):
				_used = 0.32
				f.hop_v = -480.0
				f.hop = -4.0
				f.velocity.x = float(f.facing) * 400.0
				f.trick_boost = 1.1
				f.trick_t = 1.05
				Juice.shout(Copy.BENCH)
				Juice.play("res://assets/audio/bench.wav" if ResourceLoader.exists("res://assets/audio/bench.wav") else "res://assets/audio/dash.wav")
				KitSfx.hit(f.role, "dash")
				FamilyProfile.mark_bench()
				FamilyProfile.mark_trick()
				if not _acrobat:
					_acrobat = true
					_spawn_named("Bench Clerk", 32, "street")
					Juice.toast("challenge", "BENCH CLERK", "You vaulted intake. He still wants you to sit.")
		"flag":
			if _used <= 0.0 and (f._just("jump") or f._just("special")):
				_used = 0.5
				f.hop_v = -420.0
				Juice.shout("FLAG")
				Juice.unlock_logo("STOLEN FLAG", "A rag on a stick. Points anyway.", "TOY")
				var rs := get_tree().get_first_node_in_group("run_state")
				if rs and rs.has_method("add_points"):
					rs.add_points(f.role, 20, "flag")
		"crate":
			if _used <= 0.0 and (f._just("jump") or f._street_grounded()):
				_used = 0.35
				f.hop_v = -520.0
				f.hop = -4.0
				Juice.shout("CRATE")
				KitSfx.hit(f.role, "jump")


func _spawn_acrobat() -> void:
	_spawn_named("Awning Acrobat", 34, "roof")
	Juice.toast("challenge", "AWNING ACROBAT", "You bounced the storefront. She wants a quote for the canvas.")


func _spawn_named(title: String, hp: int, home: String) -> void:
	var host := get_parent()
	if host == null:
		return
	var act := get_tree().get_first_node_in_group("run_act")
	if act is RunAct and (act as RunAct).map_id == "raven_grid" and global_position.x > 2200.0:
		return
	Party.spawn_row(host, {
		"title": title, "x": global_position.x + 48.0, "y": 430 if home == "roof" else 500,
		"home": home, "hp": hp, "pmin": global_position.x - 120.0, "pmax": global_position.x + 220.0
	}, 1.0)
