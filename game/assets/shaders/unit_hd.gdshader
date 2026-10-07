shader_type canvas_item;
// "Living illustration" for monsters that only have one painted HD image: the picture is laid on a grid
// mesh and every vertex is moved by height and side, like a light 2D rig. The upper body lags behind the
// feet, the front side reaches out in an attack, loose edges (capes, hair, wings, tails) ripple, blobs
// jiggle and worms undulate. The fragment part is the regular unit shader (flash, tint, outline, dissolve).

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 glow : source_color = vec4(0.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 outline_color : source_color = vec4(0.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;
uniform float texel_scale = 1.0;

// rig, in texture pixels: height of the figure and half its width; the side the art faces (+1 right)
uniform float rig_h = 300.0;
uniform float rig_w = 150.0;
uniform float front = -1.0;
// motion channels (fractions of the height unless noted), driven per frame from UnitView
uniform float breathe = 0.0;     // -1..1 breathing phase
uniform float breathe_amp = 1.0;
uniform float sway = 0.0;        // pendulum offset of the top
uniform float lean = 0.0;        // shear of the whole figure (forward > 0)
uniform float reach = 0.0;       // upper front pushed forward (attack), < 0 pulls back (wind-up)
uniform float crouch = 0.0;      // body compresses towards the feet, shoulders widen
uniform float wave_amp = 0.0;    // loose edges ripple
uniform float wave_speed = 2.0;
uniform float flap = 0.0;        // wing beat amplitude (flyers)
uniform float flap_speed = 10.0;
uniform float jelly = 0.0;       // blob wobble
uniform float undulate = 0.0;    // serpentine wave along the height (worms, tentacles)
uniform float skitter = 0.0;     // fast low leg jitter (spiders, crabs)
uniform float stride = 0.0;      // -1..1 gait phase while moving
uniform float stride_amp = 0.0;

#include "res://assets/shaders/recolor.gdshaderinc"

float hash(vec2 p) {
	return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec2 v = VERTEX;
	float hn = clamp(-v.y / rig_h, 0.0, 1.0);            // 0 feet .. 1 top
	float xn = clamp(v.x / max(1.0, rig_w), -1.6, 1.6);  // -1 .. 1 across the body
	float t = TIME + time_offset;
	float upper = smoothstep(0.25, 0.95, hn);
	float chest = smoothstep(0.2, 0.6, hn) * (1.0 - smoothstep(0.75, 1.0, hn));
	float edge = smoothstep(0.35, 1.05, abs(xn));
	float fside = clamp(xn * front, 0.0, 1.0);           // 1 on the side the creature faces

	// breathing: the chest lifts and widens a hair, shoulders follow
	v.y -= breathe * breathe_amp * rig_h * 0.032 * upper;
	v.x += xn * breathe * breathe_amp * rig_w * 0.035 * chest;
	// crouch: squash towards the ground, widen at the base of the torso
	v.y += crouch * rig_h * 0.10 * hn;
	v.x += xn * crouch * rig_w * 0.06 * chest;
	// pendulum sway (top moves most) and a forward lean
	v.x += front * (sway * rig_h * hn * hn + lean * rig_h * hn);
	// attack reach: the upper front (arm, weapon, jaws) swings out, the head dips into the blow
	float arm = upper * (0.35 + 0.65 * fside);
	v.x += front * reach * rig_h * 0.26 * arm;
	v.y += reach * rig_h * 0.05 * upper * fside;
	// gait: legs alternate under a steady body, the body bobs twice per stride
	float legs = 1.0 - smoothstep(0.0, 0.35, hn);
	v.x += front * stride * stride_amp * rig_w * 0.10 * legs * sign(xn + 0.0001);
	v.y -= abs(stride) * stride_amp * rig_h * 0.025 * (1.0 - legs);
	// secondary motion: loose edges and the top ripple behind the body
	float w = sin(t * wave_speed + hn * 5.0 + xn * 1.7);
	v.x += w * wave_amp * rig_w * 0.08 * hn * (0.35 + edge);
	v.y += cos(t * wave_speed * 0.8 + xn * 4.0) * wave_amp * rig_h * 0.018 * edge * hn;
	// wings: outer parts beat up and down
	v.y += flap * rig_h * 0.16 * edge * sin(t * flap_speed) * smoothstep(0.25, 0.75, hn);
	v.x -= flap * rig_w * 0.04 * edge * sign(xn) * (0.5 + 0.5 * cos(t * flap_speed));
	// jelly: squash and stretch that rolls around the body
	v.x += jelly * xn * rig_w * 0.07 * sin(t * 5.5) * (0.4 + hn);
	v.y -= jelly * rig_h * 0.07 * sin(t * 5.5 + 1.3) * hn;
	// serpentine wave
	v.x += undulate * rig_w * 0.18 * sin(hn * 6.2 - t * 3.2) * hn;
	// skitter: quick jitter of the low outer parts (legs)
	v.y -= skitter * rig_h * 0.02 * legs * edge * abs(sin(t * 22.0 + xn * 9.0));
	VERTEX = v;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * texel_scale;
	if (outline_color.a > 0.0 && c.a < 0.5) {
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (a > 0.5) {
			float pulse = 0.75 + 0.25 * sin(TIME * 4.0 + time_offset);
			c = vec4(outline_color.rgb, outline_color.a * pulse);
		}
	}
	c.rgb = apply_recolor(c.rgb);
	c.rgb *= tint.rgb;
	c.rgb = mix(c.rgb, flash_color.rgb, flash * step(0.01, c.a));
	c.rgb += glow.rgb * glow.a * step(0.01, c.a);
	if (dissolve > 0.0) {
		// noise cells about a third of a logical pixel: fine grain at 4-5x instead of square blocks
		float n = hash(floor(UV / (px * 0.33)));
		if (n < dissolve) {
			c.a = 0.0;
		} else if (n < dissolve + 0.08) {
			c.rgb = mix(c.rgb, vec3(1.0, 0.85, 0.5), 0.8);
		}
	}
	COLOR = c * vec4(1.0, 1.0, 1.0, tint.a);
}
