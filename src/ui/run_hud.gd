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
var _stage: Control
var son: Fighter
var father: Fighter
var state: RunState
var _join_grace := 0
var _blink_t := 0.0
var _dad_banner := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stage = PixelStage.attach_canvas(self)
	_fps = Label.new()
	_fps.position = Vector2(12, 6)
	_fps.visible = OS.has_feature("editor")
	UiKit.apply_label(_fps, 12, Palette.LEMON)
	_put(_fps)

	# Player plates: one chunky frame per fighter with the avatar baked into
	# a socket on the left, the name, the hearts, a thin steam line; the lead
	# plate also carries the XP bar and the purse (gold, gems, scrap). Nothing
	# of this is repeated anywhere else on screen.
	_plate(Vector2(10, 8), "son")
	_son = Label.new()
	_son.position = Vector2(118, 12)
	_son.size = Vector2(250, 24)
	_son.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_son, 18, Palette.LEMON)
	_son.add_theme_constant_override("outline_size", 6)
	_son.add_theme_color_override("font_outline_color", UiKit.INK)
	_put(_son)
	_hp_a = _pips_row(Vector2(116, 38), Palette.LEMON)
	_steam_a = _bar(Vector2(118, 68), Palette.LEMON)
	_build_xp(Vector2(118, 82))
	_build_purse(Vector2(116, 98))

	_plate(Vector2(890, 8), "father")
	_dad = Label.new()
	_dad.position = Vector2(998, 12)
	_dad.size = Vector2(250, 24)
	_dad.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_dad, 18, Palette.BRICK)
	_dad.add_theme_constant_override("outline_size", 6)
	_dad.add_theme_color_override("font_outline_color", UiKit.INK)
	_put(_dad)
	_hp_b = _pips_row(Vector2(996, 38), Palette.BRICK)
	_steam_b = _bar(Vector2(998, 68), Palette.BRICK)

	_lives = Label.new()
	_lives.visible = false
	_lives.position = Vector2(300, 690)
	_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lives.size = Vector2(680, 16)
	_lives.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_lives, 13, Palette.TEXT)
	_put(_lives)

	_scrap = Label.new()
	_scrap.visible = false
	_put(_scrap)

	_wanted = Label.new()
	_wanted.position = Vector2(12, 88)
	UiKit.apply_label(_wanted, 12, Palette.BRICK)
	_put(_wanted)

	_act = Label.new()
	_act.visible = false
	_put(_act)

	_score = Label.new()
	_score.visible = false
	_score.position = Vector2(360, 666)
	_score.size = Vector2(560, 22)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(_score, 14, Palette.EDGE)
	_put(_score)

	_boss_wrap = Control.new()
	# Between the two plates, a chunky framed bar (it crossed the plates).
	_boss_wrap.position = Vector2(400, 34)
	_boss_wrap.visible = false
	_put(_boss_wrap)
	var bb := Panel.new()
	var bst := UiKit.panel(Color(0.04, 0.03, 0.05, 0.92), Palette.BRICK)
	bb.add_theme_stylebox_override("panel", bst)
	bb.size = Vector2(480, 22)
	_boss_wrap.add_child(bb)
	_boss_fill = ColorRect.new()
	_boss_fill.position = Vector2(5, 5)
	_boss_fill.size = Vector2(470, 12)
	_boss_fill.color = Palette.BRICK
	_boss_wrap.add_child(_boss_fill)
	_boss_lab = Label.new()
	_boss_lab.position = Vector2(0, -28)
	_boss_lab.size = Vector2(480, 26)
	_boss_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_lab.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_boss_lab, 18, UiKit.GOLD)
	_boss_lab.add_theme_color_override("font_outline_color", UiKit.INK)
	_boss_wrap.add_child(_boss_lab)

	_combo = Label.new()
	_combo.position = Vector2(20, 548)
	_combo.pivot_offset = Vector2(0, 20)
	_combo.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_combo, 34, Palette.LEMON)
	_combo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_combo.add_theme_constant_override("outline_size", 8)
	_put(_combo)
	_rank = Label.new()
	_rank.position = Vector2(22, 590)
	_rank.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_rank.add_theme_constant_override("outline_size", 4)
	UiKit.apply_label(_rank, 12, Palette.LEMON)
	_put(_rank)
	_combo_bg = ColorRect.new()
	_combo_bg.position = Vector2(22, 610)
	_combo_bg.size = Vector2(180, 5)
	_combo_bg.color = Color(0, 0, 0, 0.55)
	_put(_combo_bg)
	_combo_fill = ColorRect.new()
	_combo_fill.position = Vector2(22, 610)
	_combo_fill.size = Vector2(180, 5)
	_combo_fill.color = Palette.LEMON
	_put(_combo_fill)

	_call = Label.new()
	_call.position = Vector2(280, 250)
	_call.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_call.size = Vector2(720, 30)
	_call.pivot_offset = Vector2(360, 15)
	_call.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_call, 22, Palette.LEMON)
	_call.add_theme_constant_override("outline_size", 7)
	_call.add_theme_color_override("font_outline_color", UiKit.INK)
	_put(_call)

	_snap_a = _snap_lab()
	_snap_b = _snap_lab()

	# QUICK BELT: four slots per hero along the bottom corners.
	_belt_a = _belt_row(Vector2(14, 628))
	_belt_b = _belt_row(Vector2(1280 - 14 - 4 * 46, 628))

	_hint = Label.new()
	_hint.position = Vector2(12, 688)
	_hint.size = Vector2(1250, 28)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_hint, 13, Palette.MUTED)
	_put(_hint)
	_place_banners()


