class_name ErrandGuide
extends CanvasLayer

## Story errands in the hideout. When the next map's gate needs a buy (the
## THERAPY COUCH and THICK SKIN before Gant, the UPPERCUT before the Intake
## Lot, the STOLEN SCRUBS before the roofs...), Dad and the Kid say what is
## missing, then a lit frame and a bobbing arrow walk you to it step by step:
## the room on the floor (or the COMMAND BOARD while Benny is away), the room
## card, BUILD, OPEN, the tab, the node, BUY, WEAR. It never blocks a click:
## you do the buy yourself, the first time, with the arrow on the button.
## When the way is open it points at the portal out.

const TOLD := {
	"dock_street": [
		{"who": "father", "text": "Gant hits like a late fee. I need THICK SKIN before I take him again."},
		{"who": "son", "text": "The THERAPY COUCH teaches it. It's in the skill tree once the couch is up. Follow the arrow."},
	],
	"intake_lot": [
		{"who": "son", "text": "The Intake Lot is full of Clamp King's boys. Tall boys. We need an UPPERCUT."},
		{"who": "father", "text": "The DOJO sells them. First move we buy: watch the arrow, it shows you where."},
	],
	"fire_escapes": [
		{"who": "son", "text": "The roofs have a dress code. Clinic security lets SCRUBS through."},
		{"who": "father", "text": "The WARDROBE CAGE has a pair. Buy them, then WEAR them in the LOCKER."},
	],
	"group_circle": [
		{"who": "father", "text": "Group Circle is a long hour. I want an EXTENDED MAG in that pistol."},
		{"who": "son", "text": "The RESEARCH CENTER installs it. One buy and we're back out."},
	],
	"neon_exchange": [
		{"who": "son", "text": "The agents' cams on the Neon strip blind anything without tape over the lens."},
		{"who": "father", "text": "Then we make TAPE FROM PARTS at the WORKSHOP. Arrow first, questions never."},
	],
}

const QUEST_TOLD := [
	{"who": "father", "text": "Benny left plans on the wall. A QUEST BOARD: street jobs, side money."},
	{"who": "son", "text": "Board first, then the couch. Two builds, then we go back out."},
]

var _map := ""
## What the arrow is on right now (a control key or station:id), for tests.
var target := ""
var _t := 0.0
var _rect := Rect2()
var _label := ""
var _sub := ""
var _done_t := -1.0
var _last_scene: Node = null
var _scrolled: Object = null
## -1 / 1 when the target is off screen to that side (an arrow at the edge).
var _edge := 0
var _draw: Control
var _cap: PanelContainer
var _placed_for := Rect2()
var _placed_size := Vector2.ZERO
var _cap_text: Label
var _cap_sub: Label
## The control the arrow is on (menus), for the story lock.
var _target_ctrl: Control = null
var _nudge := 0.0


## The map whose gate still wants a buy (or tonight's room is due), or "".
static func errand_map() -> String:
	if not PowerBook.enforced():
		return ""
	var hop := App.camp_next if App.camp_next != "" else FamilyProfile.next_run_map()
	if hop == "" or steps(hop).is_empty():
		return ""
	return hop


