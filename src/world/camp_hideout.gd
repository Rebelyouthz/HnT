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
var _busy := false
var _focus_x := 0.0
var _crew := {}
## Rico runs these: they open only once he is back from the Intake Lot.
const RICO_SHOP := ["pawn_shop", "invoice_wheel", "tip_jar", "lost_found"]
const CREW_SPOT := {"benny": 0.045, "rico": 0.775}


func _ready() -> void:
	Mixer.play_music("res://assets/audio/music/music_camp.ogg")
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
	# The painting ends at _w but the portal and the camera reach past it:
	# carry the room on with its own right edge, mirrored and shaded, so the
	# portal stands in a dim back corner instead of a black void.
	var strip_px := 180.0
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(float(tex.get_width()) - strip_px, 0.0, strip_px, float(tex.get_height()))
	var ext := Sprite2D.new()
	ext.texture = at
	ext.centered = false
	ext.flip_h = true
	ext.scale = Vector2(texel, texel)
	ext.position = Vector2(_w, s.position.y)
	ext.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ext.modulate = Color(0.55, 0.52, 0.6)
	ext.z_index = -5
	add_child(ext)
	var shade := Polygon2D.new()
	var ex := _w + strip_px * texel
	shade.polygon = PackedVector2Array([Vector2(_w, s.position.y), Vector2(ex, s.position.y), Vector2(ex, WALK_Y + 200.0), Vector2(_w, WALK_Y + 200.0)])
	shade.vertex_colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.75), Color(0, 0, 0, 0.75), Color(0, 0, 0, 0.0)])
	shade.z_index = -4
	add_child(shade)
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
	for who in ["benny", "rico"]:
		if StoryBook.has_crew(who):
			var npc := CrewNPC.new()
			npc.setup(who)
			npc.position = Vector2(_w * float(CREW_SPOT[who]), WALK_Y - 1.0)
			npc.face(1)
			add_child(npc)
			_crew[who] = npc
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
		if _builds(id):
			var tarp := _tarp()
			node.add_child(tarp)
			st["tarp"] = tarp
		_stations.append(st)
	for who in _crew:
		var npc: CrewNPC = _crew[who]
		_stations.append({"id": "crew_" + who, "x": npc.position.x, "name": StoryBook.who_name(who), "painted": true, "locked": false, "node": npc, "ring": null})
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


## Every camp building (core rooms and sheets) starts as a tarp until built.
func _builds(id: String) -> bool:
	return CampSheets.PATHS.has(id) or CampSheets.TAB_OF.has(id) or id in ["mail_slot", "bulletin_board", "compare_mirrors"]


func _locked(id: String) -> bool:
	if _builds(id):
		return FamilyProfile.building_level(id) <= 0
	return false


func _refresh_locks() -> void:
	for st in _stations:
		var locked := _locked(str(st["id"]))
		st["locked"] = locked
		if st.has("sprite"):
			(st["sprite"] as Sprite2D).modulate = Color(0.45, 0.45, 0.52) if locked else Color.WHITE
		var tarp: Variant = st.get("tarp")
		if tarp is Node2D and is_instance_valid(tarp):
			(tarp as Node2D).visible = locked


## Unbuilt: the corner is dark and dusty (a soft shade over the painted
## furniture) with a small sawhorse and an UNDER CONSTRUCTION board at its
## foot. Building lights it up.
func _tarp() -> Node2D:
	var t := Node2D.new()
	t.z_index = 2
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(-11, 0), Vector2(-11, -40), Vector2(11, -40), Vector2(11, 0)])
	# vertex_colors replace the fill colour: dark at the floor, fading up.
	var dark := Color(0.02, 0.02, 0.05, 0.55)
	var fade := Color(0.02, 0.02, 0.05, 0.08)
	shade.vertex_colors = PackedColorArray([dark, fade, fade, dark])
	t.add_child(shade)
	var horse := Node2D.new()
	horse.position = Vector2(0, 0)
	t.add_child(horse)
	var wood := Color(0.62, 0.45, 0.22)
	for leg in [[-6.0, -1.0], [6.0, 1.0]]:
		var l := Line2D.new()
		l.points = PackedVector2Array([Vector2(leg[0] - 2.0 * leg[1], 0), Vector2(leg[0], -7)])
		l.width = 1.2
		l.default_color = wood.darkened(0.3)
		horse.add_child(l)
	var bar := Polygon2D.new()
	bar.polygon = PackedVector2Array([Vector2(-8, -9), Vector2(8, -9), Vector2(8, -6.5), Vector2(-8, -6.5)])
	bar.color = Color(0.95, 0.8, 0.15)
	horse.add_child(bar)
	for k in 3:
		var st := Polygon2D.new()
		var x := -6.0 + float(k) * 5.0
		st.polygon = PackedVector2Array([Vector2(x, -9), Vector2(x + 2, -9), Vector2(x + 0.6, -6.5), Vector2(x - 1.4, -6.5)])
		st.color = Color(0.08, 0.08, 0.08)
		horse.add_child(st)
	return t


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
	if _busy:
		_cam.position.x = lerpf(_cam.position.x, _focus_x, minf(1.0, delta * 4.0))
	if _overlay != null or _leaving or _busy:
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
	_prompt_label.text = _prompt_for(best)
	_prompt.visible = true
	_prompt.size = Vector2.ZERO
	var sz := _prompt.get_combined_minimum_size()
	# Float the prompt over the station, above head height.
	var at := get_viewport().get_canvas_transform() * Vector2(float(best["x"]), WALK_Y - 62.0)
	var k := float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x)
	var px := clampf(at.x * k - sz.x * 0.5, 16.0, 1264.0 - sz.x)
	var py := clampf(at.y * k - sz.y, 130.0, 560.0)
	_prompt.position = Vector2(px, py).round()


