class_name UISkin
extends RefCounted
## Vector UI skin: dark iron frames, red title ribbons, bronze trim, wooden buttons, rarity-filled slots.
## Everything is drawn with gradient polygons + anti-aliased strokes at native resolution, so it stays
## crisp at every UI scale. Used by UIFrame, GameStyleBox (buttons / tabs) and ItemSlot.

const IRON_TOP := Color("#4C505C")
const IRON_BOT := Color("#2A2C34")
const BODY_TOP := Color("#25272F")
const BODY_BOT := Color("#18191F")
const OUTLINE := Color("#08080B")
const BRONZE := Color("#C8913F")
const BRONZE_HI := Color("#F2CB7A")
const BRONZE_LO := Color("#7A4E1C")
const RIBBON_TOP := Color("#B92E33")
const RIBBON_BOT := Color("#76161B")
const BAND_TOP := Color("#43181B")
const BAND_BOT := Color("#26090C")
const PARCH_TOP := Color("#DCC293")
const PARCH_BOT := Color("#B99662")
const PARCH_EDGE := Color("#6A4824")
const INK := Color("#3A2412")
## wooden button palettes: [top, bottom, inner border, text]
const BTN := {
	"orange": ["#CF7E33", "#8C4716", "#F3C77A", "#FFF4E0"],
	"brown": ["#5C4130", "#36241A", "#94704A", "#EBDCC4"],
	"gold": ["#E5B44E", "#A5751F", "#FFE7A6", "#3A240E"],
	"blue": ["#4380CF", "#244A8C", "#A6CBFF", "#F2F7FF"],
	"red": ["#C03E3B", "#7B1E1E", "#F4A38C", "#FFF0EA"],
	"green": ["#46A15B", "#24673B", "#A6EBB2", "#F0FFF2"],
	"gray": ["#4B4F5B", "#2D3038", "#727787", "#D9DCE4"],
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
## Dark iron panel with bronze corner brackets and an optional red title ribbon band.
static func panel(ci: RID, r: Rect2, header_h := 0.0, ribbon_w := 0.0) -> void:
	fill(ci, Rect2(r.position + Vector2(0, 2), r.size), 5, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.5))
	fill(ci, r, 4, IRON_TOP, IRON_BOT)
	stroke(ci, r, 4, OUTLINE, 1.0)
	stroke(ci, r.grow(-1.0), 3, Color(1, 1, 1, 0.09), 1.0)
	var body := r.grow(-4.0)
	fill(ci, body, 2, BODY_TOP, BODY_BOT)
	stroke(ci, body, 2, Color(0, 0, 0, 0.85), 1.0)
	stroke(ci, body.grow(-1.0), 2, Color(1, 1, 1, 0.035), 1.0)
	if header_h > 0.0:
		var band := Rect2(body.position, Vector2(body.size.x, header_h))
		fill(ci, band, 2, BAND_TOP, BAND_BOT)
		# woven hatch on the band
		var x := band.position.x + 2.0
		while x < band.end.x - 2.0:
			line(ci, Vector2(x, band.position.y + 2), Vector2(minf(x + 6.0, band.end.x - 2), band.end.y - 3), Color(0.55, 0.18, 0.18, 0.35), 0.8)
			line(ci, Vector2(minf(x + 6.0, band.end.x - 2), band.position.y + 2), Vector2(x, band.end.y - 3), Color(0.55, 0.18, 0.18, 0.35), 0.8)
			x += 8.0
		line(ci, Vector2(band.position.x, band.end.y - 0.5), Vector2(band.end.x, band.end.y - 0.5), BRONZE_LO, 1.0)
		line(ci, Vector2(band.position.x, band.end.y + 0.5), Vector2(band.end.x, band.end.y + 0.5), Color(0, 0, 0, 0.8), 1.0)
		if ribbon_w > 0.0:
			ribbon(ci, Rect2(Vector2(r.position.x + (r.size.x - ribbon_w) / 2.0, band.position.y + 1.5), Vector2(ribbon_w, header_h - 3.0)))
	# bronze corner brackets
	for i in 4:
		var c: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][i]
		var dx := 1.0 if i == 0 or i == 3 else -1.0
		var dy := 1.0 if i < 2 else -1.0
		var p0: Vector2 = c + Vector2(dx * 2.5, dy * 2.5)
		var pts := PackedVector2Array([p0 + Vector2(dx * 9.0, 0), p0, p0 + Vector2(0, dy * 9.0)])
		RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([OUTLINE]), 3.2, true)
		RenderingServer.canvas_item_add_polyline(ci, pts, PackedColorArray([BRONZE]), 1.6, true)
		rivet(ci, p0 + Vector2(dx * 1.5, dy * 1.5), 1.5)


## Notched red ribbon used for panel titles.
static func ribbon(ci: RID, r: Rect2) -> void:
	var n := minf(5.0, r.size.y * 0.35)
	var pts := PackedVector2Array([r.position + Vector2(n, 0), Vector2(r.end.x - n, r.position.y), Vector2(r.end.x, r.position.y + r.size.y * 0.5),
		Vector2(r.end.x - n, r.end.y), Vector2(r.position.x + n, r.end.y), Vector2(r.position.x, r.position.y + r.size.y * 0.5)])
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
	stroke(ci, r.grow(-1.5), 2, Color(0.42, 0.28, 0.13, 0.35), 2.0)
	stroke(ci, r, 2, PARCH_EDGE, 1.0)
	stroke(ci, r.grow(1.0), 3, Color(0, 0, 0, 0.7), 1.0)


static func well(ci: RID, r: Rect2) -> void:
	fill(ci, r, 2, Color("#121318"), Color("#1A1B21"))
	stroke(ci, r, 2, Color(0, 0, 0, 0.9), 1.0)
	line(ci, r.position + Vector2(2, r.size.y + 0.5), Vector2(r.end.x - 2, r.end.y + 0.5), Color(1, 1, 1, 0.06), 1.0)


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
		fill(ci, r, 2, Color("#1C1E25"), Color("#14151A"))
		stroke(ci, r, 2, Color(0, 0, 0, 0.95), 1.0)
		line(ci, r.position + Vector2(2, 1.5), Vector2(r.end.x - 2, r.position.y + 1.5), Color(0, 0, 0, 0.5), 1.0)
		line(ci, Vector2(r.position.x + 2, r.end.y - 1), Vector2(r.end.x - 2, r.end.y - 1), Color(1, 1, 1, 0.05), 1.0)
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
