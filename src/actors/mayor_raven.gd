class_name MayorRaven
extends Punk

## Politician in a ninja cape. Street / roof / both. Parries lights. SNAP after stun.

var phase := 1
var stun := 0.0
var heavies_eaten := 0
var eyes: Array[Polygon2D] = []
var _cape: Polygon2D


func _ready() -> void:
	title = "Mayor Raven"
	home = "street"
	hp = 240
	speed = 36.0
	armored = true
	cop = false
	super._ready()
	add_to_group("act_boss")
	max_hp = 240
	hp = 240
	set_meta("introed", false)
	_build_cape()


## Body height in visual units: the drawn sprite when there is one, the
## old blockout height otherwise. The cape and eyes are placed on it.
var _h := 64.0


## The collector's art (shirt, slacks, a full move set) under a charcoal
## tint reads as the mayor's suit until he has clips of his own.
func _sprite_who() -> String:
	return "gant"


func _build_cape() -> void:
	if _anim and _anim.sprite_frames:
		var tex := _anim.sprite_frames.get_frame_texture(_anim.animation, 0)
		if tex:
			_h = float(tex.get_height()) * absf(_anim.scale.y) * 0.66
		# A charcoal suit over the borrowed art (_mix_mod owns the visual's
		# modulate, the sprite's own stays ours).
		_anim.modulate = Color(0.42, 0.42, 0.52)
	var cape := Polygon2D.new()
	cape.color = Color(0.06, 0.05, 0.08, 0.97)
	visual.add_child(cape)
	# Behind the body: it hangs from the shoulders and trails back.
	visual.move_child(cape, 0)
	_cape = cape
	var lining := Polygon2D.new()
	lining.color = Color(0.55, 0.06, 0.08, 0.9)
	cape.add_child(lining)
	cape.show_behind_parent = false
	_flap()
	# Two red eyes: hidden until the lights go out in phase 3, then they are
	# what you track him by.
	var hy := -_h * 0.87 + 4.0
	for ox in [_h * 0.01, _h * 0.045]:
		var e := Polygon2D.new()
		e.color = Color(0.95, 0.2, 0.15, 0.95)
		e.polygon = PackedVector2Array([Vector2(ox - 1.5, hy - 1.2), Vector2(ox + 1.5, hy - 1.2), Vector2(ox + 1.5, hy + 0.9), Vector2(ox - 1.5, hy + 0.9)])
		Blockout.add_glow(e)
		e.visible = false
		visual.add_child(e)
		eyes.append(e)


func _physics_process(delta: float) -> void:
	if stun > 0.0:
		stun -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_alert = Color(0.7, 0.85, 1.0)
		_mix_mod()
		_flap()
		return
	_alert = Color.WHITE
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
	_flap()
	if phase == 3:
		for e in eyes:
			e.visible = true
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


func _flap() -> void:
	if _cape == null:
		return
	var t := Time.get_ticks_msec() * 0.008
	var w := 0.08 * _h * sin(t)
	var sh := -_h * 0.78
	var pts := PackedVector2Array([
		Vector2(_h * 0.1, sh), Vector2(-_h * 0.12, sh),
		Vector2(-_h * 0.34 - w, -_h * 0.32), Vector2(-_h * 0.42 - w * 1.5, -_h * 0.02),
		Vector2(-_h * 0.22 - w, -_h * 0.06), Vector2(-_h * 0.02, -_h * 0.1)
	])
	_cape.polygon = pts
	var lining := _cape.get_child(0) as Polygon2D if _cape.get_child_count() > 0 else null
	if lining:
		lining.polygon = PackedVector2Array([pts[2], pts[3], pts[4], (pts[2] + pts[4]) * 0.5 + Vector2(0, -4)])


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
