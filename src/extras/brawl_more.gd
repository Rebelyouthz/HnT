class_name BrawlMore
extends Node

## Five more brawl rules (story streets and survivor):
##   FINISHER      a thug at low health who is staggered shows a blinking
##                 skull: a HEAVY on him is an execution - slow motion, zoom,
##                 an impact frame, extra gore and a bonus
##   IMPACT FRAME  heavy and special kills flash one frame white and one
##                 frame dark with the hit frozen (the anime/fighting-game cut)
##   SCREEN KILL   now and then a heavy kill sends the body flying at the
##                 camera; it cracks the screen
##   STEAM REFUND  (SoR4) a special's steam comes back if you land three
##                 hits after it without getting hit
##   COMBO BURST   25 / 50 / 100 hit combos burst: everyone close goes down,
##                 coins rain

const FINISH_FRAC := 0.22
const REFUND_HITS := 3

static var _refund := {}
static var _burst_at := 0
static var me: BrawlMore

var _layer: CanvasLayer
var _flash: ColorRect
var _crack: Control
var _t := 0.0


func _ready() -> void:
	me = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 70
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	_layer.add_child(_flash)
	_crack = Crack.new()
	_crack.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_crack)
	_burst_at = 0


func _process(delta: float) -> void:
	_t += delta
	# Finisher prompts on staggered, nearly dead thugs.
	if fmod(_t, 0.1) < delta:
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Punk:
				var e := n as Punk
				var ok := finishable(e)
				var mark: Node = e.get_node_or_null("FinishMark")
				if ok and mark == null:
					var m := FinishMark.new()
					m.name = "FinishMark"
					m.position = Vector2(0, -110)
					e.add_child(m)
				elif not ok and mark != null:
					mark.queue_free()
	# Combo bursts.
	var c := int(Juice.combo)
	if c < _burst_at:
		_burst_at = 0
	for step in [25, 50, 100]:
		if c >= step and _burst_at < step:
			_burst_at = step
			_combo_burst(step)


static func finishable(e: Punk) -> bool:
	if e == null or e.hp <= 0 or e.flung or e is ActBoss:
		return false
	var mx := maxi(1, int(e.get("max_hp")) if e.get("max_hp") != null else e.hp)
	return float(e.hp) <= float(mx) * FINISH_FRAC and (e.recover > 0.0 or e.get("_hurt_t") > 0.0)


## A hero's blow (Punk.take_hit via BrawlPlus.on_blow): may turn a heavy
## into a FINISHER. Returns the damage to deal.
static func on_blow(e: Punk, f: Fighter, kind: String, dmg: int) -> int:
	note_hit(f)
	if kind in ["heavy", "special", "combo"] and finishable(e):
		e.set_meta("finisher", true)
		return maxi(dmg, e.hp + 999)
	return dmg


## A thug died (Punk._die): finisher / impact frame / screen kill.
static func on_kill(e: Punk, kind: String, by: Node) -> void:
	ItemRack.on_kill(by)
	if me == null or not is_instance_valid(me):
		return
	var fin := bool(e.get_meta("finisher", false))
	if fin:
		me._finisher(e, by)
	elif kind in ["heavy", "special"] and by is Fighter:
		me.impact(0.5)
		if randf() < 0.12:
			me._screen_kill(e)


static func special_used(f: Fighter, cost: float) -> void:
	_refund[f.get_instance_id()] = {"cost": cost, "hits": 0}


static func note_hit(f: Fighter) -> void:
	var r: Dictionary = _refund.get(f.get_instance_id(), {})
	if r.is_empty():
		return
	r["hits"] = int(r["hits"]) + 1
	if int(r["hits"]) >= REFUND_HITS:
		_refund.erase(f.get_instance_id())
		var back := float(r["cost"]) * 0.6
		f.steam = minf(Fighter.STEAM_MAX, f.steam + back)
		Juice.popup_number(f.global_position + Vector2(0, -110), "STEAM +%d" % int(back), Color(0.4, 1.0, 0.55))
		RewardFly.snd("up_rise", 1.6, -10.0)


## The hero got hit: the refund is gone.
static func hero_hit(f: Fighter) -> void:
	_refund.erase(f.get_instance_id())


func impact(strength: float) -> void:
	Juice.hitstop(4 + int(strength * 4.0))
	_flash.visible = true
	_flash.color = Color(1, 1, 1, 0.75 * strength)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.033)
	tw.tween_callback(func() -> void: _flash.color = Color(0.0, 0.0, 0.02, 0.55 * strength))
	tw.tween_interval(0.033)
	tw.tween_callback(func() -> void: _flash.visible = false)