## The errand talk is the family speaking: it gets their voices.
static func voiced(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		var d := (r as Dictionary).duplicate()
		d["voice"] = true
		out.append(d)
	return out


## Tonight's room in the camp plan, "" when none: the next unbuilt room
## (story rooms come through the story path) once its nights are met and
## fewer than two rooms went up since the last night out. The QUEST BOARD
## after the first night, then the couch, then a run.
static func night_room() -> String:
	if not PowerBook.enforced():
		return ""
	if int(FamilyProfile.data.get("night_builds", 0)) >= FamilyProfile.BUILDS_PER_NIGHT:
		return ""
	var story := PowerBook.story_shops()
	for id in FamilyProfile.BUILD_ORDER:
		if FamilyProfile.is_built(str(id)) or story.has(str(id)):
			continue
		return str(id) if FamilyProfile.build_blocker(str(id)) == "" else ""
	return ""


static func room_name(id: String) -> String:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	if rows is Array:
		for r in rows:
			if r is Dictionary and str((r as Dictionary).get("id", "")) == id:
				return str((r as Dictionary).get("name", id.to_upper()))
	return id.replace("_", " ").to_upper()


## What the arrow walks through, in order: tonight's room when it can be
## paid for, then the story gate's buys for the next map.
static func steps(map_id: String) -> Array:
	var out: Array = []
	var r := night_room()
	# Ember's first night home: the first forging is tonight's thing (it
	# takes the room build's place, so it is still two things, then a run).
	var fs := forge_step()
	if not fs.is_empty():
		out.append(fs)
	elif r != "" and int(FamilyProfile.data.get("gold", 0)) >= FamilyProfile.build_cost(r):
		out.append({"what": "BUILD", "id": r, "name": room_name(r), "gold": FamilyProfile.build_cost(r), "rep": 0, "parts": {}, "night": true})
	out.append_array(PowerBook.path(map_id))
	return out


## Ember is home and nothing was forged yet: walk to the anvil and make the
## cheapest piece (its gold and materials are covered on the way).
const FORGE_FIRST := "steel_cap"


static func forge_step() -> Dictionary:
	if not PowerBook.enforced() or not ForgeBook.is_open() or int(FamilyProfile.data.get("forged", 0)) > 0:
		return {}
	var rc := ForgeBook.recipe(FORGE_FIRST)
	if rc.is_empty():
		return {}
	return {"what": "FORGE", "id": FORGE_FIRST, "name": ForgeBook.title_of(rc), "gold": int(rc.get("gold", 0)), "rep": 0, "parts": rc.get("mats", {})}


## Put one guide in the tree when an errand is open (the hideout calls it).
static func ensure(host: Node) -> void:
	if host == null or not host.is_inside_tree():
		return
	var tree := host.get_tree()
	if tree.get_first_node_in_group("errand_guide") != null:
		return
	var m := errand_map()
	if m == "":
		return
	# The clinic covers what is short the first night the gate turns us back.
	PowerBook.fund(m)
	# The QUEST BOARD is the first room of the plan: Benny's lumber money
	# covers what is short, once.
	if night_room() == "bounty_board" and not bool(FamilyProfile.data.get("quest_fund", false)):
		FamilyProfile.data["quest_fund"] = true
		var short := FamilyProfile.build_cost("bounty_board") - int(FamilyProfile.data.get("gold", 0))
		if short > 0:
			FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) + short
		FamilyProfile.save()
		Guide.play(host, "errand_quest_board", voiced(QUEST_TOLD), 1.6)
	var g := ErrandGuide.new()
	g._map = m
	tree.root.add_child(g)
	var told := "errand_told_" + m
	if TOLD.has(m) and not bool(FamilyProfile.data.get(told, false)):
		FamilyProfile.data[told] = true
		FamilyProfile.save()
		Guide.play(host, "errand_" + m, voiced(TOLD[m]), 1.6)


func _ready() -> void:
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("errand_guide")
	_last_scene = get_tree().current_scene
	_draw = Control.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.draw.connect(_paint)
	add_child(_draw)
	_cap = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 0.92)
	sb.border_color = UiKit.GOLD
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	_cap.add_theme_stylebox_override("panel", sb)
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap.add_child(col)
	_cap_text = Label.new()
	_cap_text.add_theme_font_override("font", UiKit.pixel_font())
	_cap_text.add_theme_font_size_override("font_size", 8)
	_cap_text.add_theme_color_override("font_color", UiKit.GOLD)
	col.add_child(_cap_text)
	_cap_sub = Label.new()
	_cap_sub.add_theme_font_override("font", UiKit.pixel_font())
	_cap_sub.add_theme_font_size_override("font_size", 7)
	_cap_sub.add_theme_color_override("font_color", Palette.TEXT)
	col.add_child(_cap_sub)


func _process(delta: float) -> void:
	_t += delta
	_nudge = move_toward(_nudge, 0.0, delta * 2.5)
	# Leaving the hideout ends the errand guide; the next visit makes a new one.
	if get_tree().current_scene != _last_scene:
		queue_free()
		return
	var steps := ErrandGuide.steps(_map)
	if steps.is_empty():
		if _done_t < 0.0:
			_done_t = 0.0
			Juice.toast("reward", "READY", "%s is open. Take the portal." % _map.replace("_", " ").to_upper())
			Mixer.play_sfx("res://assets/audio/sfx/combo_sting.ogg", 1.0, -4.0)
		_done_t += delta
		_target_done()
	else:
		# Whatever this buy still needs is handed over (big on screen) the
		# moment the arrow reaches it, so a build the arrow showed first can
		# never leave the story buy short.
		GuideFunds.cover_step(steps[0])
		_target_step(steps[0])
	# Hide while a first-use Guide is talking: one voice at a time.
	var talking := get_tree().get_first_node_in_group("guide") != null
	for tk in get_tree().get_nodes_in_group("talk"):
		if tk.has_method("busy") and bool(tk.call("busy")):
			talking = true
	_draw.visible = not talking and _rect.size != Vector2.ZERO
	_cap.visible = _draw.visible
	if _cap.visible:
		_cap_text.text = _label
		_cap_sub.text = _sub
		_cap.reset_size()
		if _rect != _placed_for or _cap.size != _placed_size:
			_placed_for = _rect
			_placed_size = _cap.size
			_cap.position = _place_caption().round()
	_draw.queue_redraw()


