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
var _cap_text: Label
var _cap_sub: Label


## The map whose gate still wants a buy, or "".
static func errand_map() -> String:
	if not PowerBook.enforced():
		return ""
	var hop := App.camp_next if App.camp_next != "" else FamilyProfile.next_run_map()
	if hop == "" or PowerBook.path(hop).is_empty():
		return ""
	return hop


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
	var g := ErrandGuide.new()
	g._map = m
	tree.root.add_child(g)
	var told := "errand_told_" + m
	if TOLD.has(m) and not bool(FamilyProfile.data.get(told, false)):
		FamilyProfile.data[told] = true
		FamilyProfile.save()
		Guide.play(host, "errand_" + m, TOLD[m], 1.6)


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
	# Leaving the hideout ends the errand guide; the next visit makes a new one.
	if get_tree().current_scene != _last_scene:
		queue_free()
		return
	var steps := PowerBook.path(_map)
	if steps.is_empty():
		if _done_t < 0.0:
			_done_t = 0.0
			Juice.toast("reward", "READY", "%s is open. Take the portal." % _map.replace("_", " ").to_upper())
			Mixer.play_sfx("res://assets/audio/sfx/combo_sting.ogg", 1.0, -4.0)
		_done_t += delta
		_target_done()
	else:
		_target_step(steps[0])
	# Hide while a first-use Guide is talking: one voice at a time.
	var talking := get_tree().get_first_node_in_group("guide") != null
	_draw.visible = not talking and _rect.size != Vector2.ZERO
	_cap.visible = _draw.visible
	if _cap.visible:
		_cap_text.text = _label
		_cap_sub.text = _sub
		_cap.reset_size()
		var vp := get_viewport().get_visible_rect().size
		var at := Vector2(_rect.get_center().x - _cap.size.x * 0.5, _rect.position.y - _cap.size.y - 26.0)
		if at.y < 4.0:
			at.y = _rect.end.y + 16.0
		at.x = clampf(at.x, 4.0, vp.x - _cap.size.x - 4.0)
		at.y = clampf(at.y, 4.0, vp.y - _cap.size.y - 4.0)
		_cap.position = at.round()
	_draw.queue_redraw()


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


func _aim_world(at: Vector2) -> void:
	var p := get_viewport().get_canvas_transform() * at
	var vp := get_viewport().get_visible_rect().size
	_edge = 0
	if p.x < 20.0:
		_edge = -1
		p.x = 28.0
	elif p.x > vp.x - 20.0:
		_edge = 1
		p.x = vp.x - 28.0
	_rect = Rect2(p - Vector2(14, 22), Vector2(28, 44))


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
	var need: Dictionary = PowerBook.spec(_map).get("need", {})
	var shop := str(need.get("shop", ""))
	var what := str(step.get("what", ""))
	var gold := int(step.get("gold", 0))
	_sub = "STORY  ·  BEFORE %s" % _map.replace("_", " ").to_upper()
	if what == "BUILD":
		_label = "BUILD THE %s  ·  %d G" % [str(step.get("name", shop)).to_upper(), gold]
		# Benny raises rooms on the floor; while he is held, the board does it.
		var floor := shop if StoryBook.has_crew("benny") else "command_board"
		if not _chain(["build_btn_" + shop, "card_" + shop], floor):
			_chain(["tab_clinic"], "")
		return
	var id := str(need.get("id", ""))
	var name := str(step.get("name", id)).to_upper()
	match str(need.get("kind", "")):
		"cbt":
			_label = "LEARN %s IN THE SKILL TREE  ·  %d G" % [name, gold]
			if not _chain(["node_buy_" + id, "node_" + id, "tab_build"], shop):
				_chain(["button:◀  BACK"], "")
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
	var r := _rect.grow(2.0 + 2.0 * pulse)
	var col := Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.55 + 0.45 * pulse)
	if _edge == 0:
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
