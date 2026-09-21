shader_type canvas_item;

uniform vec4 neon : source_color = vec4(0.95, 0.35, 0.55, 1.0);

void fragment() {
	float pulse = 0.72 + 0.28 * sin(TIME * 6.2);
	float flicker = step(0.04, fract(sin(TIME * 38.0) * 43758.0));
	COLOR = vec4(neon.rgb * pulse * flicker, neon.a);
}
