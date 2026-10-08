class_name RooftopRun
extends Node2D

## THE ROOFTOP RUN (Fire Escapes): its own mode. A long line of roofs at
## dusk, a hunter running your own line a few seconds behind, and the
## flow of a real runner - momentum, contextual vaults / climbs / slides,
## loaded tricks released at the edge and landings that have to be met.
## Reach the zipline mast on the last roof before he closes the gap.

const MAP_ID := "fire_escapes"
const NEXT_ID := "group_circle"
const BUILDINGS := 22

var course: RoofCourse
var runners: Array[Runner] = []
var hunter: Hunter
var cam: Camera2D
var state: RunState
var _hud: Control
var _world_ui: Node2D
var _layers: Array = []
var _t := 0.0
var _go := false
var _done := false
var _count := 3.2
var _feed: Array = []      # [text, color, t]
var _card_t := 11.0
var _fade: ColorRect
var _respawning := false


func _ready() -> void:
	Fighter.FIELD = false
	App.current_map = MAP_ID
	Runner.autopilot = OS.get_environment("PARKOUR_AUTO") != ""
	Runner.autopilot_sloppy = OS.get_environment("PARKOUR_SLOPPY") != ""
	Engine.set_meta("run_parries0", int(FamilyProfile.data.get("parries", 0)))
	state = RunState.new()
	state.add_to_group("run_state")
	add_child(state)
	_sky()
	course = RoofCourse.new()
	add_child(course)
	var attempt := int(FamilyProfile.data.get("roof_tries", 0))
	course.build(hash("roofs") + attempt % 3, BUILDINGS)
	var roles: Array = ["son"]
	if App.couch or App.solo_role == "father":
		roles = ["son", "father"] if App.couch else ["father"]
	var i := 0
	for r in roles:
		var rn := Runner.new()
		rn.role = str(r)
		rn.prefix = "p1_" if i == 0 else "p2_"
		rn.course = course
		rn.position = Vector2(60.0 - 40.0 * float(i), course.ground_at(60.0))
		rn.event.connect(_on_event.bind(rn))
		add_child(rn)
		runners.append(rn)
		i += 1
	hunter = Hunter.new()
	hunter.target = runners[0]
	add_child(hunter)
	cam = Camera2D.new()
	cam.zoom = Vector2(1.3, 1.3)
	cam.position = runners[0].position + Vector2(160, -40)
	add_child(cam)
	cam.make_current()
	_world_ui = Node2D.new()
	_world_ui.z_index = 40
	add_child(_world_ui)
	_world_ui.draw.connect(_paint_world_ui)
	_hud_layer()
	Mixer.play_music("res://assets/audio/music_chase.wav")
	for rn in runners:
		rn.set_physics_process(false)


# --- Look --------------------------------------------------------------------

func _sky() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -20
	add_child(bg)
	var sky := ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float t = 0.0;
