extends Control

## PLAY GAME opens this: pick who you play, how (solo, couch, online with a
## step-by-step guide for two cities), then one button that names the stage.
## Everything else (clinic, build, locker, awards, dojo, versus) sits below
## dark and locked until the first stage is filed; then the tiles open the
## hideout on that page.

signal closed

const WHO := ["son", "father"]
const BLURB := {
	"son": "Parkour on people. Wall runs, flips, feet first. Fast, light, never where you swung.",
	"father": "Dock-shift boxing. Hooks, elbows, a hammer when it gets personal. Slow, heavy, final.",
}
const STATS := {
	"son": [["SPEED", 5], ["POWER", 2], ["AIR", 5], ["REACH", 3]],
	"father": [["SPEED", 2], ["POWER", 5], ["AIR", 2], ["REACH", 4]],
}
const LOCKED := [
	["clinic", "front_desk", "CLINIC"], ["build", "therapy_couch", "BUILD"],
	["locker", "wardrobe_cage", "LOCKER"], ["awards", "trophy_cabinet", "AWARDS"],
	["dojo", "dojo", "DOJO"], ["versus", "punching_bag", "VERSUS"],
]

var _pick := "son"
var _mode := "solo"
var _cards: Dictionary = {}
var _mode_btns: Dictionary = {}
var _net_row: HBoxContainer
var _go: Button
var _guide: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_pick = App.solo_role if App.solo_role in WHO else "son"
	_mode = "couch" if App.couch else "solo"
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.9)
	# Explicit size: the screen's own rect may not be laid out yet, and the
	# title art (logo, idle fighters) must not show through the sheet.
	dim.position = Vector2(-40, -40)
	dim.size = Vector2(1360, 800)
	add_child(dim)
	var head := UiKit.title("CHOOSE YOUR FIGHTER", 34, Palette.LEMON)
	head.position = Vector2(0, 26)
	head.size = Vector2(1280, 44)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(head)
	for i in WHO.size():
		_cards[WHO[i]] = _card(WHO[i], Vector2(150 + i * 510, 84))
	_build_modes()
	_build_go()
	_build_locked()
	_paint()
	_go.call_deferred("grab_focus")


