class_name UISkin
extends RefCounted
## Vector UI skin: dark iron frames, red title ribbons, bronze trim, wooden buttons, rarity-filled slots.
## Everything is drawn with gradient polygons + anti-aliased strokes at native resolution, so it stays
## crisp at every UI scale. Used by UIFrame, GameStyleBox (buttons / tabs) and ItemSlot.

const IRON_TOP := Color("#5A3E27")      # walnut frame
const IRON_BOT := Color("#2B1B10")
const BODY_TOP := Color("#2A211B")      # dark tooled leather
const BODY_BOT := Color("#17110D")
const OUTLINE := Color("#0A0604")
const BRONZE := Color("#C8913F")
const BRONZE_HI := Color("#F2CB7A")
const BRONZE_LO := Color("#7A4E1C")
const RIBBON_TOP := Color("#B92E33")
const RIBBON_BOT := Color("#76161B")
const BAND_TOP := Color("#3E2717")
const BAND_BOT := Color("#21140B")
const PARCH_TOP := Color("#DCC293")
const PARCH_BOT := Color("#B99662")
const PARCH_EDGE := Color("#6A4824")
const INK := Color("#3A2412")
## wooden button palettes: [top, bottom, inner border, text]
const BTN := {
	"orange": ["#CF7E33", "#8C4716", "#F3C77A", "#FFF4E0"],
	"brown": ["#6A4A30", "#3A2516", "#B08A55", "#F3E6CC"],
	"gold": ["#E5B44E", "#A5751F", "#FFE7A6", "#3A240E"],
	"blue": ["#4380CF", "#244A8C", "#A6CBFF", "#F2F7FF"],
	"red": ["#C03E3B", "#7B1E1E", "#F4A38C", "#FFF0EA"],
	"green": ["#46A15B", "#24673B", "#A6EBB2", "#F0FFF2"],
	"gray": ["#4A423A", "#2C2621", "#7A6D5E", "#D8CFC2"],
}


static func rrect(r: Rect2, rad: float, seg := 3) -> PackedVector2Array:
	var p := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	if rad <= 0.01:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var cs := [[Vector2(r.end.x - rad, r.position.y + rad), -PI / 2.0], [Vector2(r.end.x - rad, r.end.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2.0], [Vector2(r.position.x + rad, r.position.y + rad), PI]]
	for c in cs:
		for i in seg + 1:
			var a: float = c[1] + (PI / 2.0) * i / seg
			p.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return p


static func _vcols(pts: PackedVector2Array, top: Color, bot: Color, y0: float, y1: float) -> PackedColorArray:
	var c := PackedColorArray()
	var h := maxf(0.001, y1 - y0)
	for q in pts:
		c.append(top.lerp(bot, clampf((q.y - y0) / h, 0.0, 1.0)))
	return c


## Vertical-gradient rounded rect.
static func fill(ci: RID, r: Rect2, rad: float, top: Color, bot: Color) -> void:
	var pts := rrect(r, rad)
	RenderingServer.canvas_item_add_polygon(ci, pts, _vcols(pts, top, bot, r.position.y, r.end.y))


static func stroke(ci: RID, r: Rect2, rad: float, col: Color, w := 1.0) -> void:
	var pts := rrect(r, rad)
	pts.append(pts[0])
	RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([col]), w, true)