void fragment() {
	vec2 uv = UV;
	vec3 top = vec3(0.10, 0.07, 0.22);
	vec3 mid = vec3(0.48, 0.20, 0.42);
	vec3 low = vec3(1.00, 0.55, 0.30);
	vec3 c = mix(top, mid, smoothstep(0.0, 0.55, uv.y));
	c = mix(c, low, smoothstep(0.5, 0.95, uv.y));
	// The sun low on the left, a soft halo.
	vec2 sp = vec2(0.22, 0.78);
	float d = distance(uv * vec2(1.78, 1.0), sp * vec2(1.78, 1.0));
	c += vec3(1.0, 0.65, 0.35) * smoothstep(0.45, 0.0, d) * 0.55;
	c = mix(c, vec3(1.0, 0.86, 0.6), smoothstep(0.075, 0.06, d));
	// Thin cloud bands.
	float band = sin(uv.y * 40.0 + sin(uv.x * 6.0 + t * 0.05) * 2.0);
	c += vec3(0.25, 0.12, 0.18) * smoothstep(0.92, 1.0, band) * smoothstep(0.2, 0.6, uv.y) * 0.5;
	COLOR = vec4(c, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	sky.material = m
	bg.add_child(sky)
	# Three skyline silhouettes, far to near, hazier the further away.
	var specs := [[0.08, Color(0.52, 0.28, 0.44), 200.0, 0.0], [0.22, Color(0.3, 0.17, 0.32), 150.0, 0.25], [0.45, Color(0.17, 0.1, 0.2), 110.0, 0.4]]
	var k := 0
	for sp in specs:
		var layer := Skyline.new()
		layer.factor = float(sp[0])
		layer.col = sp[1]
		layer.base_h = float(sp[2])
		layer.lit = float(sp[3])
		layer.seed_v = 77 + k
		layer.z_index = -30 + k
		add_child(layer)
		_layers.append(layer)
		k += 1


class Skyline extends Node2D:
	var factor := 0.2
	var col := Color.BLACK
	var base_h := 150.0
	var lit := 0.0
	var seed_v := 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var x := -1600.0
		var horizon := RoofCourse.ROOF_BASE + 140.0
		while x < 14000.0 * factor + 3200.0:
			var w := r.randf_range(50.0, 140.0)
			var h := base_h * r.randf_range(0.5, 1.8)
			draw_rect(Rect2(x, horizon - h, w, h + 900.0), col)
			if r.randf() < 0.25:
				draw_rect(Rect2(x + w * 0.45, horizon - h - 26.0, 3.0, 26.0), col)
			if lit > 0.0:
				var yy := horizon - h + 10.0
				while yy < horizon + 200.0:
					var xx := x + 6.0
					while xx < x + w - 6.0:
						if r.randf() < lit * 0.35:
							draw_rect(Rect2(xx, yy, 3, 4), Color(1.0, 0.75, 0.45, 0.55))
						xx += 10.0
					yy += 14.0
			x += w + r.randf_range(-10.0, 30.0)


# --- Loop ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_t += delta
	if not _go:
		_count -= delta
		if _count <= 0.0:
			_go = true
			hunter.active = true
			for rn in runners:
				rn.set_physics_process(true)
			_feed_add("GO!", Color(0.45, 1.0, 0.6))
			Mixer.play_sfx("res://assets/audio/sfx/combo_sting.ogg", 1.1, -2.0)
	_camera(delta)
	for l in _layers:
		var sl := l as Node2D
		sl.position = Vector2(cam.position.x * (1.0 - float(sl.get("factor"))), cam.position.y * 0.15 * (1.0 - float(sl.get("factor"))))
	_card_t -= delta
	for g in course.guards:
		(g as RoofGuard).watch(_lead().position.x)
	if _go and not _done:
		hunter.target = _last_runner()
		hunter.record(delta)
		if hunter.tick(delta):
			_caught()
		for rn in runners:
			if rn.state == "out" and not _respawning:
				_fall(rn)
			if rn.position.x >= course.goal_x and rn.state not in ["out", "caught"]:
				_win()
				break
	_world_ui.queue_redraw()
	_hud.queue_redraw()
	if Input.is_action_just_pressed("p1_pause") and not _done:
		_pause()


func _lead() -> Runner:
	var best := runners[0]
	for rn in runners:
		if rn.position.x > best.position.x:
			best = rn
	return best


func _last_runner() -> Runner:
	var best := runners[0]
	for rn in runners:
		if rn.position.x < best.position.x:
			best = rn
	return best


func _camera(delta: float) -> void:
	var l := _lead()
	var spd := clampf(l.vx / Runner.TOP, 0.0, 1.3)
	var want := l.position + Vector2(120.0 + 150.0 * spd, -50.0)
	cam.position.x = lerpf(cam.position.x, want.x, 1.0 - exp(-6.0 * delta))
	cam.position.y = lerpf(cam.position.y, want.y, 1.0 - exp(-3.5 * delta))
	var z := lerpf(1.32, 1.12, clampf(spd, 0.0, 1.0))
	cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.0 - exp(-2.0 * delta))
	cam.offset = Juice.shake_offset() if Juice.has_method("shake_offset") else Vector2.ZERO


# --- Events ---------------------------------------------------------------------

func _on_event(kind: String, text: String, col: Color, pts: int, rn: Runner) -> void:
	match kind:
		"stumble":
			hunter.nudge(-0.3)
		"hard":
			hunter.nudge(-0.25)
			Juice.pulse_shake(5.0)
		"bail":
			hunter.nudge(-0.3)
			Mixer.play_sfx("res://assets/audio/cling_fail.wav", 1.0, -4.0)
		"sloppy":
			hunter.nudge(-0.1)
		"bad":
			hunter.nudge(-0.15)
			Juice.pulse_shake(2.5)
		"epic_take":
			hunter.nudge(-0.1)
		"epic":
			hunter.nudge(-0.5)
			Juice.pulse_shake(7.0)
			Mixer.play_sfx("res://assets/audio/cling_fail.wav", 0.8, -2.0)
		"perfect_land":
			hunter.nudge(0.22)
			Juice.pulse_shake(2.0)
			Juice.slowmo(0.6)
			get_tree().create_timer(0.09, true, false, true).timeout.connect(func() -> void: Juice.restore_time())
		"good_land":
			hunter.nudge(0.06)
		"trick_perfect":
			hunter.nudge(0.15)
	if pts > 0:
		state.add_points(rn.role, pts, kind)
	if text != "":
		var p := rn.global_position + Vector2(0, -96)
		Juice.popup_number(p, text + ("  +%d" % pts if pts > 0 else ""), col)
		if kind in ["perfect_land", "trick_call", "stumble", "epic", "bad"]:
			_feed_add(text, col)


func _feed_add(text: String, col: Color) -> void:
	_feed.append([text, col, _t])
	while _feed.size() > 4:
		_feed.pop_front()


func _fall(rn: Runner) -> void:
	_respawning = true
	rn.lives -= 1
	hunter.nudge(-0.9)
	hunter.lag = maxf(hunter.lag, 0.9)
	Mixer.play_sfx("res://assets/audio/sfx/body_fall.ogg", 0.8, 0.0)
	_feed_add("FELL  ·  %d LEFT" % maxi(0, rn.lives), Color(1.0, 0.4, 0.35))
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		if rn.lives <= 0:
			_fail("Ran out of roof.")
			return
		var cx := course.checkpoint_before(rn.position.x)
		rn.respawn(cx)
		cam.position = rn.position + Vector2(160, -40)
	)
	tw.tween_property(_fade, "color:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: _respawning = false)


func _caught() -> void:
	if _done:
		return
	var rn := hunter.target
	rn.caught()
	Juice.pulse_shake(8.0)
	Mixer.play_sfx("res://assets/audio/sfx/hit_heavy.ogg", 0.85, 0.0)
	_feed_add("CAUGHT", Color(1.0, 0.3, 0.25))
	_fail("He ran your line better than you did.")


func _win() -> void:
	if _done:
		return
	_done = true
	hunter.active = false
	for rn in runners:
		rn.win()
	Juice.slowmo(0.4)
	get_tree().create_timer(0.6, true, false, true).timeout.connect(func() -> void: Juice.restore_time())
	_feed_add("ESCAPED", Color(0.45, 1.0, 0.6))
	var lead := _lead()
	var bonus := int(hunter.lag * 20.0) + 10 * lead.perfects
	state.add_points(lead.role, bonus, "escape")
	Trees.add_flow(maxi(3, lead.style / 12))
	FamilyProfile.mark_map_filed(MAP_ID)
	FamilyProfile.data["resume"] = {"map": NEXT_ID, "x": 0.0, "y": 0.0}
	FamilyProfile.data["roof_best"] = maxi(int(FamilyProfile.data.get("roof_best", 0)), state.score_total)
	var gold := 30 + lead.perfects * 2
	FamilyProfile.add_gold(gold)
	FamilyProfile.save()
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		var sheet := ResultsSheet.new()
		sheet.headline = "ESCAPED"
		sheet.sub = "Style %d  ·  %d tricks  ·  %d perfect landings  ·  %.1fs ahead of him" % [lead.style, lead.tricks_done, lead.perfects, hunter.lag]
		sheet.win = true
		sheet.gate = true
		sheet.next_id = NEXT_ID
		sheet.next_label = Copy.NEXT_CIRCLE
		sheet.state = state
		sheet.combat = false
		sheet.tiles = [["gold", "GOLD", "+%d" % gold], ["boot", "PERFECT", str(lead.perfects)], ["bolt", "TRICKS", str(lead.tricks_done)]]
		add_child(sheet)
	)


