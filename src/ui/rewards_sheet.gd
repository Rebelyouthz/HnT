extends Control

## REWARDS desk (see RewardBook). Left: the DAILY CRATE with its 7-day strip
## (the crate shakes, bursts and the coins fly) and READY TO CLAIM, every
## claimable in the game with CLAIM ALL. Right: the CLINIC ROAD (a tile per
## account level) and TITLES to wear under the names in the hub.

signal closed

const ACCENT := Color(1.0, 0.56, 0.12)
const GREEN := Color(0.45, 1.0, 0.6)

var _focus_key := ""
var _crate: Control


func _ready() -> void:
	RewardBook.refresh_titles()
	Guides.show(self, "rewards")
	_paint()


func _paint() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(ACCENT, 0.4))
	card.position = Vector2(30, 24)
	card.size = Vector2(1220, 672)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(IconBook.rect("cur_gift", IconBook.SIZE_S))
	var t := UiKit.title("REWARDS", 28, ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(IconBook.rect("cur_power", IconBook.SIZE_S))
	var pw := Label.new()
	pw.text = "POWER %s" % UiKit.num(RewardBook.power())
	pw.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(pw, 18, Color(1.0, 0.75, 0.4))
	pw.custom_minimum_size = Vector2(200, 0)
	head.add_child(pw)
	var rows := RewardBook.claimables()
	var all := _btn("CLAIM ALL  (%d)" % rows.size(), Vector2(200, 44), "all")
	all.disabled = rows.is_empty()
	if not rows.is_empty():
		UiKit.ready_style(all)
		UiKit.dark_text(all)
		UiKit.pulse_ready(all)
	all.pressed.connect(func() -> void: _claim_all(all))
	head.add_child(all)
	var close := _btn("CLOSE", Vector2(110, 44), "close")
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	col.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(600, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	left.add_child(_daily())
	left.add_child(_ready_list(rows))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	right.add_child(_road())
	right.add_child(_titles())
	UiKit.pop_in(card)
	var want := _focus_key if _focus_key != "" else ("crate" if RewardBook.daily_ready() else "all")
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and not (b as Button).disabled:
				(b as Button).grab_focus()
				return
		close.grab_focus()
	, CONNECT_ONE_SHOT)


# --- daily crate --------------------------------------------------------------

func _daily() -> Control:
	var p := _panel(ACCENT)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	var ready := RewardBook.daily_ready()
	_crate = IconBook.rect("cur_gift", IconBook.SIZE_L)
	_crate.pivot_offset = Vector2(64, 120)
	if ready:
		var tw := _crate.create_tween().set_loops()
		tw.tween_property(_crate, "rotation", 0.06, 0.08)
		tw.tween_property(_crate, "rotation", -0.06, 0.08)
		tw.tween_property(_crate, "rotation", 0.0, 0.08)
		tw.tween_interval(1.2)
	else:
		_crate.modulate = Color(0.55, 0.55, 0.6)
	h.add_child(_crate)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiKit.title("DAILY CRATE", 18, ACCENT))
	var step := RewardBook.daily_step()
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	for d in range(1, 8):
		var cell := PanelContainer.new()
		var done := d < step or (d == step and not ready)
		var now := d == step and ready
		var edge := GREEN if done else (UiKit.GOLD if now else Color(0.3, 0.32, 0.4))
		var sb := UiKit.panel(Color(0.06, 0.07, 0.11) if not now else Color(0.18, 0.12, 0.04), edge)
		sb.set_border_width_all(3 if now else 2)
		cell.add_theme_stylebox_override("panel", sb)
		cell.custom_minimum_size = Vector2(58, 64)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 0)
		cell.add_child(cv)
		var dl := Label.new()
		dl.text = "DAY %d" % d
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(dl, 8, edge)
		cv.add_child(dl)
		var ic := IconBook.rect("cur_chest" if d == 7 else ("cur_gem" if int(RewardBook.daily_pay(d)["gems"]) > 0 else "cur_gold"), 32)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if done:
			ic.modulate = Color(0.6, 0.65, 0.6)
		cv.add_child(ic)
		var gl := Label.new()
		gl.text = "OK" if done else str(int(RewardBook.daily_pay(d)["gold"]))
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(gl, 8, GREEN if done else Palette.TEXT)
		cv.add_child(gl)
		if now:
			UiKit.pulse_ready(cell)
		strip.add_child(cell)
	v.add_child(strip)
	var pay := RewardBook.daily_pay(step)
	var today := Label.new()
	today.text = ("TODAY  " if ready else "TOMORROW  ") + RewardBook.pay_text(pay if ready else RewardBook.daily_pay(step % 7 + 1))
	today.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(today, 10, Color(UiKit.UP_COL))
	v.add_child(today)
	var ob := _btn("OPEN CRATE" if ready else "NEXT IN %s" % _hms(RewardBook.daily_wait()), Vector2(220, 40), "crate")
	ob.disabled = not ready
	if ready:
		UiKit.ready_style(ob)
		UiKit.dark_text(ob)
	ob.pressed.connect(func() -> void: _open_crate(ob))
	v.add_child(ob)
	return p


