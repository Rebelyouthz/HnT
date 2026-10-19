class_name BossBrain
extends Node

## Boss attack patterns (data/bosses.json). Between ordinary brawling the
## boss runs a telegraphed pattern: a red zone fills, then it strikes. Each
## pattern ends in a PUNISH window (dizzy, takes +50% damage) so learning the
## dodge pays. Breaking a stage (75 / 50 / 25 % hp) adds new moves, speeds
## everything up and opens with the newest move.
##   charge     back off, a red lane, then a rush along it
##   slam       leap onto you; a ring on the floor where it lands
##   volley     three fans of projectiles at different depths
##   rain       markers around you; things fall on them
##   summon     calls two thugs in from the edges
##   lane_wave  a shockwave along its own lane: step to another depth
##   grab       lunge; unblockable if it catches you
##   spin       spinning advance that hits all around, light hits bounce

const PUNISH_MUL := 1.5

var boss: ActBoss
var book: Dictionary = {}
var busy := false
var punish_t := 0.0
var _cd := 3.0
var _last := ""
var _step := 0
var _t := 0.0
var _move := ""
var _target := Vector2.ZERO
var _from := Vector2.ZERO
var _dir := 1.0
var _zone: BossFx
var _n := 0
var _opened_stage := 0


static func spec_for(title: String) -> Dictionary:
	var all: Dictionary = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/bosses.json"))
	if parsed is Dictionary:
		all = parsed
	var base: Dictionary = (all.get("default", {}) as Dictionary).duplicate(true)
	var own: Dictionary = all.get(title, {})
	for k in own:
		base[k] = own[k]
	return base


func _ready() -> void:
	book = spec_for(boss.title)
	_cd = 2.4


func pool() -> Array:
	var out: Array = []
	var st: Array = book.get("stages", [["charge"]])
	for i in mini(boss.stage + 1, st.size()):
		out.append_array(st[i])
	return out


func move_name(id: String) -> String:
	return str((book.get("names", {}) as Dictionary).get(id, id.replace("_", " ").to_upper()))


func _target_fighter() -> Fighter:
	var best: Fighter = null
	var bd := 99999.0
	for n in boss.get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d := (n as Fighter).global_position.distance_to(boss.global_position)
			if d < bd:
				bd = d
				best = n
	return best


## Called every physics frame by the boss; returns true while a pattern owns
## the body (the ordinary brawler AI is skipped).
func tick(delta: float) -> bool:
	if punish_t > 0.0:
		punish_t -= delta
		boss.velocity = Vector2.ZERO
		if punish_t <= 0.0:
			boss._alert = Color.WHITE
		return true
	if busy:
		_t += delta
		_run(delta)
		return true
	if boss.telegraph > 0.0 or boss.recover > 0.0 or boss.hp <= 0:
		return false
	var f := _target_fighter()
	if f == null or f.global_position.distance_to(boss.global_position) > 520.0:
		return false
	_cd -= delta * (1.0 + 0.18 * float(boss.stage))
	if boss.stage > _opened_stage:
		_opened_stage = boss.stage
		var st: Array = book.get("stages", [])
		if boss.stage < st.size() and not (st[boss.stage] as Array).is_empty():
			_start(str((st[boss.stage] as Array)[0]), f)
			return true
	if _cd > 0.0:
		return false
	var p := pool()
	if p.size() > 1:
		p.erase(_last)
	_start(str(p[randi() % p.size()]), f)
	return true


func _start(id: String, f: Fighter) -> void:
	busy = true
	_move = id
	_last = id
	_t = 0.0
	_step = 0
	_n = 0
	_target = f.global_position
	_from = boss.global_position
	_dir = signf(f.global_position.x - boss.global_position.x)
	if _dir == 0.0:
		_dir = 1.0
	boss.facing = int(_dir)
	boss.visual.scale.x = _dir
	boss.velocity = Vector2.ZERO
	Juice.shout(move_name(id))
	Juice.popup_number(boss.global_position + Vector2(0, -110), move_name(id), Color(1.0, 0.4, 0.3))
	Mixer.play_sfx("res://assets/audio/sfx/boss_warn.ogg" if ResourceLoader.exists("res://assets/audio/sfx/boss_warn.ogg") else "res://assets/audio/boss_roar.wav", randf_range(0.9, 1.05), -4.0)
	boss._alert = Color(1.0, 0.5, 0.35)
	_clip("attack")


func _end(punish: float) -> void:
	busy = false
	_move = ""
	_cd = maxf(1.6, 3.4 - 0.45 * float(boss.stage)) + randf_range(0.0, 0.8)
	if punish > 0.0:
		punish_t = punish
		boss._alert = Color(0.65, 0.85, 1.0)
		Juice.popup_number(boss.global_position + Vector2(0, -100), "OPEN!", Color(0.6, 0.9, 1.0))
		_clip("hurt")
	else:
		boss._alert = Color.WHITE


