shader_type canvas_item;
// Light scanlines and a soft vignette over everything.
uniform float amount : hint_range(0.0, 1.0) = 0.4;
void fragment() {
	float line = 0.5 + 0.5 * sin(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y * 3.14159 / 3.0);
	vec2 c = SCREEN_UV - 0.5;
	float vig = smoothstep(0.85, 0.35, length(c * vec2(1.0, 1.25)));
	COLOR = vec4(0.0, 0.0, 0.02, amount * (0.22 * line + 0.55 * (1.0 - vig)));
}
