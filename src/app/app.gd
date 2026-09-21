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
var run_bag: Dictionary = {}
var map_index: int = 0
var current_map: String = "dock_street"

const SCENES := {
	"dock_street": "res://scenes/levels/dock_street.tscn",
	"fire_escapes": "res://scenes/levels/fire_escapes.tscn",
	"neon_exchange": "res://scenes/levels/neon_exchange.tscn",
	"rail_bridge": "res://scenes/levels/rail_bridge.tscn",
	"city_hall": "res://scenes/levels/city_hall.tscn"
}

const ORDER := ["dock_street", "fire_escapes", "neon_exchange", "rail_bridge", "city_hall"]


func start_run() -> void:
	difficulty = str(FamilyProfile.data.get("difficulty", difficulty))
	density_coop = couch or remote_coop
	run_bag = {}
	map_index = 0
	current_map = "dock_street"
	last_run_ok = false
	enter_map("dock_street")


func enter_map(map_id: String) -> void:
	current_map = map_id
	var i := ORDER.find(map_id)
	map_index = i if i >= 0 else map_index
	var path := str(SCENES.get(map_id, SCENES["dock_street"]))
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func advance(next_id: String, state: RunState) -> void:
	run_bag = state.pack()
	get_tree().paused = false
	if has_node("/root/NetSession") and NetSession.active():
		NetSession.broadcast_begin(next_id)
	enter_map(next_id)


func carry_to_fire_escapes(state: RunState) -> void:
	advance("fire_escapes", state)


func back_to_hub(tab: String = "clinic") -> void:
	pending_tab = tab
	run_bag = {}
	remote_coop = false
	get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")


func is_solo_density() -> bool:
	return not density_coop


func two_bodies() -> bool:
	return couch or remote_coop