func _open_crate(btn: Button) -> void:
	if not RewardBook.daily_ready():
		RewardFly.snd("deny")
		return
	btn.disabled = true
	# Build-up: the crate rattles harder and harder, then bursts.
	var tw := _crate.create_tween().set_ignore_time_scale(true)
	for i in 6:
		var a := 0.08 + 0.03 * float(i)
		tw.tween_property(_crate, "rotation", a, 0.04)
		tw.tween_property(_crate, "rotation", -a, 0.04)
		tw.tween_callback(func() -> void: RewardFly.snd("part_click", 0.8 + 0.1 * float(i), -6.0))
	tw.tween_property(_crate, "rotation", 0.0, 0.03)
	tw.parallel().tween_property(_crate, "scale", Vector2(1.35, 1.35), 0.08)
	tw.tween_callback(func() -> void:
		var at := RewardFly.vp_of(_crate)
		var pay := RewardBook.open_daily()
		Juice.upgrade_fx(_crate, ACCENT, "DAY %d" % int(pay.get("step", 1)), true)
		for k: String in ["gold", "gems", "tokens"]:
			if int(pay.get(k, 0)) > 0:
				Juice.give(k, int(pay[k]), at + Vector2(randf_range(-30, 30), randf_range(-14, 6)))
		if int(pay.get("step", 1)) == 7:
			Juice.rewards.reveal("cur_chest", "DAY 7  ·  BIG CRATE", ACCENT, RewardBook.pay_text(pay))
		_after_claim("crate"))


# --- ready to claim -------------------------------------------------------------

func _ready_list(rows: Array) -> Control:
	var p := _panel(Palette.READY)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(UiKit.title("READY TO CLAIM", 16, Palette.READY))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 250)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	if rows.is_empty():
		var e := Label.new()
		e.text = "NOTHING WAITING. GO OUT AND EARN SOME."
		e.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(e, 10, Palette.MUTED)
		list.add_child(e)
	for i in rows.size():
		var row: Dictionary = rows[i]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(IconBook.rect(str(row["icon"]), 32))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tl := Label.new()
		tl.text = str(row["title"])
		tl.clip_text = true
		tl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(tl, 10, Palette.TEXT)
		tv.add_child(tl)
		var pt := RewardBook.pay_text(row["pay"])
		var pl := Label.new()
		pl.text = pt if pt != "" else "GOLD + GEMS"
		pl.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(pl, 9, Color(UiKit.UP_COL))
		tv.add_child(pl)
		h.add_child(tv)
		var b := _btn("CLAIM", Vector2(100, 34), "row_%d" % i)
		b.pressed.connect(func() -> void:
			var at := RewardBook.claimables()
			for r: Dictionary in at:
				if str(r["kind"]) == str(row["kind"]) and str(r["id"]) == str(row["id"]):
					_claim_row(r, b)
					return)
		h.add_child(b)
		list.add_child(h)
	return p


func _claim_row(row: Dictionary, from: Control) -> void:
	if str(row["kind"]) == "daily":
		_open_crate(from as Button)
		return
	var pay := RewardBook.claim(row)
	_fly(pay, RewardFly.vp_of(from))
	Juice.upgrade_fx(from, Palette.READY, "CLAIMED", str(row["kind"]) == "road" and int(row["id"]) % 5 == 0)
	_after_claim("all")


func _claim_all(from: Control) -> void:
	var tot := {}
	var n := 0
	# Repeat until dry: claiming a road level can't open more, but the codex
	# row covers many entries at once.
	for row: Dictionary in RewardBook.claimables():
		var pay := RewardBook.claim(row)
		n += 1
		for k: String in pay:
			if k in ["gold", "gems", "tokens", "flow"]:
				tot[k] = int(tot.get(k, 0)) + int(pay[k])
	if n == 0:
		RewardFly.snd("deny")
		return
	_fly(tot, RewardFly.vp_of(from))
	Juice.upgrade_fx(from, ACCENT, "%d CLAIMED" % n, true)
	Juice.rewards.reveal("cur_gift", "ALL CLAIMED", ACCENT, RewardBook.pay_text(tot), 1.3)
	_after_claim("close")