func _prompt_for(st: Dictionary) -> String:
	var id := str(st["id"])
	if id.begins_with("crew_"):
		return "▲  TALK TO  %s" % st["name"]
	if bool(st.get("locked", false)):
		var cost := FamilyProfile.build_cost(id)
		if not StoryBook.has_crew("benny"):
			return "%s  ·  BENNY COULD BUILD THIS  ·  HE'S HELD ON DOCK STREET" % st["name"]
		if int(FamilyProfile.data.get("gold", 0)) < cost:
			return "%s  ·  BENNY NEEDS %d GOLD FOR LUMBER" % [st["name"], cost]
		return "▲  BENNY, BUILD THE %s  ·  %d GOLD" % [st["name"], cost]
	if id in RICO_SHOP and not StoryBook.has_crew("rico"):
		return "%s  ·  RICO RUNS THIS  ·  FREE HIM AT THE INTAKE LOT" % st["name"]
	return "▲  OPEN  %s" % st["name"]


func _use(st: Dictionary) -> void:
	var id := str(st["id"])
	if _busy:
		return
	Juice.play("res://assets/audio/ui_click.wav")
	if id == "portal":
		_leave()
		return
	if id.begins_with("crew_"):
		_crew_talk(id.substr(5))
		return
	if id == "command_board":
		_open_hub("clinic")
		return
	if bool(st.get("locked", false)):
		if StoryBook.has_crew("benny") and int(FamilyProfile.data.get("gold", 0)) >= FamilyProfile.build_cost(id):
			_construct(st)
		elif not StoryBook.has_crew("benny"):
			_talk.play([{"who": _walker.role, "text": "Benny would have this up in a minute. We need him back from Dock Street."}], true)
		else:
			_talk.play([{"who": "benny", "text": "Love the plan. Love it more with gold for lumber."}], true)
		return
	if id in RICO_SHOP and not StoryBook.has_crew("rico"):
		_talk.play([{"who": _buddy.role, "text": "That's Rico's counter. Nobody touches the till till he's home."}], true)
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
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.72)
	dim.position = Vector2(-40, -40)
	dim.size = Vector2(1360, 800)
	wrap.add_child(dim)
	var sheet: Control = load(path).new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(sheet)
	_center_sheet.call_deferred(sheet)
	_overlay = wrap
	if sheet.has_signal("closed"):
		sheet.closed.connect(_close_overlay)
	if sheet.has_signal("need_refresh"):
		sheet.need_refresh.connect(_refresh_locks)
	FamilyProfile.peek_menu()
	_add_back_button()


## Room sheets lay their panel out from the top-left corner: slide it to
## the middle of the screen once it has a size.
func _center_sheet(sheet: Control) -> void:
	if not is_instance_valid(sheet):
		return
	var w := 0.0
	for c in sheet.get_children():
		if c is Control and (c as Control).visible:
			var cc := c as Control
			w = maxf(w, cc.position.x + maxf(cc.size.x, cc.get_combined_minimum_size().x))
	if w > 200.0 and w < 1100.0:
		sheet.position.x += (1280.0 - w) * 0.5


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
	# Anything built from the command board gets raised live on the floor.
	for st in _stations:
		if bool(st.get("locked", false)) and not _locked(str(st["id"])):
			st["locked"] = true
			_construct(st, true)
			return
	_refresh_locks()


