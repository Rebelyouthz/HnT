extends Control

signal closed
signal need_refresh

const RAIL := [3, 5, 8]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.chrome())
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -340
	card.offset_right = 340
	card.offset_top = -240
	card.offset_bottom = 240
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = Copy.STREAK
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	var n := int(FamilyProfile.data.get("streak", 0))
	var best := int(FamilyProfile.data.get("streak_best", 0))
	var s := Label.new()
	s.text = "Consecutive files. Die and the rail resets. Claim is required — the clinic does not mail trophies.\nNOW  %d    BEST  %d" % [n, best]
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(s, 14, Palette.TEXT)
	col.add_child(s)
	var bar := ProgressBar.new()
	bar.max_value = 8
	bar.value = n
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	col.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for at in RAIL:
		row.add_child(_chest(at, n))
	col.add_child(row)
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
	close.grab_focus()
	card.pivot_offset = Vector2(340, 240)
	UiKit.pop_in(card)


func _chest(at: int, now: int) -> Control:
	var claimed: Array = FamilyProfile.data.get("streak_claimed", [])
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(168, 56)
	var already := claimed.has(at)
	var ready := now >= at and not already
	var b := UiKit.button("NIGHT %d" % at, Vector2(160, 48))
	if already:
		b.text = Copy.CLAIMED
		b.disabled = true
	elif not ready:
		b.disabled = true
	else:
		UiKit.ready_style(b)
		UiKit.dark_text(b)
		UiKit.pulse_ready(b)
	b.pressed.connect(func() -> void:
		if FamilyProfile.claim_streak(at):
			var gold := 20 + at * 8
			var gems := 1 if at >= 5 else 0
			Juice.claim_burst(get_viewport_rect().size * 0.5, "STREAK %d" % at, gold, gems)
			Juice.unlock_logo("STREAK FILED", "You came back. The fridge noticed.", "+%d GOLD" % gold)
			need_refresh.emit()
			closed.emit()
			queue_free()
	)
	wrap.add_child(b)
	if ready:
		var bang := UiKit.bang()
		bang.position = Vector2(140, -4)
		wrap.add_child(bang)
	return wrap
