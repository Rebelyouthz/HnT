extends Node2D

## Prologue: what happened before you play. Three nights ago in the hideout
## the Vale brothers show off what they built; Collector Gant knocks, calls
## the brothers collateral for the family's unpaid therapy and his goons drag
## them off; the lights die. Then the alley film and the tutorial.
## Staged on cue from data/story.json "prologue" via Talk.line.
## JUMP / ENTER next line, PAUSE skips to the alley.

class FilmActor extends Node2D:
	var role := ""
	var hop := 0.0
	var anim: AnimatedSprite2D

const WALK_Y := 500.0
const ZOOM := 2.5

var _talk: Talk
var _ui: Control
var _cam: Camera2D
var _mod: CanvasModulate
var _w := 900.0
var _room_h := 130.0
var _cx := 0.0
var _benny: CrewNPC
var _rico: CrewNPC
var _gant: FilmActor
var _goons: Array[FilmActor] = []
var _done := false


func _ready() -> void:
	_build_set()
	_build_ui()
	Mixer.play_music("res://assets/audio/music/music_menu.ogg")
	_talk = Talk.new()
	add_child(_talk)
	_talk.line.connect(_on_line)
	_talk.closed.connect(_finish)
	await get_tree().create_timer(1.4).timeout
	if not _done:
		var v: Variant = StoryBook.all().get("prologue", [])
		_talk.play(v if v is Array else [])


func _build_set() -> void:
	var bg := Polygon2D.new()
	bg.color = Color(0.02, 0.02, 0.035)
	bg.polygon = PackedVector2Array([Vector2(-400, 0), Vector2(4000, 0), Vector2(4000, 900), Vector2(-400, 900)])
	bg.z_index = -10
	add_child(bg)
	var path := "res://assets/backdrops/camp.png"
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/backdrops/camp.json"))
		var ground := float(tex.get_height()) * 0.93
		var texel := 2.0 / 3.0
		if meta is Dictionary:
			ground = float((meta as Dictionary).get("ground", ground))
			texel = float((meta as Dictionary).get("texel", texel))
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(texel, texel)
		s.position = Vector2(0, WALK_Y - ground * texel)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.z_index = -5
		add_child(s)
		_w = float(tex.get_width()) * texel
		_room_h = ground * texel
	# The lounge: couch at ~0.62 of the hideout.
	_cx = _w * 0.62
	_mod = CanvasModulate.new()
	_mod.color = Color(1, 0.97, 0.92)
	add_child(_mod)
	_actor("father", Vector2(_cx - 40.0, WALK_Y), 1)
	_actor("son", Vector2(_cx - 18.0, WALK_Y + 1.0), 1)
	_benny = _crew("benny", Vector2(_cx + 18.0, WALK_Y))
	_rico = _crew("rico", Vector2(_cx + 42.0, WALK_Y + 1.0))
	_cam = Camera2D.new()
	_cam.zoom = Vector2(ZOOM, ZOOM)
	_cam.position = Vector2(_cx + 4.0, WALK_Y - _room_h * 0.5 + 6.0)
	add_child(_cam)
	_cam.make_current()


func _actor(who: String, at: Vector2, face: int) -> FilmActor:
	var a := FilmActor.new()
	a.role = who
	a.position = at
	a.add_to_group("players")
	add_child(a)
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * float(i) / 16.0
		pts.append(Vector2(cos(ang) * 14.0, sin(ang) * 3.2))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.42)
	sh.position = Vector2(0, 2)
	a.add_child(sh)
	if SpriteBook.has_who(who):
		a.anim = SpriteBook.make_anim(who)
		a.anim.flip_h = face < 0
		a.anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		a.add_child(a.anim)
	return a


