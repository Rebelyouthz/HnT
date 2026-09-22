class_name WellnessShuttle
extends Area2D

## Copay Orchard craft. File the Combine first. Then it fails on purpose.

var _rotor: Polygon2D
var _t := 0.0
var _home_y := 490.0


func _ready() -> void:
	add_to_group("shuttle")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(160, 70)
	cs.shape = sh
	add_child(cs)
	var body := Polygon2D.new()
	body.color = Color(0.72, 0.78, 0.42)
	body.polygon = PackedVector2Array([
		Vector2(-70, -16), Vector2(90, -8), Vector2(78, 24), Vector2(-62, 18)
	])
	add_child(body)
	var stripe := Polygon2D.new()
	stripe.color = Palette.LEMON
	stripe.polygon = PackedVector2Array([
		Vector2(-28, -6), Vector2(50, -2), Vector2(48, 4), Vector2(-26, 0)
	])
	add_child(stripe)
	_rotor = Polygon2D.new()
	_rotor.color = Color(0.2, 0.22, 0.18, 0.7)
	_rotor.polygon = PackedVector2Array([
		Vector2(-88, -6), Vector2(108, -6), Vector2(108, 4), Vector2(-88, 4)
	])
	_rotor.position = Vector2(8, -22)
	add_child(_rotor)
	var lab := Label.new()
	lab.position = Vector2(-90, -52)
	lab.size = Vector2(200, 32)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(lab, 13, Palette.LEMON)
	lab.text = "WELLNESS SHUTTLE  ·  SPECIAL"
	lab.name = "Hint"
	add_child(lab)
	_home_y = position.y


func _process(delta: float) -> void:
	_t += delta
	position.y = _home_y + sin(_t * 2.4) * 4.0
	if is_instance_valid(_rotor):
		_rotor.rotation += 14.0 * delta
	var act := get_tree().get_first_node_in_group("run_act")
	var filed := act != null and act.has_method("boss_filed") and bool(act.call("boss_filed"))
	var hint := get_node_or_null("Hint") as Label
	if hint:
		hint.text = "WELLNESS SHUTTLE  ·  SPECIAL" if filed else "FILE THE COMBINE. THEN THE SHUTTLE."
		hint.modulate = Color(1.2, 1.15, 0.7) if filed else Color.WHITE
	for n in get_overlapping_bodies():
		if n is Fighter and (n as Fighter)._just("special"):
			if not filed:
				Juice.shout("THE SHUTTLE WAITS FOR A CORPSE")
				return
			var rs := get_tree().get_first_node_in_group("run_state")
			if rs is RunState:
				var st: RunState = rs
				if not st.cleared:
					st.clear_run()
			Juice.shout("FILE THE RESULTS")
			Juice.toast("quest", "WELLNESS SHUTTLE", "NEXT files the orchard. Then the weather packs a personality.")
			return
