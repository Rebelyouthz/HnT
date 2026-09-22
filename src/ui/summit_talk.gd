class_name SummitTalk
extends CanvasLayer

## Yes / no / deflect. Never punish a no. Deflect is one short line.

signal finished

var map_id := ""
var ate := false
var _talk: Dictionary = {}
var _who: Label
var _body: Label
var _prompt: Label
var _row: HBoxContainer
var _lines: Array = []
var _i := 0
var _choice := ""
var _phase := "eat"
var _bubbles: Control
var _mom := false
var _focus_i := 0
var _lock_t := 0.0
var _choice_ids: Array[String] = ["yes", "no", "deflect"]


func _ready() -> void:
	layer = 68
	process_mode = Node.PROCESS_MODE_ALWAYS
	_talk = TowerBook.talk_for_map(map_id)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -460
	card.offset_right = 460
	card.offset_top = 140
	card.offset_bottom = 340
	add_child(card)
	UiKit.pop_in(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_child(LogoMark.new())
	var title := Label.new()
	title.text = str(_talk.get("title", "140M"))
	UiKit.apply_label(title, 22, Palette.LEMON)
	head.add_child(title)
	col.add_child(head)
	_who = Label.new()
	UiKit.apply_label(_who, 13, Palette.EDGE)
	col.add_child(_who)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(880, 70)
	UiKit.apply_label(_body, 20, Palette.TEXT)
	col.add_child(_body)
	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(_prompt, 14, Palette.MUTED)
	col.add_child(_prompt)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 12)
	col.add_child(_row)
	_bubbles = Control.new()
	_bubbles.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubbles)
	Mixer.play_music(str(_talk.get("music", "res://assets/audio/music_summit.wav")))
	_begin()


func _begin() -> void:
	var rs := get_tree().get_first_node_in_group("run_state")
	var has_lunch := rs != null and rs.has_method("has_lunch") and bool(rs.call("has_lunch"))
	_phase = "eat"
	_prompt.text = Copy.LUNCH_140
	if has_lunch:
		rs.call("eat_lunch")
		ate = true
		FamilyProfile.note_summit_meal()
		if FamilyProfile.has_cbt("summit_joke"):
			FamilyProfile.add_gold(12)
			Juice.toast("reward", "SUMMIT JOKE", "+12 gold. Peace is also a sink.")
		_lines = [
			{"who": "son", "text": str(_talk.get("eat_joke", "We packed this. That's the assignment."))},
			{"who": "father", "text": "Sit. Eat. Nobody bills the wind."}
		]
	else:
		_lines = [
			{"who": "son", "text": "We didn't pack. That's also the assignment."},
			{"who": "father", "text": "Sit anyway. Nobody bills the wind."}
		]
	_paint_line()


func _paint_line() -> void:
	_row.visible = false
	if _i >= _lines.size():
		_advance_phase()
		return
	var row: Variant = _lines[_i]
	if typeof(row) != TYPE_DICTIONARY:
		_i += 1
		_paint_line()
		return
	var d: Dictionary = row
	var who := str(d.get("who", ""))
	_who.text = StoryBook.who_name(who)
	_who.add_theme_color_override("font_color", Palette.BRICK if who == "father" else (Palette.LEMON if who == "son" else Palette.EDGE))
	_body.text = str(d.get("text", ""))
	_prompt.text = "LIGHT / JUMP  ·  NEXT"
	if who == "father":
		VoBank.summit_dad()
	elif who == "son":
		VoBank.summit_son()
	Juice.play("res://assets/audio/ui_click.wav")


func _advance_phase() -> void:
	_i = 0
	match _phase:
		"eat":
			_phase = "opener"
			_lines = (_talk.get("opener", []) as Array).duplicate()
			_paint_line()
		"opener":
			_offer(str(_talk.get("prompt", "Yes?")))
		"answer":
			if _choice == "yes" and bool(_talk.get("bubbles", false)) and bool(_talk.get("bubble_yes_only", true)):
				_phase = "bubbles"
				_play_bubbles()
			elif _talk.has("second") and map_id == "processing_floor":
				_phase = "second"
				var sec: Dictionary = _talk["second"]
				_offer(str(sec.get("prompt", "Farm talk?")))
			else:
				_close()
		"second_answer":
			_close()
		_:
			_close()


func _offer(prompt: String) -> void:
	_prompt.text = prompt + "  ·  LEFT / RIGHT  ·  LIGHT CONFIRMS"
	_body.text = prompt
	_who.text = StoryBook.who_name("father")
	_row.visible = true
	_lock_t = 0.22
	_focus_i = 0
	while _row.get_child_count() > 0:
		var old := _row.get_child(0)
		_row.remove_child(old)
		old.free()
	_choice_btn("YES", "yes")
	_choice_btn("NO", "no")
	_choice_btn("DEFLECT", "deflect")
	_paint_focus()


func _choice_btn(label: String, id: String) -> void:
	var b := UiKit.button(label, Vector2(180, 44))
	if id == "yes":
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
	elif id == "deflect":
		b.add_theme_stylebox_override("normal", UiKit.panel(Palette.PANEL_2, Palette.MUTED))
	b.pressed.connect(func() -> void:
		_pick(id)
	)
	_row.add_child(b)


func _paint_focus() -> void:
	var kids := _row.get_children()
	for i in kids.size():
		var b := kids[i] as Button
		if b == null:
			continue
		if i == _focus_i:
			b.grab_focus()
			b.modulate = Color(1.15, 1.12, 0.85)
		else:
			b.modulate = Color.WHITE


