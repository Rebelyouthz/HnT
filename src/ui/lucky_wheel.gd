class_name LuckyWheel
extends CanvasLayer

## The LUCKY WHEEL: eight slices, one reward, played like a real fairground
## wheel. It swings in, waits for a press (or spins itself), pulls back
## before it launches, rim bulbs chase while it turns, a rubber flapper
## clacks on every peg and the ticks get louder as it crawls to a stop. The
## winning slice lights up, rays and confetti burst from the pointer and
## gold / gems fly to their counters. Open with LuckyWheel.spin(tree, mode).

const SLICES := {
	"story": [
		["+60 GOLD", Color(1.0, 0.82, 0.3)], ["HEAL 30", Color(0.4, 0.9, 0.5)], ["LEVEL-UP CARDS", Color(0.6, 0.5, 1.0)], ["+3 KNIVES", Color(0.8, 0.85, 0.9)],
		["FULL CHI", Color(1.0, 0.5, 0.2)], ["FULL TEAM", UiKit.GOLD], ["+1 GEM", Color(0.4, 0.8, 1.0)], ["NOTHING", Color(0.35, 0.35, 0.4)],
	],
	"survivor": [
		["+12 S-COINS", Color(0.3, 0.9, 0.6)], ["HEAL HALF", Color(0.4, 0.9, 0.5)], ["FREE LEVEL", Color(0.6, 0.5, 1.0)], ["GEAR DROP", Color(1.0, 0.6, 0.2)],
		["FULL ULT", UiKit.GOLD], ["+1 REROLL", Color(0.4, 0.8, 1.0)], ["ITEM CHEST", Color(1.0, 0.82, 0.3)], ["CURSE", Color(0.8, 0.2, 0.25)],
	],
	"parkour": [
		["+12 FLOW", Color(0.5, 0.9, 1.0)], ["+40 GOLD", Color(1.0, 0.82, 0.3)], ["+1 GEM", Color(0.4, 0.8, 1.0)], ["+6 FLOW", Color(0.5, 0.9, 1.0)],
		["HEAL 30", Color(0.4, 0.9, 0.5)], ["LEVEL-UP CARDS", Color(0.6, 0.5, 1.0)], ["+25 FLOW", UiKit.GOLD], ["NOTHING", Color(0.35, 0.35, 0.4)],
	],
}
## Slices that get the jackpot treatment when they land.
const JACKPOT := ["FULL TEAM", "FULL ULT", "+25 FLOW", "ITEM CHEST", "+1 GEM", "GEAR DROP"]
const R := 220.0
const BULBS := 24
const CENTRE := Vector2(640, 380)

var mode := "story"
var _wheel: Control
var _rays: Control
var _fx: Control
var _ang := 0.0
var _vel := 0.0
## idle (waiting for a press) -> wind (pull back) -> spin -> done
var _phase := "idle"
var _phase_t := 0.0
var _was_paused := false
var _label: Label
var _prompt: Label
var _title: Label
var _last_tick := -1
var _flap := 0.0
var _flap_v := 0.0
var _win := -1
var _win_t := 0.0
var _t := 0.0
var _confetti: Array = []


static func spin(tree: SceneTree, m: String) -> void:
	if tree.get_first_node_in_group("lucky_wheel"):
		return
	var w := LuckyWheel.new()
	w.mode = m if SLICES.has(m) else "story"
	tree.current_scene.add_child(w)


