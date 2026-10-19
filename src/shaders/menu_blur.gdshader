shader_type canvas_item;
// What's behind a menu, soft-focused.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float lod = 2.0;
void fragment() {
	COLOR = vec4(textureLod(screen_tex, SCREEN_UV, lod).rgb, 1.0);
}
