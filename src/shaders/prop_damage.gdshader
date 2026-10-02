shader_type canvas_item;

// Breaking a prop in stages, per texel so it stays pixel art. damage 0..1:
//  ~0.2  hairline cracks along cell seams, a few dents (shifted texels)
//  ~0.5  cracks open and darken, soot, chunks bitten out of the silhouette
//  ~0.8  big missing chunks, deep black fractures, the rest scorched
// Same props everywhere, so every breakable gets its stages for free.

uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float flash = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + 19.19));
}

// Distance to the nearest cell seam (Voronoi F2 - F1) and that cell's id.
vec3 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = i + g;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(d2 - d1, id);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 t = floor(UV / px);
	float scale = 1.0 / 22.0;
	vec3 c = cells(t * scale);
	float broken_cell = step(hash(c.yz), damage * 0.85);
	// Dents: a hit cell slides a texel.
	vec2 uv = UV;
	if (broken_cell > 0.0 && damage > 0.15) {
		uv += (hash2(c.yz) - 0.5) * px * 2.0 * damage;
	}
	vec4 base = texture(TEXTURE, uv);
	vec3 col = base.rgb;
	float a = base.a;
	// Cracks on the seams of broken cells, wider as it goes.
	float w = 0.03 + 0.08 * damage;
	if (c.x < w && (broken_cell > 0.0 || hash(c.yz + 3.0) < damage * 0.5)) {
		col = mix(col, vec3(0.04, 0.03, 0.04), 0.85);
	} else if (c.x < w * 2.0 && broken_cell > 0.0) {
		col *= 0.7;
	}
	// Soot and scuffs.
	float soot = smoothstep(0.25, 1.0, damage) * (0.4 + 0.6 * hash(floor(t / 3.0)));
	col = mix(col, col * vec3(0.45, 0.42, 0.42), soot * 0.6);
	// Chunks bitten out: near the silhouette edge, cells go missing.
	if (damage > 0.35 && a > 0.5) {
		float edge = 0.0;
		for (int k = 1; k <= 4; k++) {
			float s = float(k) * 3.0;
			edge += step(texture(TEXTURE, UV + vec2(px.x * s, 0.0)).a, 0.5);
			edge += step(texture(TEXTURE, UV - vec2(px.x * s, 0.0)).a, 0.5);
			edge += step(texture(TEXTURE, UV - vec2(0.0, px.y * s)).a, 0.5);
		}
		vec3 cc = cells(t * scale * 1.7 + 7.0);
		if (edge > 0.0 && hash(cc.yz) < (damage - 0.35) * 1.1) {
			a = 0.0;
		} else if (edge > 0.0 && cc.x < 0.08 && hash(cc.yz) < damage) {
			col = vec3(0.05, 0.04, 0.05);
		}
	}
	col = mix(col, vec3(1.0, 0.95, 0.85), flash);
	COLOR = vec4(col, a) * COLOR;
}
