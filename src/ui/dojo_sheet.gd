extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -400
	card.offset_right = 400
	card.offset_top = -280
	card.offset_bottom = 280
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(780, 540)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(UiKit.portrait(SpriteBook.icon("dojo"), Vector2(56, 56)))
	var h := Label.new()
	h.text = "MARTIAL ARTS SCHOOL"
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Learn, upgrade, master. Rank 3 pins a shaolin badge. The Son already bills for this."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 13, Palette.MUTED)
	col.add_child(s)
	var tut_row := HBoxContainer.new()
	tut_row.add_theme_constant_override("separation", 10)
	for who in ["son", "father"]:
		var tb := UiKit.button("TUTORIAL AS %s  ·  %d LESSONS" % ["THE SON" if who == "son" else "THE FATHER", DojoSchool.LESSONS.size()], Vector2(370, 44))
		tb.pressed.connect(func() -> void:
			FamilyProfile.data["school"] = []
			App.set_meta("dojo_school", true)
			_practice(who)
		)
		tut_row.add_child(tb)
	col.add_child(tut_row)
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/dojo.json"))
	for row in table:
		col.add_child(_row(row))
	# Combos: one style per fighter, learned here, drilled on the dummy.
	for who in ["son", "father"]:
		var st := ComboBook.style(who)
		var hh := Label.new()
		hh.text = "%s COMBOS  ·  %s STYLE" % ["THE SON'S" if who == "son" else "THE FATHER'S", str(st.get("name", ""))]
		UiKit.apply_label(hh, 20, UiKit.GOLD)
		col.add_child(hh)
		var sb := Label.new()
		sb.text = str(st.get("blurb", "")) + "  The ring on your body is the beat: press the next button as it closes for PERFECT."
		sb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(sb, 12, Palette.MUTED)
		col.add_child(sb)
		var go := UiKit.button("PRACTICE ON THE DUMMY AS %s" % ("THE SON" if who == "son" else "THE FATHER"), Vector2(420, 40))
		go.pressed.connect(_practice.bind(who))
		col.add_child(go)
		for c: Dictionary in ComboBook.all_for(who):
			var info := c.duplicate()
			info["kind"] = "combo"
			info["blurb"] = ComboBook.steps_label(c, PadRouter.last_kind == "pad") + "   ·   " + str(c.get("blurb", ""))
			if bool(c.get("starter", false)):
				info["blurb"] = "KNOWN FROM THE START   ·   " + str(info["blurb"])
			col.add_child(_row(info))
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()


## Which animation shows each school move in the list.
const MOVE_ART := {
	"uppercut": ["son", "uppercut"], "roundhouse": ["son", "roundhouse"],
	"stomp_finish": ["father", "snap"], "speed_vault": ["son", "parkour_run"],
	"kong": ["son", "dive"], "dash_vault": ["son", "slide"], "land_roll": ["son", "roll"],
	"grab_slam": ["father", "hammer"], "wall_bounce": ["son", "jump_roundhouse"],
	"air_mix": ["son", "air_mix"], "tic_tac": ["son", "flying_knee"],
	"wall_kick": ["son", "side_kick"], "king_kong": ["father", "dive"],
	"lazy_vault": ["father", "parkour_run"], "reverse_vault": ["son", "cartwheel_kick"],
	"double_kong": ["son", "superman_punch"], "cat_leap": ["son", "jump"],
	"dive_roll": ["father", "roll"], "front_flip": ["son", "air_spin_kick"],
	"back_flip": ["son", "backflip_kick"], "side_flip": ["father", "jump_spin_kick"],
	"palm_spin": ["son", "sweep"], "webster": ["father", "air_spin_kick"],
	"gainer": ["son", "dropkick"], "cork": ["father", "jump_high_kick"],
	"aerial": ["son", "getup_kick"],
}


func _art(info: Dictionary) -> Texture2D:
	var id := str(info.get("id", ""))
	var t: Texture2D = null
	if str(info.get("kind", "")) == "combo":
		t = SpriteBook.move_icon(str(info.get("who", "son")), str(info.get("clip", "")))
	elif MOVE_ART.has(id):
		t = SpriteBook.move_icon(str(MOVE_ART[id][0]), str(MOVE_ART[id][1]))
	return t if t != null else SpriteBook.icon("dojo")


func _practice(who: String) -> void:
	App.set_meta("dojo_role", who)
	closed.emit()
	App.enter_map("dojo_practice")


func _row(info: Dictionary) -> Control:
	var id := str(info.get("id", ""))
	var rarity := Rarity.normalize(str(info.get("rarity", "common")))
	var rank := FamilyProfile.dojo_rank(id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Rarity.fill(rarity), Rarity.color(rarity)))
	var row := HBoxContainer.new()
	p.add_child(row)
	row.add_child(UiKit.portrait(_art(info), Vector2(56, 56)))
	if FamilyProfile.is_unseen("dojo_%s" % id):
		row.add_child(UiKit.new_dot())
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %s  ·  RANK %d/3" % [str(info.get("title", "")), Rarity.label(rarity), rank]
	UiKit.apply_label(t, 16, Rarity.color(rarity))
	var got := Label.new()
	got.text = str(info.get("kind", "move")).to_upper() + "  ·  " + str(info.get("blurb", ""))
	got.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(got, 12, Palette.LEMON)
	v.add_child(t)
	v.add_child(got)
	row.add_child(v)
	var costs: Array = info.get("gold", [20, 35, 55])
	var cost := int(costs[mini(rank, costs.size() - 1)])
	var gem_cost := FamilyProfile.dojo_gem_cost(rank)
	var label := "TRAIN  %dG" % cost if gem_cost == 0 else "MASTER  %dG + %d GEM" % [cost, gem_cost]
	var go := UiKit.button("MASTERED" if rank >= 3 else label, Vector2(150, 40))
	go.disabled = rank >= 3
	if rank < 3 and int(FamilyProfile.data.get("gold", 0)) < cost:
		go.disabled = true
		go.text = "NEED %d GOLD" % cost
	elif rank < 3 and int(FamilyProfile.data.get("gems", 0)) < gem_cost:
		go.disabled = true
		go.text = "NEED %d GEM" % gem_cost
	go.pressed.connect(func() -> void:
		if FamilyProfile.try_dojo(id):
			FamilyProfile.mark_seen("dojo_%s" % id)
			need_refresh.emit()
			queue_free()
			closed.emit()
		else:
			Juice.shout("GOLD IS ALSO A FEELING")
	)
	row.add_child(go)
	return p
