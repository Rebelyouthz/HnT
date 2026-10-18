extends CanvasLayer

## Dad's side of online play, guided: 1) the son presses PLAY WITH DAD,
## 2) FIND MY SON finds him on the same wifi by itself, 3) or type the
## number he reads out (another house) and CONNECT.

var _ip: LineEdit
var _status: Label
var _find: Button
var _connect: Button
var _busy := false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The 1280x720 design canvas (the viewport itself is 640x360).
	var ui := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.9)
	dim.size = Vector2(PixelStage.DESIGN)
	ui.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.BRICK))
	card.custom_minimum_size = Vector2(800, 0)
	ui.add_child(card)
	card.resized.connect(func() -> void:
		card.position = (Vector2(PixelStage.DESIGN) - card.size) * 0.5
	)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	col.add_child(UiKit.title("PLAY WITH MY SON", 30, Palette.LEMON))
	_step(col, "1", "Your son starts the game and presses SON · PLAY WITH DAD. A big number shows on his screen.")
	_step(col, "2", "Same wifi? Press FIND MY SON - no numbers needed.")
	_find = UiKit.button("FIND MY SON", Vector2(360, 60))
	_find.add_theme_font_override("font", UiKit.title_font())
	_find.add_theme_font_size_override("font_size", 24)
	_find.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	UiKit.pulse_ready(_find)
	_find.pressed.connect(_search)
	_center(col, _find)
	_step(col, "3", "Another house? Type the number he reads to you, then CONNECT.")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_ip = LineEdit.new()
	_ip.placeholder_text = "85.228.10.4"
	_ip.custom_minimum_size = Vector2(380, 56)
	_ip.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip.add_theme_font_size_override("font_size", 28)
	_ip.add_theme_color_override("font_color", Palette.LEMON)
	_ip.text = str(FamilyProfile.data.get("son_ip", ""))
	_ip.text_submitted.connect(func(_t: String) -> void: _go())
	row.add_child(_ip)
	_connect = UiKit.button(Copy.CONNECT, Vector2(200, 56))
	_connect.pressed.connect(_go)
	row.add_child(_connect)
	col.add_child(row)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(740, 0)
	UiKit.apply_label(_status, 16, Palette.TEXT)
	col.add_child(_status)
	var back := UiKit.button("BACK", Vector2(200, 46))
	back.pressed.connect(func() -> void:
		NetSession.shutdown()
		queue_free()
	)
	_center(col, back)
	NetSession.status_changed.connect(func() -> void:
		if _busy:
			_status.text = NetSession.status_line
	)
	NetSession.connected.connect(_on_ok)
	NetSession.failed.connect(func(r: String) -> void:
		_busy = false
		_status.text = r
		_find.disabled = false
		_connect.disabled = false
	)
	_find.grab_focus()


func _step(col: VBoxContainer, n: String, text: String) -> void:
	var l := Label.new()
	l.text = "%s.  %s" % [n, text]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(740, 0)
	UiKit.apply_label(l, 16, Palette.TEXT)
	col.add_child(l)


func _center(col: VBoxContainer, c: Control) -> void:
	var box := CenterContainer.new()
	box.add_child(c)
	col.add_child(box)


func _search() -> void:
	if _busy:
		return
	_busy = true
	_find.disabled = true
	_connect.disabled = true
	_status.text = "Looking for your son on this wifi…"
	var ip := await NetSession.find_host(6.0)
	if ip == "":
		_busy = false
		_find.disabled = false
		_connect.disabled = false
		_status.text = "Not found on this wifi. Is his screen showing PLAY WITH DAD? In another house, type his number (step 3)."
		return
	_ip.text = ip
	_status.text = "Found him at %s - connecting…" % ip
	_connect_to(ip)


func _go() -> void:
	if _busy:
		return
	var t := _ip.text.strip_edges()
	if t == "":
		_status.text = "Type the number your son reads out, like 85.228.10.4"
		_ip.grab_focus()
		return
	_busy = true
	_find.disabled = true
	_connect.disabled = true
	_connect_to(t)


func _connect_to(t: String) -> void:
	# Remembered for next time: same son, same number, one press.
	FamilyProfile.data["son_ip"] = t
	FamilyProfile.save()
	_status.text = Copy.CONNECTING
	NetSession.join_text(t)


func _on_ok() -> void:
	Juice.toast("quest", "CONNECTED", "You're in your son's game.")
	queue_free()
