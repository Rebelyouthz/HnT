extends CanvasLayer

var _fps: Label
var _son: Label
var _dad: Label
var _lives: Label
var _call: Label
var _combo: Label
var _rank: Label
var _combo_bg: ColorRect
var _combo_fill: ColorRect
var _hint: Label
var _snap_a: Label
var _snap_b: Label
var _steam_a: ColorRect
var _steam_b: ColorRect
var _hp_a: HBoxContainer
var _hp_b: HBoxContainer
var _scrap: Label
var _wanted: Label
var _act: Label
var _score: Label
var _boss_wrap: Control
var _boss_fill: ColorRect
var _boss_lab: Label
var _pause: Control
var son: Fighter
var father: Fighter
var state: RunState
var _join_grace := 0
var _blink_t := 0.0
var _dad_banner := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fps = Label.new()
	_fps.position = Vector2(12, 6)
	UiKit.apply_label(_fps, 14, Palette.LEMON)
	add_child(_fps)

	_son = Label.new()
	_son.position = Vector2(12, 28)
	UiKit.apply_label(_son, 15, Palette.LEMON)
	add_child(_son)
	_hp_a = _pips_row(Vector2(12, 68), Palette.LEMON)
	_steam_a = _bar(Vector2(12, 84), Palette.LEMON)

	_dad = Label.new()
	_dad.position = Vector2(900, 28)
	_dad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dad.size = Vector2(368, 48)
	UiKit.apply_label(_dad, 15, Palette.BRICK)
	add_child(_dad)
	_hp_b = _pips_row(Vector2(1048, 68), Palette.BRICK)
	_steam_b = _bar(Vector2(1048, 84), Palette.BRICK)

	_lives = Label.new()
	_lives.position = Vector2(500, 8)
	_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lives.size = Vector2(280, 24)
	UiKit.apply_label(_lives, 16, Palette.TEXT)
	add_child(_lives)

	_scrap = Label.new()
	_scrap.position = Vector2(500, 56)
	_scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scrap.size = Vector2(280, 20)
	UiKit.apply_label(_scrap, 14, Palette.EDGE)
	add_child(_scrap)

	_wanted = Label.new()
	_wanted.position = Vector2(820, 8)
	UiKit.apply_label(_wanted, 13, Palette.BRICK)
	add_child(_wanted)

	_act = Label.new()
	_act.position = Vector2(500, 32)
	_act.size = Vector2(280, 20)
	_act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_act, 12, Palette.MUTED)
	add_child(_act)

	_score = Label.new()
	_score.position = Vector2(360, 688)
	_score.size = Vector2(560, 22)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_score, 14, Palette.EDGE)
	add_child(_score)

	_boss_wrap = Control.new()
	_boss_wrap.position = Vector2(280, 52)
	_boss_wrap.visible = false
	add_child(_boss_wrap)
	var bb := ColorRect.new()
	bb.size = Vector2(720, 14)
	bb.color = Color(0, 0, 0, 0.7)
	_boss_wrap.add_child(bb)
	_boss_fill = ColorRect.new()
	_boss_fill.position = Vector2(2, 2)
	_boss_fill.size = Vector2(716, 10)
	_boss_fill.color = Palette.BRICK
	_boss_wrap.add_child(_boss_fill)
	_boss_lab = Label.new()
	_boss_lab.position = Vector2(0, -20)
	_boss_lab.size = Vector2(720, 20)
	_boss_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_boss_lab, 13, Palette.LEMON)
	_boss_wrap.add_child(_boss_lab)

	_combo = Label.new()
	_combo.position = Vector2(12, 98)
	UiKit.apply_label(_combo, 20, Palette.EDGE)
	add_child(_combo)
	_rank = Label.new()
	_rank.position = Vector2(12, 120)
	UiKit.apply_label(_rank, 13, Palette.LEMON)
	add_child(_rank)
	_combo_bg = ColorRect.new()
	_combo_bg.position = Vector2(12, 142)
	_combo_bg.size = Vector2(180, 6)
	_combo_bg.color = Color(0, 0, 0, 0.55)
	add_child(_combo_bg)
	_combo_fill = ColorRect.new()
	_combo_fill.position = Vector2(12, 142)
	_combo_fill.size = Vector2(180, 6)
	_combo_fill.color = Palette.LEMON
	add_child(_combo_fill)

	_call = Label.new()
	_call.position = Vector2(280, 96)
	_call.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_call.size = Vector2(720, 40)
	UiKit.apply_label(_call, 26, Palette.LEMON)
	add_child(_call)

	_snap_a = _snap_lab()
	_snap_b = _snap_lab()

	_hint = Label.new()
	_hint.position = Vector2(12, 668)
	_hint.size = Vector2(1250, 44)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.MUTED)
	_hint.text = _prompt_line()
	add_child(_hint)
	_place_banners()