func _ready() -> void:
	add_to_group("lucky_wheel")
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var root := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.03, 0.0)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.74, 0.25)
	_rays = Control.new()
	_rays.position = CENTRE
	_rays.draw.connect(_draw_rays)
	root.add_child(_rays)
	_title = UiKit.title("LUCKY WHEEL", 44, UiKit.GOLD)
	_title.size = Vector2(1280, 60)
	_title.position = Vector2(0, -60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title)
	create_tween().tween_property(_title, "position:y", 40.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wheel = Control.new()
	_wheel.position = CENTRE
	_wheel.scale = Vector2(0.2, 0.2)
	_wheel.draw.connect(_draw_wheel)
	root.add_child(_wheel)
	create_tween().tween_property(_wheel, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx = Control.new()
	_fx.draw.connect(_draw_fx)
	root.add_child(_fx)
	_label = Label.new()
	_label.position = Vector2(0, 628)
	_label.size = Vector2(1280, 60)
	_label.pivot_offset = Vector2(640, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_label, 34, Palette.TEXT)
	_label.add_theme_color_override("font_outline_color", UiKit.INK)
	_label.add_theme_constant_override("outline_size", 10)
	root.add_child(_label)
	_prompt = Label.new()
	_prompt.text = "PRESS TO SPIN"
	_prompt.position = Vector2(0, 640)
	_prompt.size = Vector2(1280, 40)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_prompt, 22, Color(1, 1, 0.9))
	root.add_child(_prompt)
	_ang = randf() * TAU
	# Spins from a wheel that is turning lazily, like it was left that way.
	_vel = 0.6


func _input(event: InputEvent) -> void:
	if _phase != "idle" or _phase_t < 0.45:
		return
	var press := event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_light") or event.is_action_pressed("p1_jump") \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if press:
		get_viewport().set_input_as_handled()
		_wind()


func _wind() -> void:
	_phase = "wind"
	_phase_t = 0.0
	_prompt.visible = false
	Mixer.play_sfx("res://assets/audio/ui/part_slide.wav", 0.8, -4.0)


func _launch() -> void:
	_phase = "spin"
	_phase_t = 0.0
	_vel = randf_range(15.0, 21.0)
	Juice.pulse_shake(2.0)
	Mixer.play_sfx("res://assets/audio/wheel.wav", 1.0, -2.0)
	Mixer.play_sfx("res://assets/audio/ui/whoosh.wav", 0.9, -3.0)


func _process(delta: float) -> void:
	_t += delta
	_phase_t += delta
	match _phase:
		"idle":
			_ang += _vel * delta
			_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 6.0)
			# Nobody pressed: it spins itself.
			if _phase_t > 2.4:
				_wind()
		"wind":
			# Pull back against the spin before letting go.
			_ang -= 2.2 * delta * (1.0 - _phase_t / 0.22)
			if _phase_t >= 0.22:
				_launch()
		"spin":
			_ang += _vel * delta
			_vel = maxf(0.0, _vel - (4.2 + _vel * 0.33) * delta)
			if _vel <= 0.04:
				_phase = "done"
				_land()
	_tick_pegs()
	# The flapper is a damped spring kicked by every peg.
	_flap_v += (-_flap * 380.0 - _flap_v * 18.0) * delta
	_flap += _flap_v * delta
	if _win >= 0:
		_win_t += delta
	_tick_confetti(delta)
	# Settle a peg bump back to size (the land / intro tweens own it otherwise).
	if _phase == "spin":
		_wheel.scale = _wheel.scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	_wheel.queue_redraw()
	_rays.queue_redraw()
	_fx.queue_redraw()


func _tick_pegs() -> void:
	var n: int = (SLICES[mode] as Array).size()
	var tick := int(floor(_ang / (TAU / float(n))))
	if tick == _last_tick:
		return
	var first := _last_tick == -1
	_last_tick = tick
	if first or _phase == "idle" or _phase == "wind":
		return
	_flap_v -= clampf(3.0 + _vel * 0.9, 3.0, 16.0)
	# Fast: a light high rattle. Crawling: every clack is heavy and loud.
	var slow := 1.0 - clampf(_vel / 12.0, 0.0, 1.0)
	Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.25 - 0.25 * slow + randf_range(-0.03, 0.03), lerpf(-12.0, -2.0, slow))
	if slow > 0.8:
		Mixer.play_sfx("res://assets/audio/ui/part_click.wav", 0.9, -6.0)
		_wheel.scale = Vector2.ONE * 1.02


func _slice_at_pointer() -> int:
	var n: int = (SLICES[mode] as Array).size()
	# The pointer sits at the top (-PI/2); find which slice is under it.
	var a := fposmod(-PI * 0.5 - _ang, TAU)
	return int(floor(a / (TAU / float(n)))) % n


