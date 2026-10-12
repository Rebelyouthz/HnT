class_name StageCard
extends CanvasLayer

## The title card at the start of every stage: the painted street slowly
## panning behind, STAGE N, the stage's name slammed in, the job in one line.
## The game waits under it (paused) until it fades or a button skips it, then
## holds a beat on the live street (GET READY ... GO!) before anything moves.

signal closed

const THEME := {
	"dock_street": "dock", "intake_lot": "lot", "fire_escapes": "roofs",
	"group_circle": "circle", "neon_exchange": "neon", "waiting_room": "waiting",
	"rail_bridge": "rail", "city_hall": "hall", "copay_orchard": "farm",
	"sleet_hour": "snow", "raven_grid": "cyber", "ledger_dive": "vault",
	"invoice_pier": "pier", "processing_floor": "processing",
}
const HOLD := 3.4

var map_id := "dock_street"
var _t := 0.0
var _pic: TextureRect
var _done := false
var _root: Control
var _beat := false


static func show_for(host: Node, id: String) -> StageCard:
	if not THEME.has(id) or host == null:
		return null
	var c := StageCard.new()
	c.map_id = id
	host.add_child(c)
	return c


## The painted section that opens the stage (first strip chunk or the
## single backdrop), or null.
static func art(id: String) -> Texture2D:
	# The mission picture first (the same one the RUN tab shows).
	var mp := "res://assets/sprites/missions/%s.png" % id
	if ResourceLoader.exists(mp):
		return load(mp) as Texture2D
	var th := str(THEME.get(id, ""))
	for p in ["res://assets/backdrops/%s_strip_0.png" % th, "res://assets/backdrops/%s.png" % th]:
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null


static func title_of(id: String) -> String:
	return str(StoryBook.act(id).get("title", id.replace("_", " ").to_upper()))


const TIPS := [
	"LIGHT + HEAVY together fires an element art. The stick picks which.",
	"Same buttons next to a thug: a grab. Bosses do not grab.",
	"Hold DASH or double-tap forward to RUN. Attack out of a run for a running strike.",
	"Hit a thug during his wind-up to INTERRUPT him.",
	"From behind it is a BACKSTAB: a quarter more.",
	"Roll just as the swing lands: PERFECT DODGE.",
	"Double-tap DUCK to taunt. Risky. Pays CHI.",
	"Hold HEAVY and tap SPECIAL when the gold ring is full.",
	"Throw with nobody in reach and a knife flies. Pick it back up.",
	"Ammo is short. Empty guns go in the bin.",
	"Fling a thug into a lamp post for a PROP SLAM.",
	"The tutorial in the dojo pays gold once per lesson.",
	"The GUNSMITH fits five parts to every gun.",
]


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Banners (UNLOCKED ...) wait until the card and GET READY / GO are gone.
	add_to_group("stage_card")
	get_tree().paused = true
	_root = PixelStage.attach_canvas(self)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var tex := art(map_id)
	if tex:
		_pic = TextureRect.new()
		_pic.texture = tex
		_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_pic.size = Vector2(1400, 760)
		_pic.position = Vector2(-20, -20)
		_pic.modulate = Color(0.78, 0.78, 0.86)
		_root.add_child(_pic)
	# Letterbox bars and a dark band for the type.
	for y in [0.0, 640.0]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0)
		bar.position = Vector2(0, y)
		bar.size = Vector2(1280, 80)
		_root.add_child(bar)
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.62)
	band.position = Vector2(0, 410)
	band.size = Vector2(1280, 170)
	_root.add_child(band)
	var idx := App.ORDER.find(map_id)
	var num := Label.new()
	num.text = "STAGE %d" % (idx + 1) if idx >= 0 else "STAGE"
	num.position = Vector2(90, 420)
	UiKit.apply_label(num, 20, Palette.BRICK)
	_root.add_child(num)
	var name_l := UiKit.title(title_of(map_id), 64, Palette.LEMON)
	name_l.position = Vector2(84, 446)
	name_l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_l.add_theme_constant_override("outline_size", 10)
	_root.add_child(name_l)
	var job := Label.new()
	job.text = str(StoryBook.act(map_id).get("main", ""))
	job.position = Vector2(90, 530)
	job.size = Vector2(1100, 40)
	job.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(job, 16, Palette.TEXT)
	_root.add_child(job)
	var cond := NightCondition.of(map_id)
	if str(cond.get("id", "")) != "quiet":
		var cl := Label.new()
		cl.text = "TONIGHT:  %s  ·  %s" % [str(cond.get("name", "")), str(cond.get("line", ""))]
		cl.position = Vector2(90, 562)
		cl.size = Vector2(1100, 24)
		UiKit.apply_label(cl, 15, Color(0.6, 0.85, 1.0))
		_root.add_child(cl)
	# TIP OF THE NIGHT: one thing worth knowing, a different one each time.
	var tip := Label.new()
	tip.text = "TIP  ·  " + str(TIPS[randi() % TIPS.size()])
	tip.position = Vector2(90, 600)
	tip.size = Vector2(900, 24)
	UiKit.apply_label(tip, 12, UiKit.GOLD)
	_root.add_child(tip)
	var skip := Label.new()
	skip.text = "JUMP / ENTER TO SKIP"
	skip.position = Vector2(0, 600)
	skip.size = Vector2(1200, 24)
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiKit.apply_label(skip, 12, Palette.MUTED)
	_root.add_child(skip)
	# Slam in.
	name_l.modulate.a = 0.0
	name_l.scale = Vector2(1.4, 1.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(name_l, "modulate:a", 1.0, 0.18).set_delay(0.25)
	tw.tween_property(name_l, "scale", Vector2.ONE, 0.22).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func() -> void:
		Juice.play("res://assets/audio/card.wav")
	)
	Juice.play("res://assets/audio/sting_intro.wav")


func _process(delta: float) -> void:
	_t += delta
	if _pic:
		_pic.position.x = -20.0 - _t * 14.0
	if _beat:
		return
	if _t > 0.5 and (Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p2_jump")):
		_close()
	if _t >= HOLD:
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_ready_beat)


## The street is on screen, frozen: GET READY, then GO! and the night starts.
func _ready_beat() -> void:
	_beat = true
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()
	_root.modulate.a = 1.0
	var l := UiKit.title("GET READY", 58, Palette.LEMON)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 90)
	l.position = Vector2(0, 150)
	l.pivot_offset = Vector2(640, 45)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 12)
	_root.add_child(l)
	l.scale = Vector2(1.5, 1.5)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.chain().tween_interval(1.0)
	tw.chain().tween_callback(func() -> void:
		l.text = "GO!"
		l.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55))
		l.scale = Vector2(1.6, 1.6)
		Juice.play("res://assets/audio/card.wav")
	)
	tw.chain().tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func() -> void:
		get_tree().paused = false
		closed.emit()
	)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(queue_free)