## Above the target unless that covers text (a popup's title, a card's
## name); then below, left or right, whichever hides the least writing.
func _place_caption() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var sz := _cap.size
	# A room on the floor: the story line sits fixed at the top, clear of
	# the people and the room's own prompt over their heads.
	if target.begins_with("station:"):
		return Vector2((vp.x - sz.x) * 0.5, 44.0)
	var cx := _rect.get_center().x - sz.x * 0.5
	var cy := _rect.get_center().y - sz.y * 0.5
	var spots := [
		Vector2(cx, _rect.position.y - sz.y - 26.0),
		Vector2(cx, _rect.end.y + 16.0),
		Vector2(_rect.position.x - sz.x - 18.0, cy),
		Vector2(_rect.end.x + 18.0, cy),
	]
	var words: Array[Rect2] = []
	for c in get_tree().root.find_children("*", "Label", true, false):
		var l := c as Label
		if l.text.strip_edges() == "" or not l.is_visible_in_tree() or is_ancestor_of(l):
			continue
		var tf := l.get_global_transform_with_canvas()
		var lr := Rect2(tf.origin, l.size * tf.get_scale())
		if not lr.intersects(_rect):
			words.append(lr)
	var best := Vector2.ZERO
	var best_cost := INF
	for i in spots.size():
		var at: Vector2 = spots[i]
		at.x = clampf(at.x, 4.0, vp.x - sz.x - 4.0)
		at.y = clampf(at.y, 4.0, vp.y - sz.y - 4.0)
		var box := Rect2(at, sz)
		# Never sit on the thing being pointed at.
		var cost := box.intersection(_rect).get_area() * 4.0 + float(i) * 40.0
		for w in words:
			cost += box.intersection(w).get_area()
		if cost < best_cost:
			best_cost = cost
			best = at
	return best


## The story leads until the way is open: while the arrow is on a room of
## the hideout, only that room opens (the rest say what comes first); while
## it is on a button in a menu, only that button presses.
func allows_station(id: String) -> bool:
	if not target.begins_with("station:"):
		return true
	return id == target.substr(8)


## Said when something off the path is tried: what to do instead.
func step_line() -> String:
	var what := _label.get_slice("·", 0).strip_edges().capitalize()
	return "Story first. %s - follow the arrow." % what if what != "" else "Story first - follow the arrow."


func nudge() -> void:
	_nudge = 1.0
	Mixer.play_sfx("res://assets/audio/ui_click.wav", 0.7, -6.0)


func _menu_locked() -> bool:
	if _target_ctrl == null or not is_instance_valid(_target_ctrl) or not _target_ctrl.is_visible_in_tree():
		return false
	# A step that cannot be done (no gold for it) never traps you.
	var tb := _target_ctrl as BaseButton
	if tb != null and tb.disabled:
		return false
	if get_tree().get_first_node_in_group("guide") != null:
		return false
	for tk in get_tree().get_nodes_in_group("talk"):
		if tk.has_method("busy") and bool(tk.call("busy")):
			return false
	return true


## Would the story lock eat a press on this control right now?
func blocks(c: Control) -> bool:
	if not _menu_locked():
		return false
	while c != null and not (c is BaseButton):
		c = c.get_parent() as Control
	if c == null or (c as BaseButton).disabled:
		return false
	return not (c == _target_ctrl or _target_ctrl.is_ancestor_of(c) or c.is_ancestor_of(_target_ctrl))


func _input(event: InputEvent) -> void:
	if not _menu_locked():
		return
	var mouse := event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	var accept := not mouse and event.is_action_pressed("ui_accept") and not event.is_echo()
	if not mouse and not accept:
		return
	var c: Control = get_viewport().gui_get_hovered_control() if mouse else get_viewport().gui_get_focus_owner()
	if not blocks(c):
		return
	get_viewport().set_input_as_handled()
	nudge()
	if accept and _target_ctrl.focus_mode != Control.FOCUS_NONE:
		_target_ctrl.grab_focus()


func _scene() -> Node:
	return get_tree().current_scene