func _draw_rays() -> void:
	if _win < 0:
		return
	var c: Color = SLICES[mode][_win][1]
	var grow := clampf(_win_t / 0.3, 0.0, 1.0)
	for i in 16:
		var a := _t * 0.7 + TAU * float(i) / 16.0
		var b := a + 0.11
		var len := (R + 220.0) * grow
		_rays.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(cos(a), sin(a)) * len, Vector2(cos(b), sin(b)) * len]),
			Color(c.r, c.g, c.b, 0.16 if i % 2 == 0 else 0.07))
	_rays.draw_circle(Vector2.ZERO, (R + 30.0) * grow, Color(c.r, c.g, c.b, 0.1))


func _draw_wheel() -> void:
	var sl: Array = SLICES[mode]
	var n := sl.size()
	# Shadow and a thick bevelled rim so it reads as a real object.
	_wheel.draw_circle(Vector2(8, 14), R + 26.0, Color(0, 0, 0, 0.45))
	_wheel.draw_circle(Vector2.ZERO, R + 24.0, Color(0.32, 0.2, 0.08))
	_wheel.draw_circle(Vector2.ZERO, R + 18.0, Color(0.62, 0.42, 0.16))
	_wheel.draw_circle(Vector2.ZERO, R + 4.0, Color(0.12, 0.08, 0.05))
	var pulse := 0.5 + 0.5 * sin(_win_t * 12.0)
	for i in n:
		var a0 := _ang + TAU * float(i) / float(n)
		var a1 := a0 + TAU / float(n)
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 13:
			var a := lerpf(a0, a1, float(k) / 12.0)
			pts.append(Vector2(cos(a), sin(a)) * R)
		var c: Color = sl[i][1]
		var fill := c.darkened(0.12 if i % 2 == 0 else 0.32)
		if _win >= 0:
			fill = c.lightened(0.15 + 0.2 * pulse) if i == _win else fill.darkened(0.55)
		_wheel.draw_colored_polygon(pts, fill)
		# Inner shade toward the hub gives each slice depth.
		var inner := PackedVector2Array([Vector2.ZERO])
		for k in 13:
			var a := lerpf(a0, a1, float(k) / 12.0)
			inner.append(Vector2(cos(a), sin(a)) * R * 0.34)
		_wheel.draw_colored_polygon(inner, Color(0, 0, 0, 0.22))
		_wheel.draw_line(Vector2.ZERO, Vector2(cos(a0), sin(a0)) * R, Color(1, 0.95, 0.8, 0.5), 2.0)
		var mid := (a0 + a1) * 0.5
		var big := 1.18 if i == _win else 1.0
		_wheel.draw_set_transform(Vector2(cos(mid), sin(mid)) * R * 0.63, mid + PI * 0.5, Vector2.ONE * big)
		var txt: String = sl[i][0]
		var fs := 15
		var w := UiKit.title_font().get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var ink := Color(0.04, 0.03, 0.06, 0.95 if (_win < 0 or i == _win) else 0.6)
		_wheel.draw_string_outline(UiKit.title_font(), Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, ink)
		_wheel.draw_string(UiKit.title_font(), Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.98, 0.9) if (_win < 0 or i == _win) else Color(0.6, 0.6, 0.6))
		_wheel.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _win >= 0:
		var a0 := _ang + TAU * float(_win) / float(n)
		_wheel.draw_arc(Vector2.ZERO, R - 3.0, a0, a0 + TAU / float(n), 24, Color(1, 1, 0.85, 0.6 + 0.4 * pulse), 6.0)
	# Pegs on the slice borders.
	for i in n:
		var a := _ang + TAU * float(i) / float(n)
		var p := Vector2(cos(a), sin(a)) * (R - 4.0)
		_wheel.draw_circle(p + Vector2(1, 2), 6.0, Color(0, 0, 0, 0.4))
		_wheel.draw_circle(p, 6.0, Color(0.85, 0.82, 0.75))
		_wheel.draw_circle(p + Vector2(-1.5, -1.5), 2.5, Color(1, 1, 1))
	# Rim bulbs chase while it spins and all blink together on a win.
	var speed := clampf(_vel / 18.0, 0.0, 1.0)
	for i in BULBS:
		var a := TAU * float(i) / float(BULBS)
		var p := Vector2(cos(a), sin(a)) * (R + 11.0)
		var on := false
		if _win >= 0:
			on = int(_win_t * 8.0) % 2 == 0
		elif _phase == "spin":
			on = (i + int(_t * (10.0 + 30.0 * speed))) % 4 == 0
		else:
			on = (i + int(_t * 4.0)) % 3 == 0
		var bc := Color(1.0, 0.92, 0.55) if on else Color(0.45, 0.32, 0.18)
		if on:
			_wheel.draw_circle(p, 9.0, Color(1.0, 0.85, 0.4, 0.25))
		_wheel.draw_circle(p, 4.5, bc)
	# Hub.
	_wheel.draw_circle(Vector2.ZERO, 30.0, UiKit.INK)
	_wheel.draw_circle(Vector2.ZERO, 24.0, Color(0.62, 0.42, 0.16))
	_wheel.draw_circle(Vector2.ZERO, 17.0, UiKit.GOLD)
	_wheel.draw_circle(Vector2(-5, -5), 6.0, Color(1, 1, 0.9, 0.7))
	# The flapper: a red tongue that bends on every peg and springs back.
	_wheel.draw_set_transform(Vector2(0, -R - 30.0), clampf(_flap, -0.9, 0.9), Vector2.ONE)
	_wheel.draw_colored_polygon(PackedVector2Array([Vector2(-18, -6), Vector2(18, -6), Vector2(0, 40)]), Color(0, 0, 0, 0.4))
	_wheel.draw_colored_polygon(PackedVector2Array([Vector2(-17, -10), Vector2(17, -10), Vector2(0, 36)]), Color(0.95, 0.2, 0.2))
	_wheel.draw_colored_polygon(PackedVector2Array([Vector2(-17, -10), Vector2(0, -10), Vector2(0, 36)]), Color(1.0, 0.45, 0.4))
	_wheel.draw_circle(Vector2(0, -6), 7.0, UiKit.GOLD)
	_wheel.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _land() -> void:
	_win = _slice_at_pointer()
	_win_t = 0.0
	var sl: Array = SLICES[mode]
	var what: String = sl[_win][0]
	var col: Color = sl[_win][1]
	var dud := what == "NOTHING" or what == "CURSE"
	var jackpot := JACKPOT.has(what)
	_label.text = what
	_label.add_theme_color_override("font_color", col.lightened(0.25))
	_label.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "scale", Vector2.ONE, 0.18)
	var wt := create_tween()
	wt.tween_property(_wheel, "scale", Vector2(1.08, 1.08), 0.08)
	wt.tween_property(_wheel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if dud:
		Juice.pulse_shake(3.0)
		Mixer.play_sfx("res://assets/audio/cling_fail.wav", 1.0, -2.0)
		Mixer.play_sfx("res://assets/audio/ui/deny.wav", 0.9, -4.0)
	else:
		Juice.pulse_shake(6.0 if jackpot else 4.0)
		Mixer.play_sfx("res://assets/audio/trick_perfect.wav", 1.0, -2.0)
		Mixer.play_sfx("res://assets/audio/ui/up_rise.wav", 1.0, -3.0)
		if jackpot:
			Mixer.play_sfx("res://assets/audio/ui/up_boom.wav", 1.0, -2.0)
			_title.text = "JACKPOT!"
			var tt := create_tween()
			tt.tween_property(_title, "scale", Vector2(1.15, 1.15), 0.1)
			tt.tween_property(_title, "scale", Vector2.ONE, 0.2)
		_burst_confetti(col, 70 if jackpot else 40)
	var t := get_tree().create_timer(1.6 if jackpot else 1.3, true, false, true)
	t.timeout.connect(func() -> void:
		get_tree().paused = _was_paused
		_apply(what)
		queue_free()
	)


func _burst_confetti(col: Color, count: int) -> void:
	var from := CENTRE + Vector2(0, -R - 20.0)
	var cols := [col, col.lightened(0.4), UiKit.GOLD, Color(1, 1, 1), Color(1.0, 0.4, 0.5), Color(0.4, 0.9, 1.0)]
	for i in count:
		var a := randf_range(-PI, 0.0)
		var s := randf_range(260.0, 720.0)
		_confetti.append({
			"p": from + Vector2(randf_range(-10, 10), 0),
			"v": Vector2(cos(a), sin(a)) * s,
			"c": cols[randi() % cols.size()],
			"rot": randf() * TAU, "spin": randf_range(-14.0, 14.0),
			"w": randf_range(5.0, 11.0), "life": randf_range(1.0, 1.7),
		})


func _tick_confetti(delta: float) -> void:
	for d: Dictionary in _confetti:
		var v: Vector2 = d["v"]
		v.y += 900.0 * delta
		v *= 1.0 - 1.6 * delta
		d["v"] = v
		d["p"] = (d["p"] as Vector2) + v * delta
		d["rot"] = float(d["rot"]) + float(d["spin"]) * delta
		d["life"] = float(d["life"]) - delta
	_confetti = _confetti.filter(func(d: Dictionary) -> bool: return float(d["life"]) > 0.0)


func _draw_fx() -> void:
	for d: Dictionary in _confetti:
		var c: Color = d["c"]
		c.a = clampf(float(d["life"]) * 2.0, 0.0, 1.0)
		var w: float = d["w"]
		# A paper square flipping: its height breathes with the spin.
		var h := w * absf(cos(float(d["rot"]) * 1.7)) + 1.0
		_fx.draw_set_transform(d["p"], float(d["rot"]), Vector2.ONE)
		_fx.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), c)
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Pointer position on the 640x360 viewport, where reward coins start.
func _pointer_vp() -> Vector2:
	return (CENTRE + Vector2(0, -R)) * PixelStage.design_scale()


