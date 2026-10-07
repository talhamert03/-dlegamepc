class_name SkillFx
extends Node2D
## Signature effects of the class skills, drawn as vector shapes with an additive glow and kept compact so
## they read on the small battle strip: rains (blades, ice, arrows, skulls, blizzard), light columns
## (holy beam, comet, sunburst, thunder), ground waves (shockwave, earth split, sonic wave), domes and
## auras (aegis, sanctuary, anthem), blade work (blade storm, fan of knives, shadow twin, death mark) and
## orbs (arcane orb, soul siphon, bone prison, frost arrow).

const KINDS := {
	"sword_rain": 1.2, "ice_rain": 1.25, "arrow_volley": 1.1, "skull_storm": 1.2, "blizzard": 1.8,
	"holy_beam": 0.8, "comet": 1.2, "sun_burst": 1.2, "thunder_chord": 1.0,
	"shockwave": 0.9, "earth_split": 1.2, "sonic_wave": 0.9,
	"aegis": 1.4, "sanctuary": 1.5, "anthem": 1.4,
	"blade_storm": 1.0, "blade_fan": 0.8, "shadow_strike": 0.9, "death_mark": 1.1,
	"arcane_orb": 1.0, "soul_siphon": 1.1, "bone_prison": 1.3, "frost_arrow": 0.7,
}
const GROUND := 64.0

static var _add: CanvasItemMaterial

var kind := ""
var src := Vector2.ZERO
var tgts: Array = []          # Vector2 feet positions of the targets (enemies or allies)
var t := 0.0
var life := 1.0
var _seed := 0.0
var _drops: Array = []        # [x, delay, size] per falling object


func setup(k: String, source: Vector2, targets: Array) -> void:
	kind = k
	src = source
	tgts = targets
	life = float(KINDS.get(k, 1.0))
	_seed = randf() * 100.0
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	z_index = 24
	var per := {"sword_rain": 3, "ice_rain": 4, "arrow_volley": 5, "skull_storm": 2, "blizzard": 8}.get(k, 0)
	for p in tgts:
		for i in per:
			_drops.append([p.x + randf_range(-10, 10), randf_range(0.0, life * 0.45), randf_range(1.3, 1.8)])


static func handles(k: String) -> bool:
	return KINDS.has(k)


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()


func _fade() -> float:
	return clampf((life - t) / 0.25, 0.0, 1.0)


func _draw() -> void:
	match kind:
		"sword_rain":
			_rain(Color("#E8EEF8"), "sword")
		"ice_rain":
			_rain(Color("#9FE4FF"), "ice")
		"arrow_volley":
			_rain(Color("#F2E3B8"), "arrow")
		"skull_storm":
			_rain(Color("#C58BFF"), "skull")
		"blizzard":
			_blizzard()
		"holy_beam":
			for p in tgts:
				_column(p, Color("#FFE38A"), 9.0)
		"sun_burst":
			_sun_burst()
		"comet":
			_comet()
		"thunder_chord":
			for i in tgts.size():
				_bolt(tgts[i], Color("#FFF27A"), i * 0.06)
		"shockwave":
			_ground_ring(Color("#D9B27A"), 1.0)
		"earth_split":
			_earth_split()
		"sonic_wave":
			_sonic()
		"aegis":
			for p in tgts:
				_dome(p, Color("#7FB8FF"), true)
		"sanctuary":
			for p in tgts:
				_dome(p, Color("#FFE38A"), false)
		"anthem":
			_anthem()
		"blade_storm":
			_blade_storm()
		"blade_fan":
			_blade_fan()
		"shadow_strike":
			_shadow_strike()
		"death_mark":
			_death_mark()
		"arcane_orb":
			_orb_burst(Color("#8FB8FF"))
		"soul_siphon":
			_siphon()
		"bone_prison":
			_bones()
		"frost_arrow":
			for p in tgts:
				_impact_star(p + Vector2(0, -12), Color("#BFEFFF"), 1.0)


