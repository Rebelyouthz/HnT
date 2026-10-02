class_name LevelUpFx
extends Node2D

## The moment before the level-up cards: light climbs each fighter from the
## feet up (you feel stronger), LEVEL UP floats off the head in pixel caps,
## then a force wave rings out round them - it shoves every thug back, and
## anyone nearly dead goes flying for good. When the text and the ring are
## gone, `done` fires and the cards come.

signal done

const RADIUS := 170.0

var _players: Array = []
var _t := 0.0
var _ring_r := 0.0
var _ring_on := false
var _waved := false


static func play(host: Node, players: Array) -> LevelUpFx:
	var fx := LevelUpFx.new()
	fx._players = players
	fx.z_index = 30
	host.add_child(fx)
	return fx


func _ready() -> void:
	Juice.play("res://assets/audio/level_up.wav" if ResourceLoader.exists("res://assets/audio/level_up.wav") else "res://assets/audio/sting_intro.wav")
	for p in _players:
		if p is Node2D:
			_glow_up(p as Node2D)
			_float_text(p as Node2D)


## A band of light sweeping up the body, the sprite itself flaring.
func _glow_up(p: Node2D) -> void:
	var col := Color(1.0, 0.86, 0.4)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(16, -8), Vector2(-16, -8)])
	beam.vertex_colors = PackedColorArray([Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.85), Color(col.r, col.g, col.b, 0.85)])
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	beam.material = m
	beam.position = p.global_position + Vector2(0, 2)
	add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "position:y", p.global_position.y - 70.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(beam, "scale", Vector2(1.2, 3.0), 0.55)
	tw.tween_property(beam, "modulate:a", 0.0, 0.2)
	tw.tween_callback(beam.queue_free)
	# Ground halo.
	var halo := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a) * 22.0, sin(a) * 5.0))
	halo.polygon = pts
	halo.color = Color(col.r, col.g, col.b, 0.5)
	halo.material = m
	halo.position = p.global_position
	add_child(halo)
	var th := halo.create_tween()
	th.tween_property(halo, "scale", Vector2(1.6, 1.6), 0.6)
	th.parallel().tween_property(halo, "modulate:a", 0.0, 0.9)
	th.tween_callback(halo.queue_free)
	var art := p.get("visual") as CanvasItem
	if art != null:
		var was := art.modulate
		var ta := art.create_tween()
		ta.tween_property(art, "modulate", Color(1.8, 1.6, 1.1), 0.45)
		ta.tween_property(art, "modulate", was, 0.5)


func _float_text(p: Node2D) -> void:
	var lab := Label.new()
	lab.text = "LEVEL UP!"
	lab.add_theme_font_override("font", UiKit.title_font())
	lab.add_theme_font_size_override("font_size", 28)
	lab.add_theme_color_override("font_color", UiKit.GOLD)
	lab.add_theme_color_override("font_outline_color", UiKit.INK)
	lab.add_theme_constant_override("outline_size", 8)
	lab.scale = Vector2(0.5, 0.5)
	lab.size = Vector2(240, 40)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = p.global_position + Vector2(-60, -84)
	lab.modulate.a = 0.0
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	lab.material = m
	add_child(lab)
	var tw := lab.create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(lab, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(lab, "scale", Vector2(0.62, 0.62), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lab, "scale", Vector2(0.5, 0.5), 0.1)
	tw.tween_property(lab, "position:y", lab.position.y - 34.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.tween_callback(lab.queue_free)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.55 and not _waved:
		_waved = true
		_ring_on = true
		_wave()
	if _ring_on:
		_ring_r += delta * 520.0
		if _ring_r > RADIUS * 1.3:
			_ring_on = false
		queue_redraw()
	if _t > 1.75:
		set_process(false)
		done.emit()
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(queue_free)


## The force wave: knock every thug away from the nearest fighter; the
## nearly-dead are blasted off and die where they land.
func _wave() -> void:
	Juice.play("res://assets/audio/boom.wav" if ResourceLoader.exists("res://assets/audio/boom.wav") else "res://assets/audio/hit_heavy.wav")
	Juice.pulse_shake(8.0)
	Juice.hitstop(5)
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Punk) or not is_instance_valid(n):
			continue
		var e := n as Punk
		var src: Node2D = null
		var best := RADIUS * (1.4 if Charms.has("dog_tag") else 1.0)
		for p in _players:
			if p is Node2D:
				var d := (p as Node2D).global_position.distance_to(e.global_position)
				if d < best:
					best = d
					src = p
		if src == null:
			continue
		var dir := signf(e.global_position.x - src.global_position.x)
		if dir == 0.0:
			dir = 1.0
		if e.hp <= 14:
			e.set("_last_zone", "blast")
			e.hp = 0
			e.call("_die", "heavy", src)
			continue
		e.hp = maxi(1, e.hp - 10)
		e.flung = true
		e.flung_dir = dir
		e.flung_t = 0.22
		e.flung_ground = false
		HitReact.react(e.visual, e.facing, "low", dir, 0.8)


func _draw() -> void:
	if not _ring_on:
		return
	var a := clampf(1.0 - _ring_r / (RADIUS * 1.3), 0.0, 1.0)
	for p in _players:
		if not (p is Node2D):
			continue
		var c := to_local((p as Node2D).global_position)
		for k in 3:
			var r := _ring_r - float(k) * 10.0
			if r <= 0.0:
				continue
			var pts := PackedVector2Array()
			for i in 49:
				var ang := TAU * float(i) / 48.0
				pts.append(c + Vector2(cos(ang) * r, sin(ang) * r * 0.3 - 4.0))
			draw_polyline(pts, Color(1.0, 0.9 - 0.2 * float(k), 0.5, a * (0.9 - 0.25 * float(k))), 3.0 - float(k) * 0.8)
		# Shock dome: a faint fill.
		var dome := PackedVector2Array()
		for i in 25:
			var ang := PI + PI * float(i) / 24.0
			dome.append(c + Vector2(cos(ang) * _ring_r * 0.9, sin(ang) * _ring_r * 0.6 - 4.0))
		draw_colored_polygon(dome, Color(1.0, 0.9, 0.6, 0.08 * a))
