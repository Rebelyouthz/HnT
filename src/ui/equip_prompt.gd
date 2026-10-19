class_name EquipPrompt
extends CanvasLayer

## NEW MOVE  ·  EQUIP NOW? Shown the moment a strike is learned (MOVES
## library, dojo drill done). Stick strikes (StickBook) go on a right-stick
## path: YES puts it on a free one; when every path of its kind is taken,
## the list is the paths with what they hold now, pick the one it replaces.
## Button strikes (air, jumping kicks ...) list the button slots they fit.
## LATER keeps the loadout as it is (MOVES > STICK / LOADOUT any time).

signal finished(slot: String)

var role := "son"
var move_id := ""
var _was_paused := false


## Ask about a just-learned move. Already on a path: a short note instead.
static func ask(who: String, id: String) -> EquipPrompt:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null or DisplayServer.get_name() == "headless" and not Engine.has_meta("equip_prompt_test"):
		return null
	if StickBook.fits(id) and StickBook.slot_of(who, id) != "":
		Juice.toast("reward", "%s  ·  ON THE STICK" % StickBook.title(id), StickBook.NAME[StickBook.slot_of(who, id)])
		return null
	var p := EquipPrompt.new()
	p.role = who
	p.move_id = id
	tree.root.add_child.call_deferred(p)
	return p


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("equip_prompt")
	_was_paused = get_tree().paused
	get_tree().paused = true
	var ui := PixelStage.attach_canvas(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.72)
	dim.size = Vector2(1280, 720)
	ui.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.LEMON, 0.4))
	card.custom_minimum_size = Vector2(560, 0)
	ui.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var clip := _clip()
	var ic := UiKit.portrait(SpriteBook.move_icon(role, clip), Vector2(84, 84))
	head.add_child(ic)
	var tv := VBoxContainer.new()
	var name := StickBook.title(move_id) if StickBook.fits(move_id) else str(Moves.row(move_id).get("title", move_id.to_upper()))
	var kicker := Label.new()
	kicker.text = "NEW MOVE  ·  %s" % (FamilyProfile.son_name() if role == "son" else FamilyProfile.father_name()).to_upper()
	UiKit.apply_label(kicker, 12, Palette.MUTED)
	tv.add_child(kicker)
	tv.add_child(UiKit.title(name, 26, Palette.LEMON))
	var q := Label.new()
	q.text = "EQUIP NOW?"
	q.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(q, 18, Palette.TEXT)
	tv.add_child(q)
	head.add_child(tv)
	col.add_child(head)
	var first: Button = null
	if StickBook.fits(move_id):
		var type := str((StickBook.CAT[move_id] as Dictionary)["type"])
		var free := StickBook.free_slot(role, move_id)
		var lo := StickBook.loadout(role)
		var note := Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(540, 0)
		UiKit.apply_label(note, 13, Palette.MUTED)
		col.add_child(note)
		if free != "":
			note.text = "A %s goes on the right stick. Free path: %s." % [type.to_upper(), StickBook.NAME[free]]
			first = _choice(col, "YES  ·  %s" % StickBook.NAME[free], "equip_yes", func() -> void: _put_stick(free))
			var or_l := Label.new()
			or_l.text = "OR REPLACE ONE:"
			UiKit.apply_label(or_l, 12, Palette.MUTED)
			col.add_child(or_l)
		else:
			note.text = "Every %s path on the stick is taken. Pick the one it replaces:" % type
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		col.add_child(grid)
		for s in StickBook.slots_of(type):
			if str(lo[s]) == "":
				continue
			var slot := str(s)
			var b := _choice(grid, "%s\n%s" % [StickBook.NAME[slot], StickBook.title(str(lo[slot]))], "equip_" + slot, func() -> void: _put_stick(slot))
			b.custom_minimum_size = Vector2(268, 46)
			if first == null:
				first = b
	else:
		var note2 := Label.new()
		note2.text = "Not a stick strike: it goes on a button. Pick the slot:"
		UiKit.apply_label(note2, 13, Palette.MUTED)
		col.add_child(note2)
		var lo2 := Moves.loadout(role)
		var grid2 := GridContainer.new()
		grid2.columns = 2
		grid2.add_theme_constant_override("h_separation", 6)
		grid2.add_theme_constant_override("v_separation", 6)
		col.add_child(grid2)
		for s in Moves.SLOTS:
			if not Moves.fits(move_id, s):
				continue
			var slot2 := str(s)
			var cur := str(Moves.row(str(lo2[slot2])).get("title", str(lo2[slot2]).to_upper()))
			var b2 := _choice(grid2, "%s\n%s" % [Moves.SLOT_NAME[slot2], cur], "equip_" + slot2, func() -> void: _put_button(slot2))
			b2.custom_minimum_size = Vector2(268, 46)
			if first == null:
				first = b2
	var later := _choice(col, "LATER  ·  MOVES MENU ANY TIME", "equip_later", func() -> void: _close(""))
	if first == null:
		first = later
	card.reset_size()
	card.position = ((Vector2(1280, 720) - card.get_combined_minimum_size()) * 0.5).round()
	UiKit.pop_in(card)
	Juice.play("res://assets/audio/claim.wav")
	var f := first
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(f):
			f.grab_focus()
	, CONNECT_ONE_SHOT)


func _clip() -> String:
	if StickBook.fits(move_id):
		var r: Dictionary = StickBook.CAT[move_id]
		if r.has("clips"):
			return str((r["clips"] as Array)[0])
		return {"jab": "jab", "gut": "gut", "mega_punch": "mega_punch", "haymaker": "heavy", "hook": "cross"}.get(move_id, move_id)
	return move_id


func _choice(host: Control, txt: String, key: String, cb: Callable) -> Button:
	var b := UiKit.button(txt, Vector2(540, 40))
	b.add_theme_font_size_override("font_size", 13)
	b.set_meta("key", key)
	b.pressed.connect(cb)
	host.add_child(b)
	return b


func _put_stick(slot: String) -> void:
	StickBook.set_slot(role, slot, move_id)
	Juice.toast("reward", "EQUIPPED  ·  %s" % StickBook.title(move_id), StickBook.NAME[slot])
	_close(slot)


func _put_button(slot: String) -> void:
	Moves.set_slot(role, slot, move_id)
	Juice.toast("reward", "EQUIPPED  ·  %s" % str(Moves.row(move_id).get("title", move_id)), str(Moves.SLOT_NAME[slot]))
	_close(slot)


func _close(slot: String) -> void:
	get_tree().paused = _was_paused
	finished.emit(slot)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close("")
