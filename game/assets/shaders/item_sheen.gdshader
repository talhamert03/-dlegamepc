shader_type canvas_item;
// Polished-metal reflection for epic and better item icons: a bright band sweeps diagonally across the
// painting every few seconds (only where the icon is opaque), with an optional soft rim glow around it.

uniform vec4 sheen_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float strength = 0.6;
uniform float speed = 0.3;
uniform float offset = 0.0;
uniform bool rainbow = false;
uniform vec4 glow_color : source_color = vec4(1.0, 0.7, 0.3, 0.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float t = fract(TIME * speed + offset);
	float pos = t * 3.2 - 0.9;                       // travels top-left -> bottom-right, then rests off-icon
	float d = (UV.x + UV.y) * 0.5 - pos;
	float band = exp(-d * d * 220.0) + 0.45 * exp(-(d - 0.08) * (d - 0.08) * 900.0);
	vec3 sc = sheen_color.rgb;
	if (rainbow) {
		sc = 0.6 + 0.4 * cos(6.2831 * (UV.x * 0.8 + UV.y * 0.6 + TIME * 0.35) + vec3(0.0, 2.1, 4.2));
	}
	c.rgb += sc * band * strength * c.a;
	// rim glow: light just outside the painted shape, breathing slowly
	if (glow_color.a > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE * 3.0;
		float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		float rim = clamp(n * 0.25 - c.a, 0.0, 1.0);
		float breath = 0.65 + 0.35 * sin(TIME * 2.2 + offset * 6.28);
		vec3 gc = rainbow ? sc : glow_color.rgb;
		float ga = rim * glow_color.a * breath * COLOR.a;
		c.rgb = mix(c.rgb, gc, ga / max(c.a + ga, 0.001));
		c.a = max(c.a, ga);
	}
	COLOR = c;
}
