class_name QuestItem
extends Area2D

## The thing a street quest sends you after (a collar, a wallet, a ticket
## book): it lies on the ground ahead with a pulsing marker and a beam, and
## is picked up by walking over it.

var kind := "wallet"
var giver: Node
var _t := 0.0
var _beam: Polygon2D


func _ready() -> void:
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 16
	cs.shape = c
	add_child(cs)
	_beam = Polygon2D.new()
	_beam.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(14, -120), Vector2(-14, -120)])
	_beam.color = Color(1.0, 0.85, 0.3, 0.16)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam.material = m
	add_child(_beam)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.25
	l.color = Color(1.0, 0.85, 0.4)
	l.energy = 0.9
	add_child(l)
	body_entered.connect(func(b: Node) -> void:
		if b is Fighter:
			_take()
	)


func _process(delta: float) -> void:
	_t += delta
	_beam.color.a = 0.12 + 0.08 * sin(_t * 4.0)
	queue_redraw()


func _draw() -> void:
	var y := -3.0 - 2.0 * absf(sin(_t * 3.0))
	match kind:
		"collar":
			draw_arc(Vector2(0, y), 5.0, 0, TAU, 16, Color(0.85, 0.15, 0.2), 2.0)
			draw_circle(Vector2(0, y + 5), 1.8, Color(0.95, 0.8, 0.3))
		"ticket":
			draw_rect(Rect2(Vector2(-6, y - 4), Vector2(12, 8)), Color(0.96, 0.94, 0.86))
			draw_line(Vector2(-4, y - 1), Vector2(4, y - 1), Color(0.5, 0.5, 0.55), 1.0)
			draw_line(Vector2(-4, y + 2), Vector2(2, y + 2), Color(0.5, 0.5, 0.55), 1.0)
		_:
			draw_rect(Rect2(Vector2(-6, y - 4), Vector2(12, 8)), Color(0.45, 0.28, 0.16))
			draw_line(Vector2(-6, y), Vector2(6, y), Color(0.3, 0.18, 0.1), 1.0)
			draw_rect(Rect2(Vector2(2, y - 3), Vector2(3, 2)), Color(0.4, 0.75, 1.0))
	var a := 0.6 + 0.4 * sin(_t * 6.0)
	draw_string(ThemeDB.fallback_font, Vector2(-4, y - 12), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.85, 0.2, a))


func _take() -> void:
	Juice.popup_number(global_position + Vector2(0, -20), "FOUND", UiKit.GOLD)
	Mixer.play_sfx("res://assets/audio/card.wav")
	if giver and is_instance_valid(giver) and giver.has_method("found_item"):
		giver.call("found_item")
	queue_free()
