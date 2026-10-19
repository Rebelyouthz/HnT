class_name SmileCam
extends Area2D

## Neon Exchange: the agents' smile cameras, on street poles and roof edges.
## A red cone sweeps the pavement; stand in it for a second (ducking hides
## you) and the street bills you: SMILE, an agent walks in from off screen.
## Break the pole (three light hits, two heavies) for cash; it counts as a
## smash for Sign Guy Pell's quest.

const SEE_T := 1.0
const COOLDOWN := 9.0
const MAX_CALLS := 2

## Pole height: tall on the street, a stub on a roof edge.
var tall := 118.0
var reach := 250.0
var spread := 0.3
var phase := 0.0
var _hp := 3
var _t := 0.0
var _seen := 0.0
var _cd := 0.0
var _calls := 0
var _dead := false
var _flash := 0.0
var _aim := PI * 0.5


static func place(host: Node, at: Vector2, on_roof := false) -> SmileCam:
	var c := SmileCam.new()
	c.position = at
	if on_roof:
		c.tall = 30.0
		c.reach = 210.0
	c.phase = fmod(at.x * 0.013, TAU)
	host.add_child(c)
	return c


func _ready() -> void:
	add_to_group("smashables")
	add_to_group("smile_cams")
	z_index = 3
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 64)
	cs.shape = r
	cs.position = Vector2(0, -32)
	add_child(cs)


func _head() -> Vector2:
	return Vector2(0, -tall)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 4.0)
	queue_redraw()
	if _dead:
		return
	_cd = maxf(0.0, _cd - delta)
	# Sweep: from straight down to forty degrees either side.
	_aim = PI * 0.5 + 0.7 * sin(_t * 0.8 + phase)
	var spotted: Fighter = null
	var head := global_position + _head()
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter):
			continue
		var f := n as Fighter
		if f.ducking or not f.is_visible_in_tree():
			continue
		var v := f.global_position + Vector2(0, -30) - head
		if v.length() > reach:
			continue
		if absf(angle_difference(v.angle(), _aim)) < spread:
			spotted = f
			break
	if spotted == null:
		_seen = maxf(0.0, _seen - delta * 1.5)
		return
	_seen += delta
	if _seen >= SEE_T and _cd <= 0.0 and _calls < MAX_CALLS:
		_bill(spotted)


func _bill(f: Fighter) -> void:
	_seen = 0.0
	_cd = COOLDOWN
	_calls += 1
	Juice.popup_number(f.global_position + Vector2(0, -70), "SMILE!  BILLED", Color(1.0, 0.3, 0.35))
	Mixer.play_sfx("res://assets/audio/card.wav", 0.8, -4.0)
	var act := get_tree().get_first_node_in_group("run_act")
	if act == null:
		return
	var mul := 1.0
	var st: Variant = act.get("_state")
	if st is Object and (st as Object).has_method("hp_mul"):
		mul = float((st as Object).call("hp_mul"))
	var cam := get_viewport().get_camera_2d()
	var side := -1.0 if randf() < 0.5 else 1.0
	var x := (cam.global_position.x if cam else f.global_position.x) + side * 330.0
	Party.spawn_row(act, {
		"title": "Agent Lin", "x": x, "y": 500, "home": "street", "hp": 40,
		"pmin": x - 200.0, "pmax": x + 200.0, "cop": true
	}, mul)


func take_hit(kind: String, from: Node) -> void:
	if _dead:
		return
	Juice.keep_combo()
	_flash = 1.0
	_hp -= 1 if kind in ["light", "jab", "jump-kick", "slide"] else 2
	Mixer.play_sfx("res://assets/audio/hit_light.wav", 1.3, -6.0)
	if _hp <= 0:
		_break(from)


func _break(_from: Node) -> void:
	_dead = true
	remove_from_group("smashables")
	set_deferred("monitorable", false)
	FamilyProfile.mark_smash()
	QuestGiver.note(get_tree(), "smash")
	Juice.popup_number(global_position + _head() + Vector2(0, -16), "CAM DOWN", UiKit.GOLD)
	Juice.pulse_shake(2.0)
	Mixer.play_sfx("res://assets/audio/smash.wav" if ResourceLoader.exists("res://assets/audio/smash.wav") else "res://assets/audio/hit_heavy.wav")
	var host := get_parent()
	if host:
		LootDrop.spawn(host, Vector2(global_position.x, 500.0 if tall > 60.0 else global_position.y), "cash", 6)


