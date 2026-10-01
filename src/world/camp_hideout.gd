extends Node2D

## The hideout: a walkable home between maps. Every camp building and core
## room is a station on the floor (walk up, press UP / ENTER / LIGHT): it
## opens just that menu. The COMMAND BOARD opens the whole clinic hub, all
## menus in one place, exactly as before. The PORTAL takes you on: to the
## next map when you came through it mid-run, else into a new run.
## Layout lives in data/camp.json (station id + x on the painted rooms).

const WALK_Y := 500.0
const SPEED := 150.0
const REACH := 14.0
## Rooms are 2/3 u per texel; at 2.5x zoom on 1080p that is 5 screen px per
## texel (integer, crisp) and the room fills the frame top to bottom.
const ZOOM := 2.5

## Inner walker so Talk / SpeechBubble find it like a Fighter (role, hop).
class CampWalker extends Node2D:
	var role := "son"
	var hop := 0.0
	var anim: AnimatedSprite2D
	var facing := 1
	var walking := false

	func setup(who: String) -> void:
		role = who
		add_to_group("players")
		var sh := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * float(i) / 16.0
			pts.append(Vector2(cos(a) * 15.0, sin(a) * 3.5))
		sh.polygon = pts
		sh.color = Color(0, 0, 0, 0.42)
		sh.position = Vector2(0, 3)
		add_child(sh)
		if SpriteBook.has_who(who):
			anim = SpriteBook.make_anim(who)
			# Actors land at 1.67 px per texel here: filter, don't nearest.
			anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			add_child(anim)

	func set_motion(vx: float) -> void:
		if absf(vx) > 1.0:
			facing = 1 if vx > 0.0 else -1
		if anim == null:
			return
		anim.flip_h = facing < 0
		var clip := "walk" if absf(vx) > 1.0 else "idle"
		if clip == "walk" and absf(vx) > 200.0 and anim.sprite_frames.has_animation("parkour_run"):
			clip = "parkour_run"
		if anim.animation != clip and anim.sprite_frames.has_animation(clip):
			anim.play(clip)
		if clip == "walk":
			anim.speed_scale = clampf(absf(vx) / 80.0, 0.6, 1.6)
		else:
			anim.speed_scale = 1.0

var _w := 900.0
var _room_h := 130.0
var _walker: CampWalker
var _buddy: CampWalker
var _cam: Camera2D
var _stations: Array[Dictionary] = []
var _near: Dictionary = {}
var _ui: Control
var _prompt: PanelContainer
var _prompt_label: Label
var _overlay_layer: CanvasLayer
var _overlay: Control
var _talk: Talk
var _portal: Node2D
var _t := 0.0
var _leaving := false


func _ready() -> void:
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	_build_room()
	_build_actors()
	_build_stations()
	_build_portal()
	_build_ui()
	_talk = Talk.new()
	add_child(_talk)
	_arrive()


# --- room -------------------------------------------------------------------