static func line(ci: RID, a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	RenderingServer.canvas_item_add_polyline(ci, PackedVector2Array([a, b]), PackedColorArray([col]), w, true)


static func poly(ci: RID, pts: PackedVector2Array, top: Color, bot: Color) -> void:
	var y0 := INF
	var y1 := -INF
	for q in pts:
		y0 = minf(y0, q.y)
		y1 = maxf(y1, q.y)
	RenderingServer.canvas_item_add_polygon(ci, pts, _vcols(pts, top, bot, y0, y1))


static func circle(ci: RID, c: Vector2, rad: float, top: Color, bot: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	RenderingServer.canvas_item_add_polygon(ci, pts, _vcols(pts, top, bot, c.y - rad, c.y + rad))


static func ring(ci: RID, c: Vector2, rad: float, col: Color, w := 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([col]), w, true)


static func rivet(ci: RID, c: Vector2, rad := 1.6) -> void:
	circle(ci, c, rad + 0.6, OUTLINE, OUTLINE)
	circle(ci, c, rad, BRONZE_HI, BRONZE_LO)
	circle(ci, c + Vector2(-rad * 0.3, -rad * 0.35), rad * 0.35, Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.2))


static func diamond(ci: RID, c: Vector2, s: float, top: Color = BRONZE_HI, bot: Color = BRONZE_LO) -> void:
	poly(ci, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), top, bot)


