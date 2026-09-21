class_name StatPanel
extends PanelContainer

## Colored stat names + numbers. Same chrome as the hub, not a debug dump.


func _init(rows: Array = []) -> void:
	add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL_2, Palette.EDGE))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		col.add_child(_line(str(row.get("name", "")), str(row.get("value", "")), row.get("color", Palette.TEXT) as Color))


static func _line(stat_name: String, value: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var n := Label.new()
	n.text = stat_name
	UiKit.apply_label(n, 13, color)
	var v := Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiKit.apply_label(v, 16, Palette.TEXT)
	row.add_child(n)
	row.add_child(v)
	return row


static func kit_rows(role: String) -> Array:
	if role == "father":
		return [
			{"name": "HP", "value": "118", "color": Palette.BRICK},
			{"name": "STEAM", "value": "100", "color": Palette.LEMON},
			{"name": "SPEED", "value": "180", "color": Palette.EDGE},
			{"name": "SPECIAL", "value": "WEB 80–280", "color": Palette.TEXT},
			{"name": "AMMO", "value": "SNARE 6", "color": Palette.READY},
			{"name": "THROW", "value": "POCKET SAND", "color": Palette.MUTED}
		]
	return [
		{"name": "HP", "value": "92", "color": Palette.BRICK},
		{"name": "STEAM", "value": "100", "color": Palette.LEMON},
		{"name": "SPEED", "value": "230", "color": Palette.EDGE},
		{"name": "SPECIAL", "value": "CAPE GUARD", "color": Palette.TEXT},
		{"name": "AMMO", "value": "BATWING 3", "color": Palette.READY},
		{"name": "AIR", "value": "GLIDE · DIVE · WALL-RUN", "color": Palette.MUTED}
	]
