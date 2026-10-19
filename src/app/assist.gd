class_name Assist
extends RefCounted
## Learning aids drawn in the world (enemy attack-height marks, boss danger
## zones, the combo ring and chi meters at the feet) show only on the easy
## difficulty (OPEN HOUSE) and in the dojo. On NIGHT CLASS / FINALS you read
## the wind-up from the body, like a real fight.


static func hints() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var app := tree.root.get_node_or_null("App")
	if app != null and str(app.get("difficulty")) == "open_house":
		return true
	var cs := tree.current_scene
	return cs != null and cs.scene_file_path.contains("dojo")
