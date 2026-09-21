extends Node2D

## SoR4 comic-between-stages. Pause skips the current beat. Light/jump advances a line.

enum Beat { CHAPTER, FILM, DONE }

var _beat: Beat = Beat.CHAPTER
var _i := 0
var _lines: Array = []
var _layer: CanvasLayer
var _caption: Label
var _who: Label
var _skip: Label
var _chapter: Label
var _sub: Label
var _sil_a: ColorRect
var _sil_b: ColorRect
var _kind := "bridge"


func _ready() -> void:
	_kind = App.film_kind if App.film_kind != "" else "bridge"
	var sky := ColorRect.new()
	sky.color = Color(0.035, 0.04, 0.065)
	sky.position = Vector2.ZERO
	sky.size = Vector2(1280, 720)
	add_child(sky)
	_layer = CanvasLayer.new()
	_layer.layer = 50
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var letter_t := ColorRect.new()
	letter_t.color = Color(0, 0, 0, 1)
	letter_t.position = Vector2(0, 0)
	letter_t.size = Vector2(1280, 90)
	_layer.add_child(letter_t)
	var letter_b := ColorRect.new()
	letter_b.color = Color(0, 0, 0, 1)
	letter_b.position = Vector2(0, 630)
	letter_b.size = Vector2(1280, 90)
	_layer.add_child(letter_b)
	_sil_a = ColorRect.new()
	_sil_a.color = Palette.BRICK
	_sil_a.size = Vector2(78, 176)
	_sil_a.position = Vector2(400, 348)
	_layer.add_child(_sil_a)
	_sil_b = ColorRect.new()
	_sil_b.color = Palette.LEMON
	_sil_b.size = Vector2(56, 158)
	_sil_b.position = Vector2(790, 366)
	_layer.add_child(_sil_b)
	_chapter = Label.new()
	_chapter.position = Vector2(80, 220)
	_chapter.size = Vector2(1120, 70)
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_chapter, 36, Palette.LEMON)
	_layer.add_child(_chapter)
	_sub = Label.new()
	_sub.position = Vector2(80, 300)
	_sub.size = Vector2(1120, 48)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_sub, 18, Palette.EDGE)
	_layer.add_child(_sub)
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
	_lines = StoryBook.film_lines(_kind, App.film_from, App.film_next)
	var ch := StoryBook.chapter_card(_kind, App.film_from, App.film_next)
	_chapter.text = str(ch.get("title", "NEXT SESSION"))
	_sub.text = str(ch.get("sub", ""))
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	if _kind == "ending":
		Juice.play("res://assets/audio/sting_intro.wav")
		Juice.unlock_logo("THE NIGHT CLOSES", "The invoice is a corpse. The fridge stays.")
	else:
		Juice.play("res://assets/audio/sting_intro.wav")
	_paint_chapter()


func _process(_delta: float) -> void:
	_sil_a.position.y = 348.0 + 6.0 * sin(Time.get_ticks_msec() * 0.004)
	_sil_b.position.y = 366.0 + 5.0 * sin(Time.get_ticks_msec() * 0.005 + 1.2)
	if Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause"):
		_advance_hard()
		return
	if Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p2_light") or Input.is_action_just_pressed("p2_jump"):
		_advance()


func _paint_chapter() -> void:
	_beat = Beat.CHAPTER
	_who.text = ""
	_caption.text = Copy.SKIP_FILM
	_sil_a.visible = false
	_sil_b.visible = false
	_chapter.visible = true
	_sub.visible = true
	_chapter.modulate.a = 0.0
	_sub.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chapter, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_sub, "modulate:a", 1.0, 0.28)
	Juice.play("res://assets/audio/card.wav")


func _paint_film() -> void:
	_chapter.visible = false
	_sub.visible = false
	_sil_a.visible = true
	_sil_b.visible = true
	if _i >= _lines.size():
		_leave()
		return
	var row: Variant = _lines[_i]
	if typeof(row) != TYPE_DICTIONARY:
		_i += 1
		_paint_film()
		return
	var d: Dictionary = row
	var who := str(d.get("who", ""))
	_who.text = StoryBook.who_name(who) if who != "" else "THE STREET"
	_caption.text = str(d.get("text", ""))
	_caption.modulate.a = 0.0
	_tint_speakers(who)
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.16)


func _tint_speakers(who: String) -> void:
	if who == "father":
		_sil_a.modulate = Color(1.35, 1.1, 1.05)
		_sil_b.modulate = Color(0.32, 0.32, 0.34, 0.5)
		_who.add_theme_color_override("font_color", Palette.BRICK)
	elif who == "son":
		_sil_a.modulate = Color(0.32, 0.32, 0.34, 0.5)
		_sil_b.modulate = Color(1.25, 1.28, 0.85)
		_who.add_theme_color_override("font_color", Palette.LEMON)
	else:
		_sil_a.modulate = Color(1, 1, 1)
		_sil_b.modulate = Color(1, 1, 1)
		_who.add_theme_color_override("font_color", Palette.EDGE)


func _advance() -> void:
	if _beat == Beat.CHAPTER:
		_beat = Beat.FILM
		_i = 0
		_paint_film()
		return
	if _beat == Beat.FILM:
		_i += 1
		_paint_film()


func _advance_hard() -> void:
	if _beat == Beat.CHAPTER:
		_beat = Beat.FILM
		_i = 0
		_paint_film()
		return
	if _beat == Beat.FILM:
		_leave()


func _leave() -> void:
	if _beat == Beat.DONE:
		return
	_beat = Beat.DONE
	if _kind == "ending" or App.film_next == "" or App.film_next == "hub":
		FamilyProfile.mark_ending()
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		if App.remote_coop:
			NetSession.shutdown()
		App.back_to_hub("awards")
		return
	var nxt := App.film_next
	App.film_kind = ""
	if App.remote_coop and NetSession.is_host():
		NetSession.broadcast_begin(nxt, App.begin_extra())
		return
	App.enter_map(nxt)
