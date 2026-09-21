extends CanvasLayer

## The Son — waiting screen. Huge room code, IP backup, WAITING FOR FATHER.

var _code: Label
var _ip: Label
var _status: Label
var _spin: Label
var _t := 0.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -340
	card.offset_right = 340
	card.offset_top = -250
	card.offset_bottom = 250
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var stamp := Label.new()
	stamp.text = Copy.HOST
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(stamp, 14, Palette.EDGE)
	col.add_child(stamp)
	var mark := LogoMark.new()
	mark.custom_minimum_size = Vector2(56, 56)
	col.add_child(mark)
	_status = Label.new()
	_status.text = Copy.WAITING
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_status, 28, Palette.LEMON)
	col.add_child(_status)
	_code = Label.new()
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.pivot_offset = Vector2(160, 28)
	UiKit.apply_label(_code, 56, Palette.TEXT)
	col.add_child(_code)
	var share := Label.new()
	share.text = Copy.SHARE_CODE
	share.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	share.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(share, 15, Palette.MUTED)
	col.add_child(share)
	_ip = Label.new()
	_ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_ip, 16, Palette.EDGE)
	col.add_child(_ip)
	_spin = Label.new()
	_spin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_spin, 18, Palette.READY)
	col.add_child(_spin)
	var cancel := UiKit.button(Copy.CANCEL_HOST, Vector2(240, 48))
	cancel.pressed.connect(_cancel)
	col.add_child(cancel)
	NetSession.status_changed.connect(_paint)
	NetSession.connected.connect(_go)
	NetSession.failed.connect(func(r: String) -> void:
		_status.text = r
	)
	if not NetSession.is_host():
		NetSession.host()
	else:
		_paint()
	NetSession.host_open_relay()
	cancel.grab_focus()
	Juice.unlock_logo("HOST", "Text him the code. The IP is a backup, not a personality.")


func _process(delta: float) -> void:
	_t += delta
	var dots := int(_t * 3.0) % 4
	_spin.text = "·".repeat(dots + 1)
	var pulse := 1.0 + 0.06 * sin(_t * 4.0)
	_code.scale = Vector2(pulse, pulse)
	_status.modulate = Color(1, 1, 1, 0.72 + 0.28 * absf(sin(_t * 2.2)))


func _paint() -> void:
	_code.text = NetSession.room_code
	_status.text = NetSession.status_line if NetSession.status_line != "" else Copy.WAITING
	var bits: PackedStringArray = [Copy.IP_BACKUP, NetSession.backup_ip]
	if NetSession.lan_ip != "":
		bits.append("LAN %s" % NetSession.lan_ip)
	if NetSession.wan_ip != "":
		bits.append("WAN %s" % NetSession.wan_ip)
	if NetSession.upnp_ok:
		bits.append("UPnP OK")
	_ip.text = "  ·  ".join(bits)


func _go() -> void:
	Juice.toast("quest", "FATHER IN", Copy.PATH_DIRECT if NetSession.path_name == Copy.PATH_DIRECT else Copy.PATH_RELAY)
	queue_free()


func _cancel() -> void:
	NetSession.shutdown()
	NetSession.cancelled.emit()
	queue_free()
