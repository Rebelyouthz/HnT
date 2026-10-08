extends CanvasLayer

## The vendor's sheet: nine goods in three rows (WEAPON, BOOSTER, HEALTH),
## each with its icon, what it does, stacks bought and the gold price. The
## game is paused while you shop. Prices grow 22% per stage.

signal closed

var stage_idx := 0
var buyer: Fighter
var _root: Control
var _gold: Label
var _list: VBoxContainer
var _first: Button
var _items: Array = []


static func price_of(row: Dictionary, stage: int, owned: int) -> int:
	return int(round(float(row.get("price", 100)) * (1.0 + 0.22 * float(stage)) * (1.0 + 0.5 * float(owned)) / 5.0)) * 5


func _ready() -> void:
	Mixer.push_music("res://assets/audio/music/music_shop.ogg")
	tree_exiting.connect(Mixer.pop_music)
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cart.json"))
	_items = parsed if parsed is Array else []
	_root = PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, UiKit.GOLD))
	card.position = Vector2(170, 40)
	card.custom_minimum_size = Vector2(940, 640)
	_root.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 18)
	card.add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	pad.add_child(col)
	var head := HBoxContainer.new()
	var pic := UiKit.portrait(load("res://assets/sprites/props/shop_cart.png"), Vector2(70, 70))
	head.add_child(pic)
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.add_child(UiKit.title("THE HALFWAY CART", 28, Palette.LEMON))
	var sub := Label.new()
	sub.text = "\"Cash only. Prices go up the further you get. That's not greed, that's geography.\""
	UiKit.apply_label(sub, 12, Palette.MUTED)
	tcol.add_child(sub)
	head.add_child(tcol)
	_gold = Label.new()
	UiKit.apply_label(_gold, 22, UiKit.GOLD)
	head.add_child(_gold)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var leave := UiKit.button("BACK TO THE STREET", Vector2(320, 46))
	leave.pressed.connect(_close)
	col.add_child(leave)
	_fill()


func _rs() -> RunState:
	return get_tree().get_first_node_in_group("run_state") as RunState


func _fill() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_first = null
	var gold := int(FamilyProfile.data.get("gold", 0))
	_gold.text = "%d G" % gold
	var rs := _rs()
	var last_kind := ""
	for row: Dictionary in _items:
		var kind := str(row.get("kind", ""))
		if kind != last_kind:
			last_kind = kind
			var h := Label.new()
			h.text = {"weapon": "WEAPON PARTS", "booster": "BOOSTERS", "hp": "HEALTH"}.get(kind, kind.to_upper())
			UiKit.apply_label(h, 14, Palette.BRICK)
			_list.add_child(h)
		var id := str(row.get("id", ""))
		var owned := rs.buff(id) if rs else 0
		var cap := int(row.get("max", 1))
		var price := price_of(row, stage_idx, owned if id != "med_kit" else 0)
		var line := PanelContainer.new()
		line.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.MUTED))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		line.add_child(hb)
		hb.add_child(UiKit.portrait(load("res://assets/sprites/loot/cart/%s.png" % str(row.get("icon", "can"))), Vector2(44, 44)))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n := Label.new()
		n.text = "%s%s" % [str(row.get("name", id)), ("   %d/%d" % [owned, cap]) if cap > 1 and id != "med_kit" else ""]
		UiKit.apply_label(n, 15, Palette.LEMON)
		v.add_child(n)
		var b := Label.new()
		b.text = str(row.get("blurb", ""))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(560, 0)
		UiKit.apply_label(b, 12, Palette.TEXT)
		v.add_child(b)
		hb.add_child(v)
		var buy := UiKit.button("%d G" % price, Vector2(150, 40))
		var maxed := owned >= cap and id != "med_kit"
		if maxed:
			buy.text = "SOLD OUT"
			buy.disabled = true
		elif gold < price:
			buy.text = "%d G" % price
			buy.disabled = true
			buy.tooltip_text = "Not enough gold. Come back richer."
		buy.pressed.connect(_buy.bind(row, price))
		hb.add_child(buy)
		_list.add_child(line)
		if _first == null and not buy.disabled:
			_first = buy
	if _first:
		_first.call_deferred("grab_focus")
	else:
		var hint := Label.new()
		hint.text = "Nothing here you can afford yet. Gold drops from thugs, crates and finished stages."
		UiKit.apply_label(hint, 13, Palette.MUTED)
		_list.add_child(hint)


func _buy(row: Dictionary, price: int) -> void:
	if int(FamilyProfile.data.get("gold", 0)) < price:
		return
	FamilyProfile.data["gold"] = int(FamilyProfile.data.get("gold", 0)) - price
	FamilyProfile.save()
	var rs := _rs()
	var id := str(row.get("id", ""))
	if rs:
		rs.buffs[id] = rs.buff(id) + 1
	_apply_now(id)
	Juice.play("res://assets/audio/card.wav")
	Juice.toast("reward", str(row.get("name", id)), "Bought. The cart guy nods like he knew.")
	_fill()


## Buys that act at once (the rest are read live from RunState.buffs).
func _apply_now(id: String) -> void:
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Fighter):
			continue
		var f := n as Fighter
		match id:
			"med_kit":
				f.hp = f.max_hp
			"iron_lungs":
				f.max_hp += 20
				f.hp += 20
			"adrenaline":
				f.bandage = maxi(f.bandage, 1)


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
