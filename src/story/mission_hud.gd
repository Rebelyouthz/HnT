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


## Show the full card for a while, then fold it down to just the title and
## the main line, dimmed, so it never sits over the fight.
func _peek(hold: float) -> void:
	if _wrap == null:
		return
	if _fold and _fold.is_valid():
		_fold.kill()
	_side.visible = true
	_lunch.visible = true
	_wrap.modulate.a = 1.0
	_fold = create_tween()
	_fold.tween_interval(hold)
	_fold.tween_callback(func() -> void:
		_side.visible = false
		_lunch.visible = false
		_wrap.reset_size()
	)
	_fold.tween_property(_wrap, "modulate:a", 0.7, 0.4)


## Objective card at the top right (under the Father's plate in co-op):
## pixel title, a checkbox line per objective that ticks green when filed.
func _ready() -> void:
	layer = 19
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
	_main = _line(col)
	_side = _line(col)
	_lunch = _line(col)
	_wrap = wrap
	_paint()
	_peek(9.0)


func _line(col: VBoxContainer) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(356, 0)
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
	if _lunch_done:
		return
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs != null and rs.has_method("has_lunch") and bool(rs.call("has_lunch")):
		_lunch_done = true
		_paint()
		_peek(4.0)
		Juice.toast("challenge", "LUNCH PACKED", "Sit at 140m. The wind does not get a bite.")


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