func _clip(c: String) -> void:
	var a: AnimatedSprite2D = boss._anim
	if a and a.sprite_frames and a.sprite_frames.has_animation(c) and a.animation != c:
		a.play(c)
		a.speed_scale = 1.0


func _host() -> Node:
	return boss.get_parent()


func _speed_k() -> float:
	return 1.0 + 0.15 * float(boss.stage)


func _run(delta: float) -> void:
	match _move:
		"charge":
			_charge(delta)
		"slam":
			_slam()
		"volley":
			_volley()
		"rain":
			_rain()
		"summon":
			_summon()
		"lane_wave":
			_lane_wave()
		"grab":
			_grab(delta)
		"spin":
			_spin(delta)
		_:
			_end(0.0)


func _charge(delta: float) -> void:
	var tele := 0.85 / _speed_k()
	if _step == 0:
		var len := 560.0
		var y := boss.global_position.y
		var x0 := boss.global_position.x
		var r := Rect2(minf(x0, x0 + _dir * len), y - 20.0, len, 40.0)
		_zone = BossFx.zone_band(_host(), r, tele, boss)
		_target = Vector2(x0 + _dir * len, y)
		_step = 1
		_clip("walk")
	elif _step == 1:
		# Wind-up: shuffle back a little.
		boss.global_position.x -= _dir * 30.0 * delta
		if _t >= tele:
			_step = 2
			_clip("attack")
			Juice.pulse_shake(3.0)
	elif _step == 2:
		var sp := 620.0 * _speed_k()
		boss.global_position.x = move_toward(boss.global_position.x, _target.x, sp * delta)
		boss._lane()
		if absf(boss.global_position.x - _target.x) < 2.0 or _t > tele + 1.4:
			Juice.pulse_shake(6.0)
			Mixer.play_sfx("res://assets/audio/sfx/melee_sledge.ogg", 0.7, -4.0)
			_end(1.1)


func _slam() -> void:
	var tele := 0.8 / _speed_k()
	if _step == 0:
		var f := _target_fighter()
		if f:
			_target = f.global_position
		_zone = BossFx.zone_circle(_host(), _target, 92.0, tele, boss)
		_step = 1
	elif _step == 1:
		var k := clampf(_t / tele, 0.0, 1.0)
		boss.global_position = _from.lerp(_target, k)
		boss.visual.position.y = 4.0 - sin(k * PI) * 120.0
		if _t >= tele:
			boss.visual.position.y = 4.0
			Juice.pulse_shake(9.0)
			Juice.hitstop(4)
			Mixer.play_sfx("res://assets/audio/sfx/melee_sledge.ogg", 0.55, -2.0)
			SuitFx.spawn(boss.global_position, "ring", 110.0, 1.0, Color(1.0, 0.75, 0.5))
			_end(1.0)


func _volley() -> void:
	var waves := 3 if boss.stage < 2 else 4
	var gap := 0.55 / _speed_k()
	if _t >= 0.45 + float(_n) * gap and _n < waves:
		var f := _target_fighter()
		var ly := f.global_position.y if f else boss.global_position.y
		var per := 3 + mini(boss.stage, 2)
		for i in per:
			var lane := clampf(ly + (float(i) - float(per - 1) * 0.5) * 30.0, Fighter.STREET_MIN + 6.0, maxf(Fighter.STREET_MAX, 590.0))
			var from := boss.global_position + Vector2(_dir * 20.0, -46.0)
			var v := Vector2(_dir * (330.0 + 30.0 * float(boss.stage)), (lane - boss.global_position.y) * 0.5)
			BossFx.shot(_host(), from, v, boss, str(book.get("shot", "paper")), lane)
		Mixer.play_sfx("res://assets/audio/sfx/throw_whoosh.ogg" if ResourceLoader.exists("res://assets/audio/sfx/throw_whoosh.ogg") else "res://assets/audio/whoosh.wav", randf_range(1.0, 1.2), -6.0)
		_n += 1
		_clip("attack")
	if _t > 0.45 + float(waves) * gap + 0.3:
		_end(0.8)


