extends SceneTree

## The three ways up side by side (ladder, drainpipe, bin+awning boost) on
## a plain street front, labelled; one frame saved.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/ways_show.gd -- /tmp/ways.png

var _out := "/tmp/ways.png"
var _frame := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 3:
		_build()
	if _frame == 30:
		root.get_viewport().get_texture().get_image().save_png(_out)
		quit(0)
		return true
	return false


func _build() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var cam := Camera2D.new()
	cam.position = Vector2(320, 360)
	cam.zoom = Vector2(0.62, 0.62)
	stage.add_child(cam)
	cam.make_current()
	var wall := ColorRect.new()
	wall.color = Color(0.2, 0.09, 0.08)
	wall.position = Vector2(0, 230)
	wall.size = Vector2(640, 270)
	stage.add_child(wall)
	var roof := ColorRect.new()
	roof.color = Color(0.12, 0.11, 0.14)
	roof.position = Vector2(0, 226)
	roof.size = Vector2(640, 24)
	stage.add_child(roof)
	var street := ColorRect.new()
	street.color = Color(0.13, 0.13, 0.17)
	street.position = Vector2(0, 500)
	street.size = Vector2(640, 60)
	stage.add_child(street)
	var names := ["LADDER", "DRAINPIPE", "BIN + AWNING"]
	var styles := ["ladder", "pipe", "boost"]
	for i in 3:
		var fe := FireEscape.new()
		fe.configure(140.0 + float(i) * 180.0, 248.0, 500.0, styles[i])
		stage.add_child(fe)
		var l := Label.new()
		l.text = names[i]
		l.position = Vector2(80.0 + float(i) * 180.0, 508)
		l.size = Vector2(120, 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		stage.add_child(l)
