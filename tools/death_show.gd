extends SceneTree

## Death variety film: two rows of thugs, each dropped by a different blow
## (DeathFall styles), then a second wave with the rest.
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1920x1080 --windowed --script res://tools/death_show.gd -- /tmp/frames 300
## Saves every second tick (30 fps) as f_00000.png ...

const WAVES := [
	[["timber", "JAB KO"], ["spin", "HOOK"], ["knockback", "DROPKICK"], ["launch", "UPPERCUT"], ["sweep", "SWEEP"], ["faceplant", "GUT"],
	 ["kneel", "MACHETE"], ["stagger", "PISTOL x2"], ["headshot", "HEADSHOT"], ["blown", "SHOTGUN"], ["legs", "LEG SHOT"], ["homerun", "BAT"]],
	[["topple", "CROSS"], ["crumple", "BODY SHOT"], ["blast", "GRENADE"], ["decap", "DECAP"], ["burn", "MOLOTOV"], ["drawn", "CLASSIC"],
	 ["spin", "ROUNDHOUSE"], ["knockback", "PIPE"], ["launch", "LAUNCHER"], ["timber", "SNAP"], ["stagger", "SMG"], ["faceplant", "KNEE"]],
]
const WHO := ["punk", "repo_goon", "bailiff", "mohawk", "cop", "valet"]

var _out := "/tmp/claude-0/deaths"
var _n := 300
var _frame := 0
var _shot := 0
var _t := 0.0
var _host: Node2D
var _ui: Control
var _wave := -1
var _alive: Array = []
var _labels: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	if a.size() > 1:
		_n = int(a[1])
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_build()
		return false
	if _frame < 6:
		return false
	_t += delta
	var w := 0 if _t < 5.0 else (1 if _t < 10.0 else 2)
	if w != _wave:
		_spawn(w)
	for a: Dictionary in _alive:
		if not bool(a["dead"]) and _t >= float(a["at"]):
			_kill(a)
	if _frame % 2 == 0:
		root.get_viewport().get_texture().get_image().save_png("%s/f_%05d.png" % [_out, _shot])
		_shot += 1
		if _shot >= _n:
			quit(0)
			return true
	return false