func _rain() -> void:
	var count := 6 + 2 * boss.stage
	var gap := 0.16
	if _n < count and _t >= 0.3 + float(_n) * gap:
		var f := _target_fighter()
		var c := f.global_position if f else boss.global_position
		var at := c + Vector2(randf_range(-140, 140), randf_range(-40, 40))
		if _n % 3 == 0 and f:
			at = f.global_position
		at.y = clampf(at.y, Fighter.STREET_MIN + 8.0, maxf(Fighter.STREET_MAX, 592.0))
		BossFx.drop(_host(), at, 0.95 / _speed_k(), boss, str(book.get("drop", "crate")))
		_n += 1
	if _t > 0.3 + float(count) * gap + 1.0:
		_end(0.9)


func _summon() -> void:
	if _step == 0 and _t > 0.4:
		_step = 1
		var cam := boss.get_viewport().get_camera_2d()
		var cx := cam.global_position.x if cam else boss.global_position.x
		var n := 2 + (1 if boss.stage >= 3 else 0)
		for i in n:
			var side := -1.0 if i % 2 == 0 else 1.0
			Party.spawn_row(_host(), {
				"title": str(book.get("add", "Bag Snatch")),
				"hp": 38,
				"home": "street",
			}, Heroes.enemy_hp_mul()).global_position = Vector2(cx + side * 360.0, randf_range(450.0, 560.0))
		Juice.pulse_shake(3.0)
	if _t > 1.0:
		_end(0.0)


func _lane_wave() -> void:
	var tele := 0.7 / _speed_k()
	var waves := 1 if boss.stage < 3 else 2
	if _step == 0:
		var r := Rect2(boss.global_position.x - 640.0, boss.global_position.y - 16.0, 1280.0, 32.0)
		_zone = BossFx.zone_band(_host(), r, tele, boss, "none")
		_step = 1
	elif _step == 1 and _t >= tele:
		for d in [-1.0, 1.0]:
			BossFx.wave(_host(), boss.global_position, d, boss)
		Juice.pulse_shake(6.0)
		Mixer.play_sfx("res://assets/audio/sfx/melee_sledge.ogg", 0.6, -3.0)
		_step = 2
		_n = 1
	elif _step == 2 and _n < waves and _t >= tele + 0.6:
		# Second wave on the lane the player stepped into.
		var f := _target_fighter()
		var y := f.global_position.y if f else boss.global_position.y
		BossFx.zone_band(_host(), Rect2(boss.global_position.x - 640.0, y - 16.0, 1280.0, 32.0), 0.45, boss, "none")
		get_tree().create_timer(0.45).timeout.connect(func() -> void:
			if is_instance_valid(boss):
				for d in [-1.0, 1.0]:
					BossFx.wave(_host(), Vector2(boss.global_position.x, y), d, boss)
		)
		_n += 1
	if _t > tele + 1.4:
		_end(0.9)


func _grab(delta: float) -> void:
	var tele := 0.55 / _speed_k()
	if _step == 0:
		boss._alert = Color(1.6, 1.6, 1.6)
		_step = 1
	elif _step == 1 and _t >= tele:
		_step = 2
		_from = boss.global_position
	elif _step == 2:
		boss.global_position.x += _dir * 520.0 * delta
		boss._lane()
		for n in boss.get_tree().get_nodes_in_group("players"):
			if n is Fighter and not (n as Fighter).downed and (n as Fighter).invuln <= 0:
				var f: Fighter = n
				if absf(f.global_position.x - boss.global_position.x) < 46.0 and absf(f.global_position.y - boss.global_position.y) < 30.0 and f.hop > -20.0:
					f.take_hit("crush", boss)
					Juice.shout("CAUGHT")
					Juice.hitstop(8)
					_end(0.6)
					return
		if absf(boss.global_position.x - _from.x) > 200.0:
			_end(1.2)


func _spin(delta: float) -> void:
	var dur := 2.2
	if _t < 0.4:
		return
	var f := _target_fighter()
	if f:
		var d := f.global_position - boss.global_position
		boss.global_position += d.normalized() * 120.0 * _speed_k() * delta
		boss._lane()
	boss.visual.scale.x = 1.0 if int(_t * 10.0) % 2 == 0 else -1.0
	if int(_t * 5.0) != _n:
		_n = int(_t * 5.0)
		for n in boss.get_tree().get_nodes_in_group("players"):
			if n is Fighter and not (n as Fighter).downed:
				var ff: Fighter = n
				if absf(ff.global_position.x - boss.global_position.x) < 62.0 and absf(ff.global_position.y - boss.global_position.y) < 34.0:
					ff.take_hit("heavy", boss)
		Mixer.play_sfx("res://assets/audio/whoosh.wav" if ResourceLoader.exists("res://assets/audio/whoosh.wav") else "res://assets/audio/sfx/throw_whoosh.ogg", randf_range(0.8, 1.0), -10.0)
	if _t > dur:
		boss.visual.scale.x = float(boss.facing)
		_end(1.4)
