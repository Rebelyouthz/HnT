extends Control

signal closed
signal need_refresh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(Palette.PANEL, Palette.EDGE))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -340
	card.offset_right = 340
	card.offset_top = -200
	card.offset_bottom = 200
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var h := Label.new()
	h.text = "QUICK PATROL"
	UiKit.apply_label(h, 24, Palette.LEMON)
	col.add_child(h)
	FamilyProfile.settle_idle()
	var left := int(FamilyProfile.data.get("patrol_left", 0))
	var active := bool(FamilyProfile.data.get("patrol_active", false))
	var ready := FamilyProfile.patrol_ready()
	var until := int(FamilyProfile.data.get("patrol_until", 0))
	var now := int(Time.get_unix_time_from_system())
	var sub := Label.new()
	if ready:
		sub.text = "The alley came home. Claim gold, XP, and a coil. Ticked while you were gone."
	elif active:
		sub.text = "On the street. %ds left. Idle of the Dead rules: closed still counts." % maxi(0, until - now)
	else:
		sub.text = "2×/day. 12 minutes. Gold and XP while the game is closed AND while you play. Left today: %d." % left
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(sub, 14, Palette.TEXT)
	col.add_child(sub)
	if ready:
		var claim := UiKit.button("CLAIM PATROL", Vector2(240, 48))
		claim.add_theme_stylebox_override("normal", UiKit.panel(Palette.READY, Palette.LEMON))
		UiKit.dark_text(claim)
		claim.pressed.connect(func() -> void:
			FamilyProfile.claim_patrol()
			need_refresh.emit()
			closed.emit()
			queue_free()
		)
		col.add_child(claim)
		claim.grab_focus()
	elif not active:
		var go := UiKit.button("SEND PATROL", Vector2(240, 48))
		go.disabled = left <= 0
		go.pressed.connect(func() -> void:
			if FamilyProfile.start_patrol():
				need_refresh.emit()
				closed.emit()
				queue_free()
			else:
				Juice.shout("TWO A DAY. THAT'S THE BOUNDARY.")
		)
		col.add_child(go)
		go.grab_focus()
	var close := UiKit.button("CLOSE", Vector2(140, 44))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	col.add_child(close)
