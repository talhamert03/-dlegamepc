class_name ChestArt
extends RefCounted
## Vector-drawn treasure chests (five rarities), drawn at any size into any CanvasItem's draw callback.
## open: 0 closed .. 1 lid thrown back; t: time for the shimmer / aura.

const PAL := {
	"wood": {"b0": Color("#B07A44"), "b1": Color("#5E3A1E"), "m0": Color("#A3A9B3"), "m1": Color("#4C5058"), "plate": Color("#8D939C"), "gem": Color(0, 0, 0, 0), "glow": Color("#FFD9A0")},
	"iron": {"b0": Color("#7C8A99"), "b1": Color("#343C47"), "m0": Color("#E2E9F2"), "m1": Color("#77828F"), "plate": Color("#CCD6E2"), "gem": Color("#6FB7FF"), "glow": Color("#BFE0FF")},
	"gold": {"b0": Color("#A8402F"), "b1": Color("#4E1712"), "m0": Color("#FFE89A"), "m1": Color("#B87D1E"), "plate": Color("#F5C24E"), "gem": Color("#FF5A4A"), "glow": Color("#FFE07A")},
	"crystal": {"b0": Color("#5644A0"), "b1": Color("#1E163F"), "m0": Color("#C8F7FF"), "m1": Color("#4596C8"), "plate": Color("#9BEBFF"), "gem": Color("#E28BFF"), "glow": Color("#D7B4FF")},
	"royal": {"b0": Color("#47294F"), "b1": Color("#140B18"), "m0": Color("#FFEDB0"), "m1": Color("#C07C22"), "plate": Color("#FFD36A"), "gem": Color("#FF3B4E"), "glow": Color("#FFB45A")},
}


