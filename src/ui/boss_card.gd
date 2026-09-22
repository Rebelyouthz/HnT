class_name BossCard
extends CanvasLayer

var _shown_for := ""


static func present(host: Node, title: String, sub: String, accent: Color, full: bool) -> void:
	if host == null:
		return
	if host.get_node_or_null("BossCard"):
		return
	var card := BossCard.new()
	card.name = "BossCard"
	host.add_child(card)
	card.flash(title, sub, accent, full)


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS


func flash(title: String, sub: String, accent: Color, full: bool) -> void:
	_shown_for = title
	var ui := PixelStage.attach_canvas(self)
	var finale := title.to_lower().contains("family plan") or title.to_lower().contains("director")
	if finale:
		Juice.play("res://assets/audio/sting_finale.wav")
	else:
		Juice.play("res://assets/audio/sting_boss.wav")
		if full:
			Mixer.play_music("res://assets/audio/music_boss.wav")
	Juice.pulse_shake(11.0 if finale else (9.0 if full else 5.0))
	Juice.freeze_frames(8 if finale else (5 if full else 3))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	ui.add_child(dim)
	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 0.92)
	top.position = Vector2.ZERO
	top.size = Vector2(1280, 70)
	ui.add_child(top)
	var bot := ColorRect.new()
	bot.color = Color(0, 0, 0, 0.92)
	bot.position = Vector2(0, 650)
	bot.size = Vector2(1280, 70)
	ui.add_child(bot)
	var portrait := ColorRect.new()
	portrait.color = accent
	portrait.size = Vector2(220, 280)
	portrait.position = Vector2(-240, 200)
	ui.add_child(portrait)
	var face := ColorRect.new()
	face.color = accent.lightened(0.25)
	face.size = Vector2(80, 48)
	face.position = Vector2(70, 70)
	portrait.add_child(face)
	var eye_l := ColorRect.new()
	eye_l.color = Color(0.05, 0.04, 0.06)
	eye_l.size = Vector2(18, 10)
	eye_l.position = Vector2(12, 16)
	face.add_child(eye_l)
	var eye_r := ColorRect.new()
	eye_r.color = Color(0.05, 0.04, 0.06)
	eye_r.size = Vector2(18, 10)
	eye_r.position = Vector2(50, 16)
	face.add_child(eye_r)
	var name_l := Label.new()
	name_l.text = title.to_upper()
	name_l.position = Vector2(1280, 250)
	name_l.size = Vector2(640, 60)
	UiKit.apply_label(name_l, 40, Palette.LEMON)
	ui.add_child(name_l)
	var sub_l := Label.new()
	sub_l.text = sub
	sub_l.position = Vector2(1280, 318)
	sub_l.size = Vector2(640, 40)
	UiKit.apply_label(sub_l, 18, accent)
	ui.add_child(sub_l)
	var tag := Label.new()
	if finale:
		tag.text = "FINALE"
	else:
		tag.text = "MINI" if not full else "BOSS"
	tag.position = Vector2(520, 210)
	UiKit.apply_label(tag, 14, Palette.EDGE)
	ui.add_child(tag)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(portrait, "position:x", 120.0, 0.28)
	tw.tween_property(name_l, "position:x", 380.0, 0.32)
	tw.tween_property(sub_l, "position:x", 384.0, 0.36)
	tw.chain().tween_interval(1.35)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.28)
	tw.finished.connect(queue_free)
	Juice.unlock_logo(title.to_upper(), sub)
