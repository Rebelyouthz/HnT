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

const SCENES := {
	"intro_flow": "res://scenes/levels/intro_flow.tscn",
	"tutorial_alley": "res://scenes/levels/tutorial_alley.tscn",
	"dock_street": "res://scenes/levels/dock_street.tscn",
	"intake_lot": "res://scenes/levels/intake_lot.tscn",
	"fire_escapes": "res://scenes/levels/fire_escapes.tscn",
	"group_circle": "res://scenes/levels/group_circle.tscn",
	"neon_exchange": "res://scenes/levels/neon_exchange.tscn",
	"waiting_room": "res://scenes/levels/waiting_room.tscn",
	"rail_bridge": "res://scenes/levels/rail_bridge.tscn",
	"city_hall": "res://scenes/levels/city_hall.tscn",
	"invoice_pier": "res://scenes/levels/invoice_pier.tscn",
	"versus": "res://scenes/levels/versus.tscn"
}

const ORDER := [
	"dock_street", "intake_lot", "fire_escapes", "group_circle",
	"neon_exchange", "waiting_room", "rail_bridge", "city_hall", "invoice_pier"
]


func start_run() -> void:
	versus = false
	difficulty = str(FamilyProfile.data.get("difficulty", difficulty))
	density_coop = couch or remote_coop
	run_bag = {}
	map_index = 0
	current_map = "dock_street"
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
	versus = false
	get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")


func is_solo_density() -> bool:
	return not density_coop


func two_bodies() -> bool:
	return couch or remote_coop or versus