# ------------------------------------------------------------------ families
func _rain(col: Color, what: String) -> void:
	var fall := 0.32
	# a soft tinted glow over the struck area while the rain lasts
	if tgts.size() > 0:
		var g := sin(clampf(t / life, 0.0, 1.0) * PI)
		for p in tgts:
			draw_circle(Vector2(p.x, GROUND - 14.0), 18.0, Color(col, 0.07 * g))
	for d in _drops:
		var lt: float = t - float(d[1])
		if lt < 0.0:
			continue
		var x: float = d[0]
		var s: float = d[2]
		if lt < fall:
			var k := lt / fall
			var y := lerpf(-8.0, GROUND - 6.0, k * k)
			var p := Vector2(x + (1.0 - k) * 6.0, y)
			_falling(p, col, what, s)
		else:
			var k2 := clampf((lt - fall) / 0.3, 0.0, 1.0)
			var p2 := Vector2(x, GROUND - 6.0)
			# impact: a flash, a ring and a few shards
			draw_circle(p2, 2.0 + 6.0 * k2, Color(col, 0.35 * (1.0 - k2)))
			draw_arc(p2 + Vector2(0, 4), 3.0 + 8.0 * k2, PI, TAU, 12, Color(col, 0.6 * (1.0 - k2)), 1.0, true)
			for j in 3:
				var a := -PI * (0.2 + 0.3 * j)
				draw_circle(p2 + Vector2(cos(a), sin(a)) * 7.0 * k2, 0.8, Color(col, 1.0 - k2))
			if what == "sword" and k2 < 1.0:
				_falling(p2 + Vector2(0, -2), col, what, s, 1.0 - k2)


func _falling(p: Vector2, col: Color, what: String, s: float, alpha := 1.0) -> void:
	match what:
		"sword":
			var tip := p + Vector2(-1.5, 6) * s
			draw_line(p + Vector2(1.2, -5) * s, tip, Color(col, alpha), 1.6, true)
			draw_line(p + Vector2(-1.5, -2.5) * s, p + Vector2(3.5, -2.0) * s, Color("#C8913F", alpha), 1.2, true)
			draw_line(p + Vector2(1.6, -5) * s, p + Vector2(2.0, -8) * s, Color("#7A4E1C", alpha), 1.2, true)
			draw_line(p + Vector2(1.2, -14) * s, p + Vector2(1.2, -6) * s, Color(col, 0.25 * alpha), 1.0, true)
		"ice":
			var pts := PackedVector2Array([p + Vector2(0, 5) * s, p + Vector2(1.6, -2) * s, p + Vector2(0, -4) * s, p + Vector2(-1.6, -2) * s])
			draw_colored_polygon(pts, Color(col, 0.95 * alpha))
			draw_line(p + Vector2(0, -3) * s, p + Vector2(0, 4) * s, Color(1, 1, 1, 0.8 * alpha), 0.6, true)
			draw_line(p + Vector2(0, -12) * s, p + Vector2(0, -5) * s, Color(col, 0.3 * alpha), 1.0, true)
		"arrow":
			var dir := Vector2(-0.35, 1).normalized()
			draw_line(p - dir * 6.0, p + dir * 3.0, Color("#7A5032", alpha), 1.1, true)
			draw_colored_polygon(PackedVector2Array([p + dir * 5.0, p + dir * 2.5 + dir.orthogonal() * 1.4, p + dir * 2.5 - dir.orthogonal() * 1.4]), Color(1, 1, 1, alpha))
			draw_line(p - dir * 6.0, p - dir * 4.0 + dir.orthogonal() * 1.5, Color(col, alpha), 1.0, true)
		"skull":
			draw_circle(p, 6.0 * s, Color(col, 0.2 * alpha))
			draw_circle(p, 3.0 * s, Color("#EDE3FF", alpha))
			draw_rect(Rect2(p + Vector2(-1.6, 1.5) * s, Vector2(3.2, 2) * s), Color("#EDE3FF", alpha))
			draw_circle(p + Vector2(-1.1, -0.3) * s, 0.8 * s, Color("#3A0A5A", alpha))
			draw_circle(p + Vector2(1.1, -0.3) * s, 0.8 * s, Color("#3A0A5A", alpha))
			draw_line(p + Vector2(0, -4) * s, p + Vector2(4, -11) * s, Color(col, 0.35 * alpha), 2.0, true)


