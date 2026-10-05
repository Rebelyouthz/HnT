class_name CardPick
extends CanvasLayer

## Level-up cards. The game pauses. Three cards fly in face down from deep
## behind the screen, land in a row, and turn over one by one (rarer ones
## flash harder). Move with the stick / arrows or point with the mouse; the
## focused card lifts and glows. Pick one: the others fly off, the chosen one
## comes right up to the glass with a burst and a reward sting, then the
## game waits a beat and carries on.

signal picked(id: String)

var ids: Array = []
var _done := false
var _ready_to_pick := false
var _table: Array = []
var _ui: Control
var _cards: Array[PixelCard] = []
var _hits: Array[Button] = []
var _focus := 1
var _reroll_btn: Button
var _skip_btn: Button
var _title: Label
var _was_paused := false

const SLOTS := [Vector2(170, 150), Vector2(490, 136), Vector2(810, 150)]


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if typeof(parsed) == TYPE_ARRAY:
		_table = parsed
	_ui = PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.04, 0.0)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(dim)
	dim.create_tween().tween_property(dim, "color:a", 0.72, 0.3)
	_title = UiKit.title("LEVEL UP!", 56, UiKit.GOLD)
	_title.position = Vector2(0, 34)
	_title.size = Vector2(1280, 70)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.pivot_offset = Vector2(640, 35)
	_title.add_theme_constant_override("outline_size", 12)
	_title.add_theme_color_override("font_outline_color", UiKit.INK)
	_ui.add_child(_title)
	_title.scale = Vector2(2.2, 2.2)
	_title.modulate.a = 0.0
	var tt := _title.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tt.tween_property(_title, "scale", Vector2.ONE, 0.3)
	tt.parallel().tween_property(_title, "modulate:a", 1.0, 0.2)
	tt.tween_callback(func() -> void:
		UiKit.blast(_ui, Vector2(640, 70), UiKit.GOLD, 300.0)
		Juice.pulse_shake(5.0)
	)
	var sub := Label.new()
	sub.text = "PICK ONE RULE FOR THIS RUN"
	sub.position = Vector2(0, 100)
	sub.size = Vector2(1280, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(sub, 16, Palette.TEXT)
	_ui.add_child(sub)
	if ids.is_empty():
		for c in _table:
			if bool(c.get("fixed", false)):
				ids.append(c["id"])
	var tools := HBoxContainer.new()
	tools.position = Vector2(0, 640)
	tools.size = Vector2(1280, 50)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 16)
	_ui.add_child(tools)
	_skip_btn = UiKit.button(Copy.SKIP, Vector2(200, 46))
	_skip_btn.pressed.connect(func() -> void: _choose(-1))
	_skip_btn.focus_mode = Control.FOCUS_NONE
	tools.add_child(_skip_btn)
	_reroll_btn = UiKit.button(Copy.REROLL, Vector2(200, 46))
	_reroll_btn.pressed.connect(_reroll)
	_reroll_btn.focus_mode = Control.FOCUS_NONE
	tools.add_child(_reroll_btn)
	_sync_reroll()
	Juice.play("res://assets/audio/card.wav")
	_deal()


func _info(id: String) -> Dictionary:
	for c in _table:
		if str(c["id"]) == id:
			var out: Dictionary = (c as Dictionary).duplicate()
			# Owned item: the card shows the next level and what it adds.
			var rs := get_tree().get_first_node_in_group("run_state")
			var lv := int(rs.call("card_level", id)) if rs and rs.has_method("card_level") else 0
			var lines: Array = out.get("lv", [])
			if not lines.is_empty():
				var nxt := clampi(lv + 1, 1, lines.size())
				out["blurb"] = str(lines[nxt - 1])
				out["level"] = nxt
				out["upgrade"] = lv > 0
			return out
	return {}


