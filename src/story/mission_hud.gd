class_name MissionHud
extends CanvasLayer

var map_id := ""
var _main: Label
var _side: Label
var _lunch: Label
var _side_done := false
var _main_done := false
var _lunch_done := false


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
	wrap.position = Vector2(930, 116 if App.two_bodies() else 8)
	wrap.custom_minimum_size = Vector2(340, 0)
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
	_paint()


func _line(col: VBoxContainer) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(316, 0)
	UiKit.apply_label(l, 13, Palette.TEXT)
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
		Juice.toast("challenge", "LUNCH PACKED", "Sit at 140m. The wind does not get a bite.")


func complete_side() -> void:
	if _side_done:
		return
	_side_done = true
	_paint()
	FamilyProfile.mark_side()
	Juice.toast("challenge", "SIDE FILED", str(StoryBook.act(map_id).get("side", "")))
	Juice.shout("SIDE HUSTLE")


func complete_main() -> void:
	if _main_done:
		return
	_main_done = true
	_paint()
	Juice.toast("quest", "MAIN FILED", str(StoryBook.act(map_id).get("main", "")))
