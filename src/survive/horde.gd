class_name Horde
extends Node2D

## Halls of Torment-style pressure, read from data/survive.json phases:
## the enemy mix, spawn rate and cap climb every phase; elites (bigger,
## glowing, with a modifier: swift / armored / vampiric / splitter /
## bomber) arrive on a timer and drop item chests; a mini-boss mid-hour, a
## swarm burst late, and the story boss at boss_at. Every kill drops an
## insight gem that feeds the hour's SurviveRun.

signal elite_pack
signal boss_time

var elapsed := 0.0
var spawn_cd := 0.8
var duration := 300.0
var mini_at := 150.0
var boss_at := 285.0
var map_w := 2000.0
var kills := 0
var gems := 0
var titles: Array[String] = []
var _mini := false
var _boss := false
var _phases: Array = []
var _mods: Array = []
var _phase: Dictionary = {}
var _elite_t := 0.0
var _swarm_done := false
var _announced := -1


func _ready() -> void:
	add_to_group("horde")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/survive.json"))
	var book: Dictionary = parsed if parsed is Dictionary else {}
	_phases = book.get("phases", [])
	_mods = book.get("elite_mods", [])
	duration = float(book.get("duration", duration))
	boss_at = float(book.get("boss_at", boss_at))
	if get_tree().get_first_node_in_group("survive_run") == null:
		get_parent().add_child.call_deferred(SurviveRun.new())
	Juice.toast("quest", "COPING HOUR", "Survive %d:%02d. Abilities fire on their own: you move, they bill. Elites drop chests." % [int(duration) / 60, int(duration) % 60])


func left() -> float:
	return maxf(0.0, duration - elapsed)


func _cur_phase() -> Dictionary:
	var cur: Dictionary = {}
	for i in _phases.size():
		var p: Dictionary = _phases[i]
		if elapsed >= float(p.get("at", 0)):
			cur = p
			if i > _announced:
				_announced = i
				if i > 0:
					Juice.toast("challenge", "THE HOUR GETS WORSE", "Phase %d of %d: %s." % [i + 1, _phases.size(), ", ".join(p.get("titles", []))])
	# Maps with their own cast keep it, with the phase's pace.
	if not titles.is_empty():
		cur = cur.duplicate()
		cur["titles"] = titles
	return cur


func _process(delta: float) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and (rs.failed or rs.cleared or rs.gated):
		return
	elapsed += delta
	_phase = _cur_phase()
	spawn_cd -= delta
	if spawn_cd <= 0.0:
		_wave()
		var rate := float(_phase.get("rate", 1.0)) * (1.0 if App.is_solo_density() else 1.7)
		var srun := SurviveRun.get_run(get_tree())
		if srun:
			rate *= 1.0 + 0.1 * float(srun.trait_n("t_curse"))
		spawn_cd = 1.6 / maxf(rate, 0.2)
	var every := float(_phase.get("elite_every", 0))
	if every > 0.0:
		_elite_t += delta
		if _elite_t >= every:
			_elite_t = 0.0
			_wave(true)
	if bool(_phase.get("mini", false)) and not _mini:
		_mini = true
		elite_pack.emit()
		Juice.toast("challenge", "MINI-BOSS", "Somebody's manager has arrived.")
	if bool(_phase.get("swarm", false)) and not _swarm_done:
		_swarm_done = true
		Juice.shout("SWARM")
		for i in (6 if App.is_solo_density() else 10):
			_wave(false, true)
	if elapsed >= boss_at and not _boss:
		_boss = true
		boss_time.emit()


func _alive() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _cap() -> int:
	var srun := SurviveRun.get_run(get_tree())
	var curse := 1.0 + (0.1 * float(srun.trait_n("t_curse")) if srun else 0.0)
	return int(round(float(_phase.get("cap", 9)) * (1 if App.is_solo_density() else 2) * curse))


