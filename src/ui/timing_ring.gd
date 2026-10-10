class_name TimingRing
extends CanvasLayer

## The timing ring for parkour, tower climbs and dojo drills: the button to
## press sits in a chunky pixel badge, a ring shrinks onto it and turns
## green in the window. Press the right button as it lands.
## Grades (real time, so slow-mo never shifts the window):
##   perfect  - inside +-PERFECT s: gold burst, hitstop, slow-mo, "PERFECT!"
##   good     - inside +-GOOD s: green pop
##   ok       - inside +-OK s (early/late): yellow
##   miss     - pressed outside the window, or never pressed: red, shake
##   big_miss - wrong button, or panic-pressed before the ring got close:
##              dark red flash, big shake
## resolved(grade) fires once; the ring follows `anchor` (a world node) if set.

signal resolved(grade: String)

## Capture / demo: rings hit themselves perfectly.
static var autoplay := false

const PERFECT := 0.05
const GOOD := 0.1
const OK := 0.17
const ACTIONS := ["jump", "light", "up", "special", "dash", "heavy"]
const NAMES := {"jump": "JUMP", "light": "PUNCH", "up": "UP", "special": "SPECIAL", "dash": "DASH", "heavy": "KICK"}
const KEYS := {"jump": "SPACE", "light": "J", "up": "W", "special": "L", "dash": "SHIFT", "heavy": "K"}

var action := "jump"
var lead := 0.85
var label := ""
var anchor: Node2D
var slow := 0.0
var _t0 := 0
var _done := false
var _ui: Control
var _ring: Control
var _badge: Label
var _name: Label
var _verdict: Label


static func spawn(host: Node, act: String, at: Node2D = null, lead_s := 0.85, title := "") -> TimingRing:
	var r := TimingRing.new()
	r.action = act
	r.anchor = at
	r.lead = lead_s
	r.label = title
	host.add_child(r)
	return r


func _ready() -> void:
	layer = 72
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = PixelStage.attach_canvas(self)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring = Control.new()
	_ring.size = Vector2(260, 260)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_ring)
	_ring.draw.connect(_draw_ring)
	_badge = Label.new()
	_badge.text = str(KEYS.get(action, action.to_upper()))
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.size = Vector2(260, 260)
	_badge.add_theme_font_override("font", UiKit.title_font())
	_badge.add_theme_font_size_override("font_size", 22 if _badge.text.length() > 2 else 34)
	_badge.add_theme_color_override("font_color", Palette.TEXT)
	_badge.add_theme_color_override("font_outline_color", UiKit.INK)
	_badge.add_theme_constant_override("outline_size", 6)
	_ring.add_child(_badge)
	_name = Label.new()
	_name.text = label if label != "" else str(NAMES.get(action, action.to_upper()))
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.position = Vector2(-70, 196)
	_name.size = Vector2(400, 30)
	_name.add_theme_font_override("font", UiKit.title_font())
	_name.add_theme_font_size_override("font_size", 20)
	_name.add_theme_color_override("font_color", UiKit.GOLD)
	_name.add_theme_color_override("font_outline_color", UiKit.INK)
	_name.add_theme_constant_override("outline_size", 6)
	_ring.add_child(_name)
	_verdict = Label.new()
	_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verdict.position = Vector2(-120, 20)
	_verdict.size = Vector2(500, 60)
	_verdict.pivot_offset = Vector2(250, 30)
	_verdict.add_theme_font_override("font", UiKit.title_font())
	_verdict.add_theme_font_size_override("font_size", 46)
	_verdict.add_theme_color_override("font_outline_color", UiKit.INK)
	_verdict.add_theme_constant_override("outline_size", 10)
	_verdict.visible = false
	_ring.add_child(_verdict)
	_t0 = Time.get_ticks_usec()
	_place()
	if slow > 0.0:
		Juice.slowmo(slow)
	_ring.scale = Vector2(0.6, 0.6)
	_ring.pivot_offset = Vector2(130, 130)
	var tw := _ring.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_ring, "scale", Vector2.ONE, 0.12)
	Juice.play("res://assets/audio/cling.wav")


func _elapsed() -> float:
	return float(Time.get_ticks_usec() - _t0) / 1000000.0


func _place() -> void:
	var center := Vector2(640, 300)
	if anchor != null and is_instance_valid(anchor):
		var p := anchor.get_global_transform_with_canvas() * Vector2(0, -70)
		center = p * (float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x))
		center.x = clampf(center.x, 150.0, 1130.0)
		center.y = clampf(center.y, 150.0, 560.0)
	_ring.position = (center - Vector2(130, 130)).round()


