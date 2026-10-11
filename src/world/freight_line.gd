class_name FreightLine
extends Node2D

## Rail Bridge: a freight track along the back of the street. Every so often
## the crossing lights blink and the bell rings, then a train tears through
## the lane. Anyone on the rails gets hit: heroes take a heavy blow and are
## thrown off the track, thugs are done for (LAST STOP, an environmental kill
## with the street's bonus). Lure them onto the rails before it comes.

const LANE_Y := 444.0
const HALF := 15.0
const WARN := 2.4
const SPEED := 1150.0
const CAR_W := 130.0
const CARS := 7

var map_w := 3000.0
var crossings: Array = []
var _t := 0.0
var _state := "idle"
var _cd := 9.0
var _warn_t := 0.0
var _train_x := 0.0
var _hit: Dictionary = {}
var _bell := 0.0


static func lay(host: Node, width: float, at: Array) -> FreightLine:
	var f := FreightLine.new()
	f.map_w = width
	f.crossings = at
	f.name = "FreightLine"
	host.add_child(f)
	return f


func _ready() -> void:
	z_index = 1
	add_to_group("freight_line")


## True while the lights are blinking or the train is through.
func live() -> bool:
	return _state != "idle"


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	match _state:
		"idle":
			_cd -= delta
			if _cd <= 0.0:
				_state = "warn"
				_warn_t = WARN
				_bell = 0.0
				var cam := get_viewport().get_camera_2d()
				var cx := cam.get_screen_center_position().x if cam else map_w * 0.5
				Juice.popup_number(Vector2(cx, LANE_Y - 70.0), "TRAIN!", Color(1.0, 0.3, 0.25))
		"warn":
			_warn_t -= delta
			_bell -= delta
			if _bell <= 0.0:
				_bell = 0.45
				Mixer.play_sfx("res://assets/audio/card.wav", 1.6, -8.0)
			if _warn_t <= 0.0:
				_state = "pass"
				_hit.clear()
				var cam2 := get_viewport().get_camera_2d()
				var right := (cam2.get_screen_center_position().x if cam2 else map_w * 0.5) + 420.0
				_train_x = minf(right, map_w + 200.0)
				Juice.pulse_shake(4.0)
				Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.45, -2.0)
		"pass":
			_train_x -= SPEED * delta
			if fmod(_t, 0.12) < delta:
				Juice.pulse_shake(1.6)
			_strike()
			var cam3 := get_viewport().get_camera_2d()
			var left := (cam3.get_screen_center_position().x if cam3 else 0.0) - 460.0
			if _train_x + float(CARS) * CAR_W < left:
				_state = "idle"
				_cd = randf_range(11.0, 16.0)


func _on_rails(n: Node2D) -> bool:
	if absf(n.global_position.y - LANE_Y) > HALF:
		return false
	return n.global_position.x > _train_x - 10.0 and n.global_position.x < _train_x + float(CARS) * CAR_W


func _strike() -> void:
	for f in get_tree().get_nodes_in_group("players"):
		if not (f is Fighter) or _hit.has(f.get_instance_id()):
			continue
		var h := f as Fighter
		if h.downed or h.hop < -20.0 or not _on_rails(h):
			continue
		_hit[h.get_instance_id()] = true
		h.take_hit("heavy", self)
		h.global_position.y = LANE_Y + HALF + 22.0
		Juice.popup_number(h.global_position + Vector2(0, -80), "HIT BY A TRAIN", Color(1.0, 0.4, 0.3))
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Punk) or _hit.has(e.get_instance_id()):
			continue
		var p := e as Punk
		if p.hp <= 0 or p.home != "street" or not _on_rails(p):
			continue
		_hit[p.get_instance_id()] = true
		_run_over(p)


func _run_over(p: Punk) -> void:
	# Named problems take a fifth of their health and a ride, not the end.
	if p.is_in_group("act_boss"):
		Juice.shout("RUN OVER")
		p.hp = maxi(1, p.hp - maxi(1, int(round(float(p.max_hp) * 0.2))))
		p.take_hit("heavy", self)
		return
	Juice.shout("LAST STOP")
	Juice.hitstop(5)
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood and blood.has_method("spray"):
		blood.spray(p.global_position, "geyser", -1.0)
	p.global_position.x -= 60.0
	p.hp = 1
	p.take_hit("finish", self)
	var host := get_parent()
	if is_instance_valid(host):
		for i in 3:
			LootDrop.spawn(host, Vector2(p.global_position.x + randf_range(-20, 20), LANE_Y + 30.0), "coin", 1, 1.2)
		var rs := host.get_tree().get_first_node_in_group("run_state")
		if rs and rs.has_method("add_xp"):
			rs.add_xp(20)
	FamilyProfile.data["env_kills"] = int(FamilyProfile.data.get("env_kills", 0)) + 1
	QuestGiver.note(get_tree(), "train", p.title)