## One fighter card: his idle loop, his style, four stat pips.
func _card(who: String, at: Vector2) -> Button:
	var b := Button.new()
	b.position = at
	b.size = Vector2(470, 300)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL, Palette.MUTED))
	b.add_theme_stylebox_override("hover", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	b.add_theme_stylebox_override("pressed", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	b.add_theme_stylebox_override("focus", UiKit.panel(Color(0, 0, 0, 0), UiKit.GOLD))
	add_child(b)
	var stage := Control.new()
	stage.position = Vector2(10, 10)
	stage.size = Vector2(200, 280)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stage)
	var sf := SpriteBook.frames(who)
	if sf != null:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = sf
		a.animation = "idle"
		a.play()
		a.texture_filter = SpriteBook.UI_FILTER
		a.scale = Vector2(1.05, 1.05)
		a.position = Vector2(100, 122)
		a.name = "Anim"
		stage.add_child(a)
	var col := VBoxContainer.new()
	col.position = Vector2(222, 18)
	col.size = Vector2(232, 270)
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	var n := UiKit.title("THE SON" if who == "son" else "THE FATHER", 26, Talk.accent(who))
	col.add_child(n)
	var st := Label.new()
	st.text = str(ComboBook.style(who).get("name", "")).to_upper() + " STYLE"
	UiKit.apply_label(st, 13, UiKit.GOLD)
	col.add_child(st)
	var hr := Label.new()
	var rn := Heroes.rarity_name(who)
	hr.text = "LV %d  ·  %s" % [Heroes.level(who), rn.to_upper()]
	UiKit.apply_label(hr, 13, Rarity.color(rn))
	col.add_child(hr)
	var bl := Label.new()
	bl.text = str(BLURB[who])
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(230, 0)
	UiKit.apply_label(bl, 12, Palette.TEXT)
	col.add_child(bl)
	for row in STATS[who]:
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.text = str(row[0])
		l.custom_minimum_size = Vector2(70, 0)
		UiKit.apply_label(l, 12, Palette.MUTED)
		line.add_child(l)
		for k in 5:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(22, 10)
			pip.color = Talk.accent(who) if k < int(row[1]) else Color(1, 1, 1, 0.1)
			line.add_child(pip)
		col.add_child(line)
	b.pressed.connect(func() -> void:
		_pick = who
		Juice.play("res://assets/audio/ui_click.wav")
		_paint()
		_go.grab_focus()
	)
	b.focus_entered.connect(func() -> void:
		_pick = who
		_paint()
	)
	return b


func _build_modes() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(150, 400)
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for pair in [["solo", "SOLO"], ["couch", "COUCH 2P"], ["online", "ONLINE 2P"]]:
		var b := UiKit.button(str(pair[1]), Vector2(220, 42))
		b.pressed.connect(func() -> void:
			_mode = str(pair[0])
			Juice.play("res://assets/audio/ui_click.wav")
			_paint()
		)
		row.add_child(b)
		_mode_btns[pair[0]] = b
	var guide := UiKit.button("HOW TO PLAY ONLINE", Vector2(290, 42))
	guide.pressed.connect(_open_guide)
	row.add_child(guide)
	_net_row = HBoxContainer.new()
	_net_row.position = Vector2(150, 452)
	_net_row.add_theme_constant_override("separation", 10)
	add_child(_net_row)
	var host := UiKit.button("HOST A ROOM", Vector2(220, 40))
	host.pressed.connect(func() -> void:
		_apply()
		get_tree().root.add_child(preload("res://src/ui/host_wait.gd").new())
	)
	var join := UiKit.button("JOIN WITH A CODE", Vector2(240, 40))
	join.pressed.connect(func() -> void:
		_apply()
		get_tree().root.add_child(preload("res://src/ui/join_sheet.gd").new())
	)
	_net_row.add_child(host)
	_net_row.add_child(join)
	var tip := Label.new()
	tip.text = "The host plays the Son, the guest the Father."
	UiKit.apply_label(tip, 12, Palette.MUTED)
	_net_row.add_child(tip)


func _build_go() -> void:
	var stage_id := FamilyProfile.next_run_map()
	_go = UiKit.button("START  ·  %s" % StageCard.title_of(stage_id), Vector2(980, 58))
	_go.position = Vector2(150, 500)
	_go.add_theme_font_override("font", UiKit.title_font())
	_go.add_theme_font_size_override("font_size", 26)
	_go.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
	UiKit.dark_text(_go)
	UiKit.pulse_ready(_go)
	_go.pressed.connect(_start)
	add_child(_go)
	var back := UiKit.button("BACK", Vector2(140, 40))
	back.position = Vector2(1110, 24)
	back.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	add_child(back)


## The rest of the game, dark until the first stage is filed.
func _build_locked() -> void:
	var open := not (FamilyProfile.data.get("maps_filed", []) as Array).is_empty()
	var row := HBoxContainer.new()
	row.position = Vector2(150, 580)
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	for t in LOCKED:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(152, 112)
		tile.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL, Palette.MUTED))
		tile.add_theme_stylebox_override("focus", UiKit.panel(Palette.PANEL, UiKit.GOLD))
		tile.add_theme_stylebox_override("hover", UiKit.panel(Palette.PANEL, UiKit.GOLD))
		var pic := UiKit.portrait(SpriteBook.icon(str(t[1])), Vector2(64, 64))
		pic.position = Vector2(44, 8)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(pic)
		var l := Label.new()
		l.text = str(t[2])
		l.position = Vector2(0, 78)
		l.size = Vector2(152, 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.apply_label(l, 13, Palette.TEXT if open else Palette.MUTED)
		tile.add_child(l)
		if not open:
			tile.modulate = Color(0.32, 0.32, 0.38)
			var lock := PixelIcon.new()
			lock.kind = "lock"
			lock.position = Vector2(60, 26)
			lock.size = Vector2(32, 32)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(lock)
			tile.tooltip_text = "Locked. File %s first." % StageCard.title_of("dock_street")
			tile.pressed.connect(func() -> void:
				Juice.shout("FILE DOCK STREET FIRST")
			)
		else:
			var id := str(t[0])
			tile.pressed.connect(func() -> void:
				_apply()
				if id == "versus":
					App.start_versus()
				elif id == "dojo":
					App.enter_map("camp")
				else:
					App.back_to_hub(id)
			)
		row.add_child(tile)


func _paint() -> void:
	for who in _cards:
		var c := _cards[who] as Button
		var on: bool = who == _pick
		c.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL, UiKit.GOLD if on else Palette.MUTED))
		c.modulate = Color(1, 1, 1) if on else Color(0.42, 0.42, 0.5)
		c.pivot_offset = c.size * 0.5
		c.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(c, "scale", Vector2(1.02, 1.02) if on else Vector2(0.97, 0.97), 0.16)
		var a := c.find_child("Anim", true, false) as AnimatedSprite2D
		if a:
			a.animation = "idle" if on else "idle"
			a.speed_scale = 1.0 if on else 0.0
	for m in _mode_btns:
		var b := _mode_btns[m] as Button
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY if m == _mode else Palette.PANEL, Palette.LEMON if m == _mode else Palette.MUTED))
	_net_row.visible = _mode == "online"
	_go.visible = _mode != "online"
	if _mode == "couch":
		_go.text = "START  ·  %s   (P2 PLAYS THE %s)" % [StageCard.title_of(FamilyProfile.next_run_map()), "FATHER" if _pick == "son" else "SON"]
	else:
		_go.text = "START  ·  %s" % StageCard.title_of(FamilyProfile.next_run_map())