func _build() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backdrops/roofs_strip_0.png")
	bg.centered = false
	var k := 360.0 / float(bg.texture.get_height())
	bg.scale = Vector2(k, k)
	bg.position = Vector2(-300, 0)
	stage.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.55)
	shade.size = Vector2(640, 360)
	stage.add_child(shade)
	for y in [190.0, 330.0]:
		var street := ColorRect.new()
		street.color = Color(0.11, 0.1, 0.13)
		street.position = Vector2(0, y - 14.0)
		street.size = Vector2(640, 30)
		stage.add_child(street)
		var lip := ColorRect.new()
		lip.color = Color(0.3, 0.27, 0.32)
		lip.position = Vector2(0, y - 14.0)
		lip.size = Vector2(640, 2)
		stage.add_child(lip)
	_host = Node2D.new()
	_host.add_to_group("dock_world")
	stage.add_child(_host)
	var blood: Node2D = load("res://src/juice/blood.gd").new()
	_host.add_child(blood)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_ui = Control.new()
	_ui.size = Vector2(640, 360)
	layer.add_child(_ui)
	var title := _label("EVERY BLOW FALLS DIFFERENT", Vector2(0, 8), Vector2(640, 24), 18, Color(1.0, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(t: String, at: Vector2, size: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = at
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	var tf: Font = load("res://assets/fonts/PixelifySans.ttf")
	if tf:
		l.add_theme_font_override("font", tf)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	_ui.add_child(l)
	return l


func _spawn(w: int) -> void:
	_wave = w
	if w == 2:
		_street_wave()
		return
	for c in _host.get_children():
		if c.is_in_group("corpses") or c.has_meta("actor"):
			c.queue_free()
	for l in _labels:
		(l as Node).queue_free()
	_labels.clear()
	_alive.clear()
	var sb := load("res://src/sprites/sprite_book.gd")
	var list: Array = WAVES[w]
	for i in list.size():
		var row := i / 6
		var col := i % 6
		var feet := Vector2(46.0 + float(col) * 104.0, 190.0 if row == 0 else 330.0)
		var who := str(WHO[(i + w) % WHO.size()])
		if not bool(sb.call("has_who", who)):
			who = "punk"
		var holder := Node2D.new()
		holder.position = feet
		holder.set_meta("actor", true)
		_host.add_child(holder)
		var anim: AnimatedSprite2D = sb.call("make_anim", who)
		sb.call("grow", anim, float(sb.get("ENEMY_SCALE")) * 0.75)
		anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim.flip_h = true
		holder.add_child(anim)
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		_alive.append({"holder": holder, "anim": anim, "style": str(list[i][0]), "at": float(w) * 5.0 + 0.6 + float(col) * 0.22 + float(row) * 0.11, "dead": false, "feet": feet})
		_labels.append(_label(str(list[i][1]), Vector2(feet.x - 50.0, feet.y + 6.0), Vector2(100, 12), 9, Color(0.92, 0.9, 0.85)))


func _kill(a: Dictionary) -> void:
	a["dead"] = true
	var holder: Node2D = a["holder"]
	var anim: AnimatedSprite2D = a["anim"]
	var hr := load("res://src/juice/hit_react.gd")
	var style := str(a["style"])
	var feet: Vector2 = a["feet"]
	var blood := _host.get_tree().get_first_node_in_group("blood_sim")
	if blood:
		blood.call("burst", feet + Vector2(0, -50), feet.y, 1.0, {"n": 14, "speed": 260.0, "spread": 0.4, "rise": 0.2, "size": 1.1, "streak": true})
	var body: Node2D = hr.call("corpse", _host, anim, feet, "head", 1.0, -1, style)
	if style == "decap" and body != null:
		var art: CanvasItem = body.get_child(0).get_child(0)
		var m := art.material as ShaderMaterial
		if m:
			m.set_shader_parameter("cut_head", 1.0)
	holder.visible = false
	if _wave == 2 and style == "stagger":
		_wall_shots(feet)


## Wave 3: the street fights back - a lamp post, a parked car, a thug
## still standing to bowl over, and rounds that paint the wall.
func _street_wave() -> void:
	for c in _host.get_children():
		if c.is_in_group("corpses") or c.has_meta("actor") or c.is_in_group("wall_marks"):
			c.queue_free()
	for l in _labels:
		(l as Node).queue_free()
	_labels.clear()
	_alive.clear()
	var sb := load("res://src/sprites/sprite_book.gd")
	# Lamp post on the top row.
	var lamp := Node2D.new()
	lamp.position = Vector2(250, 190)
	lamp.set_meta("actor", true)
	lamp.add_to_group("street_lamps")
	lamp.set_meta("half_w", 6.0)
	var la: AnimatedSprite2D = sb.call("make_anim", "lamp")
	lamp.add_child(la)
	lamp.scale = Vector2(2.9, 2.9) * 0.75
	_host.add_child(lamp)
	# Parked car further along.
	var car := Node2D.new()
	car.position = Vector2(520, 196)
	car.set_meta("actor", true)
	car.add_to_group("slam_props")
	car.add_to_group("parked_cars")
	car.set_meta("half_w", 60.0)
	var ca: AnimatedSprite2D = sb.call("make_anim", "sedan")
	ca.position.y = -24.0
	car.add_child(ca)
	car.scale = Vector2(1.6, 1.6)
	_host.add_child(car)
	_labels.append(_label("INTO THE LAMP POST", Vector2(100, 202), Vector2(200, 12), 9, Color(0.92, 0.9, 0.85)))
	_labels.append(_label("INTO A PARKED CAR", Vector2(340, 202), Vector2(200, 12), 9, Color(0.92, 0.9, 0.85)))
	_labels.append(_label("BLOWN BACK, SKIDS", Vector2(170, 342), Vector2(200, 12), 9, Color(0.92, 0.9, 0.85)))
	_labels.append(_label("CLEAN THROUGH - THE WALL", Vector2(400, 342), Vector2(220, 12), 9, Color(0.92, 0.9, 0.85)))
	var plan := [[Vector2(140, 190), "knockback", "punk", 10.4], [Vector2(380, 190), "knockback", "cop", 10.8], [Vector2(150, 330), "blown", "punk", 11.2], [Vector2(470, 330), "stagger", "cop", 11.6]]
	for pl in plan:
		var holder := Node2D.new()
		holder.position = pl[0]
		holder.set_meta("actor", true)
		_host.add_child(holder)
		var anim: AnimatedSprite2D = sb.call("make_anim", str(pl[2]))
		sb.call("grow", anim, float(sb.get("ENEMY_SCALE")) * 0.75)
		anim.flip_h = true
		holder.add_child(anim)
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		_alive.append({"holder": holder, "anim": anim, "style": str(pl[1]), "at": float(pl[3]), "dead": false, "feet": pl[0]})


func _wall_shots(feet: Vector2) -> void:
	var wm := load("res://src/juice/wall_mark.gd")
	for i in 3:
		wm.call("mark", _host, Vector2(feet.x + 40.0 + float(i) * 14.0, feet.y - 50.0 + float(i) * 9.0), 1.0, true)
