class_name SurvActives
extends Node

## ACTIVE SKILLS for the survivor hours. Two slots, picked in the lobby's
## ACTIVE SKILLS menu (everything else in a run comes from level-up cards):
##   SKILL 1  LB  /  I or Q
##   SKILL 2  LT  /  U or E
## Each skill has a cooldown; levels (bought with S-COINS) cut the cooldown
## 8% and add 15% power per level. One node per hero during a run: it reads
## the buttons, runs the skill and draws the two buttons with their
## cooldown sweep at the bottom of the screen.
## Saved in FamilyProfile.data["surv_actives"] = {own: {id: lv}, slots: [a, b]}.

const MAX_LV := 5
const LIST := {
	"frag": {"name": "FRAG GRENADE", "icon": "a_frag", "cd": 7.0, "cost": 0,
		"blurb": "Lob a grenade where you aim (or at the nearest pack). Big blast, shrapnel ring."},
	"stomp": {"name": "GROUND STOMP", "icon": "a_stomp", "cd": 9.0, "cost": 0,
		"blurb": "Slam the floor: everything close is hurt, thrown back and dazed."},
	"molotov": {"name": "MOLOTOV", "icon": "a_molotov", "cd": 10.0, "cost": 160,
		"blurb": "A burning bottle: a pool of fire that keeps cooking whatever walks in."},
	"turret": {"name": "SENTRY TURRET", "icon": "a_turret", "cd": 16.0, "cost": 260,
		"blurb": "Drop a little turret that fires at the nearest thug for 8 seconds."},
	"charge": {"name": "SHOULDER CHARGE", "icon": "a_charge", "cd": 6.0, "cost": 200,
		"blurb": "Barge forward along the stick, untouchable, flattening a lane of thugs."},
	"adrenaline": {"name": "ADRENALINE", "icon": "a_adrenaline", "cd": 18.0, "cost": 300,
		"blurb": "Five seconds of everything faster: cooldowns halved, feet quicker."},
	"decoy": {"name": "CARDBOARD DAD", "icon": "a_decoy", "cd": 15.0, "cost": 240,
		"blurb": "A cardboard cut-out every thug has to fight first. It explodes when it falls."},
	"medkit": {"name": "FIRST AID", "icon": "a_medkit", "cd": 26.0, "cost": 220,
		"blurb": "Patch up: a quarter of your health back, and a moment untouchable."},
}
const ORDER := ["frag", "stomp", "molotov", "turret", "charge", "adrenaline", "decoy", "medkit"]

var f: Fighter
var _cd := [0.0, 0.0]
var _adren := 0.0
var _hud: Control
var _over: Control
var _icons: Array = []


# --- profile -------------------------------------------------------------------

static func _state() -> Dictionary:
	var s: Dictionary = FamilyProfile.data.get("surv_actives", {})
	if not s.has("own"):
		s["own"] = {"frag": 1, "stomp": 1}
	if not s.has("slots"):
		s["slots"] = ["frag", "stomp"]
	FamilyProfile.data["surv_actives"] = s
	return s


static func level(id: String) -> int:
	return int((_state()["own"] as Dictionary).get(id, 0))


static func owned(id: String) -> bool:
	return level(id) > 0


static func slots() -> Array:
	return (_state()["slots"] as Array).duplicate()


static func equip(slot: int, id: String) -> void:
	var s: Array = _state()["slots"]
	while s.size() < 2:
		s.append("")
	var other := 1 - slot
	if str(s[other]) == id:
		s[other] = s[slot]
	s[slot] = id
	FamilyProfile.save()


static func unlock_cost(id: String) -> int:
	return int((LIST[id] as Dictionary).get("cost", 200))


static func level_cost(id: String) -> int:
	return 90 + 70 * level(id)


static func unlock(id: String) -> bool:
	var cost := unlock_cost(id)
	if owned(id) or int(FamilyProfile.data.get("tokens", 0)) < cost:
		return false
	FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) - cost
	(_state()["own"] as Dictionary)[id] = 1
	FamilyProfile.save()
	return true


