class_name PixelStage
extends Object

## 640×360 logical, 3× to 1920×1080. Existing 1280×720 UI draws at 0.5.

const LOGICAL := Vector2i(640, 360)
const DESIGN := Vector2i(1280, 720)
const WINDOW := Vector2i(1920, 1080)
const INT_SCALE := 3


static func design_scale() -> float:
	return float(LOGICAL.x) / float(DESIGN.x)


static func apply_control(n: Control) -> void:
	n.set_anchors_preset(Control.PRESET_TOP_LEFT)
	n.anchor_left = 0.0
	n.anchor_top = 0.0
	n.anchor_right = 0.0
	n.anchor_bottom = 0.0
	n.offset_left = 0.0
	n.offset_top = 0.0
	n.offset_right = float(DESIGN.x)
	n.offset_bottom = float(DESIGN.y)
	n.position = Vector2.ZERO
	n.size = Vector2(DESIGN)
	n.scale = Vector2(design_scale(), design_scale())
	n.pivot_offset = Vector2.ZERO


static func attach_canvas(layer: CanvasLayer) -> Control:
	var root := Control.new()
	root.name = "DesignRoot"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.size = Vector2(DESIGN)
	root.scale = Vector2(design_scale(), design_scale())
	root.pivot_offset = Vector2.ZERO
	layer.add_child(root)
	return root


static func safe_design_margins() -> Vector4i:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return Vector4i(16, 8, 16, 20)
	var sx := float(DESIGN.x) / float(win.x)
	var sy := float(DESIGN.y) / float(win.y)
	var left := int(round(float(safe.position.x) * sx))
	var top := int(round(float(safe.position.y) * sy))
	var right := int(round(float(win.x - safe.end.x) * sx))
	var bottom := int(round(float(win.y - safe.end.y) * sy))
	return Vector4i(maxi(16, left), maxi(8, top), maxi(16, right), maxi(20, bottom))
