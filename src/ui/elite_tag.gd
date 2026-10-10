class_name EliteTag
extends Label

## A name plate over an elite or champion. A horde with five of them would be
## a wall of text, so only the plate of the one nearest a hero (inside 260 px)
## shows; the others keep their small badge only.

static var _frame := -1
static var _shown: Node = null


static func make(text_: String, col: Color, at: Vector2, w: float) -> EliteTag:
	var t := EliteTag.new()
	t.text = text_
	t.position = at
	t.size = Vector2(w, 12)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 7)
	t.add_theme_color_override("font_color", col)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 3)
	t.modulate.a = 0.0
	return t


func _ready() -> void:
	add_to_group("elite_tags")


func _process(delta: float) -> void:
	var f := Engine.get_process_frames()
	if f != _frame:
		_frame = f
		_shown = null
		var best := 260.0
		for n in get_tree().get_nodes_in_group("elite_tags"):
			var host := (n as Node).get_parent() as Node2D
			if host == null:
				continue
			for p in get_tree().get_nodes_in_group("players"):
				var d := (p as Node2D).global_position.distance_to(host.global_position)
				if d < best:
					best = d
					_shown = n
	modulate.a = move_toward(modulate.a, 1.0 if _shown == self else 0.0, delta * 5.0)
