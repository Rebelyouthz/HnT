shader_type canvas_item;

uniform vec4 metal : source_color = vec4(0.72, 0.62, 0.28, 1.0);
uniform vec4 dark : source_color = vec4(0.12, 0.11, 0.08, 1.0);

void fragment() {
	float band = 0.5 + 0.5 * sin((UV.x + UV.y) * 18.0 + TIME * 1.6);
	float edge = smoothstep(0.08, 0.0, min(min(UV.x, UV.y), min(1.0 - UV.x, 1.0 - UV.y)));
	vec3 rgb = mix(dark.rgb, metal.rgb, band * 0.72 + 0.18);
	rgb += vec3(0.35, 0.32, 0.18) * edge;
	COLOR = vec4(rgb, 0.92);
}
