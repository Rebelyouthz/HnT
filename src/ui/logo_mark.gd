class_name LogoMark
extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "modulate", Color(1.08, 1.04, 0.92, 1.0), 0.9)
	tw.tween_property(self, "modulate", Color.WHITE, 0.9)


func _draw() -> void:
	var heart := PackedVector2Array([
		Vector2(28, 14), Vector2(42, 8), Vector2(50, 22), Vector2(28, 48),
		Vector2(6, 22), Vector2(14, 8), Vector2(28, 14)
	])
	draw_colored_polygon(PackedVector2Array([
		Vector2(28, 14), Vector2(42, 8), Vector2(50, 22), Vector2(28, 48),
		Vector2(6, 22), Vector2(14, 8)
	]), Palette.BRICK)
	draw_polyline(heart, Palette.LEMON, 2.0, true)
	draw_rect(Rect2(24, 10, 8, 18), Palette.EDGE)
	draw_rect(Rect2(20, 16, 16, 4), Palette.EDGE)
	draw_rect(Rect2(8, 4, 40, 6), Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(10, 5, 12, 4), Palette.LEMON)
	draw_rect(Rect2(34, 5, 12, 4), Palette.BRICK)
