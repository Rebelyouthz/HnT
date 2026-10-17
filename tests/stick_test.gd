extends SceneTree

## Right-stick loadout: a fresh hero has the basics on the stick and empty
## paths for what he has not learned; learning a strike asks EQUIP NOW? and
## puts it on its free path; with every path full you pick which one goes.
## Stick paths fire whatever sits on them (diagonals, RT kicks, spin kicks).
## Prints STICK OK.

var _n := 0
var ok := true
var _f: Node


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _press(key: String) -> bool:
	for c in root.find_children("*", "Button", true, false):
		if str(c.get_meta("key", "")) == key:
			(c as Button).pressed.emit()
			return true
	return false


func _fire(pts: Array, kick := false) -> String:
	_f.set("attack_cd", 0)
	_f.set("anim_atk", "")
	_f.set("hop", 0.0)
	if kick:
		Input.action_press("p1_dash")
	var arr := PackedVector2Array()
	for p in pts:
		arr.append((p as Vector2).normalized())
	_f.call("_rs_fire", arr, 0.0)
	if kick:
		Input.action_release("p1_dash")
	return str(_f.get("_last_kind"))


func _process(_d: float) -> bool:
	_n += 1
	paused = false
	var fp := root.get_node("FamilyProfile")
	if _n == 2:
		Engine.set_meta("equip_prompt_test", true)
		fp.call("reset_progress")
		fp.data["intro_done"] = true
		fp.data["gold"] = 2000
		var lo: Dictionary = load("res://src/combat/stick_book.gd").loadout("son")
		_check(str(lo["flick"]) == "jab", "flick holds the jab string")
		_check(str(lo["circle"]) == "hook", "circle holds the hook")
		_check(str(lo["upper"]) == "", "half circle empty before the uppercut is drilled")
		_check(str(lo["k_spin"]) == "", "spin kick path empty before it is learned")
		root.get_node("App").call("enter_map", "dojo_practice")
	if _n == 60:
		_f = get_first_node_in_group("players")
		_f.set("facing", 1)
		_check(_fire([Vector2(1, 0)]) == "light", "flick = jab string")
		_check(_fire([Vector2(1, -1)]) == "overhand", "flick up-forward = overhand")
		_check(_fire([Vector2(1, 1)]) == "body_hook", "flick down-forward = body hook")
		_check(_fire([Vector2(1, 0)], true) == "front_kick", "RT + flick = front kick")
		# Learn the spinning high kick: EQUIP NOW? on its home path.
		_check(bool(load("res://src/combat/moves.gd").learn("son", "spin_high_kick")), "spin high kick learned")
		var ep: Variant = load("res://src/ui/equip_prompt.gd").ask("son", "spin_high_kick")
		_check(ep != null, "EQUIP NOW? opens")
	if _n == 66:
		_check(get_first_node_in_group("equip_prompt") != null, "prompt in the tree")
		_check(_press("equip_yes"), "YES offered (free path)")
	if _n == 70:
		var sb: Variant = load("res://src/combat/stick_book.gd")
		_check(str(sb.loadout("son")["k_spin"]) == "spin_high_kick", "spin high kick on RT + FULL CIRCLE")
		_check(_fire([Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0), Vector2(0.7, 0.7)], true) == "spin_high_kick", "RT + full circle fires it")
		# Fill every kick path, then learn one more: pick which it replaces.
		load("res://src/combat/moves.gd").learn("son", "sweep")
		load("res://src/combat/moves.gd").learn("son", "side_kick")
		load("res://src/combat/moves.gd").learn("son", "flying_knee")
		load("res://src/combat/moves.gd").learn("son", "cartwheel_kick")
		load("res://src/combat/moves.gd").learn("son", "spin_low_kick")
		for pair in [["k_diag_up", "sweep"], ["k_down", "side_kick"], ["k_circle", "flying_knee"], ["k_upper", "cartwheel_kick"], ["k_windup", "spin_low_kick"]]:
			sb.set_slot("son", pair[0], pair[1])
		_check(sb.free_slot("son", "boot_kick") == "", "kick paths full")
		fp.data["dojo"] = {"roundhouse": 1}
		fp.data["dojo_train"] = {"roundhouse": 3}
		var ep2: Variant = load("res://src/ui/equip_prompt.gd").ask("son", "roundhouse")
		_check(ep2 != null, "EQUIP NOW? when full")
	if _n == 76:
		_check(not _press("equip_yes"), "no YES when every path is taken")
		_check(_press("equip_k_circle"), "pick RT + QUARTER CIRCLE to replace")
	if _n == 80:
		var sb2: Variant = load("res://src/combat/stick_book.gd")
		_check(str(sb2.loadout("son")["k_circle"]) == "roundhouse", "roundhouse replaced the flying knee")
		_check(sb2.slot_of("son", "flying_knee") == "", "flying knee off the stick")
		_check(not root.get_tree().paused, "game unpaused after the pick")
		print("STICK OK" if ok else "STICK FAILED")
		quit(0 if ok else 1)
	return false