func _blizzard() -> void:
	var a := sin(clampf(t / life, 0.0, 1.0) * PI)
	# cold haze over the enemy side
	if tgts.size() > 0:
		var x0: float = tgts[0].x - 20.0
		var x1: float = tgts[-1].x + 20.0
		var hz := Color(0.75, 0.9, 1.0, 0.14 * a)
		var xl := minf(x0, x1)
		var xr := maxf(x0, x1)
		draw_polygon(PackedVector2Array([Vector2(xl, 6), Vector2(xr, 6), Vector2(xr, GROUND), Vector2(xl, GROUND)]),
			PackedColorArray([Color(hz, 0.0), Color(hz, 0.0), hz, hz]))
		for i in 14:
			var px := fposmod(_seed * 7.0 + i * 23.0 - t * 90.0, maxf(30.0, absf(x1 - x0))) + minf(x0, x1)
			var py := fposmod(i * 17.0 + t * 70.0, GROUND - 8.0) + 6.0
			draw_line(Vector2(px, py), Vector2(px + 5, py - 2), Color(1, 1, 1, 0.55 * a), 1.0, true)
	_rain(Color("#CFF4FF"), "ice")


## Light shaft from `top` to the ground, brightest in the middle and fading to both edges (no hard rim).
func _vbar(cx: float, hw: float, top: float, c: Color) -> void:
	var clear := Color(c, 0.0)
	draw_polygon(PackedVector2Array([Vector2(cx - hw, top), Vector2(cx, top), Vector2(cx, GROUND), Vector2(cx - hw, GROUND)]),
		PackedColorArray([clear, c, c, clear]))
	draw_polygon(PackedVector2Array([Vector2(cx, top), Vector2(cx + hw, top), Vector2(cx + hw, GROUND), Vector2(cx, GROUND)]),
		PackedColorArray([c, clear, clear, c]))


func _column(p: Vector2, col: Color, w: float, delay := 0.0) -> void:
	var lt := t - delay
	if lt < 0.0:
		return
	var k := clampf(lt / 0.12, 0.0, 1.0)
	var f := clampf((life - lt) / 0.4, 0.0, 1.0)
	var top := lerpf(GROUND, -4.0, k)
	_vbar(p.x, w * 1.6, top, Color(col, 0.18 * f))
	_vbar(p.x, w * 0.6, top, Color(col, 0.55 * f))
	_vbar(p.x, w * 0.22, top, Color(1, 1, 1, 0.85 * f))
	draw_circle(Vector2(p.x, GROUND - 2), w * (1.2 + 0.6 * sin(lt * 30.0)), Color(col, 0.35 * f))
	for i in 4:
		var yy := fposmod(lt * 80.0 + i * 15.0, GROUND)
		draw_circle(Vector2(p.x + sin(i * 2.1 + lt * 9.0) * w, GROUND - yy), 0.9, Color(1, 1, 0.9, 0.8 * f))


func _sun_burst() -> void:
	var c := Vector2(src.x + 40.0, 18.0)
	if tgts.size() > 0:
		c = Vector2((tgts[0].x + tgts[-1].x) / 2.0, 16.0)
	var k := clampf(t / 0.3, 0.0, 1.0)
	var f := _fade()
	draw_circle(c, 6.0 + 4.0 * k, Color("#FFE38A", 0.5 * f))
	draw_circle(c, 3.5 + 2.0 * k, Color(1, 1, 0.9, 0.9 * f))
	for i in 12:
		var a := i * TAU / 12.0 + t * 0.8
		draw_line(c + Vector2(cos(a), sin(a)) * 9.0, c + Vector2(cos(a), sin(a)) * (12.0 + 10.0 * k), Color("#FFE38A", 0.6 * f), 1.2, true)
	for i in tgts.size():
		_column(tgts[i], Color("#FFE38A"), 4.0, 0.25 + i * 0.05)


