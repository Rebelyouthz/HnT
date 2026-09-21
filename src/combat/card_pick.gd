class_name CardPick
extends CanvasLayer

signal picked(id: String)

var _done := false
var _timer := 12.0
var _clock: Label
var ids: Array = []


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	Juice.set_world_scale(0.12)
	Juice.play("res://assets/audio/card.wav")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var row := HBoxContainer.new()
	row.position = Vector2(80, 180)
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if ids.is_empty():
		for c in table:
			if bool(c.get("fixed", false)):
				ids.append(c["id"])
	for i in mini(3, ids.size()):
		var card: Dictionary = {}
		for c in table:
			if str(c["id"]) == str(ids[i]):
				card = c
				break
		row.add_child(_card(card, i == 1))
	_clock = Label.new()
	_clock.position = Vector2(480, 120)
	_clock.size = Vector2(320, 40)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_clock, 18, Palette.LEMON)
	add_child(_clock)
	var note := Label.new()
	note.position = Vector2(240, 520)
	note.size = Vector2(800, 40)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "World is slow. Enemies are not paused. Die in the menu. That's the bit."
	UiKit.apply_label(note, 14, Palette.MUTED)
	add_child(note)
	_focus_middle(row)


func _focus_middle(row: HBoxContainer) -> void:
	if row.get_child_count() >= 2:
		var b := row.get_child(1).find_child("Pick", true, false)
		if b is Button:
			(b as Button).grab_focus()


func _card(info: Dictionary, mid: bool) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(340, 260)
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL if not mid else Palette.PANEL_2, Palette.LEMON if mid else Palette.EDGE))
	var col := VBoxContainer.new()
	wrap.add_child(col)
	var t := Label.new()
	t.text = str(info.get("name", "?"))
	UiKit.apply_label(t, 20, Palette.LEMON)
	col.add_child(t)
	var b := Label.new()
	b.text = str(info.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(300, 0)
	UiKit.apply_label(b, 14, Palette.TEXT)
	col.add_child(b)
	var go := UiKit.button("TAKE IT", Vector2(160, 44))
	go.name = "Pick"
	go.pressed.connect(func() -> void:
		_choose(str(info.get("id", "")))
	)
	col.add_child(go)
	return wrap


func _process(delta: float) -> void:
	_timer -= delta / maxf(Engine.time_scale, 0.01)
	_clock.text = "PICK A RULE  ·  %.0f" % maxf(0.0, _timer)
	if _timer <= 0.0 and not _done:
		if ids.size() >= 2:
			_choose(str(ids[1]))
		elif ids.size() == 1:
			_choose(str(ids[0]))


func _choose(id: String) -> void:
	if _done:
		return
	_done = true
	Juice.set_world_scale(1.0)
	picked.emit(id)
	queue_free()
