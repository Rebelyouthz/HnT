class_name NightCondition
extends RefCounted

## Every story stage rolls one condition for the night, named on its title
## card and the objectives card. It bends the stage a little:
##   BLACKOUT     the street lights fail; coins x2
##   INVOICE RAIN paper falls from the windows; XP x1.5
##   HAPPY HOUR   thugs are faster and drunker; coins x2, gems x1.25
##   FULL MOON    thugs are tougher (+30% health); XP and coins x1.5
##   QUIET NIGHT  nothing. Suspicious.

const ROWS := {
	"blackout": {"name": "BLACKOUT", "line": "The street lights failed. Coins x2.", "coins": 2.0, "xp": 1.0},
	"invoice_rain": {"name": "INVOICE RAIN", "line": "Paper falls from every window. XP x1.5.", "coins": 1.0, "xp": 1.5},
	"happy_hour": {"name": "HAPPY HOUR", "line": "Thugs are faster and drunker. Coins x2.", "coins": 2.0, "xp": 1.25, "speed": 1.2},
	"full_moon": {"name": "FULL MOON", "line": "Thugs are tougher. XP and coins x1.5.", "coins": 1.5, "xp": 1.5, "hp": 1.3},
	"quiet": {"name": "QUIET NIGHT", "line": "Nothing special. Suspicious.", "coins": 1.0, "xp": 1.0},
}


## The condition of this stage this run (rolled once, kept in the run bag).
static func of(map_id: String) -> Dictionary:
	var key := "cond_" + map_id
	if not App.run_bag.has(key):
		# Dock Street's first night is always quiet: learn the street first.
		if map_id == "dock_street" and (FamilyProfile.data.get("maps_filed", []) as Array).is_empty():
			App.run_bag[key] = "quiet"
		else:
			var ids := ROWS.keys()
			App.run_bag[key] = str(ids[randi() % ids.size()])
	var id := str(App.run_bag[key])
	var r: Dictionary = (ROWS.get(id, ROWS["quiet"]) as Dictionary).duplicate()
	r["id"] = id
	return r


static func mul(map_id: String, what: String) -> float:
	return float(of(map_id).get(what, 1.0))


## Dress the stage for its condition (called once the world is built).
static func dress(host: Node2D, map_id: String) -> void:
	var c := of(map_id)
	match str(c["id"]):
		"blackout":
			var cm := CanvasModulate.new()
			cm.color = Color(0.55, 0.55, 0.68)
			host.add_child(cm)
		"invoice_rain":
			var p := CPUParticles2D.new()
			p.amount = 60
			p.lifetime = 6.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(700, 10)
			p.gravity = Vector2(10, 40)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 20.0
			p.angular_velocity_min = -180.0
			p.angular_velocity_max = 180.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 3.5
			p.color = Color(0.96, 0.95, 0.88, 0.9)
			p.z_index = 8
			p.position = Vector2(0, -40)
			p.set_meta("follow", true)
			host.add_child(p)
			host.set_meta("rain_paper", p)
	host.set_meta("night_cond", c)


## Keep the paper rain over the camera.
static func follow(host: Node2D, cam: Camera2D) -> void:
	if host.has_meta("rain_paper") and cam:
		var p := host.get_meta("rain_paper") as Node2D
		if is_instance_valid(p):
			p.global_position = Vector2(cam.get_screen_center_position().x, cam.get_screen_center_position().y - 220.0)