func _activate_focus() -> void:
	if _focus_i < 0 or _focus_i >= _choice_ids.size():
		_focus_i = 0
	_pick(_choice_ids[_focus_i])


func _pick(id: String) -> void:
	_choice = id
	_row.visible = false
	var key := id
	if _phase == "second":
		var sec: Dictionary = _talk.get("second", {})
		_lines = (sec.get(key, sec.get("deflect", [])) as Array).duplicate()
		_phase = "second_answer"
	else:
		_lines = (_talk.get(key, []) as Array).duplicate()
		_phase = "answer"
	_i = 0
	FamilyProfile.note_talk_choice(str(_talk.get("id", "")), id)
	_paint_line()


func _play_bubbles() -> void:
	_prompt.text = "LIGHT  ·  NEXT MEMORY"
	_body.text = "You were three. I was twenty-six. We shot each other and we could not stop laughing."
	_who.text = StoryBook.who_name("father")
	_draw_bubble(Vector2(180, 80), Palette.LEMON, Palette.BRICK, "WAR")
	VoBank.summit_dad()
	_phase = "bubble2"


func _draw_bubble(at: Vector2, a: Color, b: Color, tag: String) -> void:
	var p := PanelContainer.new()
	p.position = at
	p.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	_bubbles.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	p.add_child(col)
	var l := Label.new()
	l.text = tag
	l.custom_minimum_size = Vector2(280, 28)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(l, 16, a)
	col.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_body_fig(a, 12, 28, 3))
	row.add_child(_body_fig(b, 22, 72, 26))
	col.add_child(row)
	var ages := Label.new()
	ages.text = "THREE  ·  TWENTY-SIX"
	ages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(ages, 11, Palette.MUTED)
	col.add_child(ages)


func _body_fig(col: Color, w: float, h: float, age: int) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(maxf(w + 16.0, 40.0), h + 18.0)
	var torso := ColorRect.new()
	torso.color = col
	torso.size = Vector2(w, h)
	torso.position = Vector2(8, 10)
	wrap.add_child(torso)
	var head := ColorRect.new()
	head.color = col.lightened(0.18)
	head.size = Vector2(w * 0.7, w * 0.7)
	head.position = Vector2(8 + w * 0.15, 2)
	wrap.add_child(head)
	var arm := ColorRect.new()
	arm.color = col.darkened(0.12)
	arm.size = Vector2(6, h * 0.45)
	arm.position = Vector2(4, 18)
	wrap.add_child(arm)
	var tag := Label.new()
	tag.text = str(age)
	tag.position = Vector2(8, h + 2)
	UiKit.apply_label(tag, 10, Palette.MUTED)
	wrap.add_child(tag)
	return wrap


func _mom_cut() -> void:
	_mom = true
	Mixer.stop_music()
	Juice.pulse_shake(8.0)
	Juice.shout("MUSIC DIES")
	_bubbles.modulate = Color(0.7, 0.2, 0.18)
	_body.text = "She comes through the door. Sells them. He's too small. Face going red. About to explode."
	_who.text = "MOM"
	_who.add_theme_color_override("font_color", Palette.BADGE)
	_prompt.text = "LIGHT  ·  LET IT END"
	_draw_bubble(Vector2(720, 70), Palette.BADGE, Palette.BRICK, "THE DOOR")
	Juice.play("res://assets/audio/mom_door.wav")


func _physics_process(delta: float) -> void:
	if _lock_t > 0.0:
		_lock_t -= delta
	if not has_node("/root/NetSession") or not NetSession.active():
		return
	if not _row.visible:
		if _net_tap("light") or _net_tap("jump"):
			_advance_line()
		return
	if _lock_t > 0.0:
		return
	if _net_tap("light") or _net_tap("jump"):
		_activate_focus()
	elif _net_tap("heavy"):
		_pick("no")
	elif _net_tap("special"):
		_pick("deflect")


func _net_tap(action: String) -> bool:
	if has_node("/root/NetSession") and NetSession.active():
		return NetSession.tapped(action)
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _row.visible:
		if _lock_t > 0.0:
			return
		if event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left") or event.is_action_pressed("ui_left"):
			_focus_i = wrapi(_focus_i - 1, 0, _choice_ids.size())
			_paint_focus()
		elif event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right") or event.is_action_pressed("ui_right"):
			_focus_i = wrapi(_focus_i + 1, 0, _choice_ids.size())
			_paint_focus()
		elif event.is_action_pressed("p1_light") or event.is_action_pressed("p1_jump") \
				or event.is_action_pressed("p2_light") or event.is_action_pressed("p2_jump"):
			_activate_focus()
		elif event.is_action_pressed("p1_heavy") or event.is_action_pressed("p2_heavy"):
			_pick("no")
		elif event.is_action_pressed("p1_special") or event.is_action_pressed("p2_special"):
			_pick("deflect")
		return
	if event.is_action_pressed("p1_light") or event.is_action_pressed("p1_jump") \
			or event.is_action_pressed("p2_light") or event.is_action_pressed("p2_jump"):
		_advance_line()


func _advance_line() -> void:
	if _phase == "bubble2":
		_mom_cut()
		_phase = "bubble_done"
		return
	if _phase == "bubble_done":
		_close()
		return
	_i += 1
	_paint_line()


func _close() -> void:
	Mixer.play_music("res://assets/audio/music_street.wav")
	finished.emit()
	queue_free()
