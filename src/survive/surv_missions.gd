class_name SurvMissions
extends Node

## In-run MISSIONS for the coping hour (Jotunnslayer style): every so often
## an optional job pops up with its own timer bar at the top:
##   CULL       kill N before the clock runs out
##   HOLD       stand in the marked circle long enough
##   CLEAN      take no damage for a while
##   CHAMPION   a named champion walks in (summoner, charger, shielder or
##              bomber): put him down in time
## Success drops a MISSION CHEST (S-COINS, gear, a starter-weapon copy);
## the hour's boss and every champion drop a BOSS CHEST. It also keeps the
## numbers the challenges read (missions, champions, no-hit streak, boss).

const FIRST_AT := 40.0
const EVERY := 70.0
const CHAMPS := {
	"summoner": {"name": "HR DIRECTOR", "col": Color(0.75, 0.45, 1.0), "title": "Invoice Clerk"},
	"charger": {"name": "OVERTIME OGRE", "col": Color(1.0, 0.45, 0.25), "title": "Repo Goon"},
	"shielder": {"name": "THE AUDITOR", "col": Color(0.45, 0.8, 1.0), "title": "Vest Ollie"},
	"bomber": {"name": "MAIL ROOM MAD", "col": Color(1.0, 0.85, 0.3), "title": "Mohawk Bo"},
}

var done_n := 0
var champs_n := 0
var boss_n := 0
var nohit_best := 0.0
var _nohit := 0.0
var _next := FIRST_AT
var _t := 0.0
var _kind := ""
var _left := 0.0
var _goal := 0.0
var _have := 0.0
var _kills0 := 0
var _hp0 := 0
var _champ: Punk
var _circle: Node2D
var _hud: Control
var _bar: ColorRect
var _lab: Label
var _time_lab: Label
var _seen_boss := {}


func _run() -> SurviveRun:
	return SurviveRun.get_run(get_tree())


func _lead() -> Fighter:
	for n in get_tree().get_nodes_in_group("players"):
		if n is Fighter and not (n as Fighter).downed:
			return n
	return null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if OS.get_environment("SURV_MISSION") != "":
		_next = 0.5
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var root := PixelStage.attach_canvas(layer)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud = PanelContainer.new()
	var sb := UiKit.panel(Color(0.04, 0.05, 0.09, 0.92), UiKit.GOLD)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	_hud.add_theme_stylebox_override("panel", sb)
	_hud.position = Vector2(14, 152)
	_hud.custom_minimum_size = Vector2(360, 0)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	root.add_child(_hud)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_hud.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	top.add_child(IconBook.rect("node_crown", 28))
	_lab = Label.new()
	_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab.add_theme_font_override("font", UiKit.title_font())
	UiKit.apply_label(_lab, 14, UiKit.GOLD)
	top.add_child(_lab)
	_time_lab = Label.new()
	_time_lab.add_theme_font_override("font", UiKit.pixel_font())
	UiKit.apply_label(_time_lab, 12, Palette.TEXT)
	top.add_child(_time_lab)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0.02)
	bg.custom_minimum_size = Vector2(340, 8)
	col.add_child(bg)
	_bar = ColorRect.new()
	_bar.color = Palette.READY
	_bar.size = Vector2(0, 8)
	bg.add_child(_bar)


func _process(delta: float) -> void:
	var run := _run()
	var f := _lead()
	if run == null or f == null:
		return
	_t += delta
	_watch_bosses()
	# No-hit streak for the challenge.
	if f.hp < _hp0:
		_nohit = 0.0
	else:
		_nohit += delta
		nohit_best = maxf(nohit_best, _nohit)
	if _kind == "":
		_hp0 = f.hp
		if _t >= _next:
			_start(run, f)
		return
	_left -= delta
	match _kind:
		"cull":
			_have = float(run.kills - _kills0)
		"hold":
			if _circle and f.global_position.distance_to(_circle.global_position) < 46.0:
				_have += delta
		"clean":
			if f.hp < _hp0:
				_fail("HIT. THE CLIPBOARD SAW.")
				return
			_have += delta
		"champion":
			if not is_instance_valid(_champ) or _champ.hp <= 0:
				_have = _goal
			else:
				_champ_tick(delta)
	_hp0 = f.hp
	_bar.size.x = 340.0 * clampf(_have / maxf(0.01, _goal), 0.0, 1.0)
	_bar.color = Palette.READY if _left > 6.0 else Color(1.0, 0.35, 0.3)
	_time_lab.text = "%d" % int(ceil(_left))
	if _have >= _goal:
		_win(f)
	elif _left <= 0.0:
		_fail("TIME. THE MEMO EXPIRED.")


