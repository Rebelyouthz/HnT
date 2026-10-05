extends Control

signal need_refresh

var _focus: Dictionary = {}
var _tip: PanelContainer
var _tip_box: HBoxContainer
var _stage: Control
## Which of the three trees is open (Trees.MODES); kept between visits.
static var mode := "brawl"

## BUILD page after Timmie's reference board: the clinic room behind, three
## vine trees (BODY / STREET / SHOW) of round skill nodes, a tooltip with the
## price and BUY / NEED GOLD, a legend box, a progress bar under each tree.
const CENTER_X := [300.0, 640.0, 980.0]
const TOP := 128.0
const STEP := 84.0
const ARM := 74.0


func _ready() -> void:
	if Engine.has_meta("build_mode"):
		mode = str(Engine.get_meta("build_mode"))
		Engine.remove_meta("build_mode")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stage)
	if ResourceLoader.exists("res://assets/ui/clinic_room.png"):
		var room := TextureRect.new()
		room.texture = load("res://assets/ui/clinic_room.png")
		room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		room.texture_filter = SpriteBook.UI_FILTER
		room.position = Vector2(-16, -8)
		room.size = Vector2(1280, 580)
		room.modulate = Color(0.42, 0.42, 0.52)
		_stage.add_child(room)
		# A soft dark well behind the three trees so the nodes, not the
		# bedroom, carry the screen.
		var well := TextureRect.new()
		well.texture = LightRig.radial_tex()
		well.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		well.position = Vector2(80, 40)
		well.size = Vector2(1100, 560)
		well.modulate = Color(0.0, 0.0, 0.03, 0.75)
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(well)
	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.border_color = UiKit.RIM
	fs.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", fs)
	frame.position = Vector2(-8, -4)
	frame.size = Vector2(1264, 572)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(frame)
	var title := UiKit.title("BUILD", 54, Palette.EDGE)
	title.position = Vector2(0, 2)
	title.size = Vector2(1248, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(title)
	for x in [470.0, 714.0]:
		var orn := ColorRect.new()
		orn.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.7)
		orn.position = Vector2(x, 34)
		orn.size = Vector2(64, 3)
		_stage.add_child(orn)
	var brand := UiKit.title("FATHER\n& SON", 20, Palette.TEXT)
	brand.position = Vector2(16, 10)
	_stage.add_child(brand)
	# The therapy couch is where the tree lives.
	var couch := UiKit.portrait(SpriteBook.icon("therapy_couch"), Vector2(56, 56))
	couch.position = Vector2(118, 10)
	_stage.add_child(couch)
	var list: Array = Trees.nodes(mode)
	var trunks: Array = Trees.TRUNKS[mode]
	for i in trunks.size():
		_tree(str(trunks[i]), list, CENTER_X[i])
	_legend()
	# One tree per way of playing: BRAWL / SURVIVOR / PARKOUR.
	var tabs := VBoxContainer.new()
	tabs.position = Vector2(14, 120)
	tabs.add_theme_constant_override("separation", 6)
	_stage.add_child(tabs)
	for m: String in Trees.MODES:
		var tb := UiKit.button(str(Trees.TITLES[m]), Vector2(150, 34))
		tb.add_theme_font_size_override("font_size", 12)
		if m == mode:
			tb.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		tb.pressed.connect(func() -> void:
			mode = m
			Juice.play("res://assets/audio/ui_click.wav")
			need_refresh.emit()
		)
		tabs.add_child(tb)
	var wallet := Label.new()
	wallet.text = "%s %d" % [Trees.cur_label(mode), Trees.balance(mode)]
	wallet.position = Vector2(1000, 50)
	wallet.size = Vector2(240, 20)
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(wallet, 15, UiKit.GOLD)
	_stage.add_child(wallet)
	# RESPEC: every node in this tree back for its full price.
	var refund := UiKit.button("REFUND TREE", Vector2(150, 30))
	refund.add_theme_font_size_override("font_size", 11)
	refund.disabled = Trees.count(mode).x == 0
	refund.position = Vector2(14, 232)
	var armed := [false]
	refund.pressed.connect(func() -> void:
		if not armed[0]:
			armed[0] = true
			refund.text = "SURE? PRESS AGAIN"
			return
		var back := Trees.refund(mode)
		Juice.toast("reward", "TREE REFUNDED", "+%d %s back. Plant it again your way." % [back, Trees.cur_label(mode)])
		Juice.play("res://assets/audio/cash.wav" if ResourceLoader.exists("res://assets/audio/cash.wav") else "res://assets/audio/claim.wav")
		need_refresh.emit()
	)
	_stage.add_child(refund)
	if mode == "brawl":
		var compare := UiKit.button("BUILD COMPARE", Vector2(170, 32))
		compare.add_theme_font_size_override("font_size", 12)
		compare.position = Vector2(1062, 16)
		compare.pressed.connect(_compare)
		_stage.add_child(compare)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiKit.frame(UiKit.GOLD, 0.3))
	_tip.visible = false
	_stage.add_child(_tip)
	_tip_box = HBoxContainer.new()
	_tip_box.add_theme_constant_override("separation", 22)
	_tip.add_child(_tip_box)
	UiKit.focus_first(self)


