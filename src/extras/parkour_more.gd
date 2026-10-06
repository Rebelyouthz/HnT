class_name ParkourMore
extends Node2D

## Five more for the roofs (with ParkourPlus):
##   PURSUER    (Vector) on the race maps a repo agent runs you down from
##              behind; keep your speed up or he catches you (HP, he is
##              shoved back); a meter shows how close he is
##   BIG AIR    a fast, long jump goes cinematic: slow motion, letterbox bars
##   MOMENTUM   keep running without stopping and it builds: a blue aura,
##              FLOW every time it fills
##   RINGS      rings float over the roofs; fly through them for FLOW, all of
##              them for a bonus (the chime climbs as you chain them)
##   STYLE      at the goal a grade from D to SSS for flow, rings, air and
##              not getting caught

var act: Node
var map_id := ""
var goal_x := 0.0
var race := false

var _t := 0.0
var _flow0 := 0
var _rings: Array[Node2D] = []
var _got := 0
var _chain_t := 0.0
var _chain := 0
var _caught := 0
var _air := 0.0
var _big_cd := 0.0
var _mom := 0.0
var _mom_paid := false
var _done := false
var _agent: Node2D
var _agent_anim: AnimatedSprite2D
var _agent_v := 0.0
var _hud: Control
var _gap_bar: ColorRect
var _mom_bar: ColorRect
var _bars: Array[ColorRect] = []
var _air_best := 0.0


func _ready() -> void:
	_flow0 = int(FamilyProfile.data.get("flow", 0))
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var root := PixelStage.attach_canvas(layer)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Letterbox bars for BIG AIR.
	for y in [0.0, 1.0]:
		var b := ColorRect.new()
		b.color = Color(0, 0, 0.02)
		b.size = Vector2(1280, 0)
		b.position = Vector2(0, y * 720.0)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(b)
		_bars.append(b)
	_hud = VBoxContainer.new()
	_hud.position = Vector2(1040, 120)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_hud as VBoxContainer).add_theme_constant_override("separation", 4)
	root.add_child(_hud)
	_mom_bar = _meter("MOMENTUM", Color(0.4, 0.85, 1.0))
	if race:
		_gap_bar = _meter("AGENT", Color(1.0, 0.35, 0.3))
	call_deferred("_setup")


func _meter(title: String, col: Color) -> ColorRect:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(90, 0)
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 10, col)
	row.add_child(l)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0.02, 0.8)
	bg.custom_minimum_size = Vector2(120, 8)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bg)
	var fg := ColorRect.new()
	fg.color = col
	fg.size = Vector2(0, 8)
	bg.add_child(fg)
	_hud.add_child(row)
	return fg


func _setup() -> void:
	# Rings over the roof tops, spread along the map.
	var tops: Array[Rect2] = []
	for r in get_tree().get_nodes_in_group("roof_solids"):
		var rect: Rect2 = r.get_meta("rect", Rect2())
		if rect.size.x > 80.0:
			tops.append(rect)
	tops.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	var step := maxi(1, tops.size() / 6)
	for i in range(0, tops.size(), step):
		var rr := tops[i]
		var ring := Ring.new()
		ring.global_position = Vector2(rr.end.x + 30.0, rr.position.y - 70.0)
		ring.z_index = 3
		act.add_child(ring)
		_rings.append(ring)
	if race and SpriteBook.has_who("roof_runner"):
		_agent = Node2D.new()
		_agent.z_index = 2
		_agent.modulate = Color(1.0, 0.75, 0.75)
		act.add_child(_agent)
		_agent_anim = SpriteBook.make_anim("roof_runner")
		SpriteBook.grow(_agent_anim, SpriteBook.FIGHTER_SCALE)
		_agent.add_child(_agent_anim)
		if _agent_anim.sprite_frames.has_animation("walk"):
			_agent_anim.play("walk")
		_agent.visible = false


func _lead() -> Fighter:
	var best: Fighter = null
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed and (best == null or (n as Fighter).global_position.x > best.global_position.x):
			best = n
	return best


func _physics_process(delta: float) -> void:
	_t += delta
	var f := _lead()
	if f == null or _done:
		return
	if f.global_position.x >= goal_x and goal_x > 0.0:
		_finish(f)
		return
	_rings_tick(f, delta)
	_momentum(f, delta)
	_big_air(f, delta)
	_pursuer(f, delta)


func _rings_tick(f: Fighter, delta: float) -> void:
	_chain_t -= delta
	if _chain_t <= 0.0:
		_chain = 0
	var body := f.global_position + Vector2(0, f.visual.position.y - 40.0)
	for r in _rings:
		if is_instance_valid(r) and not r.get_meta("got", false) and body.distance_to(r.global_position) < 26.0:
			r.set_meta("got", true)
			(r as Ring).take()
			_got += 1
			_chain += 1
			_chain_t = 2.5
			Trees.add_flow(2)
			Mixer.play_sfx("res://assets/audio/ui/coin_land.wav", 1.0 + 0.12 * float(_chain), -4.0)
			Juice.popup_number(r.global_position + Vector2(0, -20), "RING %d/%d" % [_got, _rings.size()], Color(0.6, 0.9, 1.0))
			if _got == _rings.size():
				Trees.add_flow(15)
				Juice.shout("ALL RINGS")
				Juice.rewards.upgrade(null, Color(0.6, 0.9, 1.0), "ALL RINGS  +15 FLOW", true)


