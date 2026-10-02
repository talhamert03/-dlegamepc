shader_type canvas_item;
// Hit flash, tint, elite/boss outline glow and dissolve-on-death for unit sprites.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 outline_color : source_color = vec4(0.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	if (outline_color.a > 0.0 && c.a < 0.5) {
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (a > 0.5) {
			float pulse = 0.75 + 0.25 * sin(TIME * 4.0 + time_offset);
			c = vec4(outline_color.rgb, outline_color.a * pulse);
		}
	}
	c.rgb *= tint.rgb;
	c.rgb = mix(c.rgb, vec3(1.0), flash * step(0.01, c.a));
	if (dissolve > 0.0) {
		float n = hash(UV / px);
		if (n < dissolve) {
			c.a = 0.0;
		} else if (n < dissolve + 0.08) {
			c.rgb = mix(c.rgb, vec3(1.0, 0.85, 0.5), 0.8);
		}
	}
	COLOR = c * vec4(1.0, 1.0, 1.0, tint.a);
}