func _comet() -> void:
	var p: Vector2 = tgts[0] if tgts.size() > 0 else src + Vector2(80, 0)
	var fall := 0.45
	if t < fall:
		var k := t / fall
		var a := Vector2(p.x - 70.0, -20.0)
		var b := Vector2(p.x, GROUND - 6.0)
		var h := a.lerp(b, k * k)
		for i in 8:
			var q := a.lerp(b, maxf(0.0, k * k - i * 0.035))
			draw_circle(q, 4.0 - i * 0.4, Color("#FFF27A", 0.35 - i * 0.04))
		draw_circle(h, 3.5, Color(1, 1, 0.85))
		draw_circle(h, 6.0, Color("#FFF27A", 0.35))
	else:
		_impact_star(Vector2(p.x, GROUND - 6.0), Color("#FFF27A"), 2.0, fall)


func _bolt(p: Vector2, col: Color, delay: float) -> void:
	var lt := t - delay
	if lt < 0.0 or lt > 0.5:
		return
	var f := 1.0 - lt / 0.5
	var pts := PackedVector2Array()
	var y := -2.0
	var x := p.x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed * 1000.0 + p.x) + int(lt * 20.0)
	while y < GROUND - 4.0:
		pts.append(Vector2(x, y))
		y += rng.randf_range(5.0, 9.0)
		x = p.x + rng.randf_range(-4.0, 4.0)
	pts.append(Vector2(p.x, GROUND - 4.0))
	draw_polyline(pts, Color(col, 0.35 * f), 3.5, true)
	draw_polyline(pts, Color(1, 1, 1, 0.9 * f), 1.0, true)
	draw_circle(Vector2(p.x, GROUND - 4.0), 5.0 * f + 2.0, Color(col, 0.4 * f))