func _fail(line: String) -> void:
	if _done:
		return
	_done = true
	hunter.active = false
	FamilyProfile.data["roof_tries"] = int(FamilyProfile.data.get("roof_tries", 0)) + 1
	FamilyProfile.save()
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		var card := RetryCard.new()
		card.line = line
		card.style = _lead().style
		add_child(card)
	)


func _pause() -> void:
	var p := PauseCard.new()
	add_child(p)


## Caught or out of falls: straight back in (Vector style) or home.
class RetryCard extends CanvasLayer:
	var line := ""
	var style := 0

	func _ready() -> void:
		layer = 60
		var root := PixelStage.attach_canvas(self)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.size = Vector2(PixelStage.DESIGN)
		root.add_child(dim)
		var col := VBoxContainer.new()
		col.position = Vector2(340, 230)
		col.custom_minimum_size = Vector2(600, 0)
		col.add_theme_constant_override("separation", 12)
		root.add_child(col)
		var t := UiKit.title("CAUGHT", 52, Palette.BRICK)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t)
		var s := Label.new()
		s.text = "%s\nStyle %d. Keep your speed, land your rolls, let go at the edge." % [line, style]
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(s, 15, Palette.TEXT)
		col.add_child(s)
		var again := UiKit.button("TRY AGAIN", Vector2(600, 52))
		again.pressed.connect(func() -> void: get_tree().reload_current_scene())
		col.add_child(again)
		var home := UiKit.button("BACK TO THE HIDEOUT", Vector2(600, 44))
		home.pressed.connect(func() -> void: App.back_to_hub("run"))
		col.add_child(home)
		again.grab_focus()


