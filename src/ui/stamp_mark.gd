class_name StampMark
extends Control

## Hand-built clinic stamp. Not emoji. Claim / award / toast chrome.

@export var accent: Color = Palette.BADGE


func _ready() -> void:
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "rotation", 0.08, 0.7)
	tw.tween_property(self, "rotation", -0.06, 0.7)


func _draw() -> void:
	draw_circle(Vector2(14, 14), 13.0, accent)
	draw_arc(Vector2(14, 14), 13.0, 0.0, TAU, 16, Palette.TEXT, 2.0, true)
	draw_rect(Rect2(12, 6, 4, 12), Palette.TEXT)
	draw_rect(Rect2(12, 20, 4, 4), Palette.TEXT)
