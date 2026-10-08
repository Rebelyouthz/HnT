extends Control

## THE COPING HOURS: the survivor lobby (Halls of Torment's pre-run screen).
## Pick the hour (each map's own ground as the picture, best time and kills,
## locked until the story reaches it), the AGONY dial, the hero (with the
## SURVIVOR level and weapon slots), check the starter weapon, gear and the
## survivor tree, then START. The hour is a run of its own.

signal closed

const MAPS := ["intake_lot", "group_circle", "waiting_room", "sleet_hour", "ledger_dive"]
const NAMES := {"intake_lot": "THE FLOODED LOT", "group_circle": "GROUP CIRCLE", "waiting_room": "THE WAITING ROOM",
	"sleet_hour": "THE SLEET HOUR", "ledger_dive": "LEDGER DIVE"}
const BLURB := {"intake_lot": "Wet asphalt, parked cars, the magnet is the love language.",
	"group_circle": "Courtyard pavers. Everybody brings a chair, nobody passes the stick.",
	"waiting_room": "Fluorescent forever-room. Number 87 is already sitting.",
	"sleet_hour": "Slush on the cobbles. Snowmobiles at the elite pack.",
	"ledger_dive": "Wet dock planks over black water. Billboards drown."}

var _map := ""
var _agony := 0
var _cards: Dictionary = {}
var _info: RichTextLabel
var _ag_row: HBoxContainer
var _start: Button
var _heroes: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root := Control.new()
	root.position = Vector2(40, 30)
	root.size = Vector2(1200, 660)
	add_child(root)
	var card := Panel.new()
	card.size = root.size
	var st := UiKit.panel(Color(0.025, 0.035, 0.06, 0.985), Color(0.45, 1.0, 0.6))
	st.set_border_width_all(3)
	card.add_theme_stylebox_override("panel", st)
	root.add_child(card)
	var glow := Panel.new()
	glow.size = root.size
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.add_theme_stylebox_override("panel", UiKit.frame(Color(0.45, 1.0, 0.6), 0.35))
	root.add_child(glow)
	var head := UiKit.title("THE COPING HOURS  ·  SURVIVOR", 28, Color(0.45, 1.0, 0.6))
	head.position = Vector2(24, 14)
	root.add_child(head)
	var coins := Label.new()
	coins.text = "S-COINS %d" % int(FamilyProfile.data.get("tokens", 0))
	UiKit.apply_label(coins, 16, UiKit.GOLD)
	coins.position = Vector2(860, 24)
	root.add_child(coins)
	var close := UiKit.button("CLOSE", Vector2(120, 36))
	close.position = Vector2(1060, 16)
	close.pressed.connect(func() -> void: closed.emit())
	root.add_child(close)
	# The five hours: their ground as the picture.
	var row := HBoxContainer.new()
	row.position = Vector2(24, 70)
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	for m: String in MAPS:
		var c := _map_card(m)
		row.add_child(c)
		_cards[m] = c
	# AGONY dial.
	var al := UiKit.title("AGONY", 18, Color(1.0, 0.4, 0.35))
	al.position = Vector2(24, 330)
	root.add_child(al)
	_ag_row = HBoxContainer.new()
	_ag_row.position = Vector2(120, 326)
	_ag_row.add_theme_constant_override("separation", 6)
	root.add_child(_ag_row)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.position = Vector2(24, 380)
	_info.size = Vector2(620, 160)
	_info.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(_info)
	# Heroes: who walks into the hour.
	var hl := UiKit.title("WHO GOES IN", 18, Palette.LEMON)
	hl.position = Vector2(700, 380)
	root.add_child(hl)
	_heroes = HBoxContainer.new()
	_heroes.position = Vector2(700, 414)
	_heroes.add_theme_constant_override("separation", 12)
	root.add_child(_heroes)
	# Loadout shortcuts.
	var tools := HBoxContainer.new()
	tools.position = Vector2(24, 560)
	tools.add_theme_constant_override("separation", 10)
	root.add_child(tools)
	for pair in [["STARTER WEAPON", "res://src/ui/starter_sheet.gd"], ["SURVIVOR GEAR", "res://src/ui/surv_gear_sheet.gd"]]:
		var b := UiKit.button(pair[0], Vector2(190, 44))
		b.pressed.connect(func() -> void:
			var sh: Control = load(pair[1]).new()
			add_child(sh)
			sh.closed.connect(func() -> void:
				sh.queue_free()
				_refresh())
		)
		tools.add_child(b)
	var tree := UiKit.button("SURVIVOR TREE", Vector2(190, 44))
	tree.pressed.connect(func() -> void:
		Engine.set_meta("build_mode", "survivor")
		closed.emit()
		var hub := get_tree().current_scene
		if hub and hub.has_method("_show_tab"):
			hub.call("_show_tab", "build")
	)
	tools.add_child(tree)
	_start = UiKit.button("START THE HOUR", Vector2(300, 64))
	_start.position = Vector2(876, 572)
	_start.add_theme_font_size_override("font_size", 22)
	_start.pressed.connect(_go)
	root.add_child(_start)
	var last := str(FamilyProfile.data.get("surv_last_map", ""))
	for m: String in MAPS:
		if _open(m) and _map == "":
			_map = m
	if last != "" and _open(last):
		_map = last
	_pick(_map if _map != "" else MAPS[0])
	UiKit.pop_in(card)
	_start.grab_focus()


