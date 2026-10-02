class_name MoveBook
extends Object

## How every strike moves and feels, keyed by sprite clip.
##
## Timing comes from the sprite itself: a clip's JSON says its fps and the
## frame where the limb is fully extended ("hit"). The hitbox opens exactly on
## that frame, so what you see connect is what connects. Values here are the
## physical side: how far the body travels into the strike, how long feet stay
## planted, what a clean hit does (hitstop, shake, push-off, cancel window) and
## what a whiff costs (over-extension drift, slow retract, longer recovery).
##
## Stances carry one move into the next. Every strike ends in a body position
## (lead hand out, hips turned, low, rising, leg chambered...). The next strike
## started from that position skips the part of its wind-up the body already
## did, so a cross thrown off a jab comes out faster and looks like one motion,
## and the same button gives a different move from a different stance.

## startup_cap: longest wind-up allowed (s), whatever the art says.
## lunge: forward speed while winding up (u/s) - the step into the strike.
## plant: how much stick movement survives during the strike (0 = feet planted).
## stop: hitstop frames on a clean hit. shake: camera px on hit.
## push: attacker push-off on hit (u/s backwards) - you bounce off what you hit.
## hit_cd: attack_cd after a clean hit (cancel window opens early).
## whiff_drift: forward slide after a miss (overcommitted weight).
## whiff_cd: attack_cd after a miss. whiff_rate: retract speed on a miss.
## stance: body position the strike ends in. weight: 0 light .. 1 heavy.
const MOVES := {
	"jab": {"startup_cap": 0.12, "lunge": 70.0, "plant": 0.35, "stop": 3, "shake": 2.0, "push": 40.0, "hit_cd": 6, "whiff_drift": 30.0, "whiff_cd": 12, "whiff_rate": 0.85, "stance": "lead_out", "weight": 0.15},
	"cross": {"startup_cap": 0.15, "lunge": 110.0, "plant": 0.25, "stop": 4, "shake": 3.0, "push": 60.0, "hit_cd": 7, "whiff_drift": 70.0, "whiff_cd": 15, "whiff_rate": 0.75, "stance": "rear_out", "weight": 0.35},
	"gut": {"startup_cap": 0.16, "lunge": 90.0, "plant": 0.2, "stop": 5, "shake": 4.0, "push": 50.0, "hit_cd": 8, "whiff_drift": 50.0, "whiff_cd": 16, "whiff_rate": 0.75, "stance": "low", "weight": 0.45},
	"heavy": {"startup_cap": 0.3, "lunge": 160.0, "plant": 0.1, "stop": 8, "shake": 7.0, "push": 90.0, "hit_cd": 12, "whiff_drift": 130.0, "whiff_cd": 26, "whiff_rate": 0.6, "stance": "rear_out", "weight": 0.9},
	"uppercut": {"startup_cap": 0.18, "lunge": 60.0, "plant": 0.2, "stop": 7, "shake": 6.0, "push": 30.0, "hit_cd": 10, "whiff_drift": 40.0, "whiff_cd": 22, "whiff_rate": 0.65, "stance": "rising", "weight": 0.75},
	"front_kick": {"startup_cap": 0.18, "lunge": 80.0, "plant": 0.2, "stop": 5, "shake": 4.0, "push": 110.0, "hit_cd": 9, "whiff_drift": 60.0, "whiff_cd": 18, "whiff_rate": 0.7, "stance": "kick", "weight": 0.5},
	"side_kick": {"startup_cap": 0.2, "lunge": 120.0, "plant": 0.15, "stop": 6, "shake": 5.0, "push": 130.0, "hit_cd": 10, "whiff_drift": 90.0, "whiff_cd": 20, "whiff_rate": 0.65, "stance": "kick", "weight": 0.65},
	"roundhouse": {"startup_cap": 0.24, "lunge": 90.0, "plant": 0.1, "stop": 8, "shake": 7.0, "push": 70.0, "hit_cd": 12, "whiff_drift": 40.0, "whiff_cd": 26, "whiff_rate": 0.55, "stance": "spun", "weight": 0.85},
	"air_mix": {"startup_cap": 0.16, "lunge": 140.0, "plant": 1.0, "stop": 6, "shake": 5.0, "push": 0.0, "hit_cd": 8, "whiff_drift": 0.0, "whiff_cd": 16, "whiff_rate": 0.8, "stance": "air", "weight": 0.6},
	"snap": {"startup_cap": 0.22, "lunge": 60.0, "plant": 0.0, "stop": 10, "shake": 9.0, "push": 0.0, "hit_cd": 14, "whiff_drift": 30.0, "whiff_cd": 24, "whiff_rate": 0.7, "stance": "guard", "weight": 1.0},
	"slide": {"startup_cap": 0.08, "lunge": 0.0, "plant": 1.0, "stop": 3, "shake": 3.0, "push": 0.0, "hit_cd": 6, "whiff_drift": 0.0, "whiff_cd": 10, "whiff_rate": 1.0, "stance": "low", "weight": 0.4},
	"dive": {"startup_cap": 0.1, "lunge": 0.0, "plant": 1.0, "stop": 7, "shake": 7.0, "push": 0.0, "hit_cd": 8, "whiff_drift": 0.0, "whiff_cd": 14, "whiff_rate": 1.0, "stance": "air", "weight": 0.8},
	# Dojo finishers. plant 1.0 = the clip's own travel drives the body
	# (flips, flying knees); startup caps are generous so the art's wind-up
	# reads - these are the big moves.
	"jump_roundhouse": {"startup_cap": 0.42, "lunge": 0.0, "plant": 1.0, "stop": 9, "shake": 8.0, "push": 40.0, "hit_cd": 14, "whiff_drift": 0.0, "whiff_cd": 26, "whiff_rate": 0.8, "stance": "spun", "weight": 0.9},
	"backflip_kick": {"startup_cap": 0.3, "lunge": 0.0, "plant": 1.0, "stop": 9, "shake": 8.0, "push": 0.0, "hit_cd": 14, "whiff_drift": 0.0, "whiff_cd": 24, "whiff_rate": 0.85, "stance": "air", "weight": 0.85},
	"dropkick": {"startup_cap": 0.6, "lunge": 0.0, "plant": 1.0, "stop": 12, "shake": 10.0, "push": 0.0, "hit_cd": 20, "whiff_drift": 0.0, "whiff_cd": 30, "whiff_rate": 1.0, "stance": "low", "weight": 1.0},
	"flying_knee": {"startup_cap": 0.32, "lunge": 0.0, "plant": 1.0, "stop": 8, "shake": 7.0, "push": 30.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 22, "whiff_rate": 0.85, "stance": "rising", "weight": 0.75},
	"sweep": {"startup_cap": 0.3, "lunge": 0.0, "plant": 0.0, "stop": 7, "shake": 6.0, "push": 0.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 22, "whiff_rate": 0.85, "stance": "low", "weight": 0.7},
	"cartwheel_kick": {"startup_cap": 0.38, "lunge": 0.0, "plant": 1.0, "stop": 9, "shake": 8.0, "push": 20.0, "hit_cd": 14, "whiff_drift": 0.0, "whiff_cd": 24, "whiff_rate": 0.85, "stance": "kick", "weight": 0.85},
	"superman_punch": {"startup_cap": 0.3, "lunge": 0.0, "plant": 1.0, "stop": 8, "shake": 7.0, "push": 40.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 22, "whiff_rate": 0.85, "stance": "rear_out", "weight": 0.75},
	"elbow": {"startup_cap": 0.24, "lunge": 80.0, "plant": 0.2, "stop": 8, "shake": 7.0, "push": 50.0, "hit_cd": 12, "whiff_drift": 60.0, "whiff_cd": 22, "whiff_rate": 0.7, "stance": "spun", "weight": 0.8},
	"hammer": {"startup_cap": 0.4, "lunge": 30.0, "plant": 0.1, "stop": 12, "shake": 11.0, "push": 0.0, "hit_cd": 16, "whiff_drift": 20.0, "whiff_cd": 28, "whiff_rate": 0.65, "stance": "low", "weight": 1.0},
	"boot_kick": {"startup_cap": 0.32, "lunge": 60.0, "plant": 0.15, "stop": 11, "shake": 10.0, "push": 90.0, "hit_cd": 15, "whiff_drift": 40.0, "whiff_cd": 26, "whiff_rate": 0.65, "stance": "kick", "weight": 0.95},
	"shoulder_charge": {"startup_cap": 0.3, "lunge": 0.0, "plant": 1.0, "stop": 10, "shake": 9.0, "push": 0.0, "hit_cd": 14, "whiff_drift": 0.0, "whiff_cd": 24, "whiff_rate": 0.8, "stance": "run", "weight": 0.95},
	"body_hook": {"startup_cap": 0.3, "lunge": 70.0, "plant": 0.2, "stop": 9, "shake": 8.0, "push": 40.0, "hit_cd": 13, "whiff_drift": 50.0, "whiff_cd": 24, "whiff_rate": 0.7, "stance": "rear_out", "weight": 0.85},
	"spin_backfist": {"startup_cap": 0.34, "lunge": 40.0, "plant": 0.2, "stop": 10, "shake": 9.0, "push": 60.0, "hit_cd": 14, "whiff_drift": 40.0, "whiff_cd": 26, "whiff_rate": 0.6, "stance": "spun", "weight": 0.9},
	"headbutt": {"startup_cap": 0.3, "lunge": 50.0, "plant": 0.2, "stop": 10, "shake": 8.0, "push": 30.0, "hit_cd": 12, "whiff_drift": 30.0, "whiff_cd": 22, "whiff_rate": 0.75, "stance": "guard", "weight": 0.8},
	"clinch_knee": {"startup_cap": 0.32, "lunge": 50.0, "plant": 0.2, "stop": 9, "shake": 8.0, "push": 30.0, "hit_cd": 13, "whiff_drift": 30.0, "whiff_cd": 24, "whiff_rate": 0.75, "stance": "kick", "weight": 0.85},
	"stomp": {"startup_cap": 0.22, "lunge": 0.0, "plant": 0.0, "stop": 9, "shake": 8.0, "push": 0.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 18, "whiff_rate": 0.8, "stance": "low", "weight": 0.9},
	"getup_kick": {"startup_cap": 0.4, "lunge": 0.0, "plant": 0.0, "stop": 8, "shake": 7.0, "push": 30.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 20, "whiff_rate": 0.85, "stance": "kick", "weight": 0.8},
	"getup_upper": {"startup_cap": 0.45, "lunge": 0.0, "plant": 0.0, "stop": 9, "shake": 8.0, "push": 30.0, "hit_cd": 12, "whiff_drift": 0.0, "whiff_cd": 20, "whiff_rate": 0.85, "stance": "rising", "weight": 0.85},
}

