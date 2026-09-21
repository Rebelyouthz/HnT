extends Control

signal need_refresh

const LOOKS := [
	{
		"id": "default",
		"role": "son",
		"title": "THE SON  ·  DEFAULT",
		"blurb": "Lemon headband. Cropped hoodie. Tutoring at eight."
	},
	{
		"id": "default",
		"role": "father",
		"title": "THE FATHER  ·  DEFAULT",
		"blurb": "Brick headband. Navy polo. LinkedIn in the notes app."
	},
	{
		"id": "night_tutor",
		"role": "son",
		"title": "NIGHT TUTOR",
		"blurb": "Cape on the body, still late. Rep 8. Moveset does not change."
	},
	{
		"id": "pink_slip",
		"role": "father",
		"title": "PINK-SLIP SPIDER",
		"blurb": "Fired stamp on the polo. Rep 8. The web is the same interview."
	}
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 16)
	add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	m.add_child(col)
	var head := HBoxContainer.new()
	head.add_child(LogoMark.new())
	var h := Label.new()
	h.text = "LOCKER"
	UiKit.apply_label(h, 24, Palette.LEMON)
	head.add_child(h)
	col.add_child(head)
	var s := Label.new()
	s.text = "Movesets sit on the body, not the costume. The Father webs in a polo. That is the point. Tap WEAR. Locked looks tell the truth."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 15, Palette.MUTED)
	col.add_child(s)
	col.add_child(StatPanel.new([
		{"name": "REP", "value": str(int(FamilyProfile.data["rep"])), "color": Palette.BRICK},
		{"name": "UNLOCK AT", "value": "REP 8", "color": Palette.EDGE},
		{"name": "SON", "value": FamilyProfile.costume_for("son").replace("_", " ").to_upper(), "color": Palette.LEMON},
		{"name": "FATHER", "value": FamilyProfile.costume_for("father").replace("_", " ").to_upper(), "color": Palette.BRICK}
	]))
	for item in LOOKS:
		col.add_child(_look(item))


func _look(item: Dictionary) -> Control:
	var id := str(item["id"])
	var role := str(item["role"])
	var unlocked := FamilyProfile.costume_unlocked(id)
	var wearing := FamilyProfile.costume_for(role) == id
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON if wearing else Palette.EDGE))
	var row := HBoxContainer.new()
	p.add_child(row)
	var stamp := StampMark.new()
	stamp.accent = Palette.LEMON if role == "son" else Palette.BRICK
	row.add_child(stamp)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = str(item["title"])
	UiKit.apply_label(t, 16, Palette.LEMON)
	var b := Label.new()
	b.text = str(item["blurb"])
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(b, 13, Palette.TEXT)
	v.add_child(t)
	v.add_child(b)
	row.add_child(v)
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(150, 48)
	var go := UiKit.button(Copy.WEAR, Vector2(140, 44))
	if wearing:
		go.text = Copy.WEARING
		go.disabled = true
		go.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
	elif not unlocked:
		go.text = "LOCK  REP 8"
		go.disabled = true
		var bang := UiKit.bang()
		bang.position = Vector2(118, -4)
		bang.visible = int(FamilyProfile.data["rep"]) >= 6
		wrap.add_child(bang)
	else:
		go.pressed.connect(func() -> void:
			if FamilyProfile.wear_costume(role, id):
				Juice.unlock_logo(str(item["title"]), "Costume on. Kit unchanged. Therapy still costs extra.")
				Juice.toast("reward", str(item["title"]), Copy.WEARING)
				need_refresh.emit()
		)
	wrap.add_child(go)
	row.add_child(wrap)
	return p