func _crew(who: String, at: Vector2) -> CrewNPC:
	var c := CrewNPC.new()
	c.setup(who)
	c.position = at
	c.face(-1)
	add_child(c)
	return c


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_ui = PixelStage.attach_canvas(layer)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for y in [0.0, 650.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(1280, 70)
		_ui.add_child(bar)
	var skip := Label.new()
	skip.position = Vector2(40, 22)
	skip.text = "JUMP  ·  NEXT LINE        PAUSE  ·  SKIP"
	UiKit.apply_label(skip, 13, Palette.MUTED)
	_ui.add_child(skip)
	var title := UiKit.title("THREE NIGHTS AGO", 26, Palette.EDGE)
	title.position = Vector2(900, 16)
	_ui.add_child(title)
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1280, 720)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fade)
	fade.create_tween().tween_property(fade, "color:a", 0.0, 1.2)


func _on_line(_i: int, row: Dictionary) -> void:
	var text := str(row.get("text", ""))
	if text.begins_with("A KNOCK"):
		# Three hard knocks; everyone turns to the door on the right.
		for k in 3:
			get_tree().create_timer(0.25 * float(k)).timeout.connect(func() -> void:
				Juice.play("res://assets/audio/smash.wav")
				Juice.pulse_shake(3.0)
			)
		_benny.face(1)
		_rico.face(1)
	elif str(row.get("who", "")) == "collector" and _gant == null:
		_enter_collectors()
	elif text.begins_with("THEY TOOK"):
		_drag_off()


func _enter_collectors() -> void:
	Juice.play("res://assets/audio/sting_intro.wav")
	var door_x := _cx + 150.0
	_gant = _actor("gant", Vector2(door_x, WALK_Y), -1)
	# Lines are written for "collector": that is who Talk looks for.
	_gant.role = "collector"
	for k in 2:
		var g := _actor("punk", Vector2(door_x + 24.0 + 16.0 * float(k), WALK_Y + 1.0), -1)
		g.remove_from_group("players")
		_goons.append(g)
	_tween_walk(_gant, _cx + 74.0, 0.9)
	_tween_walk(_goons[0], _cx + 96.0, 1.0)
	_tween_walk(_goons[1], _cx + 116.0, 1.1)
	var tw := create_tween()
	tw.tween_property(_cam, "position:x", _cx + 30.0, 1.0).set_trans(Tween.TRANS_SINE)


func _tween_walk(a: FilmActor, x: float, dur: float) -> void:
	if a.anim and a.anim.sprite_frames.has_animation("walk"):
		a.anim.play("walk")
	var tw := create_tween()
	tw.tween_property(a, "position:x", x, dur)
	tw.tween_callback(func() -> void:
		if a.anim and a.anim.sprite_frames.has_animation("idle"):
			a.anim.play("idle")
	)


func _drag_off() -> void:
	# Goons grab a brother each and haul them out the door; lights die.
	var exit_x := _cx + 260.0
	_benny.face(1)
	_rico.face(1)
	_benny.remove_from_group("players")
	_rico.remove_from_group("players")
	for pair in [[_goons[0], _benny], [_goons[1], _rico]]:
		var goon: FilmActor = pair[0]
		var bro: CrewNPC = pair[1]
		if goon.anim:
			goon.anim.flip_h = false
		var tw := create_tween().set_parallel(true)
		tw.tween_property(goon, "position:x", exit_x, 2.4).set_delay(0.2)
		tw.tween_property(bro, "position:x", exit_x - 14.0, 2.4).set_delay(0.35)
	if _gant.anim:
		_gant.anim.flip_h = false
	create_tween().tween_property(_gant, "position:x", exit_x + 20.0, 2.6).set_delay(0.8)
	var dim := create_tween()
	dim.tween_interval(1.6)
	for k in 3:
		dim.tween_property(_mod, "color", Color(0.25, 0.27, 0.38), 0.08)
		dim.tween_property(_mod, "color", Color(0.85, 0.82, 0.78), 0.1)
	dim.tween_property(_mod, "color", Color(0.3, 0.32, 0.45), 0.4)
	var back := create_tween()
	back.tween_property(_cam, "position:x", _cx - 20.0, 2.0).set_delay(1.6).set_trans(Tween.TRANS_SINE)


func _process(_delta: float) -> void:
	if not _done and (Input.is_action_just_pressed("p1_pause") or Input.is_action_just_pressed("p2_pause")):
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(1280, 720)
	_ui.add_child(fade)
	var tw := fade.create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func() -> void: App.enter_map("intro_flow"))
