class_name Horde
extends Node2D

## Halls of Torment-style pressure: density curve, elite packs, timed boss.

signal elite_pack
signal boss_time

var elapsed := 0.0
var spawn_cd := 0.8
var duration := 88.0
var mini_at := 32.0
var boss_at := 82.0
var map_w := 2000.0
var kills := 0
var gems := 0
var _mini := false
var _boss := false
var _cap := 8
var titles: Array[String] = ["Coping Imp", "Bag Snatch", "Clipboard"]


func _ready() -> void:
	add_to_group("horde")
	_cap = 7 if App.is_solo_density() else 14
	Juice.toast("quest", "COPING HOUR", "Hold the floor. Magnet the chips. Elites at 0:32. The bill at 1:22.")


func left() -> float:
	return maxf(0.0, duration - elapsed)


func _process(delta: float) -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs and (rs.failed or rs.cleared or rs.gated):
		return
	elapsed += delta
	spawn_cd -= delta
	if spawn_cd <= 0.0:
		_wave()
		var base := 2.25 if App.is_solo_density() else 1.05
		var curve := maxf(0.42, 1.0 - elapsed / maxf(duration, 1.0) * 0.62)
		spawn_cd = base * curve
	if elapsed >= mini_at and not _mini:
		_mini = true
		elite_pack.emit()
		Juice.toast("challenge", "ELITE PACK", "They brought friends. That's a group rate.")
		_pack()
	if elapsed >= boss_at and not _boss:
		_boss = true
		boss_time.emit()


func _alive() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			n += 1
	return n


func _wave() -> void:
	if _alive() >= _cap:
		return
	var cam := get_viewport().get_camera_2d()
	var cx := cam.global_position.x if cam else map_w * 0.5
	var side := -1.0 if randf() < 0.5 else 1.0
	var title: String = titles[randi() % titles.size()]
	var air := title == "Clipboard" or title == "Pier Gull" or title == "Drone"
	var row := {
		"title": title,
		"x": clampf(cx + side * (340.0 + randf() * 80.0), 80.0, map_w - 80.0),
		"y": 210 if air else 500,
		"home": "air" if air else "street",
		"hp": 28 if air else 36,
		"pmin": cx - 420.0,
		"pmax": cx + 420.0
	}
	var host := get_parent()
	var rs := get_tree().get_first_node_in_group("run_state")
	var mul := 1.0
	if rs and rs.has_method("hp_mul"):
		mul = rs.hp_mul()
	var p := Party.spawn_row(host, row, mul)
	if p:
		p.died.connect(func() -> void:
			kills += 1
			_gem(p.global_position)
		)


func _pack() -> void:
	var n := 2 if App.is_solo_density() else 4
	for i in n:
		_wave()


func _gem(at: Vector2) -> void:
	gems += 1
	var g := XpGem.new()
	g.global_position = at + Vector2(0, -18)
	get_parent().add_child(g)
	if kills > 0 and kills % 12 == 0:
		var chest := SurviveChest.new()
		chest.global_position = at + Vector2(24, 0)
		get_parent().add_child(chest)
