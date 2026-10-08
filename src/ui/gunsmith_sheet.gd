extends Control

## GUNSMITH for one gun. Left: the gun on the bench (GunView) with every
## fitted part on it, and the stat bars underneath; focusing a part shows a
## ghost of it on the gun and green / red changes on the bars. Right: the
## five slots, each a row of part tiles with their pixel icon. Press a tile:
## buy it (gems fly out of the wallet), fit it (it slides onto the gun and
## clicks home), or take it off again.

signal closed

var gun := "pistol"
var _view: GunView
var _bars := {}
var _info: RichTextLabel
var _wallet: Label
var _wallet_icon: Control
var _focus_key := ""

const STATS := [
	["DAMAGE", "dmg"], ["FIRE RATE", "rate"], ["RANGE", "range"],
	["CONTROL", "control"], ["MAGAZINE", "clip"], ["RELOAD", "reload"],
]
const ACCENT := Color(0.6, 0.9, 1.0)


func _ready() -> void:
	Guides.show(self, "gunsmith")
	_paint()


func _paint() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_bars.clear()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(ACCENT, 0.4))
	card.position = Vector2(40, 30)
	card.size = Vector2(1200, 660)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	# Header: name, level, the gem wallet (coins fly to and from it).
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var t := UiKit.title("GUNSMITH  ·  %s  ·  LV %d" % [str(WeaponBook.spec(gun).get("title", gun)).to_upper(), Arsenal.level(gun)], 24, ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_wallet_icon = IconBook.rect("cur_gem", IconBook.SIZE_S)
	head.add_child(_wallet_icon)
	Juice.rewards.register("gems", _wallet_icon)
	_wallet = Label.new()
	_wallet.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_wallet, 22, Palette.TEXT)
	_wallet.custom_minimum_size = Vector2(70, 0)
	head.add_child(_wallet)
	_refresh_wallet()
	if not Juice.rewards.landed.is_connected(_on_landed):
		Juice.rewards.landed.connect(_on_landed)
	col.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	# Left: bench + stats.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(600, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	_view = GunView.new()
	_view.custom_minimum_size = Vector2(600, 290)
	_view.size = Vector2(600, 290)
	_view.gun = gun
	left.add_child(_view)
	_view.call_deferred("setup", gun)
	var stats := PanelContainer.new()
	stats.add_theme_stylebox_override("panel", UiKit.panel(Color(0.04, 0.05, 0.08), Color(0.2, 0.3, 0.4)))
	left.add_child(stats)
	var sg := GridContainer.new()
	sg.columns = 2
	sg.add_theme_constant_override("h_separation", 12)
	sg.add_theme_constant_override("v_separation", 6)
	stats.add_child(sg)
	for s: Array in STATS:
		var l := Label.new()
		l.text = str(s[0])
		l.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(l, 13, Palette.TEXT)
		l.custom_minimum_size = Vector2(130, 0)
		sg.add_child(l)
		var bar := StatBar.new()
		bar.custom_minimum_size = Vector2(430, 18)
		sg.add_child(bar)
		_bars[str(s[1])] = bar
	_info = UiKit.rich("", 600, 13, Palette.TEXT, UiKit.pixel_font())
	_info.custom_minimum_size = Vector2(600, 64)
	left.add_child(_info)
	# Right: the slots.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var first: Button = null
	for slot: String in Attach.SLOTS:
		var open := Attach.slot_open(gun, slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		right.add_child(row)
		var lab := VBoxContainer.new()
		lab.custom_minimum_size = Vector2(92, 0)
		lab.alignment = BoxContainer.ALIGNMENT_CENTER
		var si := IconBook.rect("slot_" + slot, IconBook.SIZE_S)
		si.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lab.add_child(si)
		var sn := Label.new()
		sn.text = str(Attach.SLOT_NAME[slot]) if open else "LV %d" % int(Attach.SLOT_LV[slot])
		sn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sn.add_theme_font_override("font", UiKit.pixel_font())
		UiKit.apply_label(sn, 10, UiKit.GOLD if open else Palette.MUTED)
		lab.add_child(sn)
		row.add_child(lab)
		for a: String in Attach.LIST:
			if str(Attach.LIST[a]["slot"]) != slot:
				continue
			var b := _tile(a, open)
			row.add_child(b)
			if first == null and not b.disabled:
				first = b
	var done := UiKit.button("DONE", Vector2(200, 40))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.set_meta("key", "done")
	done.pressed.connect(func() -> void: closed.emit())
	right.add_child(done)
	_show_stats("")
	UiKit.pop_in(card)
	var want := _focus_key
	get_tree().process_frame.connect(func() -> void:
		for b in find_children("*", "Button", true, false):
			if str(b.get_meta("key", "")) == want and want != "":
				(b as Button).grab_focus()
				return
		if first:
			first.grab_focus()
		else:
			done.grab_focus()
	, CONNECT_ONE_SHOT)


func _tile(a: String, open: bool) -> Button:
	var spec: Dictionary = Attach.LIST[a]
	var owned := Attach.owned(a)
	var fitted := Attach.on(gun, str(spec["slot"])) == a and open
	var b := Button.new()
	b.custom_minimum_size = Vector2(104, 104)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "part_" + a)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.14, 0.1) if fitted else (Color(0.06, 0.07, 0.1) if owned else Color(0.04, 0.04, 0.06))
	bg.border_color = Palette.READY if fitted else (ACCENT if owned else Color(0.3, 0.3, 0.36))
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(4)
	var hi := bg.duplicate() as StyleBoxFlat
	hi.border_color = UiKit.GOLD
	hi.shadow_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.6)
	hi.shadow_size = 10
	b.add_theme_stylebox_override("normal", bg)
	b.add_theme_stylebox_override("hover", hi)
	b.add_theme_stylebox_override("focus", hi)
	b.add_theme_stylebox_override("pressed", hi)
	b.add_theme_stylebox_override("disabled", bg)
	var ic := IconBook.rect("part_" + a, IconBook.SIZE_M)
	ic.position = Vector2(20, 6)
	if not open:
		ic.modulate = Color(0.35, 0.35, 0.4)
	elif not owned:
		ic.modulate = Color(0.7, 0.7, 0.75)
	b.add_child(ic)
	var nm := Label.new()
	nm.text = str(spec["title"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.position = Vector2(2, 68)
	nm.size = Vector2(100, 14)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 9, Palette.TEXT if open else Palette.MUTED)
	b.add_child(nm)
	var st := HBoxContainer.new()
	st.alignment = BoxContainer.ALIGNMENT_CENTER
	st.position = Vector2(2, 82)
	st.size = Vector2(100, 18)
	st.add_theme_constant_override("separation", 2)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not owned:
		var gi := IconBook.rect("cur_gem", 18)
		st.add_child(gi)
	var sl := Label.new()
	sl.text = ("%d" % int(spec["gems"])) if not owned else ("ON" if fitted else ("FIT" if open else "OWNED"))
	sl.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(sl, 11, Palette.READY if fitted else (UiKit.GOLD if not owned else ACCENT))
	st.add_child(sl)
	b.add_child(st)
	b.disabled = not open and owned
	b.focus_entered.connect(func() -> void: _focus(a))
	b.mouse_entered.connect(func() -> void: _focus(a))
	b.pressed.connect(func() -> void: _press(a, b))
	return b


func _focus(a: String) -> void:
	var spec: Dictionary = Attach.LIST[a]
	var slot := str(spec["slot"])
	var open := Attach.slot_open(gun, slot)
	_view.preview(a if open else "")
	_show_stats(a if open else "")
	var state := ""
	if not open:
		state = "[color=#9a9aa8]Opens at gun LV %d.[/color]" % int(Attach.SLOT_LV[slot])
	elif not Attach.owned(a):
		state = "[color=#ffd75e]%d GEMS to buy (fits every gun).[/color]" % int(spec["gems"])
	elif Attach.on(gun, slot) == a:
		state = "[color=#7dffa0]On this gun. Press to take it off.[/color]"
	else:
		state = "[color=#9fe6ff]Owned. Press to fit it.[/color]"
	_info.text = "[color=#ffd75e]%s[/color]  %s\n%s" % [str(spec["title"]), UiKit.stat_bbcode(str(spec["line"])), state]


func _press(a: String, b: Button) -> void:
	var spec: Dictionary = Attach.LIST[a]
	var slot := str(spec["slot"])
	_focus_key = "part_" + a
	if not Attach.owned(a):
		if not Attach.buy(a):
			Juice.rewards.deny(b)
			return
		# Gems leave the wallet for the part.
		_spend_fx(int(spec["gems"]), b)
		Juice.upgrade_fx(b, ACCENT, "BOUGHT", false)
		_refresh_wallet()
		if Attach.slot_open(gun, slot) and Attach.on(gun, slot) != a:
			Attach.fit(gun, a)
			_after_fit(slot, true)
		else:
			_repaint_later()
		return
	var was_on := Attach.on(gun, slot) == a
	if not Attach.fit(gun, a):
		Juice.rewards.deny(b)
		return
	_after_fit(slot, not was_on)


func _after_fit(slot: String, put_on: bool) -> void:
	if put_on:
		_view.fit_anim(slot)
	else:
		_view.off_anim(slot)
	_repaint_later(0.55)


func _repaint_later(secs := 0.35) -> void:
	get_tree().create_timer(secs).timeout.connect(func() -> void:
		if is_inside_tree():
			_paint())


func _spend_fx(gems: int, to: Control) -> void:
	var tex := IconBook.tex("cur_gem_s")
	var from := RewardFly.vp_of(_wallet_icon)
	var dest := RewardFly.vp_of(to)
	for i in mini(gems * 2, 8):
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = from
		Juice.rewards.add_child(s)
		var bend := Vector2(randf_range(-40, 40), randf_range(-40, 0))
		var tw := s.create_tween()
		tw.tween_interval(0.04 * float(i))
		tw.tween_method(func(t: float) -> void:
			var mid := (from + dest) * 0.5 + bend
			s.position = from.lerp(mid, t).lerp(mid.lerp(dest, t), t).round()
		, 0.0, 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			RewardFly.snd("gem_land", 0.8 + 0.05 * float(i), -8.0)
			s.queue_free())


func _on_landed(_k: String) -> void:
	_refresh_wallet()


func _refresh_wallet() -> void:
	if _wallet:
		_wallet.text = str(int(FamilyProfile.data.get("gems", 0)) - Juice.rewards.pending("gems"))


## Multipliers with the parts on now, or with `part` swapped in.
func _mults(part: String) -> Dictionary:
	var d: Dictionary = FamilyProfile.data.get("attach_on", {})
	var had := d.has(gun)
	var keep: Variant = d.get(gun)
	if part != "":
		var f := {}
		for s in Attach.SLOTS:
			var a := Attach.on(gun, s)
			if a != "":
				f[s] = a
		var slot := str(Attach.LIST[part]["slot"])
		if str(f.get(slot, "")) == part:
			f.erase(slot)
		else:
			f[slot] = part
		d[gun] = f
		FamilyProfile.data["attach_on"] = d
	var out := {
		"dmg": Attach.dmg_mul(gun), "rate": 1.0 / Attach.rate_mul(gun), "range": Attach.range_mul(gun),
		"control": 1.0 / (Attach.spread_mul(gun) * Attach.recoil_mul(gun)), "clip": Attach.clip_mul(gun),
		"reload": 1.0 / Attach.reload_mul(gun),
	}
	if part != "":
		if had:
			d[gun] = keep
		else:
			d.erase(gun)
	return out


func _show_stats(part: String) -> void:
	var now := _mults("")
	var then := _mults(part) if part != "" else now
	for k in _bars:
		(_bars[k] as StatBar).set_vals(float(now[k]), float(then[k]))


## A segmented bar: 1.0 is the stock gun (half full); a preview shows the
## gain in green or the loss in red on top.
class StatBar extends Control:
	var now := 1.0
	var then := 1.0

	func set_vals(a: float, b: float) -> void:
		now = a
		then = b
		queue_redraw()

	func _draw() -> void:
		var segs := 20
		var w := (size.x - 150.0) / float(segs)
		var fa := clampf(now / 2.0, 0.0, 1.0)
		var fb := clampf(then / 2.0, 0.0, 1.0)
		for i in segs:
			var f := (float(i) + 0.5) / float(segs)
			var r := Rect2(Vector2(float(i) * w, 2), Vector2(w - 2, size.y - 4))
			var c := Color(0.12, 0.13, 0.17)
			if f <= minf(fa, fb):
				c = Color(0.86, 0.87, 0.9) if i % 2 == 0 else Color(0.7, 0.72, 0.78)
			elif f <= fb:
				c = Color(0.35, 1.0, 0.5)
			elif f <= fa:
				c = Color(1.0, 0.3, 0.28)
			draw_rect(r, c)
		# "1.00 > 1.20": now in grey, the change green (up) or red (down).
		var f := UiKit.pixel_font()
		var x := size.x - 140.0
		var a := "x%.2f" % now
		draw_string(f, Vector2(x, size.y - 4.0), a, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.85, 0.88))
		if absf(then - now) > 0.001:
			x += f.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 4.0
			draw_string(f, Vector2(x, size.y - 4.0), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.54, 0.55, 0.6))
			x += 10.0
			draw_string(f, Vector2(x, size.y - 4.0), "x%.2f" % then, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 1.0, 0.5) if then > now else Color(1.0, 0.35, 0.3))
