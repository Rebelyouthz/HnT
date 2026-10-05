class_name LuckyWheel
extends CanvasLayer

## The LUCKY WHEEL: eight slices, a spin that slows to a tick, one reward.
## Story nights, survivor hours and parkour medals each have their own
## slices. Open with LuckyWheel.spin(tree, mode).

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

var mode := "story"
var _wheel: Control
var _ang := 0.0
var _vel := 0.0
var _done := false
var _was_paused := false
var _label: Label
var _last_tick := -1


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
	dim.color = Color(0, 0, 0.03, 0.7)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	var t := UiKit.title("LUCKY WHEEL", 44, UiKit.GOLD)
	t.position = Vector2(0, 40)
	t.size = Vector2(1280, 60)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(t)
	_wheel = Control.new()
	_wheel.position = Vector2(640, 380)
	_wheel.draw.connect(_draw_wheel)
	root.add_child(_wheel)
	_label = Label.new()
	_label.position = Vector2(0, 640)
	_label.size = Vector2(1280, 40)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_label, 26, Palette.TEXT)
	root.add_child(_label)
	_ang = randf() * TAU
	_vel = randf_range(14.0, 20.0)
	Mixer.play_sfx("res://assets/audio/wheel.wav", 1.0, -2.0)


func _process(delta: float) -> void:
	if _done:
		return
	_ang += _vel * delta
	_vel = maxf(0.0, _vel - (4.5 + _vel * 0.35) * delta)
	var n: int = (SLICES[mode] as Array).size()
	var tick := int(floor(_ang / (TAU / float(n))))
	if tick != _last_tick:
		_last_tick = tick
		Mixer.play_sfx("res://assets/audio/ui_click.wav", 1.2 + 0.4 * clampf(_vel / 20.0, 0.0, 1.0), -10.0)
	_wheel.queue_redraw()
	if _vel <= 0.05:
		_done = true
		_land()


func _slice_at_pointer() -> int:
	var n: int = (SLICES[mode] as Array).size()
	# The pointer sits at the top (-PI/2); find which slice is under it.
	var a := fposmod(-PI * 0.5 - _ang, TAU)
	return int(floor(a / (TAU / float(n)))) % n


func _draw_wheel() -> void:
	var sl: Array = SLICES[mode]
	var n := sl.size()
	var r := 220.0
	for i in n:
		var a0 := _ang + TAU * float(i) / float(n)
		var a1 := a0 + TAU / float(n)
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 13:
			var a := lerpf(a0, a1, float(k) / 12.0)
			pts.append(Vector2(cos(a), sin(a)) * r)
		var c: Color = sl[i][1]
		_wheel.draw_colored_polygon(pts, c.darkened(0.15 if i % 2 == 0 else 0.35))
		var mid := (a0 + a1) * 0.5
		_wheel.draw_set_transform(Vector2(cos(mid), sin(mid)) * r * 0.6, mid + PI * 0.5, Vector2.ONE)
		var txt: String = sl[i][0]
		var w := UiKit.title_font().get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_wheel.draw_string(UiKit.title_font(), Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.05, 0.05, 0.08))
		_wheel.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_wheel.draw_arc(Vector2.ZERO, r, 0, TAU, 64, UiKit.GOLD, 6.0)
	_wheel.draw_circle(Vector2.ZERO, 22.0, UiKit.INK)
	_wheel.draw_circle(Vector2.ZERO, 14.0, UiKit.GOLD)
	for i in n:
		var a := _ang + TAU * float(i) / float(n)
		_wheel.draw_circle(Vector2(cos(a), sin(a)) * (r - 2.0), 5.0, Color(1, 1, 0.9))
	# Pointer.
	_wheel.draw_colored_polygon(PackedVector2Array([Vector2(-16, -r - 26), Vector2(16, -r - 26), Vector2(0, -r + 8)]), Color(1, 0.25, 0.25))


func _land() -> void:
	var i := _slice_at_pointer()
	var sl: Array = SLICES[mode]
	var what: String = sl[i][0]
	_label.text = what
	_label.add_theme_color_override("font_color", sl[i][1])
	Juice.pulse_shake(4.0)
	Mixer.play_sfx("res://assets/audio/trick_perfect.wav" if what != "NOTHING" and what != "CURSE" else "res://assets/audio/cling_fail.wav", 1.0, -2.0)
	var t := get_tree().create_timer(1.3, true, false, true)
	t.timeout.connect(func() -> void:
		get_tree().paused = _was_paused
		_apply(what)
		queue_free()
	)


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
		"+40 GOLD":
			FamilyProfile.add_gold(40)
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
		"+6 FLOW":
			Trees.add_flow(6)
		"+25 FLOW":
			Trees.add_flow(25)