func _draw() -> void:
	var head := _head()
	var steel := Color(0.22, 0.22, 0.26).lerp(Color.WHITE, _flash * 0.5)
	if _dead:
		# Snapped pole, the camera hanging by its cable.
		draw_line(Vector2.ZERO, Vector2(0, -tall * 0.55), steel, 4.0)
		var hang := Vector2(6, -tall * 0.55 + 18.0 + 2.0 * sin(_t * 2.0))
		draw_line(Vector2(0, -tall * 0.55), hang, Color(0.1, 0.1, 0.1), 1.0)
		draw_rect(Rect2(hang + Vector2(-5, 0), Vector2(10, 7)), Color(0.15, 0.15, 0.17))
		if fmod(_t, 1.3) < 0.08:
			draw_circle(hang + Vector2(0, 3), 4.0, Color(1.0, 0.85, 0.4, 0.8))
		return
	draw_line(Vector2.ZERO, head, steel, 4.0)
	draw_line(Vector2(-1, 0), head + Vector2(-1, 0), steel.lightened(0.25), 1.0)
	draw_rect(Rect2(Vector2(-6, -4), Vector2(12, 4)), steel.darkened(0.3))
	# The cone fades out with distance; where its middle meets the ground a
	# red spot slides along the pavement so you can read where it looks.
	var hot := clampf(_seen / SEE_T, 0.0, 1.0)
	var near := Color(1.0, 0.16, 0.22, 0.26 + 0.24 * hot)
	var far := Color(1.0, 0.16, 0.22, 0.02)
	var a := head + Vector2.from_angle(_aim - spread) * reach
	var b := head + Vector2.from_angle(_aim + spread) * reach
	draw_polygon(PackedVector2Array([head, a, b]), PackedColorArray([near, far, far]))
	draw_line(head, a, Color(1.0, 0.3, 0.35, 0.22 + 0.4 * hot), 1.0)
	draw_line(head, b, Color(1.0, 0.3, 0.35, 0.22 + 0.4 * hot), 1.0)
	var dir := Vector2.from_angle(_aim)
	if dir.y > 0.05:
		var hit := head + dir * minf(tall / dir.y, reach)
		var rx := 16.0 + 10.0 * absf(dir.x)
		var pts := PackedVector2Array()
		for k in 16:
			var ang := TAU * float(k) / 16.0
			pts.append(hit + Vector2(cos(ang) * rx, sin(ang) * rx * 0.3))
		draw_colored_polygon(pts, Color(1.0, 0.2, 0.25, 0.18 + 0.3 * hot))
	# Camera body: a dark housing on a bracket, lens toward the aim.
	var body := Transform2D(_aim, head)
	var shell := PackedVector2Array([Vector2(-6, -5), Vector2(9, -5), Vector2(11, -3), Vector2(11, 3), Vector2(9, 5), Vector2(-6, 5)])
	draw_colored_polygon(body * shell, Color(0.12, 0.12, 0.15).lerp(Color.WHITE, _flash * 0.6))
	draw_polyline(body * (shell + PackedVector2Array([shell[0]])), Color(0.45, 0.45, 0.5), 1.0)
	draw_line(body * Vector2(-6, -5), body * Vector2(8, -5), Color(0.6, 0.6, 0.66), 1.0)
	draw_line(head, head + Vector2(-4, 6), steel, 2.0)
	var blink := 0.5 + 0.5 * sin(_t * (6.0 + 10.0 * hot))
	draw_circle(body * Vector2(11, 0), 2.6, Color(0.05, 0.05, 0.06))
	draw_circle(body * Vector2(11, 0), 1.6, Color(1.0, 0.15, 0.2, 0.6 + 0.4 * blink))
	draw_circle(body * Vector2(-2, -2), 1.2, Color(1.0, 0.2, 0.2, blink))
	if hot > 0.05:
		draw_string(ThemeDB.fallback_font, head + Vector2(-14, -12), "SMILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.35, 0.4, hot))
