class_name GearIcon
extends Control

## A pixel-art picture of a gear piece: a shirt, cap or sneaker silhouette
## drawn in the item's own colour with shading, so the locker shows things,
## not just names. Empty slots draw a faint outline.

var slot := "clothes"
var tint := Color(0.6, 0.6, 0.65)
var empty := false
## When set and the item has painted art (assets/sprites/gear/<id>.png) that
## picture is shown instead of the silhouette.
var item_id := ""
var _tex: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var p := "res://assets/sprites/gear/%s.png" % item_id
	if item_id != "" and ResourceLoader.exists(p):
		_tex = load(p)

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
	if _tex and not empty:
		# A lighter spot behind painted art so black cloth still reads.
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.42, Color(0.42, 0.44, 0.56, 0.55))
		# Whole-number scale so the pixels stay square.
		var k := maxf(1.0, floorf(minf(size.x, size.y) / float(_tex.get_height())))
		if float(_tex.get_height()) * k > minf(size.x, size.y):
			k = minf(size.x, size.y) / float(_tex.get_height())
		var ts := Vector2(_tex.get_width(), _tex.get_height()) * k
		draw_texture_rect(_tex, Rect2(((size - ts) * 0.5).floor(), ts), false)
		return
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
