class_name TrainingDummy
extends Punk

## The dojo's sparring partner. It never dies (health tops back up), never
## walks off, and in STILL mode never swings: a body to land combos on and
## read the damage. In SPAR mode it throws slow, readable strikes and calls
## the height over its head (▲ high, ■ mid, ▼ low) in a fixed rotation, so
## the guard can be drilled: hold block and point the stick to the height.

signal struck(kind: String)

var mode := "still"
var hits := 0
var last_dmg := 0
var _spar_t := 1.4
var _cycle := ["high", "mid", "low", "mid", "high", "low"]
var _ci := 0
var _home_x := 0.0
var _home_y := 0.0
## A heavy bag, not a thug: the old clipboard-punk body read as an enemy
## that never fought. The punk clips stay underneath (hidden) so every
## reaction and finisher path still has its animations.
var _bag: Sprite2D


func _ready() -> void:
	title = "Training Dummy"
	hp = 9999
	super._ready()
	max_hp = 9999
	kit = {"attack": "light", "block": 0.0}
	_home_x = global_position.x
	_home_y = global_position.y
	var tex := load("res://assets/sprites/yard/props/heavy_bag.png") as Texture2D
	if tex != null:
		if _anim:
			_anim.visible = false
		_bag = Sprite2D.new()
		_bag.texture = tex
		_bag.centered = false
		# Pivot on the weighted base so it rocks like a real stand-up bag.
		_bag.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()))
		_bag.scale = Vector2(SpriteBook.DRAW_SCALE, SpriteBook.DRAW_SCALE)
		_bag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.add_child(_bag)


## The bag rocks away from a blow (or toward you when it "swings back").
func _rock(amount: float) -> void:
	if _bag == null:
		return
	var tw := _bag.create_tween()
	tw.tween_property(_bag, "rotation", amount, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bag, "rotation", -amount * 0.45, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bag, "rotation", amount * 0.15, 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bag, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_SINE)


func _physics_process(delta: float) -> void:
	if hp < max_hp:
		hp = max_hp
		crush = false
	# A bag on a weighted stand: it rocks, it never flies off or slides away.
	# Still mode keeps recover up, so the old drift back to the mark never
	# ran and a hard blow sent the bag down the alley for good.
	if mode == "still":
		flung = false
		var home := Vector2(_home_x, _home_y)
		if global_position.distance_to(home) > 30.0:
			global_position = home + (global_position - home).normalized() * 30.0
		if global_position.distance_to(home) > 1.0:
			global_position = global_position.move_toward(home, 220.0 * delta)
	elif flung:
		_fling(delta)
		return
	elif absf(global_position.x - _home_x) > 4.0 and recover <= 0.0 and telegraph <= 0.0:
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
			_rock(-0.22 * float(facing) * visual.scale.x)
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
	flung = false
	flung_t = 0.0
	velocity = Vector2.ZERO
	last_dmg = maxi(0, before - hp)
	hits += 1
	struck.emit(kind)
	var heavy := kind in ["heavy", "finish", "throw", "uppercut"]
	var side := 1.0
	if from is Node2D:
		side = 1.0 if (from as Node2D).global_position.x < global_position.x else -1.0
	_rock((0.32 if heavy else 0.16) * side * visual.scale.x)
	if last_dmg > 0:
		Juice.popup_number(global_position + Vector2(randf_range(-8.0, 8.0), -84.0), str(last_dmg), Color(1.0, 0.92, 0.7))


func _die(_kind: String, _from: Node) -> void:
	hp = max_hp
