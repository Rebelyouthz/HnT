extends CanvasLayer

## PLAY ONLINE (title screen): who are you? Two big buttons, the one picked
## last time already highlighted. The Son's button is the whole of his job.

const SON := "SON · PLAY WITH DAD"
const DAD := "DAD · FIND MY SON"


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The 1280x720 design canvas (the viewport itself is 640x360).
	var ui := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.88)
	dim.size = Vector2(PixelStage.DESIGN)
	ui.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	card.custom_minimum_size = Vector2(760, 0)
	ui.add_child(card)
	card.resized.connect(func() -> void:
		card.position = (Vector2(PixelStage.DESIGN) - card.size) * 0.5
	)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	col.add_child(UiKit.title("PLAY ONLINE TOGETHER", 30, Palette.LEMON))
	var who := Label.new()
	who.text = "Who are you?"
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(who, 20, Palette.TEXT)
	col.add_child(who)
	var son := _big(col, SON, "Press this. That's it - you'll get a code to read to Dad.")
	var dad := _big(col, DAD, "Press this after your son, then type the code he reads to you.")
	son.pressed.connect(func() -> void: _pick("son"))
	dad.pressed.connect(func() -> void: _pick("father"))
	var back := UiKit.button("BACK", Vector2(200, 44))
	back.pressed.connect(queue_free)
	var box := CenterContainer.new()
	box.add_child(back)
	col.add_child(box)
	(dad if str(FamilyProfile.data.get("online_role", "son")) == "father" else son).grab_focus()


func _big(col: VBoxContainer, text: String, sub: String) -> Button:
	var b := UiKit.button(text, Vector2(560, 64))
	b.add_theme_font_override("font", UiKit.title_font())
	b.add_theme_font_size_override("font_size", 24)
	UiKit.pulse_ready(b)
	var box := CenterContainer.new()
	box.add_child(b)
	col.add_child(box)
	var l := Label.new()
	l.text = sub
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(l, 14, Palette.MUTED)
	col.add_child(l)
	return b


## The host plays the Son, the guest the Father (NetSession binds them).
func _pick(role: String) -> void:
	Juice.play("res://assets/audio/ui_click.wav")
	FamilyProfile.data["online_role"] = role
	FamilyProfile.data["named"] = true
	FamilyProfile.save()
	App.solo_role = role
	App.couch = false
	App.remote_coop = false
	var sheet: Node = (preload("res://src/ui/host_wait.gd") if role == "son" else preload("res://src/ui/join_sheet.gd")).new()
	get_tree().root.add_child(sheet)
	queue_free()
