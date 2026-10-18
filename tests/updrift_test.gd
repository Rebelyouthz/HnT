extends SceneTree

## UP + HEAVY is an uppercut on the spot: the hero does not walk up first,
## and a held heavy keeps the feet planted. Plain UP still walks.
## ATTACK, then UP inside the short window turns the blow into the uppercut
## (light or heavy), with no drift; walking up and punching stays a jab.
## Prints UPDRIFT OK.

## The uppercut art: the old clip or the right / left hand ones.
const UPPERS := ["uppercut", "upper_r", "upper_l"]

var _n := 0
var ok := true
var _hero: Node2D
var _y0 := 0.0


func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FAIL: ", what)


func _process(_d: float) -> bool:
	_n += 1
	if _n == 2:
		root.get_node("App").set("solo_role", "father")
		root.get_node("App").call("enter_map", "dock_street")
	if _n > 40 and paused:
		paused = false
	if _n == 60:
		for c in current_scene.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("stage_card.gd"):
				c.queue_free()
		_hero = get_first_node_in_group("players")
		var dj: Dictionary = root.get_node("FamilyProfile").data.get("dojo", {})
		dj["uppercut"] = 1
		root.get_node("FamilyProfile").data["dojo"] = dj
		_y0 = _hero.global_position.y
		Input.action_press("p1_up")
	if _n == 63:
		Input.action_press("p1_heavy")
	if _n == 75:
		Input.action_release("p1_heavy")
	if _n == 78:
		_check(int(_hero.get("attack_cd")) > 0, "the uppercut was thrown")
	if _n == 90:
		Input.action_release("p1_up")
		_check(absf(_hero.global_position.y - _y0) < 3.0, "up+heavy stays put, even with up still held (dy %.1f)" % (_hero.global_position.y - _y0))
	if _n == 130:
		_y0 = _hero.global_position.y
		Input.action_press("p1_up")
	if _n == 160:
		Input.action_release("p1_up")
		_check(_hero.global_position.y < _y0 - 10.0, "plain up still walks (dy %.1f)" % (_hero.global_position.y - _y0))
	# LIGHT, then UP 4 frames later: uppercut, feet still.
	if _n == 200:
		_y0 = _hero.global_position.y
		Input.action_press("p1_light")
	if _n == 202:
		Input.action_release("p1_light")
	if _n == 204:
		Input.action_press("p1_up")
	if _n == 207:
		_check(str(_hero.get("_strike_clip")) in UPPERS, "light then up = uppercut (got %s)" % _hero.get("_strike_clip"))
	if _n == 235:
		Input.action_release("p1_up")
		_check(absf(_hero.global_position.y - _y0) < 3.0, "light then up stays put (dy %.1f)" % (_hero.global_position.y - _y0))
	# Walking up, then LIGHT: a jab, never an uppercut.
	if _n == 280:
		Input.action_press("p1_up")
	if _n == 310:
		Input.action_press("p1_light")
	if _n == 312:
		Input.action_release("p1_light")
	if _n == 316:
		_check(not (str(_hero.get("_strike_clip")) in UPPERS), "walk up + light is a jab (got %s)" % _hero.get("_strike_clip"))
	if _n == 330:
		Input.action_release("p1_up")
	# HEAVY held, UP 6 frames later, release: uppercut, feet still.
	if _n == 370:
		_y0 = _hero.global_position.y
		Input.action_press("p1_heavy")
	if _n == 376:
		Input.action_press("p1_up")
	if _n == 380:
		Input.action_release("p1_heavy")
	if _n == 384:
		_check(str(_hero.get("_strike_clip")) in UPPERS, "heavy then up = uppercut (got %s)" % _hero.get("_strike_clip"))
	if _n == 410:
		Input.action_release("p1_up")
		_check(absf(_hero.global_position.y - _y0) < 3.0, "heavy then up stays put (dy %.1f)" % (_hero.global_position.y - _y0))
		print("UPDRIFT OK" if ok else "UPDRIFT FAILED")
		quit()
	return false