## A visible control by meta key, or a button whose text starts with it.
func _find(key: String) -> Control:
	for c in get_tree().root.find_children("*", "Control", true, false):
		if str(c.get_meta("key", "")) == key and (c as Control).is_visible_in_tree():
			return c
	if key.begins_with("button:"):
		var want := key.substr(7).to_upper()
		for c in get_tree().root.find_children("*", "Button", true, false):
			if (c as Button).text.to_upper().begins_with(want) and (c as Button).is_visible_in_tree():
				return c
	return null


func _aim_control(c: Control) -> void:
	_edge = 0
	# Bring it into view inside a scroll list once.
	if _scrolled != c:
		_scrolled = c
		var p := c.get_parent()
		while p != null:
			if p is ScrollContainer:
				(p as ScrollContainer).ensure_control_visible(c)
				break
			p = p.get_parent()
	var tf := c.get_global_transform_with_canvas()
	_rect = Rect2(tf.origin, c.size * tf.get_scale()).grow(3.0)
	# The pad lands on it: one press of A does the step.
	if c != _target_ctrl:
		_target_ctrl = c
		var b := c as BaseButton
		if b != null and not b.disabled and b.focus_mode != Control.FOCUS_NONE and get_tree().get_first_node_in_group("guide") == null:
			b.grab_focus.call_deferred()
	# Just above the menu it points into: an UNLOCKED banner or a popup
	# over that menu covers the frame instead of the frame sitting on it.
	layer = FocusGlide.layer_above(c)


func _aim_world(at: Vector2) -> void:
	# Over the room, under the hideout's talk bubbles and sheets.
	layer = 31
	var p := get_viewport().get_canvas_transform() * at
	var vp := get_viewport().get_visible_rect().size
	_edge = 0
	if p.x < 20.0:
		_edge = -1
		p.x = 28.0
	elif p.x > vp.x - 20.0:
		_edge = 1
		p.x = vp.x - 28.0
	# The chevron hangs from the top of this rect: its tip lands on `at`.
	_rect = Rect2(p - Vector2(14, -2), Vector2(28, 44))


func _overlay_open() -> bool:
	var s := _scene()
	return s != null and s.has_method("overlay_open") and bool(s.call("overlay_open"))


func _station(id: String) -> bool:
	var s := _scene()
	if s == null or not s.has_method("station_world") or _overlay_open():
		return false
	var at: Vector2 = s.call("station_world", id)
	if at == Vector2.INF:
		return false
	_aim_world(at)
	return true


## First key that is on screen wins; then the room on the floor.
func _chain(keys: Array, station: String) -> bool:
	for k in keys:
		var c := _find(str(k))
		if c:
			_aim_control(c)
			target = str(k)
			return true
	if station != "" and _station(station):
		target = "station:" + station
		return true
	target = ""
	return false


