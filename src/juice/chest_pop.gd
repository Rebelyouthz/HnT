class_name ChestPop
extends Node2D

## A world chest you want to open: the pixel chest sits on a soft rarity
## glow, bobs, and glints now and then. open() plays the whole moment -
## it rattles harder and harder (three clicks, rising), the lid bursts up,
## a light column shoots out, coins and gems spray, bounce and fade - and
## calls `on_open` on the pop, so the reward lands with the peak.

const CLOSED := "res://assets/sprites/hub/chest_closed.png"
const OPENED := "res://assets/sprites/hub/chest_open.png"

var color := Color(1.0, 0.82, 0.3)
var big := false
var _box: Sprite2D
var _light: PointLight2D
var _t := 0.0
var _opening := -1.0
var _popped := false
var _beam := 0.0
var _glint := 0.0
var _bits: Array = []
var _on_open: Callable
var _base := 0.3


static func make(host: Node, is_big: bool, col: Color) -> ChestPop:
	var c := ChestPop.new()
	c.big = is_big
	c.color = col
	host.add_child(c)
	return c


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base = 0.34 if big else 0.27
	_box = Sprite2D.new()
	_box.texture = load(CLOSED)
	_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The art's feet sit at y 112 of 128: stand them on the node.
	_box.offset = Vector2(0, -48)
	_box.scale = Vector2.ONE * _base
	_box.light_mask = 0
	add_child(_box)
	_light = PointLight2D.new()
	_light.texture = LightRig.radial_tex()
	_light.texture_scale = 0.55 if big else 0.4
	_light.color = color
	_light.energy = 0.7
	_light.position = Vector2(0, -14)
	add_child(_light)


func open(on_open: Callable) -> void:
	if _opening >= 0.0:
		return
	_on_open = on_open
	_opening = 0.0
	Mixer.play_sfx("res://assets/audio/ui/part_click.wav", 0.85, -4.0)


func _process(delta: float) -> void:
	_t += delta
	if _opening < 0.0:
		# Waiting: a slow bob and a glint every couple of seconds.
		_box.position.y = -absf(sin(_t * 2.6)) * 2.0
		_box.rotation = 0.0
		_glint = maxf(0.0, _glint - delta * 3.0)
		if fmod(_t, 2.2) < delta:
			_glint = 1.0
	else:
		_opening += delta
		if not _popped:
			# Rattle harder until it can't hold.
			var k := _opening / 0.45
			_box.rotation = sin(_opening * 46.0) * 0.12 * k
			_box.position = Vector2(sin(_opening * 61.0) * 1.5 * k, -absf(sin(_opening * 23.0)) * 3.0 * k)
			_light.energy = 0.7 + 1.6 * k
			for i in 2:
				var at := 0.15 * float(i + 1)
				if _opening >= at and _opening - delta < at:
					Mixer.play_sfx("res://assets/audio/ui/part_click.wav", 1.0 + 0.25 * float(i + 1), -3.0)
			if _opening >= 0.45:
				_pop()
		else:
			_beam = maxf(0.0, _beam - delta * 1.4)
			_light.energy = maxf(0.0, _light.energy - delta * 2.0)
	_tick_bits(delta)
	queue_redraw()