# ------------------------------------------------------------------ composite pieces
## Fantasy window: a carved walnut frame with a raised bevel and a groove, gilded corner caps set with
## rubies, gem plates halfway down the sides and at the bottom, a dark leather body lit warmly from the
## top, and a header band whose title ribbon rests on a gilded crest with scroll curls.
static func panel(ci: RID, r: Rect2, header_h := 0.0, ribbon_w := 0.0) -> void:
	# cast shadow
	fill(ci, Rect2(r.position + Vector2(1, 3), r.size), 6, Color(0, 0, 0, 0.32), Color(0, 0, 0, 0.55))
	# carved walnut frame: dark rim, raised middle, inner groove
	fill(ci, r, 5, IRON_TOP, IRON_BOT)
	var gy := r.position.y + 1.5
	var gi := 0
	while gy < r.end.y - 1.0:
		var a := 0.05 + 0.05 * fposmod(sin(float(gi) * 12.9898) * 43758.5, 1.0)
		line(ci, Vector2(r.position.x + 1, gy), Vector2(r.position.x + 4.2, gy), Color(0, 0, 0, a), 0.6)
		line(ci, Vector2(r.end.x - 4.2, gy), Vector2(r.end.x - 1, gy), Color(0, 0, 0, a), 0.6)
		gy += 2.3
		gi += 1
	stroke(ci, r, 5, OUTLINE, 1.2)
	stroke(ci, r.grow(-1.0), 5, Color(1, 0.85, 0.6, 0.10), 0.8)
	stroke(ci, r.grow(-2.6), 4, Color(BRONZE, 0.45), 0.9)
	stroke(ci, r.grow(-4.2), 4, Color(0, 0, 0, 0.6), 0.9)
	line(ci, r.position + Vector2(6, 1.6), Vector2(r.end.x - 6, r.position.y + 1.6), Color(BRONZE_HI, 0.5), 0.8)
	# leather body, lit from the top centre
	var body := r.grow(-6.0)
	fill(ci, body, 3, BODY_TOP, BODY_BOT)
	var glow_c := Vector2(body.get_center().x, body.position.y + (header_h if header_h > 0.0 else 0.0))
	for k in 5:
		var rad := minf(body.size.x * 0.55, 120.0) * (1.0 - k * 0.17)
		RenderingServer.canvas_item_add_circle(ci, glow_c, rad, Color(1.0, 0.7, 0.4, 0.012))
	stroke(ci, body, 3, Color(0, 0, 0, 0.9), 1.0)
	for k in 3:
		stroke(ci, body.grow(-1.0 - k * 1.2), 3, Color(0, 0, 0, 0.16 - k * 0.04), 1.4)
	# a sparse tooled pattern (tiny lozenges) on the leather
	var seed := int(body.size.x * 3.0 + body.size.y * 7.0)
	var top_y := body.position.y + (header_h + 2.0 if header_h > 0.0 else 4.0)
	var yy := top_y + 6.0
	var row := 0
	while yy < body.end.y - 4.0:
		var xx := body.position.x + 8.0 + (6.0 if row % 2 == 1 else 0.0)
		while xx < body.end.x - 6.0:
			var n := fposmod(sin(float(seed + int(xx) * 31 + int(yy) * 17)) * 43758.5453, 1.0)
			if n > 0.55:
				var c := Vector2(xx, yy)
				poly(ci, PackedVector2Array([c + Vector2(0, -1.1), c + Vector2(1.1, 0), c + Vector2(0, 1.1), c + Vector2(-1.1, 0)]),
					Color(BRONZE_HI, 0.035), Color(BRONZE_HI, 0.02))
			xx += 12.0
		yy += 9.0
		row += 1
	if header_h > 0.0:
		var band := Rect2(body.position, Vector2(body.size.x, header_h))
		fill(ci, band, 3, BAND_TOP, BAND_BOT)
		var x := band.position.x + 4.0
		while x < band.end.x - 4.0:
			line(ci, Vector2(x, band.position.y + 2), Vector2(minf(x + 5.0, band.end.x - 3), band.end.y - 3), Color(BRONZE_HI, 0.07), 0.7)
			line(ci, Vector2(minf(x + 5.0, band.end.x - 3), band.position.y + 2), Vector2(x, band.end.y - 3), Color(BRONZE_HI, 0.07), 0.7)
			x += 7.0
		line(ci, Vector2(band.position.x, band.end.y + 0.5), Vector2(band.end.x, band.end.y + 0.5), Color(0, 0, 0, 0.85), 1.0)
		line(ci, Vector2(band.position.x + 2, band.end.y - 0.5), Vector2(band.end.x - 2, band.end.y - 0.5), Color(BRONZE, 0.85), 1.0)
		if ribbon_w > 0.0:
			var rr := Rect2(Vector2(r.position.x + (r.size.x - ribbon_w) / 2.0, band.position.y + 1.5), Vector2(ribbon_w, header_h - 3.0))
			# gilded rules running out from the crest to the frame, ending in a lozenge
			var cy := rr.get_center().y
			for sd in [-1.0, 1.0]:
				var x0: float = rr.position.x - 13.0 if sd < 0 else rr.end.x + 13.0
				var x1: float = band.position.x + 10.0 if sd < 0 else band.end.x - 22.0
				if (x1 - x0) * sd > 8.0:
					line(ci, Vector2(x0, cy - 1.2), Vector2(x1, cy - 1.2), Color(BRONZE, 0.55), 0.8)
					line(ci, Vector2(x0, cy + 1.2), Vector2(x1, cy + 1.2), Color(BRONZE, 0.55), 0.8)
					diamond(ci, Vector2(x1, cy), 2.0)
			_crest_plate(ci, rr)
			ribbon(ci, rr)
	# gold pinstripe inside the frame, and a tooled double rule with corner curls on the leather
	stroke(ci, body.grow(1.6), 4, Color(BRONZE, 0.42), 0.8)
	var inr := Rect2(body.position + Vector2(2.5, (header_h + 2.5) if header_h > 0.0 else 2.5), body.size - Vector2(5, ((header_h + 2.5) if header_h > 0.0 else 2.5) + 2.5))
	if inr.size.x > 40.0 and inr.size.y > 40.0:
		stroke(ci, inr, 2, Color(BRONZE, 0.20), 0.7)
		stroke(ci, inr.grow(-1.8), 2, Color(BRONZE, 0.12), 0.6)
		for i in 4:
			var cc: Vector2 = [inr.position, Vector2(inr.end.x, inr.position.y), inr.end, Vector2(inr.position.x, inr.end.y)][i]
			var ddx := 1.0 if i == 0 or i == 3 else -1.0
			var ddy := 1.0 if i < 2 else -1.0
			var curl := PackedVector2Array()
			for j in 14:
				var a: float = (PI if ddx > 0 else 0.0) + j * 0.42 * ddx * ddy
				curl.append(cc + Vector2(ddx * 9.0, ddy * 9.0) + Vector2(cos(a), sin(a)) * (6.0 - j * 0.32))
			RenderingServer.canvas_item_add_polyline(ci, curl, PackedColorArray([Color(BRONZE_HI, 0.22)]), 0.9, true)
			diamond(ci, cc + Vector2(ddx * 2.5, ddy * 2.5), 1.6, Color(BRONZE_HI, 0.5), Color(BRONZE_LO, 0.5))
	# studs along the long edges
	var sx := r.position.x + 30.0
	while sx < r.end.x - 28.0:
		if absf(sx - r.get_center().x) > 14.0:
			for sy in [r.position.y + 2.6, r.end.y - 2.6]:
				circle(ci, Vector2(sx, sy), 1.15, BRONZE_HI, BRONZE_LO)
		sx += 30.0
	var sy2 := r.position.y + 32.0
	while sy2 < r.end.y - 28.0:
		if absf(sy2 - r.get_center().y) > 14.0:
			for sx2 in [r.position.x + 2.6, r.end.x - 2.6]:
				circle(ci, Vector2(sx2, sy2), 1.15, BRONZE_HI, BRONZE_LO)
		sy2 += 30.0
	# gem plates halfway down both sides and at the bottom centre
	if r.size.y > 90.0:
		for sd in [-1.0, 1.0]:
			var gx: float = r.position.x + 2.6 if sd < 0 else r.end.x - 2.6
			_gem_plate(ci, Vector2(gx, r.get_center().y), true)
	if r.size.x > 90.0:
		_gem_plate(ci, Vector2(r.get_center().x, r.end.y - 2.6), false)
	# gilded corner caps with a ruby
	for i in 4:
		var c: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][i]
		var dx := 1.0 if i == 0 or i == 3 else -1.0
		var dy := 1.0 if i < 2 else -1.0
		_corner_cap(ci, c, dx, dy)