func _depth(node: Dictionary, by_id: Dictionary) -> int:
	var d := 0
	var req := str(node.get("requires", ""))
	while req != "" and by_id.has(req) and d < 8:
		d += 1
		req = str((by_id[req] as Dictionary).get("requires", ""))
	return d


func _glyph(node: Dictionary) -> String:
	var st := (str(node.get("stat", "")) + " " + str(node.get("id", ""))).to_lower()
	# SURVIVOR / PARKOUR nodes.
	if "+ability" in st:
		return "fist"
	if "slot" in st or "item" in st:
		return "shield"
	if "reroll" in st or "banish" in st:
		return "eye"
	if "evolution" in st or "ultimate" in st or "stun" in st:
		return "bolt"
	if "trait" in st or "luck" in st:
		return "gems"
	if "chest" in st or "token" in st or "+50% gold" in st:
		return "gold"
	if "revive" in st or "heal" in st:
		return "heart"
	if "jump" in st or "glide" in st or "hang" in st or "air" in st or "coyote" in st or "wall" in st or "speed" in st:
		return "boot"
	if "stomp" in st or "slide" in st or "quake" in st or "roll" in st or "falls" in st:
		return "fist"
	if "i-frames" in st or "combo" in st or "score" in st or "boost" in st:
		return "star"
	if "hp" in st:
		return "heart"
	if "steam" in st:
		return "drop"
	if "bandage" in st:
		return "cross"
	if "gear" in st or "wanted" in st:
		return "shield"
	if "fall" in st or "cling" in st:
		return "boot"
	if "throw" in st or "charge" in st:
		return "fist"
	if "snap" in st:
		return "bolt"
	if "shadow" in st or "eyes" in st:
		return "eye"
	if "gems" in st:
		return "gems"
	if "drops" in st or "lunch" in st or "magnet" in st:
		return "gold"
	return "star"


func _tree(trunk: String, list: Array, cx: float) -> void:
	var by_id := {}
	var nodes: Array = []
	for n: Dictionary in list:
		if str(n.get("trunk", "")) == trunk:
			nodes.append(n)
			by_id[str(n["id"])] = n
	var pos := {}
	var owned_n := 0
	for n: Dictionary in nodes:
		var d := _depth(n, by_id)
		var br := str(n.get("branch", "core"))
		var x := cx
		if d > 0:
			x += -ARM if br == "left" else ARM
		pos[str(n["id"])] = Vector2(x, TOP + float(d) * STEP + (0.0 if d == 0 else 26.0))
		if Trees.owned(mode, str(n["id"])):
			owned_n += 1
	var vines := VineDraw.new()
	vines.position = Vector2.ZERO
	vines.size = Vector2(1280, 600)
	vines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n: Dictionary in nodes:
		var req := str(n.get("requires", ""))
		var a: Vector2 = pos[str(n["id"])]
		var b: Vector2 = pos[req] if pos.has(req) else Vector2(cx, a.y + 60.0)
		vines.links.append([b, a, Trees.owned(mode, str(n["id"]))])
	vines.trunk_x = cx
	vines.trunk_top = TOP
	vines.trunk_bottom = TOP + STEP * 3.0 + 70.0
	_stage.add_child(vines)
	var name_l := UiKit.title(trunk, 22, Palette.EDGE)
	name_l.position = Vector2(cx - 80, TOP - 66)
	name_l.size = Vector2(160, 28)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(name_l)
	for n: Dictionary in nodes:
		_stage.add_child(_node_button(n, pos[str(n["id"])]))
	# Progress sits with the tree's name (the band below holds the info strip).
	name_l.text = "%s  %d/%d" % [trunk, owned_n, nodes.size()]
	name_l.position = Vector2(cx - 110, TOP - 66)
	name_l.size = Vector2(220, 28)
	var bar := UiKit.glow_bar(float(owned_n) / float(maxi(1, nodes.size())), UiKit.GOLD, Vector2(150, 6))
	bar.position = Vector2(cx - 75, TOP - 36)
	_stage.add_child(bar)


