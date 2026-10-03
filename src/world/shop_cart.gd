class_name ShopCart
extends Area2D

## The halfway vendor: one cart parked on every stage. Walk up, press UP or
## LIGHT (with no thug in arm's reach) and a sheet of the night's goods opens:
## gun upgrades, boosters, health. Gold only, prices climb with the stage, so
## on Dock Street you can look but not afford (on purpose).

var _sp: Sprite2D
var _hint: Label
var _t := 0.0
var _busy := false
var stage_idx := 0


static func place(host: Node, x: float, y: float = 478.0) -> ShopCart:
	var c := ShopCart.new()
	c.position = Vector2(x, y)
	c.stage_idx = maxi(0, App.ORDER.find(App.current_map))
	host.add_child(c)
	return c


func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(110, 120)
	cs.shape = r
	cs.position = Vector2(0, 30)
	add_child(cs)
	_sp = Sprite2D.new()
	_sp.texture = load("res://assets/sprites/props/shop_cart.png")
	_sp.centered = true
	_sp.scale = Vector2(0.24, 0.24)
	_sp.offset = Vector2(0, -float(_sp.texture.get_height()) * 0.5)
	_sp.texture_filter = SpriteBook.world_filter()
	add_child(_sp)
	var l := PointLight2D.new()
	l.texture = LightRig.radial_tex()
	l.texture_scale = 0.5
	l.color = Color(1.0, 0.78, 0.45)
	l.energy = 1.1
	l.position = Vector2(12, -52)
	add_child(l)
	_hint = Label.new()
	_hint.text = "UPGRADES  ·  UP / LIGHT"
	_hint.position = Vector2(-70, -94)
	_hint.size = Vector2(140, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_hint.add_theme_constant_override("outline_size", 3)
	add_child(_hint)


func _process(delta: float) -> void:
	_t += delta
	_hint.position.y = -94.0 - 2.0 * sin(_t * 3.0)
	if _busy:
		return
	for n in get_overlapping_bodies():
		if n is Fighter:
			var f: Fighter = n
			if f.downed:
				continue
			var hot := _enemy_near()
			_hint.text = "CLOSED WHILE YOU BLEED" if hot else "UPGRADES  ·  UP / LIGHT"
			_hint.modulate = Color(1.2, 1.15, 0.7)
			if not hot and (f._just("up") or f._just("light")):
				_open(f)
			return
	_hint.text = "UPGRADES"
	_hint.modulate = Color.WHITE


func _enemy_near() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and int(e.get("hp")) > 0 and (e as Node2D).global_position.distance_to(global_position) < 240.0:
			return true
	return false


func _open(f: Fighter) -> void:
	_busy = true
	Juice.play("res://assets/audio/ui_click.wav")
	var sheet := preload("res://src/ui/cart_sheet.gd").new()
	sheet.stage_idx = stage_idx
	sheet.buyer = f
	get_tree().current_scene.add_child(sheet)
	sheet.closed.connect(func() -> void:
		_busy = false
	)