static func level_up(id: String) -> bool:
	var cost := level_cost(id)
	if not owned(id) or level(id) >= MAX_LV or int(FamilyProfile.data.get("tokens", 0)) < cost:
		return false
	FamilyProfile.data["tokens"] = int(FamilyProfile.data.get("tokens", 0)) - cost
	(_state()["own"] as Dictionary)[id] = level(id) + 1
	FamilyProfile.save()
	return true


static func cooldown(id: String) -> float:
	return float((LIST.get(id, {}) as Dictionary).get("cd", 8.0)) * pow(0.92, float(maxi(0, level(id) - 1)))


static func power(id: String) -> float:
	return 1.0 + 0.15 * float(maxi(0, level(id) - 1))


static func icon(id: String) -> Texture2D:
	return SurviveIcons.tex(str((LIST.get(id, {}) as Dictionary).get("icon", "")))


# --- run -----------------------------------------------------------------------

static func of(fighter: Fighter) -> SurvActives:
	var a := fighter.get_node_or_null("SurvActives") as SurvActives
	if a == null:
		a = SurvActives.new()
		a.name = "SurvActives"
		a.f = fighter
		fighter.add_child(a)
	return a


func _ready() -> void:
	if f and str(f.prefix) == "p1_":
		var layer := CanvasLayer.new()
		layer.layer = 40
		add_child(layer)
		_hud = Control.new()
		_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
		_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.draw.connect(_draw_hud)
		layer.add_child(_hud)
		# Icons as their own nodes, then the cooldown veil drawn over them.
		for i in 2:
			var ic := TextureRect.new()
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_SCALE
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.size = Vector2(32, 32)
			_hud.add_child(ic)
			_icons.append(ic)
		_over = Control.new()
		_over.set_anchors_preset(Control.PRESET_FULL_RECT)
		_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_over.draw.connect(_draw_over)
		_hud.add_child(_over)


func adrenaline() -> bool:
	return _adren > 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(f) or get_tree().paused:
		return
	var k := 2.0 if _adren > 0.0 else 1.0
	for i in 2:
		_cd[i] = maxf(0.0, float(_cd[i]) - delta * k)
	if _adren > 0.0:
		_adren -= delta
	if not f.downed:
		var sl := slots()
		for i in 2:
			var act := "block" if i == 0 else "throw"
			if i < sl.size() and str(sl[i]) != "" and Input.is_action_just_pressed(str(f.prefix) + act):
				if float(_cd[i]) <= 0.0:
					_cd[i] = cooldown(str(sl[i]))
					_use(str(sl[i]))
				else:
					Mixer.play_sfx("res://assets/audio/ui/deny.wav" if ResourceLoader.exists("res://assets/audio/ui/deny.wav") else "res://assets/audio/ui_click.wav", 1.2, -12.0)
	if _hud:
		_hud.queue_redraw()
		_over.queue_redraw()


func _host() -> Node:
	return f.get_parent()


func _aim_point(reach: float) -> Vector2:
	var at := f.global_position
	var rs := PadRouter.rstick(f.prefix)
	if rs.length() > 0.3:
		return at + rs.normalized() * reach
	if PadRouter.mouse_live(f.prefix):
		var m := f.get_global_mouse_position()
		return at + (m - at).limit_length(reach)
	var best: Node2D = null
	var bd := reach
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and int(e.get("hp")) > 0:
			var d := (e as Node2D).global_position.distance_to(at)
			if d < bd:
				bd = d
				best = e
	return best.global_position if best else at + Vector2(float(f.facing) * reach * 0.6, 0)


func _hurt_around(at: Vector2, r: float, hits: int, shove: float, daze: float) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Punk) or int(e.get("hp")) <= 0:
			continue
		var p := e as Punk
		var d := p.global_position - at
		if d.length() > r:
			continue
		for i in hits:
			p.take_hit("heavy", f)
		if shove > 0.0:
			p.global_position += d.normalized() * shove * (1.0 - d.length() / r * 0.5)
		if daze > 0.0:
			p.set("recover", maxf(float(p.get("recover")), daze))
		n += 1
	return n


