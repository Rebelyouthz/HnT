class_name NightExtras
extends Node

## Five things on every street night (Dock Street and the Intake Lot):
##   BlessingMachine  a vending machine: pay gold for a 45 s blessing
##   RefundRunner     a thug with the family's tax refund runs; catch him
##   ComboRewards     25 / 50 / 100 hit combos drop coins, a flask, a shard
##   StreetEvents     every minute or so: BLACKOUT, CASH RAIN or RUSH HOUR
##   (wall bounces live in Punk._fling: bodies bounce off the screen edge)

const MACHINE_AT := {"dock_street": 1520.0, "intake_lot": 860.0, "tutorial_alley": 760.0}

static var blessing := ""
static var blessing_t := 0.0
static var event := ""
static var event_t := 0.0

var map_id := ""
var map_w := 3200.0
var _event_cd := 75.0
var _runner_cd := 50.0
var _runner_done := false
var _milestone := 0


static func place(host: Node, map: String, width: float) -> void:
	blessing = ""
	blessing_t = 0.0
	event = ""
	event_t = 0.0
	var n := NightExtras.new()
	n.map_id = map
	n.map_w = width
	n.name = "NightExtras"
	host.add_child(n)
	var m := BlessingMachine.new()
	m.position = Vector2(float(MACHINE_AT.get(map, width * 0.45)), 440.0)
	host.add_child(m)


# --- blessings, events: read by fighters and thugs ------------------------------

static func dmg_mul() -> float:
	return 1.25 if blessing == "protein" and blessing_t > 0.0 else 1.0


static func speed_mul() -> float:
	return 1.15 if blessing == "espresso" and blessing_t > 0.0 else 1.0


static func guard_mul() -> float:
	return 0.75 if blessing == "vitamin" and blessing_t > 0.0 else 1.0


static func coin_mul() -> int:
	return 2 if event == "blackout" and event_t > 0.0 else 1


static func rush() -> bool:
	return event == "rush_hour" and event_t > 0.0


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if blessing_t > 0.0:
		blessing_t -= delta
		if blessing_t <= 0.0:
			Juice.popup_number(_lead_pos() + Vector2(0, -110), "BLESSING WORN OFF", Palette.MUTED)
	_tick_combo()
	_tick_events(delta)
	_tick_runner(delta)


func _lead_pos() -> Vector2:
	var p := get_tree().get_first_node_in_group("players")
	return (p as Node2D).global_position if p is Node2D else Vector2.ZERO


func _host() -> Node:
	return get_parent()


func _tick_combo() -> void:
	var c := Juice.combo
	if c < 25:
		_milestone = 0
		return
	for step in [25, 50, 100]:
		if c >= step and _milestone < step:
			_milestone = step
			var at := _lead_pos() + Vector2(30, 0)
			Juice.shout("%d HITS!" % step)
			match step:
				25:
					for i in 4:
						LootDrop.spawn(_host(), at, "coin", 1, 1.3)
				50:
					LootDrop.spawn(_host(), at, "flask")
					for i in 4:
						LootDrop.spawn(_host(), at, "coin", 2, 1.3)
				100:
					var who := "son" if randf() < 0.5 else "father"
					LootDrop.spawn(_host(), at, "shard_" + who, 3, 0.8)
					Juice.unlock_logo("UNTOUCHABLE", "A hundred hits without a scratch.", "COMBO 100")
			FamilyProfile.data["combo_rewards"] = int(FamilyProfile.data.get("combo_rewards", 0)) + 1


func _tick_events(delta: float) -> void:
	if event_t > 0.0:
		event_t -= delta
		if event == "cash_rain" and randf() < delta * 6.0:
			var cam := get_viewport().get_camera_2d()
			var cx := cam.global_position.x if cam else _lead_pos().x
			LootDrop.spawn(_host(), Vector2(cx + randf_range(-280, 280), randf_range(440, 590)), "coin", 1, 0.3)
		if event_t <= 0.0:
			Juice.toast("quest", "STREET EVENT OVER", "Back to normal. Whatever normal is here.")
			_dark(false)
			event = ""
		return
	if get_tree().get_first_node_in_group("act_final_boss") != null:
		return
	_event_cd -= delta
	if _event_cd > 0.0:
		return
	_event_cd = randf_range(70.0, 100.0)
	event = ["blackout", "cash_rain", "rush_hour"][randi() % 3]
	event_t = {"blackout": 14.0, "cash_rain": 8.0, "rush_hour": 12.0}[event]
	var txt: Dictionary = {
		"blackout": ["BLACKOUT", "The grid gave up. Thugs drop double coins in the dark."],
		"cash_rain": ["CASH RAIN", "An ATM upstairs exploded. Grab it before the pigeons do."],
		"rush_hour": ["RUSH HOUR", "Everyone is late. Thugs are faster, kills pay double score."],
	}
	if event == "blackout":
		_dark(true)
	Juice.shout(str(txt[event][0]))
	Juice.toast("quest", str(txt[event][0]), str(txt[event][1]))
	Juice.pulse_shake(4.0)
	FamilyProfile.data["street_events"] = int(FamilyProfile.data.get("street_events", 0)) + 1


var _mod: CanvasModulate
var _mod_was := Color.WHITE


## BLACKOUT dims the whole street (reuses the map's CanvasModulate if any).
func _dark(on: bool) -> void:
	if on:
		for c in _host().get_children():
			if c is CanvasModulate:
				_mod = c
				_mod_was = _mod.color
		if _mod == null:
			_mod = CanvasModulate.new()
			_host().add_child(_mod)
		var tw := _mod.create_tween()
		tw.tween_property(_mod, "color", _mod_was * Color(0.42, 0.42, 0.58), 0.6)
	elif _mod != null:
		var tw2 := _mod.create_tween()
		tw2.tween_property(_mod, "color", _mod_was, 0.8)