var _belt_a: Control
var _belt_b: Control


func _belt_row(pos: Vector2) -> Control:
	var c := Control.new()
	c.position = pos
	c.size = Vector2(4 * 46, 50)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_meta("role", "")
	var icons: Array = []
	for id in QuickBelt.ORDER:
		icons.append(load(str(QuickBelt.ITEMS[id]["icon"])))
	c.draw.connect(func() -> void:
		var role := str(c.get_meta("role", ""))
		if role == "":
			return
		var kb := bool(c.get_meta("kb", true))
		var font := UiKit.title_font()
		for i in 4:
			var id: String = QuickBelt.ORDER[i]
			var n := QuickBelt.count(role, id)
			var rc := Rect2(float(i) * 46.0, 0, 42, 42)
			c.draw_rect(rc, Color(0.04, 0.05, 0.09, 0.82))
			c.draw_rect(rc, (UiKit.GOLD if n > 0 else Color(0.35, 0.36, 0.42)), false, 2.0)
			var tex: Texture2D = icons[i]
			if tex:
				var ts := tex.get_size()
				var k := 30.0 / maxf(ts.x, ts.y)
				var sz := ts * k
				c.draw_texture_rect(tex, Rect2(rc.position + (rc.size - sz) * 0.5, sz), false, Color(1, 1, 1, 1.0 if n > 0 else 0.3))
			c.draw_string_outline(font, rc.position + Vector2(28, 40), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
			c.draw_string(font, rc.position + Vector2(28, 40), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE if n > 0 else Palette.MUTED)
			# Which button: key number, or a d-pad arrow.
			var kp := rc.position + Vector2(8, 9)
			if kb:
				var keys := ["1", "2", "3", "4"] if role == "son" or c == _belt_a else ["7", "8", "9", "0"]
				c.draw_string_outline(font, kp + Vector2(-4, 4), keys[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color.BLACK)
				c.draw_string(font, kp + Vector2(-4, 4), keys[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.LEMON)
			else:
				var d: Vector2 = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN][i]
				var side := Vector2(-d.y, d.x)
				c.draw_colored_polygon(PackedVector2Array([kp + d * 5.0, kp - d * 3.0 + side * 4.0, kp - d * 3.0 - side * 4.0]), Palette.LEMON)
	)
	_put(c)
	return c


func _paint_belt(c: Control, f: Fighter) -> void:
	if c == null:
		return
	c.visible = f != null and get_tree().get_first_node_in_group("clinic_van") == null
	if not c.visible:
		return
	c.set_meta("role", f.role)
	c.set_meta("kb", PadRouter.device_of(f.prefix) < 0)
	c.queue_redraw()


func _put(n: Node) -> void:
	if _stage:
		_stage.add_child(n)
	else:
		add_child(n)


func _place_banners() -> void:
	# Cosmetic banners live on the player plates now.
	pass


func _banner_at(pos: Vector2, role: String) -> void:
	var tint := Cosmetics.tint("banners", FamilyProfile.equipped_cosmetic(role, "banner"))
	var b := ColorRect.new()
	b.color = tint
	b.position = pos
	b.size = Vector2(152, 18)
	_put(b)
	var frame := ColorRect.new()
	frame.color = Cosmetics.tint("frames", FamilyProfile.equipped_cosmetic(role, "frame"))
	frame.position = pos + Vector2(0, 18)
	frame.size = Vector2(152, 4)
	_put(frame)
	if FamilyProfile.has_menu_alert():
		var d := UiKit.new_dot()
		d.position = pos + Vector2(136, 2)
		_put(d)


var _plates := {}
var _faces := {}
var _last_hp := {}


func _plate(pos: Vector2, role: String) -> void:
	var p := Panel.new()
	var accent := Palette.LEMON.darkened(0.2) if role == "son" else Palette.BRICK
	var st := preload("res://src/ui/clinic_featured.gd").card_style(false)
	st.border_color = accent
	st.set_border_width_all(4)
	st.shadow_offset = Vector2(0, 5)
	p.add_theme_stylebox_override("panel", st)
	p.position = pos
	p.size = Vector2(380, 132 if role == "son" else 92)
	p.visible = role == "son"
	_put(p)
	# Avatar socket: a sunk frame the portrait sits in.
	var sock := Panel.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.02, 0.03, 0.06)
	ss.border_color = accent.darkened(0.3)
	ss.set_border_width_all(3)
	ss.border_width_top = 5
	ss.border_width_left = 5
	ss.set_corner_radius_all(4)
	sock.add_theme_stylebox_override("panel", ss)
	sock.position = Vector2(8, 8)
	sock.size = Vector2(92, 76 if role == "father" else 116)
	p.add_child(sock)
	var face := UiKit.portrait(SpriteBook.bust(role), sock.size - Vector2(10, 10))
	face.position = Vector2(13, 13)
	face.size = sock.size - Vector2(10, 10)
	face.pivot_offset = face.size * 0.5
	p.add_child(face)
	# Doom-style: the face in the corner bleeds more as the hearts go.
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://src/shaders/wound.gdshader")
	wm.set_shader_parameter("head", Vector3(face.size.x * 0.5, face.size.y * 0.38, face.size.x * 0.3))
	wm.set_shader_parameter("seed", 3.0 if role == "son" else 9.0)
	wm.set_shader_parameter("holes", PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	face.material = wm
	_faces[role] = face
	_plates[role] = p


var _xp_fill: ColorRect
var _xp_lab: Label
var _gold_l: Label
var _gem_l: Label
var _scrap_l: Label


func _build_xp(pos: Vector2) -> void:
	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.06)
	st.border_color = UiKit.INK
	st.set_border_width_all(2)
	bg.add_theme_stylebox_override("panel", st)
	bg.position = pos - Vector2(2, 2)
	bg.size = Vector2(204, 12)
	_plates["son"].add_child(bg)
	bg.position -= (_plates["son"] as Control).position
	_xp_fill = ColorRect.new()
	_xp_fill.position = Vector2(2, 2)
	_xp_fill.size = Vector2(0, 8)
	_xp_fill.color = UiKit.GOLD
	bg.add_child(_xp_fill)
	_xp_lab = Label.new()
	_xp_lab.position = Vector2(210, -6)
	_xp_lab.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_xp_lab, 12, UiKit.GOLD)
	bg.add_child(_xp_lab)


