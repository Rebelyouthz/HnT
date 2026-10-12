class_name BoneYardAct
extends RunAct

## One BONE YARD map: a short arena behind the dojo, one shared life, three
## waves (the last with a named heavy). Cleared, it pays FIGHT TOKENS and
## the run walks straight into the next open yard; the last one ends at the
## results card. Nights, builds and story resumes are not touched.

const BLOOD := Color(0.92, 0.2, 0.16)

var yard_id := "butcher_row"
var _m: Dictionary
var _wave := -1
var _wave_t := 2.4
var _yard_done := false


func _configure() -> void:
	_m = BoneYard.map(yard_id)
	map_id = yard_id
	map_w = 1680.0
	spawn_at = Vector2(260, 490)
	goal_x = 99999.0
	next_id = ""
	light_preset = str(_m.get("light", "dock_street"))
	music = "res://assets/audio/music/music_boss.ogg"
	toast_title = "BONE YARD  ·  " + str(_m.get("title", ""))
	toast_body = str(_m.get("blurb", "")) + "  ONE LIFE."
	clear_title = str(_m.get("title", "")) + "  CLEARED"
	fail_sub = "One life in the Bone Yard. The tokens you earned stay yours."
	win_mode = "boss"


func _ready() -> void:
	if not BoneYard.active:
		# Walked in directly (tests, debug): a one-yard run.
		BoneYard.chain = [yard_id]
		BoneYard.active = true
		BoneYard.step = 0
		BoneYard.t0 = Time.get_ticks_msec() / 1000.0
		BoneYard.parries0 = int(FamilyProfile.data.get("parries", 0))
	super._ready()
	_state.lives = 1
	_state.lives_changed.emit()


func build_world() -> void:
	var theme := str(_m.get("theme", "dock"))
	NightStreet.parallax(self, map_w, theme)
	if WetStreet.available():
		WetStreet.lay(self, map_w)
	else:
		NightStreet.wet_floor(self, map_w)
	NightStreet.bounds(self, map_w)
	NightStreet.plaque(self, Vector2(80, 120), "BONE YARD  ·  %s" % str(_m.get("title", "")), BLOOD, 22)
	var y := 150.0
	for c in _m.get("challenges", []):
		NightStreet.plaque(self, Vector2(80, y), ("✓ " if BoneYard.done("%s:%s" % [yard_id, str(c["id"])]) else "○ ") + str(c["text"]), Palette.MUTED, 13)
		y += 18.0
	# A pipe for the weapon branch.
	var pipe := WeaponPickup.new()
	pipe.kind = "pipe"
	pipe.global_position = Vector2(map_w * 0.55, 500)
	add_child(pipe)


## No story resume points in the yard.
func _save_resume(_at: Vector2, _announce: bool) -> void:
	pass


func _process(delta: float) -> void:
	super._process(delta)
	if _state == null or _state.failed or _state.cleared or _yard_done:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and int(e.get("hp")) > 0:
			return
	_wave_t -= delta
	if _wave_t > 0.0:
		return
	var waves: Array = _m.get("waves", [])
	_wave += 1
	if _wave >= waves.size():
		_yard_clear()
		return
	_spawn_wave(waves[_wave], _wave == waves.size() - 1)
	_wave_t = 1.8


func _spawn_wave(rows: Array, last: bool) -> void:
	var lead := spawn_at.x
	var n := 0
	for f in [_son, _dad]:
		if f and is_instance_valid(f):
			lead = f.global_position.x if n == 0 else (lead + f.global_position.x) * 0.5
			n += 1
	var hp_mul := _state.hp_mul()
	var k := 0
	for r: Dictionary in rows:
		var side := -1.0 if str(r.get("side", "R")) == "L" else 1.0
		var x := clampf(lead + side * (340.0 + 40.0 * float(k)), 60.0, map_w - 60.0)
		if absf(x - lead) < 160.0:
			x = clampf(lead - side * 340.0, 60.0, map_w - 60.0)
		var row := {"title": r["title"], "hp": r["hp"], "home": "street", "pmin": 40.0, "pmax": map_w - 40.0, "armored": bool(r.get("armored", false))}
		var pk := Party.spawn_row(self, row, hp_mul)
		if pk:
			pk.global_position = Vector2(x, 470.0 + 14.0 * float(k % 4))
			if r.has("name"):
				pk.set_meta("yard_boss", str(r["name"]))
				Juice.popup_number(pk.global_position + Vector2(0, -120), str(r["name"]), BLOOD)
		k += 1
	Juice.shout("FINAL WAVE" if last else "WAVE %d" % (_wave + 1))
	Mixer.play_sfx("res://assets/audio/sfx/bone_crack.ogg", 0.7, -6.0)


func _yard_clear() -> void:
	_yard_done = true
	var lines := BoneYard.on_clear(yard_id, [_son, _dad])
	var nxt := BoneYard.next_map()
	if nxt != "":
		BoneYard.step += 1
		for f in [_son, _dad]:
			if f and is_instance_valid(f):
				f.invuln = 600
		for l in lines:
			Juice.toast("reward", str(_m.get("title", "")), str(l))
		Juice.shout("YARD CLEARED")
		App.run_bag = _state.pack()
		get_tree().create_timer(3.2, true, false, true).timeout.connect(func() -> void:
			if is_inside_tree():
				App.enter_map(nxt)
		)
		return
	clear_sub = "\n".join(PackedStringArray(lines))
	BoneYard.end_run()
	_state.clear_run()


## Cleared: the results card only (no night, no build, no story filing).
func _on_clear() -> void:
	_clear_resume()
	if _state:
		FamilyProfile.note_score(_state.score_total)
	FamilyProfile.data["boneyard_runs"] = int(FamilyProfile.data.get("boneyard_runs", 0)) + 1
	FamilyProfile.save()
	_banner(clear_title, clear_sub, true, false)


func _on_fail() -> void:
	_clear_resume()
	BoneYard.end_run()
	FamilyProfile.data["boneyard_runs"] = int(FamilyProfile.data.get("boneyard_runs", 0)) + 1
	FamilyProfile.save()
	if _state:
		FamilyProfile.note_score(_state.score_total)
	_banner(Copy.FAIL, fail_sub, false, false, 0)
	if _end is ResultsSheet:
		(_end as ResultsSheet).death_line = DeathCause.for_run(get_tree())
