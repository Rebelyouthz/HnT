extends Control

## MOD BENCH for one melee weapon, the melee twin of the GUNSMITH. Left: the
## weapon big on the bench with every fitted mod drawn on it (MeleeDress),
## the slots, and stat rows (grey now, green / red after). Right: a tile per
## mod with its icon. Focus a tile: a ghost of the mod shows on the weapon
## and the rows preview the change. Buy: gems leave the wallet, the mod's
## icon stands big in the middle and flies onto the weapon. Fit: the mod
## goes on piece by piece (nails hammered in one by one, tape wound up the
## grip ...) with a sound per piece and the gain pops over the weapon.

signal closed

var weapon := "baseball_bat"
var _dress: MeleeDress
var _holder: Node2D
var _bench: Control
var _rows := {}
var _info: RichTextLabel
var _wallet: Label
var _wallet_icon: Control
var _focus_key := ""
var _busy := false

const ACCENT := Color(0.6, 0.9, 1.0)
const STATS := [["DAMAGE", "dmg"], ["LASTS", "uses"], ["BLEED", "bleed"], ["CRIT", "crit"], ["STUN", "stun"]]
const SOUND := {
	"nails": "res://assets/audio/hammer.wav", "tape_grip": "res://assets/audio/whoosh_light.wav",
	"weighted": "res://assets/audio/block.wav", "serrated": "res://assets/audio/snap.wav",
	"live_wire": "res://assets/audio/zap.wav",
}
const GAIN := {
	"nails": "BLEED 3 TICKS", "tape_grip": "+60% LASTS", "weighted": "+25% DAMAGE",
	"serrated": "15% CRIT", "live_wire": "20% STUN",
}


func _ready() -> void:
	_paint()


func _paint() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_rows.clear()
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
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var t := UiKit.title("MOD BENCH  ·  %s  ·  LV %d" % [str(WeaponBook.spec(weapon).get("title", weapon)).to_upper(), Arsenal.level(weapon)], 24, ACCENT)
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
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(600, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	left.add_child(_make_bench())
	left.add_child(_slot_row())
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
		l.custom_minimum_size = Vector2(110, 0)
		sg.add_child(l)
		var r := StatRow.new()
		r.key = str(s[1])
		r.custom_minimum_size = Vector2(450, 18)
		sg.add_child(r)
		_rows[str(s[1])] = r
	_info = UiKit.rich("", 600, 13, Palette.TEXT, UiKit.pixel_font())
	_info.custom_minimum_size = Vector2(600, 56)
	left.add_child(_info)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	right.add_child(grid)
	var first: Button = null
	for m: String in Arsenal.MODS:
		if str(Arsenal.MODS[m]["for"]) != "melee":
			continue
		var b := _tile(m)
		grid.add_child(b)
		if first == null:
			first = b
	var done := UiKit.button("DONE", Vector2(200, 40))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.set_meta("key", "done")
	done.pressed.connect(func() -> void: closed.emit())
	right.add_child(done)
	_show_stats("")
	_info.text = "[color=#9fe6ff]Pick a mod: a ghost of it shows on the weapon, the rows show what changes.[/color]"
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


func _make_bench() -> Control:
	_bench = Panel.new()
	_bench.custom_minimum_size = Vector2(600, 250)
	_bench.clip_contents = true
	_bench.add_theme_stylebox_override("panel", UiKit.panel(Color(0.07, 0.06, 0.06), Color(0.32, 0.24, 0.16)))
	# Workbench planks behind the weapon.
	var planks := ColorRect.new()
	planks.color = Color(0.2, 0.13, 0.08)
	planks.position = Vector2(8, 150)
	planks.size = Vector2(584, 92)
	_bench.add_child(planks)
	for i in 3:
		var seam := ColorRect.new()
		seam.color = Color(0.12, 0.08, 0.05)
		seam.position = Vector2(8, 150 + 30 * i)
		seam.size = Vector2(584, 2)
		_bench.add_child(seam)
	var p := "res://assets/sprites/held/%s.png" % weapon
	var tex: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_holder = Node2D.new()
	_bench.add_child(_holder)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_holder.add_child(spr)
	_dress = MeleeDress.new()
	_dress.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.add_child(_dress)
	_dress.setup(weapon, Arsenal.mods_on(weapon))
	_dress.tick.connect(_on_tick)
	var sz := tex.get_size() if tex else Vector2(48, 16)
	var s := floorf(minf(540.0 / sz.x, 170.0 / sz.y))
	_holder.scale = Vector2(s, s)
	_holder.position = (Vector2(600, 230) - sz * s) * 0.5
	_holder.set_meta("home", _holder.position)
	# A slow idle bob so the bench feels alive.
	var tw := _holder.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(spr, "position:y", -2.0, 1.1)
	tw.tween_property(spr, "position:y", 0.0, 1.1)
	return _bench


func _slot_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = "SLOTS"
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 13, Palette.TEXT)
	row.add_child(l)
	var on := Arsenal.mods_on(weapon)
	for i in 2:
		var open := i < Arsenal.slots(weapon)
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(44, 44)
		box.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.07, 0.1), Palette.READY if i < on.size() else (ACCENT if open else Color(0.3, 0.3, 0.36))))
		if i < on.size():
			var ic := IconBook.rect("mod_" + str(on[i]), 32)
			box.add_child(ic)
		elif not open:
			var lk := IconBook.rect("cur_lock", 28)
			box.add_child(lk)
		row.add_child(box)
	var hint := Label.new()
	hint.text = "2nd slot opens at weapon LV 3" if Arsenal.slots(weapon) < 2 else "Both slots open"
	UiKit.apply_label(hint, 11, Palette.MUTED)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)
	return row