## Draws a chest standing on `foot` (bottom centre), `w` wide.
static func draw(n: CanvasItem, foot: Vector2, w: float, kind: String, open := 0.0, t := 0.0, aura := true) -> void:
	var p: Dictionary = PAL.get(kind, PAL["wood"])
	var r := Chests.rank(kind)
	var h := w * 0.5
	var lh := w * 0.3
	var x0 := foot.x - w / 2.0
	var x1 := foot.x + w / 2.0
	var seam := foot.y - h
	var olw: float = max(1.0, w / 40.0)
	var ink := Color(0.05, 0.03, 0.04, 0.95)
	# ground shadow
	_ellipse(n, foot + Vector2(0, 0.5), Vector2(w * 0.62, w * 0.09), Color(0, 0, 0, 0.35))
	# aura for gold and above
	if aura and r >= 2:
		var pulse := 0.75 + 0.25 * sin(t * 2.6)
		var gc: Color = p["glow"]
		for k in 5:
			n.draw_circle(foot - Vector2(0, h * 0.8), w * (0.95 - k * 0.14) * (0.9 + 0.1 * pulse), Color(gc, 0.05 * pulse * (r - 1)))
	# light pouring out of an open chest
	if open > 0.05:
		var gc2: Color = p["glow"]
		var o := Vector2(foot.x, seam + 1)
		for k in 7:
			var ang := -PI / 2.0 + (k - 3) * 0.32 + sin(t * 1.5 + k) * 0.05
			var len := w * (0.9 + 0.35 * sin(t * 3.0 + k * 1.7)) * open
			var dir := Vector2(cos(ang), sin(ang))
			var side := dir.orthogonal() * w * 0.07
			n.draw_colored_polygon(PackedVector2Array([o - side * 0.5, o + side * 0.5, o + dir * len + side, o + dir * len - side]),
				Color(gc2, 0.16 * open))
		n.draw_circle(o, w * 0.32 * open, Color(gc2, 0.25 * open))
	# lid thrown back: its lit inner face leans away above the seam
	var s := 1.0 - open * 1.8
	if s < 0.0:
		var ih := lh * minf(1.0, -s) * 1.5
		var lean := w * 0.06 * minf(1.0, -s)
		var inner := PackedVector2Array([Vector2(x0 + w * 0.02, seam), Vector2(x1 - w * 0.02, seam),
			Vector2(x1 - w * 0.06 + lean, seam - ih), Vector2(x0 + w * 0.06 - lean, seam - ih)])
		_grad_poly(n, inner, p["b1"].darkened(0.3), p["b0"].lerp(p["glow"], 0.45 * open), seam - ih, seam)
		for k in 3:
			var yy := seam - ih * (0.3 + k * 0.25)
			n.draw_line(Vector2(x0 + w * 0.06, yy), Vector2(x1 - w * 0.06, yy), Color(p["b1"].darkened(0.4), 0.6), max(1.0, w / 80.0))
		_outline(n, inner, ink, olw)
		n.draw_line(Vector2(x0 + w * 0.06 - lean, seam - ih), Vector2(x1 - w * 0.06 + lean, seam - ih), p["m0"], olw * 1.4)
	# body
	var body := PackedVector2Array([Vector2(x0, seam), Vector2(x1, seam), Vector2(x1, foot.y), Vector2(x0, foot.y)])
	_grad_poly(n, body, p["b0"], p["b1"], seam, foot.y)
	if kind == "wood" or kind == "gold":
		for k in 2:
			var yy := seam + h * (0.36 + k * 0.32)
			n.draw_line(Vector2(x0 + 1, yy), Vector2(x1 - 1, yy), Color(p["b1"].darkened(0.45), 0.8), max(1.0, w / 70.0))
			n.draw_line(Vector2(x0 + 1, yy + 1), Vector2(x1 - 1, yy + 1), Color(p["b0"].lightened(0.25), 0.25), max(1.0, w / 90.0))
	elif kind == "crystal":
		for k in 3:
			var cx := x0 + w * (0.2 + k * 0.3)
			var facet := PackedVector2Array([Vector2(cx, seam + h * 0.2), Vector2(cx + w * 0.05, seam + h * 0.5), Vector2(cx, seam + h * 0.85), Vector2(cx - w * 0.05, seam + h * 0.5)])
			n.draw_colored_polygon(facet, Color(p["m0"], 0.18 + 0.1 * sin(t * 2.0 + k)))
	# opening: dark mouth with light when open
	if open > 0.05:
		var mh := h * 0.3
		var mouth := PackedVector2Array([Vector2(x0 + w * 0.03, seam), Vector2(x1 - w * 0.03, seam), Vector2(x1 - w * 0.08, seam + mh), Vector2(x0 + w * 0.08, seam + mh)])
		_grad_poly(n, mouth, p["glow"].lerp(Color.WHITE, 0.3 * open), p["b1"].darkened(0.5), seam, seam + mh)
		# heaped treasure catching the light
		for k in 9:
			var cx2 := foot.x + (k - 4) * w * 0.085
			var cy2 := seam + 1.0 + absf(k - 4) * w * 0.012
			n.draw_circle(Vector2(cx2, cy2), w * 0.045, Color("#B8821E"))
			n.draw_circle(Vector2(cx2 - w * 0.01, cy2 - w * 0.012), w * 0.025, Color("#FFE58A", open))
	# metal straps and corner caps
	var sw := w * 0.1
	for sx: float in [-0.3, 0.3]:
		var bx: float = foot.x + w * sx
		var strap := PackedVector2Array([Vector2(bx - sw / 2, seam), Vector2(bx + sw / 2, seam), Vector2(bx + sw / 2, foot.y), Vector2(bx - sw / 2, foot.y)])
		_grad_poly_h(n, strap, p["m0"], p["m1"], bx - sw / 2, bx + sw / 2)
		_outline(n, strap, Color(ink, 0.6), olw * 0.7)
		for k in 3:
			n.draw_circle(Vector2(bx, seam + h * (0.2 + k * 0.3)), max(0.6, w / 55.0), p["m1"].darkened(0.4))
	for cx: float in [x0, x1]:
		var dirx: float = 1.0 if cx == x0 else -1.0
		var cap := PackedVector2Array([Vector2(cx, foot.y), Vector2(cx, foot.y - h * 0.32), Vector2(cx + dirx * w * 0.13, foot.y)])
		n.draw_colored_polygon(cap, p["m1"])
		n.draw_polyline(PackedVector2Array([cap[1], cap[2]]), p["m0"], olw * 0.6, true)
	_outline(n, body, ink, olw)
	# closed / half-open lid
	if s > 0.0:
		var lid := _arch(x0, x1, seam, lh * s)
		_grad_poly(n, lid, p["b0"].lightened(0.12), p["b0"].darkened(0.1), seam - lh * s, seam)
		for sx: float in [-0.3, 0.3]:
			var bx: float = foot.x + w * sx
			var band := _arch(bx - sw / 2, bx + sw / 2, seam, lh * s, true, x0, x1)
			_grad_poly_h(n, band, p["m0"], p["m1"], bx - sw / 2, bx + sw / 2)
		_outline(n, lid, ink, olw)
		n.draw_line(Vector2(x0, seam), Vector2(x1, seam), p["m1"].darkened(0.3), olw * 1.6)
		n.draw_line(Vector2(x0 + 1, seam - 1), Vector2(x1 - 1, seam - 1), Color(p["m0"], 0.55), olw * 0.7)
		# a glint sliding over the lid on rare+ chests
		if r >= 2:
			var gx := fmod(t * 0.45, 1.6) - 0.3
			if gx > 0.0 and gx < 1.0:
				var gxp := x0 + w * gx
				n.draw_line(Vector2(gxp - w * 0.04, seam - lh * s * 0.85), Vector2(gxp + w * 0.04, seam - 2), Color(1, 1, 1, 0.45), max(1.0, w / 30.0))
	# lock plate (rides away with the lid)
	if s < 0.0:
		return
	var pw := w * 0.2
	var ph := h * 0.42
	var pc := Vector2(foot.x, seam + ph * 0.32 - (lh * 0.25 * maxf(0.0, s)))
	var plate := PackedVector2Array([pc + Vector2(-pw / 2, -ph / 2), pc + Vector2(pw / 2, -ph / 2), pc + Vector2(pw / 2, ph * 0.2),
		pc + Vector2(0, ph / 2), pc + Vector2(-pw / 2, ph * 0.2)])
	_grad_poly(n, plate, p["plate"].lightened(0.25), p["plate"].darkened(0.3), pc.y - ph / 2, pc.y + ph / 2)
	_outline(n, plate, ink, olw * 0.8)
	var gem: Color = p["gem"]
	if gem.a > 0.0:
		var gr := pw * 0.24
		n.draw_circle(pc - Vector2(0, ph * 0.08), gr * 1.25, ink)
		n.draw_circle(pc - Vector2(0, ph * 0.08), gr, gem)
		n.draw_circle(pc - Vector2(gr * 0.35, ph * 0.08 + gr * 0.35), gr * 0.35, Color(1, 1, 1, 0.7))
	else:
		n.draw_circle(pc - Vector2(0, ph * 0.1), pw * 0.12, ink)
		n.draw_line(pc - Vector2(0, ph * 0.08), pc + Vector2(0, ph * 0.18), ink, max(1.0, pw * 0.1))
	# sparkles on the best chests
	if r >= 3:
		for k in 3:
			var ph2 := fmod(t * 0.7 + k * 0.37, 1.0)
			var sp := foot + Vector2((k - 1) * w * 0.38 + sin(k * 3.1) * w * 0.1, -h - lh * 0.6 - ph2 * w * 0.35)
			var a := sin(ph2 * PI)
			var sz2 := w * 0.05 * a
			n.draw_line(sp - Vector2(sz2, 0), sp + Vector2(sz2, 0), Color(p["glow"], a), max(1.0, w / 60.0))
			n.draw_line(sp - Vector2(0, sz2), sp + Vector2(0, sz2), Color(p["glow"], a), max(1.0, w / 60.0))


