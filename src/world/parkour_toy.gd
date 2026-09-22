class_name ParkourToy
extends Area2D

## Rooftops, slide hills, high jumps, wires, rope swing, escape-and-land.

@export var kind := "hill"
var _used := 0.0


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
	r.size = Vector2(140, 70) if kind == "hill" else Vector2(80, 70)
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
	else:
		poly.polygon = PackedVector2Array([
			Vector2(-28, 8), Vector2(28, 8), Vector2(22, 20), Vector2(-22, 20)
		])
	add_child(poly)
	var lab := Label.new()
	lab.position = Vector2(-70, -36)
	lab.size = Vector2(140, 20)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.text = kind.to_upper()
	UiKit.apply_label(lab, 11, Palette.MUTED)
	add_child(lab)


func _process(delta: float) -> void:
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
