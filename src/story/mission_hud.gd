class_name MissionHud
extends CanvasLayer

var map_id := ""
var _main: Label
var _side: Label
var _side_done := false
var _main_done := false


func _ready() -> void:
	layer = 19
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	wrap.position = Vector2(360, 8)
	wrap.size = Vector2(560, 72)
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
