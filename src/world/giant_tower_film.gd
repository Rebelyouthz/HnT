class_name GiantTowerFilm
extends CanvasLayer

## The Harbour Clock: an Assassin's Creed perch, 100+ metres. Runs over the
## paused level in its own canvas layer.
##   1. CLIMB  - every hold is a timing ring on a random button. Perfect is a
##               fast free-climb, good/late climb slower, a miss slips you
##               down, a big miss drops you to the last ledge and costs grip.
##               Height counter + grip meter; wind and clouds as you rise.
##   2. SUMMIT - they sit on the balcony edge, legs over the city, and talk;
##               choices branch the conversation (data/towers.json talks).
##   3. DOWN   - pick a way down: leap of faith into the hay cart, the
##               dumpster or the canal, the zipline, or slide the ladder.
##               A last ring near the bottom grades the landing.
## finished(result) when the screen is back on the street.

signal finished(result: Dictionary)

const U_PER_M := 24.4
const TEXEL := 2.0 / 3.0
const ZOOM := 1.5
const TOWER_W := 120.0

var map_id := "dock_street"
var _row := {}
var _talk := {}
var _height := 3200.0
var _holds := 12
var _world: Node2D
var _cam := Vector2.ZERO
var _cam_zoom := ZOOM
var _ui: Control
var _sky: TextureRect
var _vista: TextureRect
var _dad: Node2D
var _kid: Node2D
var _talker: Talk
var _hud_m: Label
var _hud_bar: ProgressBar
var _grip_box: HBoxContainer
var _grip := 5
var _score := 0
var _perfects := 0
var _clouds: Array[Node2D] = []
var _wind: CPUParticles2D
var _t := 0.0
var _result := {}
## Where the painted tower's iron ladder and clock balcony are (texels in
## top.png / mid.png, from the slicing), in world units after placement.
const LADDER_X := -40.0
var _balcony_y := 0.0
const BALCONY_TEXEL_Y := 262.0
const BALCONY_X := Vector2(-66.0, -14.0)


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_row = TowerBook.map_row(map_id)
	_talk = TowerBook.talk(str(_row.get("film", "wharf_first")))
	_height = float(_row.get("height_m", 132)) * U_PER_M
	_holds = int(_row.get("holds", 12))
	_build_sky()
	_world = Node2D.new()
	add_child(_world)
	_build_tower()
	_build_city()
	_dad = _actor("father", Vector2(LADDER_X - 30.0, 0))
	_kid = _actor("son", Vector2(LADDER_X - 50.0, 0))
	_build_ui()
	_talker = Talk.new()
	add_child(_talker)
	# Above the film's sky / world / HUD layers.
	_talker.layer = 46
	_cam = Vector2(0, -90)
	Mixer.play_music("res://assets/audio/music_summit.wav")
	_run()


# --- set ----------------------------------------------------------------------

func _build_sky() -> void:
	var back := CanvasLayer.new()
	back.layer = 39
	add_child(back)
	var root := PixelStage.attach_canvas(back)
	_sky = TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.09))
	g.set_color(1, Color(0.16, 0.12, 0.24))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	_sky.texture = gt
	_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky.size = Vector2(1280, 720)
	root.add_child(_sky)
	for i in 60:
		var star := ColorRect.new()
		star.color = Color(0.9, 0.92, 1.0, randf_range(0.3, 0.9))
		star.size = Vector2(2, 2) * float(1 + int(randf() < 0.2))
		star.position = Vector2(randf() * 1280.0, randf() * 420.0)
		root.add_child(star)
	_vista = TextureRect.new()
	var vp := "res://assets/ui/tower/vista.png"
	if ResourceLoader.exists(vp):
		_vista.texture = load(vp)
	_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vista.size = Vector2(1280, 720)
	_vista.modulate.a = 0.0
	root.add_child(_vista)


func _tex(name: String) -> Texture2D:
	var p := "res://assets/ui/tower/%s.png" % name
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