## A map is open once the story has reached it.
func _open(m: String) -> bool:
	var filed: Array = FamilyProfile.data.get("maps_filed", [])
	if filed.has(m):
		return true
	return App.ORDER.find(m) <= App.ORDER.find(FamilyProfile.next_run_map())


func _map_card(m: String) -> Control:
	var open := _open(m)
	var b := Button.new()
	b.custom_minimum_size = Vector2(222, 240)
	b.pivot_offset = Vector2(111, 120)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.04, 0.05, 0.08, 0.95), UiKit.RIM))
	b.add_theme_stylebox_override("hover", UiKit.panel(Color(0.06, 0.08, 0.1, 0.95), Color(0.45, 1.0, 0.6)))
	b.add_theme_stylebox_override("focus", UiKit.panel(Color(0.06, 0.08, 0.1, 0.95), Color(0.45, 1.0, 0.6)))
	b.add_theme_stylebox_override("pressed", UiKit.panel(Color(0.06, 0.08, 0.1, 0.95), Color(0.45, 1.0, 0.6)))
	var pic := TextureRect.new()
	var tile := str(SurviveField.theme(m)["tile"])
	# A small cut of the map's own ground (the full one is arena-sized).
	var path := "res://assets/sprites/field/thumb_%s.png" % tile
	if ResourceLoader.exists(path):
		pic.texture = load(path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.position = Vector2(6, 6)
	pic.size = Vector2(210, 140)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.modulate = Color(1.3, 1.3, 1.3) if open else Color(0.25, 0.25, 0.3)
	b.add_child(pic)
	# A pool of lamp light on the picture.
	var glow := TextureRect.new()
	glow.texture = LightRig.radial_tex()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(46, 16)
	glow.size = Vector2(130, 110)
	glow.modulate = Color(SurviveField.theme(m)["lamp"]) * Color(1, 1, 1, 0.45)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if open:
		b.add_child(glow)
	var nm := Label.new()
	nm.text = str(NAMES[m]) if open else "LOCKED"
	nm.position = Vector2(10, 152)
	nm.size = Vector2(202, 22)
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 15, Color(0.45, 1.0, 0.6) if open else Palette.MUTED)
	b.add_child(nm)
	var best := Agony.best(m)
	var sub := Label.new()
	sub.position = Vector2(10, 178)
	sub.size = Vector2(202, 54)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if open:
		var t := int(best.get("time", 0))
		sub.text = "BEST %d:%02d  ·  %d KILLS\n%s" % [t / 60, t % 60, int(best.get("kills", 0)), Agony.NAMES[Agony.open_on(m)] + " OPEN"]
	else:
		sub.text = "Reach it in the story first."
	UiKit.apply_label(sub, 11, Palette.TEXT if open else Palette.MUTED)
	b.add_child(sub)
	b.disabled = not open
	b.pressed.connect(func() -> void: _pick(m))
	b.focus_entered.connect(func() -> void:
		if open:
			_pick(m))
	return b