func _pop() -> void:
	_popped = true
	_box.texture = load(OPENED)
	_box.rotation = 0.0
	_box.position = Vector2.ZERO
	_beam = 1.0
	var s := _base
	var tw := create_tween()
	tw.tween_property(_box, "scale", Vector2(s * 1.35, s * 0.7), 0.05)
	tw.tween_property(_box, "scale", Vector2(s * 0.85, s * 1.25), 0.08)
	tw.tween_property(_box, "scale", Vector2.ONE * s, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
	Juice.pulse_shake(7.0 if big else 4.0)
	Juice.hitstop(3)
	Mixer.play_sfx("res://assets/audio/chest.wav", 1.0, 0.0)
	Mixer.play_sfx("res://assets/audio/ui/up_boom.wav" if big else "res://assets/audio/ui/reward_pop.wav", 1.0, -2.0)
	var icons := ["cur_gold_s", "cur_gold_s", "cur_gold_s", "cur_gem_s"] if big else ["cur_gold_s", "cur_gold_s", "cur_scoin_s"]
	for i in (22 if big else 14):
		var a := randf_range(-PI * 0.92, -PI * 0.08)
		_bits.append({
			"p": Vector2(randf_range(-6, 6), -18),
			"v": Vector2(cos(a) * randf_range(40, 150), sin(a) * randf_range(160, 300)),
			"tex": IconBook.tex(str(icons[randi() % icons.size()])),
			"life": randf_range(0.9, 1.4), "spin": randf_range(-10, 10), "rot": 0.0, "bounced": false,
		})
	if _on_open.is_valid():
		_on_open.call()


func _tick_bits(delta: float) -> void:
	for b: Dictionary in _bits:
		var v: Vector2 = b["v"]
		v.y += 620.0 * delta
		var p: Vector2 = (b["p"] as Vector2) + v * delta
		if p.y > 4.0 and v.y > 0.0:
			p.y = 4.0
			v = Vector2(v.x * 0.6, -v.y * 0.42)
			if not bool(b["bounced"]):
				b["bounced"] = true
				if randf() < 0.35:
					Mixer.play_sfx("res://assets/audio/ui/coin_land.wav", randf_range(1.0, 1.4), -12.0)
		b["v"] = v
		b["p"] = p
		b["rot"] = float(b["rot"]) + float(b["spin"]) * delta
		b["life"] = float(b["life"]) - delta
	_bits = _bits.filter(func(b: Dictionary) -> bool: return float(b["life"]) > 0.0)


func _draw() -> void:
	# Ground shadow and the rarity pool under the chest.
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(Vector2.ZERO, 26.0 if big else 20.0, Color(color.r, color.g, color.b, 0.12 + 0.08 * pulse))
	draw_circle(Vector2.ZERO, 16.0 if big else 12.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _opening < 0.0:
		# Rising motes so it reads as "come get me".
		for i in 5:
			var ph := fmod(_t * 0.6 + float(i) * 0.2, 1.0)
			var x := sin(float(i) * 2.3 + _t) * 12.0
			draw_circle(Vector2(x, -6.0 - ph * 34.0), 1.2, Color(color.r, color.g, color.b, 0.7 * (1.0 - ph)))
		if _glint > 0.0:
			var g := Vector2(9, -30) + _box.position
			var r := 5.0 * _glint
			draw_line(g + Vector2(-r, 0), g + Vector2(r, 0), Color(1, 1, 0.9, _glint), 1.0)
			draw_line(g + Vector2(0, -r), g + Vector2(0, r), Color(1, 1, 0.9, _glint), 1.0)
	if _beam > 0.0:
		var w := (18.0 if big else 13.0) * (0.6 + 0.4 * _beam)
		var h := 150.0 * (1.2 - _beam * 0.2)
		for k in 4:
			var ww := w * (1.0 - 0.22 * float(k))
			draw_rect(Rect2(-ww * 0.5, -h - 18.0, ww, h), Color(color.r, color.g, color.b, 0.12 * _beam))
		draw_rect(Rect2(-w * 0.15, -h - 18.0, w * 0.3, h), Color(1, 1, 0.92, 0.5 * _beam))
		var ring := (1.0 - _beam) * 46.0 + 6.0
		draw_arc(Vector2(0, -18), ring, 0, TAU, 32, Color(1, 1, 0.9, _beam), 2.0)
	for b: Dictionary in _bits:
		var tex: Texture2D = b["tex"]
		if tex == null:
			continue
		var a := clampf(float(b["life"]) * 2.5, 0.0, 1.0)
		draw_set_transform(b["p"], float(b["rot"]), Vector2(0.8, 0.8 * absf(cos(float(b["rot"])))) + Vector2(0, 0.15))
		draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
