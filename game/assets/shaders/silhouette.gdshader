shader_type canvas_item;
// Flat-colour silhouette that keeps the sprite's alpha (bestiary entries not yet discovered).
uniform vec4 tint : source_color = vec4(0.30, 0.31, 0.40, 0.9);

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);
}