func _ground_ring(col: Color, power: float) -> void:
	var c := Vector2(src.x + 14.0, GROUND - 1.0)
	var k := clampf(t / life, 0.0, 1.0)
	var r := 10.0 + 170.0 * k * power
	var f := 1.0 - k
	draw_set_transform(c, 0.0, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col, 0.7 * f), 3.0, true)
	draw_arc(Vector2.ZERO, r * 0.85, 0, TAU, 48, Color(col, 0.3 * f), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 10:
		var x := c.x + r * (0.2 + i * 0.09)
		draw_circle(Vector2(x, GROUND - 2.0 - absf(sin(i * 1.7)) * 6.0 * f), 1.2, Color(col, 0.7 * f))


func _earth_split() -> void:
	var x0 := src.x + 10.0
	var x1: float = (tgts[-1].x + 16.0) if tgts.size() > 0 else x0 + 160.0
	var k := clampf(t / 0.4, 0.0, 1.0)
	var f := _fade()
	var xe := lerpf(x0, x1, k)
	var pts := PackedVector2Array()
	var x := x0
	var i := 0
	while x < xe:
		pts.append(Vector2(x, GROUND - 1.0 + (2.0 if i % 2 == 0 else -1.0)))
		x += 6.0
		i += 1
	pts.append(Vector2(xe, GROUND - 1.0))
	if pts.size() >= 2:
		draw_polyline(pts, Color("#FF7A33", 0.5 * f), 3.0, true)
		draw_polyline(pts, Color("#2A120A", f), 1.2, true)
	for p in tgts:
		if p.x <= xe:
			for j in 4:
				var h := 4.0 + j * 2.0
				var bx: float = p.x - 6.0 + j * 4.0
				draw_colored_polygon(PackedVector2Array([Vector2(bx - 2, GROUND), Vector2(bx, GROUND - h * f), Vector2(bx + 2, GROUND)]), Color("#8A6A4A", f))


func _sonic() -> void:
	var k := clampf(t / life, 0.0, 1.0)
	var f := 1.0 - k
	for i in 3:
		var kk := clampf(k * 1.2 - i * 0.12, 0.0, 1.0)
		var x := src.x + 10.0 + 220.0 * kk
		var r := 10.0 + 6.0 * i
		draw_arc(Vector2(x, GROUND - 16.0), r, -0.9, 0.9, 16, Color("#7FE8FF", 0.75 * f), 1.6, true)
		draw_arc(Vector2(x, GROUND - 16.0), r + 3.0, -0.7, 0.7, 12, Color(1, 1, 1, 0.35 * f), 1.0, true)


func _dome(p: Vector2, col: Color, hexes: bool) -> void:
	var k := clampf(t / 0.25, 0.0, 1.0)
	var f := _fade()
	var c := p + Vector2(0, -2)
	var r := 15.0 * k
	draw_set_transform(c, 0.0, Vector2(1.0, 1.15))
	draw_circle(Vector2.ZERO, r, Color(col, 0.10 * f))
	draw_arc(Vector2.ZERO, r, PI, TAU, 24, Color(col, 0.75 * f), 1.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hexes:
		for i in 5:
			var a := PI + (i + 0.5) * PI / 5.0
			draw_circle(c + Vector2(cos(a) * r * 0.75, sin(a) * r * 0.86), 1.4, Color(1, 1, 1, 0.6 * f))
	else:
		for i in 4:
			var yy := fposmod(t * 30.0 + i * 6.0, 22.0)
			draw_circle(c + Vector2(sin(i * 2.3) * 8.0, -yy), 1.0, Color(1, 1, 0.8, 0.8 * f))
	draw_set_transform(c + Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(col, 0.6 * f), 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _anthem() -> void:
	var f := _fade()
	for i in tgts.size():
		var p: Vector2 = tgts[i]
		draw_set_transform(p + Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, 10.0, 0, TAU, 20, Color("#FFD35A", 0.55 * f), 1.2, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for j in 2:
			var lt := fposmod(t + j * 0.5 + i * 0.13, 1.0)
			var q := p + Vector2(sin(lt * 6.0 + i) * 5.0, -8.0 - lt * 26.0)
			var a := (1.0 - lt) * f
			draw_circle(q, 1.4, Color("#FFD35A", a))
			draw_line(q + Vector2(1.3, 0), q + Vector2(1.3, -4.5), Color("#FFD35A", a), 0.8, true)


func _blade_storm() -> void:
	var c: Vector2 = (tgts[0] if tgts.size() > 0 else src + Vector2(30, 0)) + Vector2(-6, -12)
	var f := _fade()
	for i in 3:
		var a := t * 22.0 + i * TAU / 3.0
		draw_arc(c, 13.0 + i * 2.0, a, a + 2.0, 12, Color("#E8EEF8", 0.75 * f), 1.6 - i * 0.3, true)
		draw_arc(c, 13.0 + i * 2.0, a + 2.0, a + 2.6, 6, Color("#FF8A4A", 0.4 * f), 1.0, true)


func _blade_fan() -> void:
	var f := _fade()
	var k := clampf(t / 0.5, 0.0, 1.0)
	var o := src + Vector2(8, -14)
	for i in 7:
		var a := -0.6 + i * 0.2
		var d := Vector2(cos(a), sin(a))
		var p := o + d * (12.0 + 150.0 * k)
		draw_line(p - d * 5.0, p + d * 2.0, Color("#E8EEF8", f), 1.2, true)
		draw_line(p - d * 12.0, p - d * 5.0, Color("#C81E3A", 0.35 * f), 1.0, true)


func _shadow_strike() -> void:
	var p: Vector2 = tgts[0] if tgts.size() > 0 else src
	var f := _fade()
	for i in 3:
		var lt := t - i * 0.18
		if lt < 0.0 or lt > 0.4:
			continue
		var k := lt / 0.4
		var a := -0.8 + i * 0.8
		var c := p + Vector2(0, -12)
		var d := Vector2(cos(a), sin(a)) * 14.0
		draw_line(c - d * (1.0 - k), c + d * k, Color("#B266FF", 0.9 * (1.0 - k) * f), 2.0, true)
		draw_line(c - d * (1.0 - k), c + d * k, Color(1, 1, 1, 0.6 * (1.0 - k) * f), 0.7, true)
		draw_circle(c - Vector2(10 - i * 4, 0), 4.0, Color("#2A0A3A", 0.35 * (1.0 - k)))


func _death_mark() -> void:
	var p: Vector2 = (tgts[0] if tgts.size() > 0 else src) + Vector2(0, -36)
	var f := _fade()
	var k := clampf(t / 0.3, 0.0, 1.0)
	draw_arc(p, 6.0 * k, 0, TAU, 20, Color("#FF3B4E", 0.8 * f), 1.2, true)
	for i in 3:
		var a := t * 3.0 + i * TAU / 3.0
		draw_line(p + Vector2(cos(a), sin(a)) * 3.0 * k, p + Vector2(cos(a), sin(a)) * 8.0 * k, Color("#FF3B4E", 0.7 * f), 1.0, true)
	if t > 0.5:
		var k2 := clampf((t - 0.5) / 0.25, 0.0, 1.0)
		var c := p + Vector2(0, 24)
		draw_line(c + Vector2(-10, -10) * (1.0 - k2), c + Vector2(10, 10) * k2, Color("#FF3B4E", f), 2.0, true)
		draw_line(c + Vector2(-10, -10) * (1.0 - k2), c + Vector2(10, 10) * k2, Color(1, 1, 1, 0.7 * f), 0.7, true)


func _orb_burst(col: Color) -> void:
	var p: Vector2 = (tgts[0] if tgts.size() > 0 else src) + Vector2(0, -14)
	var travel := 0.35
	if t < travel:
		var k := t / travel
		var q := (src + Vector2(8, -14)).lerp(p, k)
		draw_circle(q, 6.0, Color(col, 0.25))
		draw_circle(q, 3.5, col)
		draw_circle(q, 1.8, Color(1, 1, 1, 0.9))
	else:
		_impact_star(p, col, 1.6, travel)


func _siphon() -> void:
	var f := _fade()
	for p in tgts:
		for i in 5:
			var lt := fposmod(t * 1.4 + i * 0.2, 1.0)
			var a: Vector2 = p + Vector2(0, -14)
			var b: Vector2 = src + Vector2(0, -16)
			var q: Vector2 = a.lerp(b, lt) + Vector2(0, sin(lt * PI) * -14.0 + sin(i * 3.0 + t * 8.0) * 2.0)
			draw_circle(q, 2.0 * (1.0 - lt * 0.5), Color("#B266FF", 0.55 * f))
			draw_circle(q, 0.9, Color("#F0E0FF", 0.9 * f))


func _bones() -> void:
	var f := _fade()
	var k := clampf(t / 0.25, 0.0, 1.0)
	for p in tgts:
		for j in 5:
			var bx: float = p.x - 10.0 + j * 5.0
			var h := (10.0 + (j % 2) * 5.0) * k
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 1.6, GROUND), Vector2(bx, GROUND - h), Vector2(bx + 1.6, GROUND)]), Color("#EDE6D6", f))
			draw_line(Vector2(bx, GROUND - h), Vector2(bx + 0.6, GROUND - h + 3), Color("#8A7A6A", f), 0.6, true)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, Color("#B266FF", 0.6 * f), 1.2, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _impact_star(p: Vector2, col: Color, size: float, start := 0.0) -> void:
	var lt := t - start
	var k := clampf(lt / 0.35, 0.0, 1.0)
	var f := 1.0 - k
	draw_circle(p, (4.0 + 10.0 * k) * size, Color(col, 0.25 * f))
	draw_circle(p, (2.0 + 3.0 * (1.0 - k)) * size, Color(1, 1, 1, 0.8 * f))
	for i in 8:
		var a := i * TAU / 8.0 + _seed
		var d := Vector2(cos(a), sin(a))
		draw_line(p + d * 3.0 * size, p + d * (5.0 + 12.0 * k) * size, Color(col, 0.8 * f), 1.0, true)
