class_name MayorRaven
extends Punk

## Politician in a ninja cape. Street / roof / both. Parries lights. SNAP after stun.

var phase := 1
var stun := 0.0
var heavies_eaten := 0
var eyes: Array[Polygon2D] = []


func _ready() -> void:
	title = "Mayor Raven"
	home = "street"
	hp = 240
	speed = 36.0
	armored = true
	cop = false
	super._ready()
	max_hp = 240
	hp = 240
	_cape()


func _cape() -> void:
	var cape := Polygon2D.new()
	cape.color = Color(0.08, 0.08, 0.1, 0.95)
	cape.polygon = PackedVector2Array([
		Vector2(-22, -48), Vector2(22, -48), Vector2(36, 8), Vector2(-36, 8)
	])
	visual.add_child(cape)
	for ox in [-8.0, 8.0]:
		var e := Polygon2D.new()
		e.color = Color(0.95, 0.2, 0.15, 0.95)
		e.polygon = PackedVector2Array([
			Vector2(ox - 4, -62), Vector2(ox + 4, -62), Vector2(ox + 4, -54), Vector2(ox - 4, -54)
		])
		Blockout.add_glow(e)
		visual.add_child(e)
		eyes.append(e)


func _physics_process(delta: float) -> void:
	if stun > 0.0:
		stun -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		visual.modulate = Color(0.7, 0.85, 1.0)
		return
	visual.modulate = Color.WHITE
	var ratio := float(hp) / float(maxi(max_hp, 1))
	if phase == 1 and ratio <= 0.66:
		_phase(2)
	elif phase == 2 and ratio <= 0.33:
		_phase(3)
	if phase >= 2 and home != "roof" and randf() < 0.004:
		home = "roof"
		global_position.y = 248.0
	elif phase == 1:
		home = "street"
	super._physics_process(delta)
	if phase == 3:
		for e in eyes:
			e.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.012)


func _phase(n: int) -> void:
	phase = n
	heavies_eaten = 0
	armored = true
	stun = 0.0
	if n == 2:
		home = "roof"
		global_position.y = 248.0
		Juice.shout("ROOF PROTOCOL")
		Juice.toast("challenge", "PHASE 2", "He took the roofs. You take the statues.")
	elif n == 3:
		var rig := get_tree().get_first_node_in_group("light_rig")
		if rig and rig.has_method("blackout"):
			rig.blackout()
		Juice.shout("LIGHTS OUT")
		Juice.unlock_logo("PHASE 3", "Muzzle flashes and his eyes. SNAP when he stuns.")
		Juice.pulse_shake(10.0)


func take_hit(kind: String, from: Node) -> void:
	if kind == "light":
		Juice.play("res://assets/audio/block.wav")
		Juice.flash_red(visual, 1)
		Juice.shout("PARRY")
		return
	if kind == "heavy" or kind == "launcher":
		if armored and heavies_eaten == 0:
			heavies_eaten = 1
			armored = false
			Juice.shout("ATE IT")
			Juice.hitstop(6)
			return
		heavies_eaten += 1
		if heavies_eaten >= 3:
			stun = 1.4
			Juice.shout("STUN")
			Juice.freeze_frames(6)
	if kind == "snap" and stun <= 0.0:
		Juice.shout("NOT YET")
		Juice.flash_red(visual, 2)
		return
	super.take_hit(kind, from)
