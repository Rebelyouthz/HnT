class_name SurvExtras
extends Node

## Five more for the coping hour:
##   SHRINES       (Jotunnslayer's gods) a shrine appears now and then; stand
##                 in it for 3 s and pick one of three BLESSINGS for the rest
##                 of the hour (thunder from the sky, war cry, quick hands,
##                 wide reach, second wind, fleet feet)
##   RAMPAGE       kills fill a meter; full = 8 s RAMPAGE: +50% damage, faster,
##                 the street goes red
##   PACTS         chosen before the hour (STARTER sheet): harder hour, more
##                 S-COINS at the end (read by SurviveRun)
##   CURSED CHESTS a purple chest: the best item in it, but opening it calls
##                 an elite pack
##   FORECAST      the HUD whispers which evolution is one step away

const BLESSINGS := {
	"thunder": {"title": "THUNDERHEAD", "line": "A bolt hits a thug every 2 s.", "icon": "bolt"},
	"warcry": {"title": "WAR CRY", "line": "+30% damage.", "icon": "t_dmg"},
	"quick": {"title": "QUICK HANDS", "line": "[color=#6fe08a]-20%[/color] cooldowns.", "icon": "t_cd"},
	"reach": {"title": "LONG REACH", "line": "+30% area.", "icon": "t_area"},
	"mend": {"title": "SECOND WIND", "line": "Heal 1 HP every 3 s.", "icon": "t_regen"},
	"fleet": {"title": "FLEET FEET", "line": "+20% move speed, +40% magnet.", "icon": "t_speed"},
}
const PACTS := {
	"overtime": {"title": "OVERTIME PACT", "line": "Thugs +40% health. +35% S-COINS.", "hp": 0.4, "coins": 0.35},
	"rush": {"title": "RUSH HOUR PACT", "line": "More thugs at once. +30% S-COINS.", "cap": 0.5, "coins": 0.3},
	"glass": {"title": "GLASS JAW PACT", "line": "You take +50% damage. +50% S-COINS.", "dmg": 0.5, "coins": 0.5},
}

var blessings: Array = []
var rampage_t := 0.0
var _rage := 0.0
var _kills0 := 0
var _shrine_t := 55.0
var _shrine: Node2D
var _chan := 0.0
var _thunder_t := 0.0
var _mend_t := 0.0
var _cursed_t := 80.0
var _tint: ColorRect
var _rage_bar: ColorRect
var _forecast: Label
var _fc_t := 0.0
var _t := 0.0


static func get_extras(tree: SceneTree) -> SurvExtras:
	return tree.get_first_node_in_group("surv_extras") as SurvExtras


static func pacts() -> Array:
	if App.weekly:
		return WeeklyBook.pacts()
	var p: Variant = FamilyProfile.data.get("surv_pacts", [])
	return p if p is Array else []


static func pact_sum(key: String) -> float:
	var s := 0.0
	for id in pacts():
		s += float((PACTS.get(str(id), {}) as Dictionary).get(key, 0.0))
	return s


static func toggle_pact(id: String) -> void:
	var p := pacts()
	if p.has(id):
		p.erase(id)
	else:
		p.append(id)
	FamilyProfile.data["surv_pacts"] = p
	FamilyProfile.save()


func has(b: String) -> bool:
	return blessings.has(b)


func dmg_mul() -> float:
	return (1.3 if has("warcry") else 1.0) * (1.5 if rampage_t > 0.0 else 1.0)


func cd_mul() -> float:
	return (0.8 if has("quick") else 1.0) * (0.85 if rampage_t > 0.0 else 1.0)


func area_mul() -> float:
	return 1.3 if has("reach") else 1.0


func speed_mul() -> float:
	return (1.2 if has("fleet") else 1.0) * (1.15 if rampage_t > 0.0 else 1.0)