## L-shaped gilded corner cap: two tapering arms with an engraved line, a leaf scroll at each tip and a
## ruby in a gold socket on the corner.
static func _corner_cap(ci: RID, c: Vector2, dx: float, dy: float) -> void:
	var o := c + Vector2(dx * 0.5, dy * 0.5)
	var arm := 28.0
	var plate := PackedVector2Array([o, o + Vector2(dx * arm, 0), o + Vector2(dx * (arm - 4.0), dy * 7.5), o + Vector2(dx * 13.0, dy * 8.0),
		o + Vector2(dx * 15.0, dy * 15.0), o + Vector2(dx * 8.0, dy * 13.0), o + Vector2(dx * 7.5, dy * (arm - 4.0)), o + Vector2(0, dy * arm)])
	var shadow := PackedVector2Array()
	for q in plate:
		shadow.append(q + Vector2(0.6, 1.0))
	RenderingServer.canvas_item_add_polygon(ci, shadow, PackedColorArray([Color(0, 0, 0, 0.45)]))
	poly(ci, plate, BRONZE_HI, BRONZE_LO)
	var closed := plate.duplicate()
	closed.append(plate[0])
	RenderingServer.canvas_item_add_polyline(ci, closed, PackedColorArray([OUTLINE]), 1.0, true)
	line(ci, o + Vector2(dx * 9.0, dy * 3.2), o + Vector2(dx * (arm - 4.5), dy * 3.2), Color(0.35, 0.2, 0.05, 0.75), 0.8)
	line(ci, o + Vector2(dx * 3.2, dy * 9.0), o + Vector2(dx * 3.2, dy * (arm - 4.5)), Color(0.35, 0.2, 0.05, 0.75), 0.8)
	line(ci, o + Vector2(dx * 8.0, dy * 8.0), o + Vector2(dx * 11.0, dy * 11.0), Color(0.35, 0.2, 0.05, 0.75), 0.8)
	line(ci, o + Vector2(dx * 5.0, dy * 0.9), o + Vector2(dx * (arm - 2.0), dy * 0.9), Color(1, 0.95, 0.75, 0.45), 0.6)
	# leaf scrolls at the tips
	for k in 2:
		var tip: Vector2 = o + (Vector2(dx * (arm + 1.5), dy * 2.0) if k == 0 else Vector2(dx * 2.0, dy * (arm + 1.5)))
		var arc := PackedVector2Array()
		var a0: float = (PI if dx < 0 else 0.0) if k == 0 else (PI * 0.5 if dy > 0 else -PI * 0.5)
		for j in 8:
			var a: float = a0 + j * 0.62 * (dx * dy if k == 0 else -dx * dy)
			arc.append(tip + Vector2(cos(a), sin(a)) * (2.4 - j * 0.16))
		RenderingServer.canvas_item_add_polyline(ci, arc, PackedColorArray([OUTLINE]), 1.9, true)
		RenderingServer.canvas_item_add_polyline(ci, arc, PackedColorArray([BRONZE_HI]), 0.9, true)
	var g := o + Vector2(dx * 5.0, dy * 5.0)
	circle(ci, g, 4.1, OUTLINE, OUTLINE)
	circle(ci, g, 3.5, BRONZE_HI, BRONZE_LO)
	circle(ci, g, 2.6, Color("#FF5050"), Color("#6A0A14"))
	circle(ci, g + Vector2(-0.8, -0.9), 0.85, Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.5))


