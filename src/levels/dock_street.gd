extends Node2D

func _ready() -> void:
	_world()
	var son := Fighter.new()
	son.role = "son"
	son.prefix = &"p1_"
	son.max_hp = 92
	son.speed = 230.0
	son.accent = Palette.LEMON
	son.global_position = Vector2(220, 490)
	son.add_to_group("players")
	add_child(son)

	var dad := Fighter.new()
	dad.role = "father"
	dad.prefix = &"p2_"
	dad.max_hp = 118
	dad.speed = 180.0
	dad.accent = Palette.BRICK
	dad.global_position = Vector2(300, 500)
	dad.add_to_group("players")
	add_child(dad)

	var punk := Punk.new()
	punk.global_position = Vector2(720, 500)
	add_child(punk)

	var cam := CouchCamera.new()
	cam.targets = [son, dad]
	add_child(cam)

	var hud_script := preload("res://src/ui/run_hud.gd")
	var hud: CanvasLayer = hud_script.new()
	add_child(hud)
	hud.bind(son, dad)

	if DisplayServer.is_touchscreen_available():
		add_child(preload("res://src/ui/touch_hud.gd").new())


func _world() -> void:
	var sky := Polygon2D.new()
	sky.color = Color(0.08, 0.09, 0.14)
	sky.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3200, 0), Vector2(3200, 720), Vector2(0, 720)])
	add_child(sky)
	var far := Polygon2D.new()
	far.color = Color(0.12, 0.13, 0.2)
	far.polygon = PackedVector2Array([Vector2(0, 180), Vector2(3200, 220), Vector2(3200, 720), Vector2(0, 720)])
	add_child(far)
	var mid := Polygon2D.new()
	mid.color = Color(0.16, 0.1, 0.12)
	mid.polygon = PackedVector2Array([Vector2(0, 300), Vector2(3200, 280), Vector2(3200, 720), Vector2(0, 720)])
	add_child(mid)
	var street := Polygon2D.new()
	street.color = Color(0.11, 0.11, 0.13)
	street.polygon = PackedVector2Array([Vector2(0, 430), Vector2(3200, 430), Vector2(3200, 720), Vector2(0, 720)])
	add_child(street)
	var wet := Polygon2D.new()
	wet.color = Color(0.18, 0.2, 0.28, 0.35)
	wet.polygon = PackedVector2Array([Vector2(0, 520), Vector2(3200, 520), Vector2(3200, 620), Vector2(0, 620)])
	add_child(wet)
	var lamp := Polygon2D.new()
	lamp.color = Color(0.9, 0.75, 0.35, 0.25)
	lamp.polygon = PackedVector2Array([Vector2(400, 120), Vector2(520, 120), Vector2(560, 430), Vector2(360, 430)])
	add_child(lamp)
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 80)
	cs.shape = rect
	cs.position = Vector2(1600, 600)
	floor.add_child(cs)
	add_child(floor)
	var wall_l := StaticBody2D.new()
	var wl := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(40, 800)
	wl.shape = wr
	wl.position = Vector2(-20, 360)
	wall_l.add_child(wl)
	add_child(wall_l)
	var sign := Label.new()
	sign.text = "DOCK STREET  ·  24/7 BLOOD MART"
	sign.position = Vector2(140, 150)
	UiKit.apply_label(sign, 22, Palette.EDGE)
	add_child(sign)
	var neon := Label.new()
	neon.text = "HIRING  ·  WE LIE ABOUT THAT"
	neon.position = Vector2(980, 200)
	UiKit.apply_label(neon, 18, Palette.BRICK)
	add_child(neon)
