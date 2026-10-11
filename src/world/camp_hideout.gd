extends Node2D

## Actor scale in the hideout room (crew NPCs read it too).
const CAMP_K := 1.6

## The hideout: a walkable home between maps. Every camp building and core
## room is a station on the floor (walk up, press UP / ENTER / LIGHT): it
## opens just that menu. The COMMAND BOARD opens the whole clinic hub, all
## menus in one place, exactly as before. The PORTAL takes you on: to the
## next map when you came through it mid-run, else into a new run.
## Layout lives in data/camp.json (station id + x on the painted rooms).

const WALK_Y := 500.0
const SPEED := 150.0
const BUDDY_GAP := 34.0
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

	## Top of the hair above the feet (SpeechBubble): the idle frame's
	## trimmed height at the room's size.
	func bubble_head() -> float:
		if anim == null or anim.sprite_frames == null or not anim.sprite_frames.has_animation("idle"):
			return 70.0
		var t := anim.sprite_frames.get_frame_texture("idle", 0)
		var cell_h := float(t.get_height())
		var top := 0.0
		if t is AtlasTexture:
			# AtlasTexture margins restore the cell: the body starts margin.y down.
			top = (t as AtlasTexture).margin.position.y
		var off := anim.offset.y - (cell_h * 0.5 if anim.centered else 0.0)
		return -(anim.position.y + (off + top) * absf(anim.scale.y)) + 6.0

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
			# The hideout room is painted big: a grown man stands about a
			# door frame tall (CAMP_K), not two thirds of one.
			SpriteBook.grow(anim, CAMP_K * SpriteBook.hero_k(who))
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
## The purse pills' value labels (gold / gems / rep), kept live: buys in a
## menu over the room used to leave the old sums showing.
var _purse := {}
## Rico runs these: they open only once he is back from the Intake Lot.
const RICO_SHOP := ["pawn_shop", "invoice_wheel", "tip_jar", "lost_found"]
const CREW_SPOT := {"benny": 0.045, "rico": 0.775, "dot": 0.262}


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
	# The other hero tags along a step behind, so whoever talks is on screen.
	_buddy.position = Vector2(_walker.position.x + BUDDY_GAP, WALK_Y - 2.0)
	_buddy.facing = -1
	add_child(_buddy)
	_buddy.set_motion(0.0)
	for who in CREW_SPOT:
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


## The buddy walks to a spot a step behind you and turns to face you there.
func _follow_buddy(delta: float) -> void:
	var want := _walker.position.x - float(_walker.facing) * BUDDY_GAP
	var dx := want - _buddy.position.x
	if absf(dx) < 6.0:
		_buddy.set_motion(0.0)
		_buddy.facing = 1 if _walker.position.x > _buddy.position.x else -1
		_buddy.set_motion(0.0)
		return
	var vx := signf(dx) * minf(SPEED * (1.7 if absf(dx) > 90.0 else 1.0), absf(dx) / maxf(delta, 0.001))
	_buddy.position.x += vx * delta
	_buddy.set_motion(vx)


func _cam_y() -> float:
	return WALK_Y - _room_h * 0.5 + 6.0


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
	# The pinned board is in the painting; only its glowing name plate here.
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
## furniture) so it reads as not yet built. Building lights it up.
func _tarp() -> Node2D:
	var t := Node2D.new()
	t.z_index = 2
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(-11, 0), Vector2(-11, -40), Vector2(11, -40), Vector2(11, 0)])
	# vertex_colors replace the fill colour: dark at the floor, fading up.
	var dark := Color(0.02, 0.02, 0.05, 0.3)
	var fade := Color(0.02, 0.02, 0.05, 0.0)
	shade.vertex_colors = PackedColorArray([dark, fade, fade, dark])
	t.add_child(shade)
	return t


# --- portal -----------------------------------------------------------------

