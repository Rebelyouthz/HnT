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
uniform float tear : hint_range(0.0, 1.0) = 0.0;  // ripped clothes (bosses)
uniform int suit = 0;  // 1 bat, 2 spider, 3 shaolin, 4 ninja (either fighter)
uniform float seed = 0.0;
uniform vec3 head = vec3(0.0, -60.0, 14.0);  // centre x, centre y, radius
uniform vec2 holes[6];
uniform int hole_n = 0;
uniform vec4 blood : source_color = vec4(0.58, 0.03, 0.05, 1.0);
// Dismemberment (guns). Body landmarks come from the head circle: the body
// is ~11.8 head radii tall, hips at +6 r below the head centre.
uniform float cut_head = 0.0;   // 1: head gone above the neck
uniform float cut_leg = 0.0;    // +1 / -1: the leg on that side gone below the hip
uniform vec3 gape = vec3(0.0, 0.0, 0.0); // see-through hole: x, y, radius
uniform int only = 0;           // 1: draw only the head, 2: only the cut leg (flying pieces)

varying vec2 lp;
// The node's modulate only (COLOR in fragment already holds the texel).
varying vec4 vcol;

void vertex() {
	lp = VERTEX;
	vcol = COLOR;
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

// Suits recolour the clothes by brightness so folds and shading survive.
vec3 suit_col(vec3 c, vec2 t, vec2 hv, float in_head) {
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	float shade = 0.55 + 0.9 * l;
	float yrel = hv.y;
	if (suit == 1) {
		vec3 cloth = mix(vec3(0.07, 0.07, 0.1), vec3(0.24, 0.25, 0.31), smoothstep(0.1, 0.7, l));
		vec3 o = cloth;
		// Cowl over the head, the jaw stays bare.
		if (in_head > 0.5 && skin(c) && yrel > 0.2) {
			o = c;
		}
		// Ears of the cowl.
		if (abs(abs(hv.x - 0.1) - 0.45) < 0.12 && yrel < -0.85 && yrel > -1.5) {
			o = vec3(0.07, 0.07, 0.1);
		}
		// White eye slits.
		if (in_head > 0.5 && abs(yrel + 0.12) < 0.1 && hv.x > 0.15 && hv.x < 0.7) {
			o = vec3(0.92, 0.94, 1.0);
		}
		// Utility belt.
		if (in_head < 0.5 && abs(yrel - 5.0) < 0.3) {
			o = vec3(0.86, 0.68, 0.16) * shade;
		}
		// Chest emblem: a yellow oval with a black bat.
		vec2 e = vec2((hv.x - 0.15) / 0.9, (yrel - 2.6) / 0.42);
		if (length(e) < 1.0 && in_head < 0.5) {
			o = vec3(0.95, 0.8, 0.2);
			float wing = abs(e.x);
			if (wing < 0.85 && abs(e.y + 0.1 * sin(wing * 9.0)) < 0.35 - wing * 0.25) {
				o = vec3(0.05, 0.05, 0.07);
			}
		}
		return o;
	}
	if (suit == 3) {
		// Shaolin: saffron robe, deep red sash and wraps, shaved head,
		// wooden prayer beads.
		vec3 o = mix(vec3(0.62, 0.28, 0.04), vec3(0.98, 0.62, 0.16), smoothstep(0.08, 0.75, l));
		if (in_head > 0.5) {
			// Face stays; hair becomes a shaved scalp.
			o = skin(c) ? c : (yrel < 0.25 ? vec3(0.78, 0.56, 0.42) * shade : c);
		}
		if (in_head < 0.5 && abs(yrel - 4.9) < 0.38) {
			o = vec3(0.52, 0.07, 0.06) * shade;
		}
		if (in_head < 0.5 && yrel > 7.6) {
			o = vec3(0.45, 0.08, 0.06) * shade;
		}
		// Beads around the neck.
		if (in_head < 0.5 && abs(yrel - 1.35) < 0.18 && abs(hv.x - 0.1) < 0.9 && fract((hv.x + 2.0) * 4.0) < 0.6) {
			o = vec3(0.32, 0.16, 0.06);
		}
		return o;
	}
	if (suit == 4) {
		// Ninja: charcoal gi and hood, an eye slit, red headband and sash.
		vec3 o = mix(vec3(0.04, 0.04, 0.06), vec3(0.2, 0.2, 0.25), smoothstep(0.1, 0.8, l));
		// Eye slit: the same band the bat cowl's eyes use, skin shows through.
		if (in_head > 0.5 && abs(yrel + 0.12) < 0.13 && hv.x > 0.12 && hv.x < 0.8) {
			o = skin(c) ? c * 1.1 : vec3(0.85, 0.66, 0.52) * shade;
		}
		if (in_head > 0.5 && abs(yrel + 0.62) < 0.13) {
			o = vec3(0.72, 0.06, 0.08) * shade;
		}
		// Headband tails behind the head.
		if (in_head > 0.5 && hv.x < -0.6 && hv.x > -1.4 && abs(yrel + 0.5 + (hv.x + 0.6) * 0.4) < 0.1) {
			o = vec3(0.72, 0.06, 0.08) * shade;
		}
		if (in_head < 0.5 && abs(yrel - 4.9) < 0.3) {
			o = vec3(0.72, 0.06, 0.08) * shade;
		}
		return o;
	}
	// Spider suit: red over head, chest and arms, blue legs and flanks,
	// a black web over the red, big white lenses.
	vec3 red = vec3(0.78, 0.08, 0.1) * shade;
	vec3 blue = vec3(0.1, 0.2, 0.62) * shade;
	vec3 o = yrel > 5.2 ? blue : red;
	if (yrel > 1.6 && yrel < 5.2 && abs(hv.x - 0.1) > 1.15) {
		o = blue;
	}
	if (o == red) {
		vec2 cw = vec2(hv.x - 0.1, yrel - (in_head > 0.5 ? 0.0 : 2.3));
		float ang = atan(cw.y, cw.x);
		float spoke = abs(fract(ang / 6.2832 * 10.0 + 0.5) - 0.5);
		float ring = abs(fract(length(cw) / 0.55) - 0.5);
		if (spoke < 0.04 || ring < 0.06) {
			o = vec3(0.12, 0.02, 0.03);
		}
	}
	if (in_head > 0.5) {
		vec2 lens = (hv - vec2(0.42, -0.12)) / vec2(0.26, 0.2);
		if (length(lens) < 1.0) {
			o = length(lens) > 0.78 ? vec3(0.03, 0.02, 0.04) : vec3(0.95, 0.96, 1.0);
		}
	}
	// Spider on the chest.
	vec2 sp = vec2((hv.x - 0.15) / 0.3, (yrel - 2.5) / 0.4);
	if (length(sp) < 1.0 && in_head < 0.5) {
		o = vec3(0.04, 0.02, 0.03);
	}
	return o;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 t = floor(lp);
	vec3 col = base.rgb;
	float r0 = max(head.z, 1.0);
	float neck = head.y + r0 * 1.15;
	float hip = head.y + r0 * 6.0;
	bool is_head = t.y < neck && abs(t.x - head.x) < r0 * 2.4;
	bool is_leg = cut_leg != 0.0 && t.y > hip && (t.x - head.x) * cut_leg > -r0 * 1.2;
	if (only == 1 && !is_head) { base.a = 0.0; }
	if (only == 2 && !(t.y > hip && (t.x - head.x) * (cut_leg == 0.0 ? 1.0 : cut_leg) > -r0 * 1.2)) { base.a = 0.0; }
	if (only == 0) {
		if (cut_head > 0.5 && is_head) { base.a = 0.0; }
		if (is_leg) { base.a = 0.0; }
		if (gape.z > 0.0 && distance(t, gape.xy) < gape.z) { base.a = 0.0; }
	}
	if (base.a > 0.5) {
		vec2 hv = (t - head.xy) / max(head.z, 1.0);
		float in_head = 1.0 - smoothstep(0.9, 1.25, length(hv * vec2(1.0, 0.85)));
		if (suit > 0) {
			col = suit_col(base.rgb, t, hv, in_head);
		}
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
		// Torn clothes: rips that show bruised skin and scratches.
		if (tear > 0.01 && in_head < 0.3) {
			float r = noise(t * vec2(0.12, 0.4) + 41.0);
			if (r > 1.0 - tear * 0.6) {
				col = mix(vec3(0.62, 0.4, 0.32), vec3(0.42, 0.12, 0.12), step(0.5, hash(t)) * 0.6);
			} else if (r > 1.0 - tear * 0.68) {
				col = vec3(0.06, 0.03, 0.04);
			}
		}
		// Stumps and the hole rim: meat, a white fleck of bone.
		if (only == 0 && cut_head > 0.5 && t.y >= neck && t.y < neck + 3.0 && abs(t.x - head.x) < r0 * 1.2) {
			col = mix(blood.rgb * 0.55, vec3(0.92, 0.86, 0.78), step(0.86, hash(t * 1.7)));
		}
		if (only == 0 && cut_leg != 0.0 && t.y > hip - 3.0 && t.y <= hip && (t.x - head.x) * cut_leg > -r0 * 1.2) {
			col = mix(blood.rgb * 0.6, vec3(0.92, 0.86, 0.78), step(0.85, hash(t * 2.3)));
		}
		if (only == 2 && t.y > hip && t.y < hip + 3.0) {
			col = mix(blood.rgb * 0.6, vec3(0.92, 0.86, 0.78), step(0.8, hash(t * 2.3)));
		}
		if (only == 1 && t.y > neck - 3.0) {
			col = mix(blood.rgb * 0.5, vec3(0.9, 0.84, 0.76), step(0.85, hash(t * 1.3)));
		}
		if (only == 0 && gape.z > 0.0) {
			float dg = distance(t, gape.xy);
			if (dg < gape.z + 3.0) {
				col = mix(blood.rgb * (0.45 + 0.4 * hash(t)), vec3(0.9, 0.8, 0.75), step(0.9, hash(t * 3.1)));
			} else if (dg < gape.z + 6.0) {
				col = mix(col, blood.rgb * 0.7, 0.8);
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
	COLOR = vec4(col, base.a) * vcol;
}
