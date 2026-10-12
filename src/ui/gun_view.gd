class_name GunView
extends Control

## The gunsmith's bench: the gun drawn big on a pegboard, every fitted part
## on it where it really sits, a pulsing marker on each open empty mount and
## a padlock on the shut ones. fit_anim() slides a new part onto its mount
## (a can screws onto the muzzle from the right, an optic drops onto the
## rail, a magazine pushes up into the well, a round is pressed into the
## window), then it clicks home with a flash and sparks. off_anim() pulls
## one off and lets it fall. preview(part) shows a ghost of a part before it
## is bought or fitted. Whole multiples of the pixel grid only (k).

var gun := "pistol"
var k := 4.0
var _origin := Vector2.ZERO
var _gun_rect: TextureRect
var _parts := {}
var _ghost: TextureRect
var _markers: Array[Control] = []
var _t := 0.0


func setup(id: String) -> void:
	gun = id
	_rebuild()


func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_rebuild)


func _process(delta: float) -> void:
	_t += delta
	for i in _markers.size():
		var m := _markers[i]
		if is_instance_valid(m):
			m.modulate.a = 0.45 + 0.35 * sin(_t * 4.0 + float(i))
	queue_redraw()


func _sprite() -> String:
	return Attach.gun_sprite(gun)


## The whole picture's extent in gun px with every open slot's longest part,
## so fitting a part never makes the gun jump.
func _extent() -> Rect2:
	var tex := load("res://assets/sprites/guns/%s.png" % _sprite()) as Texture2D
	var r := Rect2(Vector2.ZERO, tex.get_size() if tex else Vector2(60, 36))
	var demo := {"barrel": "long_barrel", "muzzle": "suppressor", "optic": "scope", "mag": "drum_mag", "ammo": "hollow"}
	for p: Dictionary in Attach.layout(gun, demo):
		r = r.merge(Rect2(p["pos"], p["size"]))
	return r.grow(4)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_parts.clear()
	_markers.clear()
	_ghost = null
	var ext := _extent()
	# Biggest whole step that fits (a gun px is k design px).
	k = 6.0
	while k > 2.0 and (ext.size.x * k > size.x or ext.size.y * k > size.y):
		k -= 1.0
	_origin = ((size - ext.size * k) * 0.5).floor() - ext.position * k
	_gun_rect = TextureRect.new()
	_gun_rect.texture = load("res://assets/sprites/guns/%s.png" % _sprite())
	_gun_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gun_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gun_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_gun_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _gun_rect.texture:
		_gun_rect.size = _gun_rect.texture.get_size() * k
	_gun_rect.position = _origin
	_gun_rect.pivot_offset = _gun_rect.size * 0.5
	add_child(_gun_rect)
	for p: Dictionary in Attach.layout(gun):
		_add_part(p, 1.0)
	_add_markers()


