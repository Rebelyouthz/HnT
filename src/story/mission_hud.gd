class_name MissionHud
extends CanvasLayer

var map_id := ""
var _main: Label
var _side: Label
var _lunch: Label
var _side_done := false
var _main_done := false
var _lunch_done := false
var _wrap: Control
var _fold: Tween
var _col: VBoxContainer
var _quests: Dictionary = {}
var _line_w := 356.0


## Show the full card for a while, then fold it down to just the title and
## the main line, dimmed, so it never sits over the fight.
func _peek(hold: float) -> void:
	if _wrap == null:
		return
	if _fold and _fold.is_valid():
		_fold.kill()
	_set_folded(false)
	_wrap.modulate.a = 1.0
	_fold = create_tween()
	_fold.tween_interval(hold)
	_fold.tween_callback(_set_folded.bind(true))
	_fold.tween_property(_wrap, "modulate:a", 0.62, 0.4)


## Folded: one trimmed line (the main job), every other line hidden, so the
## card is a slim strip under the boss bar instead of a block over the street.
func _set_folded(on: bool) -> void:
	if _wrap == null:
		return
	_side.visible = not on
	_lunch.visible = not on
	for k in _quests.keys():
		var q := _quests[k] as Label
		if q:
			q.visible = not on
	_main.autowrap_mode = TextServer.AUTOWRAP_OFF if on else TextServer.AUTOWRAP_WORD_SMART
	_main.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if on else TextServer.OVERRUN_NO_TRIMMING
	_main.clip_text = on
	_wrap.reset_size()


## Objective card at the top right (under the Father's plate in co-op):
## pixel title, a checkbox line per objective that ticks green when filed.
func _ready() -> void:
	layer = 19
	# Keep ticking while paused so the card can step aside for menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var wrap := PanelContainer.new()
	var st := UiKit.panel(Color(0.04, 0.06, 0.12, 0.86), UiKit.RIM)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 6
	st.content_margin_bottom = 8
	wrap.add_theme_stylebox_override("panel", st)
	# Centre, under the enemy / boss bar: clear of both player plates.
	wrap.position = Vector2(450, 78)
	wrap.custom_minimum_size = Vector2(380, 0)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PixelStage.attach_canvas(self).add_child(wrap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	wrap.add_child(col)
	var head := Label.new()
	head.text = "OBJECTIVES"
	head.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(head, 16, UiKit.GOLD)
	head.add_theme_color_override("font_outline_color", UiKit.INK)
	col.add_child(head)
	_col = col
	_main = _line(col)
	_side = _line(col)
	_lunch = _line(col)
	_wrap = wrap
	_paint()
	_peek(9.0)
	# The survivor field keeps the centre clear for the clock: the card
	# tucks under the radar on the right, narrower and smaller.
	if Fighter.FIELD:
		wrap.position = Vector2(1030, 280)
		wrap.custom_minimum_size = Vector2(236, 0)
		head.add_theme_font_size_override("font_size", 13)
		_line_w = 212.0
		for l in [_main, _side, _lunch]:
			(l as Label).custom_minimum_size = Vector2(212, 0)
			(l as Label).add_theme_font_size_override("font_size", 11)
		wrap.size = Vector2.ZERO
		wrap.reset_size()


func _line(col: VBoxContainer) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_line_w, 0)
	if _line_w < 300.0:
		l.add_theme_font_size_override("font_size", 11)
	UiKit.apply_label(l, 12, Palette.TEXT)
	col.add_child(l)
	return l


func bind(id: String) -> void:
	map_id = id
	_paint()


func _paint() -> void:
	if _main == null or _side == null:
		return
	var row := StoryBook.act(map_id)
	var main := str(row.get("main", ""))
	var side := str(row.get("side", ""))
	_main.text = ("☑  " if _main_done else "☐  ") + main
	_side.text = ("☑  " if _side_done else "☐  ") + side
	_main.add_theme_color_override("font_color", Palette.READY if _main_done else Palette.TEXT)
	_side.add_theme_color_override("font_color", Palette.READY if _side_done else Palette.MUTED)
	if _lunch:
		_lunch.text = ("☑  " if _lunch_done else "☐  ") + Copy.LUNCH_MISSION
		_lunch.add_theme_color_override("font_color", Palette.READY if _lunch_done else Palette.EDGE)


func _process(_delta: float) -> void:
	# Pause, level-up picks and sheets: the objective card steps aside.
	if _wrap:
		_wrap.visible = not get_tree().paused
	if get_tree().paused:
		return
	if _lunch_done:
		return
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs != null and rs.has_method("has_lunch") and bool(rs.call("has_lunch")):
		_lunch_done = true
		_paint()
		_peek(4.0)
		Juice.toast("challenge", "LUNCH PACKED", "Sit at 140m. The wind does not get a bite.")


## A street quest's line on the card (added on accept, ticked when paid).
func quest_line(id: String, text: String, state: String) -> void:
	if _col == null:
		return
	var l: Label = _quests.get(id) as Label
	if l == null:
		l = _line(_col)
		_quests[id] = l
	var mark := "☑  " if state == "paid" else ("➜  " if state == "ready" else "◆  ")
	l.text = mark + text
	l.add_theme_color_override("font_color", Palette.READY if state == "paid" else (UiKit.GOLD if state == "ready" else Color(0.75, 0.85, 1.0)))
	_peek(5.0)


func complete_side() -> void:
	if _side_done:
		return
	_side_done = true
	_paint()
	_peek(4.0)
	FamilyProfile.mark_side()
	Juice.toast("challenge", "SIDE FILED", str(StoryBook.act(map_id).get("side", "")))
	Juice.shout("SIDE HUSTLE")


func complete_main() -> void:
	if _main_done:
		return
	_main_done = true
	_paint()
	_peek(4.0)
	Juice.toast("quest", "MAIN FILED", str(StoryBook.act(map_id).get("main", "")))
