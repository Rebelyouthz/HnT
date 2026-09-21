shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.9, 0.85, 0.29, 1.0);
uniform float width : hint_range(0.0, 4.0) = 1.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * width;
	float a = tex.a;
	a = max(a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	a = max(a, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	vec4 edge = vec4(outline_color.rgb, a);
	COLOR = mix(edge, tex, tex.a);
}
