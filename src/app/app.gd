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
var run_bag: Dictionary = {}
var map_index: int = 0


func start_run() -> void:
	difficulty = str(FamilyProfile.data.get("difficulty", difficulty))
	density_coop = couch
	run_bag = {}
	map_index = 0
	last_run_ok = false
	get_tree().change_scene_to_file("res://scenes/levels/dock_street.tscn")


func carry_to_fire_escapes(state: RunState) -> void:
	run_bag = state.pack()
	map_index = 1
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/fire_escapes.tscn")


func back_to_hub(tab: String = "clinic") -> void:
	pending_tab = tab
	run_bag = {}
	get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")


func is_solo_density() -> bool:
	return not density_coop