func _draw() -> void:
	# Ballast, sleepers and two rails along the back of the street.
	var y := LANE_Y
	draw_rect(Rect2(0, y - 12.0, map_w, 24.0), Color(0.13, 0.12, 0.12, 0.85))
	var x := 0.0
	while x < map_w:
		draw_rect(Rect2(x, y - 10.0, 7.0, 20.0), Color(0.24, 0.17, 0.12))
		x += 18.0
	var glow := 0.0
	if _state == "warn":
		glow = 0.5 + 0.5 * sin(_t * 18.0)
	var rail := Color(0.52, 0.52, 0.56).lerp(Color(1.0, 0.4, 0.3), glow * 0.5)
	draw_line(Vector2(0, y - 6.0), Vector2(map_w, y - 6.0), rail, 2.0)
	draw_line(Vector2(0, y + 6.0), Vector2(map_w, y + 6.0), rail, 2.0)
	draw_line(Vector2(0, y - 7.0), Vector2(map_w, y - 7.0), Color(0.85, 0.85, 0.9, 0.35), 1.0)
	# Crossing signals: two red lights that take turns while it warns.
	for cx in crossings:
		var px := float(cx)
		draw_rect(Rect2(px - 2.0, y - 96.0, 4.0, 84.0), Color(0.2, 0.2, 0.22))
		draw_line(Vector2(px - 12.0, y - 92.0), Vector2(px + 12.0, y - 80.0), Color(0.9, 0.9, 0.92), 3.0)
		draw_line(Vector2(px - 12.0, y - 80.0), Vector2(px + 12.0, y - 92.0), Color(0.9, 0.9, 0.92), 3.0)
		draw_rect(Rect2(px - 14.0, y - 72.0, 28.0, 10.0), Color(0.1, 0.1, 0.12))
		var on_a := live() and fmod(_t, 0.6) < 0.3
		var on_b := live() and not on_a
		draw_circle(Vector2(px - 8.0, y - 67.0), 4.0, Color(1.0, 0.15, 0.1) if on_a else Color(0.3, 0.06, 0.05))
		draw_circle(Vector2(px + 8.0, y - 67.0), 4.0, Color(1.0, 0.15, 0.1) if on_b else Color(0.3, 0.06, 0.05))
		if on_a:
			draw_circle(Vector2(px - 8.0, y - 67.0), 10.0, Color(1.0, 0.2, 0.1, 0.25))
		if on_b:
			draw_circle(Vector2(px + 8.0, y - 67.0), 10.0, Color(1.0, 0.2, 0.1, 0.25))
	if _state != "pass":
		return
	# The train: a locomotive with a headlight, then rusty boxcars.
	var base := y + 8.0
	for i in CARS:
		var x0 := _train_x + float(i) * CAR_W
		var body := Rect2(x0 + 4.0, base - 62.0, CAR_W - 8.0, 50.0)
		var col := Color(0.32, 0.16, 0.1) if i % 3 == 1 else (Color(0.16, 0.2, 0.24) if i % 3 == 2 else Color(0.22, 0.22, 0.2))
		if i == 0:
			col = Color(0.62, 0.48, 0.12)
			draw_colored_polygon(PackedVector2Array([Vector2(x0 - 14.0, base - 18.0), Vector2(x0 + 10.0, base - 64.0), Vector2(x0 + 10.0, base - 12.0)]), col.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(x0 - 10.0, base - 46.0), Vector2(x0 - 260.0, base - 70.0), Vector2(x0 - 260.0, base + 10.0)]), Color(1.0, 0.95, 0.7, 0.14))
			draw_circle(Vector2(x0 - 4.0, base - 40.0), 5.0, Color(1.0, 0.96, 0.75))
		draw_rect(body, col)
		draw_rect(Rect2(body.position, Vector2(body.size.x, 4.0)), col.lightened(0.25))
		draw_rect(Rect2(body.position.x, body.end.y - 5.0, body.size.x, 5.0), col.darkened(0.4))
		if i > 0:
			for k in 5:
				draw_line(Vector2(body.position.x + 12.0 + float(k) * 22.0, body.position.y + 6.0), Vector2(body.position.x + 12.0 + float(k) * 22.0, body.end.y - 6.0), col.darkened(0.3), 1.0)
			if i % 2 == 0:
				draw_rect(Rect2(body.position.x + 30.0, body.position.y + 18.0, 50.0, 10.0), Color(0.85, 0.3, 0.6, 0.6))
		for wx in [x0 + 22.0, x0 + 40.0, x0 + CAR_W - 40.0, x0 + CAR_W - 22.0]:
			draw_circle(Vector2(wx, base - 8.0), 7.0, Color(0.08, 0.08, 0.09))
			draw_circle(Vector2(wx, base - 8.0), 2.5, Color(0.5, 0.5, 0.52))
		draw_rect(Rect2(x0 + CAR_W - 6.0, base - 30.0, 12.0, 4.0), Color(0.1, 0.1, 0.1))
	# Sparks off the wheels.
	for s in 6:
		var sx := _train_x + randf() * float(CARS) * CAR_W
		draw_line(Vector2(sx, base - 2.0), Vector2(sx + randf_range(8, 22), base - randf_range(2, 10)), Color(1.0, 0.8, 0.35, 0.8), 1.0)