func _build_room() -> void:
	var bg := Polygon2D.new()
	bg.color = Color(0.02, 0.02, 0.035)
	bg.polygon = PackedVector2Array([Vector2(-400, 0), Vector2(4000, 0), Vector2(4000, 900), Vector2(-400, 900)])
	bg.z_index = -10
	add_child(bg)
	var path := "res://assets/backdrops/camp.png"
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	var ground := float(tex.get_height()) * 0.9
	var texel := 2.0 / 3.0
	var meta_path := "res://assets/backdrops/camp.json"
	if FileAccess.file_exists(meta_path):
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if meta is Dictionary:
			ground = float((meta as Dictionary).get("ground", ground))
			texel = float((meta as Dictionary).get("texel", texel))
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(texel, texel)
	s.position = Vector2(0.0, WALK_Y - ground * texel)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = -5
	add_child(s)
	_w = float(tex.get_width()) * texel
	_room_h = ground * texel
	# Warm lamp pools that breathe a little.
	for i in 6:
		var glow := PointLight2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(1, 0.8, 0.5, 0.55))
		g.set_color(1, Color(1, 0.8, 0.5, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0.0)
		gt.width = 128
		gt.height = 128
		glow.texture = gt
		glow.texture_scale = 2.2
		glow.energy = 0.35
		glow.position = Vector2(_w * (0.1 + 0.16 * float(i)), WALK_Y - 120.0)
		glow.set_meta("base", 0.35)
		glow.add_to_group("camp_glow")
		add_child(glow)


func _build_actors() -> void:
	var me := App.solo_role if App.solo_role in ["son", "father"] else "son"
	var other := "father" if me == "son" else "son"
	_walker = CampWalker.new()
	_walker.setup(me)
	_walker.position = Vector2(_w - 40.0, WALK_Y)
	_walker.facing = -1
	add_child(_walker)
	_buddy = CampWalker.new()
	_buddy.setup(other)
	_buddy.position = Vector2(_couch_x() + 14.0, WALK_Y - 2.0)
	_buddy.facing = 1
	add_child(_buddy)
	_buddy.set_motion(0.0)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(ZOOM, ZOOM)
	_cam.limit_left = -20
	_cam.limit_right = int(_w + 70.0)
	_cam.limit_bottom = int(WALK_Y + 60.0)
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed = 6.0
	add_child(_cam)
	_cam.make_current()
	_cam.position = Vector2(_walker.position.x, _cam_y())
	_cam.reset_smoothing()


func _cam_y() -> float:
	return WALK_Y - _room_h * 0.5 + 6.0


func _couch_x() -> float:
	for s in _layout():
		if str((s as Dictionary).get("id", "")) == "therapy_couch":
			return float((s as Dictionary).get("x", 0.5)) * _w
	return _w * 0.5


func _layout() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/camp.json"))
	if parsed is Dictionary:
		var v: Variant = (parsed as Dictionary).get("stations", [])
		if v is Array:
			return v
	return []


# --- stations ---------------------------------------------------------------

func _names() -> Dictionary:
	var out := {"command_board": "COMMAND BOARD"}
	var list: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	if list is Array:
		for b: Variant in list:
			if b is Dictionary:
				out[str((b as Dictionary)["id"])] = str((b as Dictionary)["name"])
	return out


func _build_stations() -> void:
	var names := _names()
	for row: Variant in _layout():
		if not (row is Dictionary):
			continue
		var d := row as Dictionary
		var id := str(d.get("id", ""))
		var x := float(d.get("x", 0.5)) * _w
		var st := {"id": id, "x": x, "name": str(names.get(id, id.capitalize())).to_upper(), "painted": bool(d.get("painted", true))}
		var node := Node2D.new()
		node.position = Vector2(x, WALK_Y)
		add_child(node)
		st["node"] = node
		# Floor ring that lights up when you are in reach.
		var ring := Line2D.new()
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * float(i) / 24.0
			pts.append(Vector2(cos(a) * 16.0, sin(a) * 3.6))
		ring.points = pts
		ring.width = 1.2
		ring.default_color = Color(1.0, 0.82, 0.35, 0.0)
		ring.position = Vector2(0, 2)
		node.add_child(ring)
		st["ring"] = ring
		# Stations with no furniture in the painting stand as their icon.
		if not bool(st["painted"]):
			var icon := SpriteBook.icon(id)
			if icon != null:
				var spr := Sprite2D.new()
				spr.texture = icon
				spr.scale = Vector2.ONE * SpriteBook.DRAW_SCALE * 1.15
				spr.position = Vector2(0, -float(icon.get_height()) * SpriteBook.DRAW_SCALE * 1.15 * 0.5)
				spr.texture_filter = SpriteBook.UI_FILTER
				node.add_child(spr)
				st["sprite"] = spr
		if id == "command_board":
			_board_sign(node)
		_stations.append(st)
	_refresh_locks()


func _board_sign(node: Node2D) -> void:
	# Glowing sign + a pinned board on the wall between the dojo and the lounge.
	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(-17, -74), Vector2(17, -74), Vector2(17, -44), Vector2(-17, -44)])
	board.color = Color(0.32, 0.2, 0.12)
	node.add_child(board)
	for i in 6:
		var note := Polygon2D.new()
		var nx := -14.0 + float(i % 3) * 10.0
		var ny := -71.0 + float(i / 3) * 13.0
		note.polygon = PackedVector2Array([Vector2(nx, ny), Vector2(nx + 8, ny), Vector2(nx + 8, ny + 10), Vector2(nx, ny + 10)])
		note.color = [Palette.LEMON, Palette.EDGE, Color(0.9, 0.9, 0.85), Palette.BRICK, Color(0.9, 0.9, 0.85), Palette.LEMON][i]
		node.add_child(note)
	var lab := NightStreet.plaque(node, Vector2(-34, -86), "COMMAND BOARD", Palette.EDGE, 9)
	lab.z_index = 3


