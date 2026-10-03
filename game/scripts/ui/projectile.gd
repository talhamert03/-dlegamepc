class_name Projectile
extends Node2D
## A basic attack in flight, drawn as vector shapes with an additive glow so every class reads at a glance:
## arrows with fletching, the mage's blue arcane orb, the cleric's thin golden beam (one flash per hit),
## the necromancer's chaos orb, the bard's notes, fireballs, ice shards, enemy bolts.

const TRAIL := 7
static var _add_mat: CanvasItemMaterial

var kind := "arrow"
var from := Vector2.ZERO
var to := Vector2.ZERO
var travel := 0.3
var t := 0.0
var arc := 0.0
var color := Color.WHITE
var _trail: Array = []
var _beam := false
var _life := 0.0


func setup(k: String, a: Vector2, b: Vector2, dur: float) -> void:
	kind = k
	from = a
	to = b
	travel = max(0.05, dur)
	arc = 9.0 if k.begins_with("arrow") else (4.0 if k == "note" else 0.0)
	_beam = k == "bolt_holy"
	if _beam:
		# a beam lands at once and lingers a moment
		_life = 0.28
		position = Vector2.ZERO
	else:
		position = from
	match k:
		"arrow", "arrow_enemy":
			color = Color("#F2E3B8")
		"bolt_arcane":
			color = Color("#6FB7FF")
		"fireball":
			color = Color("#FF8A3D")
		"bolt_chaos":
			color = Color("#B266FF")
		"bolt_holy":
			color = Color("#FFE38A")
		"note":
			color = Color("#9FF3C0")
		"ice":
			color = Color("#BFEFFF")
		"bolt_enemy":
			color = Color("#FF5A8A")
		_:
			color = Color.WHITE
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	z_index = 22


func _process(delta: float) -> void:
	t += delta
	if _beam:
		if t >= _life:
			queue_free()
		queue_redraw()
		return
	var k: float = min(1.0, t / travel)
	var p := from.lerp(to, k)
	p.y -= sin(k * PI) * arc
	_trail.push_front(p)
	if _trail.size() > TRAIL:
		_trail.pop_back()
	position = p
	if k >= 1.0:
		queue_free()
	queue_redraw()


func _dir() -> Vector2:
	if _trail.size() >= 2:
		var d: Vector2 = _trail[0] - _trail[1]
		if d.length() > 0.01:
			return d.normalized()
	return (to - from).normalized()


func _draw() -> void:
	if _beam:
		_draw_beam()
		return
	var dir := _dir()
	match kind:
		"arrow", "arrow_enemy":
			_draw_arrow(dir)
		"note":
			_draw_note()
		"ice":
			_draw_shard(dir)
		_:
			_draw_orb(dir)


func _draw_arrow(dir: Vector2) -> void:
	var n := dir.orthogonal()
	var tip := dir * 4.0
	var tail := -dir * 6.0
	# faint motion streak
	draw_line(tail, tail - dir * 6.0, Color(1, 1, 1, 0.12), 1.0, true)
	draw_line(tail, tip, Color("#7A5032"), 1.2, true)
	draw_colored_polygon(PackedVector2Array([tip + dir * 2.5, tip + n * 1.6, tip - n * 1.6]), Color("#E6E8F0"))
	draw_colored_polygon(PackedVector2Array([tail, tail - dir * 2.5 + n * 1.8, tail + dir * 1.0]), color)
	draw_colored_polygon(PackedVector2Array([tail, tail - dir * 2.5 - n * 1.8, tail + dir * 1.0]), color.darkened(0.2))


func _draw_orb(dir: Vector2) -> void:
	var r := 2.6 if kind != "fireball" else 3.2
	# glowing trail (local space: trail points relative to the head)
	for i in range(_trail.size() - 1, 0, -1):
		var q: Vector2 = _trail[i] - position
		var f := 1.0 - float(i) / TRAIL
		draw_circle(q, r * (0.35 + 0.55 * f), Color(color, 0.22 * f))
	draw_circle(Vector2.ZERO, r * 2.4, Color(color, 0.12))
	draw_circle(Vector2.ZERO, r * 1.6, Color(color, 0.28))
	draw_circle(Vector2.ZERO, r, color)
	draw_circle(Vector2.ZERO, r * 0.55, color.lightened(0.6))
	if kind == "bolt_chaos":
		var a := t * 14.0
		for k in 3:
			var ang := a + k * TAU / 3.0
			draw_circle(Vector2(cos(ang), sin(ang)) * r * 1.5, 0.7, Color("#E8C8FF", 0.8))
		draw_circle(Vector2.ZERO, r * 0.35, Color("#2A0A3A"))
	elif kind == "bolt_arcane":
		# twinkle
		var s := 2.0 + sin(t * 40.0) * 1.0
		draw_line(Vector2(-s, 0), Vector2(s, 0), Color(1, 1, 1, 0.7), 0.8, true)
		draw_line(Vector2(0, -s), Vector2(0, s), Color(1, 1, 1, 0.7), 0.8, true)
	elif kind == "fireball":
		for k in 3:
			var q2 := -dir * (3.0 + k * 2.5) + dir.orthogonal() * sin(t * 30.0 + k) * 1.2
			draw_circle(q2, 1.8 - k * 0.4, Color("#FFD27A", 0.6 - k * 0.15))


func _draw_shard(dir: Vector2) -> void:
	var n := dir.orthogonal()
	draw_circle(Vector2.ZERO, 4.0, Color(color, 0.15))
	draw_colored_polygon(PackedVector2Array([dir * 5.0, n * 1.6, -dir * 4.0, -n * 1.6]), color)
	draw_line(-dir * 3.0, dir * 4.0, Color(1, 1, 1, 0.8), 0.6, true)
	for i in range(1, _trail.size()):
		var q: Vector2 = _trail[i] - position
		draw_circle(q, 0.7, Color(color, 0.4 * (1.0 - float(i) / TRAIL)))


func _draw_note() -> void:
	var wob := sin(t * 18.0) * 1.2
	draw_circle(Vector2(0, wob), 3.5, Color(color, 0.15))
	draw_circle(Vector2(-1, 1 + wob), 1.5, color)
	draw_line(Vector2(0.4, 1 + wob), Vector2(0.4, -4 + wob), color, 0.9, true)
	draw_line(Vector2(0.4, -4 + wob), Vector2(2.6, -3 + wob), color, 0.9, true)


func _draw_beam() -> void:
	var f := 1.0 - clampf(t / _life, 0.0, 1.0)
	var a := from
	var b := to
	var w := 1.0 + 1.6 * f
	draw_line(a, b, Color(color, 0.18 * f), w * 3.0, true)
	draw_line(a, b, Color(color, 0.55 * f), w, true)
	draw_line(a, b, Color(1, 1, 1, 0.85 * f), maxf(0.6, w * 0.35), true)
	draw_circle(b, 2.0 + 4.0 * (1.0 - f), Color(color, 0.35 * f))
	draw_circle(a, 1.5 + 1.5 * f, Color(color, 0.5 * f))
