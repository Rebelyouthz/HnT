extends Node

signal tab_wanted(tab: String)

var difficulty: String = "night_class"
var last_run_ok: bool = false
var pending_tab: String = "clinic"


func start_run() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/dock_street.tscn")


func back_to_hub(tab: String = "clinic") -> void:
	pending_tab = tab
	get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")
