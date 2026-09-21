shader_type canvas_item;

uniform vec4 base_col : source_color = vec4(0.18, 0.2, 0.28, 0.42);

void fragment() {
	float w = 0.5 + 0.5 * sin(UV.x * 34.0 + TIME * 1.5);
	vec3 rgb = base_col.rgb * (0.82 + 0.22 * w);
	COLOR = vec4(rgb, base_col.a);
}
