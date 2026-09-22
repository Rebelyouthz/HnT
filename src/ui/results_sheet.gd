class_name ResultsSheet
extends CanvasLayer

## After-act pinball recap + account XP. Death uses the same sheet, meaner.

var headline := "FILED"
var sub := ""
var win := true
var gate := false
var next_id := ""
var next_label := "NEXT"
var state: RunState
var _xp_bar: ProgressBar
var _xp_lab: Label


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.LEMON if win else Palette.BRICK))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -420
	card.offset_right = 420
	card.offset_top = -300
	card.offset_bottom = 300
	add_child(card)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(820, 580)
	card.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var t := Label.new()
	t.text = headline
	UiKit.apply_label(t, 30, Palette.LEMON if win else Palette.BRICK)
	col.add_child(t)
	var s := Label.new()
	s.text = sub
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(780, 0)
	UiKit.apply_label(s, 15, Palette.TEXT)
	col.add_child(s)
	var son_n := FamilyProfile.son_name()
	var dad_n := FamilyProfile.father_name()
	var son_s := 0
	var dad_s := 0
	var total := 0
	if state:
		son_s = state.score_son
		dad_s = state.score_dad
		total = state.score_total
	col.add_child(StatPanel.new([
		{"name": son_n, "value": "%06d" % son_s, "color": Palette.LEMON},
		{"name": dad_n, "value": "%06d" % dad_s, "color": Palette.BRICK},
		{"name": "TABLE", "value": "%06d" % total, "color": Palette.EDGE},
		{"name": "WINNER", "value": _winner(son_s, dad_s, son_n, dad_n), "color": Palette.READY}
	]))
	var lead := Label.new()
	if son_s == dad_s:
		lead.text = "TIE. The clinic bills you both. That's fair, in hell."
	elif son_s > dad_s:
		lead.text = "%s put more points on the table. %s will workshop that." % [son_n, dad_n]
	else:
		lead.text = "%s outscored the kid. The tutoring license just winced." % dad_n
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(lead, 14, Palette.MUTED)
	col.add_child(lead)
	col.add_child(StatPanel.new([
		{"name": "SMASH", "value": str(int(FamilyProfile.data.get("smash_kills", 0))), "color": Palette.EDGE},
		{"name": "PARRY", "value": str(int(FamilyProfile.data.get("parries", 0))), "color": Palette.LEMON},
		{"name": "CATCH", "value": str(int(FamilyProfile.data.get("catches", 0))), "color": Palette.EDGE},
		{"name": "CLASH", "value": str(int(FamilyProfile.data.get("clashes", 0))), "color": Palette.BRICK}
	]))
	var grant := _grant_xp(total)
	_xp_lab = Label.new()
	_xp_lab.text = "ACCOUNT  LV %d" % int(grant.get("level", 1))
	UiKit.apply_label(_xp_lab, 16, Palette.EDGE)
	col.add_child(_xp_lab)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(760, 22)
	_xp_bar.max_value = float(grant.get("need", 100))
	_xp_bar.value = 0.0
	_xp_bar.show_percentage = false
	col.add_child(_xp_bar)
	var xp_line := Label.new()
	xp_line.text = "+%d ACCOUNT XP  ·  %d / %d to next growth spurt" % [
		int(grant.get("gained", 0)), int(grant.get("xp", 0)), int(grant.get("need", 100))
	]
	UiKit.apply_label(xp_line, 13, Palette.TEXT)
	col.add_child(xp_line)
	if gate and next_id != "":
		var nxt := UiKit.button(next_label, Vector2(360, 52))
		nxt.process_mode = Node.PROCESS_MODE_ALWAYS
		nxt.pressed.connect(_go_next)
		col.add_child(nxt)
		nxt.grab_focus()
	var b := UiKit.button("BACK TO THE CLINIC", Vector2(280, 48))
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(_go_hub)
	col.add_child(b)
	if not gate:
		b.grab_focus()
	Juice.pulse_shake(8.0 if win else 5.0)
	if win:
		Juice.unlock_logo(headline, sub)
	_tween_xp(float(grant.get("xp", 0)), int(grant.get("dings", 0)))
	Juice.toast("reward", "PINBALL", "%s %06d  ·  %s %06d" % [son_n, son_s, dad_n, dad_s])
	if state and state.score_total > 0 and state.score_total == int(FamilyProfile.data.get("high_score", 0)):
		Juice.unlock_logo("HIGH TABLE", "The clipboard wrote it in gold ink.")
		Juice.shout("HIGH TABLE")


func _winner(son_s: int, dad_s: int, son_n: String, dad_n: String) -> String:
	if son_s == dad_s:
		return "TIE"
	return son_n if son_s > dad_s else dad_n


func _grant_xp(total: int) -> Dictionary:
	var n := maxi(8, int(total / 20.0) + (90 if win else 18))
	if gate:
		n = maxi(8, int(total / 28.0) + 40)
	return FamilyProfile.grant_account_xp(n)


func _tween_xp(xp: float, dings: int) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_ignore_time_scale(true)
	tw.tween_property(_xp_bar, "value", xp, 0.55)
	if dings > 0:
		tw.tween_callback(func() -> void:
			Juice.unlock_logo("ACCOUNT LEVEL UP", "Growth. Billed. The fridge stays.")
			Juice.toast("achievement", "LEVEL UP", "The clipboard added a zero.")
			if _xp_lab:
				_xp_lab.text = "ACCOUNT  LV %d" % int(FamilyProfile.data.get("account_level", 1))
		)


func _go_next() -> void:
	get_tree().paused = false
	if state:
		App.advance(next_id, state)


func _go_hub() -> void:
	get_tree().paused = false
	if win and gate:
		FamilyProfile.mark_run_finished(true)
		if App.is_solo_density():
			FamilyProfile.mark_solo_clear()
		FamilyProfile.push_log(headline, sub)
	Mixer.play_music("res://assets/audio/music_clinic.wav")
	if App.remote_coop:
		NetSession.shutdown()
	App.back_to_hub("awards" if win else "clinic")
