class_name MissionHud
extends CanvasLayer

var map_id := ""
var _main: Label
var _side: Label
var _lunch: Label
var _side_done := false
var _main_done := false
var _lunch_done := false


func _ready() -> void:
	layer = 19
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	wrap.position = Vector2(360, 8)
	wrap.size = Vector2(560, 96)
	add_child(wrap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	wrap.add_child(col)
	_main = Label.new()
	_main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_main.custom_minimum_size = Vector2(540, 0)
	UiKit.apply_label(_main, 13, Palette.LEMON)
	col.add_child(_main)
	_side = Label.new()
	_side.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.custom_minimum_size = Vector2(540, 0)
	UiKit.apply_label(_side, 12, Palette.MUTED)
	col.add_child(_side)
	_lunch = Label.new()
	_lunch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lunch.custom_minimum_size = Vector2(540, 0)
	UiKit.apply_label(_lunch, 12, Palette.EDGE)
	col.add_child(_lunch)
	_paint()


func bind(id: String) -> void:
	map_id = id
	_paint()


func _paint() -> void:
	if _main == null or _side == null:
		return
	var row := StoryBook.act(map_id)
	var main := str(row.get("main", ""))
	var side := str(row.get("side", ""))
	_main.text = ("FILED  ·  " if _main_done else "MAIN  ·  ") + main
	_side.text = ("FILED  ·  " if _side_done else "SIDE  ·  ") + side
	_main.add_theme_color_override("font_color", Palette.READY if _main_done else Palette.LEMON)
	_side.add_theme_color_override("font_color", Palette.READY if _side_done else Palette.MUTED)
	if _lunch:
		_lunch.text = ("FILED  ·  " if _lunch_done else "LUNCH  ·  ") + Copy.LUNCH_MISSION
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
