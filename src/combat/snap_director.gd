class_name SnapDirector
extends Node

const WORLD_SCALE := 0.22
const OPEN_HOUSE := 0.40
const NIGHT_CLASS := 0.28
const FINALS := 0.18

var active: Fighter
var victim: Node
var open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("snap_director")


func window_sec() -> float:
	match App.difficulty:
		"open_house":
			return OPEN_HOUSE
		"finals":
			return FINALS
		_:
			return NIGHT_CLASS


func _process(_delta: float) -> void:
	if open and is_instance_valid(active) and active._just("snap"):
		_execute()
		return
	if open:
		return
	var players := get_tree().get_nodes_in_group("players")
	for n in players:
		if n is Fighter:
			var f: Fighter = n
			var v := _candidate(f)
			if v:
				_open(f, v)
				return


func _candidate(f: Fighter) -> Node:
	if f.downed or f.attack_cd > 0:
		return null
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk):
			continue
		var e: Punk = n
		if not is_instance_valid(e) or e.hp <= 0:
			continue
		var dx := e.global_position.x - f.global_position.x
		var dy := e.global_position.y - f.global_position.y
		var dist := absf(dx)
		var dive := f.gliding and dy > 40.0 and absf(dx) < 54.0 and dist < 70.0
		var same_lane := absf(dy) < 62.0 and dist < 88.0 and dist > 6.0
		if not dive and not same_lane:
			continue
		var toward := signf(dx) == 0.0 or signf(f.velocity.x) == signf(dx) or absf(f.velocity.x) < 12.0
		var from_back := e.facing == f.facing
		var lined := f.vaulting or f.sliding or f.gliding or f.web_incoming or f.dashing
		if not lined and not (from_back and toward and absf(f.velocity.x) > 140.0):
			continue
		if dive or lined or from_back:
			return e
	return null


func _open(f: Fighter, e: Node) -> void:
	open = true
	active = f
	victim = e
	f.snap_ready = true
	Juice.set_world_scale(WORLD_SCALE)
	Juice.play("res://assets/audio/hit_light.wav")
	await get_tree().create_timer(window_sec(), true, false, true).timeout
	if open:
		_close()


func _execute() -> void:
	if not open:
		return
	var f := active
	var e := victim
	_close()
	if not is_instance_valid(f) or not is_instance_valid(e):
		return
	f.invuln = 18
	f.snap_ready = false
	f.global_position.x = e.global_position.x - float(f.facing) * 22.0
	if e.has_method("take_hit"):
		e.take_hit("snap", f)
	Juice.snap_bang((e as Node2D).global_position)
	FamilyProfile.mark_snap()


func _close() -> void:
	open = false
	if is_instance_valid(active):
		active.snap_ready = false
	active = null
	victim = null
	Juice.set_world_scale(1.0)
