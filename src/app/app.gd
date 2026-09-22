extends Node

signal tab_wanted(tab: String)

var difficulty: String = "night_class"
var last_run_ok: bool = false
var pending_tab: String = "clinic"
## Couch 2P is opt-in. Hub GO / Clinic PLAY start immediately with one body.
var couch: bool = false
var solo_role: String = "son"
## Locked when the run starts. Drop-in does not thicken the spawn.
var density_coop: bool = false
var remote_coop: bool = false
var versus: bool = false
var force_intro: bool = false
var run_bag: Dictionary = {}
var map_index: int = 0
var current_map: String = "dock_street"
var film_from: String = ""
var film_next: String = ""
var film_kind: String = ""

const SCENES := {
	"intro_flow": "res://scenes/levels/intro_flow.tscn",
	"tutorial_alley": "res://scenes/levels/tutorial_alley.tscn",
	"act_film": "res://scenes/levels/act_film.tscn",
	"dock_street": "res://scenes/levels/dock_street.tscn",
	"intake_lot": "res://scenes/levels/intake_lot.tscn",
	"fire_escapes": "res://scenes/levels/fire_escapes.tscn",
	"group_circle": "res://scenes/levels/group_circle.tscn",
	"neon_exchange": "res://scenes/levels/neon_exchange.tscn",
	"waiting_room": "res://scenes/levels/waiting_room.tscn",
	"rail_bridge": "res://scenes/levels/rail_bridge.tscn",
	"city_hall": "res://scenes/levels/city_hall.tscn",
	"copay_orchard": "res://scenes/levels/copay_orchard.tscn",
	"sleet_hour": "res://scenes/levels/sleet_hour.tscn",
	"raven_grid": "res://scenes/levels/raven_grid.tscn",
	"ledger_dive": "res://scenes/levels/ledger_dive.tscn",
	"invoice_pier": "res://scenes/levels/invoice_pier.tscn",
	"processing_floor": "res://scenes/levels/processing_floor.tscn",
	"versus": "res://scenes/levels/versus.tscn",
	"parachute_fall": "res://scenes/levels/parachute_fall.tscn",
	"skinwalker_film": "res://scenes/levels/skinwalker_film.tscn"
}

const ORDER := [
	"dock_street", "intake_lot", "fire_escapes", "group_circle",
	"neon_exchange", "waiting_room", "rail_bridge", "city_hall",
	"copay_orchard", "sleet_hour", "raven_grid", "ledger_dive",
	"invoice_pier", "processing_floor"
]


func start_run() -> void:
	versus = false
	difficulty = str(FamilyProfile.data.get("difficulty", difficulty))
	density_coop = couch or remote_coop
	run_bag = {}
	map_index = 0
	current_map = "dock_street"
	film_from = ""
	film_next = ""
	film_kind = ""
	last_run_ok = false
	if remote_coop:
		enter_map("dock_street")
		return
	if force_intro or not bool(FamilyProfile.data.get("intro_done", false)):
		force_intro = false
		enter_map("intro_flow")
		return
	enter_map("dock_street")


func start_versus() -> void:
	versus = true
	run_bag = {}
	remote_coop = false
	current_map = "versus"
	enter_map("versus")


func play_intro() -> void:
	force_intro = true
	versus = false
	start_run()


func enter_map(map_id: String) -> void:
	current_map = map_id
	var i := ORDER.find(map_id)
	map_index = i if i >= 0 else map_index
	var path := str(SCENES.get(map_id, SCENES["dock_street"]))
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func begin_extra() -> Dictionary:
	return {
		"film_from": film_from,
		"film_next": film_next,
		"film_kind": film_kind,
		"run_bag": run_bag.duplicate(true)
	}


func apply_begin_extra(d: Dictionary) -> void:
	film_from = str(d.get("film_from", film_from))
	film_next = str(d.get("film_next", film_next))
	film_kind = str(d.get("film_kind", film_kind))
	var bag: Variant = d.get("run_bag", {})
	if typeof(bag) == TYPE_DICTIONARY:
		run_bag = (bag as Dictionary).duplicate(true)


func advance(next_id: String, state: RunState) -> void:
	run_bag = state.pack()
	get_tree().paused = false
	film_from = current_map
	film_next = next_id
	if next_id == "ending":
		film_kind = "ending"
		film_next = "hub"
		_hop("act_film")
		return
	if current_map == "copay_orchard" and next_id == "sleet_hour":
		film_kind = "parachute"
		_hop("parachute_fall")
		return
	if current_map == "neon_exchange" and next_id == "waiting_room":
		film_kind = "skinwalker"
		_hop("skinwalker_film")
		return
	film_kind = "bridge"
	var hop := next_id
	var skip := bool(FamilyProfile.data.get("skip_films", false))
	if not skip and StoryBook.has_bridge(film_from, next_id):
		hop = "act_film"
	else:
		film_kind = ""
	_hop(hop)


func _hop(map_id: String) -> void:
	if has_node("/root/NetSession") and NetSession.active() and NetSession.is_host():
		NetSession.broadcast_begin(map_id, begin_extra())
		return
	enter_map(map_id)


func carry_to_fire_escapes(state: RunState) -> void:
	advance("fire_escapes", state)


func back_to_hub(tab: String = "clinic") -> void:
	pending_tab = tab
	run_bag = {}
	remote_coop = false
	versus = false
	film_from = ""
	film_next = ""
	film_kind = ""
	get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")


func is_solo_density() -> bool:
	return not density_coop


func two_bodies() -> bool:
	return couch or remote_coop or versus