func _target_step(step: Dictionary) -> void:
	_rect = Rect2()
	_target_ctrl = null
	var need: Dictionary = PowerBook.spec(_map).get("need", {})
	var shop := str(need.get("shop", ""))
	var what := str(step.get("what", ""))
	var gold := int(step.get("gold", 0))
	_sub = "STORY  ·  BEFORE %s" % _map.replace("_", " ").to_upper()
	if what == "FORGE":
		_label = "FORGE A %s WITH EMBER  ·  %d G" % [str(step.get("name", "")).to_upper(), gold]
		_sub = "EMBER'S FIRST NIGHT  ·  THE FORGE IN THE YARD"
		if not _chain(["forge_" + str(step.get("id", "")), "forge_tab_forge"], "forge"):
			_chain(["button:◀  BACK"], "")
		return
	if bool(step.get("night", false)):
		_sub = "TONIGHT'S BUILD  ·  THEN THE PORTAL"
		shop = str(step.get("id", shop))
	elif what == "BUILD":
		shop = str(step.get("id", shop))
	if what == "BUILD":
		_label = "BUILD THE %s  ·  %d G" % [str(step.get("name", shop)).to_upper(), gold]
		# Benny raises rooms on the floor; while he is held, the board does it.
		var floor := shop if StoryBook.has_crew("benny") else "command_board"
		if not _chain(["build_btn_" + shop, "card_" + shop], floor):
			# From inside a room's sheet (the forge): back out to the floor.
			_chain(["tab_clinic", "button:◀  BACK"], "")
		return
	var id := str(need.get("id", ""))
	var name := str(step.get("name", id)).to_upper()
	match str(need.get("kind", "")):
		"cbt":
			_label = "LEARN %s IN THE SKILL TREE  ·  %d G" % [name, gold]
			if not _chain(["node_buy_" + id, "node_" + id, "tab_build"], shop):
				_chain(["button:◀  BACK"], "")
		"dojo" when what == "TRAIN":
			var tr: Dictionary = FamilyProfile.data.get("dojo_train", {})
			_label = "DRILL %s ON THE DOJO MAT  ·  %d / %d" % [name, int(tr.get(id, 0)), FamilyProfile.TRAIN_REPS]
			_sub = "BOUGHT  ·  LAND IT 3 TIMES ON THE DUMMY"
			if not _chain(["dojo_train_" + id, "open_btn_" + shop, "card_" + shop], shop):
				_chain(["tab_clinic"], "")
		"dojo":
			_label = "TRAIN %s AT THE DOJO  ·  %d G" % [name, gold]
			if not _chain(["dojo_" + id, "open_btn_" + shop, "card_" + shop], shop):
				_chain(["tab_clinic"], "")
		"gear":
			_label = "BUY %s IN THE LOCKER  ·  %d G" % [name, gold]
			var slot := str(GearBook.item(id).get("slot", "clothes"))
			if not _chain(["gear_buy_" + id, "slot_" + slot, "tab_locker"], shop):
				_chain(["button:◀  BACK"], "")
		"research":
			_label = "RESEARCH %s  ·  %d G" % [name, gold]
			if not _chain(["research_" + id, "open_btn_" + shop, "card_" + shop], shop):
				_chain(["tab_clinic"], "")
		"craft":
			_label = "CRAFT %s AT THE WORKSHOP  ·  %d G" % [name, gold]
			if not _chain(["craft_" + id, "open_btn_" + shop, "card_" + shop], shop):
				_chain(["tab_clinic"], "")
		_:
			_label = "%s %s" % [what, name]


func _target_done() -> void:
	_rect = Rect2()
	_target_ctrl = null
	var need: Dictionary = PowerBook.spec(_map).get("need", {})
	# Bought gear goes on: point at WEAR once before the portal.
	if str(need.get("kind", "")) == "gear":
		var id := str(need.get("id", ""))
		var wear := _find("gear_wear_" + id)
		if wear:
			target = "gear_wear_" + id
			_label = "NOW WEAR IT"
			_sub = "GEAR ONLY WORKS ON YOU"
			_aim_control(wear)
			return
	_label = "READY  ·  TAKE THE PORTAL"
	_sub = "%s IS OPEN" % _map.replace("_", " ").to_upper()
	if not _chain(["button:◀  BACK"], "portal"):
		if _done_t > 30.0:
			queue_free()


func _paint() -> void:
	if _rect.size == Vector2.ZERO:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := _rect.grow(2.0 + 2.0 * pulse + 6.0 * _nudge)
	var col := Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.55 + 0.45 * pulse)
	# A room on the floor gets the arrow only: a box there just framed
	# whoever stood in front of it.
	if _edge == 0 and not target.begins_with("station:"):
		_draw.draw_rect(r, col, false, 2.0)
		_draw.draw_rect(r.grow(3.0), Color(col.r, col.g, col.b, 0.18 * pulse), false, 3.0)
	var bob := 3.0 * sin(_t * 6.0)
	if _edge != 0:
		# Off screen: a big arrow at the edge, pointing the way to walk.
		var c := r.get_center() + Vector2(float(_edge) * bob, 0)
		var e := float(_edge)
		var arrow := PackedVector2Array([c + Vector2(e * 12, 0), c + Vector2(0, -10), c + Vector2(0, -4), c + Vector2(-e * 10, -4), c + Vector2(-e * 10, 4), c + Vector2(0, 4), c + Vector2(0, 10)])
		_draw.draw_colored_polygon(arrow, UiKit.GOLD)
		_draw.draw_polyline(arrow + PackedVector2Array([arrow[0]]), UiKit.INK, 1.0)
		return
	# A chevron bobbing above the target, pointing down at it.
	var tip := Vector2(r.get_center().x, r.position.y - 4.0 + bob)
	var pts := PackedVector2Array([tip, tip + Vector2(-7, -9), tip + Vector2(-3, -9), tip + Vector2(-3, -16), tip + Vector2(3, -16), tip + Vector2(3, -9), tip + Vector2(7, -9)])
	_draw.draw_colored_polygon(pts, UiKit.GOLD)
	_draw.draw_polyline(pts + PackedVector2Array([pts[0]]), UiKit.INK, 1.0)