## Small gilded plate with a sapphire, set into the frame (vertical on the sides, horizontal at the bottom).
static func _gem_plate(ci: RID, c: Vector2, vertical: bool) -> void:
	var l := 7.0
	var w := 2.6
	var pts: PackedVector2Array
	if vertical:
		pts = PackedVector2Array([c + Vector2(0, -l), c + Vector2(w, -l + 3), c + Vector2(w, l - 3), c + Vector2(0, l), c + Vector2(-w, l - 3), c + Vector2(-w, -l + 3)])
	else:
		pts = PackedVector2Array([c + Vector2(-l, 0), c + Vector2(-l + 3, -w), c + Vector2(l - 3, -w), c + Vector2(l, 0), c + Vector2(l - 3, w), c + Vector2(-l + 3, w)])
	poly(ci, pts, BRONZE_HI, BRONZE_LO)
	var closed := pts.duplicate()
	closed.append(pts[0])
	RenderingServer.canvas_item_add_polyline(ci, closed, PackedColorArray([OUTLINE]), 1.0, true)
	circle(ci, c, 2.3, OUTLINE, OUTLINE)
	circle(ci, c, 1.8, Color("#7FB8FF"), Color("#1A3A8A"))
	circle(ci, c + Vector2(-0.5, -0.6), 0.55, Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.5))


