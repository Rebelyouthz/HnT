shader_type canvas_item;

uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform vec4 bruise : source_color = vec4(0.55, 0.12, 0.14, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = 0.85 + 0.15 * sin(TIME * (3.0 + hurt * 6.0));
	vec3 rgb = mix(tex.rgb, bruise.rgb, hurt * 0.55);
	rgb *= mix(1.0, pulse, hurt);
	COLOR = vec4(rgb, tex.a);
}