func _state(node: Dictionary) -> String:
	return Trees.state(mode, node)


func _node_button(node: Dictionary, at: Vector2) -> Control:
	var st := _state(node)
	var b := Button.new()
	b.custom_minimum_size = Vector2(62, 62)
	b.size = Vector2(62, 62)
	b.position = at - Vector2(31, 31)
	b.focus_mode = Control.FOCUS_ALL
	var ring := StyleBoxFlat.new()
	ring.set_corner_radius_all(31)
	ring.set_border_width_all(4)
	ring.bg_color = Color(0.05, 0.06, 0.1, 0.96)
	ring.anti_aliasing = true
	match st:
		"owned":
			ring.border_color = UiKit.GOLD
			ring.bg_color = Color(0.32, 0.22, 0.08)
			ring.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.5)
			ring.shadow_size = 8
		"can":
			ring.border_color = UiKit.GOLD
			ring.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.75)
			ring.shadow_size = 16
		"poor":
			ring.border_color = UiKit.RIM
		_:
			ring.border_color = Color(0.3, 0.28, 0.3)
	var hover := ring.duplicate() as StyleBoxFlat
	hover.border_color = Color.WHITE.lerp(UiKit.GOLD, 0.4)
	hover.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.8)
	hover.shadow_size = 18
	b.add_theme_stylebox_override("normal", ring)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var icon := PixelIcon.new()
	icon.kind = _glyph(node)
	icon.dim = st == "locked"
	icon.size = Vector2(36, 36)
	icon.position = Vector2(13, 13)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	Bevel.dress(b, true)
	if st == "can":
		b.pivot_offset = Vector2(31, 31)
		UiKit.pulse_ready(b)
	b.mouse_entered.connect(func() -> void: _show_tip(node, at))
	b.focus_entered.connect(func() -> void: _show_tip(node, at))
	b.pressed.connect(func() -> void:
		_show_tip(node, at)
		if st == "can":
			_buy(node)
	)
	return b