func _use(id: String) -> void:
	var pw := power(id)
	var hits := 1 + int(pw >= 1.3) + int(pw >= 1.6)
	Juice.popup_number(f.global_position + Vector2(0, -110), str(LIST[id]["name"]), Color(0.45, 1.0, 0.6))
	match id:
		"frag":
			var to := _aim_point(240.0)
			SurvProj.lob(_host(), "magnet_mines", f.global_position + Vector2(0, -30), to, 0.0)
			get_tree().create_timer(0.55, false).timeout.connect(func() -> void:
				if not is_instance_valid(f):
					return
				var r := 78.0 * (0.9 + 0.1 * pw)
				SurvProj.ring(_host(), to, r, Color(1.0, 0.6, 0.2))
				SurvProj.flash(_host(), to + Vector2(0, -10), r * 0.6)
				_hurt_around(to, r, hits + 1, 34.0, 0.4)
				Juice.pulse_shake(7.0)
				Mixer.play_sfx("res://assets/audio/sfx/explosion.ogg" if ResourceLoader.exists("res://assets/audio/sfx/explosion.ogg") else "res://assets/audio/hit_heavy.wav", 1.0, -2.0))
		"stomp":
			var r := 110.0 * (0.9 + 0.1 * pw)
			SurvProj.ring(_host(), f.global_position, r, Color(1.0, 0.85, 0.4))
			SurvProj.ring(_host(), f.global_position, r * 0.6, Color(1.0, 0.95, 0.7))
			Juice.land_puff(f.global_position)
			_hurt_around(f.global_position, r, hits, 60.0, 0.9)
			f._squash_to(Vector2(1.2, 0.8))
			Juice.pulse_shake(9.0)
			Juice.hitstop(4)
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.55, -2.0)
		"molotov":
			var to := _aim_point(220.0)
			SurvProj.lob(_host(), "magnet_mines", f.global_position + Vector2(0, -30), to, 0.0)
			get_tree().create_timer(0.5, false).timeout.connect(func() -> void:
				if not is_instance_valid(f):
					return
				SurvProj.puddle(_host(), "gravy", to, 62.0 * (0.9 + 0.1 * pw), 4.0 + pw)
				SurvProj.flash(_host(), to + Vector2(0, -6), 40.0)
				_hurt_around(to, 62.0, hits, 0.0, 0.0)
				Mixer.play_sfx("res://assets/audio/sfx/glass.ogg" if ResourceLoader.exists("res://assets/audio/sfx/glass.ogg") else "res://assets/audio/cling.wav", 1.0, -4.0))
		"turret":
			var t := _Turret.new()
			t.owner_f = f
			t.life = 8.0 * (0.9 + 0.1 * pw)
			t.rate = 0.28 / pw
			t.global_position = f.global_position + Vector2(float(f.facing) * 24.0, 6)
			_host().add_child(t)
			Mixer.play_sfx("res://assets/audio/sfx/metal_bang.ogg", 1.3, -6.0)
		"charge":
			var st := Vector2(Input.get_axis(str(f.prefix) + "left", str(f.prefix) + "right"), Input.get_axis(str(f.prefix) + "up", str(f.prefix) + "down"))
			var dir := st.normalized() if st.length() > 0.3 else Vector2(float(f.facing), 0)
			f.invuln = maxi(f.invuln, 30)
			var from := f.global_position
			var tw := f.create_tween()
			tw.tween_method(func(k: float) -> void:
				if not is_instance_valid(f):
					return
				f.global_position = from + dir * 190.0 * k
				f.set("_field_v", dir * 300.0)
				for e in get_tree().get_nodes_in_group("enemies"):
					if e is Punk and int(e.get("hp")) > 0 and (e as Punk).global_position.distance_to(f.global_position) < 34.0 and not (e as Punk).has_meta("charged"):
						(e as Punk).set_meta("charged", true)
						for i in hits + 1:
							(e as Punk).take_hit("heavy", f)
						(e as Punk).global_position += dir.orthogonal() * (24.0 if randf() < 0.5 else -24.0) + dir * 30.0
			, 0.0, 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void:
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and (e as Node).has_meta("charged"):
						(e as Node).remove_meta("charged"))
			Juice.pulse_shake(5.0)
			KitSfx.hit(f.role, "dash")
		"adrenaline":
			_adren = 5.0 * (0.9 + 0.1 * pw)
			SurvProj.ring(_host(), f.global_position, 60.0, Color(1.0, 0.3, 0.3))
			Mixer.play_sfx("res://assets/audio/sfx/heartbeat.ogg" if ResourceLoader.exists("res://assets/audio/sfx/heartbeat.ogg") else "res://assets/audio/zap.wav", 1.0, -4.0)
		"decoy":
			var d := _Decoy.new()
			d.owner_f = f
			d.life = 6.0 * (0.9 + 0.1 * pw)
			d.boom = hits + 1
			d.global_position = f.global_position + Vector2(float(f.facing) * 40.0, 0)
			_host().add_child(d)
			Mixer.play_sfx("res://assets/audio/card.wav", 0.7, -4.0)
		"medkit":
			var heal := int(round(float(f.max_hp) * 0.25 * (0.9 + 0.1 * pw)))
			f.hp = mini(f.max_hp, f.hp + heal)
			f.invuln = maxi(f.invuln, 50)
			Juice.popup_number(f.global_position + Vector2(0, -90), "+%d" % heal, Color(0.45, 1.0, 0.5))
			SurvProj.ring(_host(), f.global_position, 46.0, Color(0.45, 1.0, 0.5))
			Mixer.play_sfx("res://assets/audio/ui/up_rise.wav" if ResourceLoader.exists("res://assets/audio/ui/up_rise.wav") else "res://assets/audio/cling.wav", 1.2, -4.0)