func _locked(id: String) -> bool:
	if id == "command_board" or CampSheets.TAB_OF.has(id):
		return false
	if CampSheets.PATHS.has(id):
		return FamilyProfile.building_level(id) <= 0
	return false


func _refresh_locks() -> void:
	for st in _stations:
		var locked := _locked(str(st["id"]))
		st["locked"] = locked
		if st.has("sprite"):
			(st["sprite"] as Sprite2D).modulate = Color(0.45, 0.45, 0.52) if locked else Color.WHITE


# --- portal -----------------------------------------------------------------

func _build_portal() -> void:
	_portal = Node2D.new()
	_portal.position = Vector2(_w + 34.0, WALK_Y - 27.0)
	add_child(_portal)
	for i in 4:
		var ring := Line2D.new()
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * float(k) / 32.0
			pts.append(Vector2(cos(a) * (11.0 + 3.5 * float(i)), sin(a) * (24.0 + 2.5 * float(i))))
		ring.points = pts
		ring.width = 2.4 - 0.4 * float(i)
		ring.default_color = Color(0.45, 0.8, 1.0, 0.85 - 0.18 * float(i)).lerp(Palette.LEMON, 0.15 * float(i))
		ring.set_meta("spin", 0.6 + 0.35 * float(i))
		_portal.add_child(ring)
	var core := Polygon2D.new()
	var cp := PackedVector2Array()
	for k in 24:
		var a := TAU * float(k) / 24.0
		cp.append(Vector2(cos(a) * 10.5, sin(a) * 23.5))
	core.polygon = cp
	core.color = Color(0.1, 0.25, 0.45, 0.75)
	_portal.add_child(core)
	_portal.move_child(core, 0)
	var light := PointLight2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.5, 0.85, 1.0, 0.9))
	g.set_color(1, Color(0.5, 0.85, 1.0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 128
	gt.height = 128
	light.texture = gt
	light.texture_scale = 1.6
	light.energy = 0.9
	_portal.add_child(light)
	var sparks := CPUParticles2D.new()
	sparks.amount = 40
	sparks.lifetime = 1.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(10, 26)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.gravity = Vector2(0, -20)
	sparks.initial_velocity_min = 6.0
	sparks.initial_velocity_max = 22.0
	sparks.color = Color(0.6, 0.9, 1.0, 0.8)
	sparks.emitting = true
	_portal.add_child(sparks)
	var lab := NightStreet.plaque(_portal, Vector2(-14, -40), "PORTAL", Color(0.6, 0.9, 1.0), 10)
	lab.z_index = 3
	_stations.append({"id": "portal", "x": _portal.position.x, "name": _portal_name(), "painted": true, "locked": false, "node": _portal, "ring": null})


func _portal_name() -> String:
	if App.camp_next != "":
		return "PORTAL  ·  ON TO %s" % App.camp_next.replace("_", " ").to_upper()
	return "PORTAL  ·  NEW RUN"


# --- ui ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_ui = PixelStage.attach_canvas(layer)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UiKit.title("THE HIDEOUT", 30, Palette.EDGE)
	title.position = Vector2(40, 24)
	_ui.add_child(title)
	var sub := Label.new()
	sub.text = "WALK  ·  ◀ ▶      OPEN  ·  ▲ / ENTER      COMMAND BOARD  ·  ALL MENUS      PORTAL  ·  GO ON"
	sub.position = Vector2(42, 66)
	UiKit.apply_label(sub, 13, Palette.MUTED)
	_ui.add_child(sub)
	var pills := HBoxContainer.new()
	pills.position = Vector2(860, 28)
	pills.add_theme_constant_override("separation", 10)
	pills.add_child(UiKit.pill("GOLD", UiKit.num(FamilyProfile.data.get("gold", 0)), Palette.LEMON))
	pills.add_child(UiKit.pill("GEMS", UiKit.num(FamilyProfile.data.get("gems", 0)), Palette.EDGE))
	pills.add_child(UiKit.pill("REP", UiKit.num(FamilyProfile.data.get("rep", 0)), Palette.BRICK))
	_ui.add_child(pills)
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UiKit.frame(Palette.LEMON, 0.35))
	_prompt.visible = false
	_ui.add_child(_prompt)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_prompt_label, 15, Palette.TEXT)
	_prompt.add_child(_prompt_label)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 45
	add_child(_overlay_layer)