## Gilded crest behind the title ribbon: a low arch with a jewel on top and scroll curls at both ends.
static func _crest_plate(ci: RID, rr: Rect2) -> void:
	var cx := rr.get_center().x
	var top := rr.position.y - 2.5
	var half := rr.size.x / 2.0 + 13.0
	var pts := PackedVector2Array()
	pts.append(Vector2(cx - half, rr.end.y + 1.5))
	pts.append(Vector2(cx - half, rr.position.y + 3.0))
	for k in range(1, 12):
		var t := float(k) / 12.0
		var x := cx - half + t * half * 2.0
		var y := top + 2.6 * pow(absf(t - 0.5) * 2.0, 2.0)
		pts.append(Vector2(x, y))
	pts.append(Vector2(cx + half, rr.position.y + 3.0))
	pts.append(Vector2(cx + half, rr.end.y + 1.5))
	poly(ci, pts, Color("#5A3A1C"), Color("#24150A"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	RenderingServer.canvas_item_add_polyline(ci, closed, PackedColorArray([OUTLINE]), 1.4, true)
	RenderingServer.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(BRONZE, 0.85)]), 0.8, true)
	# scroll curls
	for sd in [-1.0, 1.0]:
		var sc: Vector2 = Vector2(cx + sd * (half - 3.0), rr.get_center().y + 0.5)
		var arc := PackedVector2Array()
		for j in 11:
			var a: float = -PI * 0.5 + j * 0.6 * sd
			arc.append(sc + Vector2(cos(a), sin(a)) * (3.6 - j * 0.24))
		RenderingServer.canvas_item_add_polyline(ci, arc, PackedColorArray([OUTLINE]), 2.2, true)
		RenderingServer.canvas_item_add_polyline(ci, arc, PackedColorArray([BRONZE_HI]), 1.0, true)
	# jewel on top of the arch
	var j := Vector2(cx, top + 0.5)
	poly(ci, PackedVector2Array([j + Vector2(0, -3.6), j + Vector2(3.2, 0), j + Vector2(0, 3.0), j + Vector2(-3.2, 0)]), BRONZE_HI, BRONZE_LO)
	poly(ci, PackedVector2Array([j + Vector2(0, -2.2), j + Vector2(1.9, 0), j + Vector2(0, 1.8), j + Vector2(-1.9, 0)]), Color("#FF6A6A"), Color("#7A0C18"))


## Notched red ribbon used for panel titles.
static func ribbon(ci: RID, r: Rect2) -> void:
	var n := minf(5.0, r.size.y * 0.35)
	var pts := PackedVector2Array([r.position + Vector2(n, 0), Vector2(r.end.x - n, r.position.y), Vector2(r.end.x, r.position.y + r.size.y * 0.5),
		Vector2(r.end.x - n, r.end.y), Vector2(r.position.x + n, r.end.y), Vector2(r.position.x, r.position.y + r.size.y * 0.5)])
	# folded banner tails behind both ends
	for sd in [-1.0, 1.0]:
		var ex: float = r.position.x if sd < 0 else r.end.x
		var tail := PackedVector2Array([Vector2(ex - sd * 2.0, r.position.y + 3.0), Vector2(ex + sd * 9.0, r.position.y + 3.0),
			Vector2(ex + sd * 5.5, r.get_center().y + 2.5), Vector2(ex + sd * 9.0, r.end.y + 2.5), Vector2(ex - sd * 2.0, r.end.y + 2.5)])
		poly(ci, tail, Color("#6E1418"), Color("#3A080B"))
		var tc := tail.duplicate()
		tc.append(tail[0])
		RenderingServer.canvas_item_add_polyline(ci, tc, PackedColorArray([OUTLINE]), 1.0, true)
	var outer := PackedVector2Array()
	var cx := r.get_center()
	for q in pts:
		outer.append(q + (q - cx).normalized() * 1.2)
	poly(ci, outer, OUTLINE, OUTLINE)
	poly(ci, pts, RIBBON_TOP, RIBBON_BOT)
	var closed := pts.duplicate()
	closed.append(pts[0])
	RenderingServer.canvas_item_add_polyline(ci, closed, PackedColorArray([BRONZE_HI]), 1.0, true)
	line(ci, r.position + Vector2(n + 1, 1.6), Vector2(r.end.x - n - 1, r.position.y + 1.6), Color(1, 0.75, 0.7, 0.35), 0.8)
	diamond(ci, Vector2(r.position.x - 3.5, cx.y), 2.4)
	diamond(ci, Vector2(r.end.x + 3.5, cx.y), 2.4)