const FALLBACK := {"startup_cap": 0.08, "lunge": 50.0, "plant": 0.4, "stop": 3, "shake": 2.0, "push": 30.0, "hit_cd": 7, "whiff_drift": 20.0, "whiff_cd": 12, "whiff_rate": 0.85, "stance": "guard", "weight": 0.3}

## How long a stance stays "live" for chaining after the strike ends (s).
## A clean hit keeps the body loaded longer than a whiff.
const STANCE_LIVE_HIT := 0.5
const STANCE_LIVE_WHIFF := 0.28

## Share of the next clip's wind-up the current stance has already done.
## e.g. after a jab (lead hand out, weight forward) a cross only needs the
## hip turn: 45% of its wind-up is skipped.
const ENTRY := {
	"lead_out": {"cross": 0.45, "gut": 0.3, "heavy": 0.25, "front_kick": 0.3, "side_kick": 0.2, "jab": 0.35},
	"rear_out": {"jab": 0.3, "gut": 0.45, "roundhouse": 0.4, "side_kick": 0.35, "heavy": 0.2},
	"low": {"uppercut": 0.6, "gut": 0.35, "heavy": 0.3, "jab": 0.2},
	"rising": {"jab": 0.25, "air_mix": 0.5, "front_kick": 0.3},
	"kick": {"side_kick": 0.4, "roundhouse": 0.35, "front_kick": 0.3, "jab": 0.25},
	"spun": {"heavy": 0.4, "cross": 0.35, "side_kick": 0.3},
	"run": {"cross": 0.35, "front_kick": 0.4, "side_kick": 0.3, "heavy": 0.3},
	"air": {"air_mix": 0.3},
}


static func move(clip: String) -> Dictionary:
	return MOVES.get(clip, FALLBACK) as Dictionary


static func entry_skip(stance: String, clip: String) -> float:
	var row: Dictionary = ENTRY.get(stance, {})
	return float(row.get(clip, 0.0))


## Stance-aware clip for a light/heavy press. The same button reads the body:
## low after a duck/gut punch -> rising uppercut; leg still chambered after a
## kick -> a second kick; sprinting -> a running cross with the whole body.
static func light_variant(stance: String, base: String) -> String:
	match stance:
		"low":
			return "uppercut" if base == "gut" else base
		"kick":
			return "front_kick" if base == "jab" else base
		"run":
			return "cross" if base == "jab" else base
	return base


static func heavy_variant(stance: String, base: String) -> String:
	if base != "heavy":
		return base
	match stance:
		"kick":
			return "side_kick"
		"low":
			return "uppercut"
		"run":
			return "front_kick"
	return base