func _build_purse(pos: Vector2) -> void:
	var row := HBoxContainer.new()
	row.position = pos - (_plates["son"] as Control).position
	row.add_theme_constant_override("separation", 6)
	_plates["son"].add_child(row)
	for pair: Array in [["gold", "_gold_l"], ["gem", "_gem_l"], ["bolt", "_scrap_l"]]:
		var ic := PixelIcon.new()
		ic.kind = str(pair[0])
		ic.custom_minimum_size = Vector2(22, 22)
		row.add_child(ic)
		# Reward coins fly to this icon and the number ticks up as they land.
		if str(pair[0]) == "gold":
			Juice.rewards.register("gold", ic)
		elif str(pair[0]) == "gem":
			Juice.rewards.register("gems", ic)
		var l := Label.new()
		l.custom_minimum_size = Vector2(54, 0)
		l.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(l, 15, Palette.TEXT)
		row.add_child(l)
		set(str(pair[1]), l)
	if not Juice.rewards.landed.is_connected(_on_reward_landed):
		Juice.rewards.landed.connect(_on_reward_landed)


const XP_STEPS := [0, 70, 160, 260, 380, 520]


func _on_reward_landed(_key: String) -> void:
	_paint_purse()


func _paint_purse() -> void:
	if _gold_l == null:
		return
	_gold_l.text = str(int(FamilyProfile.data.get("gold", 0)) - Juice.rewards.pending("gold"))
	_gem_l.text = str(int(FamilyProfile.data.get("gems", 0)) - Juice.rewards.pending("gems"))
	_scrap_l.text = str(state.scrap if state else 0)
	var xp := state.xp if state else 0
	var lv := 0
	while lv < XP_STEPS.size() - 1 and xp >= int(XP_STEPS[lv + 1]):
		lv += 1
	var lo := float(XP_STEPS[lv])
	var hi := float(XP_STEPS[mini(lv + 1, XP_STEPS.size() - 1)])
	var frac := 1.0 if hi <= lo else clampf((float(xp) - lo) / (hi - lo), 0.0, 1.0)
	_xp_fill.size.x = 200.0 * frac
	_xp_lab.text = "XP  LV %d" % (lv + 1)