static func parchment(ci: RID, r: Rect2) -> void:
	fill(ci, r, 2, PARCH_TOP, PARCH_BOT)
	# age stains and a darker, burnt rim
	var seed := int(r.size.x * 7.0 + r.size.y * 13.0)
	for k in 7:
		var u := fposmod(sin(float(seed + k * 37)) * 43758.55, 1.0)
		var v := fposmod(sin(float(seed + k * 91)) * 24634.63, 1.0)
		var rad := minf(r.size.x, r.size.y) * (0.12 + 0.18 * fposmod(u * 7.3, 1.0))
		var c := r.position + Vector2(r.size.x * (0.1 + 0.8 * u), r.size.y * (0.1 + 0.8 * v))
		RenderingServer.canvas_item_add_circle(ci, c, rad, Color(0.45, 0.3, 0.12, 0.025))
		RenderingServer.canvas_item_add_circle(ci, c, rad * 0.6, Color(0.45, 0.3, 0.12, 0.02))
	for k in 3:
		stroke(ci, r.grow(-1.0 - k * 1.5), 2, Color(0.42, 0.26, 0.1, 0.22 - k * 0.06), 1.6)
	stroke(ci, r, 2, PARCH_EDGE, 1.0)
	stroke(ci, r.grow(1.0), 3, Color(0, 0, 0, 0.7), 1.0)


## TBH-style carved frame around a section: iron band, bronze inlay, knot ornaments in the corners and
## small diamonds at the middle of the long edges.
static func ornate(ci: RID, r: Rect2) -> void:
	var o := r.grow(3.0)
	stroke(ci, o.grow(0.5), 3, OUTLINE, 1.0)
	stroke(ci, o.grow(-1.0), 3, Color("#4A4652"), 2.0)
	stroke(ci, o.grow(-2.2), 2, Color(1, 1, 1, 0.08), 0.8)
	stroke(ci, r.grow(0.5), 2, Color(BRONZE, 0.55), 0.8)
	for i in 4:
		var c: Vector2 = [o.position, Vector2(o.end.x, o.position.y), o.end, Vector2(o.position.x, o.end.y)][i]
		var dx := 1.0 if i == 0 or i == 3 else -1.0
		var dy := 1.0 if i < 2 else -1.0
		var k := c + Vector2(dx * 2.0, dy * 2.0)
		var sq := Rect2(k - Vector2(3.5, 3.5), Vector2(7, 7))
		fill(ci, sq, 1, IRON_TOP.lightened(0.15), IRON_BOT)
		stroke(ci, sq, 1, OUTLINE, 1.0)
		stroke(ci, sq.grow(-2.0), 0, Color(BRONZE, 0.85), 0.8)
		line(ci, k + Vector2(dx * 4.0, 0), k + Vector2(dx * 9.0, 0), Color(BRONZE, 0.7), 1.0)
		line(ci, k + Vector2(0, dy * 4.0), k + Vector2(0, dy * 9.0), Color(BRONZE, 0.7), 1.0)
	for y in [o.position.y, o.end.y]:
		diamond(ci, Vector2(o.get_center().x, y), 2.6)


## Sunken section: a dark inset with an inner shadow on top, a gilded hairline around it and a light
## lower lip, like a panel carved into the leather.
static func well(ci: RID, r: Rect2) -> void:
	stroke(ci, r.grow(1.2), 3, Color(BRONZE, 0.32), 0.8)
	fill(ci, r, 2, Color("#0E0907"), Color("#1A130E"))
	line(ci, r.position + Vector2(2, 1.2), Vector2(r.end.x - 2, r.position.y + 1.2), Color(0, 0, 0, 0.7), 1.4)
	line(ci, r.position + Vector2(1.2, 2), Vector2(r.position.x + 1.2, r.end.y - 2), Color(0, 0, 0, 0.45), 1.0)
	stroke(ci, r, 2, Color(0, 0, 0, 0.95), 1.0)
	line(ci, Vector2(r.position.x + 2, r.end.y + 1.6), Vector2(r.end.x - 2, r.end.y + 1.6), Color(1, 0.9, 0.7, 0.08), 0.8)