class PauseCard extends CanvasLayer:
	func _ready() -> void:
		layer = 60
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		var root := PixelStage.attach_canvas(self)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.6)
		dim.size = Vector2(PixelStage.DESIGN)
		root.add_child(dim)
		var col := VBoxContainer.new()
		col.position = Vector2(490, 260)
		col.add_theme_constant_override("separation", 12)
		root.add_child(col)
		col.add_child(UiKit.title("PAUSED", 40, UiKit.GOLD))
		var resume := UiKit.button("RESUME")
		resume.custom_minimum_size = Vector2(300, 48)
		resume.pressed.connect(_resume)
		col.add_child(resume)
		var quit := UiKit.button("BACK TO THE HIDEOUT")
		quit.custom_minimum_size = Vector2(300, 48)
		quit.pressed.connect(func() -> void:
			get_tree().paused = false
			App.back_to_hub("run"))
		col.add_child(quit)
		resume.grab_focus()

	func _resume() -> void:
		get_tree().paused = false
		queue_free()

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("p1_pause") or e.is_action_pressed("ui_cancel"):
			_resume()


# --- HUD ------------------------------------------------------------------------

func _hud_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var root := PixelStage.attach_canvas(layer)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud = Control.new()
	_hud.size = Vector2(PixelStage.DESIGN)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hud)
	_hud.draw.connect(_paint_hud)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(PixelStage.DESIGN)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


