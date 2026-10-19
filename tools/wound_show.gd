extends SceneTree

## Hurt-gait check: four thugs at low HP - LIMP (legs), CLUTCH (gut),
## DAZED (head), SCOOT (lost his nerve) - posed by WoundGait each frame.
##   ... --fixed-fps 60 --script res://tools/wound_show.gd -- /tmp/frames 120

var _out := "/tmp/claude-0/wounds"
var _n := 120
var _frame := 0
var _shot := 0
var _ps: Array = []
var _wg: GDScript


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	if a.size() > 1:
		_n = int(a[1])
	DirAccess.make_dir_recursive_absolute(_out)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_build()
		return false
	if _frame < 6:
		return false
	for p: Node2D in _ps:
		_wg.call("pose", p, 1.0 / 60.0)
	if _frame % 2 == 0:
		root.get_viewport().get_texture().get_image().save_png("%s/f_%05d.png" % [_out, _shot])
		_shot += 1
		if _shot >= _n:
			quit(0)
			return true
	return false


func _build() -> void:
	_wg = load("res://src/actors/wound_gait.gd")
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.16)
	bg.size = Vector2(640, 360)
	root.add_child(bg)
	var street := ColorRect.new()
	street.color = Color(0.2, 0.19, 0.24)
	street.position = Vector2(0, 250)
	street.size = Vector2(640, 110)
	root.add_child(street)
	var host := Node2D.new()
	root.add_child(host)
	var ps := load("res://src/actors/punk.gd")
	var cases := [["legs", false, 40.0, "LIMP"], ["gut", false, 30.0, "CLUTCH"], ["head", false, 25.0, "DAZED"], ["head", true, 30.0, "SCOOT"]]
	for i in cases.size():
		var p: Node2D = ps.new()
		p.set("hp", 100)
		p.position = Vector2(110.0 + float(i) * 140.0, 290.0)
		host.add_child(p)
		p.set_physics_process(false)
		p.set("hp", 10)
		p.set("_last_zone", str(cases[i][0]))
		if bool(cases[i][1]):
			p.set_meta("scoot", true)
		p.set("velocity", Vector2(float(cases[i][2]), 0))
		_ps.append(p)
		var l := Label.new()
		l.text = str(cases[i][3])
		l.position = Vector2(p.position.x - 40.0, 300.0)
		l.size = Vector2(80, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(l)