func _fly(pay: Dictionary, at: Vector2) -> void:
	var i := 0
	for k: String in ["gold", "gems", "tokens", "flow"]:
		if int(pay.get(k, 0)) > 0:
			Juice.give(k, int(pay[k]), at + Vector2(0, -10.0 * float(i)))
			i += 1


func _after_claim(focus: String) -> void:
	for id in RewardBook.refresh_titles():
		var t: Dictionary = RewardBook.TITLES[id]
		Juice.toast("quest", "NEW TITLE", str(t["title"]), "cur_title")
	_focus_key = focus
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_inside_tree():
			_paint())


# --- clinic road ----------------------------------------------------------------

func _road() -> Control:
	var p := _panel(Color(0.4, 0.85, 1.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var lv := int(FamilyProfile.data.get("account_level", 1))
	v.add_child(UiKit.title("CLINIC ROAD  ·  ACCOUNT LV %d" % lv, 16, Color(0.4, 0.85, 1.0)))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 150)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	sc.add_child(strip)
	var ready := RewardBook.road_ready()
	var claimed := RewardBook.road_claimed()
	for l in range(2, RewardBook.ROAD_MAX + 1):
		var big := l % 5 == 0
		var st := "claimed" if claimed.has(l) else ("ready" if ready.has(l) else "locked")
		var b := Button.new()
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(78 if big else 64, 128)
		b.set_meta("key", "road_%d" % l)
		var edge := GREEN if st == "claimed" else (UiKit.GOLD if st == "ready" else Color(0.28, 0.3, 0.38))
		if big and st == "locked":
			edge = Color(0.6, 0.4, 0.9)
		var sb := UiKit.panel(Color(0.05, 0.06, 0.1), edge)
		sb.set_border_width_all(3 if st == "ready" else 2)
		var hi := sb.duplicate() as StyleBoxFlat
		hi.border_color = UiKit.GOLD
		hi.bg_color = Color(0.14, 0.11, 0.05)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", hi)
		b.add_theme_stylebox_override("focus", hi)
		b.add_theme_stylebox_override("pressed", hi)
		var cv := VBoxContainer.new()
		cv.set_anchors_preset(Control.PRESET_FULL_RECT)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_theme_constant_override("separation", 2)
		b.add_child(cv)
		var ll := Label.new()
		ll.text = "LV %d" % l
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ll.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(ll, 9, edge if st != "locked" else Palette.MUTED)
		cv.add_child(ll)
		var pay := RewardBook.road_pay(l)
		var ic := IconBook.rect("cur_chest" if big else ("cur_gem" if int(pay.get("gems", 0)) > 0 else "cur_gold"), 32 if not big else 42)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if st == "locked":
			ic.modulate = Color(0.4, 0.4, 0.45)
		elif st == "ready":
			UiKit.pulse_ready(ic)
		cv.add_child(ic)
		for k: String in ["gold", "gems", "tokens"]:
			if int(pay.get(k, 0)) > 0:
				var pl := Label.new()
				pl.text = "%d %s" % [int(pay[k]), {"gold": "G", "gems": "GEM", "tokens": "S"}[k]]
				pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pl.add_theme_font_override("font", UiKit.pixel_font())
				UiKit.apply_label(pl, 8, Palette.TEXT if st != "locked" else Palette.MUTED)
				cv.add_child(pl)
		if st == "claimed":
			var ok := Label.new()
			ok.text = "OK"
			ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ok.add_theme_font_override("font", UiKit.pixel_font())
			UiKit.apply_label(ok, 8, GREEN)
			cv.add_child(ok)
		var lvl := l
		b.pressed.connect(func() -> void:
			if RewardBook.road_ready().has(lvl):
				var got := RewardBook.claim_road(lvl)
				_fly(got, RewardFly.vp_of(b))
				Juice.upgrade_fx(b, UiKit.GOLD, "LV %d" % lvl, lvl % 5 == 0)
				if lvl % 5 == 0:
					Juice.rewards.reveal("cur_chest", "CLINIC ROAD  ·  LV %d" % lvl, Color(0.4, 0.85, 1.0), RewardBook.pay_text(got))
				_after_claim("road_%d" % lvl)
			else:
				RewardFly.snd("deny")
				Juice.rewards.deny(b))
		strip.add_child(b)
		if l == maxi(2, lv):
			get_tree().process_frame.connect(func() -> void:
				if is_instance_valid(sc) and is_instance_valid(b):
					sc.scroll_horizontal = maxi(0, int(b.position.x) - 200)
			, CONNECT_ONE_SHOT)
	return p


# --- titles ---------------------------------------------------------------------

func _titles() -> Control:
	var p := _panel(UiKit.GOLD)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 6)
	hh.add_child(IconBook.rect("cur_title", 32))
	hh.add_child(UiKit.title("TITLES  ·  WEARING: %s" % RewardBook.title(), 16, UiKit.GOLD))
	v.add_child(hh)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	var own := RewardBook.titles_owned()
	var wearing := str(FamilyProfile.data.get("title", "new_patient"))
	for id: String in RewardBook.TITLES:
		var t: Dictionary = RewardBook.TITLES[id]
		var has := own.has(id)
		var pr := RewardBook.title_progress(id)
		var txt := str(t["title"]) if has else "%s  %d/%d" % [str(t["title"]), pr.x, pr.y]
		var b := _btn(("WORN  " if id == wearing else "") + txt, Vector2(280, 32), "title_" + id)
		b.tooltip_text = str(t["line"])
		if not has:
			b.add_theme_color_override("font_color", Palette.MUTED)
			b.add_theme_color_override("font_disabled_color", Palette.MUTED)
		elif id == wearing:
			b.add_theme_color_override("font_color", UiKit.GOLD)
		if has and FamilyProfile.is_unseen("title_" + id):
			var dot := UiKit.new_dot()
			dot.position = Vector2(270, -3)
			b.add_child(dot)
		b.pressed.connect(func() -> void:
			if not has:
				Juice.rewards.deny(b)
				RewardFly.snd("deny")
				Juice.toast("quest", str(t["title"]), str(t["line"]), "cur_lock")
				return
			RewardBook.wear_title(id)
			_focus_key = "title_" + id
			_paint()
			UiKit.fx_after(self, "title_" + id, UiKit.GOLD, "NOW WEARING", false))
		grid.add_child(b)
	v.add_child(_power_parts())
	return p