func _txt(c: CanvasItem, at: Vector2, s: String, size: int, col: Color, center := false, font: Font = null) -> void:
	var f := font if font else UiKit.title_font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := at - Vector2(w * 0.5 if center else 0.0, 0)
	c.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0.04, 0.02, 0.06))
	c.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _paint_hud() -> void:
	var c := _hud
	var lead := _lead()
	# The track: you, him, the mast.
	var tx := 340.0
	var tw := 600.0
	var ty := 26.0
	var span := maxf(1.0, course.goal_x)
	c.draw_rect(Rect2(tx - 4, ty - 4, tw + 8, 16), Color(0.04, 0.02, 0.06, 0.8))
	c.draw_rect(Rect2(tx, ty, tw, 8), Color(0.25, 0.18, 0.3))
	var hx := tx + tw * clampf(hunter.position.x / span, 0.0, 1.0)
	var lx := tx + tw * clampf(lead.position.x / span, 0.0, 1.0)
	c.draw_rect(Rect2(hx, ty, maxf(0.0, lx - hx), 8), Color(1.0, 0.35, 0.3, 0.55))
	c.draw_rect(Rect2(tx, ty, lx - tx, 8), Color(1.0, 0.62, 0.35, 0.5))
	c.draw_colored_polygon(PackedVector2Array([Vector2(tx + tw, ty - 10), Vector2(tx + tw + 14, ty - 5), Vector2(tx + tw, ty)]), Color(0.45, 1.0, 0.6))
	if hunter.visible:
		c.draw_circle(Vector2(hx, ty + 4), 7.0, Color(0.05, 0.02, 0.04))
		c.draw_circle(Vector2(hx, ty + 4), 5.0, Color(1.0, 0.3, 0.25))
	for rn in runners:
		var rx := tx + tw * clampf(rn.position.x / span, 0.0, 1.0)
		c.draw_circle(Vector2(rx, ty + 4), 8.0, Color(0.05, 0.02, 0.04))
		c.draw_circle(Vector2(rx, ty + 4), 6.0, Palette.LEMON if rn.role == "son" else Palette.BRICK)
	# The margin, the thing that matters.
	var lag := hunter.lag
	var lc := Color(0.45, 1.0, 0.6) if lag > 1.6 else (Color(1.0, 0.8, 0.35) if lag > 0.9 else Color(1.0, 0.3, 0.25))
	if lag <= 0.9:
		lc = lc.lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 14.0))
	_txt(c, Vector2(640, 64), "HUNTER  %.1fs" % lag, 20, lc, true)
	# Style, chain, speed.
	_txt(c, Vector2(24, 34), "STYLE %d" % lead.style, 22, UiKit.GOLD)
	if lead.chain > 1:
		_txt(c, Vector2(24, 60), "PERFECT CHAIN x%d" % lead.chain, 14, Color(1.0, 0.85, 0.3))
	var spd := clampf(lead.vx / lead.boost, 0.0, 1.0)
	_txt(c, Vector2(24, 92), "ROOFTOPS LV %d" % Heroes.level(lead.role, "parkour"), 11, Color(0.7, 0.85, 1.0))
	c.draw_rect(Rect2(24, 72, 180, 6), Color(0.04, 0.02, 0.06, 0.8))
	c.draw_rect(Rect2(24, 72, 180.0 * spd, 6), Color(1.0, 0.62, 0.35) if lead.boost_t <= 0.0 else Color(1.0, 0.9, 0.5))
	# Falls left.
	for i in lead.lives:
		c.draw_rect(Rect2(1180 - i * 26, 22, 18, 18), Color(0.04, 0.02, 0.06))
		c.draw_rect(Rect2(1182 - i * 26, 24, 14, 14), Palette.LEMON if lead.role == "son" else Palette.BRICK)
	_txt(c, Vector2(1090, 60), "FALLS LEFT", 11, Color(0.85, 0.8, 0.9))
	# The call feed.
	var y := 150.0
	for f in _feed:
		var age := _t - float(f[2])
		if age > 2.2:
			continue
		var a := clampf(2.2 - age, 0.0, 1.0)
		var col: Color = f[1]
		col.a = a
		_txt(c, Vector2(640, y), str(f[0]), 26, col, true)
		y += 32.0
	# Countdown.
	if not _go:
		var n := int(ceil(_count - 0.2))
		_txt(c, Vector2(640, 330), str(maxi(1, n)) if _count > 0.2 else "GO", 72, UiKit.GOLD, true)
	# How to run: shown at the start.
	if _card_t > 0.0:
		var a2 := clampf(_card_t, 0.0, 1.0)
		var r := Rect2(250, 560, 780, 138)
		c.draw_rect(r, Color(0.04, 0.02, 0.06, 0.82 * a2))
		c.draw_rect(r, Color(1.0, 0.62, 0.35, 0.8 * a2), false, 2.0)
		var lines := [
			"LEFT STICK  RIGHT = RUN   ·   UP = JUMP / VAULT / CLIMB   ·   DOWN = SLIDE",
			"HOLD RIGHT STICK + R1 R2 L1 L2 = LOAD A TRICK   ·   LET GO + LEFT UP = JUMP IT",
			"LET GO RIGHT AT THE EDGE = PERFECT   ·   BIG DROP: BOTH STICKS DOWN-RIGHT = ROLL",
			"SMALL JUMP: BOTH STICKS RIGHT   ·   PERFECT LANDINGS BOOST YOU   ·   HE RUNS YOUR LINE",
		]
		var yy := 590.0
		for ln in lines:
			_txt(c, Vector2(640, yy), ln, 13, Color(0.95, 0.9, 0.95, a2), true, UiKit.pixel_font())
			yy += 28.0