func _ready() -> void:
	add_to_group("surv_extras")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if OS.get_environment("SURV_SHRINE") != "":
		_shrine_t = 1.0
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.color = Color(1.0, 0.1, 0.05, 0.0)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_tint)
	var hl := CanvasLayer.new()
	hl.layer = 61
	add_child(hl)
	var root := PixelStage.attach_canvas(hl)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.position = Vector2(14, 108) if Fighter.FIELD else Vector2(14, 214)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(row)
	var l := Label.new()
	l.text = "RAMPAGE"
	l.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(l, 10, Color(1.0, 0.4, 0.3))
	row.add_child(l)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0.02, 0.8)
	bg.custom_minimum_size = Vector2(140, 8)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bg)
	_rage_bar = ColorRect.new()
	_rage_bar.color = Color(1.0, 0.3, 0.2)
	_rage_bar.size = Vector2(0, 8)
	bg.add_child(_rage_bar)
	_forecast = Label.new()
	_forecast.position = Vector2(14, 124) if Fighter.FIELD else Vector2(14, 232)
	_forecast.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_forecast, 10, Color(1.0, 0.7, 0.3))
	root.add_child(_forecast)


func _run() -> SurviveRun:
	return SurviveRun.get_run(get_tree())


func _lead() -> Fighter:
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			return n
	return null


func _process(delta: float) -> void:
	var run := _run()
	var f := _lead()
	if run == null or f == null:
		return
	_t += delta
	_rampage(run, f, delta)
	_shrines(f, delta)
	_blessing_ticks(f, delta)
	_cursed(f, delta)
	_fc_t -= delta
	if _fc_t <= 0.0:
		_fc_t = 1.0
		_forecast_tick(run)


func _rampage(run: SurviveRun, f: Fighter, delta: float) -> void:
	if rampage_t > 0.0:
		rampage_t -= delta
		_tint.color.a = 0.12 + 0.05 * sin(_t * 10.0)
		_rage_bar.size.x = 140.0 * rampage_t / 8.0
		if rampage_t <= 0.0:
			_tint.color.a = 0.0
			_kills0 = run.kills
		return
	_rage = clampf(float(run.kills - _kills0) / (60.0 + _t / 4.0), 0.0, 1.0)
	_rage_bar.size.x = 140.0 * _rage
	if _rage >= 1.0:
		rampage_t = 8.0
		Juice.shout("RAMPAGE")
		Juice.pulse_shake(6.0)
		ArtFx.spawn(f.get_parent(), f.global_position, "ring", Color(1.0, 0.3, 0.2), 160.0, 0.5)
		RewardFly.snd("up_boom", 1.2, -2.0)


func _shrines(f: Fighter, delta: float) -> void:
	_shrine_t -= delta
	if _shrine == null and _shrine_t <= 0.0 and blessings.size() < 4:
		_shrine = Shrine.new()
		var mw := float(get_parent().get("map_w")) if get_parent().get("map_w") != null else 3000.0
		_shrine.global_position = Vector2(clampf(f.global_position.x + randf_range(-220, 220), 80.0, mw - 80.0), clampf(f.global_position.y + randf_range(-120, 120) if Fighter.FIELD else f.global_position.y + randf_range(-30, 30), Fighter.STREET_MIN + 10.0, maxf(Fighter.STREET_MAX, 590.0)))
		if OS.get_environment("SURV_SHRINE") != "":
			_shrine.global_position = f.global_position
		get_parent().add_child(_shrine)
		Juice.toast("quest", "A SHRINE APPEARED", "Stand in it to be blessed.", "node_crown")
		_chan = 0.0
	if _shrine == null:
		return
	if f.global_position.distance_to(_shrine.global_position) < 34.0:
		_chan += delta
		(_shrine as Shrine).fill = _chan / 3.0
		if _chan >= 3.0:
			_bless()
	else:
		_chan = maxf(0.0, _chan - delta)
		(_shrine as Shrine).fill = _chan / 3.0


func _bless() -> void:
	_shrine.queue_free()
	_shrine = null
	_shrine_t = 95.0
	var pool: Array = []
	for b in BLESSINGS:
		if not blessings.has(b):
			pool.append(b)
	pool.shuffle()
	var offer := pool.slice(0, 3)
	var picker := BlessPick.new()
	picker.offer = offer
	picker.extras = self
	get_tree().current_scene.add_child(picker)


