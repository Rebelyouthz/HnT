extends Control

## Start screen: the painted city drifting behind rain, Father and Son on the
## kerb, the logo, and START GAME / CONTINUE / OPTIONS / CREDITS / QUIT.
## START GAME runs the story from the first film; CONTINUE goes to the clinic.

const DEFAULT_FATHER := "TimmieTooth"
const DEFAULT_SON := "HugoLugo"
## 8/3 design px per backdrop texel = exactly 4 screen px on 1080p.
const BD_SCALE := 8.0 / 3.0
## Actors at 2 screen px per texel on 1080p (design scale 0.5 x 3).
const ACTOR_SCALE := 2.3

var _bd: Array[TextureRect] = []
var _bd_w := 0.0
var _menu: VBoxContainer
var _modal: Control
var _logo: Label
var _t := 0.0
var _rain: CPUParticles2D
var _flash: ColorRect


func _ready() -> void:
	PixelStage.apply_control(self)
	_seed_names()
	Mixer.play_music("res://assets/audio/music/music_menu.ogg")
	_build_backdrop()
	_build_actors()
	_build_overlay()
	_build_logo()
	_build_menu()
	_build_footer()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


## The two creators are the default Father and Son until renamed in the clinic.
func _seed_names() -> void:
	var d := FamilyProfile.data
	if str(d.get("father_name", "")).strip_edges() == "":
		d["father_name"] = DEFAULT_FATHER
	if str(d.get("son_name", "")).strip_edges() == "":
		d["son_name"] = DEFAULT_SON


func _build_backdrop() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.03, 0.035, 0.07)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var path := "res://assets/backdrops/dock.png"
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	_bd_w = float(tex.get_width()) * BD_SCALE
	var h := float(tex.get_height()) * BD_SCALE
	for i in 3:
		var r := TextureRect.new()
		r.texture = tex
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.size = Vector2(_bd_w, h)
		r.position = Vector2(_bd_w * float(i), 720.0 - h + 40.0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_bd.append(r)


func _build_actors() -> void:
	var stage := Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	var specs := [["father", Vector2(250, 640), 1], ["son", Vector2(390, 646), 1]]
	for s: Array in specs:
		var who := str(s[0])
		if not SpriteBook.has_who(who):
			continue
		var a := SpriteBook.make_anim(who)
		a.scale = Vector2(ACTOR_SCALE, ACTOR_SCALE)
		var cell_h := float(a.sprite_frames.get_frame_texture("idle", 0).get_height())
		a.position = (s[1] as Vector2) - Vector2(0, cell_h * ACTOR_SCALE * 0.5 - 4.0)
		a.flip_h = int(s[2]) < 0
		a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		a.speed_scale = 0.9 if who == "father" else 1.0
		stage.add_child(a)
		var shadow := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 16:
			var ang := TAU * float(i) / 16.0
			pts.append(Vector2(cos(ang) * 46.0, sin(ang) * 8.0))
		shadow.polygon = pts
		shadow.color = Color(0, 0, 0, 0.5)
		shadow.position = s[1] as Vector2
		stage.add_child(shadow)
		stage.move_child(shadow, 0)
	_rain = CPUParticles2D.new()
	_rain.position = Vector2(640, -20)
	_rain.amount = 260
	_rain.lifetime = 0.9
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(760, 4)
	_rain.direction = Vector2(0.18, 1.0)
	_rain.spread = 2.0
	_rain.gravity = Vector2.ZERO
	_rain.initial_velocity_min = 820.0
	_rain.initial_velocity_max = 980.0
	_rain.scale_amount_min = 1.0
	_rain.scale_amount_max = 1.6
	_rain.color = Color(0.62, 0.72, 0.95, 0.35)
	_rain.emitting = true
	stage.add_child(_rain)


func _build_overlay() -> void:
	# Night grade + a dark band on the right so the menu reads over the city.
	var night := ColorRect.new()
	night.color = Color(0.05, 0.06, 0.16, 0.38)
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)
	var band := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.0, 0.0, 0.02, 0.0))
	g.set_color(1, Color(0.0, 0.0, 0.02, 0.86))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	band.texture = gt
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2(560, 0)
	band.size = Vector2(720, 720)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	_flash = ColorRect.new()
	_flash.color = Color(0.85, 0.9, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _build_logo() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(700, 70)
	box.size = Vector2(540, 200)
	box.add_theme_constant_override("separation", -6)
	add_child(box)
	_logo = UiKit.title("FATHER", 82, Palette.EDGE)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_logo)
	var amp := UiKit.title("&  SON", 64, Palette.LEMON)
	amp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(amp)
	var tag := Label.new()
	tag.text = "RAVEN WHARF  ·  ONE NIGHT  ·  NO INSURANCE"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(tag, 16, Palette.MUTED)
	box.add_child(tag)


