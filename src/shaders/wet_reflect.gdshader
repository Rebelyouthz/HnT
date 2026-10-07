shader_type canvas_item;
render_mode unshaded;

// Wet street: mirrors what is already on screen above the kerb line into
// the road, strong in puddles (wet_mask), a faint sheen elsewhere. Rain
// rings ripple the puddles; the reflection is snapped to chunky blocks so it
// stays pixel art. Unshaded so the night modulate does not dim it twice.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wet_mask : filter_nearest, repeat_enable;
uniform float mirror_y = 0.5;      // kerb line, screen uv
uniform vec2 uv_block = vec2(0.003, 0.0055); // one art texel in screen uv
uniform float sheen = 0.15;        // reflectivity of damp stone
uniform float pool = 0.38;        // reflectivity of a puddle
uniform float rain = 1.0;
uniform vec2 tex_size = vec2(331.0, 200.0);

varying vec2 world;

void vertex() {
	world = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 suv = (floor(SCREEN_UV / uv_block) + 0.5) * uv_block;
	float wet = texture(wet_mask, UV).r;
	// Rain rings: one drop per cell, each its own phase.
	vec2 cell = floor(world / vec2(26.0, 9.0));
	vec2 local = fract(world / vec2(26.0, 9.0)) - 0.5;
	float ph = fract(TIME * 0.9 + hash(cell));
	vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float r = length((local - off * 0.5) * vec2(1.0, 2.6));
	float ring = smoothstep(0.05, 0.0, abs(r - ph * 0.45)) * (1.0 - ph) * rain;
	float depth = clamp((suv.y - mirror_y) * 2.4, 0.0, 1.0);
	vec2 ruv = vec2(suv.x, mirror_y - (suv.y - mirror_y) * 1.15);
	// Ripple: puddles wobble, stone barely.
	ruv.x += sin(world.y * 0.9 + TIME * 3.0) * 0.0015 * (0.3 + wet) + ring * 0.004;
	ruv.y += sin(world.x * 0.35 + TIME * 2.1) * 0.0012 * wet;
	// Smear downwards like light on wet asphalt.
	vec3 refl = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		refl += textureLod(screen_tex, clamp(ruv + vec2(0.0, float(i) * 0.009 * (1.0 - wet * 0.5)), 0.001, 0.999), 0.5).rgb;
	}
	refl /= 5.0;
	// Bright things (lamps, neon) carry; dark walls barely show.
	float lum = dot(refl, vec3(0.3, 0.55, 0.15));
	refl *= 0.6 + lum * 1.1;
	float k = mix(sheen, pool, wet) * mix(1.0, 0.12, depth);
	vec3 col = refl + vec3(0.55, 0.7, 0.9) * ring * wet * 0.6;
	COLOR = vec4(col, clamp(k * (0.35 + lum * 1.2) + ring * wet * 0.5, 0.0, 0.92));
}
