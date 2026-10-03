class_name ChestDrop
extends Node2D
## A chest popping out of a defeated enemy: arcs out, bounces on the ground, shines for a moment, then
## flies into the chest pile at the strip's left edge.

signal collected

const LIFE := 2.6
var kind := "wood"
var start := Vector2.ZERO
var land := Vector2.ZERO
var target := Vector2.ZERO
var _t := 0.0
var _played := false


func setup(k: String, from: Vector2, to: Vector2) -> void:
	kind = k
	start = from
	land = Vector2(from.x + 10.0, from.y)
	target = to
	position = from
	z_index = 22


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.45:
		# arc out of the body and land
		var k := _t / 0.45
		position = start.lerp(land, k) - Vector2(0, sin(k * PI) * 18.0)
	elif _t < 0.7:
		if not _played:
			_played = true
			AudioManager.play("chest_drop", 0.06, 0.55 + 0.08 * Chests.rank(kind))
		var k2 := (_t - 0.45) / 0.25
		position = land - Vector2(0, sin(k2 * PI) * 4.0)
	elif _t < 2.0:
		position = land
	else:
		# fly to the pile, shrinking
		var k3 := clampf((_t - 2.0) / (LIFE - 2.0), 0.0, 1.0)
		var e := k3 * k3
		position = land.lerp(target, e) - Vector2(0, sin(k3 * PI) * 14.0)
		scale = Vector2.ONE * lerpf(1.0, 0.45, e)
		if k3 >= 1.0:
			collected.emit()
			queue_free()
	queue_redraw()


func _draw() -> void:
	var squash := 1.0
	if _t >= 0.45 and _t < 0.6:
		squash = 1.0 - sin((_t - 0.45) / 0.15 * PI) * 0.18
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / squash, squash))
	ChestArt.draw(self, Vector2.ZERO, 16.0, kind, 0.0, _t, _t < 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# a beam of light on rare chests while they sit on the ground
	if Chests.rank(kind) >= 2 and _t > 0.6 and _t < 2.2:
		var a := sin(clampf((_t - 0.6) / 1.6, 0.0, 1.0) * PI) * 0.35
		var c := Chests.color(kind)
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -6), Vector2(4, -6), Vector2(2, -60), Vector2(-2, -60)]), Color(c, a * 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -4), Vector2(8, -4), Vector2(5, -46), Vector2(-5, -46)]), Color(c, a * 0.25))
