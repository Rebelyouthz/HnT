shader_type canvas_item;

uniform vec4 base_col : source_color = vec4(0.16, 0.18, 0.26, 0.55);
uniform vec4 spec_col : source_color = vec4(0.55, 0.7, 0.92, 0.35);

void fragment() {
	float wave = 0.5 + 0.5 * sin(UV.x * 42.0 + TIME * 1.15);
	float spec = smoothstep(0.62, 0.85, wave) * (0.55 + 0.45 * sin(TIME * 0.7 + UV.x * 8.0));
	vec3 rgb = mix(base_col.rgb, spec_col.rgb, spec * 0.55);
	rgb *= 0.78 + 0.22 * wave;
	COLOR = vec4(rgb, mix(base_col.a, spec_col.a, spec * 0.4));
}