## Base, a repeated middle band, and the crown (clock, balcony, spire), all
## from the painted tower, stacked to the real height.
func _build_tower() -> void:
	var base := _tex("base")
	var mid := _tex("mid")
	var top := _tex("top")
	var y := 0.0
	if base == null or mid == null or top == null:
		_balcony_y = -_height
		var body := Polygon2D.new()
		body.color = Color(0.32, 0.16, 0.12)
		body.polygon = PackedVector2Array([Vector2(-TOWER_W * 0.5, 0), Vector2(TOWER_W * 0.5, 0), Vector2(TOWER_W * 0.4, -_height), Vector2(-TOWER_W * 0.4, -_height)])
		_world.add_child(body)
		return
	y = _stack(base, y)
	while y > -_height + float(top.get_height()) * TEXEL:
		y = _stack(mid, y)
	var top_h := float(top.get_height()) * TEXEL
	_stack(top, y)
	_balcony_y = y - top_h + BALCONY_TEXEL_Y * TEXEL
	_height = -_balcony_y


func _stack(tex: Texture2D, y: float) -> float:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(TEXEL, TEXEL)
	var h := float(tex.get_height()) * TEXEL
	s.position = Vector2(-float(tex.get_width()) * TEXEL * 0.5, y - h)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_world.add_child(s)
	return y - h + 1.0


func _build_city() -> void:
	# The wharf at the foot of the tower, so the street falls away below.
	if ResourceLoader.exists("res://assets/backdrops/dock.png"):
		var tex := load("res://assets/backdrops/dock.png") as Texture2D
		for i in [-1, 0, 1]:
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.scale = Vector2(4.0 / 3.0, 4.0 / 3.0)
			var w := float(tex.get_width()) * 4.0 / 3.0
			s.position = Vector2(-w * 0.5 + float(i) * w, -float(tex.get_height()) * 4.0 / 3.0 + 60.0)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.z_index = -2
			_world.add_child(s)
	var street := Polygon2D.new()
	street.color = Color(0.07, 0.07, 0.1)
	street.polygon = PackedVector2Array([Vector2(-1400, 0), Vector2(1400, 0), Vector2(1400, 300), Vector2(-1400, 300)])
	street.z_index = -1
	_world.add_child(street)
	for i in 14:
		var c := Polygon2D.new()
		var pts := PackedVector2Array()
		var w := randf_range(80.0, 180.0)
		for k in 14:
			var a := TAU * float(k) / 14.0
			pts.append(Vector2(cos(a) * w, sin(a) * w * 0.28))
		c.polygon = pts
		c.color = Color(0.62, 0.66, 0.8, randf_range(0.08, 0.16))
		c.position = Vector2(randf_range(-500, 500), -randf_range(500.0, _height - 300.0))
		c.z_index = 5
		_world.add_child(c)
		_clouds.append(c)
	_wind = CPUParticles2D.new()
	_wind.amount = 50
	_wind.lifetime = 1.6
	_wind.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_wind.emission_rect_extents = Vector2(10, 160)
	_wind.direction = Vector2(1, 0.05)
	_wind.spread = 6.0
	_wind.gravity = Vector2.ZERO
	_wind.initial_velocity_min = 260.0
	_wind.initial_velocity_max = 420.0
	_wind.scale_amount_min = 1.0
	_wind.scale_amount_max = 3.0
	_wind.color = Color(0.85, 0.9, 1.0, 0.25)
	_wind.z_index = 6
	_wind.emitting = true
	_world.add_child(_wind)


func _actor(who: String, at: Vector2) -> Node2D:
	var a := Node2D.new()
	a.set_meta("film", true)
	a.set_script(preload("res://src/world/film_actor.gd"))
	a.set("role", who)
	a.position = at
	a.add_to_group("players")
	_world.add_child(a)
	a.z_index = 4
	a.call("build")
	return a


