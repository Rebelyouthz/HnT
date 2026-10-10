extends Control

## Two small night-desk sheets in one script:
##   mode "artifacts"  NIGHT ARTIFACTS: toggle up to two risk / reward rules
##   mode "contracts"  DAILY CONTRACTS: today's three jobs, claim the pay

signal closed
signal need_refresh

var mode := "artifacts"


func _ready() -> void:
	_paint()


func _paint(keep := "") -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var col_a := Color(0.85, 0.45, 1.0) if mode == "artifacts" else UiKit.GOLD
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(col_a, 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -470
	card.offset_right = 470
	card.offset_top = -300
	card.offset_bottom = 300
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	var t := UiKit.title("NIGHT ARTIFACTS" if mode == "artifacts" else "DAILY CONTRACTS", 30, col_a)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.title_icon(t, "cur_power" if mode == "artifacts" else "head_jobs")
	head.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 38))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	col.add_child(head)
	var sub := Label.new()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(880, 0)
	UiKit.apply_label(sub, 13, Palette.MUTED)
	col.add_child(sub)
	var focus: Button = null
	if mode == "artifacts":
		sub.text = "Pick up to %d. Each makes the night harder and pays better. They stay on until you turn them off. ON: %d/%d" % [Artifacts.MAX_ON, Artifacts.on().size(), Artifacts.MAX_ON]
		for id: String in Artifacts.LIST:
			var row: Dictionary = Artifacts.LIST[id]
			var on := Artifacts.has(id)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 12)
			var info := UiKit.rich("[color=#ffd75e]%s[/color]\n[color=#ff6a5e]RISK[/color] %s   [color=#5effa0]REWARD[/color] %s" % [str(row["title"]), str(row["risk"]), str(row["reward"])], 700, 14, Palette.TEXT)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(info)
			var b := UiKit.button("ON" if on else "OFF", Vector2(130, 40))
			if on:
				b.add_theme_stylebox_override("normal", UiKit.panel(Color(0.3, 0.12, 0.4), col_a))
			b.set_meta("key", id)
			b.pressed.connect(func() -> void:
				if Artifacts.toggle(id):
					Juice.play("res://assets/audio/card.wav")
				else:
					Juice.popup_number(Vector2(640, 360), "TWO AT MOST", Palette.BRICK)
				need_refresh.emit()
				_paint(id)
			)
			line.add_child(b)
			col.add_child(line)
			if focus == null or id == keep:
				focus = b
	else:
		var left := Contracts.secs_left()
		sub.text = "Three jobs a day. New ones in %dh %02dm. Progress counts from the start of the day.   STREAK %d" % [left / 3600, (left % 3600) / 60, Contracts.streak()]
		for r: Dictionary in Contracts.list():
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 12)
			var jic := UiKit.portrait(IconBook.tex(str(r.get("icon", "head_jobs"))), Vector2(52, 52))
			line.add_child(jic)
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var nm := Label.new()
			nm.text = str(r["title"])
			nm.add_theme_font_override("font", UiKit.title_font())
			UiKit.apply_label(nm, 18, Palette.READY if bool(r["claimed"]) else Palette.TEXT)
			v.add_child(nm)
			var bar := UiKit.glow_bar(float(r["have"]) / float(r["n"]), UiKit.GOLD, Vector2(500, 10))
			v.add_child(bar)
			var prow := HBoxContainer.new()
			prow.add_theme_constant_override("separation", 6)
			var pl := Label.new()
			pl.text = "%d / %d   ·   PAY" % [int(r["have"]), int(r["n"])]
			UiKit.apply_label(pl, 12, Palette.MUTED)
			prow.add_child(pl)
			for cur in (r["pay"] as Dictionary):
				prow.add_child(UiKit.portrait(IconBook.tex(Contracts.pay_icon(str(cur))), Vector2(18, 18)))
				var pv := Label.new()
				pv.text = "%d %s" % [int(r["pay"][cur]), str(cur).to_upper()]
				UiKit.apply_label(pv, 12, UiKit.GOLD)
				prow.add_child(pv)
			v.add_child(prow)
			line.add_child(v)
			var done := int(r["have"]) >= int(r["n"])
			var b := UiKit.button("CLAIMED" if bool(r["claimed"]) else ("CLAIM" if done else "WORKING"), Vector2(150, 44))
			b.disabled = bool(r["claimed"]) or not done
			var rid := str(r["id"])
			b.pressed.connect(func() -> void:
				if Contracts.claim(rid):
					Juice.play("res://assets/audio/claim.wav")
					Juice.shout("CONTRACT DONE")
					need_refresh.emit()
					_paint()
			)
			line.add_child(b)
			col.add_child(line)
			if focus == null and not b.disabled:
				focus = b
		# All three: the bonus crate, bigger every day of the streak.
		var sep := HSeparator.new()
		col.add_child(sep)
		var brow := HBoxContainer.new()
		brow.add_theme_constant_override("separation", 12)
		brow.add_child(UiKit.portrait(IconBook.tex("cur_chest"), Vector2(64, 64)))
		var bl := Label.new()
		var st := mini(Contracts.streak() + 1, 7)
		bl.text = "ALL THREE  ·  BONUS CRATE\n+%d GOLD  +%d GEM  ·  grows each day in a row (day 7: 2 gems)" % [60 + 20 * st, 1]
		bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.apply_label(bl, 14, UiKit.GOLD)
		brow.add_child(bl)
		var bb := UiKit.button("OPEN" if Contracts.bonus_ready() else "LOCKED", Vector2(150, 44))
		bb.disabled = not Contracts.bonus_ready()
		if Contracts.bonus_ready():
			UiKit.ready_style(bb)
			UiKit.dark_text(bb)
			UiKit.pulse_ready(bb)
			focus = bb
		bb.pressed.connect(func() -> void:
			var got := Contracts.claim_bonus()
			if not got.is_empty():
				Juice.play("res://assets/audio/chest.wav")
				Juice.rewards.reveal("cur_chest", "BONUS CRATE  ·  STREAK %d" % int(got["streak"]), UiKit.GOLD, "+%d GOLD  ·  +%d GEMS" % [int(got["gold"]), int(got["gems"])], 1.4)
				need_refresh.emit()
				_paint()
		)
		brow.add_child(bb)
		col.add_child(brow)
	UiKit.pop_in(card)
	var fb: Button = focus if focus != null else close
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(fb):
			fb.grab_focus()
	, CONNECT_ONE_SHOT)
