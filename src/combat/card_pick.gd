class_name CardPick
extends CanvasLayer

signal picked(id: String)

var _done := false
var _timer := 12.0
var _clock: Label
var ids: Array = []
var _row: HBoxContainer
var _table: Array = []
var _reroll_btn: Button
var _ui: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	Juice.set_world_scale(0.12)
	Juice.play("res://assets/audio/card.wav")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if typeof(parsed) == TYPE_ARRAY:
		_table = parsed
	# Design space like every other HUD layer (it drew at 2x before).
	_ui = PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.6)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(dim)
	var title := UiKit.title("LEVEL UP!", 54, Palette.EDGE)
	title.position = Vector2(0, 28)
	title.size = Vector2(1280, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(title)
	title.pivot_offset = Vector2(640, 32)
	title.scale = Vector2(1.5, 1.5)
	title.create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).tween_property(title, "scale", Vector2.ONE, 0.25)
	_clock = Label.new()
	_clock.position = Vector2(0, 92)
	_clock.size = Vector2(1280, 30)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_clock, 18, Palette.TEXT)
	_ui.add_child(_clock)
	_row = HBoxContainer.new()
	_row.position = Vector2(70, 140)
	_row.size = Vector2(1140, 420)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 26)
	_ui.add_child(_row)
	if ids.is_empty():
		for c in _table:
			if bool(c.get("fixed", false)):
				ids.append(c["id"])
	_paint_cards()
	var tools := HBoxContainer.new()
	tools.position = Vector2(0, 590)
	tools.size = Vector2(1280, 50)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 14)
	_ui.add_child(tools)
	var skip := UiKit.button(Copy.SKIP, Vector2(240, 44))
	skip.pressed.connect(func() -> void:
		_choose("skip")
	)
	tools.add_child(skip)
	_reroll_btn = UiKit.button(Copy.REROLL, Vector2(200, 44))
	_reroll_btn.pressed.connect(_reroll)
	tools.add_child(_reroll_btn)
	_sync_reroll()
	var note := Label.new()
	note.position = Vector2(180, 650)
	note.size = Vector2(920, 48)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "World is slow. Enemies are not paused. Die in the menu. That's the bit. Border is rarity. Legendary shouts. Skip banks nothing."
	UiKit.apply_label(note, 14, Palette.MUTED)
	_ui.add_child(note)
	_focus_middle()


func _paint_cards() -> void:
	for c in _row.get_children():
		c.queue_free()
	for i in mini(3, ids.size()):
		var card: Dictionary = {}
		for c in _table:
			if str(c["id"]) == str(ids[i]):
				card = c
				break
		_row.add_child(_card(card, i == 1))


func _focus_middle() -> void:
	if _row.get_child_count() >= 2:
		var b := _row.get_child(1).find_child("Pick", true, false)
		if b is Button:
			(b as Button).grab_focus()


func _border_for(rarity: String, mid: bool) -> Color:
	var c := Rarity.color(rarity)
	if Rarity.normalize(rarity) == "common" and not mid:
		return Palette.MUTED
	return c


func _glyph(info: Dictionary) -> String:
	var tag := (str(info.get("tag", "")) + " " + str(info.get("id", ""))).to_lower()
	for pair in [["air", "boot"], ["steam", "drop"], ["gold", "gold"], ["gem", "gems"], ["snap", "bolt"], ["block", "shield"], ["parry", "shield"], ["heal", "heart"], ["hp", "heart"], ["gun", "star"], ["throw", "fist"], ["heavy", "fist"], ["light", "fist"]]:
		if str(pair[0]) in tag:
			return str(pair[1])
	return "star"