func _place_banners() -> void:
	_banner_at(Vector2(0, 0), "son")
	if App.two_bodies():
		_banner_at(Vector2(1128, 0), "father")


func _banner_at(pos: Vector2, role: String) -> void:
	var tint := Cosmetics.tint("banners", FamilyProfile.equipped_cosmetic(role, "banner"))
	var b := ColorRect.new()
	b.color = tint
	b.position = pos
	b.size = Vector2(152, 18)
	add_child(b)
	var frame := ColorRect.new()
	frame.color = Cosmetics.tint("frames", FamilyProfile.equipped_cosmetic(role, "frame"))
	frame.position = pos + Vector2(0, 18)
	frame.size = Vector2(152, 4)
	add_child(frame)
	if FamilyProfile.has_menu_alert():
		var d := UiKit.new_dot()
		d.position = pos + Vector2(136, 2)
		add_child(d)


func _pips_row(pos: Vector2, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.position = pos
	row.add_theme_constant_override("separation", 3)
	for i in 8:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(24, 8)
		pip.color = color
		row.add_child(pip)
	add_child(row)
	return row


func _bar(pos: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = Vector2(220, 8)
	bg.color = Color(0, 0, 0, 0.55)
	add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = Vector2(220, 8)
	fill.color = color
	add_child(fill)
	return fill


func _snap_lab() -> Label:
	var l := Label.new()
	l.text = "SNAP"
	l.visible = false
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	l.z_index = -1
	UiKit.apply_label(l, 22, Color(0.86, 0.92, 1.0))
	add_child(l)
	return l


func bind(p_son: Fighter, p_dad: Fighter, p_state: RunState = null) -> void:
	var joining := (p_dad != null and father == null) or (p_son != null and son == null)
	son = p_son
	father = p_dad
	state = p_state
	if joining:
		_join_grace = 18
	if father != null and not _dad_banner:
		_banner_at(Vector2(1128, 0), "father")
		_dad_banner = true


func _prompt_line() -> String:
	if son == null or father == null:
		return PadRouter.p1_prompt() + "  ·  " + Copy.JOIN_HINT
	return PadRouter.p1_prompt() + "  ·  " + PadRouter.p2_prompt()


func _process(delta: float) -> void:
	if _join_grace > 0:
		_join_grace -= 1
	_blink_t += delta
	_fps.text = "FPS %d" % int(Engine.get_frames_per_second())
	var left: Fighter = son if son else father
	var right: Fighter = father if son else null
	_paint_fighter(_son, _steam_a, _hp_a, _snap_a, left, left != null and left.role == "son")
	_paint_fighter(_dad, _steam_b, _hp_b, _snap_b, right, false)
	var life_n := 3
	if state:
		life_n = state.lives
	var stamps := ""
	for i in 3:
		stamps += "[  ] " if i < life_n else "[x] "
	_lives.text = "LIVES  " + stamps
	if Juice.combo < 2:
		_combo.text = ""
		_rank.text = ""
		_combo_fill.size.x = 0
		_combo_bg.visible = false
	else:
		_combo.text = "%d HIT" % Juice.combo
		_rank.text = Juice.combo_rank() + "  ·  CASH OUT IF THE BAR DIES"
		_combo_bg.visible = true
		_combo_fill.size.x = 180.0 * Juice.combo_frac()
		_combo_fill.color = Palette.LEMON if Juice.combo_frac() > 0.35 else Palette.BRICK
	_call.text = Juice.callout
	if state:
		_scrap.text = "SCRAP  %d   XP  %d" % [state.scrap, state.xp]
		var w := ""
		for i in 5:
			w += "I" if i < state.wanted else "."
		_wanted.text = "" if state.wanted == 0 else "WANTED  " + w
		_act.text = str(App.current_map).replace("_", " ").to_upper()
		var horde := get_tree().get_first_node_in_group("horde")
		if horde and horde.has_method("left"):
			_act.text += "  ·  %ds" % int(horde.left())
		if App.remote_coop:
			_act.text += "  ·  " + (NetSession.path_name if NetSession.path_name != "" else "REMOTE")
		_score.text = "%s %06d   ·   %s %06d" % [
			FamilyProfile.son_name(), state.score_son, FamilyProfile.father_name(), state.score_dad
		]
		_paint_boss()
	_hint.text = _prompt_line()
	if _join_grace > 0:
		return
	if Input.is_action_just_pressed("p1_pause"):
		_toggle_pause()
	elif Input.is_action_just_pressed("p2_pause") and father != null and son != null:
		_toggle_pause()


func _paint_boss() -> void:
	if _boss_wrap == null:
		return
	var best: Node2D = null
	var best_hp := 0
	var best_max := 1
	var best_name := ""
	var plates := -1
	for n in get_tree().get_nodes_in_group("act_boss"):
		if not is_instance_valid(n):
			continue
		if n is Punk:
			var p: Punk = n
			if p.hp > best_hp:
				best = p
				best_hp = p.hp
				best_max = maxi(p.max_hp, 1)
				best_name = p.title
				if p is FamilyPlan:
					plates = (p as FamilyPlan).plates
	if best == null:
		_boss_wrap.visible = false
		return
	_boss_wrap.visible = true
	var frac := clampf(float(best_hp) / float(best_max), 0.0, 1.0)
	_boss_fill.size.x = 716.0 * frac
	_boss_fill.color = Palette.EDGE if plates > 0 else (Palette.BRICK if frac < 0.33 else Palette.LEMON)
	if plates >= 0:
		_boss_lab.text = "%s  ·  ARMOR %d  ·  %d" % [best_name.to_upper(), plates, best_hp]
	else:
		_boss_lab.text = "%s  ·  %d / %d" % [best_name.to_upper(), best_hp, best_max]


func _paint_fighter(lab: Label, bar: ColorRect, pips: HBoxContainer, snap: Label, f: Fighter, lemon_slot: bool) -> void:
	if f == null or not is_instance_valid(f):
		lab.text = ""
		bar.size.x = 0
		snap.visible = false
		for pip in pips.get_children():
			(pip as ColorRect).color = Color(0.12, 0.12, 0.14, 0.6)
		return
	var kit := ("BATWING %d" % f.ammo) if f.role == "son" else ("WEB SHOT %d" % f.ammo)
	var title := FamilyProfile.son_name() if f.role == "son" else FamilyProfile.father_name()
	var role := "THE SON" if f.role == "son" else "THE FATHER"
	lab.text = "%s\n%s   STEAM %d  %s" % [title, role, int(f.steam), kit]
	if lemon_slot:
		lab.add_theme_color_override("font_color", Palette.LEMON)
	else:
		lab.add_theme_color_override("font_color", Palette.BRICK)
	bar.size.x = 220.0 * (f.steam / Fighter.STEAM_MAX)
	_paint_pips(pips, f, lemon_slot)
	_place_snap(snap, f)


func _paint_pips(row: HBoxContainer, f: Fighter, lemon_slot: bool) -> void:
	var filled := int(round((float(f.hp) / float(maxi(f.max_hp, 1))) * 8.0))
	var on := Palette.LEMON if lemon_slot else Palette.BRICK
	var i := 0
	for pip in row.get_children():
		var r := pip as ColorRect
		if i < filled:
			r.color = on if f.hp > int(float(f.max_hp) * 0.3) else Palette.BADGE
		else:
			r.color = Color(0.12, 0.12, 0.14, 0.65)
		i += 1


func _place_snap(lab: Label, f: Fighter) -> void:
	var ally_near := _ally_holding(f)
	if f.downed:
		lab.visible = true
		lab.text = "HOLD" if ally_near else "DOWN"
		lab.modulate.a = 0.4 + 0.6 * absf(sin(_blink_t * 8.0))
	elif f.snap_ready:
		lab.visible = true
		lab.text = "SNAP"
		lab.modulate.a = 0.45 + 0.55 * absf(sin(_blink_t * 7.0))
	else:
		lab.visible = false
		return
	var cam := get_viewport().get_camera_2d()
	var gp := f.global_position + Vector2(0, -110)
	if cam:
		lab.position = cam.get_screen_transform() * gp + Vector2(-28, 0)
	else:
		lab.position = gp


func _ally_holding(f: Fighter) -> bool:
	if not f.downed:
		return false
	for n in get_tree().get_nodes_in_group("players"):
		if n == f or not (n is Fighter):
			continue
		var other: Fighter = n
		if other.downed:
			continue
		if other.global_position.distance_to(f.global_position) > 58.0:
			continue
		if other._pressed("snap"):
			return true
	return false


func _toggle_pause() -> void:
	if _pause and is_instance_valid(_pause):
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		return
	get_tree().paused = true
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_pause = layer
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var col := VBoxContainer.new()
	col.position = Vector2(440, 88)
	col.add_theme_constant_override("separation", 10)
	layer.add_child(col)
	var t := Label.new()
	t.text = Copy.PAUSE
	UiKit.apply_label(t, 28, Palette.LEMON)
	col.add_child(t)
	var r := UiKit.button("RESUME", Vector2(220, 48))
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	r.pressed.connect(_toggle_pause)
	col.add_child(r)
	var end := UiKit.button("END SESSION", Vector2(220, 48))
	end.process_mode = Node.PROCESS_MODE_ALWAYS
	end.pressed.connect(func() -> void:
		get_tree().paused = false
		FamilyProfile.mark_run_finished(false)
		Mixer.play_music("res://assets/audio/music_clinic.wav")
		App.back_to_hub("awards")
	)
	col.add_child(end)
	if state:
		var son_n := FamilyProfile.son_name()
		var dad_n := FamilyProfile.father_name()
		col.add_child(StatPanel.new([
			{"name": son_n, "value": "%06d" % state.score_son, "color": Palette.LEMON},
			{"name": dad_n, "value": "%06d" % state.score_dad, "color": Palette.BRICK},
			{"name": "TABLE", "value": "%06d" % state.score_total, "color": Palette.EDGE},
			{"name": "LIVES", "value": str(state.lives), "color": Palette.READY},
			{"name": "SCRAP", "value": str(state.scrap), "color": Palette.EDGE},
			{"name": "XP", "value": str(state.xp), "color": Palette.LEMON},
			{"name": "WANTED", "value": str(state.wanted), "color": Palette.BRICK},
			{"name": "CARDS", "value": str(state.cards.size()), "color": Palette.TEXT},
			{"name": "COMBO", "value": str(Juice.combo), "color": Palette.EDGE},
			{"name": "ACT", "value": str(App.current_map).replace("_", " ").to_upper(), "color": Palette.LEMON},
			{"name": "MODE", "value": ("REMOTE" if App.remote_coop else ("COUCH" if App.density_coop else "SOLO")), "color": Palette.TEXT},
			{"name": "ACCOUNT", "value": "LV %d" % int(FamilyProfile.data.get("account_level", 1)), "color": Palette.TEXT}
		]))
		var lead := Label.new()
		if state.score_son == state.score_dad:
			lead.text = "TIE on the table. The clinic bills you both."
		elif state.score_son > state.score_dad:
			lead.text = "%s is winning the night. %s will workshop that." % [son_n, dad_n]
		else:
			lead.text = "%s is winning the night. The tutoring license winced." % dad_n
		lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lead.custom_minimum_size = Vector2(400, 0)
		UiKit.apply_label(lead, 13, Palette.MUTED)
		col.add_child(lead)
	r.grab_focus()