func take_blessing(b: String) -> void:
	blessings.append(b)
	var spec: Dictionary = BLESSINGS[b]
	Juice.rewards.reveal(str(spec["icon"]), "BLESSED  ·  " + str(spec["title"]), Color(1.0, 0.85, 0.4), str(spec["line"]).replace("[color=#6fe08a]", "").replace("[/color]", ""))


func _blessing_ticks(f: Fighter, delta: float) -> void:
	if has("thunder"):
		_thunder_t -= delta
		if _thunder_t <= 0.0:
			_thunder_t = 2.0
			var best: Node2D = null
			var bd := 360.0
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node2D and int(e.get("hp")) > 0:
					var d := (e as Node2D).global_position.distance_to(f.global_position)
					if d < bd:
						bd = d
						best = e
			if best:
				SurvProj.bolt(get_parent(), best.global_position + Vector2(0, -260), best.global_position + Vector2(0, -26))
				if _zap == null or not is_instance_valid(_zap):
					_zap = Zapper.new()
					get_parent().add_child(_zap)
				_zap.global_position = best.global_position + Vector2(0, -200)
				SurvProj.strike(best, "late_fee", _zap)
				Mixer.play_sfx("res://assets/audio/zap.wav" if ResourceLoader.exists("res://assets/audio/zap.wav") else "res://assets/audio/hit_heavy.wav", 0.7, -8.0)
	if has("mend"):
		_mend_t -= delta
		if _mend_t <= 0.0:
			_mend_t = 3.0
			f.hp = mini(f.max_hp, f.hp + 1)


var _zap: Node2D


## The thunder's source for SurvProj.strike (it reads skill_dmg off it).
class Zapper extends Node2D:
	var skill_dmg := 10


func _cursed(f: Fighter, delta: float) -> void:
	_cursed_t -= delta
	if _cursed_t > 0.0:
		return
	_cursed_t = 120.0
	var c := CursedChest.new()
	c.extras = self
	var mw := float(get_parent().get("map_w")) if get_parent().get("map_w") != null else 3000.0
	c.global_position = Vector2(clampf(f.global_position.x + randf_range(-200, 200), 80.0, mw - 80.0), f.global_position.y)
	get_parent().add_child(c)
	Juice.toast("challenge", "CURSED CHEST", "The best item inside. Something comes with it.", "cur_chest")


func _forecast_tick(run: SurviveRun) -> void:
	_forecast.text = ""
	for e: Dictionary in run.book.get("evolutions", []):
		var ab := str(e.get("ability", ""))
		var lv := int(run.abilities.get(ab, 0))
		if lv <= 0 or run.evolved.has(ab):
			continue
		var has_item := run.has_item(str(e.get("item", "")))
		if lv >= 7 and not has_item:
			_forecast.text = ("EVOLUTION  ·  %s NEEDS %s" % [str(run.row("abilities", ab).get("name", ab)), str(run.row("items", str(e.get("item", ""))).get("name", e.get("item", "")))]).to_upper()
			return
		if has_item and lv >= 5:
			_forecast.text = "EVOLUTION  ·  %s at LV 7 (%d/7)" % [str(run.row("abilities", ab).get("name", ab)), lv]
			return


