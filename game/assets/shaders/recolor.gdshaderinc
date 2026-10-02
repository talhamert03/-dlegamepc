// Costume recolor: pixels whose hue is near src_hue (and saturated enough) are moved to dst_hue.
uniform float recolor = 0.0;
uniform float src_hue = 0.0;
uniform float hue_tol = 0.09;
uniform float dst_hue = 0.0;
uniform float sat_mul = 1.0;
uniform float val_mul = 1.0;

vec3 rc_rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 rc_hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 apply_recolor(vec3 rgb) {
	if (recolor < 0.5) {
		return rgb;
	}
	vec3 hsv = rc_rgb2hsv(rgb);
	float dh = abs(hsv.x - src_hue);
	dh = min(dh, 1.0 - dh);
	if (dh > hue_tol || hsv.y < 0.28) {
		return rgb;
	}
	float off = hsv.x - src_hue;
	if (off > 0.5) { off -= 1.0; }
	if (off < -0.5) { off += 1.0; }
	hsv.x = fract(dst_hue + off + 1.0);
	hsv.y = clamp(hsv.y * sat_mul, 0.0, 1.0);
	hsv.z = clamp(hsv.z * val_mul, 0.0, 1.0);
	return rc_hsv2rgb(hsv);
}