## The two skill buttons, bottom middle: frame, icon, cooldown sweep, key.
func _slot_rect(i: int) -> Rect2:
	var vp := _hud.get_viewport_rect().size
	var c := Vector2(vp.x * 0.5 + (float(i) - 0.5) * 44.0, vp.y - 30.0)
	return Rect2(c - Vector2(17, 17), Vector2(34, 34))


func _draw_hud() -> void:
	var sl := slots()
	for i in 2:
		var ic: TextureRect = _icons[i] if i < _icons.size() else null
		if i >= sl.size() or str(sl[i]) == "":
			if ic:
				ic.visible = false
			continue
		var id := str(sl[i])
		var r := _slot_rect(i)
		var ready := float(_cd[i]) <= 0.0
		_hud.draw_rect(r.grow(2), Color(0.02, 0.03, 0.06, 0.85))
		_hud.draw_rect(r.grow(2), Color(0.45, 1.0, 0.6) if ready else Color(0.35, 0.38, 0.45), false, 2.0)
		if ic:
			ic.visible = true
			ic.texture = icon(id)
			ic.position = r.position + Vector2(1, 1)
			ic.size = r.size - Vector2(2, 2)
			ic.modulate = Color(1, 1, 1, 1.0 if ready else 0.5)


func _draw_over() -> void:
	var vp := _hud.get_viewport_rect().size
	var sl := slots()
	var font := ThemeDB.fallback_font
	var keys := ["LB", "LT"] if PadRouter.last_p1_kind == "pad" else ["Q", "E"]
	for i in 2:
		if i >= sl.size() or str(sl[i]) == "":
			continue
		var id := str(sl[i])
		var r := _slot_rect(i)
		var c := r.get_center()
		if float(_cd[i]) > 0.0:
			var frac := clampf(float(_cd[i]) / maxf(0.1, cooldown(id)), 0.0, 1.0)
			_over.draw_rect(Rect2(r.position + Vector2(0, r.size.y * (1.0 - frac)), Vector2(r.size.x, r.size.y * frac)), Color(0, 0, 0, 0.55))
			var t := "%d" % ceili(float(_cd[i]))
			_over.draw_string_outline(font, c + Vector2(-5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
			_over.draw_string(font, c + Vector2(-5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		_over.draw_string_outline(font, r.position + Vector2(1, -3), keys[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color.BLACK)
		_over.draw_string(font, r.position + Vector2(1, -3), keys[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.9, 0.5))
	if _adren > 0.0:
		_over.draw_string_outline(font, Vector2(vp.x * 0.5 - 34, vp.y - 54), "ADRENALINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
		_over.draw_string(font, Vector2(vp.x * 0.5 - 34, vp.y - 54), "ADRENALINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.4, 0.4))


## A little sentry: swivels to the nearest thug and plinks it.
class _Turret extends Node2D:
	var owner_f: Fighter
	var life := 8.0
	var rate := 0.28
	var _t := 0.0
	var _ang := 0.0

	func _ready() -> void:
		z_index = 5
		y_sort_enabled = false

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0 or not is_instance_valid(owner_f):
			SurvProj.ring(get_parent(), global_position, 20.0, Color(0.7, 0.7, 0.75))
			queue_free()
			return
		_t -= delta
		var best: Node2D = null
		var bd := 300.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node2D and int(e.get("hp")) > 0:
				var d := (e as Node2D).global_position.distance_to(global_position)
				if d < bd:
					bd = d
					best = e
		if best:
			_ang = lerp_angle(_ang, (best.global_position + Vector2(0, -24) - (global_position + Vector2(0, -16))).angle(), 0.3)
			if _t <= 0.0:
				_t = rate
				SurvProj.shoot(get_parent(), "bullet", "nail_driver", global_position + Vector2(0, -16) + Vector2.from_angle(_ang) * 14.0, Vector2.from_angle(_ang) * 760.0, 1, owner_f)
				Mixer.play_sfx("res://assets/audio/sfx/pistol.ogg" if ResourceLoader.exists("res://assets/audio/sfx/pistol.ogg") else "res://assets/audio/ui_click.wav", randf_range(1.5, 1.7), -16.0)
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(0, -10), Vector2(-9, 2), Color(0.3, 0.32, 0.38), 2.0)
		draw_line(Vector2(0, -10), Vector2(9, 2), Color(0.3, 0.32, 0.38), 2.0)
		draw_rect(Rect2(-7, -22, 14, 12), Color(0.5, 0.53, 0.6))
		draw_set_transform(Vector2(0, -16), _ang, Vector2.ONE)
		draw_rect(Rect2(0, -2, 16, 4), Color(0.18, 0.2, 0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(-2, -16), 2.0, Color(1.0, 0.25, 0.2) if fmod(life, 0.5) < 0.25 else Color(0.5, 0.1, 0.1))
		var a := clampf(life / 8.0, 0.0, 1.0)
		draw_rect(Rect2(-8, -28, 16 * a, 2), Color(0.45, 1.0, 0.6))


## A cardboard cut-out of Dad: thugs nearby walk to it and punch it. When
## its time is up (or it is beaten flat) it goes off.
class _Decoy extends Node2D:
	var owner_f: Fighter
	var life := 6.0
	var boom := 2
	var _t := 0.0

	func _process(delta: float) -> void:
		life -= delta
		_t += delta
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Punk and int(e.get("hp")) > 0:
				var p := e as Punk
				var d := global_position - p.global_position
				if d.length() < 220.0 and d.length() > 26.0:
					p.global_position += d.normalized() * 60.0 * delta
		if life <= 0.0:
			SurvProj.ring(get_parent(), global_position, 90.0, Color(1.0, 0.6, 0.2))
			SurvProj.flash(get_parent(), global_position + Vector2(0, -20), 60.0)
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Punk and int(e.get("hp")) > 0 and (e as Punk).global_position.distance_to(global_position) < 90.0:
					for i in boom:
						(e as Punk).take_hit("heavy", owner_f)
			Juice.pulse_shake(6.0)
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.7, -3.0)
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var wob := sin(_t * 9.0) * 0.06
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, wob, Vector2.ONE)
		draw_rect(Rect2(-9, -46, 18, 34), Color(0.77, 0.63, 0.42))
		draw_circle(Vector2(0, -54), 8.0, Color(0.77, 0.63, 0.42))
		draw_rect(Rect2(-9, -46, 18, 34), Color(0.4, 0.3, 0.2), false, 1.0)
		draw_line(Vector2(-3, -54), Vector2(-3, -53), Color.BLACK, 2.0)
		draw_line(Vector2(3, -54), Vector2(3, -53), Color.BLACK, 2.0)
		draw_line(Vector2(0, -12), Vector2(0, 0), Color(0.4, 0.3, 0.2), 2.0)
		var a := clampf(life / 6.0, 0.0, 1.0)
		draw_rect(Rect2(-9, -68, 18 * a, 2), Color(1.0, 0.6, 0.2))