func _apply(what: String) -> void:
	var tree := get_tree()
	var ps: Array[Fighter] = []
	for n in tree.get_nodes_in_group("players"):
		if n is Fighter:
			ps.append(n)
	var run := SurviveRun.get_run(tree)
	var rs := tree.get_first_node_in_group("run_state")
	match what:
		"+60 GOLD":
			FamilyProfile.add_gold(60)
			Juice.rewards.give("gold", 60, _pointer_vp(), false)
		"+40 GOLD":
			FamilyProfile.add_gold(40)
			Juice.rewards.give("gold", 40, _pointer_vp(), false)
		"HEAL 30":
			for f in ps:
				f.hp = mini(f.max_hp, f.hp + 30)
		"HEAL HALF":
			for f in ps:
				f.hp = mini(f.max_hp, f.hp + f.max_hp / 2)
		"LEVEL-UP CARDS":
			if rs and rs.has_signal("need_cards"):
				rs.emit_signal("need_cards")
		"+3 KNIVES":
			for f in ps:
				f.knives = mini(f.knives_max, f.knives + 3)
		"FULL CHI":
			for f in ps:
				f.chi = Elements.CHI_MAX
		"FULL TEAM":
			for f in ps:
				f.team = Elements.TEAM_MAX
		"+1 GEM":
			FamilyProfile.add_gems(1)
			Juice.rewards.give("gems", 1, _pointer_vp(), false)
		"+12 S-COINS":
			if run:
				run.coins += 12
		"FREE LEVEL":
			if run:
				run.add_xp(run.need())
		"GEAR DROP":
			SurvGear.drop(0.1)
		"FULL ULT":
			if run:
				run.ult_charge = SurviveRun.ULT_NEED
		"+1 REROLL":
			if run:
				run.rerolls += 1
		"ITEM CHEST":
			if run:
				run.open_item_chest()
		"CURSE":
			if run:
				run.traits["t_curse"] = run.trait_n("t_curse") + 1
				Juice.shout("CURSED: MORE OF THEM, MORE XP")
		"+12 FLOW":
			Trees.add_flow(12)
			Juice.rewards.give("flow", 12, _pointer_vp(), false)
		"+6 FLOW":
			Trees.add_flow(6)
			Juice.rewards.give("flow", 6, _pointer_vp(), false)
		"+25 FLOW":
			Trees.add_flow(25)
			Juice.rewards.give("flow", 25, _pointer_vp(), false)