func _add_part(p: Dictionary, alpha: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = p["tex"]
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = (p["size"] as Vector2) * k
	r.position = _origin + (p["pos"] as Vector2) * k
	r.pivot_offset = r.size * 0.5
	r.modulate.a = alpha
	add_child(r)
	if str(p["mount"]) == "mag":
		move_child(r, 0)
	_parts[str(p["slot"])] = r
	return r


## A soft marker on every mount: pulsing when the slot is open and empty, a
## small padlock with the level when it is shut.
func _add_markers() -> void:
	var gm := Attach._gun_meta(_sprite())
	var mounts := {"muzzle": "muzzle", "optic": "rail", "barrel": "muzzle", "mag": "mag", "ammo": "window"}
	var done := {}
	for slot: String in Attach.SLOTS:
		if _parts.has(slot):
			continue
		var m := str(mounts[slot])
		var key := m
		if slot == "barrel":
			key = "barrel"
		if done.has(key):
			continue
		done[key] = true
		var a: Array = gm.get(m, gm.get("muzzle", [0, 0]))
		var at := _origin + Vector2(float(a[0]), float(a[1])) * k
		if slot == "barrel":
			at += Vector2(-10.0 * k, 0)
		var open := Attach.slot_open(gun, slot)
		var ic := IconBook.rect("slot_" + slot if open else "cur_lock", IconBook.SIZE_S * 0.75)
		ic.position = at - ic.size * 0.5 + _marker_push(slot) * k
		add_child(ic)
		if open:
			_markers.append(ic)
		else:
			ic.modulate = Color(1, 1, 1, 0.75)


func _marker_push(slot: String) -> Vector2:
	match slot:
		"muzzle":
			return Vector2(8, 0)
		"optic":
			return Vector2(0, -7)
		"mag":
			return Vector2(0, 7)
		"ammo":
			return Vector2(0, 0)
	return Vector2(0, -6)


## Where a new part comes in from, in gun px, relative to where it sits.
func _approach(slot: String) -> Vector2:
	match slot:
		"muzzle", "barrel":
			return Vector2(26, 0)
		"optic":
			return Vector2(0, -22)
		"mag":
			return Vector2(0, 22)
	return Vector2(0, -12)


func preview(part: String) -> void:
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	if part == "":
		return
	var slot := str(Attach.LIST[part]["slot"])
	if Attach.on(gun, slot) == part:
		return
	var f := {}
	for s in Attach.SLOTS:
		var a := Attach.on(gun, s)
		if a != "" and Attach.slot_open(gun, s):
			f[s] = a
	f[slot] = part
	for p: Dictionary in Attach.layout(gun, f):
		if str(p["slot"]) == slot:
			var old: TextureRect = _parts.get(slot)
			_parts.erase(slot)
			_ghost = _add_part(p, 0.45)
			_ghost.modulate = Color(0.6, 1.0, 0.8, 0.5)
			if old:
				_parts[slot] = old
			var tw := _ghost.create_tween().set_loops()
			tw.tween_property(_ghost, "modulate:a", 0.25, 0.5)
			tw.tween_property(_ghost, "modulate:a", 0.6, 0.5)


## Slide the part for `slot` onto the gun and lock it with a click.
func fit_anim(slot: String) -> void:
	preview("")
	var keep := {}
	for s in _parts:
		keep[s] = true
	_rebuild()
	var r: TextureRect = _parts.get(slot)
	if r == null:
		return
	var home := r.position
	var from := home + _approach(slot) * k
	r.position = from
	r.modulate.a = 0.0
	RewardFly.snd("part_slide", 1.0, -4.0)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(r, "position", home + (from - home) * 0.12, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if slot == "muzzle":
		# Screwed on: a little wobble while it threads.
		for i in 3:
			tw.tween_property(r, "rotation", 0.06 * (1.0 if i % 2 == 0 else -1.0), 0.05)
		tw.tween_property(r, "rotation", 0.0, 0.04)
	tw.tween_property(r, "position", home, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		RewardFly.snd("part_click", 1.0, -1.0)
		var tf := r.create_tween()
		tf.tween_property(r, "modulate", Color(2.4, 2.4, 2.2), 0.03)
		tf.tween_property(r, "modulate", Color.WHITE, 0.22)
		Juice.upgrade_fx(r, Color(0.6, 0.95, 1.0), "", false)
		var tg := _gun_rect.create_tween()
		tg.tween_property(_gun_rect, "position", _origin + Vector2(-k, k * 0.5), 0.04)
		tg.tween_property(_gun_rect, "position", _origin, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


## Pull the part in `slot` off (it is already gone from the save).
func off_anim(slot: String) -> void:
	var r: TextureRect = _parts.get(slot)
	if r == null:
		_rebuild()
		return
	_parts.erase(slot)
	RewardFly.snd("part_off", 1.0, -3.0)
	var away := r.position + _approach(slot) * k
	var tw := r.create_tween()
	tw.tween_property(r, "position", away, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(r, "position:y", away.y + 60.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(r, "rotation", 0.6, 0.25)
	tw.parallel().tween_property(r, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		r.queue_free()
		_rebuild())


func _draw() -> void:
	# Pegboard bench behind the gun.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.075, 0.1))
	var step := 24.0
	var y := step * 0.5
	while y < size.y:
		var x := step * 0.5
		while x < size.x:
			draw_rect(Rect2(Vector2(x, y).floor(), Vector2(4, 4)), Color(0.03, 0.03, 0.05))
			x += step
		y += step
	# Work light pooled on the gun.
	var c := size * 0.5
	for i in 6:
		draw_circle(c, size.y * (0.5 - 0.06 * float(i)), Color(0.55, 0.75, 0.9, 0.025))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.6, 0.75, 0.6), false, 2.0)