## A glowing shrine; fills as you stand in it.
class Shrine extends Node2D:
	var fill := 0.0
	var _t := 0.0

	func _ready() -> void:
		add_to_group("map_pins")
		set_meta("pin", "shrine")
		var tex: Texture2D = load("res://assets/sprites/survive/shrine.png") if ResourceLoader.exists("res://assets/sprites/survive/shrine.png") else null
		if tex:
			var art := Sprite2D.new()
			art.texture = tex
			art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var k := 64.0 / float(tex.get_height())
			art.scale = Vector2(k, k)
			art.offset = Vector2(0, -float(tex.get_height()) * 0.5)
			add_child(art)
			set_meta("art", true)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Color(1.0, 0.85, 0.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 34.0, Color(c.r, c.g, c.b, 0.12 + 0.05 * sin(_t * 4.0)))
		draw_arc(Vector2.ZERO, 34.0, 0, TAU, 40, Color(c.r, c.g, c.b, 0.8), 2.0)
		draw_arc(Vector2.ZERO, 34.0, -PI / 2.0, -PI / 2.0 + TAU * fill, 40, Color(1, 1, 1, 0.95), 4.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not has_meta("art"):
			draw_rect(Rect2(-6, -60, 12, 56), Color(0.5, 0.45, 0.4))
			draw_rect(Rect2(-9, -64, 18, 6), Color(0.6, 0.55, 0.5))
		draw_circle(Vector2(0, -74 + sin(_t * 2.0) * 3.0), 6.0, c)
		for i in 6:
			var a := _t * 1.2 + float(i) * TAU / 6.0
			draw_circle(Vector2(cos(a) * 20.0, -40.0 + sin(a * 2.0) * 10.0), 1.5, Color(c.r, c.g, c.b, 0.7))


## Purple chest: the best item, then an elite pack.
class CursedChest extends Node2D:
	var extras: SurvExtras
	var _t := 0.0

	func _ready() -> void:
		add_to_group("map_pins")
		set_meta("pin", "cursed")
		var s := Sprite2D.new()
		s.texture = IconBook.tex("cur_chest")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -16)
		s.modulate = Color(0.75, 0.45, 1.0)
		add_child(s)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t < 0.5:
			return
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 26.0:
				var run := SurviveRun.get_run(get_tree())
				if run:
					run.luck_boost = 3.0
					run.open_item_chest()
					run.luck_boost = 0.0
				var horde := get_tree().get_first_node_in_group("horde")
				if horde and horde.has_method("_wave"):
					for i in 3:
						horde.call("_wave", true, true)
				Juice.shout("CURSED")
				Juice.pulse_shake(5.0)
				RewardFly.snd("deny", 0.7, 0.0)
				queue_free()
				return

	func _draw() -> void:
		for i in 6:
			var a := _t * 2.0 + float(i) * TAU / 6.0
			draw_circle(Vector2(cos(a) * 18.0, -18.0 + sin(a) * 8.0), 2.0, Color(0.7, 0.4, 1.0, 0.6))


## Pick one of three blessings (pauses the hour).
class BlessPick extends CanvasLayer:
	var offer: Array = []
	var extras: SurvExtras

	func _ready() -> void:
		layer = 90
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		var root := PixelStage.attach_canvas(self)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0.02, 0.7)
		dim.size = Vector2(1280, 720)
		root.add_child(dim)
		var t := UiKit.title("CHOOSE A BLESSING", 30, Color(1.0, 0.85, 0.4))
		t.position = Vector2(0, 150)
		t.size = Vector2(1280, 40)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(t)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		row.position = Vector2(1280.0 * 0.5 - float(offer.size()) * 162.0, 240)
		root.add_child(row)
		var first: Button = null
		for b in offer:
			var spec: Dictionary = BLESSINGS[str(b)]
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(300, 260)
			btn.add_theme_stylebox_override("normal", UiKit.panel(Color(0.08, 0.07, 0.04), Color(1.0, 0.85, 0.4)))
			var hi := UiKit.panel(Color(0.14, 0.12, 0.06), Color.WHITE)
			hi.shadow_color = Color(1.0, 0.85, 0.4, 0.7)
			hi.shadow_size = 14
			for s in ["hover", "focus", "pressed"]:
				btn.add_theme_stylebox_override(s, hi)
			var ic := IconBook.rect(str(spec["icon"]), IconBook.SIZE_L)
			ic.position = Vector2(86, 16)
			btn.add_child(ic)
			var nl := Label.new()
			nl.text = str(spec["title"])
			nl.position = Vector2(0, 156)
			nl.size = Vector2(300, 24)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.add_theme_font_override("font", UiKit.title_font())
			UiKit.apply_label(nl, 18, Color(1.0, 0.85, 0.4))
			btn.add_child(nl)
			var rl := UiKit.rich(str(spec["line"]), 270, 13, Palette.TEXT)
			rl.position = Vector2(15, 196)
			btn.add_child(rl)
			var id := str(b)
			btn.pressed.connect(func() -> void:
				get_tree().paused = false
				extras.take_blessing(id)
				queue_free())
			row.add_child(btn)
			if first == null:
				first = btn
		RewardFly.snd("reward_pop")
		if first:
			first.call_deferred("grab_focus")
