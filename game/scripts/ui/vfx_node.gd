class_name VfxNode
extends Node2D
## Lightweight procedural pixel VFX (no textures needed). Each effect lives `life` seconds.

var kind := "hit"
var t := 0.0
var life := 0.4
var color := Color.WHITE
var size := 8.0
var data: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _parts: Array = []


func setup(k: String, c: Color, s: float, d: Dictionary = {}) -> void:
	kind = k
	color = c
	size = s
	data = d
	_rng.randomize()
	match kind:
		"hit":
			life = 0.22
		"crit":
			life = 0.3
		"slash":
			life = 0.28
		"heal", "levelup":
			life = 0.9 if kind == "levelup" else 0.7
			for i in (14 if kind == "levelup" else 8):
				_parts.append([Vector2(_rng.randf_range(-size, size), _rng.randf_range(-4, 0)), _rng.randf_range(14, 34), _rng.randf_range(0, 0.3)])
		"burst", "explosion", "ice", "poison", "holy", "dark":
			life = 0.45
			for i in 10:
				var a := _rng.randf() * TAU
				_parts.append([Vector2.ZERO, Vector2(cos(a), sin(a) * 0.6) * _rng.randf_range(10, 28), _rng.randf_range(1, 2)])
		"lightning":
			life = 0.3
		"loot_beam":
			life = 2.2
		"telegraph":
			life = float(d.get("t", 1.5))
		"notes":
			life = 0.9
			for i in 4:
				_parts.append([Vector2(_rng.randf_range(-8, 8), -10), _rng.randf_range(-6, 6), _rng.randf_range(0, 0.3)])
		"shield":
			life = 0.6
		"coin":
			life = 0.5
		"meteor":
			life = 0.6
		"rain":
			life = 0.8
			for i in 14:
				_parts.append([Vector2(_rng.randf_range(-size, size), _rng.randf_range(-60, -30)), _rng.randf_range(0, 0.4)])
		"summon":
			life = 0.6
		"smoke":
			life = 0.6
		_:
			life = 0.4


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
		return
	queue_redraw()


func _px(p: Vector2, c: Color, s := 1.0) -> void:
	draw_rect(Rect2(round(p.x), round(p.y), s, s), c)