func _build_ui() -> void:
	var top := CanvasLayer.new()
	top.layer = 41
	top.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(top)
	_ui = PixelStage.attach_canvas(top)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := PanelContainer.new()
	box.name = "HeightBox"
	box.add_theme_stylebox_override("panel", UiKit.frame(UiKit.GOLD, 0.25))
	box.position = Vector2(28, 140)
	_ui.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	box.add_child(col)
	var name_l := UiKit.title(str(_row.get("label", "TOWER")), 16, Palette.EDGE)
	col.add_child(name_l)
	_hud_m = UiKit.title("0 M", 40, Palette.TEXT)
	col.add_child(_hud_m)
	_hud_bar = UiKit.glow_bar(0.0, UiKit.GOLD, Vector2(180, 12))
	col.add_child(_hud_bar)
	var gl := Label.new()
	gl.text = "GRIP"
	gl.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(gl, 13, Palette.MUTED)
	col.add_child(gl)
	_grip_box = HBoxContainer.new()
	_grip_box.add_theme_constant_override("separation", 4)
	col.add_child(_grip_box)
	_paint_grip()


func _paint_grip() -> void:
	for c in _grip_box.get_children():
		c.queue_free()
	for i in 5:
		var h := PixelIcon.new()
		h.kind = "fist"
		h.dim = i >= _grip
		h.custom_minimum_size = Vector2(26, 26)
		_grip_box.add_child(h)


# --- camera -----------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	var view := Vector2(320.0, 180.0)
	_world.scale = Vector2(_cam_zoom, _cam_zoom)
	_world.position = (view - _cam * _cam_zoom).round()
	_wind.position = Vector2(_cam.x - 230.0, _cam.y)
	for c in _clouds:
		c.position.x += delta * 14.0
		if c.position.x > 700.0:
			c.position.x = -700.0
	var h := clampf(-_cam.y / _height, 0.0, 1.0)
	_sky.modulate = Color(1, 1, 1).lerp(Color(0.8, 0.85, 1.15), h)


func _cam_to(p: Vector2, dur: float, zoom := -1.0) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam", p, dur)
	if zoom > 0.0:
		tw.parallel().tween_property(self, "_cam_zoom", zoom, dur)
	await tw.finished


func _set_height(y: float) -> void:
	var m := int(round(-y / U_PER_M))
	_hud_m.text = "%d M" % maxi(0, m)
	_hud_bar.value = clampf(-y / _height, 0.0, 1.0)


# --- flow -------------------------------------------------------------------

func _run() -> void:
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1280, 720)
	_ui.add_child(fade)
	fade.create_tween().tween_property(fade, "color:a", 0.0, 0.6)
	await get_tree().create_timer(0.5).timeout
	_talker.play([{"who": "son", "text": "How high does that go?"}, {"who": "father", "text": "Only one way to find out. Hands, feet, timing. Don't look down."}], true)
	await _talker.closed
	await _climb()
	await _summit()
	await _descend()
	finished.emit(_result)
	queue_free()


