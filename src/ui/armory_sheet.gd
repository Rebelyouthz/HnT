extends Control

## ARMORY: every weapon on the street - its art, what it does, how many
## you have put down with it and how far to MASTERY. Weapons never held
## show as a dark silhouette with where to look.

signal closed

const MELEE_ORDER := ["knife", "pipe", "board", "chain", "crowbar", "baseball_bat", "machete", "sledgehammer", "clipboard", "stapler", "invoice_star"]
const GUN_ORDER := ["pistol", "revolver", "nailgun", "smg", "shotgun", "flare_gun", "ray"]
const WHERE := {
	"baseball_bat": "Dock Street, near the start.", "machete": "Dock Street and the Intake Lot.",
	"sledgehammer": "The Intake Lot gate, and City Hall.", "revolver": "The Intake Lot, and the Waiting Room.",
	"flare_gun": "Dock Street mid-way, and the Invoice Pier.", "invoice_star": "A secret.",
}

var _grid: GridContainer
var _focus_key := ""
var _pop: Control


func _ready() -> void:
	_paint()


func _paint() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Palette.BRICK, 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -600
	card.offset_right = 600
	card.offset_top = -340
	card.offset_bottom = 340
	add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	card.add_child(outer)
	var head := HBoxContainer.new()
	var t := UiKit.title("ARMORY", 32, Palette.BRICK)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := UiKit.button("CLOSE", Vector2(120, 40))
	close.pressed.connect(func() -> void:
		closed.emit()
	)
	head.add_child(close)
	outer.add_child(head)
	var total := 0
	var have := 0
	var mastered := 0
	for id in MELEE_ORDER + GUN_ORDER:
		if WeaponBook.spec(id).is_empty():
			continue
		total += 1
		if Arsenal.found(id):
			have += 1
		if Arsenal.mastered(id):
			mastered += 1
	var sub := UiKit.rich("FOUND [color=#ffd75e]%d/%d[/color]   ·   MASTERED [color=#ffd75e]%d[/color]   ·   %d kills with any weapon %s" % [have, total, mastered, Arsenal.MASTERY_KILLS, "= +15% damage with it, for good"], 1100, 14, Palette.MUTED)
	outer.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	for pair in [["MELEE", MELEE_ORDER], ["GUNS", GUN_ORDER]]:
		col.add_child(UiKit.title(str(pair[0]), 18, Palette.EDGE))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		for id: String in pair[1]:
			if not WeaponBook.spec(id).is_empty():
				grid.add_child(_tile(id))
		col.add_child(grid)
	UiKit.pop_in(card)
	FamilyProfile.mark_seen("armory")
	var want := _focus_key
	get_tree().process_frame.connect(func() -> void:
		if want != "":
			for b in _buttons(self):
				if str(b.get_meta("key", "")) == want and not b.disabled:
					b.grab_focus()
					return
		if is_instance_valid(close):
			close.grab_focus()
	, CONNECT_ONE_SHOT)