## A tall pixel card: thick rarity-coloured frame on a 3D base, a big icon
## medallion, the rule's name, what it does, the rarity ribbon, TAKE IT.
func _card(info: Dictionary, mid: bool) -> Control:
	var rarity := Rarity.normalize(str(info.get("rarity", "common")))
	var rc := _border_for(rarity, mid)
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(330, 420)
	var st := preload("res://src/ui/clinic_featured.gd").card_style(mid)
	st.border_color = rc
	st.shadow_color = Color(rc.r, rc.g, rc.b, 0.45) if mid else Color(0, 0, 0.02, 0.9)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 16
	wrap.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	wrap.add_child(col)
	var ribbon := Label.new()
	ribbon.text = Rarity.label(rarity)
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(ribbon, 14, rc)
	col.add_child(ribbon)
	var medal := Control.new()
	medal.custom_minimum_size = Vector2(0, 110)
	col.add_child(medal)
	var disc := Panel.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.1, 0.13, 0.24)
	ds.border_color = rc
	ds.set_border_width_all(4)
	ds.set_corner_radius_all(52)
	ds.shadow_color = Color(0, 0, 0.02, 0.85)
	ds.shadow_size = 1
	ds.shadow_offset = Vector2(0, 5)
	disc.add_theme_stylebox_override("panel", ds)
	disc.size = Vector2(104, 104)
	disc.position = Vector2(95, 2)
	medal.add_child(disc)
	var ic := PixelIcon.new()
	ic.kind = _glyph(info)
	ic.size = Vector2(64, 64)
	ic.position = Vector2(115, 22)
	medal.add_child(ic)
	var t := UiKit.title(str(info.get("name", "?")), 24, rc if Rarity.rank(rarity) >= 2 else Palette.EDGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(290, 0)
	col.add_child(t)
	var b := Label.new()
	b.text = str(info.get("blurb", ""))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(290, 0)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiKit.apply_label(b, 15, Palette.TEXT)
	col.add_child(b)
	var stat := Label.new()
	stat.text = _card_stat(info)
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(stat, 14, UiKit.GOLD)
	col.add_child(stat)
	var go := UiKit.button("TAKE IT", Vector2(200, 50))
	go.name = "Pick"
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		_choose(str(info.get("id", "")))
	)
	col.add_child(go)
	if mid:
		UiKit.pulse_ready(go)
	wrap.pivot_offset = Vector2(165, 210)
	wrap.scale = Vector2(0.7, 0.7)
	wrap.modulate.a = 0.0
	var tw := wrap.create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.08 * float(_row.get_child_count()))
	tw.tween_property(wrap, "scale", Vector2.ONE, 0.25)
	tw.parallel().tween_property(wrap, "modulate:a", 1.0, 0.15)
	return wrap


func _sync_reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	var n := 0
	if rs:
		n = int(rs.get("rerolls"))
	_reroll_btn.disabled = n <= 0
	_reroll_btn.text = Copy.REROLL if n <= 0 else "%s  x%d" % [Copy.REROLL, n]


func _reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null or int(rs.get("rerolls")) <= 0:
		return
	rs.set("rerolls", int(rs.get("rerolls")) - 1)
	var owned: Array = []
	var cards_v: Variant = rs.get("cards")
	if typeof(cards_v) == TYPE_ARRAY:
		owned = (cards_v as Array).duplicate()
	var pool: Array = []
	for c in _table:
		var cid := str(c["id"])
		if owned.has(cid):
			continue
		pool.append(cid)
	pool.shuffle()
	ids = pool.slice(0, 3)
	Juice.play("res://assets/audio/card.wav")
	Juice.shout("SECOND OPINION")
	_paint_cards()
	_sync_reroll()
	_focus_middle()


func _process(delta: float) -> void:
	_timer -= delta / maxf(Engine.time_scale, 0.01)
	_clock.text = "PICK A RULE  ·  %.0f" % maxf(0.0, _timer)
	if _timer <= 0.0 and not _done:
		if ids.size() >= 2:
			_choose(str(ids[1]))
		elif ids.size() == 1:
			_choose(str(ids[0]))
		else:
			_choose("skip")


func _card_stat(info: Dictionary) -> String:
	var st: Variant = info.get("stats", {})
	if typeof(st) == TYPE_DICTIONARY and not (st as Dictionary).is_empty():
		var bits: PackedStringArray = []
		for k in (st as Dictionary).keys():
			bits.append("%s %s" % [str(k).to_upper(), str((st as Dictionary)[k])])
		return "  ·  ".join(bits)
	return str(info.get("tag", "RULE"))


func _choose(id: String) -> void:
	if _done:
		return
	_done = true
	Juice.set_world_scale(1.0)
	picked.emit(id)
	queue_free()