func _climb() -> void:
	var seg := (_height - 20.0) / float(_holds)
	var y := 0.0
	var ledge_y := 0.0
	var acts := ["jump", "light", "up", "heavy"]
	var i := 0
	while i < _holds:
		var act: String = acts[randi() % acts.size()]
		var lead := lerpf(0.95, 0.62, float(i) / float(maxi(1, _holds - 1)))
		var ring := TimingRing.spawn(self, act, _dad, lead, "HOLD %d / %d" % [i + 1, _holds])
		ring.layer = 73
		_dad.call("reach", true)
		var grade: String = await ring.resolved
		match grade:
			"perfect", "good", "ok":
				var dur := 0.38 if grade == "perfect" else (0.55 if grade == "good" else 0.75)
				y -= seg
				_score += 30 if grade == "perfect" else (18 if grade == "good" else 8)
				if grade == "perfect":
					_perfects += 1
				_dad.call("climb_to", Vector2(LADDER_X, y), dur)
				_kid.call("climb_to", Vector2(LADDER_X + 14.0, y + seg * 0.55), dur * 1.15)
				Juice.play("res://assets/audio/cling_ok.wav")
				await _cam_to(Vector2(LADDER_X * 0.5, y - 40.0), dur)
				_set_height(y)
				i += 1
				if i % 4 == 0 and i < _holds:
					ledge_y = y
					Juice.toast("reward", "LEDGE", "%d M  ·  catch your breath" % int(-y / U_PER_M))
			"miss":
				_grip -= 1
				_paint_grip()
				_dad.call("slip", Vector2(LADDER_X, y + seg * 0.4))
				await _cam_to(Vector2(0, y + seg * 0.4 - 40.0), 0.25)
				_dad.call("climb_to", Vector2(LADDER_X, y), 0.4)
				await _cam_to(Vector2(0, y - 40.0), 0.4)
			_:
				_grip -= 2
				_paint_grip()
				Juice.named_slowmo()
				_dad.call("climb_to", Vector2(LADDER_X, ledge_y), 0.6)
				_kid.call("climb_to", Vector2(LADDER_X + 14.0, ledge_y + 30.0), 0.7)
				await _cam_to(Vector2(0, ledge_y - 40.0), 0.6)
				i = int(round(-ledge_y / seg))
				y = ledge_y
				_set_height(y)
				Juice.toast("challenge", "FELL TO THE LEDGE", "Grip -2. The tower doesn't care. Go again.")
		if _grip <= 0:
			_grip = 3
			_paint_grip()
			_talker.play([{"who": "father", "text": "Arms are jelly. Breathe. Again."}], true)
	_result["perfects"] = _perfects
	_result["score"] = _score


func _summit() -> void:
	var top_y := _balcony_y
	_dad.call("sit_at", Vector2(BALCONY_X.x + 10.0, top_y))
	_kid.call("sit_at", Vector2(BALCONY_X.x + 34.0, top_y))
	# The painted balcony railing is already in the art; they sit on its
	# edge with their legs over the city.
	Juice.unlock_logo("SYNCHRONISED", "%d metres. The whole city owes someone something." % int(_height / U_PER_M), str(_row.get("label", "TOWER")))
	FamilyProfile.note_tower()
	var vt := create_tween()
	vt.tween_property(_vista, "modulate:a", 1.0, 1.6)
	var hb := _ui.get_node_or_null("HeightBox") as Control
	if hb:
		hb.create_tween().tween_property(hb, "modulate:a", 0.0, 1.0).set_delay(2.0)
	await _cam_to(Vector2(BALCONY_X.x + 30.0, top_y - 30.0), 1.6, 1.0)
	await get_tree().create_timer(2.2).timeout
	# Then close in on the two of them on the edge.
	await _cam_to(Vector2(BALCONY_X.x + 26.0, top_y - 22.0), 1.4, 2.6)
	for beat: Dictionary in _talk.get("beats", []):
		if beat.has("lines"):
			_talker.play(beat["lines"], true)
			await _talker.closed
		elif beat.has("choice"):
			var pick: Dictionary = await _choose(str(beat["choice"]), beat.get("options", []))
			_result["choice_%d" % _result.size()] = str(pick.get("label", ""))
			_talker.play(pick.get("lines", []), true)
			await _talker.closed
	vt = create_tween()
	vt.tween_property(_vista, "modulate:a", 0.0, 0.6)