func _show_tip(node: Dictionary, _at: Vector2) -> void:
	# One fixed info strip under the trees (it never covers the nodes).
	_focus = node
	for c in _tip_box.get_children():
		c.queue_free()
	var st := _state(node)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(190, 0)
	var name_l := Label.new()
	name_l.text = str(node["name"])
	name_l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(name_l, 17, UiKit.GOLD)
	left.add_child(name_l)
	var stat := Label.new()
	stat.text = str(node.get("stat", ""))
	stat.add_theme_font_override("font", UiKit.pixel_font())
	var stxt := str(node.get("stat", ""))
	UiKit.apply_label(stat, 15, Color(0.36, 1.0, 0.54) if not stxt.begins_with("-") else Color(1.0, 0.35, 0.29))
	left.add_child(stat)
	_tip_box.add_child(left)
	var blurb := Label.new()
	blurb.text = str(node.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(380, 0)
	blurb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiKit.apply_label(blurb, 13, Palette.MUTED)
	_tip_box.add_child(blurb)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(190, 0)
	var cost := Label.new()
	cost.text = "%d %s%s%s" % [int(node["gold"]), Trees.cur_label(mode), ("  ·  %d REP" % int(node["rep"])) if int(node["rep"]) > 0 else "", ("  ·  %d GEM" % int(node.get("gems", 0))) if int(node.get("gems", 0)) > 0 else ""]
	cost.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(cost, 13, Palette.TEXT)
	right.add_child(cost)
	match st:
		"owned":
			var o := Label.new()
			o.text = "OWNED"
			o.add_theme_font_override("font", UiKit.pixel_font())
			UiKit.apply_label(o, 15, Palette.READY)
			right.add_child(o)
		"locked":
			var l := Label.new()
			l.text = "BUY %s FIRST" % str(Trees.node(mode, str(node.get("requires", ""))).get("name", str(node.get("requires", "")))).to_upper()
			l.add_theme_font_override("font", UiKit.pixel_font())
			UiKit.apply_label(l, 13, Palette.MUTED)
			right.add_child(l)
		"poor":
			var p := Label.new()
			p.text = ("NEED " + Trees.cur_label(mode)) if Trees.balance(mode) < int(node["gold"]) else ("NEED REP" if int(FamilyProfile.data["rep"]) < int(node["rep"]) else "NEED GEM")
			p.add_theme_font_override("font", UiKit.pixel_font())
			UiKit.apply_label(p, 16, Color(0.95, 0.25, 0.22))
			right.add_child(p)
		_:
			var buy := UiKit.button("BUY", Vector2(150, 34))
			buy.pressed.connect(func() -> void: _buy(node))
			right.add_child(buy)
	_tip_box.add_child(right)
	_tip.visible = true
	_tip.size = Vector2.ZERO
	_tip.position = Vector2(170, 470)


func _buy(node: Dictionary) -> void:
	if Trees.try_buy(mode, str(node["id"])):
		Juice.play("res://assets/audio/claim.wav")
		need_refresh.emit()
	else:
		Juice.claim_burst(get_viewport_rect().size * 0.5, "NOT ENOUGH " + Trees.cur_label(mode), 0, 0)


func _legend() -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.frame(UiKit.RIM, 0.2))
	box.position = Vector2(14, 300)
	_stage.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	box.add_child(col)
	for pair in [["heart", "HP"], ["fist", "DAMAGE"], ["boot", "SPEED"], ["drop", "STEAM"], ["bolt", "SNAP"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var ic := PixelIcon.new()
		ic.kind = str(pair[0])
		ic.custom_minimum_size = Vector2(24, 24)
		row.add_child(ic)
		var l := Label.new()
		l.text = str(pair[1])
		l.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(l, 14, Palette.TEXT)
		row.add_child(l)
		col.add_child(row)


## Brown vines with leaves from each node up to its parent, plus the trunk.
class VineDraw extends Control:
	var links: Array = []
	var trunk_x := 0.0
	var trunk_top := 0.0
	var trunk_bottom := 0.0

	func _draw() -> void:
		var bark := Color(0.33, 0.22, 0.12)
		var bark_lit := Color(0.5, 0.36, 0.2)
		var leaf := Color(0.27, 0.48, 0.2)
		draw_line(Vector2(trunk_x, trunk_top), Vector2(trunk_x, trunk_bottom), bark, 12.0)
		draw_line(Vector2(trunk_x - 3, trunk_top), Vector2(trunk_x - 3, trunk_bottom), bark_lit, 3.0)
		for l: Array in links:
			var a: Vector2 = l[0]
			var b: Vector2 = l[1]
			var lit: bool = l[2]
			var mid := Vector2(a.x, (a.y + b.y) * 0.5)
			var pts := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
			draw_polyline(pts, bark, 7.0)
			draw_polyline(pts, Color(0.9, 0.7, 0.3, 0.8) if lit else bark_lit, 2.0)
			for i in [3, 7, 10]:
				var p: Vector2 = pts[i]
				var side := 7.0 if i % 2 == 0 else -7.0
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(side, -4), p + Vector2(side * 1.6, 1), p + Vector2(side, 4)]), leaf)
		for k in 5:
			var y := lerpf(trunk_top + 20.0, trunk_bottom - 10.0, float(k) / 4.0)
			var s := 9.0 if k % 2 == 0 else -9.0
			var p := Vector2(trunk_x, y)
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(s, -5), p + Vector2(s * 1.7, 1), p + Vector2(s, 5)]), leaf)


func _compare() -> void:
	if not FamilyProfile.is_built("compare_mirrors"):
		Juice.claim_burst(get_viewport_rect().size * 0.5, "BUILD THE MIRRORS FIRST. NARCISSISM HAS A COVER CHARGE.", 0, 0)
		return
	Juice.unlock_logo("BUILD COMPARE", "%s  vs  %s. Same tree. Different damage." % [FamilyProfile.son_name(), FamilyProfile.father_name()])
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var row := HBoxContainer.new()
	row.position = Vector2(80, 120)
	row.add_theme_constant_override("separation", 24)
	layer.add_child(row)
	var son_box := VBoxContainer.new()
	var st := Label.new()
	st.text = "%s  ·  THE SON" % FamilyProfile.son_name()
	UiKit.apply_label(st, 18, Palette.LEMON)
	son_box.add_child(st)
	son_box.add_child(StatPanel.new(StatPanel.kit_rows("son")))
	var dad_box := VBoxContainer.new()
	var dt := Label.new()
	dt.text = "%s  ·  THE FATHER" % FamilyProfile.father_name()
	UiKit.apply_label(dt, 18, Palette.BRICK)
	dad_box.add_child(dt)
	dad_box.add_child(StatPanel.new(StatPanel.kit_rows("father")))
	row.add_child(son_box)
	row.add_child(dad_box)
	var close := UiKit.button("CLOSE THE MIRRORS", Vector2(240, 44))
	close.position = Vector2(500, 520)
	close.pressed.connect(layer.queue_free)
	layer.add_child(close)
	close.grab_focus()
