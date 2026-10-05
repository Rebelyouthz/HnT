class_name GearIcon
extends Control

## A pixel-art picture of a gear piece: a shirt, cap or sneaker silhouette
## drawn in the item's own colour with shading, so the locker shows things,
## not just names. Empty slots draw a faint outline.

var slot := "clothes"
var tint := Color(0.6, 0.6, 0.65)
var empty := false

const SHAPES := {
	"clothes": [
		"..XX....XX..",
		".XXXX..XXXX.",
		"XXXXXXXXXXXX",
		"XXXXXXXXXXXX",
		"XX.XXXXXX.XX",
		"...XXXXXX...",
		"...XXXXXX...",
		"...XXXXXX...",
		"...XXXXXX...",
		"...XXXXXX...",
	],
	"hat": [
		"............",
		"....XXXX....",
		"...XXXXXX...",
		"..XXXXXXXX..",
		"..XXXXXXXX..",
		"..XXXXXXXX..",
		".XXXXXXXXXXX",
		"XXXXXXXXXXXX",
		"............",
		"............",
	],
	"shoes": [
		"............",
		"............",
		"............",
		"XXXX........",
		"XXXX........",
		"XXXXX.......",
		"XXXXXXXXX...",
		"XXXXXXXXXXX.",
		"XXXXXXXXXXXX",
		"WWWWWWWWWWWW",
	],
	"charm": [
		"....XXXX....",
		"...X....X...",
		"....XXXX....",
		"...XXXXXX...",
		"..XXXXXXXX..",
		"..XXXXXXXX..",
		"..XXXXXXXX..",
		"...XXXXXX...",
		"....XXXX....",
		"............",
	],
}


func _draw() -> void:
	# A lit plate behind the piece so dark clothes still read.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.22, 0.3, 0.55))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.48, 0.6, 0.6), false, 1.0)
	var grid: Array = SHAPES.get(slot, SHAPES["clothes"])
	var px := floorf(minf(size.x / 12.0, size.y / 10.0))
	var off := ((size - Vector2(12, 10) * px) * 0.5).floor()
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var c := tint
			if ch == "W":
				c = Color(0.92, 0.92, 0.9)
			# Light from the top left: a highlight edge and a darker bottom.
			var lit := 1.0 + 0.25 * (1.0 - float(y) / 9.0) - 0.15 * float(x) / 11.0
			c = Color(c.r * lit, c.g * lit, c.b * lit)
			if empty:
				c = Color(1, 1, 1, 0.12)
			draw_rect(Rect2(off + Vector2(x, y) * px, Vector2(px, px)), c)
