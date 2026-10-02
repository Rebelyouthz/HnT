shader_type canvas_item;

// Painted backdrops come alive: neon (bright, saturated pink / cyan / teal)
// hums and now and then stutters, lit windows breathe a little, each sign
// on its own clock (hashed by position), with a soft glow added on top.

uniform float glow = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = mx - mn;
	float neon = smoothstep(0.35, 0.6, sat) * smoothstep(0.55, 0.85, mx);
	float warm = smoothstep(0.55, 0.8, c.r) * smoothstep(0.15, 0.4, c.r - c.b) * (1.0 - neon);
	vec2 cell = floor(UV * vec2(9.0, 5.0));
	float ph = hash(cell) * 40.0;
	float hum = 0.9 + 0.1 * sin(TIME * 7.0 + ph);
	float stutter = step(0.985, fract(sin(floor(TIME * 9.0 + ph) * 12.9898) * 43758.5)) ;
	float k = neon * (hum - stutter * 0.6);
	// Small glow: sample a ring around and add the bright neon around it.
	vec3 halo = vec3(0.0);
	vec2 px = TEXTURE_PIXEL_SIZE * 3.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785;
		vec4 s = texture(TEXTURE, UV + vec2(cos(a), sin(a)) * px);
		float sm = max(s.r, max(s.g, s.b));
		float ss = sm - min(s.r, min(s.g, s.b));
		halo += s.rgb * smoothstep(0.35, 0.6, ss) * smoothstep(0.55, 0.85, sm);
	}
	halo /= 8.0;
	vec3 rgb = c.rgb * (1.0 + 0.25 * k) + halo * glow * (hum - stutter * 0.6);
	rgb *= 1.0 + warm * 0.06 * sin(TIME * 1.3 + ph);
	COLOR = vec4(rgb, c.a) * vcol;
}
