class_name DrillIcon
extends Control

var drill := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(24, 26)


func _draw() -> void:
	draw_set_transform(size / 2.0)
	var tint := RangeStyle.RED
	match drill:
		0:
			draw_arc(Vector2.ZERO, 10.0, 0, TAU, 28, tint, 1.5, true)
			draw_arc(Vector2.ZERO, 5.6, 0, TAU, 20, tint, 1.35, true)
		1:
			for axis: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(axis * 4.0, axis * 10.0, tint, 1.5, true)
			draw_circle(Vector2.ZERO, 1.3, tint)
		2:
			_trace([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0), Vector2(0, -10)])
		3:
			_trace([Vector2(-5, -5), Vector2(-10, 0), Vector2(-5, 5)])
			_trace([Vector2(5, -5), Vector2(10, 0), Vector2(5, 5)])
			draw_line(Vector2(-10, 0), Vector2(10, 0), tint, 1.5, true)
		4:
			_trace([Vector2(8, -9), Vector2(8, 9)])
			_trace([Vector2(-11, 0), Vector2(3, 0), Vector2(-2, -5)])
			_trace([Vector2(3, 0), Vector2(-2, 5)])
		5:
			draw_rect(Rect2(-9, -9, 18, 18), tint, false, 1.5, true)
			draw_line(Vector2(0, -9), Vector2(0, 9), tint, 1.5, true)
			draw_line(Vector2(4, 3), Vector2(7, 3), tint, 1.5, true)
		6:
			_trace([Vector2(2, -11), Vector2(-6, 1), Vector2(1, 1), Vector2(-2, 11), Vector2(7, -2), Vector2(0, -2), Vector2(2, -11)])
		7:
			_trace([Vector2(-8, -1), Vector2(0, -10), Vector2(8, -1), Vector2(4, -1), Vector2(4, 9), Vector2(-4, 9), Vector2(-4, -1), Vector2(-8, -1)])


func _trace(points: Array) -> void:
	draw_polyline(PackedVector2Array(points), RangeStyle.RED, 1.5, true)
