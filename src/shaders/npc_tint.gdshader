shader_type canvas_item;

// Street-person recolour of a shared body sheet: rotates the hue of every
// coloured texel and lifts darks toward a coat colour, so a quest giver never
// reads as one of the thugs drawn on the same sheet.
uniform float hue = 0.3;          // turns of the colour wheel
uniform vec3 coat = vec3(0.45, 0.32, 0.2);
uniform float coat_mix = 0.55;

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 h = rgb2hsv(t.rgb);
	// Skin stays skin.
	bool skin = t.r > t.g && t.g > t.b * 0.9 && (t.r - t.b) > 0.12 && t.r > 0.35 && h.y < 0.6;
	vec3 col = t.rgb;
	if (!skin) {
		if (h.y > 0.18) {
			h.x = fract(h.x + hue);
			col = hsv2rgb(h);
		} else if (h.z < 0.35) {
			col = mix(col, coat * (0.4 + h.z * 1.6), coat_mix);
		}
	}
	COLOR = vec4(col, t.a) * vcol;
}