func _buttons(n: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _art(id: String) -> Texture2D:
	for dir in ["held", "guns"]:
		var p := "res://assets/sprites/%s/%s.png" % [dir, id]
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _tile(id: String) -> Control:
	var spec := WeaponBook.spec(id)
	var have := Arsenal.found(id)
	var rarity := Rarity.normalize(str(spec.get("rarity", "common")))
	var col := Rarity.color(rarity)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(370, 176)
	Bevel.dress(p, false, 0.7)
	p.add_theme_stylebox_override("panel", UiKit.panel(Color(0.06, 0.07, 0.12), UiKit.GOLD if Arsenal.mastered(id) else (col if have else Palette.MUTED)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var art := TextureRect.new()
	art.texture = _art(id)
	art.custom_minimum_size = Vector2(120, 52)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not have:
		art.modulate = Color(0.05, 0.05, 0.08)
	top.add_child(art)
	var names := VBoxContainer.new()
	var nm := Label.new()
	nm.text = str(spec.get("title", id)).to_upper() if have else "???"
	nm.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(nm, 17, col if have else Palette.MUTED)
	names.add_child(nm)
	var tag := Label.new()
	var gun := spec.has("gun")
	tag.text = "%s  ·  %s" % [Rarity.label(rarity), ("GUN  ·  " + str(spec.get("caliber", "")).to_upper()) if gun else "MELEE"]
	UiKit.apply_label(tag, 10, Palette.MUTED)
	names.add_child(tag)
	top.add_child(names)
	v.add_child(top)
	var line := ""
	if have:
		if gun:
			line = "DMG %d%s  ·  MAG %d  ·  %.1f/s" % [int(spec.get("dmg", 0)), (" x%d" % int(spec.get("pellets", 1))) if int(spec.get("pellets", 1)) > 1 else "", int(spec.get("mag", 0)), 1.0 / maxf(0.05, float(spec.get("rate", 0.3)))]
		else:
			line = "%s  ·  LASTS %d HITS" % [str(spec.get("hit", "heavy")).to_upper() + " HITS", Arsenal.uses(id)]
		if str(spec.get("blurb", "")) != "":
			line += "\n" + str(spec["blurb"])
	else:
		line = "NOT FOUND  ·  " + str(WHERE.get(id, "Somewhere on the street."))
	var info := UiKit.rich(line, 350, 12, Palette.TEXT)
	info.text = UiKit.stat_bbcode(line)
	v.add_child(info)
	var k := Arsenal.kills(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var bar := UiKit.glow_bar(clampf(float(k) / float(Arsenal.MASTERY_KILLS), 0.0, 1.0), UiKit.GOLD if Arsenal.mastered(id) else col, Vector2(220, 8))
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var kl := Label.new()
	kl.text = ("★ MASTERED  %d" % k) if Arsenal.mastered(id) else "%d/%d KILLS" % [k, Arsenal.MASTERY_KILLS]
	UiKit.apply_label(kl, 12, UiKit.GOLD if Arsenal.mastered(id) else Palette.TEXT)
	row.add_child(kl)
	v.add_child(row)
	if have:
		# Weapon level (gold) and mods (fitted in slots, bought with gems).
		var br := HBoxContainer.new()
		br.add_theme_constant_override("separation", 6)
		var lv := Arsenal.level(id)
		var up := UiKit.button(("LV %d  ▲ %dG" % [lv, Arsenal.level_cost(id)]) if lv < Arsenal.MAX_LV else "LV MAX", Vector2(120, 30))
		up.set_meta("key", "lv_" + id)
		up.disabled = lv >= Arsenal.MAX_LV or int(FamilyProfile.data.get("gold", 0)) < Arsenal.level_cost(id)
		up.pressed.connect(func() -> void:
			if Arsenal.try_level(id):
				Juice.play("res://assets/audio/claim.wav")
				Juice.shout("%s LV %d" % [str(spec.get("title", id)).to_upper(), Arsenal.level(id)])
				_focus_key = "lv_" + id
				_paint()
		)
		br.add_child(up)
		var mod_names: Array[String] = []
		var mb: Button
		if Arsenal.is_gun(id):
			for slot in Attach.SLOTS:
				var a := Attach.on(id, slot)
				if a != "" and Attach.slot_open(id, slot):
					mod_names.append(str(Attach.LIST[a]["title"]))
			mb = UiKit.button("GUNSMITH %d/5" % mod_names.size(), Vector2(130, 30))
			mb.pressed.connect(_gunsmith.bind(id))
		else:
			var on := Arsenal.mods_on(id)
			for m in on:
				if Arsenal.MODS.has(m):
					mod_names.append(str(Arsenal.MODS[m]["title"]))
			mb = UiKit.button("MODS %d/%d" % [on.size(), Arsenal.slots(id)], Vector2(110, 30))
			mb.pressed.connect(_mods_for.bind(id))
		mb.set_meta("key", "mods_" + id)
		mb.tooltip_text = ", ".join(mod_names) if not mod_names.is_empty() else "Nothing fitted."
		br.add_child(mb)
		# CARRY IN (needs META STARTER KIT): start every night with this one.
		if Meta.rank("starter_kit") > 0:
			var carrying := str(FamilyProfile.data.get("carry_weapon", "")) == id
			var cb := UiKit.button("CARRIED" if carrying else "CARRY", Vector2(110, 30))
			cb.set_meta("key", "carry_" + id)
			if carrying:
				cb.add_theme_color_override("font_color", Palette.READY)
			cb.pressed.connect(func() -> void:
				FamilyProfile.data["carry_weapon"] = "" if carrying else id
				FamilyProfile.save()
				Juice.play("res://assets/audio/claim.wav")
				_focus_key = "carry_" + id
				_paint()
			)
			br.add_child(cb)
		v.add_child(br)
		if not mod_names.is_empty():
			var ml := Label.new()
			ml.text = "  ".join(mod_names)
			UiKit.apply_label(ml, 11, Color(0.6, 0.9, 1.0))
			v.add_child(ml)
	return p


## GUNSMITH: five slots on one gun (muzzle, optic, barrel, magazine, ammo),
## each part bought once with gems and fitted to any gun; slots open with
## the gun's level.
func _gunsmith(id: String) -> void:
	if _pop and is_instance_valid(_pop):
		_pop.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_pop = dim
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Color(0.6, 0.9, 1.0), 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -520
	card.offset_right = 520
	card.offset_top = -320
	card.offset_bottom = 320
	dim.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)
	col.add_child(UiKit.title("GUNSMITH  ·  %s  ·  LV %d" % [str(WeaponBook.spec(id).get("title", id)).to_upper(), Arsenal.level(id)], 22, Color(0.6, 0.9, 1.0)))
	var sub := Label.new()
	sub.text = "One part per slot. Muzzle and ammo from LV 1, optic LV 2, magazine LV 3, barrel LV 4.  Gems %d.  Ammo is scarce out there: a gun comes with one spare magazine, then it is your fists." % int(FamilyProfile.data.get("gems", 0))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(1000, 0)
	UiKit.apply_label(sub, 12, Palette.MUTED)
	col.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	sc.add_child(body)
	var first: Button = null
	for slot: String in Attach.SLOTS:
		var open := Attach.slot_open(id, slot)
		var hl := Label.new()
		hl.text = "%s%s" % [Attach.SLOT_NAME[slot], "" if open else "   ·   OPENS AT LV %d" % int(Attach.SLOT_LV[slot])]
		hl.add_theme_font_override("font", UiKit.title_font())
		UiKit.apply_label(hl, 15, UiKit.GOLD if open else Palette.MUTED)
		body.add_child(hl)
		for a: String in Attach.LIST:
			var spec: Dictionary = Attach.LIST[a]
			if str(spec["slot"]) != slot:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var fitted := Attach.on(id, slot) == a
			var info := UiKit.rich("[color=%s]%s[/color]  %s" % ["#7dffa0" if fitted else "#ffd75e", str(spec["title"]), str(spec["line"])], 780, 13, Palette.TEXT if open else Palette.MUTED)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.text = info.text.replace("[center]", "").replace("[/center]", "")
			row.add_child(info)
			var txt := "BUY %d GEMS" % int(spec["gems"]) if not Attach.owned(a) else ("REMOVE" if fitted else "FIT")
			var b := UiKit.button(txt, Vector2(170, 32))
			b.disabled = (not open and Attach.owned(a)) or (not Attach.owned(a) and int(FamilyProfile.data.get("gems", 0)) < int(spec["gems"]))
			b.pressed.connect(func() -> void:
				if not Attach.owned(a):
					if Attach.buy(a):
						Juice.play("res://assets/audio/card.wav")
				elif Attach.fit(id, a):
					Juice.play("res://assets/audio/sfx/mag_in.ogg")
				_gunsmith(id)
			)
			row.add_child(b)
			if first == null and not b.disabled:
				first = b
			body.add_child(row)
	var done := UiKit.button("DONE", Vector2(160, 40))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void:
		_focus_key = "mods_" + id
		_paint()
	)
	col.add_child(done)
	if first:
		first.call_deferred("grab_focus")
	else:
		done.call_deferred("grab_focus")


## The mod bench for one melee weapon: every mod of its kind, fit / remove /
## buy with gems.
func _mods_for(id: String) -> void:
	if _pop and is_instance_valid(_pop):
		_pop.queue_free()
	var kind := "gun" if Arsenal.is_gun(id) else "melee"
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_pop = dim
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.frame(Color(0.6, 0.9, 1.0), 0.4))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -360
	card.offset_right = 360
	card.offset_top = -250
	card.offset_bottom = 250
	dim.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(UiKit.title("MOD BENCH  ·  %s" % str(WeaponBook.spec(id).get("title", id)).to_upper(), 22, Color(0.6, 0.9, 1.0)))
	var sub := Label.new()
	sub.text = "Slots %d (2 from LV 3).  Gems %d." % [Arsenal.slots(id), int(FamilyProfile.data.get("gems", 0))]
	UiKit.apply_label(sub, 13, Palette.MUTED)
	col.add_child(sub)
	var first: Button = null
	for m: String in Arsenal.MODS:
		var spec: Dictionary = Arsenal.MODS[m]
		if str(spec["for"]) != kind:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := UiKit.rich("[color=#ffd75e]%s[/color]  %s" % [str(spec["title"]), str(spec["line"])], 460, 13, Palette.TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var txt := ""
		if not Arsenal.mod_owned(m):
			txt = "BUY %d GEMS" % int(spec["gems"])
		elif Arsenal.has_mod(id, m):
			txt = "REMOVE"
		else:
			txt = "FIT"
		var b := UiKit.button(txt, Vector2(170, 34))
		b.pressed.connect(func() -> void:
			if not Arsenal.mod_owned(m):
				if Arsenal.buy_mod(m):
					Juice.play("res://assets/audio/card.wav")
			elif Arsenal.toggle_mod(id, m):
				Juice.play("res://assets/audio/claim.wav")
			else:
				Juice.popup_number(Vector2(640, 360), "NO FREE SLOT", Palette.BRICK)
			_mods_for(id)
		)
		row.add_child(b)
		if first == null:
			first = b
		col.add_child(row)
	var done := UiKit.button("DONE", Vector2(160, 40))
	done.pressed.connect(func() -> void:
		_focus_key = "mods_" + id
		_paint()
	)
	col.add_child(done)
	if first:
		first.call_deferred("grab_focus")
