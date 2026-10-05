class_name ResultsSheet
extends CanvasLayer

## After-act pinball recap + account XP. Death uses the same sheet, meaner.

var headline := "FILED"
var sub := ""
var win := true
var gate := false
var next_id := ""
var next_label := "NEXT"
var fail_gold := 0
## Lost runs: how it ended ("GOT SHOT WITH A 9MM BY SHIFT LEAD").
var death_line := ""
var lock_line := ""
var state: RunState
var _xp_bar: ProgressBar
var _xp_lab: Label


## Pixel reward screen: gold title on a ribbon, rank stars that slam in, the
## two of them with their scores counting up (crown on the winner), reward
## tiles, highlight chips, the account XP bar filling (LEVEL UP burst), and
## big 3D buttons.
func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var ui := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.size = Vector2(1280, 720)
	ui.add_child(dim)
	var accent := UiKit.GOLD if win else Palette.BRICK
	var card := PanelContainer.new()
	var cs := preload("res://src/ui/clinic_featured.gd").card_style(true)
	cs.border_color = accent
	cs.shadow_color = Color(accent.r, accent.g, accent.b, 0.4)
	cs.content_margin_left = 34
	cs.content_margin_right = 34
	cs.content_margin_top = 20
	cs.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", cs)
	card.position = Vector2(170, 34)
	card.custom_minimum_size = Vector2(940, 0)
	card.resized.connect(func() -> void:
		card.position = Vector2((1280.0 - card.size.x) * 0.5, (720.0 - card.size.y) * 0.5).round()
	)
	ui.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var t := UiKit.title(headline, 46, Palette.EDGE if win else Palette.BRICK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	if not win:
		_death_plate(col)
	var s := Label.new()
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 17, Palette.TEXT)
	col.add_child(s)
	var son_n := FamilyProfile.son_name()
	var dad_n := FamilyProfile.father_name()
	var son_s := 0
	var dad_s := 0
	var total := 0
	if state:
		son_s = state.score_son
		dad_s = state.score_dad
		total = state.score_total
	# Rank stars.
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 14)
	col.add_child(stars)
	var n_stars := 0
	if win:
		n_stars = 1 + int(total >= 1500) + int(total >= 4000)
	for k in 3:
		var st := PixelIcon.new()
		st.kind = "star"
		st.dim = k >= n_stars
		st.custom_minimum_size = Vector2(58, 58)
		st.pivot_offset = Vector2(29, 29)
		st.scale = Vector2.ZERO
		stars.add_child(st)
		var tw := st.create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.25 + 0.22 * float(k))
		tw.tween_property(st, "scale", Vector2.ONE, 0.25)
		if k < n_stars:
			tw.tween_callback(func() -> void:
				Juice.play("res://assets/audio/claim.wav")
				Juice.pulse_shake(2.5)
			)
	# The two of them.
	var duo := HBoxContainer.new()
	duo.alignment = BoxContainer.ALIGNMENT_CENTER
	duo.add_theme_constant_override("separation", 40)
	col.add_child(duo)
	duo.add_child(_player_tile("son", son_n, son_s, son_s >= dad_s and son_s > 0, Palette.LEMON))
	var vs := UiKit.title("VS", 28, Palette.MUTED)
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	duo.add_child(vs)
	duo.add_child(_player_tile("father", dad_n, dad_s, dad_s > son_s, Palette.BRICK))
	var grant := _grant_xp(total)
	# Reward tiles.
	var rewards := HBoxContainer.new()
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.add_theme_constant_override("separation", 14)
	col.add_child(rewards)
	rewards.add_child(_reward("star", "SCORE", "%d" % total))
	rewards.add_child(_reward("bolt", "XP", "+%d" % int(grant.get("gained", 0))))
	if state:
		rewards.add_child(_reward("gold", "SCRAP", "+%d" % state.scrap))
	if not win and fail_gold > 0:
		rewards.add_child(_reward("gold", "GOLD", "+%d" % fail_gold))
	rewards.add_child(_reward("fist", "SMASH", str(int(FamilyProfile.data.get("smash_kills", 0)))))
	rewards.add_child(_reward("shield", "PARRY", str(int(FamilyProfile.data.get("parries", 0)))))
	# Account XP.
	var xp_row := HBoxContainer.new()
	xp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	xp_row.add_theme_constant_override("separation", 12)
	col.add_child(xp_row)
	_xp_lab = UiKit.title("LV %d" % int(grant.get("level", 1)), 26, Palette.EDGE)
	xp_row.add_child(_xp_lab)
	_xp_bar = UiKit.glow_bar(0.0, UiKit.GOLD, Vector2(560, 20))
	_xp_bar.max_value = float(grant.get("need", 100))
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_row.add_child(_xp_bar)
	var xp_line := Label.new()
	xp_line.text = "%d / %d" % [int(grant.get("xp", 0)), int(grant.get("need", 100))]
	xp_line.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(xp_line, 15, Palette.TEXT)
	xp_row.add_child(xp_line)
	# Buttons.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	if gate and next_id != "":
		var enter_lock := PowerBook.lock(next_id, "enter")
		if lock_line == "" and not enter_lock.is_empty():
			lock_line = PowerBook.line(enter_lock)
		if lock_line != "":
			var why := Label.new()
			why.text = lock_line
			why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiKit.apply_label(why, 15, Palette.BRICK)
			col.add_child(why)
		else:
			var nxt := UiKit.button(next_label, Vector2(330, 60))
			nxt.add_theme_font_override("font", UiKit.title_font())
			nxt.add_theme_font_size_override("font_size", 22)
			nxt.process_mode = Node.PROCESS_MODE_ALWAYS
			nxt.pressed.connect(_go_next)
			row.add_child(nxt)
			nxt.call_deferred("grab_focus")
	var b := UiKit.button("BACK TO THE HIDEOUT", Vector2(300, 60))
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(_go_hub)
	row.add_child(b)
	if not gate or lock_line != "":
		b.call_deferred("grab_focus")
	UiKit.pop_in(card)
	Juice.pulse_shake(8.0 if win else 5.0)
	_tween_xp(float(grant.get("xp", 0)), int(grant.get("dings", 0)))
	if state and state.score_total > 0 and state.score_total == int(FamilyProfile.data.get("high_score", 0)):
		Juice.unlock_logo("HIGH TABLE", "The clipboard wrote it in gold ink.")
		Juice.shout("HIGH TABLE")