## Wooden button. state: normal | hover | pressed | disabled
static func button(ci: RID, r: Rect2, color: String, state: String) -> void:
	var pal: Array = BTN.get(color, BTN["brown"])
	var top := Color(pal[0])
	var bot := Color(pal[1])
	var edge := Color(pal[2])
	match state:
		"hover":
			top = top.lightened(0.14)
			bot = bot.lightened(0.10)
		"pressed":
			var t2 := top
			top = bot.darkened(0.05)
			bot = t2.darkened(0.1)
		"disabled":
			top = Color("#34363E")
			bot = Color("#24262C")
			edge = Color("#4A4D57")
	var off := 1.0 if state == "pressed" else 0.0
	fill(ci, Rect2(r.position + Vector2(0, 1), r.size), 3, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45))
	var rr := Rect2(r.position + Vector2(0, off), r.size - Vector2(0, 1))
	fill(ci, rr, 3, top, bot)
	stroke(ci, rr, 3, OUTLINE, 1.0)
	stroke(ci, rr.grow(-1.0), 2, Color(edge, 0.85), 1.0)
	if state != "pressed" and state != "disabled":
		line(ci, rr.position + Vector2(3, 2), Vector2(rr.end.x - 3, rr.position.y + 2), Color(1, 1, 1, 0.22), 1.0)


## Bronze medallion button (bottom bar of the hero panel, strip quick buttons).
static func medallion(ci: RID, c: Vector2, rad: float, state: String, active := false) -> void:
	circle(ci, c + Vector2(0, 1.2), rad + 1.0, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5))
	circle(ci, c, rad + 0.8, OUTLINE, OUTLINE)
	var top := BRONZE_HI if state == "hover" else BRONZE
	circle(ci, c, rad, top, BRONZE_LO)
	var inner_top := Color("#7E4A1D") if not active else Color("#B5652A")
	var inner_bot := Color("#4A2810") if not active else Color("#7A3A14")
	if state == "pressed":
		inner_top = inner_top.darkened(0.2)
	circle(ci, c, rad * 0.74, inner_bot, inner_top)
	ring(ci, c, rad * 0.74, Color(0, 0, 0, 0.6), 1.0)
	ring(ci, c, rad - 0.6, Color(1, 0.92, 0.7, 0.35), 0.8)


## Item slot: rarity-filled square (empty slots are dark wells).
static func slot(ci: RID, r: Rect2, rarity_col: Color, has_item: bool, hover: bool) -> void:
	if not has_item:
		fill(ci, r, 2, Color("#4A3826"), Color("#2A1E14"))
		var inner := r.grow(-1.4)
		fill(ci, inner, 1.5, Color("#130D09"), Color("#1E1610"))
		line(ci, inner.position + Vector2(1, 1.0), Vector2(inner.end.x - 1, inner.position.y + 1.0), Color(0, 0, 0, 0.65), 1.2)
		stroke(ci, r, 2, Color(0, 0, 0, 0.95), 1.0)
		line(ci, r.position + Vector2(2, 0.8), Vector2(r.end.x - 2, r.position.y + 0.8), Color(BRONZE_HI, 0.18), 0.6)
	else:
		fill(ci, r, 2, rarity_col.lightened(0.12), rarity_col.darkened(0.35))
		stroke(ci, r, 2, Color(0, 0, 0, 0.95), 1.0)
		stroke(ci, r.grow(-1.0), 1.5, Color(rarity_col.lightened(0.45), 0.55), 1.0)
	if hover:
		stroke(ci, r.grow(-0.5), 2, Color("#FFE08A"), 1.2)


static func rarity_fill(r: String) -> Color:
	match r:
		"magic":
			return Color("#2F63C2")
		"rare":
			return Color("#C9A227")
		"epic":
			return Color("#8A3FC9")
		"legendary":
			return Color("#D9692A")
		"set":
			return Color("#2F9A4A")
		"mythic":
			return Color("#C93A4F")
	return Color("#8C919C")