func _start(run: SurviveRun, f: Fighter) -> void:
	var kinds := ["cull", "hold", "clean", "champion"]
	_kind = str(kinds[randi() % kinds.size()])
	# Dev shots: SURV_MISSION=<kind> forces one right away.
	if OS.get_environment("SURV_MISSION") in kinds:
		_kind = OS.get_environment("SURV_MISSION")
	_have = 0.0
	_kills0 = run.kills
	_hp0 = f.hp
	match _kind:
		"cull":
			_goal = 30.0 + floor(_t / 60.0) * 10.0
			_left = 30.0
			_lab.text = "MISSION  ·  KILL %d" % int(_goal)
		"hold":
			_goal = 10.0
			_left = 30.0
			_lab.text = "MISSION  ·  HOLD THE MARK"
			_circle = Mark.new()
			_circle.global_position = f.global_position + Vector2(randf_range(-160, 160), randf_range(-20, 20))
			get_parent().add_child(_circle)
		"clean":
			_goal = 18.0
			_left = 18.5
			_lab.text = "MISSION  ·  DON'T GET HIT"
		"champion":
			_goal = 1.0
			_left = 50.0
			_spawn_champ(f)
	_hud.visible = true
	_hud.pivot_offset = _hud.size * 0.5
	_hud.scale = Vector2(0.6, 0.6)
	_hud.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(_hud, "scale", Vector2.ONE, 0.2)
	Juice.shout(_lab.text.get_slice("·", 1).strip_edges())
	RewardFly.snd("reward_pop", 0.8, -4.0)


func _end() -> void:
	_kind = ""
	_next = _t + EVERY
	if _circle and is_instance_valid(_circle):
		_circle.queue_free()
	_circle = null
	var tw := _hud.create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(func() -> void: _hud.visible = false)


func _win(f: Fighter) -> void:
	done_n += 1
	if _kind == "champion":
		champs_n += 1
	Juice.toast("quest", "MISSION DONE", "A chest dropped. Overtime is paid.", "cur_chest")
	Juice.shout("MISSION DONE")
	Juice.upgrade_fx(_hud, Palette.READY, "", true)
	BossChest.drop(get_parent(), f.global_position + Vector2(40.0 * float(f.facing), 0), _kind == "champion")
	_end()


func _fail(why: String) -> void:
	Juice.toast("challenge", "MISSION FAILED", why)
	RewardFly.snd("deny")
	if _kind == "champion" and is_instance_valid(_champ):
		_champ.set_meta("champ_expired", true)
	_end()


# --- champions -----------------------------------------------------------

func _spawn_champ(f: Fighter) -> void:
	var keys := CHAMPS.keys()
	var k := str(keys[randi() % keys.size()])
	var spec: Dictionary = CHAMPS[k]
	var side := 1.0 if randf() < 0.5 else -1.0
	var mw := float(get_parent().get("map_w")) if get_parent().get("map_w") != null else 3000.0
	var cx := f.global_position.x + side * 260.0
	if cx < 80.0 or cx > mw - 80.0:
		cx = f.global_position.x - side * 260.0
	cx = clampf(cx, 80.0, mw - 80.0)
	var row := {"title": spec["title"], "x": cx, "y": f.global_position.y, "home": "street", "hp": 60, "pmin": f.global_position.x - 600.0, "pmax": f.global_position.x + 600.0}
	var run := _run()
	var hp_mul := 14.0 + _t / 20.0
	_champ = Party.spawn_row(get_parent(), row, hp_mul)
	if _champ == null:
		_kind = ""
		return
	# Punk sets its own health from its kit in _ready: the champion's goes on top.
	_champ.hp = int(60.0 * hp_mul)
	_champ.max_hp = _champ.hp
	_champ.set_meta("champ", k)
	_champ.scale = Vector2(1.45, 1.45)
	_champ.modulate = (spec["col"] as Color).lerp(Color.WHITE, 0.5)
	if k == "charger":
		_champ.speed *= 1.6
	OverheadBadge.attach.call_deferred(_champ, "boss")
	_champ.add_child.call_deferred(EliteTag.make("CHAMPION · " + str(spec["name"]), spec["col"], Vector2(-70, -104), 140))
	_lab.text = "MISSION  ·  " + str(spec["name"])
	Juice.pulse_shake(4.0)
	if run:
		Discover.see("enemy", str(spec["title"]), str(spec["title"]).to_upper())