func _arrive() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0.6, 0.85, 1.0, 1.0)
	fade.size = Vector2(1280, 720)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fade)
	var tw := fade.create_tween()
	tw.tween_property(fade, "color", Color(0.6, 0.85, 1.0, 0.0), 0.7)
	tw.tween_callback(fade.queue_free)
	Juice.play("res://assets/audio/sting_intro.wav")
	await get_tree().create_timer(0.9).timeout
	var lines := [
		{"who": _walker.role, "text": "Home. Technically a basement."},
		{"who": _buddy.role, "text": "Fridge first. Then we argue about the map."},
	]
	if App.camp_next != "":
		lines = [
			{"who": _buddy.role, "text": "You made it back. The portal's still humming."},
			{"who": _walker.role, "text": "Patch up, gear up, then %s." % App.camp_next.replace("_", " ")},
		]
	_talk.play(lines)
	var tab := App.camp_open_tab
	App.camp_open_tab = ""
	if tab != "" and tab != "clinic":
		_open_hub(tab)


func _process(delta: float) -> void:
	_t += delta
	for c in _portal.get_children():
		if c is Line2D:
			(c as Line2D).rotation = sin(_t * float(c.get_meta("spin", 1.0))) * 0.25
			(c as Line2D).scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 3.0 + float(c.get_meta("spin", 1.0))))
	for g in get_tree().get_nodes_in_group("camp_glow"):
		(g as PointLight2D).energy = float(g.get_meta("base", 0.35)) * (0.92 + 0.08 * sin(_t * 1.7 + (g as Node2D).position.x))
	if _overlay != null or _leaving:
		_walker.set_motion(0.0)
		_prompt.visible = false
		return
	var x := Input.get_axis("p1_left", "p1_right") + Input.get_axis("p2_left", "p2_right")
	x = clampf(x, -1.0, 1.0)
	var fast := Input.is_action_pressed("p1_dash") or Input.is_action_pressed("p2_dash")
	var vx := x * SPEED * (1.6 if fast else 1.0)
	_walker.position.x = clampf(_walker.position.x + vx * delta, 8.0, _w + 40.0)
	_walker.set_motion(vx)
	_cam.position = Vector2(_walker.position.x, _cam_y())
	# The buddy turns to face you.
	_buddy.facing = 1 if _walker.position.x > _buddy.position.x else -1
	_buddy.set_motion(0.0)
	_pick_near()
	if not _near.is_empty() and _pressed_use():
		_use(_near)


func _pressed_use() -> bool:
	for a in ["p1_up", "p2_up", "ui_accept", "p1_light", "p2_light"]:
		if Input.is_action_just_pressed(a):
			return true
	return false


