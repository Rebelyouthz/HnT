class_name SurviveAct
extends RunAct

## Timed horde hour between brawl acts. Same kits. Solo thinner. Co-op denser.

var duration := 88.0
var _horde: Horde


func _ready() -> void:
	music = "res://assets/audio/music_survive.wav"
	win_mode = "boss"
	super._ready()
	_horde = Horde.new()
	_horde.duration = duration
	_horde.map_w = map_w
	_horde.elite_pack.connect(func() -> void:
		_spawn_story_unit(true)
	)
	_horde.boss_time.connect(func() -> void:
		_spawn_story_unit(false)
	)
	add_child(_horde)
	add_child(SurviveHud.new())
	# Clearing the hour: drop one item down the well for the next ones.
	_state.run_cleared.connect(func() -> void:
		var run := SurviveRun.get_run(get_tree())
		if run:
			run.call_deferred("well")
	)
