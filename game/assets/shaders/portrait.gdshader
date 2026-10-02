shader_type canvas_item;
// Portrait costume recolor.
#include "res://assets/shaders/recolor.gdshaderinc"

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = apply_recolor(c.rgb);
	COLOR = c;
}