## Over the runner's head: the trick being loaded, and the landing call.
func _paint_world_ui() -> void:
	# Speed streaks while boosting.
	var l := _lead()
	if l.boost_t > 0.0 or l.vx > Runner.TOP * 0.95:
		var r := RandomNumberGenerator.new()
		r.seed = int(_t * 20.0)
		for i in 7:
			var y := l.position.y - r.randf_range(0.0, 90.0)
			var x := l.position.x - r.randf_range(40.0, 260.0)
			_world_ui.draw_line(Vector2(x, y), Vector2(x - r.randf_range(40.0, 110.0), y), Color(1.0, 0.85, 0.6, 0.25), 1.5)
	# He is behind you, off screen: an arrow at the left edge.
	if hunter.visible and hunter.active:
		var half := get_viewport_rect().size.x * 0.5 / cam.zoom.x
		var left := cam.position.x - half
		if hunter.position.x < left + 10.0:
			var ay := clampf(hunter.position.y - 34.0, cam.position.y - 200.0, cam.position.y + 200.0)
			var ax := left + 26.0
			var pulse := 1.0 + 0.2 * sin(_t * 10.0)
			var c := Color(1.0, 0.3, 0.25)
			_world_ui.draw_colored_polygon(PackedVector2Array([Vector2(ax - 14.0 * pulse, ay), Vector2(ax + 6.0, ay - 10.0 * pulse), Vector2(ax + 6.0, ay + 10.0 * pulse)]), c)
			_txt(_world_ui, Vector2(ax + 12.0, ay + 5.0), "%dm" % int((left - hunter.position.x) / 37.0 + 6.0), 11, c)
	for rn in runners:
		var head := rn.position + Vector2(0, -92)
		var ld := rn.loading()
		var tr := rn.armed()
		if not ld.is_empty() or not tr.is_empty():
			var name := str(tr.get("name", "...")) if not tr.is_empty() else "..."
			var parts: Array = []
			var d := str(ld.get("dir", tr.get("dir", "")))
			if d != "":
				parts.append(d)
			for b in ld.get("btn", tr.get("btn", [])):
				parts.append(str(b))
			var glyph := " + ".join(PackedStringArray(parts))
			var held := not ld.is_empty()
			var col := Color(0.75, 0.9, 1.0) if held else Color(0.45, 1.0, 0.6)
			if tr.has("locked"):
				name = "LOCKED · ROOFTOPS LV %d" % int(tr["locked"])
				col = Color(0.9, 0.6, 0.45)
			_txt(_world_ui, head, name, 12, col, true)
			_txt(_world_ui, head + Vector2(0, 14), glyph if held else "UP!", 10, col.darkened(0.1), true, UiKit.pixel_font())
		var need := rn.landing_need()
		if need != "":
			var ok := rn._pose_ok(need)
			var txt := "ROLL  ↘ ↘" if need == "roll" else "LAND  → →"
			var col2 := Color(0.45, 1.0, 0.6) if ok else Color(1.0, 0.8, 0.4)
			var g := course.ground_at(rn.position.x, 9.0)
			var k := clampf((g - rn.position.y) / 160.0, 0.0, 1.0) if g != INF else 1.0
			_world_ui.draw_arc(rn.position + Vector2(0, -34), 22.0 + 30.0 * k, 0.0, TAU, 32, Color(col2.r, col2.g, col2.b, 0.7), 2.0)
			_txt(_world_ui, rn.position + Vector2(0, 26), txt, 12, col2, true)