func _process(_delta: float) -> void:
	if _done:
		return
	_place()
	_ring.queue_redraw()
	var t := _elapsed()
	if t > lead + OK + 0.05:
		_finish("miss")
		return
	var hit := _just(action) or (autoplay and t >= lead)
	if hit:
		var err := absf(t - lead) / _wide()
		if t < lead * 0.45:
			_finish("big_miss")
		elif err <= PERFECT:
			_finish("perfect")
		elif err <= GOOD:
			_finish("good")
		elif err <= OK:
			_finish("ok")
		else:
			_finish("miss")
		return
	for a in ACTIONS:
		if a != action and _just(a) and t > lead * 0.3:
			_finish("big_miss")
			return


func _just(a: String) -> bool:
	return Input.is_action_just_pressed("p1_" + a) or Input.is_action_just_pressed("p2_" + a)


func _draw_ring() -> void:
	var t := _elapsed()
	var u := clampf(t / lead, 0.0, 1.25)
	var c := Vector2(130, 130)
	var err := absf(t - lead)
	var col := Color(0.95, 0.95, 0.9)
	if err <= GOOD:
		col = Palette.READY
	elif err <= OK:
		col = Palette.LEMON
	elif t > lead:
		col = Palette.BADGE
	# Badge: chunky pixel button with a dark base (3D) and a gold rim.
	c.y += 3.0
	_ring.draw_circle(c + Vector2(0, 5), 36.0, Color(0, 0, 0.02, 0.85))
	_ring.draw_circle(c, 36.0, UiKit.INK)
	_ring.draw_circle(c, 32.0, Color(0.1, 0.13, 0.24))
	_ring.draw_arc(c, 32.0, 0.0, TAU, 40, UiKit.GOLD, 3.0, true)
	# Target ring + shrinking ring.
	_ring.draw_arc(c, 42.0, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.5), 3.0, true)
	var r := lerpf(120.0, 42.0, minf(u, 1.0))
	if t > lead:
		r = 42.0 - (t - lead) * 60.0
	_ring.draw_arc(c, maxf(30.0, r), 0.0, TAU, 56, Color(0, 0, 0, 0.6), 9.0, true)
	_ring.draw_arc(c, maxf(30.0, r), 0.0, TAU, 56, col, 6.0, true)


func _finish(grade: String) -> void:
	if _done:
		return
	_done = true
	if slow > 0.0:
		Juice.restore_time()
	var col := Palette.READY
	var text := "GOOD"
	match grade:
		"perfect":
			col = UiKit.GOLD
			text = "PERFECT!"
			Juice.play("res://assets/audio/trick_perfect.wav")
			Juice.hitstop(5)
			Juice.pulse_shake(3.0)
			Juice.named_slowmo()
			_burst(UiKit.GOLD, 26)
		"good":
			text = "GOOD"
			Juice.play("res://assets/audio/cling_ok.wav")
			Juice.pulse_shake(1.5)
			_burst(Palette.READY, 12)
		"ok":
			col = Palette.LEMON
			text = "LATE" if _elapsed() > lead else "EARLY"
			Juice.play("res://assets/audio/trick_ok.wav")
		"miss":
			col = Palette.BADGE
			text = "MISS"
			Juice.play("res://assets/audio/cling_fail.wav")
			# A miss deflates; shaking the screen is for hits.
		_:
			col = Color(0.6, 0.05, 0.08)
			text = "BIG MISS"
			Juice.play("res://assets/audio/stumble.wav")
			Juice.pulse_shake(2.0)
	_verdict.text = text
	_verdict.add_theme_color_override("font_color", col)
	_verdict.visible = true
	_verdict.scale = Vector2(0.4, 0.4)
	_badge.add_theme_color_override("font_color", col)
	var tw := _ring.create_tween().set_ignore_time_scale(true)
	tw.tween_property(_verdict, "scale", Vector2(1.15, 1.15), 0.09).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_verdict, "scale", Vector2.ONE, 0.07)
	if grade == "miss" or grade == "big_miss":
		_ring.modulate = Color(0.55, 0.55, 0.6)
		for k in 4:
			tw.tween_property(_ring, "position:x", _ring.position.x + (6.0 if k % 2 == 0 else -6.0), 0.03)
	tw.tween_interval(0.35)
	tw.tween_property(_ring, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
	resolved.emit(grade)


func _burst(col: Color, n: int) -> void:
	for i in n:
		var p := ColorRect.new()
		p.color = col
		p.size = Vector2(6, 6)
		p.position = Vector2(127, 130)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.add_child(p)
		var ang := TAU * float(i) / float(n) + randf() * 0.3
		var d := randf_range(70.0, 130.0)
		var tw := p.create_tween().set_ignore_time_scale(true).set_parallel(true)
		tw.tween_property(p, "position", p.position + Vector2(cos(ang), sin(ang)) * d, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.35)


## Grandpa's Watch widens every window.
static func _wide() -> float:
	return 1.25 if Charms.has("old_watch") else 1.0


static func is_success(grade: String) -> bool:
	return grade == "perfect" or grade == "good" or grade == "ok"