func _finisher(e: Punk, by: Node) -> void:
	impact(1.0)
	Juice.shout("FINISHER")
	Juice.pulse_shake(9.0)
	Juice.slowmo(0.3)
	get_tree().create_timer(0.45, true, false, true).timeout.connect(Juice.restore_time)
	CouchCamera.punch(get_tree(), 0.18, 0.5, e.global_position + Vector2(0, -40))
	for i in 3:
		Juice.kill_burst(e.global_position + Vector2(randf_range(-10, 10), randf_range(-60, -20)), "heavy")
	Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 0.7, 0.0)
	RewardFly.snd("up_boom", 0.8, -3.0)
	if by is Fighter:
		(by as Fighter).chi = minf(Elements.CHI_MAX, (by as Fighter).chi + 15.0)
	FamilyProfile.add_gold(5)
	Juice.rewards.give("gold", 5, e.get_global_transform_with_canvas().origin + Vector2(0, -40), false)
	FamilyProfile.data["finishers"] = int(FamilyProfile.data.get("finishers", 0)) + 1


func _screen_kill(e: Punk) -> void:
	# A ghost of the body flies at the lens, then the glass cracks.
	var vis: CanvasItem = e.get("visual")
	if vis == null:
		return
	var ghost := Sprite2D.new()
	var anim := vis.find_child("*", true, false) as AnimatedSprite2D if not (vis is AnimatedSprite2D) else vis as AnimatedSprite2D
	if anim == null or anim.sprite_frames == null:
		return
	ghost.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var at := e.get_global_transform_with_canvas().origin + Vector2(0, -30)
	ghost.position = at
	ghost.scale = Vector2.ONE * 0.25
	_layer.add_child(ghost)
	var c := get_viewport().get_visible_rect().size * 0.5
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(ghost, "position", c + Vector2(randf_range(-80, 80), randf_range(-40, 20)), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(ghost, "scale", Vector2.ONE * 1.6, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(ghost, "rotation", randf_range(-1.5, 1.5), 0.22)
	tw.tween_callback(func() -> void:
		(_crack as Crack).hit(ghost.position)
		Juice.shout("SCREEN KILL")
		Juice.pulse_shake(8.0)
		Mixer.play_sfx("res://assets/audio/sfx/glass_break.ogg", 0.8, 0.0))
	tw.tween_property(ghost, "position:y", ghost.position.y + 400.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(ghost, "modulate:a", 0.0, 0.6)
	tw.tween_callback(ghost.queue_free)


func _combo_burst(step: int) -> void:
	var f: Fighter = null
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and str((n as Fighter).role) == str(Juice.last_hitter):
			f = n
	if f == null:
		return
	impact(0.7)
	Juice.shout("COMBO %d" % step)
	ArtFx.spawn(f.get_parent(), f.global_position, "ring", UiKit.GOLD, 180.0, 0.5)
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Punk and (n as Punk).global_position.distance_to(f.global_position) < 180.0 and not (n is ActBoss):
			var e := n as Punk
			e.flung = true
			e.flung_dir = signf(e.global_position.x - f.global_position.x)
			e.flung_t = 0.3
			e.flung_ground = false
	var gold := step / 5
	FamilyProfile.add_gold(gold)
	Juice.rewards.give("gold", gold, f.get_global_transform_with_canvas().origin + Vector2(0, -60))


## The blinking skull over a thug you can finish.
class FinishMark extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if fmod(_t, 0.4) > 0.28:
			return
		var c := Color(1.0, 0.3, 0.25)
		draw_circle(Vector2(0, 0), 6.0, c)
		draw_rect(Rect2(-4, 3, 8, 5), c)
		draw_circle(Vector2(-2, -1), 1.6, Color(0, 0, 0))
		draw_circle(Vector2(2, -1), 1.6, Color(0, 0, 0))
		draw_string(UiKit.pixel_font(), Vector2(-14, -10), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, c)


## Cracked glass where a body hit the lens; fades out.
class Crack extends Control:
	var _at := Vector2.ZERO
	var _life := 0.0
	var _lines: Array = []

	func hit(at: Vector2) -> void:
		_at = at
		_life = 1.2
		_lines.clear()
		for i in 12:
			var a := TAU * float(i) / 12.0 + randf_range(-0.2, 0.2)
			var pts := PackedVector2Array([at])
			var p := at
			for k in 4:
				p += Vector2.from_angle(a + randf_range(-0.4, 0.4)) * randf_range(14.0, 30.0)
				pts.append(p)
			_lines.append(pts)

	func _process(delta: float) -> void:
		if _life > 0.0:
			_life -= delta
			queue_redraw()

	func _draw() -> void:
		if _life <= 0.0:
			return
		var a := clampf(_life, 0.0, 1.0)
		for pts: PackedVector2Array in _lines:
			draw_polyline(pts, Color(1, 1, 1, 0.85 * a), 1.0)
		draw_circle(_at, 6.0, Color(1, 1, 1, 0.4 * a))
