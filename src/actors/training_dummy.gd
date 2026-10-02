class_name TrainingDummy
extends Punk

## The dojo's sparring partner. It never dies (health tops back up), never
## walks off, and in STILL mode never swings: a body to land combos on and
## read the damage. In SPAR mode it throws slow, readable strikes and calls
## the height over its head (▲ high, ■ mid, ▼ low) in a fixed rotation, so
## the guard can be drilled: hold block and point the stick to the height.

var mode := "still"
var hits := 0
var last_dmg := 0
var _spar_t := 1.4
var _cycle := ["high", "mid", "low", "mid", "high", "low"]
var _ci := 0
var _home_x := 0.0


func _ready() -> void:
	title = "Training Dummy"
	hp = 9999
	super._ready()
	max_hp = 9999
	kit = {"attack": "light", "block": 0.0}
	_home_x = global_position.x


func _physics_process(delta: float) -> void:
	if hp < max_hp:
		hp = max_hp
		crush = false
	if flung:
		_fling(delta)
		return
	# Drift back to its mark after being knocked around.
	if absf(global_position.x - _home_x) > 4.0 and recover <= 0.0 and telegraph <= 0.0:
		global_position.x = move_toward(global_position.x, _home_x, 90.0 * delta)
	if mode == "still":
		telegraph = 0.0
		recover = maxf(recover, 0.2)
		super._physics_process(delta)
		return
	_spar_t -= delta
	if _spar_t <= 0.0 and telegraph <= 0.0 and recover <= 0.0:
		_spar_t = 1.7
		var p := _nearest()
		if p != null and absf(p.global_position.x - global_position.x) < 70.0:
			facing = 1 if p.global_position.x > global_position.x else -1
			visual.scale.x = float(facing)
			_start_telegraph()
			# Slow and fixed for drilling, whatever the difficulty.
			telegraph = 0.55
			atk_height = str(_cycle[_ci % _cycle.size()])
			_ci += 1
			_show_height()
			_pick_swing()
	super._physics_process(delta)


func _nearest() -> Fighter:
	var best: Fighter = null
	var bd := 9999.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			var d := absf((n as Fighter).global_position.x - global_position.x)
			if d < bd:
				bd = d
				best = n
	return best


func take_hit(kind: String, from: Node) -> void:
	var before := hp
	super.take_hit(kind, from)
	last_dmg = maxi(0, before - hp)
	hits += 1
	if last_dmg > 0:
		Juice.popup_number(global_position + Vector2(randf_range(-8.0, 8.0), -84.0), str(last_dmg), Color(1.0, 0.92, 0.7))


func _die(_kind: String, _from: Node) -> void:
	hp = max_hp
