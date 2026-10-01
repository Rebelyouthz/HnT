extends Node2D

## Opening film, staged in the alley: rain, the painted backstreet, Father
## and Son on the kerb talking in speech bubbles (Talk), then the comic slam,
## then the tutorial. JUMP / LIGHT / ENTER moves on, PAUSE skips.

## Inner actor so Talk finds the speakers like it finds Fighters.
class FilmActor extends Node2D:
	var role := ""
	var hop := 0.0

enum Beat { FILM1, COMIC, DONE }
var _beat: Beat = Beat.FILM1
var _film: Dictionary = {}
var _talk: Talk
var _ui: Control
var _comic_wrap: Control
var _cam: Camera2D
var _dad: FilmActor
var _kid: FilmActor
var _t := 0.0


func _ready() -> void:
	_film = StoryBook.all().get("intro", {})
	_build_set()
	_build_ui()
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	Juice.play("res://assets/audio/sting_intro.wav")
	_talk = Talk.new()
	add_child(_talk)
	_talk.closed.connect(_on_film_done)
	# A beat of rain and the street before anyone talks.
	await get_tree().create_timer(1.1).timeout
	if _beat == Beat.FILM1:
		_talk.play(_lines("film1"))


func _build_set() -> void:
	var map_w := 1400.0
	NightStreet.parallax(self, map_w, "tutorial")
	NightStreet.wet_floor(self, map_w, true)
	NightStreet.pixel_dock(self, map_w, false)
	NightStreet.rain(self, 700.0)
	AmbientProp.lamp(self, Vector2(470.0, 500.0), 3)
	var mod := CanvasModulate.new()
	mod.color = Palette.NIGHT
	add_child(mod)
	_dad = _actor("father", Vector2(560, 492), 1)
	_kid = _actor("son", Vector2(700, 496), -1)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(CouchCamera.ZOOM, CouchCamera.ZOOM)
	_cam.position = Vector2(640, 400)
	add_child(_cam)
	_cam.make_current()


func _actor(who: String, at: Vector2, face: int) -> FilmActor:
	var a := FilmActor.new()
	a.role = who
	a.position = at
	a.add_to_group("players")
	add_child(a)
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * float(i) / 16.0
		pts.append(Vector2(cos(ang) * 16.0, sin(ang) * 3.5))
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.45)
	shadow.position = Vector2(0, 3)
	a.add_child(shadow)
	if SpriteBook.has_who(who):
		var anim := SpriteBook.make_anim(who)
		anim.flip_h = face < 0
		a.add_child(anim)
	return a


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
	skip.text = "JUMP  ·  NEXT LINE        PAUSE  ·  SKIP FILM"
	UiKit.apply_label(skip, 13, Palette.MUTED)
	_ui.add_child(skip)
	var title := UiKit.title("RAVEN WHARF", 26, Palette.EDGE)
	title.position = Vector2(980, 16)
	_ui.add_child(title)
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.size = Vector2(1280, 720)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fade)
	fade.create_tween().tween_property(fade, "color:a", 0.0, 0.9)


func _lines(key: String) -> Array:
	var v: Variant = _film.get(key, [])
	return v if typeof(v) == TYPE_ARRAY else []


func _process(delta: float) -> void:
	_t += delta
	# Slow push-in while they talk.
	if _cam and _beat == Beat.FILM1:
		_cam.position.x = lerpf(_cam.position.x, 630.0, delta * 0.15)
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_advance_hard()
		return
	if _beat == Beat.COMIC and (Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p2_light")):
		_to_tutorial()


func _on_film_done() -> void:
	if _beat == Beat.FILM1:
		_start_comics()


func _start_comics() -> void:
	_beat = Beat.COMIC
	_comic_wrap = Control.new()
	_comic_wrap.size = Vector2(1280, 720)
	_comic_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_comic_wrap)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.6)
	dim.size = Vector2(1280, 720)
	_comic_wrap.add_child(dim)
	var arr := _lines("comics")
	if arr.is_empty():
		_to_tutorial()
		return
	var whos := ["", "father", "son"]
	for i in arr.size():
		var row: Variant = arr[i]
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = row
		var panel := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.98, 0.96, 0.9)
		st.border_color = Color(0.05, 0.05, 0.08)
		st.set_border_width_all(5)
		st.shadow_color = Color(0, 0, 0, 0.5)
		st.shadow_size = 10
		st.shadow_offset = Vector2(6, 8)
		st.content_margin_left = 16
		st.content_margin_right = 16
		st.content_margin_top = 12
		st.content_margin_bottom = 14
		panel.add_theme_stylebox_override("panel", st)
		panel.custom_minimum_size = Vector2(350, 330)
		panel.position = Vector2(1300, 170)
		panel.rotation = deg_to_rad([-3.0, 2.0, -1.5][i % 3])
		_comic_wrap.add_child(panel)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		panel.add_child(col)
		var t := UiKit.title(str(d.get("title", "")), 24, Talk.accent(str(whos[i % 3])) if i > 0 else Palette.BRICK)
		t.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
		col.add_child(t)
		var who := str(whos[i % 3])
		if who != "":
			var pic := UiKit.portrait(SpriteBook.bust(who, 0.55), Vector2(318, 150))
			col.add_child(pic)
		var b := Label.new()
		b.text = str(d.get("text", ""))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(318, 0)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", Color(0.06, 0.06, 0.09))
		col.add_child(b)
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.22 * i)
		tw.tween_callback(func() -> void:
			Juice.play("res://assets/audio/card.wav")
			Juice.pulse_shake(4.0)
		)
		tw.tween_property(panel, "position", Vector2(70 + i * 395, 160), 0.3)
	var hint := Label.new()
	hint.text = "PRESS JUMP"
	hint.position = Vector2(0, 590)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(hint, 18, Palette.LEMON)
	_comic_wrap.add_child(hint)
	UiKit.pulse_ready(hint)
	Juice.unlock_logo("INTAKE COMIC", "Three panels. Zero attendance. Maximum billing.")


func _advance_hard() -> void:
	if _beat == Beat.FILM1:
		_talk._close()
	elif _beat == Beat.COMIC:
		_to_tutorial()


func _to_tutorial() -> void:
	if _beat == Beat.DONE:
		return
	_beat = Beat.DONE
	App.enter_map("tutorial_alley")