func _tile(m: String) -> Button:
	var spec: Dictionary = Arsenal.MODS[m]
	var owned := Arsenal.mod_owned(m)
	var fitted := Arsenal.has_mod(weapon, m)
	var b := Button.new()
	b.custom_minimum_size = Vector2(176, 150)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("key", "mod_" + m)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.14, 0.1) if fitted else (Color(0.06, 0.07, 0.1) if owned else Color(0.04, 0.04, 0.06))
	bg.border_color = Palette.READY if fitted else (ACCENT if owned else Color(0.3, 0.3, 0.36))
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(4)
	var hi := bg.duplicate() as StyleBoxFlat
	hi.border_color = UiKit.GOLD
	b.add_theme_stylebox_override("normal", bg)
	b.add_theme_stylebox_override("hover", hi)
	b.add_theme_stylebox_override("focus", hi)
	b.add_theme_stylebox_override("pressed", hi)
	var ic := IconBook.rect("mod_" + m, 64)
	ic.position = Vector2(56, 8)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not owned:
		ic.modulate = Color(0.7, 0.7, 0.75)
	b.add_child(ic)
	if fitted:
		# A slow shine on the icon of a mod that is on.
		var tw := ic.create_tween().set_loops()
		tw.tween_property(ic, "modulate", Color(1.25, 1.25, 1.1), 0.7)
		tw.tween_property(ic, "modulate", Color.WHITE, 0.7)
	var nm := Label.new()
	nm.text = str(spec["title"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(4, 76)
	nm.size = Vector2(168, 16)
	nm.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(nm, 12, Palette.TEXT)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	var gain := Label.new()
	gain.text = str(GAIN.get(m, ""))
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gain.position = Vector2(4, 94)
	gain.size = Vector2(168, 14)
	gain.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(gain, 10, Palette.READY)
	gain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(gain)
	var st := HBoxContainer.new()
	st.alignment = BoxContainer.ALIGNMENT_CENTER
	st.position = Vector2(4, 116)
	st.size = Vector2(168, 22)
	st.add_theme_constant_override("separation", 3)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not owned:
		st.add_child(IconBook.rect("cur_gem", 18))
	var sl := Label.new()
	sl.text = ("%d" % int(spec["gems"])) if not owned else ("ON  ·  REMOVE" if fitted else "FIT")
	sl.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(sl, 12, Palette.READY if fitted else (UiKit.GOLD if not owned else ACCENT))
	st.add_child(sl)
	b.add_child(st)
	b.focus_entered.connect(func() -> void: _focus(m))
	b.mouse_entered.connect(func() -> void: _focus(m))
	b.pressed.connect(func() -> void: _press(m, b))
	return b


func _focus(m: String) -> void:
	if _busy:
		return
	var spec: Dictionary = Arsenal.MODS[m]
	_dress.ghost = "" if Arsenal.has_mod(weapon, m) else m
	_dress.queue_redraw()
	_show_stats(m)
	var state := ""
	if not Arsenal.mod_owned(m):
		state = "[color=#ffd75e]%d GEMS to buy (fits every melee weapon).[/color]" % int(spec["gems"])
	elif Arsenal.has_mod(weapon, m):
		state = "[color=#7dffa0]On this weapon. Press to take it off.[/color]"
	elif Arsenal.mods_on(weapon).size() >= Arsenal.slots(weapon):
		state = "[color=#ff8a7a]Slots full: take a mod off first.[/color]"
	else:
		state = "[color=#9fe6ff]Owned. Press to fit it.[/color]"
	_info.text = "[color=#ffd75e]%s[/color]  %s\n%s" % [str(spec["title"]), UiKit.stat_bbcode(str(spec["line"])), state]


func _press(m: String, b: Button) -> void:
	if _busy:
		return
	_focus_key = "mod_" + m
	var spec: Dictionary = Arsenal.MODS[m]
	if not Arsenal.mod_owned(m):
		if not Arsenal.buy_mod(m):
			Juice.rewards.deny(b)
			return
		_spend_fx(int(spec["gems"]), b)
		_refresh_wallet()
		_dress.ghost = ""
		# The mod's logo stands big in the middle, then flies to the bench.
		Juice.upgrade_fx(_bench, ACCENT, str(spec["title"]), true, "mod_" + m)
		if Arsenal.mods_on(weapon).size() < Arsenal.slots(weapon) and Arsenal.toggle_mod(weapon, m):
			_busy = true
			get_tree().create_timer(1.3).timeout.connect(func() -> void:
				if is_inside_tree():
					_fit_anim(m))
		else:
			_repaint_later(0.6)
		return
	var was_on := Arsenal.has_mod(weapon, m)
	if not Arsenal.toggle_mod(weapon, m):
		Juice.rewards.deny(b)
		Juice.popup_number(RewardFly.vp_of(b), "NO FREE SLOT", Palette.BRICK)
		return
	if was_on:
		Mixer.play_sfx("res://assets/audio/whoosh_light.wav", 0.8, -6.0)
		_dress.ghost = ""
		_dress.play_out(m)
		_show_stats("")
		_repaint_later(0.5)
	else:
		_busy = true
		_fly_icon(m, b)


## The tile's icon flies onto the weapon, then the mod goes on.
func _fly_icon(m: String, from: Control) -> void:
	var s := Sprite2D.new()
	s.texture = IconBook.tex("mod_" + m)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(2, 2)
	var a := RewardFly.vp_of(from)
	var z := RewardFly.vp_of(_bench)
	s.position = a
	Juice.rewards.add_child(s)
	Mixer.play_sfx("res://assets/audio/whoosh_light.wav", 1.2, -6.0)
	var tw := s.create_tween()
	tw.tween_method(func(t: float) -> void:
		var mid := (a + z) * 0.5 + Vector2(0, -90)
		s.position = a.lerp(mid, t).lerp(mid.lerp(z, t), t)
		s.scale = Vector2.ONE * lerpf(2.0, 3.5, sin(t * PI)) * (1.0 - t * 0.5)
	, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		s.queue_free()
		if is_inside_tree():
			_fit_anim(m))


func _fit_anim(m: String) -> void:
	_dress.ghost = ""
	_dress.play_in(m, 1.0 if m == "nails" else 0.8)
	get_tree().create_timer(1.05).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		Juice.play("res://assets/audio/claim.wav")
		Juice.upgrade_fx(_bench, Palette.READY, str(GAIN.get(m, "FITTED")), false)
		_busy = false
		_repaint_later(0.5))


func _on_tick(m: String, i: int) -> void:
	Mixer.play_sfx(str(SOUND.get(m, "res://assets/audio/ui_click.wav")), 0.9 + 0.07 * float(i), -5.0)
	# Every piece knocks the weapon on the bench.
	var home: Vector2 = _holder.get_meta("home", _holder.position)
	var tw := _holder.create_tween()
	tw.tween_property(_holder, "position", home + Vector2(0, 5 if m == "nails" else 3), 0.03)
	tw.tween_property(_holder, "position", home, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if m == "nails" or m == "live_wire" or m == "serrated" or m == "weighted":
		var n := maxi(_dress._steps(m) - 1, 1)
		var f := 0.5 + 0.46 * float(i) / float(n)
		var e := _dress._edge(_dress._along(f))
		var p := CPUParticles2D.new()
		p.position = home + Vector2(_dress._along(f), e.x) * _holder.scale
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = 10
		p.lifetime = 0.25
		p.direction = Vector2(0, -1)
		p.spread = 70.0
		p.gravity = Vector2(0, 500)
		p.initial_velocity_min = 80.0
		p.initial_velocity_max = 200.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 3.0
		p.color = Color(0.6, 0.85, 1.0) if m == "live_wire" else Color(1.0, 0.86, 0.45)
		_bench.add_child(p)
		p.emitting = true
		get_tree().create_timer(0.5).timeout.connect(p.queue_free)


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


## The weapon's numbers with the mods on now, or with `m` toggled.
func _vals(m: String) -> Dictionary:
	var d: Dictionary = FamilyProfile.data.get("weapon_mods", {})
	var had := d.has(weapon)
	var keep: Array = (d.get(weapon, []) as Array).duplicate()
	if m != "":
		var on := keep.duplicate()
		if on.has(m):
			on.erase(m)
		else:
			on.append(m)
		d[weapon] = on
		FamilyProfile.data["weapon_mods"] = d
	var out := {
		"dmg": Arsenal.power_mul(weapon), "uses": float(Arsenal.uses(weapon)),
		"bleed": 3.0 if Arsenal.has_mod(weapon, "nails") else 0.0,
		"crit": 15.0 if Arsenal.has_mod(weapon, "serrated") else 0.0,
		"stun": 20.0 if Arsenal.has_mod(weapon, "live_wire") else 0.0,
	}
	if m != "":
		if had:
			d[weapon] = keep
		else:
			d.erase(weapon)
	return out


func _show_stats(m: String) -> void:
	var now := _vals("")
	var then := _vals(m) if m != "" else now
	for k in _rows:
		(_rows[k] as StatRow).set_vals(float(now[k]), float(then[k]))


## A segmented bar with "now › then": grey now, the change green or red.
class StatRow extends Control:
	var key := "dmg"
	var now := 0.0
	var then := 0.0
	const TOP := {"dmg": 2.5, "uses": 60.0, "bleed": 3.0, "crit": 25.0, "stun": 25.0}

	func set_vals(a: float, b: float) -> void:
		now = a
		then = b
		queue_redraw()

	func _txt(v: float) -> String:
		match key:
			"dmg":
				return "x%.2f" % v
			"uses":
				return "%d HITS" % int(v)
			"bleed":
				return ("%d TICKS" % int(v)) if v > 0.0 else "—"
		return ("%d%%" % int(v)) if v > 0.0 else "—"

	func _draw() -> void:
		var segs := 20
		var w := (size.x - 170.0) / float(segs)
		var top := float(TOP.get(key, 1.0))
		var fa := clampf(now / top, 0.0, 1.0)
		var fb := clampf(then / top, 0.0, 1.0)
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
		var f := UiKit.pixel_font()
		var x := size.x - 160.0
		var a := _txt(now)
		draw_string(f, Vector2(x, size.y - 4.0), a, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.85, 0.88))
		if absf(then - now) > 0.001:
			x += f.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 4.0
			draw_string(f, Vector2(x, size.y - 4.0), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.54, 0.55, 0.6))
			x += 10.0
			draw_string(f, Vector2(x, size.y - 4.0), _txt(then), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 1.0, 0.5) if then > now else Color(1.0, 0.35, 0.3))
