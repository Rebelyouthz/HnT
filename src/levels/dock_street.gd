extends Node2D

const MAP_W := 3200.0
const ROOF_Y := 248.0

var _son: Fighter
var _dad: Fighter
var _state: RunState
var _hud: CanvasLayer
var _end: Control


func _ready() -> void:
	add_to_group("dock_world")
	_state = RunState.new()
	_state.add_to_group("run_state")
	_state.checkpoint = Vector2(220, 490)
	_state.run_failed.connect(_on_fail)
	_state.run_cleared.connect(_on_clear)
	add_child(_state)
	_world()
	add_child(LightRig.new())
	add_child(SnapDirector.new())

	_son = Fighter.new()
	_son.role = "son"
	_son.prefix = &"p1_"
	_son.max_hp = 92
	_son.speed = 230.0
	_son.accent = Palette.LEMON
	_son.global_position = Vector2(220, 490)
	_son.add_to_group("players")
	add_child(_son)

	_dad = Fighter.new()
	_dad.role = "father"
	_dad.prefix = &"p2_"
	_dad.max_hp = 118
	_dad.speed = 180.0
	_dad.accent = Palette.BRICK
	_dad.global_position = Vector2(300, 500)
	_dad.add_to_group("players")
	add_child(_dad)

	_spawn_punk("Bag Snatch", Vector2(800, 500), "street", 40, 720, 980)
	_spawn_punk("Bag Snatch", Vector2(1120, 500), "street", 40, 1000, 1280)
	_spawn_punk("Roof Runner", Vector2(1620, 248), "roof", 36, 1480, 1880)
	_spawn_punk("Mohawk Bo", Vector2(2240, 500), "street", 70, 2040, 2480)
	_spawn_punk("Bag Snatch", Vector2(2720, 500), "street", 40, 2560, 2920)

	var cam := CouchCamera.new()
	cam.targets = [_son, _dad]
	add_child(cam)

	var hud_script := preload("res://src/ui/run_hud.gd")
	_hud = hud_script.new()
	add_child(_hud)
	_hud.bind(_son, _dad, _state)

	if DisplayServer.is_touchscreen_available():
		add_child(preload("res://src/ui/touch_hud.gd").new())


func _process(_delta: float) -> void:
	if _state.failed or _state.cleared:
		return
	if _son.global_position.x > 2920.0:
		_state.mark_checkpoint(Vector2(2920, 490))
	if _son.global_position.x > 3000.0 and _dad.global_position.x > 3000.0:
		_state.clear_run()


func _spawn_punk(title: String, at: Vector2, home: String, hp: int, pmin: float, pmax: float) -> void:
	var p := Punk.new()
	p.title = title
	p.home = home
	p.hp = hp
	p.patrol_min = pmin
	p.patrol_max = pmax
	p.speed = 34.0 if title == "Mohawk Bo" else 48.0
	p.global_position = at
	add_child(p)


func _world() -> void:
	var sky := Blockout.poly(self, Rect2(0, 0, MAP_W, 720), Color(0.07, 0.08, 0.13), -8)
	sky.z_index = -8
	_parallax()

	Blockout.poly(self, Rect2(0, 430, MAP_W, 290), Color(0.10, 0.10, 0.12), 0)
	var wet := Blockout.poly(self, Rect2(0, 520, MAP_W, 90), Color(0.18, 0.2, 0.28, 0.38), 1)
	wet.z_index = 1
	wet.uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = preload("res://src/shaders/wet_asphalt.gdshader")
	wet.material = wet_mat

	_tenement(Rect2(80, 160, 220, 280), Color(0.14, 0.1, 0.12))
	_tenement(Rect2(420, 90, 260, 160), Color(0.16, 0.11, 0.13))
	_tenement(Rect2(860, 70, 300, 180), Color(0.13, 0.1, 0.14))
	_tenement(Rect2(1480, 60, 340, 190), Color(0.15, 0.1, 0.12))
	_tenement(Rect2(2480, 80, 280, 170), Color(0.14, 0.11, 0.13))
	_tenement(Rect2(2920, 140, 220, 290), Color(0.12, 0.16, 0.14))

	Blockout.solid(self, Rect2(400, ROOF_Y, 840, 22), true)
	Blockout.poly(self, Rect2(400, ROOF_Y, 840, 22), Color(0.22, 0.18, 0.2), 2)
	Blockout.solid(self, Rect2(1420, ROOF_Y, 580, 22), true)
	Blockout.poly(self, Rect2(1420, ROOF_Y, 580, 22), Color(0.22, 0.18, 0.2), 2)
	Blockout.solid(self, Rect2(2480, ROOF_Y, 440, 22), true)
	Blockout.poly(self, Rect2(2480, ROOF_Y, 440, 22), Color(0.22, 0.18, 0.2), 2)

	var wall := Blockout.solid(self, Rect2(1234, 140, 18, 110), false)
	wall.add_to_group("metal")
	Blockout.poly(self, Rect2(1234, 140, 18, 110), Color(0.3, 0.22, 0.2), 3)

	_fire_escape(480.0)
	_fire_escape(1920.0)
	_fire_escape(2520.0)

	var c1 := VaultCrate.new()
	c1.global_position = Vector2(640, 500)
	add_child(c1)
	var c2 := VaultCrate.new()
	c2.global_position = Vector2(2320, 500)
	add_child(c2)

	_anchor(Vector2(640, 88))
	_anchor(Vector2(1320, 64))
	_anchor(Vector2(1760, 84))
	_anchor(Vector2(2680, 90))

	var floor := Blockout.solid(self, Rect2(-40, 600, 3400, 80), false)
	floor.collision_layer = 1
	var wall_l := Blockout.solid(self, Rect2(-40, 0, 40, 720), false)
	var wall_r := Blockout.solid(self, Rect2(MAP_W, 0, 40, 720), false)
	wall_l.collision_layer = 1
	wall_r.collision_layer = 1

	var sign := Label.new()
	sign.text = "DOCK STREET  ·  RAVEN WHARF"
	sign.position = Vector2(140, 150)
	UiKit.apply_label(sign, 22, Palette.EDGE)
	add_child(sign)
	var neon := Label.new()
	neon.text = "HIRING  ·  WE LIE ABOUT THAT"
	neon.position = Vector2(900, 178)
	UiKit.apply_label(neon, 18, Palette.BRICK)
	add_child(neon)
	Blockout.add_glow(neon)
	var mart := Label.new()
	mart.text = "24/7 BLOOD MART"
	mart.position = Vector2(2940, 168)
	UiKit.apply_label(mart, 20, Palette.READY)
	add_child(mart)
	var gap := Label.new()
	gap.text = "GAP  ·  GLIDE OR WEB"
	gap.position = Vector2(1258, 210)
	UiKit.apply_label(gap, 14, Palette.MUTED)
	add_child(gap)

	_rain()