func _wave(elite := false, force := false) -> void:
	if not force and not elite and _alive() >= _cap():
		return
	var pool: Array = _phase.get("titles", ["Coping Imp"])
	if pool.is_empty():
		pool = ["Coping Imp"]
	var cam := get_viewport().get_camera_2d()
	var cx := cam.global_position.x if cam else map_w * 0.5
	var side := -1.0 if randf() < 0.5 else 1.0
	var title := str(pool[randi() % pool.size()])
	var air := title in ["Clipboard", "Pier Gull", "Drone", "Ice Drone", "Billboard Gull", "Invoice Chopper"]
	var row := {
		"title": title,
		"x": clampf(cx + side * (340.0 + randf() * 120.0), 80.0, map_w - 80.0),
		"y": 210 if air else 460 + randi() % 100,
		"home": "air" if air else "street",
		"hp": 28 if air else 36,
		"pmin": cx - 520.0,
		"pmax": cx + 520.0
	}
	var host := get_parent()
	var rs := get_tree().get_first_node_in_group("run_state")
	var mul := 1.0 + elapsed / 120.0
	if rs and rs.has_method("hp_mul"):
		mul *= rs.hp_mul()
	var p := Party.spawn_row(host, row, mul)
	if p == null:
		return
	if elite:
		_make_elite(p)
	p.died.connect(func() -> void:
		kills += 1
		var run := SurviveRun.get_run(get_tree())
		if run:
			run.note_kill()
		_gem(p.global_position, p.elite_mod != "")
		if p.elite_mod != "":
			_elite_death(p)
	)


func _make_elite(p: Punk) -> void:
	OverheadBadge.attach.call_deferred(p, "elite")
	if _mods.is_empty():
		return
	var m: Dictionary = _mods[randi() % _mods.size()]
	p.elite_mod = str(m.get("id", ""))
	p.hp *= 4
	p.max_hp = p.hp
	var col: Array = m.get("color", [1, 1, 1])
	var c := Color(float(col[0]), float(col[1]), float(col[2]))
	p.modulate = c.lerp(Color.WHITE, 0.45)
	p.scale = Vector2(1.25, 1.25)
	if p.elite_mod == "swift":
		p.speed *= 1.7
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.4
	l.color = c
	l.energy = 1.2
	l.position = Vector2(0, -30)
	p.add_child(l)
	var tag := Label.new()
	tag.text = "ELITE · " + str(m.get("name", ""))
	tag.position = Vector2(-50, -96)
	tag.size = Vector2(100, 12)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override("font_color", c)
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tag.add_theme_constant_override("outline_size", 3)
	p.add_child(tag)
	if p.elite_mod == "vampiric":
		var tm := Timer.new()
		tm.wait_time = 1.0
		tm.autostart = true
		tm.timeout.connect(func() -> void:
			if is_instance_valid(p) and p.hp > 0:
				p.hp = mini(p.max_hp, p.hp + maxi(1, p.max_hp / 40))
		)
		p.add_child(tm)


func _elite_death(p: Punk) -> void:
	var at := p.global_position
	match p.elite_mod:
		"splitter":
			for i in 2:
				var r := {"title": "Coping Imp", "x": at.x + (i * 2 - 1) * 20.0, "y": at.y, "home": "street", "hp": 30, "pmin": at.x - 300.0, "pmax": at.x + 300.0}
				Party.spawn_row.call_deferred(get_parent(), r, 1.0)
		"bomber":
			SurvProj.ring(get_parent(), at, 70.0, Color(1.0, 0.5, 0.15))
			for f in get_tree().get_nodes_in_group("players"):
				if f is Fighter and (f as Fighter).global_position.distance_to(at) < 70.0:
					(f as Fighter).take_hit("heavy", p)
			Juice.pulse_shake(6.0)
	var chest := SurviveChest.new()
	chest.global_position = at + Vector2(18, 0)
	get_parent().add_child.call_deferred(chest)
	# TWO FOR ONE: a second chest a third of the time.
	if Trees.has("f_chest") and randf() < 0.33:
		var c2 := SurviveChest.new()
		c2.global_position = at + Vector2(-22, 6)
		get_parent().add_child.call_deferred(c2)


func _gem(at: Vector2, big := false) -> void:
	gems += 1
	var g := XpGem.new()
	g.amount = 18 if big else 4 + int(elapsed / 90.0)
	g.global_position = at + Vector2(0, -18)
	get_parent().add_child.call_deferred(g)
