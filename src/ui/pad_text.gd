class_name PadText
extends RefCounted

## Xbox buttons in a line of prompt text: "HOLD LB + X" becomes coloured
## chips the way the pad prints them (A green, B red, X blue, Y yellow,
## shoulders and triggers dark with white letters, sticks as LS / RS).
## BBCode for a RichTextLabel; plain words around them stay as they are.

const FACE := {
	"A": Color(0.33, 0.72, 0.22), "B": Color(0.86, 0.22, 0.2),
	"X": Color(0.2, 0.47, 0.92), "Y": Color(0.95, 0.74, 0.12),
}
const DARK := ["LB", "RB", "LT", "RT", "LS", "RS", "L3", "R3", "MENU", "VIEW"]
const _RX := "(?<![A-Z0-9])(LB|RB|LT|RT|LS|RS|L3|R3|A|B|X|Y)(?![A-Z0-9])"

static var _re: RegEx


static func bb(text: String) -> String:
	if _re == null:
		_re = RegEx.new()
		_re.compile(_RX)
	var out := ""
	var at := 0
	for m in _re.search_all(text):
		out += text.substr(at, m.get_start() - at)
		out += chip(m.get_string(1))
		at = m.get_end()
	return out + text.substr(at)


static func chip(btn: String) -> String:
	if FACE.has(btn):
		var c: Color = FACE[btn]
		var ink := "#1b1406" if btn == "Y" else "#ffffff"
		return "[bgcolor=#%s][color=%s] %s [/color][/bgcolor]" % [c.to_html(false), ink, btn]
	return "[bgcolor=#2a2c33][color=#f2f2f2] %s [/color][/bgcolor]" % btn


## A centred RichTextLabel for one prompt line.
static func label(text: String, w: float, size: int) -> RichTextLabel:
	var r := UiKit.rich("", w, size, Palette.TEXT)
	set_text(r, text)
	return r


static func set_text(r: RichTextLabel, text: String) -> void:
	r.text = "[center]" + bb(text) + "[/center]"
