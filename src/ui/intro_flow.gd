extends Node2D

## Film 1 → comic slam → tutorial alley. Skip: pause or light.

enum Beat { FILM1, COMIC, DONE }
var _beat: Beat = Beat.FILM1
var _i := 0
var _layer: CanvasLayer
var _caption: Label
var _who: Label
var _skip: Label
var _film: Dictionary = {}
var _sil_a: ColorRect
var _sil_b: ColorRect
var _letter_t: ColorRect
var _letter_b: ColorRect
var _comic_wrap: Control


func _ready() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.04, 0.045, 0.07)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.size = Vector2(1280, 720)
	add_child(sky)
	_film = StoryBook.all().get("intro", {})
	_layer = CanvasLayer.new()
	_layer.layer = 50
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_letter_t = ColorRect.new()
	_letter_t.color = Color(0, 0, 0, 1)
	_letter_t.position = Vector2(0, 0)
	_letter_t.size = Vector2(1280, 90)
	_layer.add_child(_letter_t)
	_letter_b = ColorRect.new()
	_letter_b.color = Color(0, 0, 0, 1)
	_letter_b.position = Vector2(0, 630)
	_letter_b.size = Vector2(1280, 90)
	_layer.add_child(_letter_b)
	_sil_a = ColorRect.new()
	_sil_a.color = Palette.BRICK
	_sil_a.size = Vector2(70, 160)
	_sil_a.position = Vector2(420, 360)
	_layer.add_child(_sil_a)
	_sil_b = ColorRect.new()
	_sil_b.color = Palette.LEMON
	_sil_b.size = Vector2(54, 150)
	_sil_b.position = Vector2(760, 370)
	_layer.add_child(_sil_b)
	_who = Label.new()
	_who.position = Vector2(80, 520)
	_who.size = Vector2(1120, 28)
	UiKit.apply_label(_who, 14, Palette.EDGE)
	_layer.add_child(_who)
	_caption = Label.new()
	_caption.position = Vector2(80, 552)
	_caption.size = Vector2(1120, 70)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_caption, 22, Palette.TEXT)
	_layer.add_child(_caption)
	_skip = Label.new()
	_skip.position = Vector2(40, 24)
	_skip.text = Copy.SKIP_FILM
	UiKit.apply_label(_skip, 14, Palette.MUTED)
	_layer.add_child(_skip)
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	Juice.play("res://assets/audio/sting_intro.wav")
	_paint_film()


func _process(_delta: float) -> void:
	_sil_a.position.y = 360.0 + 6.0 * sin(Time.get_ticks_msec() * 0.004)
	_sil_b.position.y = 370.0 + 5.0 * sin(Time.get_ticks_msec() * 0.005 + 1.2)
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_advance_hard()
		return
	if Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p2_light"):
		_advance()


func _film_lines() -> Array:
	var key := "film1" if _beat == Beat.FILM1 else "film2"
	var v: Variant = _film.get(key, [])
	return v if typeof(v) == TYPE_ARRAY else []


func _paint_film() -> void:
	var lines := _film_lines()
	if _i >= lines.size():
		if _beat == Beat.FILM1:
			_start_comics()
		else:
			_to_dock()
		return
	var row: Variant = lines[_i]
	if typeof(row) != TYPE_DICTIONARY:
		_i += 1
		_paint_film()
		return
	var d: Dictionary = row
	var who := str(d.get("who", ""))
	_who.text = StoryBook.who_name(who) if who != "" else "INTRO"
	_caption.text = str(d.get("text", ""))
	_caption.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.18)


func _start_comics() -> void:
	_beat = Beat.COMIC
	_i = 0
	_sil_a.visible = false
	_sil_b.visible = false
	_who.text = "FILE PHOTOS"
	_caption.text = ""
	_comic_wrap = Control.new()
	_comic_wrap.size = Vector2(1280, 720)
	_layer.add_child(_comic_wrap)
	var comics: Variant = _film.get("comics", [])
	if typeof(comics) != TYPE_ARRAY:
		_to_tutorial()
		return
	var arr: Array = comics
	for i in arr.size():
		var row: Variant = arr[i]
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = row
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL_2, Palette.LEMON if i == 1 else Palette.BRICK))
		panel.size = Vector2(340, 280)
		panel.position = Vector2(1280, 180)
		_comic_wrap.add_child(panel)
		var col := VBoxContainer.new()
		panel.add_child(col)
		var t := Label.new()
		t.text = str(d.get("title", ""))
		UiKit.apply_label(t, 18, Palette.EDGE)
		col.add_child(t)
		var b := Label.new()
		b.text = str(d.get("text", ""))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(310, 0)
		UiKit.apply_label(b, 16, Palette.TEXT)
		col.add_child(b)
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.12 * i)
		tw.tween_property(panel, "position", Vector2(90 + i * 370, 180), 0.32)
		Juice.play("res://assets/audio/card.wav")
	Juice.unlock_logo("INTAKE COMIC", "Three panels. Zero attendance. Maximum billing.")


func _advance() -> void:
	if _beat == Beat.COMIC:
		_to_tutorial()
		return
	_i += 1
	_paint_film()


func _advance_hard() -> void:
	if _beat == Beat.FILM1:
		_start_comics()
	elif _beat == Beat.COMIC:
		_to_tutorial()
	else:
		_to_dock()


func _to_tutorial() -> void:
	if _beat == Beat.DONE:
		return
	_beat = Beat.DONE
	App.enter_map("tutorial_alley")


func _to_dock() -> void:
	FamilyProfile.mark_intro()
	App.enter_map("dock_street")