func _apply() -> void:
	App.solo_role = _pick
	App.couch = _mode == "couch"
	App.remote_coop = false
	FamilyProfile.data["named"] = true
	FamilyProfile.save()


func _start() -> void:
	_apply()
	Juice.play("res://assets/audio/ui_click.wav")
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(0, 0, 0, 1), 0.35)
	tw.tween_callback(func() -> void:
		# First night: the prologue and the alley film, then Stage 1's card.
		if not bool(FamilyProfile.data.get("intro_done", false)):
			App.play_intro()
		else:
			App.start_run()
	)


## Two cities, one couch's worth of nonsense: how to connect, step by step.
func _open_guide() -> void:
	if _guide and is_instance_valid(_guide):
		_guide.queue_free()
	_guide = PanelContainer.new()
	_guide.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	_guide.position = Vector2(190, 70)
	_guide.custom_minimum_size = Vector2(900, 560)
	add_child(_guide)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_guide.add_child(col)
	col.add_child(UiKit.title("PLAYING ONLINE FROM TWO CITIES", 26, Palette.LEMON))
	var steps := [
		"1.  Both of you start the game and press PLAY GAME, then ONLINE 2P.",
		"2.  The Son presses HOST A ROOM. A big room code shows up (plus an IP as a backup).",
		"3.  Text the code to the Father (SMS, Discord, anything).",
		"4.  The Father presses JOIN WITH A CODE, types the code and presses CONNECT.",
		"5.  When the Son's screen says FATHER CONNECTED, the stage starts for both of you.",
		"",
		"If the code will not connect:",
		"  -  Check both games are the same version (title screen footer).",
		"  -  Try the IP backup: the Son reads his IP off the host screen, the Father pastes it instead of the code.",
		"  -  On a home router the IP route needs port 24567 (UDP) forwarded to the Son's PC. The room code does not.",
		"  -  A phone hotspot or school wifi can block it; try another network.",
		"",
		"Enemies do not multiply online. The Son's game is the boss of the night; the Father's mirrors it.",
	]
	for s in steps:
		var l := Label.new()
		l.text = s
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(860, 0)
		UiKit.apply_label(l, 14, Palette.TEXT if not s.begins_with("If") else UiKit.GOLD)
		col.add_child(l)
	var ok := UiKit.button("GOT IT", Vector2(200, 44))
	ok.pressed.connect(func() -> void:
		_guide.queue_free()
		if _mode_btns.has("online"):
			(_mode_btns["online"] as Button).grab_focus()
	)
	col.add_child(ok)
	ok.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _guide and is_instance_valid(_guide):
			_guide.queue_free()
		else:
			closed.emit()
			queue_free()
		get_viewport().set_input_as_handled()
