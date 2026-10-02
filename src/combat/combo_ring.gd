class_name ComboRing
extends Node2D

## The beat of a combo, drawn on the fighter. When a chain step connects, a
## ring starts wide round the body and closes; the moment it meets the inner
## mark is PERFECT (it flashes gold), then it thins out until the window is
## gone. Each press leaves a small tick (gold perfect, white good), and a
## finished combo bursts. In the dojo the next input is written under it.

var fighter: Fighter
var show_next := false
var _flash := 0.0
var _flash_col := Color.WHITE
var _burst := 0.0
var _burst_gold := false
var _next_text := ""
var _font: Font


func _ready() -> void:
	z_index = 20
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	_font = UiKit.title_font()


func pressed(grade: String) -> void:
	if grade == "":
		return
	_flash = 0.22
	_flash_col = UiKit.GOLD if grade == "perfect" else Color(0.9, 0.95, 1.0)


func finished(perfect: bool) -> void:
	_burst = 0.35
	_burst_gold = perfect


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
	if _burst > 0.0:
		_burst -= delta
	_next_text = ""
	if show_next and fighter != null and fighter._combo != null:
		var lv: Array = fighter._combo.live(ComboBook.learned(fighter.role))
		var pad := PadRouter.last_kind == "pad"
		var bits: PackedStringArray = []
		for row: Dictionary in lv:
			var c: Dictionary = row["combo"]
			var steps: Array = c["steps"]
			var i := int(row["next"])
			if i < steps.size():
				var lab := ComboBook.step_label(str(steps[i]), pad)
				if not bits.has(lab):
					bits.append(lab)
		_next_text = "  /  ".join(bits)
	queue_redraw()


func _ring_phase() -> float:
	if fighter == null or fighter._combo == null:
		return -1.0
	var cb: ComboBook = fighter._combo
	if cb.hist.is_empty() or cb.ring_t < 0.0:
		return -1.0
	var dt := fighter._clock - cb.ring_t
	if dt > ComboBook.WINDOW:
		return -1.0
	return dt


func _draw() -> void:
	if fighter == null:
		return
	var c := Vector2(0.0, -40.0 + fighter.hop)
	var dt := _ring_phase()
	if dt >= 0.0:
		var inner := 13.0
		var k := clampf(dt / ComboBook.PERFECT_AT, 0.0, 1.0)
		var r := lerpf(34.0, inner, k)
		var in_perfect := absf(dt - ComboBook.PERFECT_AT) <= ComboBook.PERFECT_TOL
		var fade := 1.0 - clampf((dt - ComboBook.PERFECT_AT) / (ComboBook.WINDOW - ComboBook.PERFECT_AT), 0.0, 1.0)
		var col := UiKit.GOLD if in_perfect else Color(0.85, 0.92, 1.0)
		draw_arc(c, inner, 0.0, TAU, 32, Color(1.0, 0.85, 0.35, 0.35 * fade), 1.0)
		draw_arc(c, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.9 * fade), 2.4 if in_perfect else 1.6)
	if _flash > 0.0:
		var a := _flash / 0.22
		draw_arc(c, 13.0 + (1.0 - a) * 10.0, 0.0, TAU, 32, Color(_flash_col.r, _flash_col.g, _flash_col.b, a), 2.0)
	if _burst > 0.0:
		var b := _burst / 0.35
		var bc := UiKit.GOLD if _burst_gold else Color(1.0, 0.55, 0.3)
		for i in 10:
			var ang := TAU * float(i) / 10.0
			var r0 := 14.0 + (1.0 - b) * 26.0
			draw_line(c + Vector2(cos(ang), sin(ang)) * r0, c + Vector2(cos(ang), sin(ang)) * (r0 + 8.0 * b), Color(bc.r, bc.g, bc.b, b), 2.0)
	if _next_text != "" and _font != null:
		# Child of the fighter, not of the flipped visual: text reads right.
		var fs := 9
		var w := _font.get_string_size(_next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := c + Vector2(-w * 0.5, 34.0)
		draw_string_outline(_font, p, _next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, UiKit.INK)
		draw_string(_font, p, _next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.GOLD)