## Pixel choice cards under the conversation; LEFT/RIGHT + JUMP/ENTER, or
## click. Returns the picked option.
func _choose(prompt: String, options: Array) -> Dictionary:
	var box := VBoxContainer.new()
	box.position = Vector2(40, 520)
	box.size = Vector2(1200, 160)
	box.add_theme_constant_override("separation", 10)
	_ui.add_child(box)
	var q := UiKit.title(prompt, 24, Palette.EDGE)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var picked: Array = []
	for o: Dictionary in options:
		var w := 290.0 if options.size() <= 3 else 190.0
		var b := UiKit.button(str(o.get("label", "...")), Vector2(w, 60))
		b.add_theme_font_size_override("font_size", 18 if options.size() <= 3 else 14)
		b.process_mode = Node.PROCESS_MODE_ALWAYS
		b.pressed.connect(func() -> void:
			if picked.is_empty():
				picked.append(o)
		)
		row.add_child(b)
	(row.get_child(0) as Button).grab_focus()
	UiKit.pop_in(box)
	var waited := 0.0
	while picked.is_empty():
		waited += get_process_delta_time()
		if TimingRing.autoplay and waited > 1.2:
			picked.append(options[0])
			break
		var focus := get_viewport().gui_get_focus_owner()
		var idx := row.get_children().find(focus)
		if idx < 0:
			idx = 0
		if Input.is_action_just_pressed("p1_right") or Input.is_action_just_pressed("p2_right"):
			(row.get_child(mini(idx + 1, row.get_child_count() - 1)) as Button).grab_focus()
		elif Input.is_action_just_pressed("p1_left") or Input.is_action_just_pressed("p2_left"):
			(row.get_child(maxi(idx - 1, 0)) as Button).grab_focus()
		elif Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p1_light") or Input.is_action_just_pressed("p2_jump"):
			picked.append(options[idx])
		await get_tree().process_frame
	Juice.play("res://assets/audio/ui_click.wav")
	box.queue_free()
	return picked[0]


const DESCENTS := [
	{"id": "hay", "label": "LEAP  ·  HAY CART", "icon": "haycart"},
	{"id": "dumpster", "label": "LEAP  ·  DUMPSTER", "icon": "dumpster"},
	{"id": "water", "label": "LEAP  ·  CANAL", "icon": ""},
	{"id": "zip", "label": "ZIPLINE", "icon": ""},
	{"id": "ladder", "label": "SLIDE THE LADDER", "icon": ""},
]


func _descend() -> void:
	var opts: Array = []
	for d: Dictionary in DESCENTS:
		opts.append({"label": d["label"], "id": d["id"]})
	var pick: Dictionary = await _choose("HOW DO WE GET DOWN?", opts)
	var id := str(pick.get("id", "hay"))
	_result["descent"] = id
	var top_y := _balcony_y
	_dad.call("stand_at", Vector2(BALCONY_X.x + 12.0, top_y))
	_kid.call("stand_at", Vector2(BALCONY_X.y - 10.0, top_y))
	await _cam_to(Vector2(BALCONY_X.x + 20.0, top_y - 40.0), 0.4, ZOOM)
	match id:
		"zip":
			await _zip(top_y)
		"ladder":
			await _ladder(top_y)
		_:
			await _leap(top_y, id)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(1280, 720)
	_ui.add_child(fade)
	var tw := fade.create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished


func _landing_prop(kind: String) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(150, 0)
	n.z_index = 3
	_world.add_child(n)
	var tex := _tex(kind) if kind != "water" else null
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var k := 70.0 / float(tex.get_width())
		s.scale = Vector2(k, k)
		s.position = Vector2(-35.0, -float(tex.get_height()) * k + 4.0)
		s.texture_filter = SpriteBook.UI_FILTER
		n.add_child(s)
	else:
		var w := Polygon2D.new()
		w.color = Color(0.1, 0.25, 0.45, 0.95)
		w.polygon = PackedVector2Array([Vector2(-90, -2), Vector2(90, -2), Vector2(90, 40), Vector2(-90, 40)])
		n.add_child(w)
		var shine := Polygon2D.new()
		shine.color = Color(0.5, 0.75, 1.0, 0.6)
		shine.polygon = PackedVector2Array([Vector2(-90, -2), Vector2(90, -2), Vector2(90, 0), Vector2(-90, 0)])
		n.add_child(shine)
	return n


