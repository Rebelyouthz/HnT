class_name AskBox
extends CanvasLayer

## A small yes / no card over a paused game: a title, a line and two big
## buttons with their Xbox buttons on them (A yes, B no). Pad, keyboard and
## mouse; `answered(yes)` fires once and the card frees itself.
##   var ask := AskBox.open(self, "CLIMB AGAIN?", "The clock tower. 132 metres.", "CLIMB", "NOT NOW")
##   var yes: bool = await ask.answered

signal answered(yes: bool)

var title := ""
var line := ""
var yes_text := "YES"
var no_text := "NO"
var _done := false
var _yes: Button


static func open(host: Node, t: String, l: String, y := "YES", n := "NO") -> AskBox:
	var a := AskBox.new()
	a.title = t
	a.line = l
	a.yes_text = y
	a.no_text = n
	host.get_tree().root.add_child(a)
	return a


func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(PixelStage.DESIGN)
	root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(UiKit.GOLD, 0.25))
	root.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)
	var t := UiKit.title(title, 30, Palette.EDGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	if line != "":
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(520, 0)
		UiKit.apply_label(l, 18, Palette.TEXT)
		col.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	_yes = UiKit.button("A  ·  " + yes_text, Vector2(230, 58))
	var no := UiKit.button("B  ·  " + no_text, Vector2(230, 58))
	for b in [_yes, no]:
		b.process_mode = Node.PROCESS_MODE_ALWAYS
		row.add_child(b)
	_yes.pressed.connect(_answer.bind(true))
	no.pressed.connect(_answer.bind(false))
	card.reset_size()
	card.position = ((Vector2(PixelStage.DESIGN) - card.size) * 0.5).round()
	UiKit.pop_in(card)
	_yes.grab_focus.call_deferred()
	Juice.play("res://assets/audio/card.wav")


func _process(_d: float) -> void:
	if _done:
		return
	for p in ["p1_", "p2_"]:
		if Input.is_action_just_pressed(p + "jump"):
			_answer(true)
			return
		if Input.is_action_just_pressed(p + "special") or Input.is_action_just_pressed(p + "pause"):
			_answer(false)
			return
	if Input.is_action_just_pressed("ui_cancel"):
		_answer(false)


func _answer(yes: bool) -> void:
	if _done:
		return
	_done = true
	Juice.play("res://assets/audio/ui_click.wav")
	answered.emit(yes)
	queue_free()