func _build_portal() -> void:
	_portal = Node2D.new()
	_portal.position = Vector2(_w + 34.0, WALK_Y - 27.0)
	add_child(_portal)
	# Benny's welded pipe ring on a pallet, the rift swirling inside
	# (assets/sprites/portal, tools/portal_art.py). Drawn rings without it.
	var sheet_path := "res://assets/sprites/portal/portal_sheet.png"
	if ResourceLoader.exists(sheet_path):
		var sheet: Texture2D = load(sheet_path)
		var fw := 144
		var sf := SpriteFrames.new()
		sf.set_animation_speed("default", 10.0)
		for k in int(sheet.get_width() / fw):
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(k * fw, 0, fw, sheet.get_height())
			sf.add_frame("default", at)
		var spr := AnimatedSprite2D.new()
		spr.name = "PortalSprite"
		spr.sprite_frames = sf
		spr.scale = Vector2(0.34, 0.34)
		# Pallet on the floor, the ring where the drawn one stood; the
		# walker passes in front of it.
		spr.position = Vector2(0, 31.0 - sheet.get_height() * 0.17)
		spr.z_index = -1
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.play("default")
		_portal.add_child(spr)
	else:
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
	sparks.emission_rect_extents = Vector2(9, 22)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.gravity = Vector2(0, -20)
	sparks.initial_velocity_min = 6.0
	sparks.initial_velocity_max = 22.0
	sparks.color = Color(0.6, 0.9, 1.0, 0.8)
	sparks.emitting = true
	sparks.z_index = -1
	_portal.add_child(sparks)
	var lab := NightStreet.plaque(_portal, Vector2(-14, -50), "PORTAL", Color(0.6, 0.9, 1.0), 10)
	lab.z_index = 3
	lab.name = "PortalPlaque"
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
	for pr in [["GOLD", "gold", Palette.LEMON], ["GEMS", "gems", Palette.EDGE], ["REP", "rep", Palette.BRICK]]:
		var pill := UiKit.pill(pr[0], UiKit.num(FamilyProfile.data.get(pr[1], 0)), pr[2])
		_purse[pr[1]] = pill.get_node("Value")
		pills.add_child(pill)
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
	# The story owes a camp buy: say which one, plainly.
	var hop := App.camp_next if App.camp_next != "" else FamilyProfile.next_run_map()
	var steps := PowerBook.path(hop)
	if not steps.is_empty():
		var first: Dictionary = steps[0]
		lines[1] = {"who": _buddy.role, "text": "Before %s: %s %s, %d gold. Then we go." % [hop.replace("_", " "), str(first["what"]).to_lower(), str(first["name"]).capitalize(), int(first["gold"])]}
	_talk.play(lines)
	var tab := App.camp_open_tab
	App.camp_open_tab = ""
	if tab != "" and tab != "clinic":
		_open_hub(tab)
	# A story errand (the gate's buy) gets its arrow once the hello is said.
	get_tree().create_timer(3.2).timeout.connect(func() -> void:
		if is_inside_tree():
			ErrandGuide.ensure(self)
	)


## Errand guide: where a station stands on the floor, INF if none.
func station_world(id: String) -> Vector2:
	for st in _stations:
		if str(st["id"]) == id:
			# Just over the heads, under the station's floating prompt.
			return Vector2(float(st["x"]), WALK_Y - _walker.bubble_head() - 2.0)
	return Vector2.INF


func overlay_open() -> bool:
	return _overlay != null and is_instance_valid(_overlay)


func _process(delta: float) -> void:
	_t += delta
	for k: String in _purse:
		var v := UiKit.num(FamilyProfile.data.get(k, 0))
		if (_purse[k] as Label).text != v:
			(_purse[k] as Label).text = v
	for c in _portal.get_children():
		if c is Line2D:
			(c as Line2D).rotation = sin(_t * float(c.get_meta("spin", 1.0))) * 0.25
			(c as Line2D).scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 3.0 + float(c.get_meta("spin", 1.0))))
	# The PORTAL sign steps aside while its own prompt is up.
	var plq := _portal.get_node_or_null("PortalPlaque") as CanvasItem
	if plq != null:
		var near_portal := not _near.is_empty() and str(_near.get("id", "")) == "portal"
		plq.modulate.a = move_toward(plq.modulate.a, 0.0 if near_portal else 1.0, delta * 4.0)
	for g in get_tree().get_nodes_in_group("camp_glow"):
		(g as PointLight2D).energy = float(g.get_meta("base", 0.35)) * (0.92 + 0.08 * sin(_t * 1.7 + (g as Node2D).position.x))
	if _busy:
		_cam.position.x = lerpf(_cam.position.x, _focus_x, minf(1.0, delta * 4.0))
	_follow_buddy(delta)
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
			var c := (ring as Line2D).default_color
			# The prompt over the station says you are in reach; no floor ring.
			c.a = 0.0
			(ring as Line2D).default_color = c
	_near = best
	# While someone talks, the floating prompt would sit on the balloon.
	if best.is_empty() or (_talk != null and _talk.busy()):
		_prompt.visible = false
		return
	_prompt_label.text = _prompt_for(best)
	_prompt.visible = true
	# While a story errand points somewhere else, this station whispers.
	var eg := get_tree().get_first_node_in_group("errand_guide")
	var aside := eg != null and str(eg.get("target")).begins_with("station:") and str(eg.get("target")) != "station:" + str(best["id"])
	_prompt.modulate.a = move_toward(_prompt.modulate.a, 0.45 if aside else 1.0, 0.1)
	_prompt.size = Vector2.ZERO
	var sz := _prompt.get_combined_minimum_size()
	# Float the prompt over the station, above head height.
	# Over the hair, not across the faces of whoever stands at the station.
	var at := get_viewport().get_canvas_transform() * Vector2(float(best["x"]), WALK_Y - _walker.bubble_head() - 10.0)
	var k := float(PixelStage.DESIGN.x) / float(PixelStage.LOGICAL.x)
	var px := clampf(at.x * k - sz.x * 0.5, 16.0, 1264.0 - sz.x)
	var py := clampf(at.y * k - sz.y, 96.0, 560.0)
	_prompt.position = Vector2(px, py).round()