## Where POWER comes from, one bar per source.
func _power_parts() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 6)
	hh.add_child(IconBook.rect("cur_power", 32))
	hh.add_child(UiKit.title("POWER  ·  %d" % RewardBook.power(), 16, Color(1.0, 0.75, 0.4)))
	box.add_child(hh)
	var tree_p := 0
	for m: String in Trees.MODES:
		tree_p += 6 * Trees.count(m).x
	var meta_p := 0
	for id: String in Meta.LIST:
		meta_p += 4 * Meta.rank(id)
	var st_p := 0
	for id: String in SurvStarter.LIST:
		st_p += 3 * maxi(0, SurvStarter.level(id) - 1)
	var parts := [["THE KID", Heroes.power("son"), Palette.EDGE], ["DAD", Heroes.power("father"), Palette.LEMON], ["SKILL TREES", tree_p, Color(0.45, 1.0, 0.6)], ["META", meta_p, Color(0.4, 0.85, 1.0)], ["STARTERS", st_p, ACCENT]]
	var top := 1
	for pr in parts:
		top = maxi(top, int(pr[1]))
	for pr in parts:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = str(pr[0])
		l.custom_minimum_size = Vector2(130, 0)
		l.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(l, 9, Palette.TEXT)
		h.add_child(l)
		var bg := ColorRect.new()
		bg.color = Color(0, 0, 0.02, 0.8)
		bg.custom_minimum_size = Vector2(300, 10)
		bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bg)
		var fg := ColorRect.new()
		fg.color = pr[2]
		fg.size = Vector2(0, 10)
		bg.add_child(fg)
		fg.create_tween().tween_property(fg, "size:x", 300.0 * float(pr[1]) / float(top), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var n := Label.new()
		n.text = str(int(pr[1]))
		n.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(n, 9, pr[2])
		h.add_child(n)
		box.add_child(h)
	return box


# --- helpers ------------------------------------------------------------------

func _panel(edge: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiKit.panel(Color(0.04, 0.05, 0.08), Color(edge.r, edge.g, edge.b, 0.7))
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


func _hms(s: int) -> String:
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func _btn(txt: String, sz: Vector2, key: String) -> Button:
	var b := UiKit.button(txt, sz)
	b.add_theme_font_size_override("font_size", 11)
	b.set_meta("key", key)
	return b
