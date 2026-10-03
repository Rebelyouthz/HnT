class_name PixelIcon
extends Control

## Tiny drawn currency icons on a 11x11 pixel grid (scaled to the control):
## gold coin, blue gem, grey rep badge. Crisp at any UI scale.

@export var kind := "gold"
@export var dim := false

const COIN := [
	"...XXXXX...", "..XyyyyyX..", ".XyYYYYYyX.", "XyYYyyyYYyX", "XyYyYYYYYyX", "XyYyYYYYYyX",
	"XyYyYyyYYyX", "XyYYyyyYYyX", ".XyYYYYYyX.", "..XyyyyyX..", "...XXXXX...",
]
const GEM := [
	"...........", "..XXXXXXX..", ".XcCCcCCcX.", "XcCCCcCCCcX", "XXXXXXXXXXX", ".XcCCCCCcX.",
	"..XcCCCcX..", "...XcCcX...", "....XcX....", ".....X.....", "...........",
]
const REP := [
	"..XXXXXXX..", ".XgGGGGGgX.", "XgGGgggGGgX", "XgGgGGGgGgX", "XgGgGGGgGgX", "XgGGgggGGgX",
	"XgGGGGGGGgX", ".XgGGGGGgX.", "..XgGGGgX..", "...XgGgX...", "....XXX....",
]
const LOCK := [
	"...XXXXX...", "..XgggggX..", ".XgX...XgX.", ".XgX...XgX.", "XXXXXXXXXXX", "XyYYYYYYYyX",
	"XyYYyXyYYyX", "XyYYyXyYYyX", "XyYYYyYYYyX", "XyyyyyyyyyX", "XXXXXXXXXXX",
]
const GLYPHS := {
	"heart": [".RR...RR...", "RrrR.RrrR..", "RrrrRrrrR..", "RrrrrrrrR..", ".RrrrrrR...", "..RrrrR....", "...RrR.....", "....R......", "...........", "...........", "..........."],
	"drop": ["....C......", "...CcC.....", "...CcC.....", "..CccCC....", "..CcccC....", ".CcccccC...", ".CccWccC...", ".CccWccC...", "..CcccC....", "...CCC.....", "..........."],
	"cross": ["...........", "...RRRR....", "...RWWR....", ".RRRWWRRR..", ".RWWWWWWR..", ".RWWWWWWR..", ".RRRWWRRR..", "...RWWR....", "...RRRR....", "...........", "..........."],
	"shield": [".GGGGGGGG..", ".GgggggggG.", ".GgWgggggG.", ".GgWgggggG.", ".GgggggggG.", "..GgggggG..", "..GgggggG..", "...GgggG...", "....GgG....", ".....G.....", "..........."],
	"boot": ["..XXXX.....", "..XbbX.....", "..XbbX.....", "..XbbX.....", "..XbbXXX...", "..XbbbbbX..", "..XbbbbbbX.", ".XXXXXXXXX.", "...........", "...........", "..........."],
	"fist": ["...........", "..SSSSSS...", ".SsSsSsSS..", ".SsSsSsSsS.", ".SssssssS..", ".SssssssS..", "..SssssS...", "..SssssS...", "...SSSS....", "...........", "..........."],
	"star": [".....Y.....", "....YyY....", "....YyY....", "YYYYyyyYYYY", ".YyyyyyyyY.", "..YyyyyyY..", "..YyyYyyY..", ".YyyY.YyyY.", ".YyY...YyY.", ".YY.....YY.", "..........."],
	"bolt": ["......YY...", ".....YyY...", "....YyY....", "...YyY.....", "..YyyyyY...", ".....YyY...", "....YyY....", "...YyY.....", "..YyY......", "..YY.......", "..........."],
	"eye": ["...........", "...........", "...XXXXX...", ".XXWWWWWXX.", "XWWWcCcWWWX", "XWWWCXCWWWX", ".XXWcCcWXX.", "...XXXXX...", "...........", "...........", "..........."],
}
const COL := {
	"X": Color(0.12, 0.07, 0.03), "y": Color(0.75, 0.5, 0.1), "Y": Color(1.0, 0.82, 0.25),
	"c": Color(0.2, 0.45, 0.95), "C": Color(0.45, 0.8, 1.0),
	"g": Color(0.45, 0.47, 0.5), "G": Color(0.82, 0.84, 0.86),
	"R": Color(0.55, 0.08, 0.1), "r": Color(0.95, 0.25, 0.28), "W": Color(0.97, 0.95, 0.9),
	"b": Color(0.55, 0.36, 0.2), "S": Color(0.45, 0.25, 0.12), "s": Color(0.95, 0.72, 0.52),
}


func _draw() -> void:
	var grid: Array = COIN
	if kind.begins_with("gem"):
		grid = GEM
	elif kind.begins_with("rep"):
		grid = REP
	elif kind == "lock":
		grid = LOCK
	elif GLYPHS.has(kind):
		grid = GLYPHS[kind]
	var px := floorf(minf(size.x, size.y) / 11.0)
	var off := ((size - Vector2(px * 11.0, px * 11.0)) * 0.5).floor()
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if COL.has(ch):
				var c: Color = COL[ch]
				if dim:
					var l := c.get_luminance() * 0.55
					c = Color(l, l, l * 1.08, c.a)
				draw_rect(Rect2(off + Vector2(x, y) * px, Vector2(px, px)), c)
