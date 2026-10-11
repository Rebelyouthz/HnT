class_name CabinetDrop
extends Node2D

## City Hall: the clerks upstairs throw filing cabinets out of the windows.
## A shadow grows on the pavement for a second, then the cabinet lands:
## heroes under it take a heavy hit, thugs are FILED (an environmental kill
## with the street's bonus), bosses lose a fifth of their health. Bait them
## under the shadow.

const FALL := 1.25
const R := Vector2(30, 13)

var map_w := 2200.0
var _cd := 7.0
var _drops: Array = []   # {at: Vector2, t: float, landed: bool, life: float, seed: int}


static func place(host: Node, width: float) -> CabinetDrop:
	var c := CabinetDrop.new()
	c.map_w = width
	c.name = "CabinetDrop"
	host.add_child(c)
	return c


func _ready() -> void:
	z_index = 2
	add_to_group("cabinet_drop")


## Drop one now at a street spot (tests and scripted beats).
func drop_at(at: Vector2) -> void:
	_drops.append({"at": at, "t": 0.0, "landed": false, "life": 4.0, "seed": randi()})


func _process(delta: float) -> void:
	queue_redraw()
	_cd -= delta
	if _cd <= 0.0:
		_cd = randf_range(6.5, 10.0)
		var heroes: Array = []
		for f in get_tree().get_nodes_in_group("players"):
			if f is Fighter and not (f as Fighter).downed:
				heroes.append(f)
		if not heroes.is_empty():
			var h: Fighter = heroes[randi() % heroes.size()]
			var at := Vector2(clampf(h.global_position.x + randf_range(-90.0, 90.0), 60.0, map_w - 60.0),
				clampf(h.global_position.y + randf_range(-30.0, 30.0), Fighter.STREET_MIN + 6.0, Fighter.STREET_MAX - 6.0))
			drop_at(at)
	for d in _drops:
		d["t"] = float(d["t"]) + delta
		if not bool(d["landed"]) and float(d["t"]) >= FALL:
			d["landed"] = true
			_land(d["at"])
		if bool(d["landed"]):
			d["life"] = float(d["life"]) - delta
	_drops = _drops.filter(func(d: Dictionary) -> bool: return float(d["life"]) > 0.0)


func _under(n: Node2D, at: Vector2) -> bool:
	var v := n.global_position - at
	return absf(v.x) < R.x and absf(v.y) < R.y


func _land(at: Vector2) -> void:
	Juice.pulse_shake(5.0)
	Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.6, -1.0)
	Juice.popup_number(at + Vector2(0, -50), "FILED", UiKit.GOLD)
	for f in get_tree().get_nodes_in_group("players"):
		if f is Fighter and not (f as Fighter).downed and (f as Fighter).hop > -20.0 and _under(f, at):
			(f as Fighter).take_hit("heavy", self)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Punk):
			continue
		var p := e as Punk
		if p.hp <= 0 or p.home != "street" or not _under(p, at):
			continue
		if p.is_in_group("act_boss"):
			p.hp = maxi(1, p.hp - maxi(1, int(round(float(p.max_hp) * 0.2))))
			p.take_hit("heavy", self)
			continue
		Juice.shout("FILED")
		p.hp = 1
		p.take_hit("finish", self)
		var host := get_parent()
		if is_instance_valid(host):
			for i in 3:
				LootDrop.spawn(host, at + Vector2(randf_range(-16, 16), 4), "coin", 1, 1.2)
			var rs := host.get_tree().get_first_node_in_group("run_state")
			if rs and rs.has_method("add_xp"):
				rs.add_xp(20)
		FamilyProfile.data["env_kills"] = int(FamilyProfile.data.get("env_kills", 0)) + 1
		QuestGiver.note(get_tree(), "filed", p.title)


func _draw() -> void:
	for d in _drops:
		var at: Vector2 = d["at"]
		var k := clampf(float(d["t"]) / FALL, 0.0, 1.0)
		var r := RandomNumberGenerator.new()
		r.seed = int(d["seed"])
		if not bool(d["landed"]):
			# The shadow tightens and darkens as it comes down.
			var pts := PackedVector2Array()
			for i in 18:
				var a := TAU * float(i) / 18.0
				pts.append(at + Vector2(cos(a) * R.x * (1.6 - 0.6 * k), sin(a) * R.y * (1.6 - 0.6 * k)))
			draw_colored_polygon(pts, Color(0, 0, 0, 0.2 + 0.45 * k))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.3, 0.25, 0.4 + 0.5 * k * (0.5 + 0.5 * sin(k * 30.0))), 1.5)
			var y := lerpf(at.y - 420.0, at.y, k * k)
			_cabinet(Vector2(at.x, y), k * 4.0, Color.WHITE)
		else:
			var fade := clampf(float(d["life"]) / 1.0, 0.0, 1.0)
			_cabinet(at, 0.25, Color(1, 1, 1, fade))
			# Paper burst around the wreck.
			var age := 4.0 - float(d["life"])
			for i in 10:
				var dir := Vector2.from_angle(r.randf() * TAU)
				var dist := minf(age * 90.0, 40.0 + r.randf() * 30.0)
				var p := at + Vector2(dir.x * dist, dir.y * dist * 0.4 - maxf(0.0, 30.0 - age * 40.0))
				draw_rect(Rect2(p, Vector2(5, 3)), Color(0.95, 0.94, 0.88, fade))


func _cabinet(base: Vector2, tilt: float, mod: Color) -> void:
	var tr := Transform2D(sin(tilt) * 0.3, base)
	var body := PackedVector2Array([Vector2(-14, -46), Vector2(14, -46), Vector2(14, 0), Vector2(-14, 0)])
	draw_colored_polygon(tr * body, Color(0.46, 0.5, 0.46) * mod)
	for k in 3:
		var y := -42.0 + float(k) * 14.0
		draw_colored_polygon(tr * PackedVector2Array([Vector2(-11, y), Vector2(11, y), Vector2(11, y + 11), Vector2(-11, y + 11)]), Color(0.38, 0.42, 0.38) * mod)
		draw_line(tr * Vector2(-4, y + 5), tr * Vector2(4, y + 5), Color(0.8, 0.8, 0.75) * mod, 2.0)
	draw_line(tr * Vector2(-14, -46), tr * Vector2(14, -46), Color(0.7, 0.74, 0.7) * mod, 2.0)