func _pick(m: String) -> void:
	if not _open(m):
		return
	_map = m
	_agony = mini(_agony, Agony.open_on(m))
	for k: String in _cards:
		var cb := _cards[k] as Button
		cb.modulate = Color.WHITE if k == m else Color(0.7, 0.7, 0.76)
		cb.scale = Vector2.ONE * (1.04 if k == m else 1.0)
		var sel := UiKit.panel(Color(0.05, 0.09, 0.07, 0.98), Color(0.45, 1.0, 0.6))
		sel.set_border_width_all(4)
		cb.add_theme_stylebox_override("normal", sel if k == m else UiKit.panel(Color(0.04, 0.05, 0.08, 0.95), UiKit.RIM))
	_refresh()


func _refresh() -> void:
	for c in _ag_row.get_children():
		c.queue_free()
	var top := Agony.open_on(_map)
	for i in Agony.MAX + 1:
		var b := UiKit.button(Agony.NAMES[i], Vector2(84, 34))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = i > top
		if i == _agony:
			b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.3, 0.06, 0.05, 0.95), Color(1.0, 0.4, 0.35)))
		b.pressed.connect(func() -> void:
			_agony = i
			Juice.play("res://assets/audio/ui_click.wav")
			_refresh())
		_ag_row.add_child(b)
	var a := _agony
	var boss: Dictionary = StoryBook.act(_map).get("boss", {})
	var mini: Dictionary = StoryBook.act(_map).get("miniboss", {})
	_info.text = "[color=#73ff99]%s[/color]  ·  [color=#ff6a5a]%s[/color]\n%s\n\nMID-HOUR  [color=#ffd36b]%s[/color]     THE BOSS  [color=#ff6a5a]%s[/color]\nThugs [color=#ff6a5a]+%d%% health  +%d%% at once[/color]   ·   S-COINS [color=#5effa0]+%d%%[/color]\nSurvive the hour, beat the boss: the next AGONY opens here." % [
		str(NAMES[_map]), Agony.NAMES[a], str(BLURB[_map]), str(mini.get("title", "a named problem")).to_upper(), str(boss.get("title", "the hour's boss")).to_upper(), int(30 * a), int(15 * a), int(35 * a)]
	for c in _heroes.get_children():
		c.queue_free()
	for role in ["son", "father"]:
		var who := FamilyProfile.son_name() if role == "son" else FamilyProfile.father_name()
		var hb := UiKit.button("%s\nSURV LV %d  ·  %d SLOTS" % [who.to_upper(), Heroes.level(role, "survivor"), SurviveRun.MAX_ABILITIES + Heroes.weapon_slots()], Vector2(240, 64))
		hb.add_theme_font_size_override("font_size", 12)
		if App.solo_role == role:
			hb.add_theme_stylebox_override("normal", UiKit.panel(Palette.BRICK, Palette.LEMON))
		hb.pressed.connect(func() -> void:
			App.solo_role = role
			Juice.play("res://assets/audio/ui_click.wav")
			_refresh())
		_heroes.add_child(hb)


func _go() -> void:
	if _map == "":
		return
	Juice.play("res://assets/audio/claim.wav")
	FamilyProfile.data["surv_last_map"] = _map
	FamilyProfile.save()
	App.start_survivor(_map, _agony)