var _ct := 0.0


func _champ_tick(delta: float) -> void:
	_ct -= delta
	if _ct > 0.0:
		return
	var k := str(_champ.get_meta("champ", ""))
	var at := _champ.global_position
	match k:
		"summoner":
			_ct = 4.5
			for i in 2:
				Party.spawn_row(get_parent(), {"title": "Coping Imp", "x": at.x + (i * 2 - 1) * 30.0, "y": at.y, "home": "street", "hp": 30, "pmin": at.x - 400.0, "pmax": at.x + 400.0}, 1.0 + _t / 120.0)
			SurvProj.ring(get_parent(), at, 40.0, CHAMPS[k]["col"])
		"charger":
			_ct = 3.0
			var f := _lead()
			if f:
				var dir := signf(f.global_position.x - at.x)
				_champ.global_position.x += dir * 60.0
				SurvProj.ring(get_parent(), at, 30.0, CHAMPS[k]["col"])
		"shielder":
			_ct = 0.5
			# Heals back slowly unless hit hard: a shield that has to be broken.
			_champ.hp = mini(_champ.max_hp, _champ.hp + maxi(1, _champ.max_hp / 120))
		"bomber":
			_ct = 3.5
			var f2 := _lead()
			if f2:
				var w := Warn.new()
				w.src = _champ
				w.global_position = f2.global_position
				get_parent().add_child(w)


func _watch_bosses() -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is ActBoss and not _seen_boss.has(n.get_instance_id()):
			_seen_boss[n.get_instance_id()] = true
			var b := n as ActBoss
			b.died.connect(func() -> void:
				boss_n += 1
				BossChest.drop(get_parent(), b.global_position, true)
			)


func stats() -> Dictionary:
	return {"missions": done_n, "champs": champs_n, "boss": boss_n, "nohit": int(nohit_best)}


## A red ring under you: get out before it goes off.
class Warn extends Node2D:
	var src: Node
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= 0.9:
			for n in get_tree().get_nodes_in_group("players"):
				if n is Fighter and (n as Fighter).global_position.distance_to(global_position) < 40.0 and is_instance_valid(src):
					(n as Fighter).take_hit("heavy", src)
			SurvProj.ring(get_parent(), global_position, 40.0, Color(1.0, 0.5, 0.2))
			Juice.pulse_shake(3.0)
			Mixer.play_sfx("res://assets/audio/hit_heavy.wav", 0.7, -6.0)
			queue_free()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 40.0 * clampf(_t / 0.9, 0.0, 1.0), Color(1.0, 0.25, 0.2, 0.3))
		draw_arc(Vector2.ZERO, 40.0, 0, TAU, 32, Color(1.0, 0.3, 0.25, 0.9), 2.0)


## The ring you have to stand in for HOLD.
class Mark extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 46.0, Color(0.4, 1.0, 0.55, 0.12 + 0.06 * sin(_t * 5.0)))
		draw_arc(Vector2.ZERO, 46.0, 0, TAU, 40, Color(0.5, 1.0, 0.6, 0.9), 2.0)
		draw_arc(Vector2.ZERO, 46.0 - fmod(_t * 30.0, 46.0), 0, TAU, 40, Color(0.5, 1.0, 0.6, 0.4), 1.0)
