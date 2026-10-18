extends CanvasLayer

## The Son's side of online play: one button got him here, nothing to type.
## His game hosts; the screen shows the number to read out to Dad, big, and
## a three-step guide. Dad's FIND MY SON finds it on the same wifi by itself.

var _status: Label
var _lan: Label
var _wan: Label
var _code: Label
var _spin: Label
var _t := 0.0


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
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	card.custom_minimum_size = Vector2(800, 0)
	ui.add_child(card)
	card.resized.connect(func() -> void:
		card.position = (Vector2(PixelStage.DESIGN) - card.size) * 0.5
	)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(UiKit.title("PLAY WITH DAD", 30, Palette.LEMON))
	_step(col, "1", "You are the SON. Your game is ready - you don't press anything else.", Palette.READY)
	_step(col, "2", "Read this number out to Dad:", Palette.TEXT)
	_lan = Label.new()
	_lan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_lan, 46, Palette.LEMON)
	col.add_child(_lan)
	_wan = Label.new()
	_wan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A wrapping label needs a width up front, or it reports one word per
	# line on the first layout and the card grows off the screen.
	_wan.custom_minimum_size = Vector2(740, 0)
	UiKit.apply_label(_wan, 17, Palette.EDGE)
	col.add_child(_wan)
	_step(col, "3", "Dad presses DAD · FIND MY SON. Same wifi: it finds you by itself. Other house: he types the number.", Palette.TEXT)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(740, 0)
	UiKit.apply_label(_status, 22, Palette.LEMON)
	col.add_child(_status)
	_spin = Label.new()
	_spin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_spin, 18, Palette.READY)
	col.add_child(_spin)
	var fw := Label.new()
	fw.text = "If Windows asks about the firewall: press ALLOW."
	fw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(fw, 13, Palette.MUTED)
	col.add_child(fw)
	_code = Label.new()
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_code, 12, Palette.MUTED)
	col.add_child(_code)
	var cancel := UiKit.button("BACK", Vector2(200, 46))
	cancel.pressed.connect(_cancel)
	var row := CenterContainer.new()
	row.add_child(cancel)
	col.add_child(row)
	NetSession.status_changed.connect(_paint)
	NetSession.connected.connect(_go)
	NetSession.failed.connect(func(r: String) -> void:
		_status.text = r
	)
	if not NetSession.is_host():
		NetSession.host()
	NetSession.host_open_relay()
	_paint()
	cancel.grab_focus()


func _step(col: VBoxContainer, n: String, text: String, c: Color) -> void:
	var l := Label.new()
	l.text = "%s.  %s" % [n, text]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(740, 0)
	UiKit.apply_label(l, 16, c)
	col.add_child(l)


func _process(delta: float) -> void:
	_t += delta
	_spin.text = "·".repeat(int(_t * 3.0) % 4 + 1)
	_status.modulate = Color(1, 1, 1, 0.7 + 0.3 * absf(sin(_t * 2.2)))
	_lan.scale = Vector2.ONE * (1.0 + 0.03 * sin(_t * 3.0))


func _paint() -> void:
	_lan.text = NetSession.lan_ip if NetSession.lan_ip != "" else "…"
	_lan.pivot_offset = Vector2(370, 28)
	if NetSession.wan_ip != "" and NetSession.wan_ip != NetSession.lan_ip:
		_wan.text = "Dad in ANOTHER HOUSE? Read him this one instead:  %s" % NetSession.wan_ip
	else:
		_wan.text = "Dad in another house? Looking up your internet number…"
	_status.text = NetSession.status_line if NetSession.status_line != "" else Copy.WAITING
	_code.text = "room code %s%s" % [NetSession.room_code, "  ·  router opened (UPnP)" if NetSession.upnp_ok else ""]


func _go() -> void:
	Juice.toast("quest", "DAD IS IN", "Here we go.")
	queue_free()


func _cancel() -> void:
	NetSession.shutdown()
	NetSession.cancelled.emit()
	queue_free()
