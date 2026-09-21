extends Control

signal need_refresh

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 16)
	add_child(m)
	var col := VBoxContainer.new()
	m.add_child(col)
	var h := Label.new()
	h.text = "LOCKER"
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var s := Label.new()
	s.text = "Movesets sit on the body, not the costume. The Father webs in a polo. That is the point."
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 15, Palette.MUTED)
	col.add_child(s)
	for item in [
		["THE SON  ·  DEFAULT", "Lemon headband. Cropped hoodie. Tutoring at eight."],
		["THE FATHER  ·  DEFAULT", "Brick headband. Navy polo. LinkedIn in the notes app."],
		["NIGHT TUTOR", "Locked. A cape is not a personality. Rep 8."],
		["PINK-SLIP SPIDER", "Locked. Fired stamp on the chest. Rep 8."]
	]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiKit.panel())
		var v := VBoxContainer.new()
		p.add_child(v)
		var t := Label.new()
		t.text = item[0]
		UiKit.apply_label(t, 16, Palette.LEMON)
		var b := Label.new()
		b.text = item[1]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.apply_label(b, 13, Palette.TEXT)
		v.add_child(t)
		v.add_child(b)
		col.add_child(p)