func _parallax() -> void:
	var pb := ParallaxBackground.new()
	add_child(pb)
	var moon_l := ParallaxLayer.new()
	moon_l.motion_scale = Vector2(0.05, 0.04)
	pb.add_child(moon_l)
	var moon := Polygon2D.new()
	moon.color = Color(0.78, 0.82, 0.92, 0.85)
	moon.polygon = PackedVector2Array([
		Vector2(980, 40), Vector2(1040, 40), Vector2(1040, 100), Vector2(980, 100)
	])
	moon_l.add_child(moon)
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.15, 0.08)
	pb.add_child(far)
	Blockout.poly(far, Rect2(0, 200, MAP_W, 400), Color(0.11, 0.12, 0.18), -6)
	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.35, 0.12)
	pb.add_child(mid)
	Blockout.poly(mid, Rect2(0, 260, MAP_W, 360), Color(0.15, 0.1, 0.12), -4)


func _tenement(rect: Rect2, color: Color) -> void:
	Blockout.poly(self, rect, color, -1)
	Blockout.occluder(self, rect)
	var win_y := rect.position.y + 24.0
	while win_y < rect.end.y - 40.0:
		var win_x := rect.position.x + 18.0
		while win_x < rect.end.x - 24.0:
			var lit := randf() > 0.45
			var w := Blockout.poly(self, Rect2(win_x, win_y, 14, 16), Color(0.9, 0.75, 0.35, 0.7) if lit else Color(0.08, 0.08, 0.1, 0.9), 0)
			if lit:
				Blockout.add_glow(w)
			win_x += 36.0
		win_y += 36.0


func _fire_escape(at_x: float) -> void:
	var fe := FireEscape.new()
	fe.configure(at_x, ROOF_Y, 500.0)
	add_child(fe)


func _anchor(at: Vector2) -> void:
	var a := WebAnchor.new()
	a.position = at
	add_child(a)


func _rain() -> void:
	var rain := CPUParticles2D.new()
	rain.position = Vector2(1600, -20)
	rain.amount = 70
	rain.lifetime = 1.3
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(1700, 8)
	rain.direction = Vector2(0.12, 1)
	rain.spread = 4.0
	rain.gravity = Vector2(0, 980)
	rain.initial_velocity_min = 220.0
	rain.initial_velocity_max = 320.0
	rain.color = Color(0.55, 0.62, 0.75, 0.35)
	rain.z_index = 12
	add_child(rain)


func _on_fail() -> void:
	_banner(Copy.FAIL, "The lives were shared. That was the joke.", false)


func _on_clear() -> void:
	FamilyProfile.add_gold(12)
	FamilyProfile.mark_run_finished()
	_banner(Copy.CLEAR, Copy.CLEAR_SUB, true)


func _banner(title: String, sub: String, win: bool) -> void:
	if _end and is_instance_valid(_end):
		return
	get_tree().paused = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_end = Control.new()
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_end)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(dim)
	var col := VBoxContainer.new()
	col.position = Vector2(360, 220)
	col.add_theme_constant_override("separation", 12)
	_end.add_child(col)
	var t := Label.new()
	t.text = title
	UiKit.apply_label(t, 32, Palette.LEMON if win else Palette.BRICK)
	col.add_child(t)
	var s := Label.new()
	s.text = sub
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(560, 0)
	UiKit.apply_label(s, 16, Palette.TEXT)
	col.add_child(s)
	var b := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(func() -> void:
		get_tree().paused = false
		App.back_to_hub("awards" if win else "clinic")
	)
	col.add_child(b)
	Juice.pulse_shake(8.0 if win else 5.0)
