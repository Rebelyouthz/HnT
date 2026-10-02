shader_type canvas_item;

// Damage on a character sprite, painted per texel so it stays pixel art:
//  wound  0..1  blood in the face: cuts, a split brow, a nose bleed that runs
//               down over the chin, bruising round the eyes. Grows with damage.
//  splat  0..1  spatter on the clothes, heavier on the side that took hits.
//  holes        bullet holes (local texels): dark core, wet rim, a run below.
// Works in the sprite's local texel space (VERTEX), so the marks stay on the
// body while the frames change. Multiplies the node modulate like normal.

uniform float wound : hint_range(0.0, 1.0) = 0.0;
uniform float splat : hint_range(0.0, 1.0) = 0.0;
uniform float side = 1.0;
uniform float seed = 0.0;
uniform vec3 head = vec3(0.0, -60.0, 14.0);  // centre x, centre y, radius
uniform vec2 holes[6];
uniform int hole_n = 0;
uniform vec4 blood : source_color = vec4(0.58, 0.03, 0.05, 1.0);

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

bool skin(vec3 c) {
	return c.r > c.g && c.g > c.b * 0.9 && (c.r - c.b) > 0.1 && c.r > 0.28;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 t = floor(lp);
	vec3 col = base.rgb;
	if (base.a > 0.5) {
		vec2 hv = (t - head.xy) / max(head.z, 1.0);
		float in_head = 1.0 - smoothstep(0.9, 1.25, length(hv * vec2(1.0, 0.85)));
		// Face: cuts and smears where the skin is.
		if (wound > 0.01 && in_head > 0.0) {
			float n = noise(t * 0.35) * 0.6 + noise(t * 0.9) * 0.4;
			float cut = step(0.92 - wound * 0.8, n) * in_head;
			// Nose / mouth bleed: a run down the face's lower half.
			float run = step(abs(t.x - head.x - head.z * 0.15 * side), 1.0 + wound * 1.5)
				* step(head.y, t.y) * step(t.y, head.y + head.z * (0.5 + wound * 1.8)) * step(0.18, wound);
			float bruise = smoothstep(0.3, 1.0, wound) * step(abs(hv.y + 0.15), 0.18) * in_head;
			float m = clamp(cut + run, 0.0, 1.0);
			if (skin(base.rgb) || run > 0.0) {
				col = mix(col, col * vec3(0.55, 0.42, 0.6), bruise * 0.6);
				col = mix(col, blood.rgb * (0.8 + 0.4 * hash(t)), m);
			}
		}
		// Clothes: spatter, denser on the struck side, and drips.
		if (splat > 0.01 && in_head < 0.5) {
			float lean = 0.5 + 0.5 * clamp((t.x - head.x) * side / 18.0, -1.0, 1.0);
			float s = noise(t * 0.55 + 13.0) * 0.7 + hash(t) * 0.3;
			float thr = 1.0 - splat * (0.3 + 0.4 * lean);
			if (s > thr) {
				col = mix(col, blood.rgb * 0.75, 0.85);
			}
		}
		// Bullet holes.
		for (int i = 0; i < 6; i++) {
			if (i >= hole_n) break;
			vec2 d = t - floor(holes[i]);
			float r = length(d);
			if (r < 1.5) {
				col = vec3(0.08, 0.0, 0.01);
			} else if (r < 3.0) {
				col = mix(col, blood.rgb * 0.7, 0.9);
			} else if (abs(d.x) < 1.0 && d.y > 0.0 && d.y < 6.0 + 10.0 * wound) {
				col = mix(col, blood.rgb * 0.8, 0.85);
			}
		}
	}
	COLOR = vec4(col, base.a) * COLOR;
}