func _build_menu() -> void:
	_menu = VBoxContainer.new()
	_menu.position = Vector2(830, 330)
	_menu.size = Vector2(280, 300)
	_menu.add_theme_constant_override("separation", 12)
	add_child(_menu)
	var has_save := bool(FamilyProfile.data.get("intro_done", false))
	_add_item("PLAY GAME", _play)
	if has_save:
		_add_item("CONTINUE", _continue)
	_add_item("OPTIONS", _options)
	_add_item("CREDITS", _credits)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		_add_item("QUIT", func() -> void: get_tree().quit())
	# Last night, under CONTINUE: where it ended and how.
	var hist: Array = FamilyProfile.data.get("run_history", [])
	if has_save and not hist.is_empty():
		var h: Dictionary = hist[0]
		var last := Label.new()
		last.text = "LAST NIGHT  ·  %s  ·  %s  ·  %d KILLS" % [StageCard.title_of(str(h.get("map", ""))), "CLEARED" if bool(h.get("ok", false)) else "WENT DOWN", int(h.get("kills", 0))]
		last.custom_minimum_size = Vector2(280, 0)
		last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		last.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.apply_label(last, 11, Palette.MUTED)
		_menu.add_child(last)
		_menu.move_child(last, 2)
	var first := _menu.get_child(0) as Button
	if first:
		first.call_deferred("grab_focus")


func _add_item(text: String, cb: Callable) -> void:
	var b := UiKit.button(text, Vector2(280, 50))
	b.add_theme_font_override("font", UiKit.title_font())
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func() -> void:
		Juice.play("res://assets/audio/ui_click.wav")
		cb.call()
	)
	b.focus_entered.connect(func() -> void:
		Juice.play("res://assets/audio/chrome_ui.wav")
	)
	_menu.add_child(b)


func _build_footer() -> void:
	var f := Label.new()
	f.text = "A  %s  &  %s  GAME" % [DEFAULT_FATHER.to_upper(), DEFAULT_SON.to_upper()]
	f.position = Vector2(700, 676)
	f.size = Vector2(540, 24)
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(f, 13, Palette.MUTED)
	add_child(f)


func _process(delta: float) -> void:
	_t += delta
	if _bd_w > 0.0:
		var off := fmod(_t * 6.0, _bd_w)
		for i in _bd.size():
			_bd[i].position.x = roundf(_bd_w * float(i) - off)
	if _logo:
		_logo.modulate = Color(1, 1, 1, 0.92 + 0.08 * sin(_t * 2.2))
	# Far lightning now and then.
	if _flash and randf() < delta * 0.06:
		var tw := _flash.create_tween()
		tw.tween_property(_flash, "color:a", 0.16, 0.05)
		tw.tween_property(_flash, "color:a", 0.0, 0.5)


## PLAY GAME: the character select (mode, online guide, the stage button).
func _play() -> void:
	_clear_modal()
	_seed_names()
	var sheet := preload("res://src/ui/character_select.gd").new()
	add_child(sheet)
	_modal = sheet
	_menu.visible = false
	sheet.closed.connect(func() -> void:
		_modal = null
		_menu.visible = true
		var first := _menu.get_child(0) as Button
		if first:
			first.grab_focus()
	)


func _start_game() -> void:
	_seed_names()
	FamilyProfile.data["named"] = true
	FamilyProfile.save()
	_leave(func() -> void: App.play_intro())


func _continue() -> void:
	var r: Variant = FamilyProfile.data.get("resume", {})
	if r is Dictionary and str((r as Dictionary).get("map", "")) != "":
		var d := r as Dictionary
		App.resume_map = str(d["map"])
		App.resume_pos = Vector2(float(d.get("x", 0.0)), float(d.get("y", 490.0)))
		_leave(func() -> void: App.enter_map(App.resume_map))
		return
	_leave(func() -> void: App.back_to_hub("clinic"))


func _leave(then: Callable) -> void:
	_menu.process_mode = Node.PROCESS_MODE_DISABLED
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(0, 0, 0, 1), 0.35)
	tw.tween_callback(then)


func _options() -> void:
	_clear_modal()
	var sheet := preload("res://src/ui/settings_sheet.gd").new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	_modal = sheet
	sheet.closed.connect(_clear_modal)


func _credits() -> void:
	_clear_modal()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_modal = root
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.EDGE, 0.4))
	card.position = Vector2(340, 110)
	card.size = Vector2(600, 500)
	root.add_child(card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	var h := UiKit.title("CREDITS", 40, Palette.EDGE)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	for row: Array in [["TimmieTooth", "THE FATHER", Palette.BRICK, "father"], ["HugoLugo", "THE SON", Palette.LEMON, "son"]]:
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 18)
		var pic := UiKit.portrait(SpriteBook.bust(str(row[3])), Vector2(88, 88))
		line.add_child(pic)
		var txt := VBoxContainer.new()
		var name_l := UiKit.title(str(row[0]), 34, row[2] as Color)
		txt.add_child(name_l)
		var role_l := Label.new()
		role_l.text = str(row[1])
		UiKit.apply_label(role_l, 16, Palette.MUTED)
		txt.add_child(role_l)
		line.add_child(txt)
		col.add_child(line)
	var made := Label.new()
	made.text = "Created, directed, played and argued over by the two of them."
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	made.custom_minimum_size = Vector2(520, 0)
	UiKit.apply_label(made, 15, Palette.TEXT)
	col.add_child(made)
	var fonts := Label.new()
	fonts.text = "Fonts: Cinzel, Rajdhani (SIL Open Font License)  ·  Engine: Godot"
	fonts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(fonts, 12, Palette.MUTED)
	col.add_child(fonts)
	var back := UiKit.button("BACK", Vector2(200, 44))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_clear_modal)
	col.add_child(back)
	back.call_deferred("grab_focus")
	UiKit.pop_in(card)


func _clear_modal() -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	if _menu and _menu.get_child_count() > 0:
		(_menu.get_child(0) as Button).call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if _modal != null and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_pause")):
		_clear_modal()
		get_viewport().set_input_as_handled()
