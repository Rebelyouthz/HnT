class_name SecretLedge
extends Area2D

## A VAULT CRATE on the hardest roof to reach on every map: the far end of
## the highest roof segment. Only the roof plane gets there (ladder, pipe,
## bin-and-awning or the web), and the first time on each map it pays a CARD
## TOKEN, gems and gold; after that a little gold. A faint shimmer and a "?"
## show only when you are close.

var map_id := ""
var _sp: Sprite2D
var _t := 0.0
var _done := false
var _hint: Label


static func place(host: Node, map: String) -> void:
	var best: Rect2 = Rect2()
	var found := false
	for n in host.get_tree().get_nodes_in_group("roof_solids"):
		if not n.has_meta("rect") or not host.is_ancestor_of(n):
			continue
		var r: Rect2 = n.get_meta("rect")
		if r.size.x < 160.0:
			continue
		# Highest roof first, then the one furthest along.
		if not found or r.position.y < best.position.y - 4.0 or (absf(r.position.y - best.position.y) <= 4.0 and r.end.x > best.end.x):
			best = r
			found = true
	if not found:
		return
	var s := SecretLedge.new()
	s.map_id = map
	s.position = Vector2(best.end.x - 40.0, best.position.y)
	host.add_child(s)


func _ready() -> void:
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(44, 50)
	cs.shape = r
	cs.position = Vector2(0, -22)
	add_child(cs)
	_sp = Sprite2D.new()
	_sp.texture = IconBook.tex("cur_chest")
	_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sp.scale = Vector2(0.9, 0.9)
	_sp.offset = Vector2(0, -16)
	add_child(_sp)
	var glow := PointLight2D.new()
	glow.texture = LightRig.radial_tex()
	glow.texture_scale = 0.35
	glow.color = Color(1.0, 0.8, 0.35)
	glow.energy = 0.8
	glow.position = Vector2(0, -16)
	add_child(glow)
	_hint = Label.new()
	_hint.text = "?"
	_hint.position = Vector2(-10, -58)
	_hint.size = Vector2(20, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_hint.add_theme_constant_override("outline_size", 3)
	add_child(_hint)
	NearFade.on(_hint, 90, 200)
	var got: Array = FamilyProfile.data.get("secret_ledges", [])
	if got.has(map_id):
		_sp.modulate = Color(0.7, 0.7, 0.75)
	body_entered.connect(_take)


func _process(delta: float) -> void:
	_t += delta
	if _sp and not _done:
		_sp.position.y = sin(_t * 2.2) * 2.0


func _take(b: Node) -> void:
	if _done or not (b is Fighter):
		return
	_done = true
	var got: Array = FamilyProfile.data.get("secret_ledges", [])
	if not got.has(map_id):
		got.append(map_id)
		FamilyProfile.data["secret_ledges"] = got
		FamilyProfile.add_gems(4)
		FamilyProfile.add_gold(40)
		VaultCards.add_tokens(1, "Found the VAULT CRATE on the high roof.")
		Juice.unlock_logo("VAULT CRATE", "The hardest roof on the map paid out.", "+1 TOKEN  ·  +4 GEMS  ·  +40 GOLD", IconBook.tex("cur_card_token"))
		Rarity.juice("epic", "VAULT CRATE")
	else:
		FamilyProfile.add_gold(12)
		Juice.popup_number(global_position + Vector2(0, -40), "+12 GOLD", UiKit.GOLD)
	Juice.play("res://assets/audio/chest.wav")
	var tw := create_tween()
	tw.tween_property(_sp, "scale", Vector2(1.4, 1.4), 0.12)
	tw.tween_property(_sp, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