func _crew_talk(who: String) -> void:
	var pool: Array = (StoryBook.all().get("crew_talk", {}) as Dictionary).get(who, [])
	if pool.is_empty():
		return
	var npc: CrewNPC = _crew.get(who)
	if npc:
		npc.face(1 if _walker.position.x > npc.position.x else -1)
	_talk.play([{"who": who, "text": str(pool[randi() % pool.size()])}], true)


## Live construction in front of the camera: Benny walks over, hammers,
## planks drop in and stack, dust and chips fly, the tarp is whipped off and
## the room is revealed with a flash. paid = already bought via the hub.
func _construct(st: Dictionary, paid := false) -> void:
	var id := str(st["id"])
	if not paid and not FamilyProfile.try_build(id):
		return
	_busy = true
	_prompt.visible = false
	var x := float(st["x"])
	_focus_x = x
	var node: Node2D = st["node"]
	var benny: CrewNPC = _crew.get("benny")
	var start_x := 0.0
	if benny:
		start_x = benny.position.x
		var walk := benny.walk_to(x - 20.0, 140.0)
		await walk.finished
		benny.face(1)
		benny.hammering = true
	_talk.play([{"who": "benny", "text": "Stand back. Art is happening."}], true)
	var planks: Array[Polygon2D] = []
	for i in 6:
		await get_tree().create_timer(0.36).timeout
		Juice.play("res://assets/audio/hammer.wav")
		Juice.pulse_shake(1.5)
		_dust(node.global_position + Vector2(randf_range(-12, 12), -4))
		var p := Polygon2D.new()
		var w := randf_range(18.0, 30.0)
		p.polygon = PackedVector2Array([Vector2(-w * 0.5, -1.5), Vector2(w * 0.5, -1.5), Vector2(w * 0.5, 1.5), Vector2(-w * 0.5, 1.5)])
		p.color = Color(0.62, 0.43, 0.24).darkened(randf_range(0.0, 0.25))
		p.z_index = 3
		p.position = Vector2(randf_range(-6, 6), -90.0)
		p.rotation = randf_range(-0.6, 0.6)
		node.add_child(p)
		planks.append(p)
		var land := Vector2(randf_range(-8, 8), -3.0 - float(i) * 6.0)
		var tw := p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", land, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "rotation", randf_range(-0.12, 0.12) + (PI * 0.5 if i % 3 == 2 else 0.0), 0.28)
	await get_tree().create_timer(0.3).timeout
	# Reveal.
	Juice.play("res://assets/audio/claim.wav")
	Juice.pulse_shake(4.0)
	var tarp: Variant = st.get("tarp")
	if tarp is Node2D and is_instance_valid(tarp):
		var tn := tarp as Node2D
		var tt := tn.create_tween().set_parallel(true)
		tt.tween_property(tn, "position", tn.position + Vector2(26, -70), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tt.tween_property(tn, "rotation", 1.4, 0.5)
		tt.tween_property(tn, "modulate:a", 0.0, 0.5)
	for p in planks:
		var pt := p.create_tween().set_parallel(true)
		pt.tween_property(p, "modulate:a", 0.0, 0.35)
		pt.tween_property(p, "position:y", p.position.y - 10.0, 0.35)
	Juice.impact(node.global_position + Vector2(0, -24), 1.0, 1)
	for k in 3:
		_dust(node.global_position + Vector2(randf_range(-16, 16), -randf_range(4, 30)))
	if benny:
		benny.hammering = false
	st["locked"] = false
	_refresh_locks()
	var info := {}
	var list: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	if list is Array:
		for b: Variant in list:
			if b is Dictionary and str((b as Dictionary)["id"]) == id:
				info = b
	Juice.carpenter(str(info.get("name", st["name"])), str(info.get("unlocks", "CAMP")))
	_talk.play([{"who": "benny", "text": "%s. Built to code. Our code." % str(st["name"]).capitalize()}], true)
	await get_tree().create_timer(1.2).timeout
	for p in planks:
		if is_instance_valid(p):
			p.queue_free()
	if benny:
		benny.walk_to(start_x, 110.0)
	_busy = false


func _dust(at: Vector2) -> void:
	var d := CPUParticles2D.new()
	d.global_position = at
	d.one_shot = true
	d.explosiveness = 0.9
	d.amount = 14
	d.lifetime = 0.6
	d.direction = Vector2(0, -1)
	d.spread = 70.0
	d.gravity = Vector2(0, 60)
	d.initial_velocity_min = 10.0
	d.initial_velocity_max = 40.0
	d.scale_amount_min = 1.0
	d.scale_amount_max = 2.2
	d.color = Color(0.75, 0.65, 0.5, 0.7)
	d.z_index = 4
	d.emitting = true
	add_child(d)
	get_tree().create_timer(1.0).timeout.connect(d.queue_free)


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