func _player_tile(who: String, name_text: String, score: int, crown: bool, accent: Color) -> Control:
	var box := PanelContainer.new()
	var st := UiKit.panel(UiKit.NAVY_HI, accent)
	st.content_margin_left = 16
	st.content_margin_right = 16
	box.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(UiKit.portrait(SpriteBook.bust(who), Vector2(70, 80)))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	var n := UiKit.title(name_text + ("  ♛" if crown else ""), 20, accent)
	col.add_child(n)
	var v := UiKit.title("0", 34, Palette.TEXT)
	col.add_child(v)
	var tw := v.create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.6)
	tw.tween_method(func(x: float) -> void: v.text = "%d" % int(x), 0.0, float(score), 0.9)
	return box


func _reward(icon: String, label: String, value: String) -> Control:
	var box := PanelContainer.new()
	var st := UiKit.panel(UiKit.NAVY, UiKit.RIM)
	st.content_margin_left = 12
	st.content_margin_right = 12
	box.add_theme_stylebox_override("panel", st)
	box.custom_minimum_size = Vector2(130, 0)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	box.add_child(col)
	var ic := PixelIcon.new()
	ic.kind = icon
	ic.custom_minimum_size = Vector2(34, 34)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(ic)
	var v := UiKit.title(value, 22, Palette.TEXT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(v)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 12, UiKit.GOLD)
	col.add_child(l)
	return box


func _winner(son_s: int, dad_s: int, son_n: String, dad_n: String) -> String:
	if son_s == dad_s:
		return "TIE"
	return son_n if son_s > dad_s else dad_n


func _grant_xp(total: int) -> Dictionary:
	var n := maxi(8, int(total / 20.0) + (90 if win else 18))
	if gate:
		n = maxi(8, int(total / 28.0) + 40)
	return FamilyProfile.grant_account_xp(n)


func _tween_xp(xp: float, dings: int) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_xp_bar, "value", xp, 0.55)
	if dings > 0:
		tw.tween_callback(func() -> void:
			Juice.unlock_logo("ACCOUNT LEVEL UP", "Growth. Billed. The fridge stays.")
			Juice.toast("achievement", "LEVEL UP", "The clipboard added a zero.")
			if _xp_lab:
				_xp_lab.text = "LV %d" % int(FamilyProfile.data.get("account_level", 1))
		)


func _go_next() -> void:
	var enter_lock := PowerBook.lock(next_id, "enter")
	if not enter_lock.is_empty():
		Juice.toast("challenge", "LOCKED", PowerBook.line(enter_lock))
		return
	get_tree().paused = false
	if state:
		App.advance(next_id, state)


func _go_hub() -> void:
	get_tree().paused = false
	if win and gate:
		FamilyProfile.mark_run_finished(true)
		if App.is_solo_density():
			FamilyProfile.mark_solo_clear()
		FamilyProfile.push_log(headline, sub)
	Mixer.play_music("res://assets/audio/music/music_menu.ogg")
	if App.remote_coop:
		NetSession.shutdown()
	App.back_to_hub("awards" if win else "clinic")


## A red plate with a skull-ish cross under the title: the cause of death.
func _death_plate(col: VBoxContainer) -> void:
	var line := death_line
	if line == "":
		line = DeathCause.for_run(get_tree())
	if line == "":
		return
	var plate := PanelContainer.new()
	var st := UiKit.panel(Color(0.18, 0.03, 0.04), Palette.BRICK)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	plate.add_theme_stylebox_override("panel", st)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	plate.add_child(row)
	var ic := PixelIcon.new()
	ic.kind = "cross"
	ic.custom_minimum_size = Vector2(30, 30)
	row.add_child(ic)
	var l := Label.new()
	l.text = line
	l.add_theme_font_override("font", UiKit.title_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1.0, 0.82, 0.78))
	l.add_theme_color_override("font_outline_color", UiKit.INK)
	l.add_theme_constant_override("outline_size", 6)
	row.add_child(l)
	col.add_child(plate)
	plate.pivot_offset = Vector2(200, 20)
	plate.scale = Vector2(1.4, 1.4)
	plate.modulate.a = 0.0
	var tw := plate.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(plate, "scale", Vector2.ONE, 0.25)
	tw.parallel().tween_property(plate, "modulate:a", 1.0, 0.15)