func _pick_near() -> void:
	var best: Dictionary = {}
	var bd := REACH
	for st in _stations:
		var d := absf(float(st["x"]) - _walker.position.x)
		if d < bd:
			bd = d
			best = st
	for st in _stations:
		var ring: Variant = st.get("ring")
		if ring is Line2D:
			var on := st == best
			var c := (ring as Line2D).default_color
			c.a = move_toward(c.a, 0.95 if on else 0.0, 0.15)
			(ring as Line2D).default_color = c
	_near = best
	if best.is_empty():
		_prompt.visible = false
		return
	var locked := bool(best.get("locked", false))
	if locked:
		_prompt_label.text = "%s  ·  BUILD IT AT THE COMMAND BOARD  (%d GOLD)" % [best["name"], FamilyProfile.build_cost(str(best["id"]))]
	else:
		_prompt_label.text = "▲  OPEN  %s" % best["name"]
	_prompt.visible = true
	_prompt.size = Vector2.ZERO
	var sz := _prompt.get_combined_minimum_size()
	# Float the prompt over the station, above head height.
	var at := get_viewport().get_canvas_transform() * Vector2(float(best["x"]), WALK_Y - 62.0)
	var k := float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x)
	var px := clampf(at.x * k - sz.x * 0.5, 16.0, 1264.0 - sz.x)
	var py := clampf(at.y * k - sz.y, 130.0, 560.0)
	_prompt.position = Vector2(px, py).round()


func _use(st: Dictionary) -> void:
	var id := str(st["id"])
	Juice.play("res://assets/audio/ui_click.wav")
	if id == "portal":
		_leave()
		return
	if id == "command_board":
		_open_hub("clinic")
		return
	if bool(st.get("locked", false)):
		_open_hub("clinic")
		return
	if CampSheets.TAB_OF.has(id):
		_open_hub(str(CampSheets.TAB_OF[id]))
		return
	var path := CampSheets.path(id)
	if path != "":
		_open_sheet(path)
		return
	_open_hub("clinic")


# --- overlays ---------------------------------------------------------------

func _open_hub(tab: String) -> void:
	_close_overlay()
	App.pending_tab = tab
	var hub: Control = load("res://scenes/ui/hub.tscn").instantiate()
	_overlay_layer.add_child(hub)
	_overlay = hub
	_add_back_button()


func _open_sheet(path: String) -> void:
	_close_overlay()
	var wrap := Control.new()
	_overlay_layer.add_child(wrap)
	PixelStage.apply_control(wrap)
	var sheet: Control = load(path).new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(sheet)
	_overlay = wrap
	if sheet.has_signal("closed"):
		sheet.closed.connect(_close_overlay)
	if sheet.has_signal("need_refresh"):
		sheet.need_refresh.connect(_refresh_locks)
	FamilyProfile.peek_menu()
	_add_back_button()


func _add_back_button() -> void:
	var bar := Control.new()
	_overlay_layer.add_child(bar)
	PixelStage.apply_control(bar)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := UiKit.button("◀  BACK TO HIDEOUT", Vector2(200, 30))
	b.add_theme_font_size_override("font_size", 13)
	b.position = Vector2(1062, 68)
	b.pressed.connect(_close_overlay)
	bar.add_child(b)
	bar.set_meta("back_bar", true)


func _close_overlay() -> void:
	for c in _overlay_layer.get_children():
		c.queue_free()
	_overlay = null
	_refresh_locks()


func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_pause")):
		_close_overlay()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_walker, "position:x", _portal.position.x, 0.35)
	tw.parallel().tween_property(_walker, "modulate", Color(0.6, 0.9, 1.0, 0.0), 0.45)
	var flash := ColorRect.new()
	flash.color = Color(0.6, 0.85, 1.0, 0.0)
	flash.size = Vector2(1280, 720)
	_ui.add_child(flash)
	tw.tween_property(flash, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		if App.camp_next != "":
			App.leave_camp()
		else:
			App.start_run()
	)