func _tick_runner(delta: float) -> void:
	if _runner_done:
		return
	_runner_cd -= delta
	if _runner_cd > 0.0:
		return
	_runner_done = true
	var at := _lead_pos() + Vector2(220, randf_range(-20, 20))
	var p := Party.spawn_row(_host(), {"title": "Bag Snatch", "hp": 70, "home": "street"}, 1.0)
	p.global_position = Vector2(at.x, clampf(at.y, 440, 580))
	# A negative speed makes the brawler AI run AWAY from the family.
	p.speed = -88.0
	p._walk = -88.0
	p._base_mod = Color(1.4, 1.25, 0.5)
	p.set_meta("refund", true)
	p.died.connect(func() -> void:
		var pos := p.global_position
		LootDrop.spawn(_host(), pos, "cash", 45)
		for i in 6:
			LootDrop.spawn(_host(), pos, "coin", 2, 1.4)
		LootDrop.spawn(_host(), pos, "shard_" + ("son" if randf() < 0.5 else "father"), 3, 0.8)
		Juice.unlock_logo("TAX REFUND", "Caught him. The family is solvent for a week.", "STREET RUNNER")
		FamilyProfile.data["refunds"] = int(FamilyProfile.data.get("refunds", 0)) + 1
	)
	Juice.shout("TAX REFUND!")
	Juice.toast("quest", "HE HAS YOUR REFUND", "A thug with the family's money is running. Catch him in 18 seconds.")
	get_tree().create_timer(18.0).timeout.connect(func() -> void:
		if is_instance_valid(p) and p.hp > 0:
			Juice.toast("quest", "GOT AWAY", "The refund is in another city now.")
			p.queue_free()
	)


## The street vending machine: stand at it and press UP (or LIGHT) to buy a
## 45 s blessing. Three a night, each dearer.
class BlessingMachine:
	extends Node2D

	var uses := 0
	var _t := 0.0
	var _prompt: Label

	func _ready() -> void:
		z_index = 2
		var glow := PointLight2D.new()
		glow.texture = LightRig.radial_tex()
		glow.texture_scale = 0.5
		glow.color = Color(0.4, 0.9, 1.0)
		glow.energy = 0.9
		glow.position = Vector2(0, -30)
		add_child(glow)
		_prompt = Label.new()
		_prompt.position = Vector2(-70, -96)
		_prompt.size = Vector2(140, 14)
		_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_prompt.add_theme_font_size_override("font_size", 7)
		_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_prompt.add_theme_constant_override("outline_size", 3)
		_prompt.visible = false
		add_child(_prompt)

	func price() -> int:
		return 25 * (uses + 1)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		var near: Fighter = null
		for n in get_tree().get_nodes_in_group("players"):
			if n is Fighter and absf((n as Fighter).global_position.x - global_position.x) < 34.0 and absf((n as Fighter).global_position.y - global_position.y - 40.0) < 50.0:
				near = n
		_prompt.visible = near != null
		if near == null:
			return
		_prompt.text = "UP: BLESSING %dG" % price() if uses < 3 else "SOLD OUT"
		if uses >= 3 or not (near._just("up") or near._just("light")) or absf(near.velocity.x) > 30.0:
			return
		if int(FamilyProfile.data.get("gold", 0)) < price():
			Juice.popup_number(global_position + Vector2(0, -80), "NEED %d GOLD" % price(), Palette.BRICK)
			return
		FamilyProfile.data["gold"] = int(FamilyProfile.data["gold"]) - price()
		uses += 1
		var pick: String = ["protein", "espresso", "vitamin"][randi() % 3]
		NightExtras.blessing = pick
		NightExtras.blessing_t = 45.0
		var t: Dictionary = {"protein": ["PROTEIN SHAKE", "+25% damage for 45 s."], "espresso": ["TRIPLE ESPRESSO", "+15% speed for 45 s."], "vitamin": ["VITAMIN WATER", "Heal 30% now, take 25% less damage for 45 s."]}
		if pick == "vitamin":
			near.hp = mini(near.max_hp, near.hp + int(round(float(near.max_hp) * 0.3)))
		Juice.toast("reward", str(t[pick][0]), str(t[pick][1]))
		Juice.shout(str(t[pick][0]))
		Juice.play("res://assets/audio/cash.wav" if ResourceLoader.exists("res://assets/audio/cash.wav") else "res://assets/audio/cling.wav")
		FamilyProfile.data["blessings"] = int(FamilyProfile.data.get("blessings", 0)) + 1

	func _draw() -> void:
		draw_rect(Rect2(-16, -72, 32, 72), Color(0.12, 0.2, 0.32))
		draw_rect(Rect2(-16, -72, 32, 72), Color(0.05, 0.08, 0.12), false, 1.5)
		draw_rect(Rect2(-12, -66, 18, 40), Color(0.5, 0.85, 1.0, 0.55 + 0.15 * sin(_t * 3.0)))
		for i in 4:
			for j in 2:
				var c: Color = [Color(1, 0.4, 0.3), Color(1, 0.85, 0.3), Color(0.4, 1, 0.5), Color(0.9, 0.5, 1)][(i + j) % 4]
				draw_rect(Rect2(-10 + j * 8, -62 + i * 9, 5, 6), c)
		draw_rect(Rect2(8, -60, 5, 14), Color(0.7, 0.72, 0.78))
		draw_rect(Rect2(-12, -18, 24, 8), Color(0.03, 0.04, 0.06))
		draw_rect(Rect2(-16, -80, 32, 9), Color(0.9, 0.2, 0.25))
