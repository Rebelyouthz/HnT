class_name PadCompat
extends RefCounted

## Odd and new gamepads (iPega PG-9777 and friends).
##  1. A fresh copy of the community SDL GameControllerDB ships in
##     data/gamecontrollerdb.txt: every line for this OS is handed to Godot
##     at boot, so pads newer than the engine's built-in list map right.
##  2. A pad Godot still does not know that looks like an iPega (vendor
##     0x1949 in its GUID, or "ipega" / "PG-" in its name) gets the layout
##     the other iPega pads share, as a best guess.
##  3. Anything else - or a guess that is wrong - is fixed in OPTIONS ->
##     CONTROLS -> CONTROLLER SETUP: press each button once and the game
##     remembers that pad (PadRouter reads FamilyProfile.data["pad_maps"]).

## The layout the iPega PG-90xx pads share in the database (HID mode); the
## right stick sits on axes 3/4 on Windows, 2/3 elsewhere.
const IPEGA := "a:b0,b:b1,x:b3,y:b4,back:b10,start:b11,leftshoulder:b6,rightshoulder:b7,lefttrigger:b8,righttrigger:b9,leftstick:b13,rightstick:b14,leftx:a0,lefty:a1,%s,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8"

static var _loaded := false
static var guessed: Dictionary = {}


static func platform() -> String:
	match OS.get_name():
		"Windows":
			return "Windows"
		"macOS":
			return "Mac OS X"
		"Android":
			return "Android"
		"iOS":
			return "iOS"
	return "Linux"


## Feed this OS's lines of the shipped database to the engine (once).
static func load_db() -> int:
	if _loaded:
		return 0
	_loaded = true
	var f := FileAccess.open("res://data/gamecontrollerdb.txt", FileAccess.READ)
	if f == null:
		return 0
	var want := "platform:%s," % platform()
	var n := 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#") or not line.contains(want):
			continue
		Input.add_joy_mapping(line, true)
		n += 1
	return n


static func looks_ipega(device: int) -> bool:
	var guid := Input.get_joy_guid(device).to_lower()
	var name := Input.get_joy_name(device).to_lower()
	return guid.contains("49190000") or name.contains("ipega") or name.contains("pg-9") or name.contains("pg9")


## A pad the engine does not know: guess the iPega layout for it. Returns
## true when a guess was made (the pad is remapped on the spot).
static func guess(device: int) -> bool:
	if Input.is_joy_known(device) or not looks_ipega(device):
		return false
	var guid := Input.get_joy_guid(device)
	if guid == "" or guessed.has(guid):
		return false
	var rs := "rightx:a3,righty:a4" if platform() == "Windows" else "rightx:a2,righty:a3"
	var line := "%s,iPega (Father & Son guess),%s,platform:%s," % [guid, IPEGA % rs, platform()]
	Input.add_joy_mapping(line, true)
	guessed[guid] = true
	return true


## One line for the setup screen: name, known / guessed / unknown.
static func describe(device: int) -> String:
	var guid := Input.get_joy_guid(device)
	var state := "KNOWN" if Input.is_joy_known(device) else ("iPEGA GUESS" if guessed.has(guid) else "UNKNOWN - run CONTROLLER SETUP")
	return "PAD %d  ·  %s  ·  %s" % [device + 1, Input.get_joy_name(device), state]