## Deal: face down from far behind, one after another, then turn over.
func _deal() -> void:
	_ready_to_pick = false
	for c in _cards:
		c.queue_free()
	for h in _hits:
		h.queue_free()
	_cards.clear()
	_hits.clear()
	var n := mini(3, ids.size())
	for i in n:
		var card := PixelCard.new()
		card.info = _info(str(ids[i]))
		card.face_up = false
		_ui.add_child(card)
		card.position = Vector2(490, 230)
		card.scale = Vector2(0.15, 0.15)
		card.rotation = randf_range(-0.6, 0.6)
		card.modulate.a = 0.0
		Bevel.dress(card, false, 0.9)
		_cards.append(card)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.position = SLOTS[i]
		hit.size = Vector2(PixelCard.W, PixelCard.H)
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			hit.add_theme_stylebox_override(s, empty)
		var idx := i
		hit.mouse_entered.connect(func() -> void: _set_focus(idx))
		# Press: the card sinks and darkens under the finger, then springs.
		var cref := card
		hit.button_down.connect(func() -> void:
			if is_instance_valid(cref):
				cref.pivot_offset = cref.size * 0.5
				cref.create_tween().tween_property(cref, "scale", Vector2(0.94, 0.94), 0.05)
				cref.modulate = Color(0.85, 0.85, 0.9)
		)
		hit.button_up.connect(func() -> void:
			if is_instance_valid(cref):
				cref.modulate = Color.WHITE
		)
		hit.pressed.connect(func() -> void: _choose(idx))
		_ui.add_child(hit)
		_hits.append(hit)
		var tw := card.create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.12 * float(i))
		tw.tween_callback(func() -> void: Juice.play("res://assets/audio/whoosh_light.wav" if ResourceLoader.exists("res://assets/audio/whoosh_light.wav") else "res://assets/audio/card.wav"))
		tw.tween_property(card, "position", SLOTS[i], 0.42)
		tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.42)
		tw.parallel().tween_property(card, "rotation", 0.0, 0.42)
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.2)
	# Turn them over one by one.
	var flip := create_tween()
	flip.tween_interval(0.12 * float(n) + 0.45)
	for i in n:
		var card := _cards[i]
		flip.tween_property(card, "scale:x", 0.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flip.tween_callback(func() -> void:
			card.set_face(true)
			Juice.play("res://assets/audio/card.wav")
			var r := card.rarity()
			if r == "legendary" or r == "epic":
				Rarity.juice(r, str(card.info.get("name", "")))
		)
		flip.tween_property(card, "scale:x", 1.08, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flip.tween_property(card, "scale:x", 1.0, 0.06)
		flip.tween_interval(0.08)
	flip.tween_callback(func() -> void:
		_ready_to_pick = true
		_set_focus(mini(1, n - 1))
	)


func _set_focus(i: int) -> void:
	if not _ready_to_pick or _done or i < 0 or i >= _cards.size():
		return
	_focus = i
	for k in _cards.size():
		var c := _cards[k]
		var on := k == i
		c.lit = on
		c.z_index = 2 if on else 0
		var tw := c.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position:y", SLOTS[k].y - (22.0 if on else 0.0), 0.16)
		tw.parallel().tween_property(c, "scale", Vector2.ONE * (1.06 if on else 0.96), 0.16)
		c.modulate = Color.WHITE if on else Color(0.72, 0.72, 0.78)
	Juice.play("res://assets/audio/ui_click.wav")


func _unhandled_input(event: InputEvent) -> void:
	if _done or not _ready_to_pick:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left"):
		_set_focus(maxi(0, _focus - 1))
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right"):
		_set_focus(mini(_cards.size() - 1, _focus + 1))
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_jump") or event.is_action_pressed("p1_light"):
		_choose(_focus)
	else:
		return
	get_viewport().set_input_as_handled()


func _sync_reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	var n := 0
	if rs:
		n = int(rs.get("rerolls"))
	_reroll_btn.disabled = n <= 0
	_reroll_btn.text = Copy.REROLL if n <= 0 else "%s  x%d" % [Copy.REROLL, n]


func _reroll() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	if rs == null or int(rs.get("rerolls")) <= 0 or not _ready_to_pick:
		return
	rs.set("rerolls", int(rs.get("rerolls")) - 1)
	var owned: Array = []
	var cards_v: Variant = rs.get("cards")
	if typeof(cards_v) == TYPE_ARRAY:
		owned = (cards_v as Array).duplicate()
	var lvs: Dictionary = rs.get("card_lv") if rs.get("card_lv") is Dictionary else {}
	var pool: Array = []
	for c in _table:
		if RunState.offerable(c, owned, lvs):
			pool.append(str(c["id"]))
	pool.shuffle()
	ids = pool.slice(0, 3)
	Juice.shout("SECOND OPINION")
	_deal()
	_sync_reroll()


## The pick: the others fall away, the chosen card comes up to the glass.
func _choose(idx: int) -> void:
	if _done:
		return
	if idx >= 0 and not _ready_to_pick:
		return
	_done = true
	var id := "skip" if idx < 0 or idx >= ids.size() else str(ids[idx])
	for k in _cards.size():
		if k == idx:
			continue
		var c := _cards[k]
		c.lit = false
		var tw := c.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(c, "position", c.position + Vector2((float(k) - float(idx)) * 260.0, 520.0), 0.35)
		tw.parallel().tween_property(c, "rotation", (float(k) - float(idx)) * 0.6, 0.35)
		tw.parallel().tween_property(c, "modulate:a", 0.0, 0.35)
	_skip_btn.visible = false
	_reroll_btn.visible = false
	if idx >= 0 and idx < _cards.size():
		var c := _cards[idx]
		c.z_index = 5
		c.lit = true
		var tw := c.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position", Vector2(640 - PixelCard.W * 0.5, 360 - PixelCard.H * 0.5), 0.35)
		tw.parallel().tween_property(c, "scale", Vector2(1.35, 1.35), 0.35)
		tw.tween_callback(func() -> void:
			_burst(Vector2(640, 360), PixelCard.PALETTES.get(c.rarity(), PixelCard.PALETTES["common"])[1])
			Juice.play("res://assets/audio/trick_perfect.wav")
			Juice.play("res://assets/audio/chest.wav" if ResourceLoader.exists("res://assets/audio/chest.wav") else "res://assets/audio/card.wav")
			Juice.pulse_shake(5.0)
			_title.text = str(c.info.get("name", "RULE"))
			_title.scale = Vector2(1.4, 1.4)
			_title.create_tween().set_trans(Tween.TRANS_BACK).tween_property(_title, "scale", Vector2.ONE, 0.25)
		)
		tw.tween_property(c, "scale", Vector2(1.45, 1.45), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(0.35)
		tw.tween_property(c, "modulate:a", 0.0, 0.25)
		tw.parallel().tween_property(c, "scale", Vector2(1.7, 1.7), 0.25)
	var end := create_tween()
	end.tween_interval(1.55 if idx >= 0 else 0.4)
	end.tween_callback(func() -> void:
		# A short beat before the street moves again.
		get_tree().paused = _was_paused
		picked.emit(id)
		queue_free()
	)


## Reward burst: rays and pixel sparks out of the chosen card.
func _burst(at: Vector2, col: Color) -> void:
	for i in 14:
		var ray := ColorRect.new()
		ray.color = Color(col.r, col.g, col.b, 0.7)
		ray.size = Vector2(6, 120)
		ray.pivot_offset = Vector2(3, 0)
		ray.position = at - Vector2(3, 0)
		ray.rotation = TAU * float(i) / 14.0
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(ray)
		_ui.move_child(ray, 1)
		var tw := ray.create_tween().set_parallel(true)
		tw.tween_property(ray, "size:y", 420.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(ray, "modulate:a", 0.0, 0.8)
		tw.chain().tween_callback(ray.queue_free)
	for i in 30:
		var p := ColorRect.new()
		p.color = col if i % 3 else Color(1, 1, 0.9)
		p.size = Vector2(6, 6)
		p.position = at
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(p)
		var a := randf() * TAU
		var d := randf_range(160.0, 360.0)
		var tw := p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", at + Vector2(cos(a), sin(a)) * d, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.6)
		tw.chain().tween_callback(p.queue_free)
