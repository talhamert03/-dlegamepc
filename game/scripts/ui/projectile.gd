class_name Projectile
extends Node2D
## Procedural pixel projectile travelling from a source to a target position.

var kind := "arrow"
var from := Vector2.ZERO
var to := Vector2.ZERO
var travel := 0.3
var t := 0.0
var arc := 0.0
var color := Color.WHITE


func setup(k: String, a: Vector2, b: Vector2, dur: float) -> void:
	kind = k
	from = a
	to = b
	travel = max(0.05, dur)
	arc = 10.0 if k.begins_with("arrow") else 0.0
	match k:
		"arrow", "arrow_enemy":
			color = Color("#E8D9A8")
		"bolt_arcane", "fireball":
			color = Color("#FF8A3D")
		"bolt_chaos":
			color = Color("#B266FF")
		"bolt_holy":
			color = Color("#FFE08A")
		"note":
			color = Color("#9FF3C0")
		"ice":
			color = Color("#9FDFFF")
		"bolt_enemy":
			color = Color("#E05A8A")
		_:
			color = Color.WHITE
	position = from


func _process(delta: float) -> void:
	t += delta
	var k: float = min(1.0, t / travel)
	var p := from.lerp(to, k)
	p.y -= sin(k * PI) * arc
	position = p.round()
	if k >= 1.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var dir := (to - from).normalized()
	if kind.begins_with("arrow"):
		var tail := -dir * 7.0
		draw_line(Vector2.ZERO, tail, Color("#8E5B3E"), 1.0)
		draw_rect(Rect2(round(dir.x * 1.0), -0.5, 2, 1), Color("#E6E8F0"))
		draw_rect(Rect2(round(tail.x), round(tail.y) - 1, 2, 1), color)
	elif kind == "note":
		draw_rect(Rect2(-1, -1, 3, 2), color)
		draw_line(Vector2(1.5, -1), Vector2(1.5, -5), color)
	else:
		draw_circle(Vector2.ZERO, 2.5, Color(color, 0.45))
		draw_rect(Rect2(-1, -1, 3, 3), color.lightened(0.3))
		draw_rect(Rect2(round(-dir.x * 4), round(-dir.y * 4), 2, 2), Color(color, 0.5))
		draw_rect(Rect2(round(-dir.x * 7), round(-dir.y * 7), 1, 1), Color(color, 0.3))