func _prompt_for(st: Dictionary) -> String:
	var id := str(st["id"])
	if id.begins_with("crew_"):
		return "▲  TALK TO  %s" % st["name"]
	if bool(st.get("locked", false)):
		var cost := FamilyProfile.build_cost(id)
		var blk := FamilyProfile.build_blocker(id)
		if blk != "":
			return "%s  ·  %s" % [st["name"], FamilyProfile.blocker_text(id)]
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
	# Story first: while the errand points at a room, only that room opens.
	var eg := get_tree().get_first_node_in_group("errand_guide")
	if eg != null and not bool(eg.call("allows_station", id)):
		eg.call("nudge")
		_talk.play([{"who": _walker.role, "text": str(eg.call("step_line"))}], true)
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
		var blk2 := FamilyProfile.build_blocker(id)
		if blk2.begins_with("@"):
			var n := int(blk2.substr(1))
			_talk.play([{"who": "benny", "text": "Not yet. Bring me %d more night%s of stories and I'll find the lumber." % [n, "" if n == 1 else "s"]}], true)
			return
		if blk2 != "":
			_talk.play([{"who": "benny", "text": "One thing at a time. The %s goes up first, then this." % blk2.replace("_", " ")}], true)
			return
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
	var planks: Array[Node2D] = []
	var lumber: Texture2D = load("res://assets/sprites/camp/planks.png") if ResourceLoader.exists("res://assets/sprites/camp/planks.png") else null
	for i in 6:
		await get_tree().create_timer(0.36).timeout
		Juice.play("res://assets/audio/hammer.wav")
		Juice.pulse_shake(1.5)
		_dust(node.global_position + Vector2(randf_range(-12, 12), -4))
		# A pixel-art plank (tools/plank_art.py) at the room's texel size.
		var p := Sprite2D.new()
		if lumber != null:
			var at := AtlasTexture.new()
			at.atlas = lumber
			at.region = Rect2(56 * (i % 4), 0, 56, 10)
			p.texture = at
			p.scale = Vector2.ONE * (2.0 / 3.0)
			p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			p.modulate = Color.WHITE.darkened(randf_range(0.0, 0.18))
		# Behind the people standing at the station, over the painted room.
		p.z_index = -1
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
	Juice.carpenter(str(info.get("name", st["name"])), str(info.get("unlocks", "CAMP")), str(st["id"]))
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
	# The rift pulls him in: he thins and lifts into its middle, the ring
	# flares and spins up, a whoosh.
	tw.parallel().tween_property(_walker, "scale", Vector2(0.35, 1.25), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_walker, "position:y", _walker.position.y - 18.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var spr := _portal.get_node_or_null("PortalSprite") as AnimatedSprite2D
	if spr != null:
		spr.speed_scale = 3.0
		var t2 := create_tween()
		t2.tween_property(spr, "modulate", Color(1.6, 1.8, 2.2), 0.25)
		t2.tween_property(spr, "scale", spr.scale * 1.06, 0.2).set_trans(Tween.TRANS_BACK)
	for c in _portal.get_children():
		if c is PointLight2D:
			create_tween().tween_property(c, "energy", 2.6, 0.4)
		elif c is CPUParticles2D:
			(c as CPUParticles2D).initial_velocity_max = 70.0
			(c as CPUParticles2D).amount = 80
	Juice.pulse_shake(3.0)
	Mixer.play_sfx("res://assets/audio/dash.wav", 0.6, -2.0)
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
