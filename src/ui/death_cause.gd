class_name DeathCause
extends RefCounted

## How you died, in one line for the death screen: who did it and with what.

static func line(who: String, kind: String) -> String:
	var name := who.to_upper() if who != "" else "THE NIGHT"
	match kind:
		"fall":
			return "FELL TO THE STREET. SMASHED LIKE A TOMATO."
		"bullet":
			return "GOT SHOT WITH A 9MM BY %s" % name
		"blade":
			return "OPENED UP BY %s'S KNIFE" % name
		"heavy":
			return "FLATTENED BY %s'S HAYMAKER" % name
		"throw":
			return "THROWN INTO THE CURB BY %s" % name
		"snap", "special":
			return "FOLDED IN HALF BY %s" % name
		"barrel", "boom":
			return "BLOWN ACROSS DOCK STREET"
		"light":
			return "BEATEN DOWN BY %s" % name
	return "KILLED BY %s" % name


## The line for a whole run: the last fighter to drop names the killer.
static func for_run(tree: SceneTree) -> String:
	var best: Fighter = null
	for n in tree.get_nodes_in_group("players"):
		if n is Fighter and (n as Fighter).last_hit_kind != "":
			best = n
	if best == null:
		return ""
	return line(best.last_hit_by, best.last_hit_kind)
