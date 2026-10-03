extends Node2D

## Between-acts film, staged on the street: the painted backdrop of the map
## just filed, the Father and Son (plus any crew the story brings in) as real
## sprites, lines as speech bubbles, a pixel chapter card first. Used for
## bridges (outros), the ending, and anything StoryBook.film_lines returns.
## JUMP / ENTER next line, PAUSE skips.

const BACKDROPS := {"dock_street": "dock", "tutorial_alley": "tutorial"}

var _kind := "bridge"
var _talk: Talk
var _ui: Control
var _cam: Camera2D
var _done := false
var _card: Control


func _ready() -> void:
	_kind = App.film_kind if App.film_kind != "" else "bridge"
	_build_set()
	_build_ui()
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	Juice.play("res://assets/audio/sting_intro.wav")
	_talk = Talk.new()
	add_child(_talk)
	_talk.closed.connect(_leave)
	await _chapter_card()
	if _done:
		return
	var lines := StoryBook.film_lines(_kind, App.film_from, App.film_next)
	if lines.is_empty():
		_leave()
		return
	_talk.play(lines, true)


func _stage() -> Dictionary:
	var b := StoryBook.bridge(App.film_from, App.film_next)
	var v: Variant = b.get("stage", {})
	return v if v is Dictionary else {}


func _build_set() -> void:
	var st := _stage()
	var theme := str(st.get("theme", BACKDROPS.get(App.film_from, "dock")))
	var map_w := 1400.0
	NightStreet.parallax(self, map_w, theme)
	NightStreet.wet_floor(self, map_w, true)
	NightStreet.pixel_dock(self, map_w, false)
	NightStreet.rain(self, 700.0)
	AmbientProp.lamp(self, Vector2(520.0, 500.0), 3)
	var mod := CanvasModulate.new()
	mod.color = Palette.NIGHT
	add_child(mod)
	var cast: Array = st.get("cast", ["father", "son"])
	var xs := [560.0, 610.0, 680.0, 730.0]
	for i in cast.size():
		var who := str(cast[i])
		var at := Vector2(float(xs[mini(i, xs.size() - 1)]), 494.0 + float(i % 2) * 2.0)
		if SpriteBook.has_who(who):
			var a := Node2D.new()
			a.set_script(preload("res://src/world/film_actor.gd"))
			a.set("role", who)
			a.position = at
			a.add_to_group("players")
			add_child(a)
			a.call("build")
			var anim: AnimatedSprite2D = a.get("anim")
			if anim and i >= 2:
				anim.flip_h = true
		else:
			var c := CrewNPC.new()
			c.setup(who)
			c.position = at
			c.face(-1)
			add_child(c)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(2.2, 2.2)
	_cam.position = Vector2(640, 446)
	add_child(_cam)
	_cam.make_current()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_ui = PixelStage.attach_canvas(layer)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for y in [0.0, 650.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(1280, 70)
		_ui.add_child(bar)
	var skip := Label.new()
	skip.position = Vector2(40, 22)
	skip.text = "JUMP  ·  NEXT LINE        PAUSE  ·  SKIP"
	UiKit.apply_label(skip, 13, Palette.MUTED)
	_ui.add_child(skip)


## Pixel chapter card: CHAPTER n, the title in big gold caps, the sub line;
## slams in, holds, fades.
func _chapter_card() -> void:
	var ch := StoryBook.chapter_card(_kind, App.film_from, App.film_next)
	var b := StoryBook.bridge(App.film_from, App.film_next)
	_card = Control.new()
	_card.size = Vector2(1280, 720)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_card)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.8)
	dim.size = Vector2(1280, 720)
	_card.add_child(dim)
	var panel := PanelContainer.new()
	var ps := preload("res://src/ui/clinic_featured.gd").card_style(true)
	ps.content_margin_left = 60
	ps.content_margin_right = 60
	ps.content_margin_top = 26
	ps.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", ps)
	panel.position = Vector2(240, 220)
	panel.custom_minimum_size = Vector2(800, 0)
	_card.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var chap := Label.new()
	chap.text = str(b.get("chapter", "THE NIGHT CONTINUES" if _kind != "ending" else "EPILOGUE"))
	chap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chap.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(chap, 18, Palette.MUTED)
	col.add_child(chap)
	var t := UiKit.title(str(ch.get("title", "NEXT SESSION")), 50, Palette.EDGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var sub := Label.new()
	sub.text = str(ch.get("sub", ""))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(sub, 18, Palette.TEXT)
	col.add_child(sub)
	panel.scale = Vector2(1.4, 1.4)
	panel.pivot_offset = Vector2(400, 90)
	panel.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)
	Juice.play("res://assets/audio/card.wav")
	Juice.pulse_shake(4.0)
	var held := 0.0
	while held < 2.4 and not _done:
		held += get_process_delta_time()
		if held > 0.4 and (Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("ui_accept")):
			break
		await get_tree().process_frame
	var out := create_tween()
	out.tween_property(_card, "modulate:a", 0.0, 0.35)
	await out.finished
	_card.queue_free()


func _process(_delta: float) -> void:
	if _done:
		return
	if _cam:
		_cam.position.x = lerpf(_cam.position.x, 650.0, 0.004)
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_leave()


func _leave() -> void:
	if _done:
		return
	_done = true
	if _kind == "ending" or App.film_next == "" or App.film_next == "hub":
		FamilyProfile.mark_ending()
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		if App.remote_coop:
			NetSession.shutdown()
		App.back_to_hub("awards")
		return
	if App.film_to_camp:
		App.film_done_to_camp()
		return
	var nxt := App.film_next
	App.film_kind = ""
	if App.remote_coop and NetSession.is_host():
		NetSession.broadcast_begin(nxt, App.begin_extra())
		return
	App.enter_map(nxt)