func _momentum(f: Fighter, delta: float) -> void:
	var running := absf(f.velocity.x) > 190.0
	_mom = clampf(_mom + (delta / 4.0 if running else -delta * 1.5), 0.0, 1.0)
	_mom_bar.size.x = 120.0 * _mom
	if _mom >= 1.0 and not _mom_paid:
		_mom_paid = true
		Trees.add_flow(4)
		Juice.popup_number(f.global_position + Vector2(0, -120), "MOMENTUM  +4 FLOW", Color(0.4, 0.85, 1.0))
		RewardFly.snd("up_rise", 1.3, -8.0)
	elif _mom < 0.5:
		_mom_paid = false
	f.visual.modulate = Color.WHITE.lerp(Color(0.75, 0.95, 1.2), _mom * 0.6) if _mom > 0.2 else Color.WHITE


func _big_air(f: Fighter, delta: float) -> void:
	_big_cd -= delta
	var airborne := f.hop < -10.0 or (f.plane == "roof" and not f.is_on_floor())
	if airborne:
		_air += delta
		_air_best = maxf(_air_best, _air)
		if _air > 0.45 and absf(f.velocity.x) > 250.0 and _big_cd <= 0.0:
			_big_cd = 6.0
			Juice.shout("BIG AIR")
			Juice.slowmo(0.5)
			get_tree().create_timer(0.35, true, false, true).timeout.connect(Juice.restore_time)
			CouchCamera.punch(get_tree(), 0.06, 0.5, f.global_position)
			for b in _bars:
				var tw := b.create_tween().set_ignore_time_scale(true)
				var down := b.position.y > 100.0
				tw.tween_property(b, "size:y", 48.0, 0.12)
				if down:
					tw.parallel().tween_property(b, "position:y", 672.0, 0.12)
				tw.tween_interval(0.55)
				tw.tween_property(b, "size:y", 0.0, 0.2)
				if down:
					tw.parallel().tween_property(b, "position:y", 720.0, 0.2)
	else:
		_air = 0.0


func _pursuer(f: Fighter, delta: float) -> void:
	if _agent == null:
		return
	if _t < 3.0:
		return
	if not _agent.visible:
		_agent.visible = true
		_agent.global_position = f.global_position + Vector2(-320.0, 0)
		Juice.shout("REPO AGENT")
	# Rubber band: fast when far behind, a little slower than a hero who
	# keeps running.
	var gap := f.global_position.x - _agent.global_position.x
	var want := 205.0 + clampf((gap - 160.0) * 0.6, -60.0, 140.0)
	_agent_v = move_toward(_agent_v, want, 400.0 * delta)
	_agent.global_position.x += _agent_v * delta
	_agent.global_position.y = lerpf(_agent.global_position.y, f.global_position.y, minf(1.0, delta * 3.0))
	_agent_anim.position.y = f.visual.position.y * 0.6
	_agent_anim.scale.x = absf(_agent_anim.scale.x)
	if _gap_bar:
		_gap_bar.size.x = 120.0 * clampf(1.0 - gap / 320.0, 0.0, 1.0)
	if gap < 26.0:
		_caught += 1
		f.hp = maxi(1, f.hp - 1)
		Juice.flash_red(f.visual)
		Juice.shout("CAUGHT")
		Juice.pulse_shake(6.0)
		Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.9, -4.0)
		_agent.global_position.x -= 220.0
		_agent_v = 0.0


func _finish(f: Fighter) -> void:
	_done = true
	if _agent:
		_agent.queue_free()
	var flow := int(FamilyProfile.data.get("flow", 0)) - _flow0
	var pts := flow + _got * 3 + int(_air_best * 6.0) - _caught * 8
	var grades := [["SSS", 70], ["SS", 55], ["S", 42], ["A", 30], ["B", 20], ["C", 10], ["D", -999]]
	var g := "D"
	for pair in grades:
		if pts >= int(pair[1]):
			g = str(pair[0])
			break
	var best := str(FamilyProfile.data.get("style_" + map_id, ""))
	var order := ["D", "C", "B", "A", "S", "SS", "SSS"]
	if order.find(g) > order.find(best):
		FamilyProfile.data["style_" + map_id] = g
		FamilyProfile.save()
	var col := Color(1.0, 0.56, 0.12) if g.begins_with("S") else (Color(0.4, 0.85, 1.0) if g == "A" else Palette.TEXT)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		Juice.rewards.reveal("node_score", "STYLE  %s" % g, col, "FLOW %d  ·  RINGS %d/%d  ·  AIR %.1fs  ·  CAUGHT %d" % [flow, _got, _rings.size(), _air_best, _caught]))


## A ring floating over a roof edge.
class Ring extends Node2D:
	var _t := 0.0
	var _taken := -1.0

	func take() -> void:
		_taken = 0.0
		ArtFx.spawn(get_parent(), global_position + Vector2(0, 20), "ring", Color(0.6, 0.9, 1.0), 40.0, 0.3)

	func _process(delta: float) -> void:
		_t += delta
		if _taken >= 0.0:
			_taken += delta
			if _taken > 0.3:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 3.0) * 3.0
		var k := 1.0 + (_taken * 2.0 if _taken >= 0.0 else 0.0)
		var a := 1.0 - (_taken / 0.3 if _taken >= 0.0 else 0.0)
		draw_set_transform(Vector2(0, bob), 0.0, Vector2(0.45 * k, 1.0 * k))
		draw_arc(Vector2.ZERO, 18.0, 0, TAU, 28, Color(0.6, 0.9, 1.0, 0.9 * a), 3.0)
		draw_arc(Vector2.ZERO, 14.0, 0, TAU, 28, Color(1, 1, 1, 0.5 * a), 1.0)
