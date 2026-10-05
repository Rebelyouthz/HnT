class_name SurvEvents
extends Node

## Survivor hour events and helpers (one per hour, child of the horde):
##   GOLDEN THUG     every 90 s a gold-plated thug runs away with S-COINS
##   BOUNTY MARK     every 60 s one thug is marked: kill him in 15 s
##   ENCIRCLE        at 2:30 a ring of them closes in around you
##   SUPPLY DROP     every 75 s a crate falls: a heal or a magnet pull
##   KILL MILESTONE  every 100 kills a chest lands by you
##   WHEEL           every 100 s a lucky wheel token appears
##   PANIC CRY       the first time you drop under 25%: a shockwave
##   EDGE ARROWS     arrows at the screen edge to chests, elites, gold
## and the TALENT DRAW: a free pick when the hour starts.

var horde: Node
var _t := {}
var _encircled := false
var _milestone := 0
var _panic := false
var _bounty: Punk
var _bounty_t := 0.0
var _arrows: Arrows


func _ready() -> void:
	_arrows = Arrows.new()
	add_child(_arrows)
	call_deferred("_talent_draw")


func _talent_draw() -> void:
	var run := SurviveRun.get_run(get_tree())
	if run:
		Juice.shout("TALENT DRAW")
		run.add_xp(run.need())


func _every(key: String, secs: float, delta: float) -> bool:
	_t[key] = float(_t.get(key, 0.0)) + delta
	if float(_t[key]) >= secs:
		_t[key] = 0.0
		return true
	return false


func _lead() -> Fighter:
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			return n
	return null


func _process(delta: float) -> void:
	var f := _lead()
	var run := SurviveRun.get_run(get_tree())
	if f == null or run == null:
		return
	var host := horde.get_parent()
	if _every("gold", 90.0, delta):
		_golden(host, f)
	if _every("bounty", 60.0, delta):
		_mark()
	if _bounty and is_instance_valid(_bounty):
		_bounty_t -= delta
		if _bounty.hp <= 0:
			Juice.shout("BOUNTY PAID")
			SurvCoin.spawn(host, _bounty.global_position, 4)
			run.add_xp(run.need() / 3)
			_bounty = null
		elif _bounty_t <= 0.0:
			Juice.popup_number(_bounty.global_position + Vector2(0, -100), "BOUNTY GONE", Palette.MUTED)
			_bounty = null
	if not _encircled and float(horde.get("elapsed")) >= 150.0:
		_encircled = true
		_encircle(host, f)
	if _every("supply", 75.0, delta):
		Supply.drop(host, f.global_position + Vector2(randf_range(-160, 160), randf_range(-20, 30)))
	if _every("wheel", 70.0 if Trees.has("f_wheel") else 100.0, delta):
		WheelToken.place(host, f.global_position + Vector2(randf_range(120, 220) * (1.0 if randf() < 0.5 else -1.0), randf_range(-10, 20)), "survivor")
	if run.kills >= (_milestone + 1) * 100:
		_milestone += 1
		var c := SurviveChest.new()
		c.global_position = f.global_position + Vector2(60.0 * float(f.facing), 0)
		host.add_child(c)
		Juice.shout("%d KILLS: A CHEST" % (_milestone * 100))
	if not _panic and f.hp > 0 and f.hp < int(float(f.max_hp) * 0.25):
		_panic = true
		Juice.shout("BACK OFF")
		Juice.named_slowmo()
		ArtFx.spawn(host, f.global_position, "ring", Color(1.0, 0.4, 0.35), 180.0, 0.5)
		for m in get_tree().get_nodes_in_group("enemies"):
			if m is Punk and (m as Punk).global_position.distance_to(f.global_position) < 180.0:
				var e: Punk = m
				e.flung = true
				e.flung_dir = signf(e.global_position.x - f.global_position.x)
				e.flung_t = 0.3


func _golden(host: Node, f: Fighter) -> void:
	var side := -1.0 if randf() < 0.5 else 1.0
	var row := {"title": "Bag Snatch", "x": f.global_position.x + side * 300.0, "y": f.global_position.y, "home": "street", "hp": 60, "pmin": 0.0, "pmax": 99999.0}
	var p := Party.spawn_row(host, row, 2.0)
	if p == null:
		return
	p.modulate = Color(1.4, 1.15, 0.4)
	p.speed = -absf(p.speed) * 1.5
	p.set_meta("golden", true)
	OverheadBadge.attach.call_deferred(p, "bounty")
	Juice.shout("GOLDEN THUG: CATCH HIM")
	p.died.connect(func() -> void:
		SurvCoin.spawn(host, p.global_position, 15)
		Juice.shout("GOLD RUSH")
	)
	get_tree().create_timer(12.0).timeout.connect(func() -> void:
		if is_instance_valid(p) and p.hp > 0:
			p.queue_free()
	)


