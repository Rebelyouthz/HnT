class_name ActBoss
extends Punk

var display := ""
var is_mini := false
var accent := Color(0.72, 0.22, 0.2)
var sub := ""
var introed := false
## Bosses break down in four stages (100 / 75 / 50 / 25 % hp): each one
## lands with a stagger, a roar and a blood burst, and leaves them more torn,
## bloodier and angrier; the last one bleeds as they walk.
var stage := 0
var _drip := 0.0


func _ready() -> void:
	if title == "":
		title = display if display != "" else "Named Problem"
	super._ready()
	add_to_group("act_boss")
	if is_mini:
		add_to_group("act_mini")
	else:
		add_to_group("act_final_boss")
	armored = not is_mini
	_crown()
	died.connect(_on_dead)


func _crown() -> void:
	if _anim != null:
		return
	var band := Polygon2D.new()
	band.color = accent
	band.polygon = PackedVector2Array([
		Vector2(-22, -86), Vector2(22, -86), Vector2(16, -70), Vector2(-16, -70)
	])
	Blockout.add_glow(band)
	visual.add_child(band)
	visual.modulate = accent.lerp(Color.WHITE, 0.35)


func _on_dead() -> void:
	var act := get_tree().get_first_node_in_group("run_act")
	if is_mini:
		Juice.toast("challenge", "MINI DOWN", "%s filed. The street keeps going. That's the bit." % title.to_upper())
		Juice.shout("MINI FILED")
		if act and act.has_method("on_mini_down"):
			act.on_mini_down()
		return
	Juice.toast("quest", "BOSS FILED", "%s is a receipt now." % title.to_upper())
	# Gant's office had something hanging in the closet.
	if act is RunAct and (act as RunAct).map_id == "dock_street":
		Suits.grant("bat")
		Suits.grant("spider")
	var charm := Charms.roll()
	if charm != "":
		Charms.grant(charm)
	if act and act.has_method("finish_boss"):
		act.finish_boss()


func take_hit(kind: String, from: Node) -> void:
	super.take_hit(kind, from)
	if hp <= 0 or not is_inside_tree():
		return
	var frac := float(hp) / float(maxi(max_hp, 1))
	var want := 0
	if frac <= 0.25:
		want = 3
	elif frac <= 0.5:
		want = 2
	elif frac <= 0.75:
		want = 1
	while stage < want:
		stage += 1
		_break_stage(from)
	_dress_stage()


func _break_stage(from: Node) -> void:
	var dir := -float(facing)
	if from is Node2D:
		dir = signf(global_position.x - (from as Node2D).global_position.x)
	Juice.hitstop(10)
	Juice.pulse_shake(9.0 + 3.0 * float(stage))
	Juice.play("res://assets/audio/boss_roar.wav" if ResourceLoader.exists("res://assets/audio/boss_roar.wav") else "res://assets/audio/kill.wav")
	Juice.shout(["", "HE'S BLEEDING", "SHIRT'S GONE", "ONE MORE"][stage])
	var blood := get_tree().get_first_node_in_group("blood_sim")
	if blood:
		blood.hit(self, "head", dir, 1.0, 1.0)
		blood.pump(global_position, dir)
		if stage >= 2:
			blood.screen(dir, 0.8)
	HitReact.react(visual, facing, "low" if stage == 2 else "gut", dir, 1.0)
	recover = maxf(recover, 0.9)
	telegraph = 0.0
	# Angrier: faster, harder to stagger after each break.
	speed *= 1.15
	_walk = speed


func _dress_stage() -> void:
	if _anim == null:
		return
	var hurt := 1.0 - float(hp) / float(maxi(max_hp, 1))
	BloodSim.wound(_anim, maxf(hurt * 1.15, [0.0, 0.35, 0.6, 0.9][stage]), maxf(_splat, [0.0, 0.3, 0.6, 0.9][stage]), 1.0)
	var m := _anim.material as ShaderMaterial
	if m:
		m.set_shader_parameter("tear", [0.0, 0.3, 0.65, 1.0][stage])
	# A rage tint that deepens.
	_base_mod = Color.WHITE.lerp(Color(1.15, 0.8, 0.78), float(stage) / 3.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if stage >= 3 and hp > 0:
		_drip -= delta
		if _drip <= 0.0:
			_drip = 0.25
			var blood := get_tree().get_first_node_in_group("blood_sim")
			if blood:
				blood.burst(global_position + Vector2(randf_range(-4, 4), -30), global_position.y, -float(facing), {"n": 2, "speed": 40.0, "spread": 0.6, "rise": 0.1, "size": 1.2, "h": -30})