func _pips_row(pos: Vector2, _color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.position = pos
	row.add_theme_constant_override("separation", 2)
	for i in 8:
		var pip := PixelIcon.new()
		pip.kind = "heart"
		pip.custom_minimum_size = Vector2(28, 28)
		row.add_child(pip)
	_put(row)
	return row


func _bar(pos: Vector2, color: Color) -> ColorRect:
	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.06)
	st.border_color = UiKit.INK
	st.set_border_width_all(2)
	st.set_corner_radius_all(3)
	bg.add_theme_stylebox_override("panel", st)
	bg.position = pos - Vector2(2, 2)
	bg.size = Vector2(244, 8)
	_put(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = Vector2(240, 4)
	fill.color = Color(0.4, 0.75, 1.0)
	fill.set_meta("bg", bg)
	_put(fill)
	var shine := ColorRect.new()
	shine.position = Vector2(0, 0)
	shine.size = Vector2(240, 1)
	shine.color = Color(1, 1, 1, 0.35)
	fill.add_child(shine)
	return fill


func _snap_lab() -> Label:
	var l := Label.new()
	l.text = "SNAP"
	l.visible = false
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	l.z_index = -1
	UiKit.apply_label(l, 22, Color(0.86, 0.92, 1.0))
	_put(l)
	return l


func bind(p_son: Fighter, p_dad: Fighter, p_state: RunState = null) -> void:
	var joining := (p_dad != null and father == null) or (p_son != null and son == null)
	son = p_son
	father = p_dad
	state = p_state
	if joining:
		_join_grace = 18
	if father != null and not _dad_banner:
		_dad_banner = true


func _prompt_line() -> String:
	if get_tree().get_first_node_in_group("skinwalker_film"):
		return "SLIP  ·  LIGHT ADVANCES  ·  PAUSE DOES NOT SKIP"
	if get_tree().get_first_node_in_group("parachute_fall"):
		return "FALL  ·  SPECIAL FP  ·  CLING THE SLAP  ·  PAUSE DOES NOT SKIP"
	if get_tree().get_first_node_in_group("towers") and get_tree().get_first_node_in_group("cling"):
		return "CLING  ·  LIGHT WHEN GREEN"
	if get_tree().get_first_node_in_group("chase_crash"):
		return "RAMP  ·  SLOW-MO  ·  CANAL  ·  CRAWL"
	if get_tree().get_first_node_in_group("clinic_van"):
		return "DRIVE  ·  RAIL 360  ·  SPECIAL SWAP  ·  RAMP AHEAD"
	return ""


func _process(delta: float) -> void:
	if _join_grace > 0:
		_join_grace -= 1
	_blink_t += delta
	_fps.text = "FPS %d" % int(Engine.get_frames_per_second())
	var left: Fighter = son if son else father
	var right: Fighter = father if son else null
	_paint_fighter(_son, _steam_a, _hp_a, _snap_a, left, left != null and left.role == "son")
	_paint_fighter(_dad, _steam_b, _hp_b, _snap_b, right, false)
	_paint_belt(_belt_a, left)
	_paint_belt(_belt_b, right)
	var life_n := 3
	if state:
		life_n = state.lives
	var stamps := ""
	for i in 3:
		stamps += "[  ] " if i < life_n else "[x] "
	var scrap := ""
	var act := ""
	if state:
		scrap = "  ·  SCRAP %d  XP %d%s" % [state.scrap, state.xp, "  LUNCH" if state.lunch > 0 else ""]
		act = "  ·  " + str(App.current_map).replace("_", " ").to_upper()
	_lives.text = "LIVES  " + stamps + scrap + act
	_paint_purse()
	if Juice.combo < 2:
		_combo.text = ""
		_combo.set_meta("n", 0)
		_rank.text = ""
		_combo_fill.size.x = 0
		_combo_bg.visible = false
	else:
		_combo.text = "%d HITS" % Juice.combo
		# Every new hit kicks the counter; colour climbs with the count.
		if int(_combo.get_meta("n", 0)) != Juice.combo:
			_combo.set_meta("n", Juice.combo)
			_combo.scale = Vector2(1.35, 1.35)
			_combo.modulate = Color(1.6, 1.6, 1.6)
			var kt := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			kt.set_ignore_time_scale(true)
			kt.tween_property(_combo, "scale", Vector2.ONE, 0.14)
			kt.parallel().tween_property(_combo, "modulate", Color.WHITE, 0.14)
		var heat := clampf(float(Juice.combo) / 30.0, 0.0, 1.0)
		_combo.add_theme_color_override("font_color", Palette.LEMON.lerp(Color(1.0, 0.3, 0.2), heat))
		_rank.text = Juice.combo_rank() + ("  ·  XP x%.1f" % Juice.xp_mul()) + "  ·  CASH OUT IF THE BAR DIES"
		_combo_bg.visible = true
		_combo_fill.size.x = 180.0 * Juice.combo_frac()
		_combo_fill.color = Palette.LEMON if Juice.combo_frac() > 0.35 else Palette.BRICK
		if str(_combo.get_meta("rank", "")) != Juice.combo_rank() and Juice.combo_rank() != "":
			_combo.set_meta("rank", Juice.combo_rank())
			_combo.scale = Vector2(1.24, 1.24)
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.set_ignore_time_scale(true)
			tw.tween_property(_combo, "scale", Vector2.ONE, 0.18)
			tw.parallel().tween_property(_rank, "modulate", Palette.LEMON, 0.08)
	if _call.text != Juice.callout:
		_call.text = Juice.callout
		# Survivor has its clock and kill count where the call-out sits.
		_call.position.y = 262.0 if SurviveRun.get_run(get_tree()) != null else 250.0
		if Juice.callout != "":
			# Every call-out lands: pops big and settles.
			_call.scale = Vector2(1.5, 1.5)
			var ctw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ctw.set_ignore_time_scale(true)
			ctw.tween_property(_call, "scale", Vector2.ONE, 0.2)
	if state:
		_scrap.text = ""
		var w := ""
		for i in 5:
			w += "I" if i < state.wanted else "."
		_wanted.text = "" if state.wanted == 0 else "WANTED  " + w
		if son and son.revenge_win > 0:
			_wanted.text += "  ·  REVENGE"
		elif father and father.revenge_win > 0:
			_wanted.text += "  ·  REVENGE"
		_act.text = ""
		var horde := get_tree().get_first_node_in_group("horde")
		if horde and horde.has_method("left"):
			_lives.text += "  ·  %ds" % int(horde.left())
		if App.remote_coop:
			_lives.text += "  ·  " + (NetSession.path_name if NetSession.path_name != "" else "REMOTE")
		_score.text = "%s %06d   ·   %s %06d" % [
			FamilyProfile.son_name(), state.score_son, FamilyProfile.father_name(), state.score_dad
		]
		_paint_boss()
	_hint.text = _prompt_line()
	_hint.visible = _hint.text != ""
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
				plates = p.plates
	if best == null:
		_boss_wrap.visible = false
		return
	_boss_wrap.visible = true
	var frac := clampf(float(best_hp) / float(best_max), 0.0, 1.0)
	_boss_fill.size.x = 470.0 * frac
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
		pips.visible = false
		_show_bar(bar, false)
		return
	pips.visible = true
	_show_bar(bar, true)
	var title := FamilyProfile.son_name() if f.role == "son" else FamilyProfile.father_name()
	var lives := ""
	if state and lemon_slot:
		lives = "   LIVES %d" % state.lives
	lab.text = "%s  LV%d%s" % [title.to_upper(), Heroes.level(f.role), lives.replace("   ", "  ")]
	# The weapon in hand and what is left in it.
	if f.pickup != "":
		var wt := str(WeaponBook.spec(f.pickup).get("title", f.pickup)).to_upper()
		# Long names keep their first word in the HUD ("LOUISVILLE LIEN" -> "LOUISVILLE").
		if wt.length() > 10 and wt.contains(" "):
			wt = wt.get_slice(" ", 0)
		if f.pickup in Fighter.GUNS:
			wt += " %d/%d" % [f.pistol_shots, f.gun_reserve]
		elif Arsenal.USES.has(f.pickup):
			wt += " ·%d" % f.melee_uses
		lab.text += "  " + wt
	var extra := f.throw_n > 0 or f.grenades > 0 or f.pickup != ""
	if f.knives > 0:
		lab.text += ("  KNV %d" if extra else "   KNIVES %d") % f.knives
	if f.throw_n > 0 and ThrowLob.KINDS.has(f.throw_kind):
		lab.text += "  %s %d" % [str({"molotov": "MOLOTOV", "flashbang": "FLASH", "teargas": "GAS", "brick": "BRICK"}.get(f.throw_kind, f.throw_kind.to_upper())), f.throw_n]
	if f.grenades > 0:
		lab.text += "  GREN %d" % f.grenades
	# Crowded line: lives as "x3".
	if f.pickup != "" or extra:
		lab.text = lab.text.replace("LIVES ", "x")
	# Never run out of the portrait panel: shrink the line to fit.
	var base := int(lab.get_meta("base_fs", lab.get_theme_font_size("font_size")))
	lab.set_meta("base_fs", base)
	var font := lab.get_theme_font("font")
	var fs := base
	var room := 262.0
	while fs > 8 and font != null and font.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	lab.add_theme_font_size_override("font_size", fs)
	var plate: Variant = _plates.get(_slot_of(f))
	if plate is Control:
		(plate as Control).visible = true
	if lemon_slot:
		lab.add_theme_color_override("font_color", Palette.LEMON)
	else:
		lab.add_theme_color_override("font_color", Palette.BRICK)
	bar.size.x = 240.0 * (f.steam / Fighter.STEAM_MAX)
	_paint_pips(pips, f, lemon_slot)
	_paint_face(f)
	_place_snap(snap, f)


func _paint_pips(row: HBoxContainer, f: Fighter, lemon_slot: bool) -> void:
	var filled := int(round((float(f.hp) / float(maxi(f.max_hp, 1))) * 8.0))
	var billable := int(round(((float(f.hp) + f.copay) / float(maxi(f.max_hp, 1))) * 8.0))
	var on := Palette.LEMON if lemon_slot else Palette.BRICK
	var i := 0
	var low := f.hp <= int(float(f.max_hp) * 0.3)
	for pip in row.get_children():
		var h := pip as PixelIcon
		var want := i >= filled
		if h.dim != want:
			h.dim = want
			h.queue_redraw()
			if want:
				# Losing a heart: it pops.
				h.pivot_offset = Vector2(14, 14)
				h.scale = Vector2(1.5, 1.5)
				h.create_tween().tween_property(h, "scale", Vector2.ONE, 0.2)
		# Low HP: the last hearts beat. Billable (COPAY) hearts glow gold:
		# hit someone to get them back before they fade.
		h.modulate = Color(1, 1, 1, 1.0 if not low or want else 0.6 + 0.4 * absf(sin(_blink_t * 7.0)))
		if want and i < billable:
			h.modulate = Color(1.6, 1.3, 0.4, 0.55 + 0.35 * absf(sin(_blink_t * 9.0)))
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
	if get_tree().get_first_node_in_group("skinwalker_film"):
		Juice.shout("WATCH THE SLIP")
		return
	if get_tree().get_first_node_in_group("parachute_fall"):
		Juice.shout("WATCH THE FALL")
		return
	if get_tree().get_first_node_in_group("chase_crash"):
		Juice.shout("WATCH THE CRASH")
		return
	if _pause and is_instance_valid(_pause):
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		return
	get_tree().paused = true
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_put(layer)
	_pause = layer
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	# A framed card: actions on the left, the night's numbers on the right.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	card.position = Vector2(200, 70)
	card.custom_minimum_size = Vector2(880, 0)
	layer.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	card.add_child(pad)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	pad.add_child(cols)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(400, 0)
	cols.add_child(col)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var t := Label.new()
	t.text = Copy.PAUSE
	UiKit.apply_label(t, 28, Palette.LEMON)
	col.add_child(t)
	var hint := Label.new()
	hint.text = "C ducks. Stick down walks into the street, it does not crouch. Tap BLOCK to PARRY. THROW pipes, tap THROW to CATCH. HEAVY vs a wind-up is a CLASH. Holding a gun: light fires, stick up aims at the head, down at the legs. Pause never skips the Raven Grid crash."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(380, 0)
	UiKit.apply_label(hint, 13, Palette.MUTED)
	col.add_child(hint)
	var r := UiKit.button("RESUME", Vector2(400, 48))
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	r.pressed.connect(_toggle_pause)
	col.add_child(r)
	var ml := UiKit.button("MOVES & COMBOS", Vector2(400, 48))
	ml.process_mode = Node.PROCESS_MODE_ALWAYS
	ml.pressed.connect(func() -> void: _move_list(layer, ml))
	col.add_child(ml)
	var opts := UiKit.button("OPTIONS", Vector2(400, 48))
	opts.process_mode = Node.PROCESS_MODE_ALWAYS
	opts.pressed.connect(func() -> void:
		var sheet := preload("res://src/ui/settings_sheet.gd").new()
		sheet.process_mode = Node.PROCESS_MODE_ALWAYS
		sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(sheet)
		sheet.closed.connect(func() -> void:
			sheet.queue_free()
			if is_instance_valid(opts):
				opts.grab_focus()
		)
	)
	col.add_child(opts)
	var end := UiKit.button("END SESSION", Vector2(400, 48))
	end.process_mode = Node.PROCESS_MODE_ALWAYS
	end.pressed.connect(func() -> void:
		Juice.restore_time()
		get_tree().paused = false
		FamilyProfile.mark_run_finished(false)
		Mixer.play_music("res://assets/audio/music/music_menu.ogg")
		App.back_to_hub("awards")
	)
	col.add_child(end)
	if state:
		var son_n := FamilyProfile.son_name()
		var dad_n := FamilyProfile.father_name()
		# Only what means something right now: one score in solo, and the
		# side tallies once they have moved off zero.
		var duo := App.density_coop or App.remote_coop
		var rows: Array = []
		if duo:
			rows.append({"name": son_n, "value": "%06d" % state.score_son, "color": Palette.LEMON})
			rows.append({"name": dad_n, "value": "%06d" % state.score_dad, "color": Palette.BRICK})
		rows.append({"name": "TABLE", "value": "%06d" % state.score_total, "color": Palette.EDGE})
		rows.append({"name": "LIVES", "value": str(state.lives), "color": Palette.READY})
		rows.append({"name": "XP", "value": str(state.xp), "color": Palette.LEMON})
		for extra in [["SCRAP", state.scrap, Palette.EDGE], ["WANTED", state.wanted, Palette.BRICK], ["HEAT", state.heat, Palette.BRICK], ["CARDS", state.cards.size(), Palette.TEXT]]:
			if int(extra[1]) > 0:
				rows.append({"name": str(extra[0]), "value": str(extra[1]), "color": extra[2]})
		rows.append({"name": "STAGE", "value": StageCard.title_of(App.current_map), "color": Palette.LEMON})
		rows.append({"name": "MODE", "value": ("REMOTE" if App.remote_coop else ("COUCH" if App.density_coop else "SOLO")), "color": Palette.TEXT})
		right.add_child(StatPanel.new(rows))
		var lead := Label.new()
		if not duo:
			lead.text = "Paused. The street waits. The clinic's meter does not."
		elif state.score_son == state.score_dad:
			lead.text = "TIE on the table. The clinic bills you both."
		elif state.score_son > state.score_dad:
			lead.text = "%s is winning the night. %s will workshop that." % [son_n, dad_n]
		else:
			lead.text = "%s is winning the night. The tutoring license winced." % dad_n
		lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lead.custom_minimum_size = Vector2(380, 0)
		UiKit.apply_label(lead, 13, Palette.MUTED)
		right.add_child(lead)
	# LOADOUT: what the suit parts and the weapon in hand do right now.
	var lines: Array[String] = []
	for f: Fighter in [son, father]:
		if f == null or not is_instance_valid(f):
			continue
		var who := FamilyProfile.son_name() if f.role == "son" else FamilyProfile.father_name()
		var parts: Array[String] = []
		for part in Suits.PARTS:
			var sid := f.suit_part(part)
			if sid != "":
				parts.append("[color=#ffd75e]%s[/color] %s" % [str(Suits.part_row(sid, part)["title"]), str(Suits.part_row(sid, part)["perk"])])
		if f.suit_set() != "":
			parts.append("[color=#5effa0]SET[/color] " + str(Suits.LIST[f.suit_set()]["set"]))
		if f.pickup != "":
			var ws := WeaponBook.spec(f.pickup)
			var extra := ("  ·  %d hits left" % f.melee_uses) if Arsenal.USES.has(f.pickup) else ""
			parts.append("[color=#ff8a5e]%s[/color]%s%s" % [str(ws.get("title", f.pickup)).to_upper(), extra, "  ·  ★ MASTERED" if Arsenal.mastered(f.pickup) else ""])
		var rn := Heroes.rarity_name(f.role)
		parts.push_front("[color=#%s]LV %d  ·  %s[/color]" % [Rarity.color(rn).to_html(false), Heroes.level(f.role), rn.to_upper()])
		lines.append("[b]%s[/b]\n%s" % [who.to_upper(), "\n".join(parts)])
	if not lines.is_empty():
		var lo := UiKit.rich("", 520, 12, Palette.TEXT)
		lo.text = "[color=#ffd75e]LOADOUT[/color]\n" + "\n".join(lines)
		right.add_child(lo)
	# BUILD: the night's cards and items with their kind and level.
	if state and not state.cards.is_empty():
		var table: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
		var names := {}
		if table is Array:
			for c in table:
				names[str(c["id"])] = c
		var bits: Array[String] = []
		for id in state.cards:
			var c: Dictionary = names.get(str(id), {})
			var kd := str(c.get("kind", "PASSIVE"))
			var kcol: Color = (PixelCard.KINDS.get(kd, PixelCard.KINDS["PASSIVE"]) as Array)[2]
			var lv := int(state.card_lv.get(id, 1))
			bits.append("[color=#%s]%s[/color] %s%s" % [kcol.to_html(false), kd.left(4), str(c.get("name", id)), "  LV %d" % lv if int(c.get("max_lv", 1)) > 1 else ""])
		var bd := UiKit.rich("", 520, 12, Palette.TEXT)
		bd.text = "[color=#ffd75e]BUILD[/color]\n" + "\n".join(bits)
		right.add_child(bd)
	r.grab_focus()


func _show_bar(bar: ColorRect, on: bool) -> void:
	bar.visible = on
	var bg: Variant = bar.get_meta("bg", null)
	if bg is Control:
		(bg as Control).visible = on


## The corner portrait: blood builds up with damage, it flinches and flashes
## on every hit, and goes grey when down.
## Solo Father plays in the left (first) plate: his face goes into it and
## the right plate stays hidden.
func _slot_of(f: Fighter) -> String:
	if son == null and f == father:
		var face: Variant = _faces.get("son")
		if face is TextureRect and not (face as TextureRect).has_meta("father"):
			(face as TextureRect).texture = SpriteBook.bust("father")
			(face as TextureRect).set_meta("father", true)
		return "son"
	return f.role


func _paint_face(f: Fighter) -> void:
	var face: Variant = _faces.get(_slot_of(f))
	if not (face is TextureRect):
		return
	var tr := face as TextureRect
	var hurt := 1.0 - float(f.hp) / float(maxi(f.max_hp, 1))
	var m := tr.material as ShaderMaterial
	if m and not FamilyProfile.less_gore():
		m.set_shader_parameter("wound", clampf(hurt * 1.2, 0.0, 1.0))
		m.set_shader_parameter("splat", clampf(hurt * 0.8, 0.0, 1.0))
	var was := int(_last_hp.get(f.role, f.hp))
	_last_hp[f.role] = f.hp
	if f.hp < was:
		tr.modulate = Color(1.6, 0.5, 0.45)
		var tw := tr.create_tween()
		tw.tween_property(tr, "position:x", 8.0 + 4.0, 0.03)
		tw.tween_property(tr, "position:x", 8.0 - 3.0, 0.04)
		tw.tween_property(tr, "position:x", 8.0, 0.05)
		tw.parallel().tween_property(tr, "modulate", Color.WHITE, 0.25)
	if f.downed:
		tr.modulate = Color(0.45, 0.4, 0.42)
	elif f.hp >= was and tr.modulate == Color(0.45, 0.4, 0.42):
		tr.modulate = Color.WHITE


## Pause > MOVES & COMBOS: what each button does right now (the hero's own
## loadout) and every combo they know, with the buttons to press.
func _move_list(layer: Control, back_to: Control) -> void:
	var pad := not Input.get_connected_joypads().is_empty()
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(sheet)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(UiKit.GOLD, 0.4))
	card.position = Vector2(60, 36)
	card.size = Vector2(1160, 648)
	sheet.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := HBoxContainer.new()
	var t := UiKit.title("MOVES & COMBOS", 26, UiKit.GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var back := UiKit.button("BACK", Vector2(120, 40))
	back.process_mode = Node.PROCESS_MODE_ALWAYS
	back.pressed.connect(func() -> void:
		sheet.queue_free()
		if is_instance_valid(back_to):
			back_to.grab_focus())
	head.add_child(back)
	v.add_child(head)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)
	var roles: Array[String] = []
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not roles.has((n as Fighter).role):
			roles.append((n as Fighter).role)
	if roles.is_empty():
		roles = ["son"]
	for role in roles:
		var sc := ScrollContainer.new()
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		cols.add_child(sc)
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 4)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(c)
		var who := FamilyProfile.son_name() if role == "son" else FamilyProfile.father_name()
		c.add_child(UiKit.title(who.to_upper(), 18, Palette.LEMON if role == "son" else Palette.BRICK))
		c.add_child(UiKit.title("BUTTONS", 13, Palette.EDGE))
		var lo := Moves.loadout(role)
		for slot: String in Moves.SLOTS:
			var mv := Moves.row(str(lo.get(slot, Moves.DEFAULT.get(slot, ""))))
			var tok: String = {"L1": "L", "L2": "L", "L3": "L", "H": "H", "F+H": "F+H", "U+H": "U+H", "STR": "H", "AIR_L": "L", "AIR_H": "H"}[slot]
			var key := ComboBook.step_label(str(tok), pad)
			var pre: String = {"L2": "2ND ", "L3": "3RD ", "STR": "AFTER 2 LIGHTS ", "AIR_L": "IN THE AIR ", "AIR_H": "IN THE AIR "}.get(slot, "")
			c.add_child(_row_line("%s%s" % [pre, key], str(mv.get("title", mv.get("id", "?"))).to_upper(), Palette.TEXT))
		c.add_child(UiKit.title("COMBOS", 13, Palette.EDGE))
		var known := ComboBook.learned(role)
		if known.is_empty():
			c.add_child(_row_line("-", "Learn combos in the DOJO", Palette.MUTED))
		for cb: Dictionary in known:
			c.add_child(_row_line(ComboBook.steps_label(cb, pad), "%s  ·  %d" % [str(cb.get("title", cb["id"])), int(cb.get("dmg", 0))], Rarity.color(str(cb.get("rarity", "common")))))
	back.grab_focus()


func _row_line(keys: String, what: String, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var k := Label.new()
	k.text = keys
	k.custom_minimum_size = Vector2(250, 0)
	k.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(k, 13, UiKit.GOLD)
	h.add_child(k)
	var w := Label.new()
	w.text = what
	w.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(w, 13, col)
	h.add_child(w)
	return h