## Leap of faith: swan dive off the balcony, the city rushes up, a last ring
## for the landing, and a burst of hay / bags / water.
func _leap(top_y: float, kind: String) -> void:
	var prop := _landing_prop("haycart" if kind == "hay" else ("dumpster" if kind == "dumpster" else "water"))
	_talker.play([{"who": "father", "text": "Trust me. Arms out."}], true)
	await get_tree().create_timer(1.2).timeout
	_talker._close()
	Juice.play("res://assets/audio/wind.wav")
	_dad.call("dive_pose")
	_kid.call("dive_pose")
	var land := Vector2(prop.position.x - 6.0, -8.0)
	var dur := 2.4
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_dad, "position", land, dur)
	tw.tween_property(_kid, "position", land + Vector2(14, 0), dur + 0.25)
	tw.tween_property(self, "_cam", Vector2(land.x * 0.7, land.y - 60.0), dur)
	await get_tree().create_timer(dur - 0.55).timeout
	var ring := TimingRing.spawn(self, "dash", _dad, 0.45, "LAND")
	ring.layer = 73
	var grade: String = await ring.resolved
	await tw.finished
	_result["landing"] = grade
	var col := Color(0.95, 0.8, 0.35) if kind == "hay" else (Color(0.15, 0.15, 0.18) if kind == "dumpster" else Color(0.6, 0.8, 1.0))
	_burst(land + Vector2(0, -10), col, 40)
	Juice.play("res://assets/audio/splash.wav" if kind == "water" else "res://assets/audio/smash.wav")
	Juice.pulse_shake(9.0 if TimingRing.is_success(grade) else 14.0)
	_dad.call("stand_at", land + Vector2(-20, 8))
	_kid.call("stand_at", land + Vector2(20, 8))
	await get_tree().create_timer(0.8).timeout


func _zip(top_y: float) -> void:
	var far := Vector2(700, -260)
	var wire := Line2D.new()
	wire.points = PackedVector2Array([Vector2(BALCONY_X.y, top_y - 30), far])
	wire.width = 1.6
	wire.default_color = Color(0.75, 0.75, 0.8)
	wire.z_index = 7
	_world.add_child(wire)
	_talker.play([{"who": "son", "text": "Is that a washing line?"}, {"who": "father", "text": "It's a zipline if you believe."}], true)
	await _talker.closed
	Juice.play("res://assets/audio/zip.wav")
	_dad.call("hang_pose")
	_kid.call("hang_pose")
	var dur := 2.6
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_dad, "position", far + Vector2(-10, 40), dur)
	tw.tween_property(_kid, "position", far + Vector2(-30, 40), dur + 0.3)
	tw.tween_property(self, "_cam", far + Vector2(-40, 20), dur)
	await get_tree().create_timer(dur - 0.5).timeout
	var ring := TimingRing.spawn(self, "jump", _dad, 0.45, "LET GO")
	ring.layer = 73
	_result["landing"] = await ring.resolved
	await tw.finished
	_burst(far + Vector2(0, 40), Color(1.0, 0.85, 0.4), 18)
	_dad.call("stand_at", far + Vector2(-20, 60))
	_kid.call("stand_at", far + Vector2(10, 60))
	await get_tree().create_timer(0.6).timeout


func _ladder(top_y: float) -> void:
	_talker.play([{"who": "father", "text": "Hands loose, feet on the rails. Slide."}], true)
	await _talker.closed
	_dad.call("hang_pose")
	_kid.call("hang_pose")
	var dur := 3.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_dad.position = Vector2(LADDER_X, top_y)
	_kid.position = Vector2(LADDER_X + 14.0, top_y - 30.0)
	tw.tween_property(_dad, "position", Vector2(LADDER_X, -6), dur)
	tw.tween_property(_kid, "position", Vector2(LADDER_X + 14.0, -6), dur + 0.3)
	tw.tween_property(self, "_cam", Vector2(0, -60), dur)
	for k in 10:
		get_tree().create_timer(0.25 * float(k)).timeout.connect(func() -> void:
			_burst(_dad.position + Vector2(0, -30), Color(1.0, 0.7, 0.3), 5)
		)
	await get_tree().create_timer(dur - 0.5).timeout
	var ring := TimingRing.spawn(self, "dash", _dad, 0.45, "LAND")
	ring.layer = 73
	_result["landing"] = await ring.resolved
	await tw.finished
	_dad.call("stand_at", Vector2(-24, 0))
	_kid.call("stand_at", Vector2(20, 0))
	await get_tree().create_timer(0.5).timeout


func _burst(at: Vector2, col: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = col
	p.z_index = 10
	p.emitting = true
	_world.add_child(p)