func _mark() -> void:
	var pool: Array = []
	for m in get_tree().get_nodes_in_group("enemies"):
		if m is Punk and (m as Punk).hp > 0 and not (m as Punk).has_meta("golden"):
			pool.append(m)
	if pool.is_empty():
		return
	_bounty = pool[randi() % pool.size()]
	_bounty_t = 15.0
	OverheadBadge.attach.call_deferred(_bounty, "bounty")
	Juice.shout("BOUNTY: 15 SECONDS")


func _encircle(host: Node, f: Fighter) -> void:
	Juice.shout("THEY HAVE YOU SURROUNDED")
	Juice.pulse_shake(4.0)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var at := f.global_position + Vector2(cos(a) * 280.0, sin(a) * 60.0)
		var row := {"title": "Coping Imp", "x": at.x, "y": clampf(at.y, 460.0, 560.0), "home": "street", "hp": 30, "pmin": at.x - 400.0, "pmax": at.x + 400.0}
		Party.spawn_row(host, row, 1.0 + float(horde.get("elapsed")) / 85.0)


## A crate on a parachute: heal or magnet.
class Supply extends Node2D:
	var _y0 := 0.0
	var _t := 0.0
	var landed := false

	static func drop(host: Node, at: Vector2) -> void:
		var s := Supply.new()
		s.global_position = at
		host.add_child(s)
		Juice.popup_number(at + Vector2(0, -160), "SUPPLY DROP", Color(0.6, 1.0, 0.7))

	func _ready() -> void:
		z_index = 5
		_y0 = -220.0

	func _physics_process(delta: float) -> void:
		_t += delta
		if not landed:
			_y0 = move_toward(_y0, 0.0, 160.0 * delta)
			if _y0 >= 0.0:
				landed = true
				Juice.land_puff(global_position)
		else:
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 24.0:
					if randf() < 0.5:
						for p in get_tree().get_nodes_in_group("players"):
							if p is Fighter:
								(p as Fighter).hp = mini((p as Fighter).max_hp, (p as Fighter).hp + (p as Fighter).max_hp / 3)
						Juice.shout("FIRST AID")
					else:
						for g in get_tree().get_nodes_in_group("xp_gems"):
							if g is Node2D:
								(g as Node2D).global_position = (n as Fighter).global_position
						Juice.shout("MAGNET")
					Mixer.play_sfx("res://assets/audio/chest.wav", 1.2, -4.0)
					queue_free()
					return
		queue_redraw()

	func _draw() -> void:
		if not landed:
			draw_line(Vector2(-10, _y0 - 24), Vector2(0, _y0 - 60), Color(0.9, 0.9, 0.9, 0.6), 1.0)
			draw_line(Vector2(10, _y0 - 24), Vector2(0, _y0 - 60), Color(0.9, 0.9, 0.9, 0.6), 1.0)
			draw_arc(Vector2(0, _y0 - 60), 20.0, PI, TAU, 16, Color(1.0, 0.5, 0.3), 4.0)
		draw_rect(Rect2(-12, _y0 - 22, 24, 22), Color(0.45, 0.62, 0.32))
		draw_rect(Rect2(-12, _y0 - 14, 24, 4), Color(0.9, 0.9, 0.85))
		draw_rect(Rect2(-2, _y0 - 22, 4, 22), Color(0.9, 0.2, 0.2))


## Screen-edge arrows to what matters off screen.
class Arrows extends CanvasLayer:
	var _c: Control

	func _ready() -> void:
		layer = 5
		_c = Control.new()
		_c.size = Vector2(640, 360)
		_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_c.draw.connect(_draw_arrows)
		add_child(_c)

	func _process(_d: float) -> void:
		_c.queue_redraw()

	func _draw_arrows() -> void:
		var vp := get_viewport()
		var cam := vp.get_camera_2d()
		if cam == null:
			return
		var xf := vp.get_canvas_transform()
		var marks: Array = []
		for n in get_tree().get_nodes_in_group("survive_chests"):
			marks.append([n, UiKit.GOLD])
		for n in get_tree().get_nodes_in_group("wheel_tokens"):
			marks.append([n, Color(0.6, 0.5, 1.0)])
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk and ((n as Punk).elite_mod != "" or (n as Punk).has_meta("golden")):
				marks.append([n, Color(1.0, 0.45, 0.3) if (n as Punk).elite_mod != "" else Color(1.0, 0.85, 0.3)])
		for m in marks:
			if not is_instance_valid(m[0]):
				continue
			var sp: Vector2 = xf * ((m[0] as Node2D).global_position + Vector2(0, -30))
			if sp.x > 8.0 and sp.x < 632.0 and sp.y > 8.0 and sp.y < 352.0:
				continue
			var c := sp.clamp(Vector2(12, 40), Vector2(628, 340))
			var d := (sp - Vector2(320, 180)).normalized()
			var col: Color = m[1]
			var tip := c + d * 6.0
			var side := Vector2(-d.y, d.x) * 4.0
			_c.draw_colored_polygon(PackedVector2Array([tip, c - d * 4.0 + side, c - d * 4.0 - side]), col)
