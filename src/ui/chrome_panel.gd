class_name ChromePanel
extends ColorRect

## Metallic 3D-feeling menu juice. Shader, not a second World2D.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := load("res://src/shaders/chrome.gdshader") as Shader
	if sh == null:
		color = Palette.EDGE
		return
	var mat := ShaderMaterial.new()
	mat.shader = sh
	material = mat
	color = Color(1, 1, 1, 1)