func _draw() -> void:
	var k := t / life
	var a := 1.0 - k
	match kind:
		"hit":
			var r := 2.0 + k * 6.0
			for i in 6:
				var ang := i * TAU / 6.0 + 0.3
				_px(Vector2(cos(ang), sin(ang)) * r, Color(color, a), 2 if k < 0.4 else 1)
			_px(Vector2(-1, -1), Color(1, 1, 1, a), 2)
		"crit":
			var r2 := 3.0 + k * 9.0
			for i in 8:
				var ang2 := i * TAU / 8.0
				var p := Vector2(cos(ang2), sin(ang2)) * r2
				draw_line(p * 0.4, p, Color(1.0, 0.85, 0.3, a), 1.0)
			_px(Vector2(-1, -1), Color(1, 1, 1, a), 3)
		"slash":
			var arc := 10.0 + size * 0.5
			for i in 9:
				var f := float(i) / 8.0
				if f > k * 1.6:
					break
				var ang3: float = lerp(-1.2, 1.0, f)
				var p2 := Vector2(cos(ang3) * arc * 0.6, sin(ang3) * arc)
				_px(p2, Color(color, a), 2)
				_px(p2 + Vector2(-2, 0), Color(color.lightened(0.5), a * 0.6), 1)
		"heal", "levelup":
			for p in _parts:
				var tt: float = max(0.0, t - float(p[2]))
				var pos: Vector2 = p[0] + Vector2(0, -tt * float(p[1]))
				var c := color if kind == "heal" else Color("#FFE08A")
				_px(pos, Color(c, a), 1)
				if int(tt * 20) % 2 == 0:
					_px(pos + Vector2(0, -1), Color(1, 1, 1, a * 0.6), 1)
			if kind == "levelup":
				var h: float = 40.0 * min(1.0, k * 3.0)
				draw_rect(Rect2(-5, -h, 10, h), Color(1.0, 0.85, 0.4, a * 0.35))
				draw_rect(Rect2(-2, -h, 4, h), Color(1.0, 0.95, 0.7, a * 0.5))
		"burst", "explosion", "ice", "poison", "holy", "dark":
			var rr := size * (0.3 + k)
			draw_circle(Vector2.ZERO, rr * 0.6, Color(color, a * 0.35))
			for p in _parts:
				var pos2: Vector2 = (p[1] as Vector2) * k
				_px(pos2, Color(color.lightened(0.3), a), float(p[2]))
		"lightning":
			var y := -80.0
			var x := 0.0
			while y < 0:
				var nx := x + _rng.randf_range(-4, 4)
				var ny: float = min(0.0, y + _rng.randf_range(6, 12))
				draw_line(Vector2(x, y), Vector2(nx, ny), Color(1, 1, 0.6, a), 1.0)
				x = nx
				y = ny
			draw_circle(Vector2.ZERO, 4 * a, Color(1, 1, 0.8, a * 0.6))
		"loot_beam":
			var h2: float = 70.0
			var pulse := 0.6 + 0.4 * sin(t * 8.0)
			var fade: float = min(1.0, (life - t) * 2.0)
			draw_rect(Rect2(-3, -h2, 6, h2), Color(color, 0.18 * fade * pulse))
			draw_rect(Rect2(-1, -h2, 2, h2), Color(color.lightened(0.4), 0.55 * fade))
			for i in 5:
				var yy := -fmod(t * 30.0 + i * 14.0, h2)
				_px(Vector2(_rng.randf_range(-3, 3), yy), Color(color.lightened(0.6), fade))
		"telegraph":
			var blink := 0.35 + 0.35 * sin(t * 14.0)
			var w := size
			draw_rect(Rect2(-w, -2, w * 2, 3), Color(1.0, 0.2, 0.15, blink))
			draw_rect(Rect2(-w, -2, w * 2, 1), Color(1.0, 0.6, 0.5, blink))
			_px(Vector2(-1, -60), Color(1, 0.3, 0.2, 0.5 + blink), 3)
			_px(Vector2(-1, -55), Color(1, 0.3, 0.2, 0.5 + blink), 3)
		"notes":
			for p in _parts:
				var tt2: float = max(0.0, t - float(p[2]))
				var pos3: Vector2 = p[0] + Vector2(sin(tt2 * 6.0) * 3.0 + float(p[1]), -tt2 * 24.0)
				_px(pos3, Color(color, a), 2)
				_px(pos3 + Vector2(2, -3), Color(color, a), 1)
				draw_line(pos3 + Vector2(1.5, 0), pos3 + Vector2(1.5, -3), Color(color, a))
		"shield":
			var r3 := 10.0 + k * 4.0
			draw_arc(Vector2(0, -12), r3, 0, TAU, 16, Color("#8FD8FF", a), 1.0)
		"coin":
			var p4 := Vector2(sin(k * 6.0) * 4.0, -k * 18.0 + k * k * 18.0)
			_px(p4, Color("#F7C948", a), 2)
		"meteor":
			var start := Vector2(-40, -90)
			var p5 := start.lerp(Vector2.ZERO, min(1.0, k * 1.8))
			draw_circle(p5, 5, Color("#FF7A33", 1.0 if k < 0.55 else a))
			draw_line(p5, p5 + Vector2(-10, -14), Color("#FFB347", 0.7), 3.0)
			if k > 0.55:
				draw_circle(Vector2.ZERO, 16 * (k - 0.4), Color("#FFB347", a * 0.6))
		"rain":
			for p in _parts:
				var tt3: float = max(0.0, t - float(p[1]))
				var pos4: Vector2 = p[0] + Vector2(-tt3 * 30, tt3 * 140)
				if pos4.y < 0:
					draw_line(pos4, pos4 + Vector2(2, -5), Color(color, 0.9))
		"summon":
			draw_rect(Rect2(-6, -20 * k, 12, 20 * k), Color(color, a * 0.4))
			for i in 6:
				_px(Vector2(_rng.randf_range(-6, 6), -_rng.randf_range(0, 24)), Color(color.lightened(0.5), a))
		"smoke":
			for i in 5:
				draw_circle(Vector2(i * 5 - 10, -6 - k * 6), 4 + k * 4, Color(0.6, 0.6, 0.7, a * 0.4))