## Half-ellipse lid outline from (a, y) to (b, y), bulging up by `hh`. With `clip`, only the part between
## a and b of the arch spanning lx..rx (a strap over the lid).
static func _arch(a: float, b: float, y: float, hh: float, clip := false, lx := 0.0, rx := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	if not clip:
		lx = a
		rx = b
	var cx := (lx + rx) / 2.0
	var rw := (rx - lx) / 2.0
	pts.append(Vector2(a, y))
	for i in steps + 1:
		var x := lerpf(a, b, float(i) / steps)
		var u := clampf((x - cx) / rw, -1.0, 1.0)
		pts.append(Vector2(x, y - hh * sqrt(maxf(0.0, 1.0 - u * u * 0.92))))
	pts.append(Vector2(b, y))
	return pts


static func _grad_poly(n: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color, y0: float, y1: float) -> void:
	var cols := PackedColorArray()
	for v in pts:
		cols.append(top.lerp(bottom, clampf((v.y - y0) / maxf(0.001, y1 - y0), 0.0, 1.0)))
	n.draw_polygon(pts, cols)


static func _grad_poly_h(n: CanvasItem, pts: PackedVector2Array, mid: Color, edge: Color, x0: float, x1: float) -> void:
	var cols := PackedColorArray()
	for v in pts:
		var u := absf((v.x - x0) / maxf(0.001, x1 - x0) - 0.4) * 2.0
		cols.append(mid.lerp(edge, clampf(u, 0.0, 1.0)))
	n.draw_polygon(pts, cols)


static func _outline(n: CanvasItem, pts: PackedVector2Array, c: Color, wdt: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	n.draw_polyline(loop, c, wdt, true)


static func _ellipse(n: CanvasItem, c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	n.draw_colored_polygon(pts, col)
