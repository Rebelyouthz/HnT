extends CanvasLayer

## The Father — Join. Room code preferred, IP backup collapsed, Connect.

var _code: LineEdit
var _ip: LineEdit
var _ip_wrap: Control
var _status: Label
var _path: Label
var _connect: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.BRICK))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -340
	card.offset_right = 340
	card.offset_top = -260
	card.offset_bottom = 260
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var stamp := Label.new()
	stamp.text = Copy.JOIN
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(stamp, 14, Palette.EDGE)
	col.add_child(stamp)
	var h := Label.new()
	h.text = "ROOM CODE"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(h, 22, Palette.LEMON)
	col.add_child(h)
	_code = LineEdit.new()
	_code.placeholder_text = "7K3Q2M"
	_code.max_length = 8
	_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.add_theme_font_size_override("font_size", 28)
	_code.add_theme_color_override("font_color", Palette.LEMON)
	col.add_child(_code)
	var tog := UiKit.button("SHOW IP BACKUP", Vector2(220, 40))
	col.add_child(tog)
	_ip_wrap = VBoxContainer.new()
	_ip_wrap.visible = false
	var ip_l := Label.new()
	ip_l.text = Copy.IP_BACKUP
	UiKit.apply_label(ip_l, 13, Palette.MUTED)
	_ip_wrap.add_child(ip_l)
	_ip = LineEdit.new()
	_ip.placeholder_text = "192.168.0.12 or public ip"
	_ip.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_wrap.add_child(_ip)
	col.add_child(_ip_wrap)
	tog.pressed.connect(func() -> void:
		_ip_wrap.visible = not _ip_wrap.visible
		tog.text = "HIDE IP BACKUP" if _ip_wrap.visible else "SHOW IP BACKUP"
	)
	_connect = UiKit.button(Copy.CONNECT, Vector2(280, 56))
	_connect.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
	UiKit.pulse_ready(_connect)
	_connect.pressed.connect(_go)
	col.add_child(_connect)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_status, 15, Palette.TEXT)
	col.add_child(_status)
	_path = Label.new()
	_path.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_path, 13, Palette.MUTED)
	col.add_child(_path)
	var back := UiKit.button("BACK", Vector2(160, 44))
	back.pressed.connect(func() -> void:
		NetSession.shutdown()
		queue_free()
	)
	col.add_child(back)
	NetSession.status_changed.connect(_paint)
	NetSession.connected.connect(_on_ok)
	NetSession.failed.connect(func(r: String) -> void:
		_status.text = r
		_connect.disabled = false
	)
	_code.grab_focus()
	Juice.unlock_logo("JOIN", "Paste the code. Connect. Direct first, relay if the router sulks.")


func _go() -> void:
	_connect.disabled = true
	_status.text = Copy.CONNECTING
	NetSession.join(_code.text, _ip.text)


func _paint() -> void:
	_status.text = NetSession.status_line
	if NetSession.path_name != "":
		_path.text = NetSession.path_name


func _on_ok() -> void:
	_path.text = NetSession.path_name
	Juice.toast("quest", "IN", NetSession.path_name)
	queue_free()
